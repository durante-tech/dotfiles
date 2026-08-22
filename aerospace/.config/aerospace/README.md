# AeroSpace Window Manager Configuration

This configuration provides an i3-like tiling window manager experience on macOS with integrations for Sketchybar (status bar) and JankyBorders (window borders).

> **Source of truth:** `aerospace/templates/aerospace.toml.template` in the
> dotfiles repo — *not* the `aerospace.toml` beside this file, which is
> gitignored output from `scripts/scripts/render-aerospace.sh`. Stow deploys
> this README into `~/.config/aerospace/`, where it sits next to the config and
> reads as authoritative, so it drifts silently whenever the template changes.
> When the two disagree the template wins; CLAUDE.md's AeroSpace section is the
> maintained prose summary.

## Quick Reference

### Modifier Key
All keybindings use **`alt`** (Option) as the primary modifier.

---

## Navigation & Focus

| Keybinding | Action | Description |
|------------|--------|-------------|
| `alt-h/j/k/l` | Focus left/down/up/right | Vim-style window focus |
| `alt-[` | Focus DFS previous | Cycle backwards through ALL windows (depth-first) |
| `alt-]` | Focus DFS next | Cycle forwards through ALL windows (depth-first) |
| `alt-tab` | Workspace back-and-forth | Toggle between last two workspaces |
| `alt-0` | Workspace back-and-forth | Same as alt-tab |

### DFS Navigation Explained
DFS (Depth-First Search) navigation cycles through **all windows across all workspaces** in a predictable order. Unlike directional focus (h/j/k/l), this lets you quickly find any window without knowing its position.

---

## Window Management

| Keybinding | Action | Description |
|------------|--------|-------------|
| `alt-shift-h/j/k/l` | Move window | Move focused window in direction |
| `alt-ctrl-h/j/k/l` | **Swap window** | Exchange position with adjacent window |
| `alt-shift-minus` | Resize smaller | Shrink window by 50px |
| `alt-shift-equal` | Resize larger | Grow window by 50px |
| `alt-shift-space` | Fullscreen | Toggle fullscreen mode |
| `alt-shift-c` | Close window | Close focused window |

### Swap vs Move
- **Move** (`alt-shift-*`): Relocates your window to a new position
- **Swap** (`alt-ctrl-*`): Exchanges positions with the neighbor window (both windows move)

---

## Layouts

| Keybinding | Action | Description |
|------------|--------|-------------|
| `alt-/` | Toggle tiles | Switch between horizontal/vertical tiling |
| `alt-,` | Toggle accordion | Switch between horizontal/vertical accordion |
| `alt-.` | Toggle floating | Switch window between floating and tiling |

### Layout Types
- **Tiles**: Windows split the space equally (like i3 default)
- **Accordion**: Windows stack with tabs, one visible at a time (like i3 tabbed)
- **Floating**: Window floats freely, not managed by tiling

---

## Workspaces

### Switch Workspace

Monitor names are per-machine, so the template holds
`@DOTFILES_MONITOR_BUILTIN@` / `@DOTFILES_MONITOR_EXTERNAL@` sentinels that
`render-aerospace.sh` substitutes from `~/.config/dotfiles/personal.env`. The
column below therefore names the *role*, not a panel — nothing is called
DEV-MAIN or DEV-SECOND.

| Keybinding | Workspace | Monitor |
|------------|-----------|---------|
| `alt-1` | 1 (Main) | built-in |
| `alt-2` | 2 (Secondary) | external (portrait) |
| `alt-a` | A (AI — Claude, ChatGPT, Perplexity) | built-in |
| `alt-b` | B (Browser) | built-in |
| `alt-d` | D (Development) | built-in |
| `alt-m` | M (Messaging) | external (portrait) |
| `alt-t` | T (Terminal) | external (portrait) |
| `alt-w` | E (Email) | built-in |
| `alt-o` | N (Notes) | built-in |

