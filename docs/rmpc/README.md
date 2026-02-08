# rmpc - Music Player Client

rmpc is a Rust-based TUI client for MPD (Music Player Daemon). It provides a vim-style interface for managing your music library.

**Requires**: MPD running (`mpd` command). See [MPD docs](../mpd/README.md).

## Quick Reference

| Key | Action |
|-----|--------|
| `p` | Play/pause |
| `>` / `<` | Next/previous track |
| `,` / `.` | Volume down/up |
| `q` | Quit |

## Navigation

| Key | Action |
|-----|--------|
| `j` / `k` | Move down/up |
| `h` / `l` | Left/right (collapse/expand) |
| `g` / `G` | Top/bottom of list |
| `Ctrl+H/J/K/L` | Navigate between panes |
| `1`-`4` | Switch tabs |
| `Tab` / `Shift+Tab` | Cycle tabs |

## Tabs

| Tab | Key | Content |
|-----|-----|---------|
| Queue | `1` | Current playlist |
| Playlists | `2` | Saved playlists |
| Library | `3` | Browse by directory |
| Artists | `4` | Browse by artist |
| Search | `F` | Search library |

## Queue Management

| Key | Action |
|-----|--------|
| `a` | Add to queue |
| `A` | Add all to queue |
| `d` | Remove from queue |
| `D` | Clear queue |
| `C` | Jump to currently playing |

## Playback Control

| Key | Action |
|-----|--------|
| `z` | Toggle repeat |
| `x` | Toggle random/shuffle |
| `c` | Toggle consume mode |
| `v` | Toggle single mode |
| `s` | Stop playback |

## Other

| Key | Action |
|-----|--------|
| `u` | Update database |
| `U` | Rescan database |
| `:` | Command mode |

## Theme

Custom Rose Pine + Catppuccin theme with:
- Orange active tab indicator
- Album art display (auto-detect, max 850x850px)
- Progress bar and scrollbar

## Tmux Access

```
Ctrl+B > Ctrl+M    # Opens rmpc in floating tmux window
```

## File Locations

```
rmpc/.config/rmpc/config.ron        # Main configuration
rmpc/.config/rmpc/themes/custom.ron # Color theme
```
