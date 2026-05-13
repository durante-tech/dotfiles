#!/usr/bin/env bun
/**
 * obs — minimal OBS WebSocket v5 CLI for DuranteOS build-in-public stack.
 *
 * Usage:
 *   obs scene <name>          switch to a named scene
 *   obs scenes                list scenes (JSON)
 *   obs current               print current scene name
 *   obs rec start|stop|toggle control recording
 *   obs rec status            recording status JSON {active, paused, timecode, bytes}
 *   obs stream start|stop|toggle  control streaming
 *   obs marker [label]        create a recording chapter marker (OBS 31+)
 *   obs stats                 OBS performance stats JSON
 *   obs mute <input>          toggle input mute (e.g. "Mic/Aux")
 *   obs raw <requestType> [json]  arbitrary request, prints response
 *
 * Auth precedence:
 *   1. $OBS_WEBSOCKET_PASSWORD env var
 *   2. ~/.config/obs-cli/password (mode 600)
 *
 * Server: defaults to ws://localhost:4455 — override via $OBS_WEBSOCKET_URL.
 *
 * No npm dependencies. Uses Bun's built-in WebSocket + crypto.
 */

import { createHash } from "node:crypto";
import { readFileSync, existsSync } from "node:fs";
import { homedir } from "node:os";

const URL_ = process.env.OBS_WEBSOCKET_URL ?? "ws://localhost:4455";

function password(): string {
  if (process.env.OBS_WEBSOCKET_PASSWORD) return process.env.OBS_WEBSOCKET_PASSWORD;
  const passFile = `${homedir()}/.config/obs-cli/password`;
  if (existsSync(passFile)) return readFileSync(passFile, "utf8").trim();
  return "";
}

function authResponse(salt: string, challenge: string, pass: string): string {
  const secret = createHash("sha256").update(pass + salt).digest("base64");
  return createHash("sha256").update(secret + challenge).digest("base64");
}

type AnyMsg = { op: number; d: any };

async function call(requestType: string, requestData: Record<string, any> = {}): Promise<any> {
  const ws = new WebSocket(URL_);
  const pass = password();

  return new Promise((resolve, reject) => {
    const requestId = `req_${Date.now()}_${Math.random().toString(36).slice(2, 8)}`;
    const timeout = setTimeout(() => {
      ws.close();
      reject(new Error(`OBS WebSocket timeout after 5s. Is OBS running with WebSocket enabled on ${URL_}?`));
    }, 5000);

    ws.addEventListener("message", (ev) => {
      const msg: AnyMsg = JSON.parse(ev.data as string);

      // Hello → Identify
      if (msg.op === 0) {
        const auth = msg.d.authentication
          ? authResponse(msg.d.authentication.salt, msg.d.authentication.challenge, pass)
          : undefined;
        ws.send(
          JSON.stringify({
            op: 1,
            d: { rpcVersion: 1, ...(auth ? { authentication: auth } : {}), eventSubscriptions: 0 },
          })
        );
        return;
      }

      // Identified — send request
      if (msg.op === 2) {
        ws.send(
          JSON.stringify({
            op: 6,
            d: { requestType, requestId, requestData },
          })
        );
        return;
      }

      // RequestResponse
      if (msg.op === 7 && msg.d.requestId === requestId) {
        clearTimeout(timeout);
        ws.close();
        if (msg.d.requestStatus.result) {
          resolve(msg.d.responseData ?? {});
        } else {
          reject(new Error(`${requestType} failed: ${msg.d.requestStatus.comment ?? "unknown"} (code ${msg.d.requestStatus.code})`));
        }
        return;
      }
    });

    ws.addEventListener("error", (e) => {
      clearTimeout(timeout);
      reject(new Error(`WebSocket error connecting to ${URL_}: ${(e as ErrorEvent).message ?? "unknown"}`));
    });

    ws.addEventListener("close", (e) => {
      clearTimeout(timeout);
      // Map OBS WebSocket close codes to actionable errors.
      // Full table: https://github.com/obsproject/obs-websocket/blob/master/docs/generated/protocol.md#websocketclosecode
      if (e.code === 4009) reject(new Error(`Authentication failed (4009). Wrong password in ~/.config/obs-cli/password or $OBS_WEBSOCKET_PASSWORD. Reveal current password in OBS → Tools → WebSocket Server Settings → Show Connect Info.`));
      else if (e.code === 4008) reject(new Error(`Authentication required (4008). Set password in ~/.config/obs-cli/password.`));
      else if (e.code === 4006) reject(new Error(`Session invalidated (4006). Restart OBS and retry.`));
      // For normal close (1000) after a successful response, resolve() already fired — this is a no-op.
    });
  });
}