`alt-e` and `alt-n` are pt-BR dead keys (acute / tilde), so E and N live on
`alt-w` and `alt-o`; Karabiner's Hyper+E / Hyper+N still reach them unchanged.
`alt-3` … `alt-9` are commented out in the template, and `alt-f` is deliberately
left FREE: workspace F was retired 2026-07-28 because Finder floats on the
current screen and F could never hold a window.

D sits on the built-in *opposite* T on purpose — editors and agents are watched
while the work happens in tmux on the portrait panel, so the two must not share
a monitor.

### Move Window to Workspace
`alt-shift-<same key>` moves the focused window instead of switching to it:

| Keybinding | Moves window to |
|------------|-----------------|
| `alt-shift-1` / `alt-shift-2` | 1 / 2 |
| `alt-shift-a` / `alt-shift-b` / `alt-shift-d` | A / B / D |
| `alt-shift-m` / `alt-shift-t` | M / T |
| `alt-shift-w` / `alt-shift-o` | E / N (the same dead-key substitutes) |

### Cross-Monitor
| Keybinding | Action |
|------------|--------|
| `alt-shift-tab` | Move workspace to next monitor |

---

## Modes

AeroSpace supports modal keybindings (like vim). Press the mode key to enter, `esc` or `enter` to exit. Three modes are bound: `alt-shift-r` resize, `alt-shift-s` service, and `alt-shift-x` bd-mode — the BetterDisplay chord, one key per display mode, driving `scripts/scripts/bd-apply.sh`.

### Resize Mode (`alt-shift-r`)
| Key | Action |
|-----|--------|
| `h` | Shrink width |
| `l` | Grow width |
| `k` | Shrink height |
| `j` | Grow height |
| `b` | Balance all sizes |
| `esc/enter` | Exit resize mode |

### Service Mode (`alt-shift-s`)
*Upstream's chord is `alt-shift-;`, which stays commented out in the template:
pt-BR accents come from Option dead keys, so Option+Shift+letter is safe and
`s` = service is mnemonic. The mode itself is LIVE — only the `;` binding is
commented out, not the mode.*

| Key | Action |
|-----|--------|
| `esc` | Reload config & exit |
| `r` | Reset/flatten workspace tree |
| `f` | Toggle floating/tiling |
| `backspace` | Close all windows except current |
| `alt-shift-h/j/k/l` | Join with adjacent container |

---

## Integrations

### Sketchybar (Status Bar)
Sketchybar displays workspace indicators at the top of your screen.

**How it works:**
1. AeroSpace triggers `aerospace_workspace_change` event on workspace switch
2. Sketchybar updates the visual indicator for the focused workspace
3. Click workspace indicators to switch directly

**Files:**
- `~/.config/sketchybar/sketchybarrc` - Main config
- `~/.config/sketchybar/plugins/aerospace.sh` - Workspace highlight script
- `~/.config/sketchybar/items/space.sh` - Workspace item definitions

### JankyBorders (Window Borders)
Adds colored borders to help identify the focused window.

**Current colors (Catppuccin):**
- Active: Blue (`0xff8aadf4`)
- Inactive: Grey (`0xff939ab7`)
- Width: 4px

**Customize:** Edit the `after-startup-command` in `aerospace.toml`:
```toml
'exec-and-forget borders active_color=0xff8aadf4 inactive_color=0xff939ab7 width=4.0'
```

**Options:**
- `active_color` / `inactive_color` - Hex colors (0xAARRGGBB format)
- `width` - Border thickness in pixels
- `style=round` - Rounded corners (add to command)

---

## Callbacks (Advanced)

### on-workspace-change
Triggers when you switch workspaces. Used for Sketchybar integration.

```toml
exec-on-workspace-change = ['/bin/bash', '-c',
    'sketchybar --trigger aerospace_workspace_change FOCUSED_WORKSPACE=$AEROSPACE_FOCUSED_WORKSPACE'
]
```

