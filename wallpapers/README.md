# wallpapers/

Durante-themed wallpaper gallery, GLSL shaders for Plash, and the
hourly time-banded rotation that drives them.

## The Durante Gallery (10 pieces)

10 hand-curated, AI-generated wallpapers that visually express what
Durante / DOS *is*. Each piece carries a signature gold accent
(#D4A574) so the set reads as one cohesive collection. They live in
`~/Pictures/Wallpapers/` (not in this git repo — too large) and rotate
on a time-of-day curve.

| # | File | Theme | Orientation |
|---|------|-------|-------------|
| 01 | `01-telos.jpg` | Goal-oriented north star over indigo ridges | landscape |
| 02 | `02-voice.jpg` | Speech becoming form — concentric ripples | landscape |
| 03 | `03-skills.jpg` | Modular hexagonal lattice of capability tiles | portrait |
| 04 | `04-algorithm.jpg` | The 7-phase loop as a cosmic ouroboros | landscape |
| 05 | `05-studio.jpg` | Floating cloud-cathedral — the SaaS atelier | landscape |
| 06 | `06-hooks.jpg` | Vertical thread of golden pulses (lifecycle events) | portrait |
| 07 | `07-mempalace.jpg` | Receding gilded archways, the cosmic library | landscape |
| 08 | `08-sentinel.jpg` | Lone gold lighthouse at the cliff's edge | landscape |
| 09 | `09-council.jpg` | Robed silhouettes around a central gold flame | landscape |
| 10 | `10-dos.jpg` | Vertical OS boot-as-cosmos (the centerpiece) | portrait |

## Hourly time-banded rotation

`~/scripts/wallpaper-rotate.sh` fires every 3600 seconds via
`com.lucas.wallpaper-rotate` LaunchAgent. It picks orientation-matched
wallpapers per monitor from the band of the current hour:

| Hour band | Mood | Pool |
|-----------|------|------|
| **06–12 morning** | calm | 01-telos, 02-voice, 03-skills |
| **12–18 afternoon** | active | 04-algorithm, 05-studio, 06-hooks |
| **18–22 evening** | contemplative | 07-mempalace, 08-sentinel |
| **22–06 night** | deep | 09-council, 10-dos |

If a band has no portrait image (e.g. evening, night), portrait
monitors fall back to any portrait in the full pool.

### Manual control

```bash
wpn                    # fire rotation now (band-aware)
wpa                    # rotate from the FULL gallery (ignore band)
wp                     # show current wallpaper
wp <path>              # set a specific image
```

### LaunchAgent control

```bash
# Status
launchctl list | grep wallpaper-rotate

# Watch the rotation log
tail -f ~/Library/Logs/wallpaper-rotate.log

# Force one rotation now
launchctl kickstart -k gui/$(id -u)/com.lucas.wallpaper-rotate

# Stop / start
launchctl bootout   gui/$(id -u) ~/Library/LaunchAgents/com.lucas.wallpaper-rotate.plist
launchctl bootstrap gui/$(id -u) ~/Library/LaunchAgents/com.lucas.wallpaper-rotate.plist
```

### Per-workspace overrides (optional)

The AeroSpace `exec-on-workspace-change` hook still calls
`wallpaper-workspace.sh` — drop a `workspace-<NAME>.jpg` into
`~/Pictures/Wallpapers/` and switching to that workspace will paint
that specific image (overriding whatever the rotation chose). Useful
if you want a pinned image for a specific context.

## GLSL shaders for Plash

```
shaders/
├── matrix.html    # Matrix-style digital rain (Catppuccin green)
├── aurora.html    # Slow aurora curtains (teal/mauve/sky)
└── flowfield.html # Domain-warped fbm plasma (blue/lavender/pink)
```

In Plash: **Add Website → Local file → wallpapers/shaders/<name>.html**.
60fps, sub-1% CPU on M-series, self-contained no-network pages.

```bash
wps matrix      # open matrix shader in Plash
wps aurora
wps flowfield
```

## Why this design

- **Time bands** match the day's mood: morning is light, evening is
  contemplative. The wallpaper *follows* you instead of being random
  noise.
- **Orientation-aware** so the portrait monitor always gets a portrait
  composition, not a stretched landscape.
- **Signature gold** (#D4A574) appears in every piece — gives the
  10-image set gallery cohesion. Catppuccin Mocha for the rest of
  the palette to match the terminal stack.
- **Stow-managed LaunchAgent** — fully reproducible on a fresh
  machine via `stow launchagents` + `launchctl bootstrap`.

## Archive

The original 6 generic-themed wallpapers (workspace-D/B/M/N/T/default)
live at `~/Pictures/Wallpapers/.archive-pre-durante/`. Move them back
to the parent dir if you ever want them again — the script ignores
anything not matching `[0-9][0-9]-*.jpg`.
