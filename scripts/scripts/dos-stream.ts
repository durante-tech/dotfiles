#!/usr/bin/env bun
/**
 * dos-stream — runtime control plane for the DuranteOS build-in-public pipeline.
 *
 * Commands:
 *   phase <observe|think|plan|build|execute|verify|learn>
 *     Update Terminal Frame ?phase= via OBS WebSocket.
 *
 *   preshow [n] [agenda-pipe-separated]
 *     Increment stored session counter (or use $1), set Intro Overlay URL with
 *     ?n=N&agenda=... &in=5, switch to 01_Intro.
 *
 *   endshow [n] [shipped-pipe-separated] [runtime]
 *     Set Outro Overlay URL with ?n=N&shipped=...&runtime=HH:MM:SS,
 *     switch to 05_Outro. If runtime omitted, computes from session-start file.
 *
 *   marker [label]
 *     Create OBS recording chapter marker with the given label.
 *
 *   session-start
 *     Record current time as session start (used by endshow for runtime).
 *
 *   git-shipped
 *     Print today's commits (one per line) — used as default for endshow.
 *
 *   status
 *     Print current OBS scene + recording status + active phase + session N.
 *
 * State files:
 *   ~/.config/dos-stream/session.json   { lastN, sessionStartMs, phase }
 */

import { createHash } from "node:crypto";
import { readFileSync, existsSync, mkdirSync, writeFileSync } from "node:fs";
import { homedir } from "node:os";
import { execSync } from "node:child_process";

const URL_ = process.env.OBS_WEBSOCKET_URL ?? "ws://localhost:4455";
const HOME = homedir();
const STATE_DIR = `${HOME}/.config/dos-stream`;
const STATE_FILE = `${STATE_DIR}/session.json`;

const PHASES = ["observe","think","plan","build","execute","verify","learn"] as const;
type Phase = typeof PHASES[number];

// ─── State ───────────────────────────────────────────────────────────────
type State = { lastN: number; sessionStartMs: number | null; phase: Phase };
function loadState(): State {
  if (!existsSync(STATE_FILE)) return { lastN: 0, sessionStartMs: null, phase: "observe" };
  try { return JSON.parse(readFileSync(STATE_FILE, "utf8")); }
  catch { return { lastN: 0, sessionStartMs: null, phase: "observe" }; }
}
function saveState(s: State) {
  mkdirSync(STATE_DIR, { recursive: true });
  writeFileSync(STATE_FILE, JSON.stringify(s, null, 2));
}

// ─── OBS WebSocket helpers (auth + single-request) ──────────────────────
function password(): string {
  if (process.env.OBS_WEBSOCKET_PASSWORD) return process.env.OBS_WEBSOCKET_PASSWORD;
  const f = `${HOME}/.config/obs-cli/password`;
  if (existsSync(f)) return readFileSync(f, "utf8").trim();
  return "";
}
function authResp(salt: string, challenge: string, pass: string): string {
  const secret = createHash("sha256").update(pass + salt).digest("base64");
  return createHash("sha256").update(secret + challenge).digest("base64");
}

async function obs(requestType: string, requestData: any = {}): Promise<any> {
  const ws = new WebSocket(URL_);
  const pass = password();
  return new Promise((resolve, reject) => {
    const id = `req_${Date.now()}_${Math.random().toString(36).slice(2, 8)}`;
    let settled = false;
    let t: ReturnType<typeof setTimeout>;
    const close = () => {
      try { ws.close(); } catch {}
    };
    const fail = (err: Error) => {
      if (settled) return;
      settled = true;
      clearTimeout(t);
      close();
      reject(err);
    };
    const done = (data: any) => {
      if (settled) return;
      settled = true;
      clearTimeout(t);
      close();
      resolve(data);
    };
    t = setTimeout(() => fail(new Error(`OBS timeout: ${requestType}`)), 5000);
    ws.addEventListener("message", (ev) => {
      const m = JSON.parse(ev.data as string);
      if (m.op === 0) {
        const auth = m.d.authentication
          ? authResp(m.d.authentication.salt, m.d.authentication.challenge, pass) : undefined;
        ws.send(JSON.stringify({ op: 1, d: { rpcVersion: 1, ...(auth ? { authentication: auth } : {}), eventSubscriptions: 0 } }));
      } else if (m.op === 2) {
        ws.send(JSON.stringify({ op: 6, d: { requestType, requestId: id, requestData } }));
      } else if (m.op === 7 && m.d.requestId === id) {
        if (m.d.requestStatus.result) done(m.d.responseData ?? {});
        else fail(new Error(`${requestType}: ${m.d.requestStatus.comment} (${m.d.requestStatus.code})`));
      }
    });
    ws.addEventListener("error", () => {
      fail(new Error(`OBS WebSocket error while running ${requestType}`));
    });
    ws.addEventListener("close", (e) => {
      if (settled) return;
      if (e.code === 4009) fail(new Error("Auth failed — wrong OBS WebSocket password"));
      else fail(new Error(`OBS WebSocket closed before ${requestType} (${e.code})`));
    });
  });
}

