# wallpapers/

Wallpaper assets and GLSL shader pages for the Plash + AeroSpace stack.

## Layout

```
wallpapers/
├── README.md          # this file
└── shaders/
    ├── matrix.html    # Matrix-style digital rain (green, Catppuccin)
    ├── aurora.html    # Slow aurora curtains (teal/mauve/sky)
    └── flowfield.html # Domain-warped fbm plasma (blue/lavender/pink)
```

## How to use

### Live shader as wallpaper (Plash)

1. Install Plash from the Mac App Store: <https://sindresorhus.com/plash>
2. In Plash, **Add Website** → choose **Local file** → pick one of `shaders/*.html`
3. Done. Each shader is self-contained, runs at 60fps, sub-1% CPU on M-series.
4. For multi-monitor: add the same file twice, set per-display in Plash preferences.

### Per-workspace wallpaper switching (AeroSpace)

`aerospace.toml` has an `exec-on-workspace-change` hook that calls
`scripts/wallpaper-workspace.sh` with the focused workspace name.

The script looks up `~/Pictures/Wallpapers/workspace-<NAME>.jpg` and applies it.
Drop named files into `~/Pictures/Wallpapers/`:

| File | Triggers on workspace |
|------|----------------------|
| `workspace-1.jpg` | Workspace 1 |
| `workspace-2.jpg` | Workspace 2 |
| `workspace-B.jpg` | Browser |
| `workspace-D.jpg` | Development |
| `workspace-T.jpg` | Terminal |
| `workspace-M.jpg` | Messaging |
| `workspace-N.jpg` | Notes |
| `workspace-E.jpg` | Email |
| `default.jpg` | fallback when no per-workspace file exists |

### CLI control

```bash
wp                              # show current wallpaper
wp ~/Pictures/Wallpapers/space-portrait.jpg   # set wallpaper
wpr                             # random wallpaper from ~/Pictures/Wallpapers
wps shaders/matrix.html         # shortcut: open shader in Plash
```

## Adding more shaders

Drop any Shadertoy shader into a new `.html` file. The template expects the
fragment shader to use these uniforms (the file already provides them):

```glsl
uniform vec2  iResolution;  // window size in pixels (DPR-scaled)
uniform float iTime;        // seconds since page load
```

Copy `flowfield.html` as a starting template — replace only the fragment shader
body. The vertex shader, GL setup, and resize handlers are boilerplate.

## Why these three

- **matrix.html** — pairs with your existing `matrix-rain.mp4`, but as a true
  shader (zero file size, infinite resolution, GPU-rendered).
- **aurora.html** — calm ambient layer for focus work; designed to read well
  through a 75% opacity Ghostty.
- **flowfield.html** — Catppuccin Mocha palette mapped onto a domain-warped
  fbm; same color story as the rest of your terminal stack.
