#!/usr/bin/env bun
/**
 * obs-scene-build — programmatically (re)build the 5 DuranteOS scenes via OBS WebSocket v5.
 *
 * Idempotent: drops + recreates each scene each run. Safe to invoke after editing this file.
 *
 * Requires:
 *   - OBS running with WebSocket enabled on ws://localhost:4455
 *   - ~/.config/obs-cli/password (or $OBS_WEBSOCKET_PASSWORD env)
 *   - ~/Durante/Overlays/{lower-third,webcam-frame,brb}.html (overlays)
 *   - ~/Pictures/DuranteOS-BIP/{wordmark,outro-card}.png (brand assets)
 *   - ~/Pictures/Wallpapers/{10-dos,07-mempalace,01-telos}.jpg (scene backgrounds)
 */

import { createHash } from "node:crypto";
import { readFileSync, existsSync } from "node:fs";
import { homedir } from "node:os";

// ─── Config ──────────────────────────────────────────────────────────────
const URL_ = process.env.OBS_WEBSOCKET_URL ?? "ws://localhost:4455";
const HOME = homedir();
const OVERLAYS = `${HOME}/Durante/Overlays`;
const BRAND = `${HOME}/Pictures/DuranteOS-BIP`;
const WALLS = `${HOME}/Pictures/Wallpapers`;

const CANVAS_W = 1920;
const CANVAS_H = 1080;

// ─── Auth ────────────────────────────────────────────────────────────────
function loadPassword(): string {
  if (process.env.OBS_WEBSOCKET_PASSWORD) return process.env.OBS_WEBSOCKET_PASSWORD;
  const passFile = `${HOME}/.config/obs-cli/password`;
  if (existsSync(passFile)) return readFileSync(passFile, "utf8").trim();
  return "";
}

function authResp(salt: string, challenge: string, pass: string): string {
  const secret = createHash("sha256").update(pass + salt).digest("base64");
  return createHash("sha256").update(secret + challenge).digest("base64");
}

// ─── WebSocket helpers ──────────────────────────────────────────────────
type AnyMsg = { op: number; d: any };

let ws: WebSocket;
const pending = new Map<string, { resolve: (v: any) => void; reject: (e: any) => void }>();

function connect(): Promise<void> {
  return new Promise((resolve, reject) => {
    ws = new WebSocket(URL_);
    const timeout = setTimeout(() => reject(new Error("Connect timeout")), 5000);

    ws.addEventListener("message", async (ev) => {
      const msg: AnyMsg = JSON.parse(ev.data as string);

      if (msg.op === 0) {
        // Hello → Identify
        const pass = loadPassword();
        const auth = msg.d.authentication
          ? authResp(msg.d.authentication.salt, msg.d.authentication.challenge, pass)
          : undefined;
        ws.send(JSON.stringify({
          op: 1,
          d: { rpcVersion: 1, ...(auth ? { authentication: auth } : {}), eventSubscriptions: 0 },
        }));
      } else if (msg.op === 2) {
        clearTimeout(timeout);
        resolve();
      } else if (msg.op === 7) {
        // Request response
        const id = msg.d.requestId;
        const slot = pending.get(id);
        if (!slot) return;
        pending.delete(id);
        if (msg.d.requestStatus.result) {
          slot.resolve(msg.d.responseData ?? {});
        } else {
          // Map common-fail codes to cleaner errors
          const c = msg.d.requestStatus.code;
          const comment = msg.d.requestStatus.comment ?? "no comment";
          slot.reject(new Error(`Request ${msg.d.requestType} failed: code ${c} — ${comment}`));
        }
      }
    });

    ws.addEventListener("close", (e) => {
      clearTimeout(timeout);
      if (e.code === 4009) reject(new Error("Auth failed (4009). Wrong OBS WebSocket password."));
    });
    ws.addEventListener("error", () => reject(new Error("WebSocket error connecting to " + URL_)));
  });
}

function call(requestType: string, requestData: any = {}): Promise<any> {
  return new Promise((resolve, reject) => {
    const requestId = `req_${Date.now()}_${Math.random().toString(36).slice(2, 8)}`;
    pending.set(requestId, { resolve, reject });
    ws.send(JSON.stringify({ op: 6, d: { requestType, requestId, requestData } }));
  });
}

// Tolerant call: warn on failure but don't throw (used for delete-if-exists ops).
async function callMaybe(requestType: string, requestData: any = {}): Promise<any> {
  try { return await call(requestType, requestData); }
  catch (e: any) { return null; }
}

// ─── Source builders ────────────────────────────────────────────────────
type Transform = {
  alignment?: number;
  positionX?: number; positionY?: number;
  scaleX?: number; scaleY?: number;
  width?: number; height?: number;
  boundsType?: string; boundsAlignment?: number;
  boundsWidth?: number; boundsHeight?: number;
  cropLeft?: number; cropTop?: number; cropRight?: number; cropBottom?: number;
};

const ALIGN_CENTER = 0;
// "OBS_BOUNDS_SCALE_INNER" = fit inside the bounds rect, preserving aspect