// ─── Commands ────────────────────────────────────────────────────────────

async function cmdPhase(phaseName: string) {
  if (!PHASES.includes(phaseName as Phase)) {
    die(`Invalid phase. Use one of: ${PHASES.join(", ")}`);
  }
  const state = loadState();
  state.phase = phaseName as Phase;
  saveState(state);

  // Update Terminal Frame URL with the new phase
  const cur = await obs("GetInputSettings", { inputName: "Terminal Frame" });
  const baseUrl = cur.inputSettings.url || `file://${HOME}/Durante/Overlays/terminal-frame.html`;
  const u = new URL(baseUrl);
  u.searchParams.set("phase", phaseName);
  await obs("SetInputSettings", {
    inputName: "Terminal Frame",
    inputSettings: { ...cur.inputSettings, url: u.toString() },
    overlay: true,
  });

  // Notify via macOS for visual feedback
  try { execSync(`osascript -e 'display notification "Phase → ${phaseName}" with title "DuranteOS"'`); } catch {}
  console.log(`✓ phase → ${phaseName}`);
}

async function cmdPreshow(nArg?: string, agendaArg?: string) {
  const state = loadState();
  const n = nArg ? parseInt(nArg, 10) : state.lastN + 1;
  state.lastN = n;
  state.sessionStartMs = Date.now();
  saveState(state);

  const agenda = agendaArg ?? "Today's build · DuranteOS v0.0.11";
  const url = `file://${HOME}/Durante/Overlays/intro.html?n=${n}&in=5&agenda=${encodeURIComponent(agenda)}`;

  // Get current Intro Overlay settings, merge
  const cur = await obs("GetInputSettings", { inputName: "Intro Overlay" });
  await obs("SetInputSettings", {
    inputName: "Intro Overlay",
    inputSettings: { ...cur.inputSettings, is_local_file: false, url },
    overlay: true,
  });
  await obs("SetCurrentProgramScene", { sceneName: "01_Intro" });
  try { execSync(`osascript -e 'display notification "Session #${String(n).padStart(3,"0")} pre-show starting" with title "DuranteOS"'`); } catch {}
  console.log(`✓ preshow · session ${n} · agenda: ${agenda}`);
}

async function cmdEndshow(nArg?: string, shippedArg?: string, runtimeArg?: string) {
  const state = loadState();
  const n = nArg ? parseInt(nArg, 10) : state.lastN;

  // Compute runtime if not provided
  let runtime = runtimeArg;
  if (!runtime && state.sessionStartMs) {
    const elapsed = Math.floor((Date.now() - state.sessionStartMs) / 1000);
    const h = Math.floor(elapsed / 3600);
    const m = String(Math.floor((elapsed % 3600) / 60)).padStart(2, "0");
    const s = String(elapsed % 60).padStart(2, "0");
    runtime = `${h}:${m}:${s}`;
  }
  if (!runtime) runtime = "0:00:00";

  // Default shipped list: today's commits across known DOS project dirs
  const shipped = shippedArg ?? defaultShipped();

  const params = new URLSearchParams({ n: String(n), shipped, runtime });
  const url = `file://${HOME}/Durante/Overlays/outro.html?${params}`;

  const cur = await obs("GetInputSettings", { inputName: "Outro Overlay" });
  await obs("SetInputSettings", {
    inputName: "Outro Overlay",
    inputSettings: { ...cur.inputSettings, is_local_file: false, url },
    overlay: true,
  });
  await obs("SetCurrentProgramScene", { sceneName: "05_Outro" });
  console.log(`✓ endshow · session ${n} · runtime ${runtime} · shipped: ${shipped.slice(0, 80)}…`);
}

