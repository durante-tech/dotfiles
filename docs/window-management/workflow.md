# Window Management Workflow

How to use AeroSpace and Karabiner together for full keyboard-driven window management on macOS.

## The System

| Tool | Role | Modifier |
|------|------|----------|
| **AeroSpace** | Tiling window manager (position, resize, workspaces) | `Alt` |
| **Karabiner** | Key remapping (Hyper key, sublayers, app launches) | `CapsLock` (Hyper) |
| **SketchyBar** | Status bar (workspace indicators, system info) | Visual feedback |
| **JankyBorders** | Window border highlighting | Auto (launched by AeroSpace) |

These four tools form a unified layer. AeroSpace handles window geometry, Karabiner handles shortcuts, SketchyBar shows state, and JankyBorders shows focus.

## Daily Workflow: A Typical Session

### Morning Setup

```
1. Open Ghostty (terminal)          → Auto-moves to workspace T
2. Open Chrome (browser)            → Auto-moves to workspace B
3. Open Slack (messaging)           → Auto-moves to workspace M
4. Open Notion (notes)              → Auto-moves to workspace N

You didn't move anything. AeroSpace's on-window-detected rules did it.
```

### Switching Context

```
Alt+T     → Terminal workspace (coding)
Alt+B     → Browser workspace (research/docs)
Alt+M     → Messaging (check Slack)
Alt+T     → Back to terminal
Alt+Tab   → Toggle between last two workspaces
```

### Working in Splits

```
Alt+Enter → New Ghostty window (tiled next to current)
Alt+H/L   → Focus left/right between splits
Alt+/     → Toggle layout (horizontal ↔ vertical)
```

## Workspace Map

Each workspace has a letter, a purpose, and an assigned monitor.

| Key | Workspace | Monitor | Auto-Assigned Apps |
|-----|-----------|---------|-------------------|
| `Alt+1` | General | Laptop | (none — manual) |
| `Alt+2` | Secondary | Portrait | (none — manual) |
| `Alt+D` | Development | Laptop | VS Code, Cursor, JetBrains IDEs, Xcode |
| `Alt+T` | Terminal | Portrait | Ghostty, Alacritty, WezTerm, iTerm2 |
| `Alt+B` | Browser | Laptop | Chrome, Safari, Firefox, Arc, Zen |
| `Alt+M` | Messaging | Laptop | Slack, Discord, Telegram, Teams, WhatsApp |
| `Alt+F` | Finder | Laptop | Finder (floating layout) |

**Note:** Workspaces N (Notes) and E (Email) exist but their `alt-n` / `alt-e` bindings are currently commented out to avoid conflicts with Brazilian accent input. Access them via the Hyper key instead.

### Auto-Assignment Rules

AeroSpace moves windows automatically based on `[[on-window-detected]]` rules in the config. When you open Chrome, it goes to workspace B. When you open Ghostty, it goes to T.

You never need to manually move common apps.

### Moving Windows Manually

For apps without auto-assignment rules:

```
Alt+Shift+T    → Move current window to Terminal workspace
Alt+Shift+B    → Move current window to Browser workspace
Alt+Shift+D    → Move current window to Development workspace
Alt+Shift+1    → Move current window to workspace 1
```

## Navigation Reference

### Focus (Move Attention)

| Keys | Action |
|------|--------|
| `Alt+H` | Focus window to the left |
| `Alt+J` | Focus window below |
| `Alt+K` | Focus window above |
| `Alt+L` | Focus window to the right |
| `Alt+[` | Cycle to previous window (DFS order) |
| `Alt+]` | Cycle to next window (DFS order) |

### Move (Reposition Window)

| Keys | Action |
|------|--------|
| `Alt+Shift+H` | Move window left |
| `Alt+Shift+J` | Move window down |
| `Alt+Shift+K` | Move window up |
| `Alt+Shift+L` | Move window right |

### Swap (Exchange Positions)