/** Create an input on a scene + apply transform. Returns the scene item ID. */
async function addSource(
  sceneName: string,
  inputName: string,
  inputKind: string,
  inputSettings: any,
  transform: Transform = {}
): Promise<number> {
  // Delete any pre-existing input with this name (idempotent re-runs)
  await callMaybe("RemoveInput", { inputName });
  const created = await call("CreateInput", {
    sceneName,
    inputName,
    inputKind,
    inputSettings,
    sceneItemEnabled: true,
  });
  const sceneItemId = created.sceneItemId;

  if (Object.keys(transform).length > 0) {
    await call("SetSceneItemTransform", {
      sceneName,
      sceneItemId,
      sceneItemTransform: transform,
    });
  }
  return sceneItemId;
}

/** Fit-to-canvas bounds transform (preserves aspect, fills 1920×1080).
 *  Note: `alignment: 0` (center) is REQUIRED — without it, sources default to top-left
 *  anchor (alignment: 5 = LEFT|TOP) and extend off-canvas from positionX,Y. */
function fitCanvas(): Transform {
  return {
    alignment: 0,
    boundsType: "OBS_BOUNDS_SCALE_INNER",
    boundsAlignment: ALIGN_CENTER,
    boundsWidth: CANVAS_W,
    boundsHeight: CANVAS_H,
    positionX: CANVAS_W / 2,
    positionY: CANVAS_H / 2,
  };
}

// ─── Camera detection ───────────────────────────────────────────────────
async function pickCamera(): Promise<{ name: string; uid?: string }> {
  // Query macOS for connected cameras — prefer iPhone Continuity if present
  const { execSync } = require("node:child_process");
  const out = execSync("system_profiler SPCameraDataType 2>/dev/null").toString();
  const iphoneMatch = out.match(/iPhone[\w\s]*Camera:\s*\n\s*Model ID: ([^\n]+)\s*\n\s*Unique ID: ([\w-]+)/);
  if (iphoneMatch) {
    return { name: "iPhone Continuity", uid: iphoneMatch[2] };
  }
  return { name: "FaceTime HD", uid: undefined }; // OBS will pick default
}

