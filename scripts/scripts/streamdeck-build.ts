#!/usr/bin/env bun
/**
 * streamdeck-build — build the DuranteOS Stream Deck profile.
 *
 * Inputs:
 *   $1 — source .streamDeckProfile (zip) to clone & enhance
 *   $2 — output .streamDeckProfile path
 *
 * What it does:
 *   1. Unzips the source profile to a temp dir
 *   2. Generates ~30 brand-aligned 144×144 PNG icons matching DESIGN.md v0.0.10
 *   3. Rewrites the JSON manifests to:
 *      - Wire the DuranteOS Stream landing page (5 scenes top, controls mid, toggles bottom)
 *      - Fix the Scenes folder (program target, named scenes)
 *      - Keep OBS Profile + Audio + Dev folders, with new icons
 *   4. Re-zips to the output path
 *
 * No external deps. Uses rsvg-convert for SVG→PNG.
 */

import { mkdtempSync, mkdirSync, writeFileSync, readFileSync, copyFileSync, rmSync } from "node:fs";
import { tmpdir } from "node:os";
import { join, dirname } from "node:path";
import { execSync } from "node:child_process";

// ─────────────────────────────────────────────────────────────────────────
// Design tokens (synced with /Users/lgertel/Downloads/Durante Studio/theme.css)
// ─────────────────────────────────────────────────────────────────────────
const TOKENS = {
  bg: "#0a0d0f",
  surface1: "#14171c",
  primary: "#00e1ab",
  primaryDim: "#008f6b",
  primaryFore: "#003828",
  fg: "#e9e9ec",
  fgDim: "#b6b9bd",
  fgMute: "#797d83",
  hairline: "rgba(255,255,255,0.22)",
  red: "#ff5a52",
  // stage palette
  observe: "#36ffc4",
  think: "#6ed0ff",
  plan: "#ffb95a",
  build: "#deb7ff",
  execute: "#ff9f70",
  verify: "#00e1ab",
  learn: "#f0dbff",
} as const;

// ─────────────────────────────────────────────────────────────────────────
// SVG template — every icon shares this shell (corner brackets + bg)
// glyph + label vary per icon. 144×144 is the Stream Deck native key size.
// ─────────────────────────────────────────────────────────────────────────
type IconSpec = {
  /** Big center glyph (e.g. "$_", "&lt;/&gt;", "01", "●", "✕") */
  centerText?: string;
  /** Font size for centerText (default 64) */
  centerSize?: number;
  /** Italic center text (cyan italic register) */
  italic?: boolean;
  /** Glyph color (default TOKENS.fgMute = idle grey) */
  color?: string;
  /** Show 2px cyan outline ring (active state) */
  ring?: boolean;
  /** Background color override (rare) */
  bg?: string;
};

type IconDef = {
  key: string;
  idle: IconSpec;       // state 0
  active: IconSpec;     // state 1
  title: string;        // Stream Deck title-overlay text
};

