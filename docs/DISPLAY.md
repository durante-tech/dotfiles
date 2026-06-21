# Display & monitor configuration

How the two-panel rig (16" MacBook Pro Liquid Retina XDR + Samsung 28" 4K) is
driven, and the deliberate decisions behind it. Audited 2026-06-20 (BetterDisplay
v4.4.0, Pro unlocked); the rig is near its hardware ceiling — most "unused"
capabilities are intentionally unused (see below).

## Two independent axes

| Axis | Owner | State file | What it controls |
|------|-------|-----------|------------------|
| **Layout** (resolution / rotation / origin) | `display-restore.sh` (displayplacer) | `~/.cache/bd-profile` | which of the 5 profiles is active |
| **Brightness / color** (DDC + EDR) | `bd-apply.sh` (betterdisplaycli) | `~/.cache/bd-state` | time/task brightness mode |

These never collide: layout is resolution, brightness is DDC/EDR.

## Layout profiles — `display-restore.sh [profile] [--force|--dry-run]`

| Profile | Built-in | Samsung | Notes |
|---------|----------|---------|-------|
| `--daily` (default) | 1728×1117 | 1920×1080 | true integer-2x, sharpest |
| `--stream` | 1728×**1080** | 1920×1080 | clean OBS 2:1 → 1080 canvas |
| `--hires` | 1728×1117 | 2560×1440 HiDPI | ~78% more area, slightly soft |
| `--native` | 3456×2234 | 3840×2160 | 1x native, pixel-perfect, UI tiny |
| `--portrait` | 1728×1117 | 1080×1920 (rot 90°) | 1920px crisp vertical |

**Sharpness invariant:** true integer-2x = logical×2 == panel native (zero scaling).
Unique per panel; "more space" always means HiDPI supersampling (softer). See
`memory/display-true-2x-canonical-layout.md`.

**Wake persistence:** `display-restore.sh` writes the active profile to
`~/.cache/bd-profile`; `bd-wake.sh` re-applies it on wake. Without this, sleep/wake
reverted everything to daily (fixed 2026-06-20).

## Brightness / color — `bd-apply.sh <mode>`

Modes: `dawn day afternoon evening night` (time) + `meeting read stream cinema` (task).
Built-in uses XDR P3-1600 with EDR software-brightness upscale; the Samsung is a
**color-reference** display — only brightness follows the mode, white point + contrast
are pinned neutral on every mode. Direct readback-verified DDC writes (NOT favoriteMode
— see below). `bd-apply.sh verify` diffs live state vs intent and prints an EDR-headroom
diagnostic.

**Automation:**
- 5 launchd timers (`com.lucas.bd-{dawn,day,afternoon,evening,night}`) fire at fixed hours.
- `bd-lmu-watch` polls ambient light every 60s and switches mode on bucket transitions.
- `bd-wake.sh` (sleepwatcher `~/.wakeup`) re-applies layout + brightness on wake.
- `BD_SOURCE` tags each apply in the log: `timer` | `wake` | `lmu` | `manual`.

**Ambient source:** `betterdisplaycli get --ambientLight` (the ONLY live ambient
surface on this Apple Silicon — every ioreg ALS class is empty here; the ioreg ladder
is a fallback for other hardware). The earlier "Screen Recording permission" theory was
wrong. A dead sensor now raises a `bd_mode` sketchybar alert after ~5min.

> **Repo-tracking gap:** the 5 launchd plists live only in `~/Library/LaunchAgents`,
> not in this repo. Bringing them into a stow package is a worthwhile follow-up so the
> `BD_SOURCE` instrumentation + schedule survive a fresh machine setup.

## Deliberate decisions (do NOT "fix" these)

- **Color depth is maxed.** Built-in exposes 8-bit only at native (macOS dithers);
  Samsung is already 10-bit RGB Full SDR at its 4K/60 ceiling. 12-bit needs blurry
  YCbCr 4:2:2. `connectionMode` is not an improvement axis.
- **Night Shift stays OFF** — `bd-apply.sh` owns color temperature per mode; enabling
  Night Shift would double-shift the white point. (Verified off 2026-06-20.)
- **True Tone is ON** — it's a single GLOBAL toggle affecting only the built-in XDR
  panel (the Samsung has no Apple ambient hardware). Benign for daily work; turn off
  only if the built-in is ever used for reference-grade grading.
- **Notch stays ON** in all profiles — notchless would shorten logical height off 1080
  and break the stream profile's clean 2:1 supersample.
- **`set -u` only, never `set -e`** — the readback-retry loops in `bd-apply.sh` treat a
  `betterdisplaycli set` exit code as a lie (DDC writes no-op silently but exit 0); the
  `(( cond )) &&` idioms return 1 on false by design. `set -e` would abort both.
- **`favoriteMode` is a manual recovery fallback, not a migration target** — the
  direct-set path adds per-feature readback verification favoriteMode lacks.

## Deliberately-unused BetterDisplay Pro capabilities

Pro is unlocked, but these are correctly skipped: **virtual screens** (crash AeroSpace —
verified hard constraint), **BD stream/pip overlays** (would fight displayplacer as a
2nd scaler), **`protectResolution`/`protectRefreshRate`** (don't cover rotation or
multi-display origin, fight the profile switches), **`sendCEC`** (no TV in the chain),
**grayscale/inverted** (accessibility, not workflow). The only genuine win adopted was
`--ambientLight`.

## Deferred / optional

- **ColorSync declutter** — archiving dead ICC profiles is cosmetic; verify their actual
  location before moving anything, and never touch the two active display UUIDs
  (`37D8832A…` built-in, `E3434867…` Samsung).