**Available env vars:**
- `$AEROSPACE_FOCUSED_WORKSPACE` - Current workspace name
- `$AEROSPACE_PREV_WORKSPACE` - Previous workspace name

### on-mode-changed
Triggers when you enter/exit a mode (like resize mode). Currently commented out.

**Important:** Unlike `exec-on-workspace-change`, this callback runs **AeroSpace commands**, not bash directly. Use `exec-and-forget` to run external scripts:

```toml
# Run sketchybar trigger when mode changes
on-mode-changed = ['exec-and-forget sketchybar --trigger mode_change MODE=$AEROSPACE_MODE']
```

**Available env vars:**
- `$AEROSPACE_MODE` - Current mode name
- `$AEROSPACE_PREV_MODE` - Previous mode name

**Ideas:**
- Show mode indicator in Sketchybar (e.g., "RESIZE" badge)
- Play a sound when entering resize mode
- Change border color based on mode

---

## Auto-Window Assignment

Windows are automatically moved to workspaces based on app:

| App Type | Workspace | Layout |
|----------|-----------|--------|
| Browsers (Chrome, Safari, Firefox, Zen, Arc, Dia) | B | Tiling |
| IDEs (VSCode, Cursor, Xcode, Zed, Android Studio, JetBrains, Godot, Frame0) | D | Tiling |
| Terminals (Ghostty, kitty, iTerm2, Alacritty, WezTerm) | T | Tiling |
| AI apps (Claude, ChatGPT, Perplexity, LM Studio, Wispr Flow) | A | Tiling |
| Notes (Notion, Obsidian, Apple Notes) | N | Tiling |
| Messaging (Slack, Discord, Telegram, Teams, WhatsApp, Signal) | M | Tiling |
| Email (Spark, Apple Mail) | E | Tiling |
| Finder | *current* | **Floating** |
| Screenshot tools (CleanShot X, Shottr) | *current* | **Floating** |
| Playwright Chromium | *current* | **Floating** |
| Utilities (1Password, BetterDisplay, Stream Deck, Logi, Docker) | *current* | **Floating** |

Claude and ChatGPT are on **A**, not N — A is the AI-surface workspace, N is
Notion/Obsidian/Notes. Finder has no workspace: it floats wherever you are,
which is why `alt-f` and workspace F were retired.

---

## Troubleshooting

### Reload Config
```bash
aerospace reload-config
# Or use keybinding: alt-r
```

### Check Status
```bash
aerospace list-workspaces --all
aerospace list-windows --all
aerospace list-monitors
```

### Restart Everything
```bash
# Kill and restart borders
pkill borders
borders active_color=0xff8aadf4 inactive_color=0xff939ab7 width=4.0 &

# Restart sketchybar
brew services restart sketchybar

# Reload aerospace
aerospace reload-config
```

### Brazilian Accent Conflicts
`alt-<key>` produces accented characters on a pt-BR layout. The affected
bindings were *moved*, not disabled — reaching for the documented key and
getting nothing is the failure this section exists to prevent:

| Dead key | Produces | Live binding |
|----------|----------|--------------|
| `alt-e` | ´ (acute) | `alt-w` → workspace E, `alt-shift-w` to move |
| `alt-n` | ˜ (tilde) | `alt-o` → workspace N, `alt-shift-o` to move |
| `alt-shift-;` | upstream service chord | `alt-shift-s` |

Karabiner's Hyper+E / Hyper+N still reach E and N unchanged.

---

## Resources

- [AeroSpace Guide](https://nikitabobko.github.io/AeroSpace/guide)
- [AeroSpace Commands](https://nikitabobko.github.io/AeroSpace/commands)
- [AeroSpace Goodies](https://nikitabobko.github.io/AeroSpace/goodies)
- [Sketchybar Docs](https://felixkratz.github.io/SketchyBar/)
- [JankyBorders](https://github.com/FelixKratz/JankyBorders)