| Keys | Action |
|------|--------|
| `Alt+Ctrl+H` | Swap with left window |
| `Alt+Ctrl+J` | Swap with window below |
| `Alt+Ctrl+K` | Swap with window above |
| `Alt+Ctrl+L` | Swap with right window |

### Layout

| Keys | Action |
|------|--------|
| `Alt+/` | Cycle: tiles horizontal → vertical |
| `Alt+,` | Toggle accordion layout |
| `Alt+.` | Toggle floating ↔ tiling |
| `Alt+Shift+Space` | Toggle fullscreen |
| `Alt+Shift+C` | Close window |
| `Alt+Enter` | Open new Ghostty |

### Resize

**Quick resize** (from main mode):

| Keys | Action |
|------|--------|
| `Alt+Shift+-` | Shrink (50 units) |
| `Alt+Shift+=` | Grow (50 units) |

**Resize mode** (for precise control):

```
Alt+Shift+R    → Enter resize mode
  h            → Shrink width
  j            → Grow height
  k            → Shrink height
  l            → Grow width
  b            → Balance all sizes
  Enter / Esc  → Exit resize mode
```

### Monitor Management

| Keys | Action |
|------|--------|
| `Alt+Tab` | Switch to last workspace (back-and-forth) |
| `Alt+Shift+Tab` | Move workspace to next monitor |

## Karabiner Hyper Key

CapsLock becomes the Hyper key (`Ctrl+Alt+Shift+Cmd` simultaneously):

- **Tap** CapsLock → Escape (great for Vim)
- **Hold** CapsLock → Hyper modifier

### Direct Shortcuts (Hyper + Key)

| Keys | Action |
|------|--------|
| `Hyper+T` | Go to workspace T (Terminal) |
| `Hyper+B` | Go to workspace B (Browser) |
| `Hyper+D` | Go to workspace D (Development) |
| `Hyper+M` | Go to workspace M (Messaging) |
| `Hyper+F` | Go to workspace F (Finder) |
| `Hyper+1` | Go to workspace 1 |
| `Hyper+2` | Go to workspace 2 |
| `Hyper+X` | Raycast AI Chat |
| `Hyper+,` | Start Focus Session |
| `Hyper+.` | Raycast Notes |

### Sublayers (Hold Hyper + Hold Key, Then Tap)

Sublayers are like modes. You hold the Hyper key plus a mode key, then tap action keys.

**IMPORTANT: This is a chord, not a sequence.**

```
WRONG:  Press Hyper+O → Release O → Press M
RIGHT:  HOLD Hyper → HOLD O → TAP M → Release all
```

#### `Hyper+O` → App Launcher

| Tap | App |
|-----|-----|
| `m` | Obsidian |
| `n` | Notion |
| `d` | Discord |
| `i` | Messages |
| `p` | Music |
| `v` | VS Code |
| `c` | Chrome |
| `w` | WezTerm |

#### `Hyper+W` → Window Positioning

| Tap | Action |
|-----|--------|
| `h` | Left half |
| `j` | Bottom half |
| `k` | Top half |
| `l` | Right half |
| `Enter` | Maximize |
| `y` / `o` | Previous / next desktop |
| `u` / `i` | Previous / next tab |
| `n` / `m` | Next window / focus next |
| `d` | Next display |
| `;` | Hide window |

#### `Hyper+S` → System Controls

| Tap | Action |
|-----|--------|
| `u` / `j` | Volume up / down |
| `i` / `k` | Brightness up / down |
| `l` | Lock screen |
| `p` | Play/pause |
| `;` | Fast forward |
| `d` | Do Not Disturb toggle |
| `t` | Toggle dark/light mode |
| `c` | Open camera |

#### `Hyper+V` → Vim Arrow Keys (Everywhere)

| Tap | Action |
|-----|--------|
| `h/j/k/l` | Arrow keys (left/down/up/right) |
| `u` / `i` | Page down / Page up |

Use this in any app that doesn't have native vim keys.

#### `Hyper+C` → Media

