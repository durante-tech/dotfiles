# New Tools Guide

Quick reference for the CLI tools added to your dotfiles setup.

---

## File Management

### Yazi - Terminal File Manager

```bash
y                    # Open yazi in current directory
ya                   # Open yazi, cd to last directory on exit
ya ~/Projects        # Open yazi in specific directory
```

**Keybindings (vim-style):**
| Key | Action |
|-----|--------|
| `h/j/k/l` | Navigate (left/down/up/right) |
| `Enter` | Open file/enter directory |
| `q` | Quit |
| `Space` | Toggle selection |
| `y` | Copy (yank) |
| `x` | Cut |
| `p` | Paste |
| `d` | Delete (trash) |
| `D` | Delete permanently |
| `a` | Create file/directory |
| `r` | Rename |
| `/` | Search |
| `z` | Jump with zoxide |
| `gg` | Go to top |
| `G` | Go to bottom |
| `.` | Toggle hidden files |
| `t` | New tab |
| `1-3` | Switch tabs |

**Quick jumps:**
- `gh` → Home
- `gc` → ~/.config
- `gd` → ~/dotfiles
- `gD` → ~/Downloads
- `gp` → ~/Projects

---

## Modern CLI Replacements

### procs - Better `ps`

```bash
ps                   # Aliased to procs - colorful process list
procs                # Same thing
procs -w             # Watch mode (auto-refresh)
procs --tree         # Process tree view
procs node           # Filter by name
procs -p 1234        # Show specific PID
```

### bottom (btm) - Better `top`/`htop`

```bash
top                  # Aliased to btm
htop                 # Aliased to btm
btm                  # Graphical system monitor
```

**Keybindings:**
| Key | Action |
|-----|--------|
| `e` | Toggle process tree |
| `s` | Sort by column |
| `/` | Search processes |
| `k` | Kill process |
| `Tab` | Switch widgets |
| `?` | Help |
| `q` | Quit |

### curlie - Better `curl`

```bash
curl https://api.github.com    # Aliased to curlie
curlie https://api.github.com  # Syntax-highlighted JSON response
curlie -v POST api.com data=x  # POST with verbose
```

### dust - Better `du`

```bash
du                   # Aliased to dust
dust                 # Visual disk usage tree
dust -d 2            # Limit depth to 2
dust ~/Projects      # Specific directory
dust -r              # Reverse sort (smallest first)
```

### broot - Interactive Tree

```bash
br                   # Aliased to broot
broot                # Interactive tree navigation
br -s                # Show sizes
br -h                # Show hidden files
br -w                # Whale mode (find large files)
```

**Inside broot:**
| Key | Action |
|-----|--------|
| `Enter` | Open/cd |
| `:e` | Edit file |
| `:cp` | Copy |
| `:mv` | Move |
| `:rm` | Remove |
| `/` | Search |
| `ctrl+q` | Quit |

---

## JSON & Data

### fx - Interactive JSON Viewer

```bash
json file.json       # Aliased to fx
fx file.json         # Interactive JSON explorer
curl api.com | fx    # Pipe JSON to fx
fx data.json '.key'  # Query specific key
```

**Inside fx:**
| Key | Action |
|-----|--------|
| `j/k` | Navigate |
| `Enter` | Expand/collapse |
| `.` | Start filter query |
| `e` | Edit mode |
| `y` | Copy value |
| `q` | Quit |

---

## Productivity

### navi - Interactive Cheatsheets

```bash
cheat                # Aliased to navi
navi                 # Browse cheatsheets with fzf
navi --query git     # Search for git commands
navi fn welcome      # Run specific function
```

**Features:**
- Select command → fills in template
- Press Tab to fill variables
- Custom cheatsheets in `~/.config/navi/`

### onefetch - Git Repo Summary

```bash
ginfo                # Aliased to onefetch
onefetch             # Show repo info (in git repo)
onefetch ~/project   # Specific repo
onefetch --no-art    # Text only
```

Shows: Languages, contributors, LOC, commits, license, etc.

---

## Neovim Additions

### oil.nvim - File Explorer as Buffer

```
-           Open parent directory
<leader>-   Open in floating window
```

**Inside oil buffer:**
- Edit like a normal buffer
- Save to apply changes (rename, delete, create)
- `q` to close

### faster.nvim - Big File Optimization

Automatically activates for files >1MB:
- Disables LSP, treesitter, syntax highlighting
- Speeds up macro execution
- No configuration needed

---

## Quick Reference Card

```
┌─────────────────────────────────────────────────────┐
│  FILES                                              │
│  y / ya        Yazi file manager (ya = cd on exit) │
│  br            Broot interactive tree              │
│  -             Oil.nvim (in nvim)                  │
├─────────────────────────────────────────────────────┤
│  SYSTEM                                             │
│  ps            procs - colorful processes          │
│  top / htop    btm - graphical monitor             │
│  du            dust - visual disk usage            │
├─────────────────────────────────────────────────────┤
│  DATA                                               │
│  json          fx - interactive JSON               │
│  curl          curlie - syntax highlighted         │
├─────────────────────────────────────────────────────┤
│  HELP                                               │
│  cheat         navi - interactive cheatsheets      │
│  ginfo         onefetch - git repo summary         │
└─────────────────────────────────────────────────────┘
```

---

## Tips

1. **Yazi + tmux**: Use `ya` to navigate, directory persists after exit
2. **btm in tmux popup**: Add to tmux.conf for quick access
3. **navi cheatsheets**: Add your own in `~/.config/navi/`
4. **fx for API debugging**: `curl api | fx` is faster than jq for exploration
5. **broot whale mode**: `br -w` quickly finds what's eating disk space

---

*Generated: 2025-12-23*