function defaultShipped(): string {
  // Get today's commits from the current cwd's git repo, fallback to "ship list pending"
  try {
    const out = execSync(`git log --since=midnight --pretty=format:'%s' 2>/dev/null | head -4`, {
      stdio: ["ignore", "pipe", "ignore"],
    }).toString().trim();
    if (out) return out.split("\n").map(s => s.replace(/\|/g, "·")).join("|");
  } catch {}
  return "Ship list pending · edit live via ?shipped= param";
}

async function cmdMarker(label?: string) {
  // Use AppleScript prompt if label not provided
  let l = label;
  if (!l) {
    try {
      l = execSync(
        `osascript -e 'tell app "System Events" to display dialog "Marker label:" default answer "" buttons {"Drop"} default button "Drop"'`,
        { stdio: ["ignore", "pipe", "ignore"] }
      ).toString().match(/text returned:([^\n]+)/)?.[1]?.trim() ?? "";
    } catch { l = ""; }
  }
  if (l && l.length > 0) {
    await obs("CreateRecordChapter", { chapterName: l });
    console.log(`✓ marker · "${l}"`);
  } else {
    await obs("CreateRecordChapter", {});
    console.log(`✓ marker · (no label)`);
  }
}

async function cmdSessionStart() {
  const state = loadState();
  state.sessionStartMs = Date.now();
  saveState(state);
  console.log(`✓ session started · ${new Date(state.sessionStartMs).toISOString()}`);
}

async function cmdGitShipped() {
  console.log(defaultShipped().replace(/\|/g, "\n"));
}

async function cmdStatus() {
  const state = loadState();
  try {
    const scene = await obs("GetCurrentProgramScene");
    const rec   = await obs("GetRecordStatus");
    const summary = `${scene.currentProgramSceneName} · ${rec.outputActive ? "REC" : "idle"} · phase ${state.phase} · session #${state.lastN}`;
    try { execSync(`osascript -e 'display notification "${summary}" with title "DuranteOS · Status"'`); } catch {}
    // Print compact one-liner — keeps notification UI tidy when Raycast shows the last stdout line
    console.log(summary);
  } catch (e: any) {
    console.error("OBS unreachable:", e.message);
  }
}

async function cmdReplaySave() {
  // Check if replay buffer is running first. If not, start it (so future presses can save).
  const status = await obs("GetReplayBufferStatus");
  if (!status.outputActive) {
    await obs("StartReplayBuffer");
    try {
      execSync(`osascript -e 'display notification "Replay buffer started · accumulating 60s · press REPLAY again to clip" with title "DuranteOS · Replay"'`);
    } catch {}
    console.log("✓ replay buffer started (was not running)");
    return;
  }
  await obs("SaveReplayBuffer");
  try { execSync(`osascript -e 'display notification "Replay clip saved to ~/Movies/OBS/" with title "DuranteOS · Replay"'`); } catch {}
  console.log("✓ replay saved");
}

function die(msg: string): never {
  process.stderr.write(`dos-stream: ${msg}\n`);
  process.exit(1);
}

// ─── Main ────────────────────────────────────────────────────────────────
const [cmd, ...rest] = process.argv.slice(2);

try {
  switch (cmd) {
    case "phase":         await cmdPhase(rest[0] ?? ""); break;
    case "preshow":       await cmdPreshow(rest[0], rest[1]); break;
    case "endshow":       await cmdEndshow(rest[0], rest[1], rest[2]); break;
    case "marker":        await cmdMarker(rest.join(" ").trim() || undefined); break;
    case "session-start": await cmdSessionStart(); break;
    case "git-shipped":   await cmdGitShipped(); break;
    case "status":        await cmdStatus(); break;
    case "replay-save":   await cmdReplaySave(); break;
    case "help": case undefined: case "-h": case "--help":
      console.log([
        "dos-stream — runtime control plane for the build-in-public pipeline",
        "",
        "  phase <observe|think|plan|build|execute|verify|learn>",
        "  preshow [n] [agenda-pipe-separated]",
        "  endshow [n] [shipped-pipe-separated] [runtime HH:MM:SS]",
        "  marker [label — prompts if omitted]",
        "  session-start",
        "  git-shipped",
        "  status",
      ].join("\n"));
      break;
    default:
      die(`Unknown command: ${cmd}. Try \`dos-stream help\`.`);
  }
} catch (e: any) {
  die(e.message ?? String(e));
}