| Tap | Action |
|-----|--------|
| `p` | Play/pause |
| `n` | Next track |
| `b` | Previous track |

#### `Hyper+R` → Raycast Tools

| Tap | Action |
|-----|--------|
| `c` | Color picker |
| `e` | Emoji picker |
| `n` | Raycast notes |
| `h` | Clipboard history |
| `p` | Confetti |

## Floating Apps

Some apps are always floating (never tiled):

- Finder
- Shottr (screenshots)
- 1Password
- BetterDisplay
- Docker Desktop
- Chromium (Playwright browsers)
- Logi Options

## SketchyBar Integration

SketchyBar shows workspace indicators on the top bar. When you switch workspaces, the indicator updates via `exec-on-workspace-change`:

```
[1] [2] [D] [T] [B] [M] [F]
         ↑
    Current workspace highlighted
```

JankyBorders adds colored borders: blue for the focused window, grey for others.

## Common Workflows

### Workflow 1: Code + Reference Side by Side

```
Alt+T              # Terminal workspace
Alt+Enter          # Open second Ghostty
Alt+L              # Focus right pane
# Open docs in one, code in the other
Alt+H / Alt+L      # Switch between them
```

### Workflow 2: Quick Slack Check

```
Alt+M              # Jump to Messaging
# Read/reply to messages
Alt+Tab            # Back to wherever you were
```

### Workflow 3: Research + Implement

```
Alt+B              # Browser: research docs
Alt+T              # Terminal: implement
Alt+Tab            # Toggle between the two
```

### Workflow 4: Multi-Monitor Layout

```
Laptop:   [D] Development  |  [B] Browser  |  [M] Messaging
Portrait: [T] Terminal      |  [2] Secondary

# Move something to the other monitor:
Alt+Shift+Tab      # Move entire workspace to next monitor
Alt+Shift+T        # Move window to Terminal workspace (portrait)
```

### Workflow 5: Fullscreen Focus

```
Alt+Shift+Space    # Fullscreen current window
# ... deep work ...
Alt+Shift+Space    # Back to tiled layout
```

## Configuration

### Changing Workspace Assignments

Edit `aerospace/.config/aerospace/aerospace.toml`:

```toml
# Change which monitor gets which workspace
[workspace-to-monitor-force-assignment]
T = '^YOUR-MONITOR-NAME$'   # Get names from: aerospace list-monitors
```

### Adding App Auto-Assignment

```toml
[[on-window-detected]]
if.app-id = 'com.example.myapp'    # Get app-id from: mdls -name kMDItemCFBundleIdentifier /Applications/MyApp.app
run = "move-node-to-workspace D"
```

### Adjusting Gaps

```toml
[gaps]
inner.horizontal = 15    # Between windows
inner.vertical = 15
outer.left = 15          # From screen edges
outer.bottom = 15
outer.right = 15
outer.top = 15           # Or per-monitor: [{ monitor."Name" = 50 }, 15]
```

## Quick Reference

| Task | Keys |
|------|------|
| Switch workspace | `Alt+T/B/D/M/F/1/2` |
| Move window to workspace | `Alt+Shift+T/B/D/M/F/1/2` |
| Focus window | `Alt+H/J/K/L` |
| Move window | `Alt+Shift+H/J/K/L` |
| Swap windows | `Alt+Ctrl+H/J/K/L` |
| Toggle fullscreen | `Alt+Shift+Space` |
| Change layout | `Alt+/` (tiles), `Alt+,` (accordion), `Alt+.` (float) |
| Resize | `Alt+Shift+R` then `H/J/K/L`, or `Alt+Shift+-/=` |
| New terminal | `Alt+Enter` |
| Last workspace | `Alt+Tab` |
| Close window | `Alt+Shift+C` |
| Launch app | `Hyper+O` then tap app key |
| Lock screen | `Hyper+S` then `L` |

---

**Next:** [Daily Workflow](../getting-started/daily-workflow.md)
