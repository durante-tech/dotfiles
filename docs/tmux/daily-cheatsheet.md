# Tmux Daily Cheatsheet

Quick reference for the most common tmux operations. Print this or keep it open!

> **Prefix Key:** `Ctrl+Space` (Press and release before each command)

## 🎯 Top 10 Most Used

| Action | Keys | Notes |
|--------|------|-------|
| Split vertical | `C-Space \|` | Side by side |
| Split horizontal | `C-Space -` | Top and bottom |
| Switch projects | `C-Space o` | SessionX fuzzy finder |
| New window | `C-Space c` | Like a new tab |
| Next/prev window | `C-Space n/p` | Navigate tabs |
| **Detach** | `C-Space D` | **Capital D!** Leave running |
| **Config menu** | `C-Space d` | **Lowercase!** Edit dotfiles |
| Maximize pane | `C-Space m` | Zoom toggle |
| Lazygit | `C-Space C-g` | Git UI in float |
| Copy mode | `C-Space v` | Scroll and copy |

## 🗂️ Sessions (Projects)

### Starting & Attaching
| Command | Action |
|---------|--------|
| `tmux` | Start new session |
| `tmux new -s name` | Start named session |
| `tmux ls` | List sessions |
| `tmux attach` | Attach to last session |
| `tmux attach -t name` | Attach to specific session |
| `tmux kill-session -t name` | Kill session |

### Inside Tmux
| Keys | Action |
|------|--------|
| `C-Space D` | **Detach** (capital D - keeps running) |
| `C-Space d` | **Config menu** (lowercase - edit dotfiles) |
| `C-Space o` | SessionX - switch between projects |
| `C-Space f` | Sessionizer - find project directories |
| `C-Space n` | New session (prompts for name) |
| `C-Space $` | Rename current session |

## 🪟 Windows (Tabs)

### Managing Windows
| Keys | Action |
|------|--------|
| `C-Space c` | Create window |
| `C-Space ,` | Rename window |
| `C-Space &` | Kill window |
| `C-Space w` | List windows (interactive) |

### Navigation
| Keys | Action |
|------|--------|
| `C-Space n` | Next window |
| `C-Space p` | Previous window |
| `C-Space l` | Last window (toggle) |
| `C-Space 1-9` | Go to window 1-9 (starts at 1!) |
| `C-Space '` | Prompt for window index |

## 📱 Panes (Splits)

### Creating Panes
| Keys | Action |
|------|--------|
| `C-Space \|` | Split vertically |
| `C-Space -` | Split horizontally |

### Navigation
| Keys | Action |
|------|--------|
| `C-h` | Move left |
| `C-j` | Move down |
| `C-k` | Move up |
| `C-l` | Move right |
| `C-Space q` | Show pane numbers |
| `C-Space q <num>` | Jump to pane number |

### Resizing
| Keys | Action |
|------|--------|
| `C-Space h` | Resize left |
| `C-Space j` | Resize down |
| `C-Space k` | Resize up |
| `C-Space l` | Resize right |
| `C-Space z` | Toggle zoom (alias: `C-Space m`) |

### Managing
| Keys | Action |
|------|--------|
| `C-Space x` | Kill pane (confirm with y) |
| `C-Space !` | Break pane to new window |
| `C-Space {` | Move pane left |
| `C-Space }` | Move pane right |
| `C-Space Space` | Cycle through layouts |
| `C-Space C-o` | Rotate panes |

## 📋 Copy Mode (Vi-style)

### Entering/Exiting
| Keys | Action |
|------|--------|
| `C-Space v` | Enter copy mode |
| `q` | Exit copy mode |
| `C-c` | Exit copy mode |

### Navigation (Vi Keys)
| Keys | Action |
|------|--------|
| `h/j/k/l` | Move cursor |
| `w/b` | Next/previous word |
| `0/$` | Start/end of line |
| `gg/G` | Top/bottom of buffer |
| `C-u/C-d` | Half page up/down |
| `C-Space/C-f` | Full page up/down |

### Searching
| Keys | Action |
|------|--------|
| `/` | Search forward |
| `?` | Search backward |
| `n` | Next match |
| `N` | Previous match |

### Selecting & Copying
| Keys | Action |
|------|--------|
| `v` | Start selection |
| `V` | Line selection |
| `C-v` | Block selection |
| `y` | Copy (yank) selection |
| `Enter` | Copy and exit |

## 🎨 Floating Windows

| Keys | Action |
|------|--------|
| `C-Space C-g` | Lazygit (git UI) |
| `C-Space C-y` | Yazi (file manager) |
| `C-Space C-t` | Quick terminal |
| `C-Space C-m` | RMPC (music player) |
| `C-Space C-w` | W3m (web browser) |
| `Esc` | Close floating window |

## ⚙️ Configuration & Help

| Keys | Action |
|------|--------|
| `C-Space r` | Reload tmux config |
| `C-Space ?` | Show all keybindings |
| `C-Space d` | Config menu (dotfiles) |
| `C-Space :` | Enter command mode |

