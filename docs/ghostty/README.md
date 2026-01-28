# Ghostty Configuration

GPU-accelerated terminal emulator with tmux-style keybindings.

## Quick Reference

| Key | Action |
|-----|--------|
| `Cmd+B > R` | Reload config |
| `Cmd+B > C` | New tab |
| `Cmd+B > N` | New window |
| `Cmd+B > X` | Close surface |
| `Cmd+B > \` | Split right |
| `Cmd+B > -` | Split down |
| `Cmd+B > E` | Equalize splits |
| `Cmd+B > ,` | Quick terminal |
| `Cmd+I` | Toggle inspector |

## Tab Navigation

| Key | Action |
|-----|--------|
| `Cmd+B > 1-9` | Go to tab N |

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
| Cursor | Yellow block, no blink |
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
- `Shift+Enter` sends literal newline (useful in some apps)
- Config reloads with `Cmd+Shift+,` (default) or `Cmd+B > R`
