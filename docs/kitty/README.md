# Kitty - Terminal Emulator

> **Status: Backup** — Mirrors [Ghostty](../ghostty/README.md) configuration. Available as a fallback terminal.

Kitty was configured to match Ghostty feature-for-feature, providing a backup GPU-accelerated terminal option.

## Configuration Summary

| Setting | Value |
|---------|-------|
| Theme | Rose Pine |
| Font | JetBrainsMono Nerd Font, 14pt |
| Opacity | 0.75 |
| Background blur | 23px |
| Cell width | 95% |
| `macos_option_as_alt` | yes |

## Keybindings (Cmd+B prefix)

Mirrors Ghostty's tmux-style keybindings:

| Key | Action |
|-----|--------|
| `Cmd+B > r` | Reload config |
| `Cmd+B > c` | New tab |
| `Cmd+B > n` | New window |
| `Cmd+B > 1-9` | Jump to tab |
| `Cmd+B > \` | Split right |
| `Cmd+B > -` | Split down |
| `Cmd+B > h/j/k/l` | Navigate splits |
| `Cmd+B > e` | Equalize splits |
| `Cmd+B > ,` | Quick terminal overlay |

## File Locations

```
kitty/.config/kitty/kitty.conf      # Main configuration
kitty/.config/kitty/rosepine.conf   # Color theme
```
