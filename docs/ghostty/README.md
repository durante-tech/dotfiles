# Ghostty Configuration

GPU-accelerated terminal emulator with tmux-style keybindings.

## Quick Reference

| Key | Action |
|-----|--------|
| `Cmd+B > R` | Reload config |
| `Cmd+B > C` | New window (`macos-titlebar-style = hidden` disallows tabs) |
| `Cmd+B > N` | New window |
| `Cmd+B > X` | Close surface |
| `Cmd+B > \` | Split right |
| `Cmd+B > -` | Split down |
| `Cmd+B > E` | Equalize splits |
| `Cmd+B > ,` | Quick terminal |
| `Cmd+I` | Toggle inspector |

## Split Navigation

| Key | Action |
|-----|--------|
| `Cmd+B > H` | Go to left split |
| `Cmd+B > J` | Go to bottom split |
| `Cmd+B > K` | Go to top split |
| `Cmd+B > L` | Go to right split |

## Appearance

| Setting | Value |
|---------|-------|
| Theme | Rose-pine |
| Font | JetBrainsMono Nerd Font 16pt |
| Opacity | 75% with 23px blur |
| Cursor | Block (`cursor-color = cell-foreground`), no blink |
| Titlebar | Hidden |

## Features

- **Ligatures enabled**: `==`, `=>`, `!=`, `>=`, `<=`
- **Option as Alt**: For terminal escape sequences
- **Mouse hide while typing**: Clean focus
- **No close confirmation**: Fast exit

## File Location

```
ghostty/.config/ghostty/
├── config           # Main configuration
└── themes/
    └── rosepine    # Color theme
```

## Notes

- Splits work independently from tmux
- `Shift+Enter` is not remapped (the old keybind conflicted with Claude Code multi-line input)
- Config reloads with `Cmd+Shift+,` (default) or `Cmd+B > R`
