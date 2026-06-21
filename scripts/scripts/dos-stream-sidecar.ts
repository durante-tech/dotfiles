#!/usr/bin/env bun
/**
 * dos-stream-sidecar — serve REAL build activity to the DuranteOS terminal-frame overlay.
 *
 * The terminal-frame.html overlay shows a rolling activity stream; by default it
 * uses simulated SEED/ROLLING events. This sidecar replaces that with live data:
 * recent git commits, branch/dirty state, current OBS scene, and recording status.
 *
 * Run (alongside OBS):  bun ~/scripts/dos-stream-sidecar  [--port 7842] [--repo ~/Durante]
 * Then the overlay fetches http://127.0.0.1:7842/events every few seconds.
 * If the sidecar is offline the overlay silently falls back to simulated events.
 *
 * GET /events → { branch, dirty, scene, rec, runtimeMs, events: [{time,label}] }
 *   `label` may contain the overlay's inline spans: <span class="ok|accent|warn|num">…</span>
 *
 * Zero npm deps — Bun built-ins + git/obs CLIs on PATH.
 */
import { execSync } from "node:child_process";
import { readFileSync, readlinkSync, existsSync } from "node:fs";
import { homedir } from "node:os";
const HOME = process.env.HOME || homedir();

const args = process.argv.slice(2);
const flag = (n: string, d: string) => { const i = args.indexOf(n); return i >= 0 ? args[i + 1] : d; };
const PORT = parseInt(flag("--port", "7842"), 10);
const REPO = flag("--repo", `${process.env.HOME}/Durante`).replace("~", process.env.HOME || "");
const startMs = Date.now();

function sh(cmd: string): string {
  try { return execSync(cmd, { cwd: REPO, encoding: "utf8", stdio: ["ignore", "pipe", "ignore"], timeout: 2500 }).trim(); }
  catch { return ""; }
}
function obs(sub: string): string {
  try { return execSync(`obs ${sub}`, { encoding: "utf8", stdio: ["ignore", "pipe", "ignore"], timeout: 2500 }).trim(); }
  catch { return ""; }
}
// truncate THEN escape (so the byte budget = visible text, never a half-entity);
// escape quotes too as defense-in-depth in case a label is ever used in an attribute context.
const esc = (s: string) => s.slice(0, 48).replace(/[<>&"']/g, (c) => ({ "<": "&lt;", ">": "&gt;", "&": "&amp;", '"': "&quot;", "'": "&#39;" }[c]!));
const hm = () => { const d = new Date(); const p = (n: number) => String(n).padStart(2, "0"); return `${p(d.getHours())}:${p(d.getMinutes())}`; };

function collect() {
  const branch = sh("git rev-parse --abbrev-ref HEAD") || "main";
  const dirtyN = (sh("git status --porcelain").split("\n").filter(Boolean)).length;
  const commits = sh("git log --oneline -6 --no-decorate").split("\n").filter(Boolean);
  const scene = obs("current") || "—";
  const recRaw = obs("rec status");
  const rec = /"outputActive"\s*:\s*true/.test(recRaw) ? "REC" : "idle";

  const events: { time: string; label: string }[] = [];
  events.push({ time: hm(), label: `<span class="${dirtyN ? "warn" : "ok"}">●</span> git · <span class="num">${esc(branch)}</span> · ${dirtyN ? `<span class="warn">${dirtyN} dirty</span>` : "clean"}` });
  if (scene !== "—") events.push({ time: hm(), label: `<span class="accent">●</span> obs · <span class="num">${esc(scene)}</span>` });
  events.push({ time: hm(), label: `<span class="${rec === "REC" ? "warn" : "ok"}">●</span> rec · <span class="num">${rec}</span>` });
  for (const c of commits) {
    const sha = c.slice(0, 7);
    const msg = esc(c.slice(8));
    events.push({ time: hm(), label: `<span class="ok">✓</span> commit · <span class="num">${sha}</span> · ${msg}` });
  }
  return { branch, dirty: dirtyN, scene, rec, runtimeMs: Date.now() - startMs, events, ...meta() };
}

// Live "reality" fields the overlays show as static text by default.
function meta() {
  const home = HOME;
  let build = "";
  try { build = (readlinkSync(`${home}/.claude`).match(/Releases\/(v[\d.]+)/) || [])[1] || ""; } catch {}
  let algorithm = "";
  try { algorithm = readFileSync(`${home}/.claude/DOS/Algorithm/LATEST`, "utf8").trim(); } catch {}
  // drawers: best-effort live count from the memory-events stream (filed-away drawers); "" if unavailable.
  let drawers = "";
  try {
    const ev = `${home}/.claude/MEMORY/MEMPALACE/memory-events.jsonl`;
    if (existsSync(ev)) {
      const n = readFileSync(ev, "utf8").split("\n").filter((l) => l.includes("add_drawer")).length;
      if (n > 0) drawers = n.toLocaleString("en-US").replace(/,/g, " ");
    }
  } catch {}
  return { build, algorithm, drawers };
}

// Stream-profile drift detector. The sketchybar OBS button pairs a stream
// toggle with display-restore.sh --stream/--force, but a stream toggled from the
// OBS GUI bypasses that — leaving the built-in at daily 1117px while OBS captures
// for a 1080 canvas. This read-only check surfaces that drift (warning-only; no
// auto-correct, since a GUI toggle may be intentional). Reads displayplacer list
// + OBS status only — Constraint-1 safe (no virtual-screen ops).
const BUILTIN_UUID = "37D8832A-2D66-02CA-B9F7-8F30A301B230";
function builtinHeight(): number {
  let out = "";
  try { out = execSync("displayplacer list", { encoding: "utf8", stdio: ["ignore", "pipe", "ignore"], timeout: 2500 }).trim(); }
  catch { return -1; }
  const idx = out.indexOf(BUILTIN_UUID);
  if (idx < 0) return -1;
  const m = out.slice(idx).match(/Resolution:\s*\d+x(\d+)/);
  return m ? parseInt(m[1], 10) : -1;
}
function verifyStreamProfile() {
  const streaming = /"outputActive"\s*:\s*true/.test(obs("stream status"));
  const h = builtinHeight();
  // --stream sets the built-in to 1080-tall; daily is 1117. Drift = live stream
  // but the built-in is NOT on the stream profile (and we could read the height).
  const drift = streaming && h > 0 && h !== 1080;
  return {
    streaming,
    builtinHeight: h,
    expectedHeight: streaming ? 1080 : 1117,
    drift,
    message: drift
      ? `DRIFT: streaming but built-in is ${h}px tall (expected 1080). Run: display-restore.sh --stream --force`
      : "ok",
  };
}

const CORS = { "Access-Control-Allow-Origin": "*", "Content-Type": "application/json" };
Bun.serve({
  port: PORT,
  hostname: "127.0.0.1", // localhost only — never expose git/OBS activity to the LAN
  fetch(req) {
    const url = new URL(req.url);
    if (url.pathname === "/events") return new Response(JSON.stringify(collect()), { headers: CORS });
    if (url.pathname === "/verify-stream-profile") return new Response(JSON.stringify(verifyStreamProfile()), { headers: CORS });
    if (url.pathname === "/health") return new Response(JSON.stringify({ ok: true, repo: REPO }), { headers: CORS });
    return new Response("dos-stream-sidecar · GET /events", { status: 404, headers: { "Access-Control-Allow-Origin": "*" } });
  },
});
console.log(`dos-stream-sidecar on http://127.0.0.1:${PORT}/events · repo=${REPO}`);