function out(data: unknown) {
  if (typeof data === "string") process.stdout.write(data + "\n");
  else process.stdout.write(JSON.stringify(data, null, 2) + "\n");
}

function die(msg: string): never {
  process.stderr.write(`obs: ${msg}\n`);
  process.exit(1);
}

const [cmd, ...rest] = process.argv.slice(2);

try {
  switch (cmd) {
    case "scene": {
      const name = rest.join(" ");
      if (!name) die("usage: obs scene <name>");
      await call("SetCurrentProgramScene", { sceneName: name });
      out(`→ ${name}`);
      break;
    }
    case "scenes": {
      const r = await call("GetSceneList");
      out(r.scenes.map((s: any) => s.sceneName));
      break;
    }
    case "current": {
      const r = await call("GetCurrentProgramScene");
      out(r.currentProgramSceneName);
      break;
    }
    case "rec": {
      const sub = rest[0];
      if (sub === "start") await call("StartRecord");
      else if (sub === "stop") await call("StopRecord");
      else if (sub === "toggle") await call("ToggleRecord");
      else if (sub === "status" || !sub) {
        const r = await call("GetRecordStatus");
        out(r);
        break;
      } else die(`unknown rec subcommand: ${sub}`);
      out(`rec ${sub}`);
      break;
    }
    case "stream": {
      const sub = rest[0];
      if (sub === "start") await call("StartStream");
      else if (sub === "stop") await call("StopStream");
      else if (sub === "toggle") await call("ToggleStream");
      else if (sub === "status" || !sub) {
        const r = await call("GetStreamStatus");
        out(r);
        break;
      } else die(`unknown stream subcommand: ${sub}`);
      out(`stream ${sub}`);
      break;
    }
    case "marker": {
      const chapterName = rest.join(" ") || undefined;
      await call("CreateRecordChapter", chapterName ? { chapterName } : {});
      out(`marker ${chapterName ?? "(default)"}`);
      break;
    }
    case "stats": {
      const r = await call("GetStats");
      out(r);
      break;
    }
    case "mute": {
      const inputName = rest.join(" ");
      if (!inputName) die("usage: obs mute <input>");
      await call("ToggleInputMute", { inputName });
      out(`mute toggled: ${inputName}`);
      break;
    }
    case "raw": {
      const requestType = rest[0];
      if (!requestType) die("usage: obs raw <requestType> [jsonData]");
      const data = rest[1] ? JSON.parse(rest[1]) : {};
      const r = await call(requestType, data);
      out(r);
      break;
    }
    case undefined:
    case "help":
    case "-h":
    case "--help":
      out([
        "obs — OBS WebSocket v5 CLI",
        "",
        "Commands:",
        "  scene <name>           switch to scene",
        "  scenes                 list scenes",
        "  current                current scene name",
        "  rec start|stop|toggle  recording control",
        "  rec status             recording status",
        "  stream start|stop|toggle  streaming control",
        "  stream status          streaming status",
        "  marker [label]         drop a recording chapter (OBS 31+)",
        "  stats                  OBS perf stats",
        "  mute <input>           toggle input mute",
        "  raw <type> [json]      raw request",
        "",
        `Server: $OBS_WEBSOCKET_URL = ${URL_}`,
        "Auth:   $OBS_WEBSOCKET_PASSWORD or ~/.config/obs-cli/password",
      ].join("\n"));
      break;
    default:
      die(`unknown command: ${cmd}. Try \`obs help\`.`);
  }
} catch (e: any) {
  die(e.message ?? String(e));
}