// ─── Main: build all 5 scenes ──────────────────────────────────────────
async function main() {
  await connect();
  console.log("✅ connected to OBS WebSocket");

  // Set canvas to 1920×1080@60 (idempotent — already there per probe)
  await call("SetVideoSettings", {
    baseWidth: CANVAS_W, baseHeight: CANVAS_H,
    outputWidth: CANVAS_W, outputHeight: CANVAS_H,
    fpsNumerator: 60, fpsDenominator: 1,
  });

  // Detect camera
  const cam = await pickCamera();
  console.log(`📷 camera: ${cam.name}${cam.uid ? ` (uid ${cam.uid.slice(0, 8)}…)` : ""}`);

  // ─── Drop existing 01_-05_ scenes for idempotent re-runs ─────────────
  const scenes = ["01_Intro", "02_Coding", "03_Terminal_Only", "04_Break", "05_Outro"];
  for (const s of scenes) {
    await callMaybe("RemoveScene", { sceneName: s });
  }

  // ─── 01_Intro ────────────────────────────────────────────────────────
  await call("CreateScene", { sceneName: "01_Intro" });
  await addSource("01_Intro", "Intro Background", "image_source",
    { file: `${WALLS}/10-dos.jpg`, unload: false },
    fitCanvas()
  );
  await addSource("01_Intro", "Intro Wordmark", "image_source",
    { file: `${BRAND}/wordmark.png`, unload: false },
    {
      width: 1200, height: 400,
      positionX: CANVAS_W / 2, positionY: CANVAS_H / 2,
      boundsType: "OBS_BOUNDS_SCALE_INNER",
      boundsAlignment: ALIGN_CENTER,
      boundsWidth: 900, boundsHeight: 300,
    }
  );
  console.log("✅ 01_Intro");

  // ─── 02_Coding ───────────────────────────────────────────────────────
  await call("CreateScene", { sceneName: "02_Coding" });
  // Main display capture (built-in Retina by default — user can switch displays in source props).
  // Built-in Retina is 3456×2234 (16:10-ish, 1.547). Canvas is 1920×1080 (16:9, 1.778).
  // Use SCALE_OUTER so the canvas FILLS with no black bars — small top (menu) + bottom (dock) crop.
  await addSource("02_Coding", "Display (Main)", "screen_capture",
    { type: 0, show_cursor: true, hide_obs: true },
    {
      alignment: 0,
      positionX: CANVAS_W / 2, positionY: CANVAS_H / 2,
      boundsType: "OBS_BOUNDS_SCALE_OUTER",
      boundsAlignment: ALIGN_CENTER,
      boundsWidth: CANVAS_W, boundsHeight: CANVAS_H,
    }
  );
  // Webcam, bottom-right PiP at 320×180, center-anchored, 20px margin from corners
  const webcamCx = CANVAS_W - 320 / 2 - 20; // 1740
  const webcamCy = CANVAS_H - 180 / 2 - 20; // 970
  await addSource("02_Coding", "Webcam", "av_capture_input_v2",
    {
      ...(cam.uid ? { uid: cam.uid, use_preset: true, preset: "AVCaptureSessionPresetHigh" } : { use_preset: true, preset: "AVCaptureSessionPresetHigh" }),
      enable_audio: false,
    },
    {
      alignment: 0,
      positionX: webcamCx, positionY: webcamCy,
      boundsType: "OBS_BOUNDS_SCALE_INNER",
      boundsAlignment: ALIGN_CENTER,
      boundsWidth: 320, boundsHeight: 180,
    }
  );
  // Webcam frame overlay aligned over the webcam (same center)
  await addSource("02_Coding", "Webcam Frame", "browser_source",
    {
      is_local_file: true,
      local_file: `${OVERLAYS}/webcam-frame.html`,
      width: 640, height: 360,
      fps: 30, reroute_audio: false,
      restart_when_active: true,
    },
    {
      alignment: 0,
      positionX: webcamCx, positionY: webcamCy,
      boundsType: "OBS_BOUNDS_SCALE_INNER",
      boundsAlignment: ALIGN_CENTER,
      boundsWidth: 320, boundsHeight: 180,
    }
  );
  // Lower-third browser source — full canvas width, 220px tall, anchored bottom
  // local_file mode does NOT support query strings; slide-in animation plays live in OBS.
  await addSource("02_Coding", "Lower Third", "browser_source",
    {
      is_local_file: true,
      local_file: `${OVERLAYS}/lower-third.html`,
      width: 1920, height: 220,
      fps: 30, reroute_audio: false,
      restart_when_active: true,
    },
    {
      alignment: 0,
      positionX: CANVAS_W / 2, positionY: CANVAS_H - 220 / 2,
      boundsType: "OBS_BOUNDS_SCALE_INNER",
      boundsAlignment: ALIGN_CENTER,
      boundsWidth: 1920, boundsHeight: 220,
    }
  );
  console.log("✅ 02_Coding");

  // ─── 03_Terminal_Only ────────────────────────────────────────────────
  await call("CreateScene", { sceneName: "03_Terminal_Only" });
  // Portrait display is 4320×7680 (9:16). Crop the TOP 4320×2430 region (16:9 slice)
  // and SCALE_INNER it to the canvas. User can move the crop region in OBS GUI if they
  // prefer mid/bottom of the portrait monitor.
  await addSource("03_Terminal_Only", "Display (Terminal)", "screen_capture",
    { type: 0, show_cursor: true, hide_obs: true },
    {
      alignment: 0,
      positionX: CANVAS_W / 2, positionY: CANVAS_H / 2,
      boundsType: "OBS_BOUNDS_SCALE_INNER",
      boundsAlignment: ALIGN_CENTER,
      boundsWidth: CANVAS_W, boundsHeight: CANVAS_H,
      cropTop: 0, cropBottom: 5250, cropLeft: 0, cropRight: 0,
    }
  );
  console.log("✅ 03_Terminal_Only — open this scene's Display source and pick your portrait monitor");

  // ─── 04_Break ────────────────────────────────────────────────────────
  await call("CreateScene", { sceneName: "04_Break" });
  await addSource("04_Break", "Break Background", "image_source",
    { file: `${WALLS}/07-mempalace.jpg`, unload: false },
    fitCanvas()
  );
  // BRB uses URL mode (not local_file) because query params are needed for the countdown duration.
  // file:// URLs preserve ?minutes=N; local_file paths do not.
  await addSource("04_Break", "BRB Overlay", "browser_source",
    {
      is_local_file: false,
      url: `file://${OVERLAYS}/brb.html?minutes=10`,
      width: 1920, height: 1080,
      fps: 30, reroute_audio: false,
      restart_when_active: true,
    },
    {
      positionX: 0, positionY: 0,
      boundsType: "OBS_BOUNDS_NONE",
    }
  );
  console.log("✅ 04_Break");

  // ─── 05_Outro ────────────────────────────────────────────────────────
  await call("CreateScene", { sceneName: "05_Outro" });
  await addSource("05_Outro", "Outro Background", "image_source",
    { file: `${WALLS}/01-telos.jpg`, unload: false },
    fitCanvas()
  );
  await addSource("05_Outro", "Outro Card", "image_source",
    { file: `${BRAND}/outro-card.png`, unload: false },
    fitCanvas()
  );
  console.log("✅ 05_Outro");

  // ─── Clean up the default "Scene" if present ─────────────────────────
  await callMaybe("RemoveScene", { sceneName: "Scene" });

  // Switch program to Intro so Stream Deck lights up
  await call("SetCurrentProgramScene", { sceneName: "01_Intro" });

  console.log(`\n✅ Built ${scenes.length} scenes. Open OBS → you should see the scene list populated.`);
  console.log("   Next: 03_Terminal_Only → right-click Display (Terminal) source → Properties → pick your portrait monitor from the Display dropdown.");

  ws.close();
}

main().catch((e) => {
  console.error("❌", e.message);
  process.exit(1);
});