### Common Commands
| Command | Action |
|---------|--------|
| `:setw synchronize-panes on` | Type in all panes at once |
| `:setw synchronize-panes off` | Disable sync |
| `:swap-window -s 3 -t 1` | Swap window 3 with 1 |
| `:move-window -t session:` | Move window to another session |

## 🖱️ Mouse Support

**Your config has mouse enabled!**

| Action | How |
|--------|-----|
| Select pane | Click pane |
| Resize pane | Drag pane border |
| Scroll | Mouse wheel (in pane) |
| Copy text | Click and drag to select |
| Paste | Middle click (or `Shift+Insert`) |

## 🔄 Common Workflows

### Quick Project Switch
```
C-Space o              # Open SessionX
Type project name
Enter              # Switch instantly
```

### Git Workflow
```
C-Space C-g            # Open lazygit
# Stage, commit, push in UI
Esc                # Close
```

### Code + Tests + Server
```
Window 1: Editor
  C-Space c            # New window
  nvim

Window 2: Tests
  C-Space c            # New window
  C-Space |            # Split
  Left: npm test
  Right: npm run dev

C-Space 1/2            # Switch between them
```

### Multi-pane Setup
```
C-Space |              # Split vertical
C-Space -              # Split horizontal (right pane)
C-h/j/k/l          # Navigate
C-Space h/j/k/l        # Resize
C-Space m              # Zoom one pane
```

## 🎓 Pro Tips

### Navigation Speed
- `C-h/j/k/l` works in **both tmux and nvim**!
- No mental context switch between editor and terminal

### Session Management
- Always use named sessions: `tmux new -s projectname`
- Use `C-Space o` (SessionX) to switch - faster than `tmux attach`

### Window Naming
- Name windows by task: "editor", "tests", "server", "logs"
- Makes navigation visual and fast

### Copy Mode
- Think of it as vim in your terminal history
- `/pattern` to search, `n` for next, `v` to select, `y` to copy

### Detaching
- **Always detach** (`C-Space D` - capital D!) instead of closing tmux
- Your work persists - tmux auto-saves every 15 minutes
- Note: `C-Space d` (lowercase) opens the config menu

### Floating Windows
- Use for temporary tasks: git, file browsing
- Less clutter than permanent panes

## 📱 Emergency Commands

| Situation | Solution |
|-----------|----------|
| Pane frozen | `C-Space C-c` or `Ctrl+c` |
| Wrong pane active | `C-h/j/k/l` to switch |
| Panes messed up | `C-Space Space` to cycle layouts |
| Lost in copy mode | `q` to exit |
| Want to start over | `C-Space &` to kill window |
| Tmux unresponsive | `pkill -USR1 tmux` (from outside) |

## 🔢 Quick Reference Card

**Print this section:**

```
PREFIX: Ctrl+Space

SESSIONS              WINDOWS              PANES
C-Space D  Detach         C-Space c  New           C-Space |  Split vert
C-Space d  Config menu    C-Space ,  Rename        C-Space -  Split horiz
C-Space o  SessionX       C-Space n  Next          C-Space m  Maximize
C-Space f  Sessionizer    C-Space p  Previous      C-Space x  Close
C-Space n  New session    C-Space 1-9 Go to #      C-h/j/k/l Navigate
C-Space $  Rename sess                         C-Space h/j/k/l Resize

COPY MODE             FLOATING             SYSTEM
C-Space v  Enter          C-Space C-g Lazygit      C-Space r  Reload
h/j/k/l Move          C-Space C-y Yazi         C-Space ?  Help
/      Search         C-Space C-t Terminal     C-Space :  Command
v      Select         C-Space C-m Music        C-Space d  Config menu
y      Copy           Esc     Close
q      Exit

MOUSE
Click pane: select
Drag border: resize
Wheel: scroll
Click+drag: copy
```

## 🎯 Daily Practice Goals

**Week 1:**
- [ ] Use `C-Space |` and `C-Space -` for splits
- [ ] Use `C-h/j/k/l` for navigation
- [ ] Detach (`C-Space d`) and reattach (`tmux attach`)
- [ ] Create windows (`C-Space c`) and switch (`C-Space n/p`)

**Week 2:**
- [ ] Use named sessions (`tmux new -s name`)
- [ ] Master SessionX (`C-Space o`) for switching
- [ ] Use copy mode (`C-Space v`) for scrolling
- [ ] Try floating lazygit (`C-Space C-g`)

**Week 3:**
- [ ] Create project-specific layouts
- [ ] Use window naming (`C-Space ,`)
- [ ] Master copy mode selection (`v`, `y`)
- [ ] Resize panes comfortably

---

**Memorization Tip:** Focus on one section per day. By end of week, these will be muscle memory!

**Stuck?** Check the [Quick Start](quick-start.md) guide or [Keybindings Reference](keybindings.md) for more details.
