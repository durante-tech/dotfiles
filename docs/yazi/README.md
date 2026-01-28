# Yazi Configuration

Blazing fast terminal file manager written in Rust.

## Quick Reference

| Key | Action |
|-----|--------|
| `h` | Go to parent directory |
| `l` or `Enter` | Open file/enter directory |
| `j/k` | Move down/up |
| `g g` | Go to top |
| `G` | Go to bottom |
| `Space` | Select file |
| `V` | Visual select mode |
| `y` | Yank (copy) |
| `d` | Delete |
| `p` | Paste |
| `r` | Rename |
| `a` | Create file |
| `A` | Create directory |
| `/` | Search |
| `q` | Quit |

## Shell Integration

The `ya` function in zsh changes directory on exit:

```bash
ya              # Open yazi
# Navigate to desired directory
q               # Quit - shell now in that directory
```

## Opening in Tmux

`Ctrl+B > Ctrl+Y` opens yazi in a floating tmux popup.

## Aliases

| Alias | Command |
|-------|---------|
| `y` | `yazi` |
| `ya` | Yazi with cd-on-exit |

## File Location

```
yazi/.config/yazi/
├── yazi.toml    # Main config
├── theme.toml   # Colors and styling
└── keymap.toml  # Custom keybindings
```

## Features

- **Async I/O**: Non-blocking file operations
- **Image preview**: In supported terminals
- **Bulk rename**: Select files and rename with editor
- **Tab support**: Multiple directories in tabs