function xmlEsc(s: string | undefined): string | undefined {
  if (s === undefined) return undefined;
  return s.replace(/&/g, "&amp;").replace(/</g, "&lt;").replace(/>/g, "&gt;").replace(/"/g, "&quot;").replace(/'/g, "&apos;");
}

/**
 * Render a text-free 144×144 icon. Labels live on the Stream Deck Title overlay,
 * NOT baked into the PNG. The glyph sits high (~y=78) to leave bottom space for
 * Stream Deck's title-overlay rendering.
 */
function svg(spec: IconSpec): string {
  const bg = spec.bg ?? TOKENS.bg;
  const color = spec.color ?? TOKENS.fgMute;
  const centerSize = spec.centerSize ?? 64;
  const italic = spec.italic ? "italic" : "normal";
  const centerText = xmlEsc(spec.centerText);
  const isActive = spec.ring === true;
  const bracketColor = isActive ? TOKENS.primary : TOKENS.fgMute;

  const activeRing = isActive
    ? `<rect x="3" y="3" width="138" height="138" rx="6" ry="6"
            fill="none" stroke="${TOKENS.primary}" stroke-width="2"
            stroke-opacity="0.85"/>`
    : "";

  return `<svg xmlns="http://www.w3.org/2000/svg" width="144" height="144" viewBox="0 0 144 144">
  <rect width="144" height="144" fill="${bg}"/>
  ${activeRing}
  <g stroke="${bracketColor}" stroke-width="1" stroke-opacity="${isActive ? 1 : 0.5}" fill="none">
    <path d="M 6 18 L 6 6 L 18 6"/>
    <path d="M 126 6 L 138 6 L 138 18"/>
    <path d="M 6 126 L 6 138 L 18 138"/>
    <path d="M 126 138 L 138 138 L 138 126"/>
  </g>
  ${centerText ? `<text x="72" y="86" text-anchor="middle" font-family="Manrope" font-size="${centerSize}" font-weight="600" letter-spacing="-2.4" font-style="${italic}" fill="${color}">${centerText}</text>` : ""}
</svg>`;
}

// ─────────────────────────────────────────────────────────────────────────
// Icon manifest — every icon we need to ship.
// Each entry has BOTH state PNGs (idle/active) + a title for Stream Deck overlay.
// ─────────────────────────────────────────────────────────────────────────
const ICONS: IconDef[] = [
  // ── Scenes (5 build-in-public scenes) ──
  // Idle = grey number, active = cyan italic with ring (scene-is-current)
  { key: "scene-01", title: "01 INTRO",    idle: { centerText: "01",  italic: true, color: TOKENS.fgMute }, active: { centerText: "01",  italic: true, color: TOKENS.primary, ring: true } },
  { key: "scene-02", title: "02 CODING",   idle: { centerText: "</>",               color: TOKENS.fgMute, centerSize: 52 }, active: { centerText: "</>",               color: TOKENS.primary, centerSize: 52, ring: true } },
  { key: "scene-03", title: "03 TERMINAL", idle: { centerText: "$_",                color: TOKENS.fgMute, centerSize: 56 }, active: { centerText: "$_",                color: TOKENS.primary, centerSize: 56, ring: true } },
  { key: "scene-04", title: "04 BREAK",    idle: { centerText: "04",  italic: true, color: TOKENS.fgMute }, active: { centerText: "04",  italic: true, color: TOKENS.primary, ring: true } },
  { key: "scene-05", title: "05 OUTRO",    idle: { centerText: "→",                 color: TOKENS.fgMute, centerSize: 64 }, active: { centerText: "→",                 color: TOKENS.primary, centerSize: 64, ring: true } },

  // ── Mic mute (state 0 = audio on, state 1 = muted) ──
  // Different glyphs per state — clearer visual signal than just color
  { key: "mic", title: "MIC", idle: { centerText: "●", color: TOKENS.primary, centerSize: 56 }, active: { centerText: "✕", color: TOKENS.red, centerSize: 60, ring: false } },

  // ── Record (state 0 = idle, state 1 = recording — red emphasis) ──
  { key: "rec", title: "REC", idle: { centerText: "●", color: TOKENS.fgMute, centerSize: 56 }, active: { centerText: "●", color: TOKENS.red, centerSize: 56, ring: true } },

  // ── Stream (state 0 = offline, state 1 = live) ──
  { key: "stream", title: "STREAM", idle: { centerText: "▷", color: TOKENS.fgMute, centerSize: 56 }, active: { centerText: "●", color: TOKENS.primary, centerSize: 56, ring: true } },

  // ── Marker (chapter) — single-state visual, but provide both ──
  { key: "marker", title: "MARKER", idle: { centerText: "❰", color: TOKENS.primary, italic: true, centerSize: 64 }, active: { centerText: "❰", color: TOKENS.primary, italic: true, centerSize: 64, ring: true } },

  // ── Source visibility toggles ──
  { key: "cam",  title: "CAM",  idle: { centerText: "○", color: TOKENS.fgMute, centerSize: 60 }, active: { centerText: "◉", color: TOKENS.primary, centerSize: 60, ring: true } },
  { key: "chat", title: "FRAME", idle: { centerText: "▢", color: TOKENS.fgMute, centerSize: 54 }, active: { centerText: "▣", color: TOKENS.primary, centerSize: 54, ring: true } },
  { key: "lt",   title: "LOWER THIRD", idle: { centerText: "▭", color: TOKENS.fgMute, centerSize: 56 }, active: { centerText: "▬", color: TOKENS.primary, centerSize: 56, ring: true } },

  // ── BRB scene (single state — just navigates) ──
  { key: "brb", title: "BRB",  idle: { centerText: "⏸", color: TOKENS.fgMute, centerSize: 56 }, active: { centerText: "⏸", color: TOKENS.primary, centerSize: 56, ring: true } },

  // ── Folder links — stateless visually ──
  { key: "folder-obs",    title: "OBS",    idle: { centerText: "obs", italic: true, color: TOKENS.primary, centerSize: 42 }, active: { centerText: "obs", italic: true, color: TOKENS.primary, centerSize: 42 } },
  { key: "folder-dev",    title: "DEV",    idle: { centerText: "dev", italic: true, color: TOKENS.primary, centerSize: 42 }, active: { centerText: "dev", italic: true, color: TOKENS.primary, centerSize: 42 } },
  { key: "folder-audio",  title: "AUDIO",  idle: { centerText: "♪",                 color: TOKENS.primary, centerSize: 64 }, active: { centerText: "♪",                 color: TOKENS.primary, centerSize: 64 } },
  { key: "folder-scenes", title: "SCENES", idle: { centerText: "◫",                 color: TOKENS.primary, centerSize: 60 }, active: { centerText: "◫",                 color: TOKENS.primary, centerSize: 60 } },
  { key: "back-parent",   title: "BACK",   idle: { centerText: "←",                 color: TOKENS.primary, centerSize: 64 }, active: { centerText: "←",                 color: TOKENS.primary, centerSize: 64 } },

  // ── Dev folder actions ──
  { key: "dev-post-x", title: "POST",   idle: { centerText: "𝕏",   color: TOKENS.fg,      centerSize: 60 }, active: { centerText: "𝕏",   color: TOKENS.primary, centerSize: 60, ring: true } },
  { key: "dev-push",   title: "PUSH",   idle: { centerText: "↑",   color: TOKENS.primary, centerSize: 64 }, active: { centerText: "↑",   color: TOKENS.primary, centerSize: 64, ring: true } },
  { key: "dev-server", title: "SERVER", idle: { centerText: "▶",   color: TOKENS.fgMute,  centerSize: 56 }, active: { centerText: "▶",   color: TOKENS.primary, centerSize: 56, ring: true } },
  { key: "dev-lfg",    title: "lfg",    idle: { centerText: "lfg", italic: true, color: TOKENS.primary, centerSize: 40 }, active: { centerText: "lfg", italic: true, color: TOKENS.primary, centerSize: 40, ring: true } },
  { key: "dev-popup",  title: "POPUP",  idle: { centerText: "◰",   color: TOKENS.primary, centerSize: 56 }, active: { centerText: "◰",   color: TOKENS.primary, centerSize: 56, ring: true } },

  // ── Stream ritual buttons ──
  { key: "preshow",     title: "PRE-SHOW",  idle: { centerText: "⚡", color: TOKENS.fgMute,  centerSize: 56 }, active: { centerText: "⚡", color: TOKENS.primary, centerSize: 56, ring: true } },
  { key: "endshow",     title: "END",       idle: { centerText: "▣", color: TOKENS.fgMute,  centerSize: 52 }, active: { centerText: "▣", color: TOKENS.primary, centerSize: 52, ring: true } },
  { key: "marker-label",title: "MARK ＋",   idle: { centerText: "❰", italic: true, color: TOKENS.primary, centerSize: 60 }, active: { centerText: "❰", italic: true, color: TOKENS.primary, centerSize: 60, ring: true } },

  // ── New Dev row 2 actions (replacing the missing lfg/push/server) ──
  { key: "status",        title: "STATUS",  idle: { centerText: "ⓘ", color: TOKENS.fgMute,  centerSize: 56 }, active: { centerText: "ⓘ", color: TOKENS.primary, centerSize: 56, ring: true } },
  { key: "session-start", title: "SESSION", idle: { centerText: "⏱", color: TOKENS.fgMute,  centerSize: 50 }, active: { centerText: "⏱", color: TOKENS.primary, centerSize: 50, ring: true } },
  { key: "replay-save",   title: "REPLAY",  idle: { centerText: "⇩", color: TOKENS.fgMute,  centerSize: 60 }, active: { centerText: "⇩", color: TOKENS.primary, centerSize: 60, ring: true } },

  // ── Source visibility icons (generic eye + state) — Sources folder ──
  { key: "vis-eye", title: "VIS", idle: { centerText: "◌", color: TOKENS.fgMute, centerSize: 56 }, active: { centerText: "◉", color: TOKENS.primary, centerSize: 56, ring: true } },

  // ── Phase swap buttons — each colored with its stage tone (DESIGN.md §01 Stage Palette) ──
  { key: "phase-obs", title: "OBSERVE", idle: { centerText: "Ob", italic: true, color: TOKENS.fgMute,  centerSize: 48 }, active: { centerText: "Ob", italic: true, color: TOKENS.observe, centerSize: 48, ring: true } },
  { key: "phase-thn", title: "THINK",   idle: { centerText: "Th", italic: true, color: TOKENS.fgMute,  centerSize: 48 }, active: { centerText: "Th", italic: true, color: TOKENS.think,   centerSize: 48, ring: true } },
  { key: "phase-pln", title: "PLAN",    idle: { centerText: "Pl", italic: true, color: TOKENS.fgMute,  centerSize: 48 }, active: { centerText: "Pl", italic: true, color: TOKENS.plan,    centerSize: 48, ring: true } },
  { key: "phase-bld", title: "BUILD",   idle: { centerText: "Bd", italic: true, color: TOKENS.fgMute,  centerSize: 48 }, active: { centerText: "Bd", italic: true, color: TOKENS.build,   centerSize: 48, ring: true } },
  { key: "phase-exe", title: "EXEC",    idle: { centerText: "Ex", italic: true, color: TOKENS.fgMute,  centerSize: 48 }, active: { centerText: "Ex", italic: true, color: TOKENS.execute, centerSize: 48, ring: true } },
  { key: "phase-ver", title: "VERIFY",  idle: { centerText: "Vf", italic: true, color: TOKENS.fgMute,  centerSize: 48 }, active: { centerText: "Vf", italic: true, color: TOKENS.verify,  centerSize: 48, ring: true } },
  { key: "phase-lrn", title: "LEARN",   idle: { centerText: "Ln", italic: true, color: TOKENS.fgMute,  centerSize: 48 }, active: { centerText: "Ln", italic: true, color: TOKENS.learn,   centerSize: 48, ring: true } },

  // ── OBS folder controls ──
  { key: "studio-mode",  title: "STUDIO",     idle: { centerText: "▢", color: TOKENS.fgMute,  centerSize: 56 }, active: { centerText: "▣", color: TOKENS.primary, centerSize: 56, ring: true } },
  { key: "transition",   title: "TRANSITION", idle: { centerText: "⇄", color: TOKENS.primary, centerSize: 56 }, active: { centerText: "⇄", color: TOKENS.primary, centerSize: 56, ring: true } },
  { key: "scene-fade",   title: "FADE",       idle: { centerText: "≈", color: TOKENS.primary, centerSize: 56 }, active: { centerText: "≈", color: TOKENS.primary, centerSize: 56, ring: true } },
  { key: "scene-stinger",title: "STINGER",    idle: { centerText: "✦", color: TOKENS.primary, centerSize: 56 }, active: { centerText: "✦", color: TOKENS.primary, centerSize: 56, ring: true } },
  { key: "virtcam",      title: "VCAM",       idle: { centerText: "▢", color: TOKENS.fgMute,  centerSize: 56 }, active: { centerText: "◉", color: TOKENS.primary, centerSize: 56, ring: true } },
  { key: "replay-buffer",title: "REPLAY",     idle: { centerText: "↻", color: TOKENS.fgMute,  centerSize: 64 }, active: { centerText: "↻", color: TOKENS.primary, centerSize: 64, ring: true } },
  { key: "replay-save",  title: "SAVE",       idle: { centerText: "⇩", color: TOKENS.primary, centerSize: 64 }, active: { centerText: "⇩", color: TOKENS.primary, centerSize: 64, ring: true } },
  { key: "rec-pause",    title: "PAUSE",      idle: { centerText: "‖", color: TOKENS.fgMute,  centerSize: 60 }, active: { centerText: "‖", color: TOKENS.primary, centerSize: 60, ring: true } },

  // ── Screen modes (BetterDisplay mode-switching via bd-apply.sh through Raycast script-commands) ──
  // Mood colors map to the bd-apply.sh curve: warm/observe for dawn, primary for day, dim/cool for evening/night.
  { key: "screen-dawn",      title: "DAWN",      idle: { centerText: "Dw",  italic: true, color: TOKENS.fgMute, centerSize: 48 }, active: { centerText: "Dw",  italic: true, color: TOKENS.observe,    centerSize: 48, ring: true } },
  { key: "screen-day",       title: "DAY",       idle: { centerText: "Dy",  italic: true, color: TOKENS.fgMute, centerSize: 48 }, active: { centerText: "Dy",  italic: true, color: TOKENS.primary,    centerSize: 48, ring: true } },
  { key: "screen-afternoon", title: "AFTERNOON", idle: { centerText: "Af",  italic: true, color: TOKENS.fgMute, centerSize: 48 }, active: { centerText: "Af",  italic: true, color: TOKENS.primaryDim, centerSize: 48, ring: true } },
  { key: "screen-evening",   title: "EVENING",   idle: { centerText: "Ev",  italic: true, color: TOKENS.fgMute, centerSize: 48 }, active: { centerText: "Ev",  italic: true, color: TOKENS.plan,       centerSize: 48, ring: true } },
  { key: "screen-night",     title: "NIGHT",     idle: { centerText: "Nt",  italic: true, color: TOKENS.fgMute, centerSize: 48 }, active: { centerText: "Nt",  italic: true, color: TOKENS.build,      centerSize: 48, ring: true } },
  { key: "screen-meeting",   title: "MEETING",   idle: { centerText: "Mt",  italic: true, color: TOKENS.fgMute, centerSize: 48 }, active: { centerText: "Mt",  italic: true, color: TOKENS.fg,         centerSize: 48, ring: true } },
  { key: "screen-read",      title: "READ",      idle: { centerText: "Rd",  italic: true, color: TOKENS.fgMute, centerSize: 48 }, active: { centerText: "Rd",  italic: true, color: TOKENS.learn,      centerSize: 48, ring: true } },
  { key: "screen-stream",    title: "STREAM",    idle: { centerText: "St",  italic: true, color: TOKENS.fgMute, centerSize: 48 }, active: { centerText: "St",  italic: true, color: TOKENS.red,        centerSize: 48, ring: true } },
  { key: "screen-cinema",    title: "CINEMA",    idle: { centerText: "Cn",  italic: true, color: TOKENS.fgMute, centerSize: 48 }, active: { centerText: "Cn",  italic: true, color: TOKENS.execute,    centerSize: 48, ring: true } },
  { key: "folder-screens",   title: "SCREENS",   idle: { centerText: "scr", italic: true, color: TOKENS.primary, centerSize: 42 }, active: { centerText: "scr", italic: true, color: TOKENS.primary, centerSize: 42 } },
];

// ─────────────────────────────────────────────────────────────────────────
// Render all SVGs to PNGs via rsvg-convert — emits 2 files per icon (idle, active)
// Returns: iconKey → { idle, active, title } with absolute file paths
// ─────────────────────────────────────────────────────────────────────────
type RenderedIcon = { idle: string; active: string; title: string };
function renderIcons(outDir: string): Record<string, RenderedIcon> {
  mkdirSync(outDir, { recursive: true });
  const result: Record<string, RenderedIcon> = {};
  for (const icon of ICONS) {
    const renderOne = (variant: "idle" | "active", spec: IconSpec) => {
      const svgPath = join(outDir, `${icon.key}-${variant}.svg`);
      const pngPath = join(outDir, `${icon.key}-${variant}.png`);
      writeFileSync(svgPath, svg(spec));
      execSync(`rsvg-convert -w 144 -h 144 "${svgPath}" -o "${pngPath}"`, { stdio: "ignore" });
      return pngPath;
    };
    result[icon.key] = {
      idle: renderOne("idle", icon.idle),
      active: renderOne("active", icon.active),
      title: icon.title,
    };
  }
  return result;
}

// ─────────────────────────────────────────────────────────────────────────
// Manifest builders
// ─────────────────────────────────────────────────────────────────────────
function uuid(): string {
  return crypto.randomUUID();
}

/** Build a States[] entry with Stream Deck title overlay rendered on top. */
function stateEntry(imagePath: string, title: string): any {
  return {
    FontFamily: "",
    FontSize: 11,
    FontStyle: "",
    FontUnderline: false,
    Image: imagePath,
    OutlineThickness: 2,
    ShowTitle: true,
    Title: title,
    TitleAlignment: "bottom",
    TitleColor: "#ffffff",
  };
}

/** Standard OBS plugin action with title-bearing states. */
function obsAction(uuid_action: string, plugin_name: string, settings: any, icon: RenderedIcon, customTitle?: string): any {
  const title = customTitle ?? icon.title;
  return {
    ActionID: uuid(),
    LinkedTitle: true,
    Name: plugin_name,
    Plugin: { Name: "OBS Studio", UUID: "com.elgato.obsstudio", Version: "2.2.9.9" },
    Resources: null,
    Settings: settings,
    State: 0,
    States: [stateEntry(icon.idle, title), stateEntry(icon.active, title)],
    UUID: uuid_action,
  };
}

function actionScene(sceneName: string, icon: RenderedIcon): any {
  return obsAction("com.elgato.obsstudio.scene", "Scene", { target: "program", sceneName }, icon, icon.title);
}
function actionRecord(icon: RenderedIcon): any {
  return obsAction("com.elgato.obsstudio.record", "Record", { isInMultiAction: false }, icon);
}
function actionStream(icon: RenderedIcon): any {
  return obsAction("com.elgato.obsstudio.stream", "Stream", { isInMultiAction: false, longpress: false }, icon);
}
function actionMicMute(icon: RenderedIcon): any {
  return obsAction("com.elgato.obsstudio.mixeraudio", "Audio Mixer",
    { isInMultiAction: false, mode: "toggle", source: "Mic/Aux", step: 1, style: "static", type: "mute", volume: 0.5 },
    icon);
}
function actionMarker(icon: RenderedIcon): any {
  return obsAction("com.elgato.obsstudio.record.addchapter", "Chapter Marker", {}, icon);
}
function actionSourceVisibility(sourceName: string, icon: RenderedIcon, customTitle?: string): any {
  return obsAction("com.elgato.obsstudio.source", "Source Visibility", { sourceName }, icon, customTitle);
}
function actionStudioMode(icon: RenderedIcon): any {
  return obsAction("com.elgato.obsstudio.studiomode", "Studio Mode", {}, icon);
}
function actionTransitionStudio(icon: RenderedIcon): any {
  return obsAction("com.elgato.obsstudio.transitionstudio", "Transition", {}, icon);
}
function actionSceneTransition(transition: string, icon: RenderedIcon): any {
  return obsAction("com.elgato.obsstudio.transition", "Scene Transition", { duration: 0, transition }, icon);
}
function actionVirtCam(icon: RenderedIcon): any {
  return obsAction("com.elgato.obsstudio.virtualcam", "Virtual Camera", { isInMultiAction: false, longpress: false }, icon);
}
function actionReplayBuffer(icon: RenderedIcon): any {
  return obsAction("com.elgato.obsstudio.replaybuffer", "Replay Buffer", {}, icon);
}
function actionReplaySave(icon: RenderedIcon): any {
  return obsAction("com.elgato.obsstudio.replaybuffer.save", "Replay Buffer Save", {}, icon);
}
function actionRecordPause(icon: RenderedIcon): any {
  return obsAction("com.elgato.obsstudio.record.pause", "Record Pause", {}, icon);
}

function actionOpenFolder(profileUUID: string, icon: RenderedIcon): any {
  return {
    ActionID: uuid(),
    LinkedTitle: true,
    Name: "Create Folder",
    Plugin: { Name: "Create Folder", UUID: "com.elgato.streamdeck.profile.openchild", Version: "1.0" },
    Resources: null,
    Settings: { ProfileUUID: profileUUID },
    State: 0,
    States: [stateEntry(icon.idle, icon.title), stateEntry(icon.active, icon.title)],
    UUID: "com.elgato.streamdeck.profile.openchild",
  };
}

function actionBackToParent(icon: RenderedIcon): any {
  return {
    ActionID: uuid(),
    LinkedTitle: true,
    Name: "Parent Folder",
    Resources: null,
    Settings: {},
    State: 0,
    States: [stateEntry(icon.idle, icon.title), stateEntry(icon.active, icon.title)],
    UUID: "com.elgato.streamdeck.profile.backtoparent",
  };
}

function actionOpenURL(url: string, icon: RenderedIcon, customTitle?: string): any {
  const title = customTitle ?? icon.title;
  // openInBrowser: false → use system default app for URL scheme (raycast://, typefully://, etc.)
  //                       NOT the default browser, which can't handle custom schemes.
  return {
    ActionID: uuid(),
    LinkedTitle: true,
    Name: "Open",
    Plugin: { Name: "Open", UUID: "com.elgato.streamdeck.system.open", Version: "1.0" },
    Resources: null,
    Settings: { openInBrowser: false, path: url },
    State: 0,
    States: [stateEntry(icon.idle, title), stateEntry(icon.active, title)],
    UUID: "com.elgato.streamdeck.system.open",
  };
}

// ─────────────────────────────────────────────────────────────────────────
// Main
// ─────────────────────────────────────────────────────────────────────────
const [src, dst] = process.argv.slice(2);
if (!src || !dst) {
  console.error("usage: streamdeck-build <source.streamDeckProfile> <output.streamDeckProfile>");
  process.exit(1);
}

const work = mkdtempSync(join(tmpdir(), "sdbuild-"));
console.log(`work dir: ${work}`);

// 1. Unzip source
execSync(`unzip -oq "${src}" -d "${work}"`, { stdio: "inherit" });

// 2. Find the root profile dir (Profiles/<UUID>.sdProfile/)
const profilesRoot = join(work, "Profiles");
const rootProfileDirName = execSync(`ls "${profilesRoot}"`).toString().trim().split("\n")[0];
const rootProfileDir = join(profilesRoot, rootProfileDirName);
const subProfilesDir = join(rootProfileDir, "Profiles");

// 3. Read existing sub-profile UUIDs
const existingProfiles = execSync(`ls "${subProfilesDir}"`).toString().trim().split("\n");
console.log("Existing sub-profiles:", existingProfiles);

// Map known profile UUIDs to roles (read by parsing manifests for known signatures)
function readManifest(uuid: string): any | null {
  const path = join(subProfilesDir, uuid, "manifest.json");
  try { return JSON.parse(readFileSync(path, "utf8")); } catch { return null; }
}
function writeManifest(uuid: string, data: any) {
  const path = join(subProfilesDir, uuid, "manifest.json");
  writeFileSync(path, JSON.stringify(data));
}

// Classify each sub-profile by signature
const profileRoles: Record<string, string> = {};
for (const p of existingProfiles) {
  const m = readManifest(p);
  if (!m) continue;
  const actions = m.Controllers?.[0]?.Actions || {};
  const names = Object.values(actions).map((a: any) => a.Name);
  if (names.some(n => n === "Studio Mode")) profileRoles[p] = "obs";
  else if (names.filter(n => n === "Audio Mixer").length >= 5) profileRoles[p] = "audio";
  else if (names.filter(n => n === "Source Visibility").length >= 5) profileRoles[p] = "sources";
  else if (names.filter(n => n === "Scene").length >= 5) profileRoles[p] = "scenes";
  else profileRoles[p] = "landing";
}
console.log("Profile roles:", profileRoles);

const landingUUID = Object.entries(profileRoles).find(([, r]) => r === "landing")![0];
const obsUUID = Object.entries(profileRoles).find(([, r]) => r === "obs")![0];
const scenesUUID = Object.entries(profileRoles).find(([, r]) => r === "scenes")![0];
const audioUUID = Object.entries(profileRoles).find(([, r]) => r === "audio")![0];

// 4. Render all icons to a temp dir, then copy to each sub-profile's Images/ dir
const renderDir = join(work, "_icons");
const renderedIcons = renderIcons(renderDir);

function ensureImagesIn(profileUUID: string): string {
  const imgDir = join(subProfilesDir, profileUUID, "Images");
  mkdirSync(imgDir, { recursive: true });
  return imgDir;
}

/**
 * Copy idle + active PNGs into a sub-profile's Images/ directory and return
 * a refs object that exposes RenderedIcon objects with profile-relative paths.
 */
function copyIconsTo(profileUUID: string): Record<string, RenderedIcon> {
  const imgDir = ensureImagesIn(profileUUID);
  const refs: Record<string, RenderedIcon> = {};
  for (const [k, ico] of Object.entries(renderedIcons)) {
    const idleName = `${k}-idle.png`;
    const activeName = `${k}-active.png`;
    copyFileSync(ico.idle, join(imgDir, idleName));
    copyFileSync(ico.active, join(imgDir, activeName));
    refs[k] = { idle: `Images/${idleName}`, active: `Images/${activeName}`, title: ico.title };
  }
  return refs;
}

const imageRefs: Record<string, Record<string, RenderedIcon>> = {};
for (const profileUUID of [landingUUID, obsUUID, scenesUUID, audioUUID]) {
  imageRefs[profileUUID] = copyIconsTo(profileUUID);
}

// 5. Build the LANDING manifest (the new DuranteOS Stream page)
const L = imageRefs[landingUUID];
const landingManifest = {
  Controllers: [{
    Actions: {
      // Row 0 — 5 scene direct jumps (col 0-4) — title overlays show "01 INTRO" etc.
      "0,0": actionScene("01_Intro",         L["scene-01"]),
      "1,0": actionScene("02_Coding",        L["scene-02"]),
      "2,0": actionScene("03_Terminal_Only", L["scene-03"]),
      "3,0": actionScene("04_Break",         L["scene-04"]),
      "4,0": actionScene("05_Outro",         L["scene-05"]),
      // Row 1 — primary controls (state-pair toggles where applicable)
      "0,1": actionMicMute(L["mic"]),
      "1,1": actionRecord(L["rec"]),
      "2,1": actionStream(L["stream"]),
      "3,1": actionOpenFolder(/* screens folder UUID set below */ "SCREENS_PLACEHOLDER", L["folder-screens"]),
      "4,1": actionOpenFolder(/* dev folder UUID set below */ "DEV_PLACEHOLDER", L["folder-dev"]),
      // Row 2 — source toggles + folder links
      "0,2": actionSourceVisibility("Webcam",       L["cam"]),
      "1,2": actionSourceVisibility("Coding Frame", L["chat"]),  // brand strips toggle
      "2,2": actionSourceVisibility("Lower Third",  L["lt"]),
      "3,2": actionScene("04_Break",                L["brb"]),
      "4,2": actionOpenFolder(obsUUID,              L["folder-obs"]),
    },
    Type: "Keypad",
  }],
  Icon: "",
  Name: "DuranteOS Stream",
};

// 6. Build a NEW dev folder
const devUUID = uuid();
const devDir = join(subProfilesDir, devUUID.toUpperCase());
mkdirSync(devDir, { recursive: true });
const D = copyIconsTo(devUUID.toUpperCase());
// Dense Dev folder layout — 4 stream rituals + 7 phase swaps + 4 dev quickies.
const devManifest = {
  Controllers: [{
    Actions: {
      // Row 0 — stream rituals + post
      "0,0": actionBackToParent(D["back-parent"]),
      "1,0": actionOpenURL("raycast://script-commands/preshow",       D["preshow"]),
      "2,0": actionOpenURL("raycast://script-commands/endshow",       D["endshow"]),
      "3,0": actionOpenURL("raycast://script-commands/marker",        D["marker-label"]),
      "4,0": actionOpenURL("raycast://script-commands/post-x",        D["dev-post-x"]),
      // Row 1 — phase swap (Obs/Thn/Pln/Bld/Exe)
      "0,1": actionOpenURL("raycast://script-commands/phase-observe", D["phase-obs"]),
      "1,1": actionOpenURL("raycast://script-commands/phase-think",   D["phase-thn"]),
      "2,1": actionOpenURL("raycast://script-commands/phase-plan",    D["phase-pln"]),
      "3,1": actionOpenURL("raycast://script-commands/phase-build",   D["phase-bld"]),
      "4,1": actionOpenURL("raycast://script-commands/phase-execute", D["phase-exe"]),
      // Row 2 — phase verify/learn + new ritual quickies (status, session restart, replay save)
      "0,2": actionOpenURL("raycast://script-commands/phase-verify",  D["phase-ver"]),
      "1,2": actionOpenURL("raycast://script-commands/phase-learn",   D["phase-lrn"]),
      "2,2": actionOpenURL("raycast://script-commands/status",        D["status"]),
      "3,2": actionOpenURL("raycast://script-commands/session-start", D["session-start"]),
      "4,2": actionOpenURL("raycast://script-commands/replay-save",   D["replay-save"]),
    },
    Type: "Keypad",
  }],
  Icon: "",
  Name: "Dev · DOS Stream Control",
};

// 7. Wire devUUID into landing's 4,1 button
landingManifest.Controllers[0].Actions["4,1"].Settings.ProfileUUID = devUUID;

// 7a. Build the SCREENS folder — BetterDisplay mode switching via Raycast.
// Requires bd-{dawn,day,afternoon,evening,night,meeting,read,stream,cinema}.sh
// in ~/Durante/scripts/raycast/ to be enabled in Raycast → Script Commands.
const screensUUID = uuid();
const screensDir = join(subProfilesDir, screensUUID.toUpperCase());
mkdirSync(screensDir, { recursive: true });
const SC = copyIconsTo(screensUUID.toUpperCase());
const screensManifest = {
  Controllers: [{
    Actions: {
      // Row 0 — time-of-day curve (matches bd-apply.sh schedule)
      "0,0": actionOpenURL("raycast://script-commands/bd-dawn",      SC["screen-dawn"]),
      "1,0": actionOpenURL("raycast://script-commands/bd-day",       SC["screen-day"]),
      "2,0": actionOpenURL("raycast://script-commands/bd-afternoon", SC["screen-afternoon"]),
      "3,0": actionOpenURL("raycast://script-commands/bd-evening",   SC["screen-evening"]),
      "4,0": actionOpenURL("raycast://script-commands/bd-night",     SC["screen-night"]),
      // Row 1 — task-named modes + back-to-parent
      "0,1": actionOpenURL("raycast://script-commands/bd-meeting",   SC["screen-meeting"]),
      "1,1": actionOpenURL("raycast://script-commands/bd-read",      SC["screen-read"]),
      "2,1": actionOpenURL("raycast://script-commands/bd-stream",    SC["screen-stream"]),
      "3,1": actionOpenURL("raycast://script-commands/bd-cinema",    SC["screen-cinema"]),
      "4,1": actionBackToParent(SC["back-parent"]),
      // Row 2 — reserved
    },
    Type: "Keypad",
  }],
  Icon: "",
  Name: "Screens · Display Modes",
};
landingManifest.Controllers[0].Actions["3,1"].Settings.ProfileUUID = screensUUID;

writeManifest(landingUUID, landingManifest);
writeFileSync(join(devDir, "manifest.json"), JSON.stringify(devManifest));
writeFileSync(join(screensDir, "manifest.json"), JSON.stringify(screensManifest));

// 7b. Rewrite the Sources folder with our real OBS source-visibility toggles
const sourcesUUID = Object.entries(profileRoles).find(([, r]) => r === "sources")?.[0];
if (sourcesUUID) {
  const SR = copyIconsTo(sourcesUUID); // source refs
  const sourcesManifest = readManifest(sourcesUUID);
  sourcesManifest.Name = "Visibility";
  sourcesManifest.Controllers[0].Actions = {
    "0,0": actionBackToParent(SR["back-parent"]),
    // Row 0 · 02_Coding scene sources
    "1,0": actionSourceVisibility("Webcam",          SR["vis-eye"], "WEBCAM"),
    "2,0": actionSourceVisibility("Webcam Frame",    SR["vis-eye"], "W-FRAME"),
    "3,0": actionSourceVisibility("Lower Third",     SR["vis-eye"], "LOWER"),
    "4,0": actionSourceVisibility("Coding Frame",    SR["vis-eye"], "CODE-FR"),
    // Row 1 · displays + terminal scene
    "0,1": actionSourceVisibility("Display (Main)",     SR["vis-eye"], "D-MAIN"),
    "1,1": actionSourceVisibility("Display (Terminal)", SR["vis-eye"], "D-TERM"),
    "2,1": actionSourceVisibility("Terminal Frame",     SR["vis-eye"], "T-FRAME"),
    "3,1": actionSourceVisibility("BRB Overlay",        SR["vis-eye"], "BRB"),
    "4,1": actionSourceVisibility("Intro Overlay",      SR["vis-eye"], "INTRO"),
    // Row 2 · 05_Outro + leftover slots empty
    "0,2": actionSourceVisibility("Outro Overlay",      SR["vis-eye"], "OUTRO"),
    "1,2": actionSourceVisibility("Break Background",   SR["vis-eye"], "BRK-BG"),
    // 2,2  3,2  4,2 — intentionally empty
  };
  writeManifest(sourcesUUID, sourcesManifest);
}

// 8. Fix the Scenes folder — switch target preview→program, name actual scenes
const S = imageRefs[scenesUUID];
const sceneNames = ["01_Intro", "02_Coding", "03_Terminal_Only", "04_Break", "05_Outro"];
const sceneIconKeys = ["scene-01", "scene-02", "scene-03", "scene-04", "scene-05"];
const scenesManifest = readManifest(scenesUUID);
const newScenesActions: Record<string, any> = {
  "0,0": actionBackToParent(S["back-parent"]),
};
sceneNames.forEach((sceneName, i) => {
  // Row 1, cols 0-4
  newScenesActions[`${i},1`] = actionScene(sceneName, S[sceneIconKeys[i]]);
});
scenesManifest.Controllers[0].Actions = newScenesActions;
scenesManifest.Name = "Scenes";
writeManifest(scenesUUID, scenesManifest);

// 9. Rebuild the OBS Profile manifest with new icons
const O = imageRefs[obsUUID];
const obsManifest = readManifest(obsUUID);
obsManifest.Name = "OBS Studio";
obsManifest.Controllers[0].Actions = {
  // Row 0
  "0,0": actionOpenFolder(audioUUID, O["folder-audio"]),
  "1,0": actionStudioMode(O["studio-mode"]),
  "2,0": actionStream(O["stream"]),
  "3,0": actionRecord(O["rec"]),
  "4,0": actionRecordPause(O["rec-pause"]),
  // Row 1
  "0,1": actionOpenFolder(scenesUUID, O["folder-scenes"]),
  "1,1": actionTransitionStudio(O["transition"]),
  "2,1": actionSceneTransition("Fade",    O["scene-fade"]),
  "3,1": actionSceneTransition("Stinger", O["scene-stinger"]),
  "4,1": actionMarker(O["marker"]),
  // Row 2
  "0,2": actionBackToParent(O["back-parent"]),
  "1,2": actionMicMute(O["mic"]),
  "2,2": actionVirtCam(O["virtcam"]),
  "3,2": actionReplayBuffer(O["replay-buffer"]),
  "4,2": actionReplaySave(O["replay-save"]),
};
writeManifest(obsUUID, obsManifest);

// 10. Update the ROOT profile manifest to set the landing as the default page
const rootManifestPath = join(rootProfileDir, "manifest.json");
const rootManifest = JSON.parse(readFileSync(rootManifestPath, "utf8"));
rootManifest.Name = "DuranteOS";
rootManifest.Pages.Default = landingUUID;
rootManifest.Pages.Pages = [landingUUID, obsUUID, scenesUUID, audioUUID, devUUID.toUpperCase(), screensUUID.toUpperCase()];
writeFileSync(rootManifestPath, JSON.stringify(rootManifest));

// 11. Re-zip → output .streamDeckProfile
rmSync(renderDir, { recursive: true, force: true });
const dstAbs = dst.startsWith("/") ? dst : join(process.cwd(), dst);
rmSync(dstAbs, { force: true });
execSync(`cd "${work}" && zip -rq "${dstAbs}" .`, { stdio: "inherit" });

console.log(`✅ wrote ${dstAbs}`);
console.log(`open "${dstAbs}" to import into the Stream Deck app`);
