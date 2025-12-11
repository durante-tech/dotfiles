# AeroSpace Window Manager Configuration

This configuration provides an i3-like tiling window manager experience on macOS with integrations for Sketchybar (status bar) and JankyBorders (window borders).

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
| Keybinding | Workspace | Monitor Assignment |
|------------|-----------|-------------------|
| `alt-d` | D (Development) | DEV-MAIN |
| `alt-t` | T (Terminal) | PORTRAIT-MONITOR |
| `alt-b` | B (Browser) | DEV-SECOND |
| `alt-m` | M (Messaging) | DEV-SECOND |
| `alt-f` | F (Finder) | DEV-SECOND |
| `alt-1/2/3/4/8/9` | Numbered | Any monitor |

### Move Window to Workspace
Use `alt-shift-<key>` to move the focused window:
- `alt-shift-d` → Move to Development
- `alt-shift-t` → Move to Terminal
- `alt-shift-b` → Move to Browser
- etc.

### Cross-Monitor
| Keybinding | Action |
|------------|--------|
| `alt-shift-tab` | Move workspace to next monitor |

---

## Modes

AeroSpace supports modal keybindings (like vim). Press the mode key to enter, `esc` or `enter` to exit.

### Resize Mode (`alt-shift-r`)
| Key | Action |
|-----|--------|
| `h` | Shrink width |
| `l` | Grow width |
| `k` | Shrink height |
| `j` | Grow height |
| `b` | Balance all sizes |
| `esc/enter` | Exit resize mode |

### Service Mode (`alt-shift-;`)
*Note: Currently commented out for Brazilian accent compatibility*

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
| Browsers (Chrome, Safari, Firefox, Zen, Arc) | B | Tiling |
| IDEs (VSCode, Cursor, Xcode, JetBrains) | D | Tiling |
| Terminals (iTerm2, Alacritty, Wezterm) | T | Tiling |
| Notes (Notion, Obsidian, Claude, ChatGPT) | N | Tiling |
| Messaging (Slack, Discord, WhatsApp, Teams) | M | Tiling |
| Email (Spark, Apple Mail) | E | Tiling |
| Finder | F | **Floating** |
| Utilities (1Password, BetterDisplay, etc.) | Current | **Floating** |

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
Some keybindings are disabled because `alt-<key>` produces accented characters:
- `alt-e` → ´ (acute accent)
- `alt-n` → ˜ (tilde)
- `alt-;` → … (ellipsis on some layouts)

Workaround: Use alternative keys or Karabiner to remap.

---

## Resources

- [AeroSpace Guide](https://nikitabobko.github.io/AeroSpace/guide)
- [AeroSpace Commands](https://nikitabobko.github.io/AeroSpace/commands)
- [AeroSpace Goodies](https://nikitabobko.github.io/AeroSpace/goodies)
- [Sketchybar Docs](https://felixkratz.github.io/SketchyBar/)
- [JankyBorders](https://github.com/FelixKratz/JankyBorders)
