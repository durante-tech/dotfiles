# w3m - Terminal Web Browser

w3m is a text-mode web browser integrated into the tmux workflow. Access it via `Ctrl+B > Ctrl+W` as a floating tmux popup.

## Quick Reference

| Key | Action |
|-----|--------|
| `j` / `k` | Scroll down/up |
| `h` / `l` | Scroll left/right |
| `Ctrl+F` / `Ctrl+B` | Page down/up |
| `Ctrl+D` / `Ctrl+U` | Half-page down/up |
| `gg` / `G` | Top/bottom of page |
| `o` | Open URL |
| `q` | Quit |

## Navigation

| Key | Action |
|-----|--------|
| `H` | Go back |
| `L` | Go forward |
| `Ctrl+O` | Go back (alternative) |
| `r` | Reload page |
| `0` / `$` | Line start/end |

## Tabs

| Key | Action |
|-----|--------|
| `t` | New tab |
| `T` | Tab menu |
| `Ctrl+H` / `Ctrl+L` | Previous/next tab |
| `d` | Close tab |

## Links & Search

| Key | Action |
|-----|--------|
| `f` | Move through links |
| `F` | Full link menu |
| `/` | Search forward |
| `?` | Search backward |
| `n` / `N` | Next/previous match |

## Bookmarks

| Key | Action |
|-----|--------|
| `a` | Add bookmark |
| `b` | View bookmarks |

## External

| Key | Action |
|-----|--------|
| `M` | Open current page in system browser |
| `v` | View page source |
| `:` | Command mode |

## Configuration

- **Editor**: nvim (for form editing)
- **Colors**: Catppuccin Mocha (via terminal)
- **Frames**: Rendered (`frame 1`)

## Tmux Integration

Access w3m as a floating popup in tmux:

```
Ctrl+B > Ctrl+W    # Opens w3m in floating window
```

## File Locations

```
w3m/.w3m/config     # Main configuration
w3m/.w3m/keymap     # Vi-style keybindings
w3m/.w3m/cookie     # Cookie storage
```
