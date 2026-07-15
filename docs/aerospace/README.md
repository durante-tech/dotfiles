# AeroSpace Configuration

i3-like tiling window manager for macOS with Alt-based keybindings.

## Quick Reference

| Key | Action |
|-----|--------|
| `Alt+H/J/K/L` | Focus left/down/up/right |
| `Alt+Shift+H/J/K/L` | Move window left/down/up/right |
| `Alt+Ctrl+H/J/K/L` | Swap window position |
| `Alt+Tab` | Previous workspace |
| `Alt+0` | Toggle last workspace |
| `Alt+Enter` | Open Ghostty terminal |
| `Alt+Shift+C` | Close window |
| `Alt+Shift+Space` | Toggle fullscreen |
| `Alt+R` | Reload config |
| `Alt+Shift+S` | Enter service mode (flatten tree, join-with, close-others) |
| `Ctrl+Shift+\` | Toggle sketchybar (via Karabiner — terminals swallow Option) |

## Workspaces

| Key | Workspace | Apps |
|-----|-----------|------|
| `Alt+1` | 1 | General (Built-in) |
| `Alt+2` | 2 | Secondary (Portrait) |
| `Alt+A` | AI | Claude, Codex, ChatGPT, Perplexity |
| `Alt+D` | Development | IDEs, Cursor, VS Code |
| `Alt+T` | Terminal | Ghostty, iTerm, terminals |
| `Alt+B` | Browser | Chrome, Safari, Firefox, Zen |
| `Alt+M` | Messaging | Slack, Discord, WhatsApp |
| `Alt+F` | Finder | Finder (floating) |

> **Note**: `Alt+N` (Notes) and `Alt+E` (Email) stay unbound — they are pt-BR accent dead keys. Reach those workspaces via Karabiner `Hyper+N` / `Hyper+E`; `persistent-workspaces` keeps them alive when empty.

### Move to Workspace

`Alt+Shift+<workspace key>` moves current window to that workspace.

## Layout Controls

| Key | Action |
|-----|--------|
| `Alt+/` | Toggle tiles horizontal/vertical |
| `Alt+,` | Toggle accordion layout |
| `Alt+.` | Toggle floating/tiling |
| `Alt+Shift+R` | Enter resize mode |

### Resize Mode

When in resize mode (`Alt+Shift+R`):
| Key | Action |
|-----|--------|
| `H/J/K/L` | Resize in direction |
| `B` | Balance window sizes |
| `Enter/Esc` | Exit resize mode |

## Monitor Assignment

Workspaces are pinned to monitors:

| Workspace | Monitor |
|-----------|---------|
| 1, B, D, F, M | Built-in Retina Display |
| 2, T | PORTRAIT-MONITOR |

## Auto-Assignments

Apps automatically move to workspaces:

| App Type | Workspace |
|----------|-----------|
| Browsers | B |
| IDEs | D |
| Terminals | T |
| Messaging | M |
| Notes (Obsidian, Notion, Claude) | N (auto-assign, no hotkey) |
| Finder | F (floating) |

## Integration

- **Sketchybar**: Receives workspace change events
- **JankyBorders**: Window borders (blue=active, grey=inactive)

## File Location

```
aerospace/.config/aerospace/aerospace.toml
```
