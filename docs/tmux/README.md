# Tmux Documentation

Complete guide for mastering tmux - your terminal multiplexer and session manager.

## 📚 Documentation Structure

### Getting Started
- **[Quick Start](quick-start.md)** - Get productive with tmux in 10 minutes

### Daily Reference
- **[Daily Cheatsheet](daily-cheatsheet.md)** - Most common commands at a glance
- **[Keybindings Reference](keybindings.md)** - Complete keybinding list

### Workflows
Learn tmux workflows for real development:

- **[Sessions](workflows/sessions.md)** - Managing projects and contexts
- **[Windows](workflows/windows.md)** - Organizing tasks within a session
- **[Panes](workflows/panes.md)** - Splitting and managing terminal views
- **[Copy Mode](workflows/copy-mode.md)** - Copying and scrolling like vim

### Integration
- **[Tmux + Neovim](integration/nvim.md)** - Seamless navigation between tmux and nvim

## 🎯 What is Tmux?

Tmux is a **terminal multiplexer**. It lets you:

1. **Switch between programs** in one terminal
2. **Detach and reattach** sessions (survive disconnects)
3. **Split terminal** into multiple panes
4. **Organize work** into sessions and windows
5. **Keep processes running** even when you disconnect

## 🔥 Your Tmux Setup Highlights

### Prefix Key
```
Ctrl+Space  (C-Space)  →  Your prefix key (press before all tmux commands)
```

### Quick Access Features

| Keys | Action | Use Case |
|------|--------|----------|
| `C-Space D` | Detach | Leave session running (capital D!) |
| `C-Space d` | Config Menu | Quick access to dotfiles (lowercase d) |
| `C-Space o` | SessionX | Switch between projects (like VSCode workspace) |
| `C-Space f` | Sessionizer | Find and open project directories |
| `C-Space C-g` | Lazygit | Git UI in floating window |
| `C-Space C-y` | Yazi | File manager in floating window |
| `C-Space C-t` | Quick terminal | Floating terminal |
| `C-Space C-w` | W3m | Text-based web browser |

### Smart Features

✅ **Auto-restore sessions** - Your work persists across reboots
✅ **Vi-mode navigation** - Copy/scroll like vim
✅ **Neovim integration** - Seamless pane navigation
✅ **Mouse support** - Click, resize, scroll
✅ **Session persistence** - Auto-saves every 15 minutes
✅ **Beautiful theme** - Catppuccin Mocha

## 📖 Learning Path

### Beginner (Week 1)
1. Start with [Quick Start](quick-start.md)
2. Review [Daily Cheatsheet](daily-cheatsheet.md) - keep it open!
3. Master [Sessions](workflows/sessions.md) - project management
4. Learn [Panes](workflows/panes.md) - terminal splitting

### Intermediate (Week 2-3)
1. Master [Windows](workflows/windows.md) - task organization
2. Learn [Copy Mode](workflows/copy-mode.md) - vim-style copying
3. Integrate [Tmux + Neovim](integration/nvim.md)

### Advanced (Month 2+)
1. Build personal workflow patterns
2. Create project-specific layouts
3. Master advanced copy-mode techniques

## 🚀 Most Used Commands

### Sessions (Projects)
```bash
# Start/attach session
tmux                 # New session
tmux attach          # Attach to last session
tmux attach -t name  # Attach to specific session

# Inside tmux:
C-Space D                # Detach (capital D! - session keeps running)
C-Space o                # SessionX - switch projects
C-Space f                # Sessionizer - find projects
```

### Panes (Splits)
```bash
C-Space |                # Split vertically
C-Space -                # Split horizontally
C-Space h/j/k/l          # Resize panes (vim-style)
C-Space m                # Maximize pane (zoom)
C-Space x                # Close pane
```

### Windows (Tabs)
```bash
C-Space c                # Create window
C-Space ,                # Rename window
C-Space n                # Next window
C-Space p                # Previous window
C-Space 1-9              # Go to window 1-9 (starts at 1!)
```

### Copy Mode (Scrolling)
```bash
C-Space v                # Enter copy mode
# Then use vim keys: h/j/k/l, /, n, N, v, y
```

## 💡 Philosophy

This tmux configuration follows:

1. **Vim-style everything** - hjkl navigation, vi copy-mode
2. **Session = Project** - One tmux session per project/context
3. **Windows = Tasks** - Different windows for different tasks within project
4. **Panes = Views** - Multiple terminal views for one task
5. **Floating tools** - Lazygit, yazi, terminal as popup overlays

## 🆘 Common Scenarios

### "I want to work on multiple projects"
```bash
# Each project = one session:
tmux new -s project1
C-Space D               # Detach (capital D!)
tmux new -s project2
C-Space D               # Detach (capital D!)
C-Space o               # Switch between them (SessionX)
```

### "I need to see code and run tests simultaneously"
```bash
C-Space |               # Split vertically
# Left: run nvim
# Right: run tests
C-Space h/l             # Resize as needed
```

### "My SSH connection dropped!"
```bash
# Reconnect:
ssh server
tmux attach         # Your session is still running!
```

### "I want to copy terminal output"
```bash
C-Space v               # Enter copy mode
# Navigate with hjkl
v                   # Start selection
y                   # Copy
q                   # Exit copy mode
```

## 🔗 Integration Points

### With Neovim
- `Ctrl-h/j/k/l` works across tmux panes AND nvim splits
- Seamless navigation, no mental context switching

### With Ghostty
- Tmux runs inside Ghostty terminal
- Ghostty handles display, tmux handles multiplexing
- Ghostty splits (`Cmd+B`) vs Tmux splits (`C-Space`)

### With Git (Lazygit)
- `C-Space C-g` opens lazygit in floating window
- Stage, commit, push without leaving tmux

### With Files (Yazi)
- `C-Space C-y` opens file manager in floating window
- Navigate, preview, manage files visually

## 📝 Quick Reference Card

**Print this or keep on second monitor:**

```
PREFIX: Ctrl+Space (C-Space)

SESSIONS:              PANES:                 WINDOWS:
C-Space D  Detach          C-Space |  Split vert     C-Space c  New
C-Space o  SessionX        C-Space -  Split horiz    C-Space ,  Rename
C-Space f  Sessionizer     C-Space m  Maximize       C-Space n  Next
C-Space n  New session     C-Space x  Close          C-Space p  Previous
                       C-Space hjkl Resize        C-Space 1-9 Go to

COPY:                  FLOATING:              OTHER:
C-Space v  Copy mode       C-Space C-g  Lazygit      C-Space r  Reload config
v      Select          C-Space C-y  Yazi         C-Space d  Config menu
y      Yank            C-Space C-t  Terminal     C-Space ?  Show keys
q      Exit            C-Space C-m  Music
                       C-Space C-w  W3m
```

## 🎓 Next Steps

**New to tmux?** Start here:
1. [Quick Start](quick-start.md) - 10 minute tutorial
2. [Daily Cheatsheet](daily-cheatsheet.md) - Keep this open!

**Ready to go deeper?**
1. [Sessions](workflows/sessions.md) - Project management
2. [Panes](workflows/panes.md) - Terminal splitting
3. [Copy Mode](workflows/copy-mode.md) - Vim-style text selection

**Want integration?**
1. [Tmux + Neovim](integration/nvim.md) - Seamless workflow

---

**Remember:** Tmux is about **persistance and organization**. Learn to think in Sessions → Windows → Panes, and you'll never lose your work again!

**Stuck?** Check the [Keybindings Reference](keybindings.md) or [Daily Cheatsheet](daily-cheatsheet.md).
