# Tmux + Neovim Integration

Master the seamless workflow between tmux and Neovim for maximum terminal productivity.

## Why Tmux + Neovim?

**Tmux provides:**
- Session persistence (survives disconnects/reboots)
- Multiple windows per project
- Terminal panes for servers, tests, shells

**Neovim provides:**
- Powerful text editing
- LSP integration
- Built-in terminal

**Together:**
- Edit in Neovim, run commands in tmux panes
- Seamless navigation between editor and terminals
- Never lose your work (tmux persistence + auto-session)
- Perfect for remote development

## Navigation: vim-tmux-navigator

### The Magic: No Prefix Needed!

**Your config has seamless navigation between tmux panes and Neovim splits.**

| Keys | Action | Works In |
|------|--------|----------|
| `Ctrl+h` | Move left | Tmux panes AND Neovim splits |
| `Ctrl+j` | Move down | Tmux panes AND Neovim splits |
| `Ctrl+k` | Move up | Tmux panes AND Neovim splits |
| `Ctrl+l` | Move right | Tmux panes AND Neovim splits |

**No prefix, no mode switching, just works!**

### How It Works

**Setup (already configured):**

**Tmux side** (`~/.config/tmux/tmux.conf`):
```bash
set -g @plugin "christoomey/vim-tmux-navigator"
```

**Neovim side** (you need this plugin in your Neovim config):
```lua
-- lua/sethy/plugins/vim-tmux-navigator.lua
return {
  "christoomey/vim-tmux-navigator",
  lazy = false,
}
```

### Example Workflow

**Scenario: Edit code + run tests + check server**

```
+------------------+----------+
| Neovim           |  Tests   |
|                  |          |
| [split | split]  +----------+
|                  |  Server  |
+------------------+----------+

Navigation:
1. Editing in Neovim left split
2. Ctrl+l → Neovim right split
3. Ctrl+l → Tests pane (tmux)
4. Ctrl+j → Server pane (tmux)
5. Ctrl+h → Back to Neovim
```

**No mental context switch!** Same muscle memory everywhere.

### Edge Behavior

**At boundaries:**
- **Neovim at right edge** + `Ctrl+l` → Moves to tmux pane on right
- **Tmux pane at left edge** + `Ctrl+h` → Moves to Neovim on left
- **Circular:** At edge of tmux, wraps to other side (if panes exist)

**Smart detection:**
- Plugin knows if you're in Neovim or terminal
- Seamlessly passes navigation between them

### Troubleshooting Navigation

**Navigation not working?**

1. **Check Neovim has the plugin:**
   ```vim
   :Lazy
   " Look for vim-tmux-navigator
   ```

2. **Check tmux has the plugin:**
   ```bash
   ls ~/.config/tmux/.tmux/plugins/
   # Should show vim-tmux-navigator/
   ```

3. **Reinstall plugins:**
   ```bash
   # Tmux:
   C-b I (Shift+i)

   # Neovim:
   :Lazy sync
   ```

4. **Check for conflicting mappings:**
   ```vim
   " In Neovim:
   :verbose map <C-h>
   :verbose map <C-j>
   :verbose map <C-k>
   :verbose map <C-l>
   ```

5. **Reload configs:**
   ```bash
   # Tmux:
   C-b r

   # Neovim:
   :source $MYVIMRC
   " Or restart Neovim
   ```

**Still not working?**

Check if `$TMUX` environment variable is set:
```bash
# Inside tmux:
echo $TMUX
# Should show something like: /tmp/tmux-501/default,12345,0
```

If empty, you're not in tmux! Start tmux first.

## Copy/Paste Between Tmux and Neovim

### Understanding Clipboards

**Three clipboards in play:**

1. **System clipboard** - macOS clipboard (Cmd+C/V)
2. **Tmux buffer** - Internal to tmux
3. **Neovim registers** - Internal to Neovim

**Goal:** Make them work together seamlessly!

### Copy from Tmux → Paste in Neovim

**Method 1: Tmux buffer to Neovim**

```bash
# In tmux pane (outside Neovim):
# Copy some output using copy mode
C-b v                   # Enter copy mode
# Select text with v, copy with y

# In Neovim:
:r !tmux show-buffer    # Reads tmux buffer into current file
# Or in insert mode:
Ctrl+r =system('tmux show-buffer')<CR>
```

**Method 2: Via system clipboard**

If your tmux is configured for system clipboard:
```bash
# Copy in tmux (C-b v, v, y)
# Paste in Neovim:
"+p                     # Paste from system clipboard
```

**Method 3: Open file from tmux buffer**

```bash
# Copy file path in tmux
C-b v
# Navigate to path, select it, y

# In Neovim:
:e <Ctrl+r><Ctrl+r>+    # Paste from system clipboard
# Or
:e <path>               # Type it out
```

### Copy from Neovim → Paste in Tmux

**Method 1: System clipboard**

```vim
" In Neovim (visual mode):
"+y                     " Copy to system clipboard

" In tmux pane:
C-b ]                   " Paste (if tmux has clipboard integration)
" Or just paste normally (Cmd+V on macOS)
```

**Method 2: Via :terminal**

```vim
" In Neovim:
:terminal               " Open terminal in split
" Now you're in a shell inside Neovim
" Paste with Ctrl+Shift+V or mouse
```

**Method 3: Write to file**

```vim
" In Neovim (visual mode):
:'<,'>w !pbcopy         " macOS: Copy selection to clipboard
:'<,'>w !xclip -sel c   " Linux: Copy to clipboard

" In tmux pane:
pbpaste                 " macOS: Paste
xclip -o                " Linux: Paste
```

### Configuring Clipboard Integration

**For macOS (in tmux.conf):**

```bash
# Copy to system clipboard
bind-key -T copy-mode-vi y send-keys -X copy-pipe-and-cancel "pbcopy"
bind-key -T copy-mode-vi Enter send-keys -X copy-pipe-and-cancel "pbcopy"
bind-key -T copy-mode-vi MouseDragEnd1Pane send-keys -X copy-pipe-and-cancel "pbcopy"

# Paste from system clipboard
bind-key p run "pbpaste | tmux load-buffer - && tmux paste-buffer"
```

**For Linux with X11 (in tmux.conf):**

```bash
bind-key -T copy-mode-vi y send-keys -X copy-pipe-and-cancel "xclip -in -selection clipboard"
bind-key -T copy-mode-vi Enter send-keys -X copy-pipe-and-cancel "xclip -in -selection clipboard"
```

**For Linux with Wayland (in tmux.conf):**

```bash
bind-key -T copy-mode-vi y send-keys -X copy-pipe-and-cancel "wl-copy"
bind-key -T copy-mode-vi Enter send-keys -X copy-pipe-and-cancel "wl-copy"
```

**In Neovim (init.lua or options.lua):**

```lua
-- Use system clipboard
vim.opt.clipboard = "unnamedplus"  -- Use system clipboard for all operations

-- Or set specific register:
vim.keymap.set({"n", "v"}, "<leader>y", '"+y', { desc = "Yank to system clipboard" })
vim.keymap.set({"n", "v"}, "<leader>p", '"+p', { desc = "Paste from system clipboard" })
```

## Session Management

### Tmux Sessions vs Neovim Sessions

**Both support sessions, but they're different:**

| Feature | Tmux Sessions | Neovim Sessions (auto-session) |
|---------|---------------|--------------------------------|
| **What it saves** | Windows, panes, layout | Buffers, splits, working directory |
| **Persistence** | Until killed/reboot | Until deleted |
| **Auto-restore** | Via continuum plugin | Via auto-session plugin |
| **Scope** | Entire terminal workspace | One Neovim instance |
| **Best for** | Project-level organization | Editor state |

### Recommended Pattern

**Use both together!**

```
Tmux Session: myproject
  ├─ Window 0: editor
  │   └─ Pane: Neovim (auto-session saves this)
  ├─ Window 1: tests
  │   ├─ Pane: test runner
  │   └─ Pane: git status
  └─ Window 2: server
      └─ Pane: dev server
```

**Workflow:**

1. **Create tmux session:**
   ```bash
   tmux new -s myproject -c ~/projects/myproject
   ```

2. **In first window, open Neovim:**
   ```bash
   nvim
   # Neovim auto-session kicks in
   # Restores previous state for this project
   ```

3. **Create more tmux windows for other tasks:**
   ```
   C-b c                   # New window for tests
   C-b c                   # New window for server
   ```

4. **Detach when done:**
   ```
   C-b D  # Detach (capital D!)
   # Tmux session persists
   # Neovim session auto-saved
   ```

5. **Come back later:**
   ```bash
   tmux attach -t myproject
   # Tmux restores windows/panes
   # Neovim restores buffers/splits
   ```

### Session Commands

**Tmux sessions:**
```bash
tmux ls                 # List tmux sessions
tmux attach -t name     # Attach to session
C-b o                   # SessionX (fuzzy find)
C-b f                   # Sessionizer (find projects)
```

**Neovim sessions (auto-session):**
```vim
:RestoreSession         " Restore session for current directory
:SaveSession            " Save current session
:DeleteSession          " Delete session
:Telescope session-lens " Browse sessions

" Or with your keymaps:
<leader>wr              " Restore session
<leader>ws              " Save session
<leader>wf              " Find session (Telescope)
```

### Session Persistence

**What persists automatically:**

**Tmux (via resurrect + continuum):**
- ✅ Session names
- ✅ Window layout
- ✅ Pane layout
- ✅ Working directories
- ✅ Some programs (nvim, less, man, etc.)
- ❌ Running servers (need manual restart)
- ❌ SSH connections
- ❌ Interactive programs

**Neovim (via auto-session):**
- ✅ Open buffers
- ✅ Split layout
- ✅ Working directory
- ✅ Some plugin state
- ✅ Git branch (if enabled)
- ❌ Unsaved changes (save before detaching!)
- ❌ Terminal state
- ❌ Some plugin state

## Built-in Terminal vs Tmux Panes

**Neovim has a built-in terminal.** Should you use it instead of tmux panes?

### Neovim Terminal

**Open terminal in Neovim:**
```vim
:terminal               " Horizontal split
:vsplit | terminal      " Vertical split
:tabnew | terminal      " New tab
```

**Pros:**
- Inside Neovim, easy to copy/paste
- Can use Neovim keybindings
- Shares Neovim's clipboard

**Cons:**
- Less stable than tmux for long-running processes
- Harder to manage multiple terminals
- Not persistent (closes with Neovim)
- No session management

### Tmux Panes

**Pros:**
- Persistent (survive Neovim crashes/exits)
- Better for long-running processes
- Full tmux features (copy mode, layouts, etc.)
- Can see terminal output while editing

**Cons:**
- Separate from Neovim (different clipboard)
- Need to switch panes

### Recommendation

**Use tmux panes for:**
- Servers, watchers, daemons
- Logs monitoring
- Long-running commands
- Multiple shells

**Use Neovim terminal for:**
- Quick one-off commands
- REPL interaction (when copying code from buffer)
- When you want to stay in Neovim

**Hybrid approach (best):**
```
Tmux Window 0: editor
  └─ Neovim (use :terminal for quick commands)

Tmux Window 1: servers
  ├─ Dev server
  └─ Database

Tmux Window 2: monitoring
  ├─ Logs
  └─ Tests
```

## Common Workflows

### Workflow 1: Full-Stack Development

**Setup:**

```
Tmux Session: fullstack-app

Window 0: editor
  +------------------+
  |      Neovim      |
  +------------------+

Window 1: backend
  +------------------+----------+
  |  Backend Server  | Backend  |
  |  (npm run dev)   | Logs     |
  +------------------+----------+

Window 2: frontend
  +------------------+----------+
  |  Frontend Dev    | Frontend |
  |  (npm run dev)   | Logs     |
  +------------------+----------+

Window 3: database
  +------------------+----------+
  |  Database        | DB       |
  |  (psql/mongo)    | Logs     |
  +------------------+----------+

Window 4: tests
  +------------------+----------+
  |  Test Runner     | Git      |
  |  (jest --watch)  | Status   |
  +------------------+----------+
```

**Workflow:**

1. **Edit code in Neovim** (Window 0)
   ```
   C-b 1                   # Go to editor window
   # Edit files, use LSP, etc.
   :w                      # Save
   ```

2. **Check backend logs** (Window 1)
   ```
   C-b 1                   # Go to backend window
   # See server restart, check errors
   ```

3. **Check frontend** (Window 2)
   ```
   C-b 2                   # Go to frontend window
   # See hot reload, check errors
   ```

4. **Run database queries** (Window 3)
   ```
   C-b 3                   # Go to database window
   # Run queries, check data
   ```

5. **Check tests** (Window 4)
   ```
   C-b 4                   # Go to tests window
   # See test results, use git
   ```

6. **Quick git commit** (from any window)
   ```
   C-b C-g                 # Floating lazygit
   # Stage, commit, push
   Esc                     # Close
   ```

### Workflow 2: Code + Tests Side-by-Side

**Setup:**

```
Tmux Session: myfeature

Window 0: dev
  +------------------+----------+
  |                  |          |
  |  Neovim          |  Tests   |
  |  (editing)       | (watch)  |
  |                  |          |
  +------------------+----------+
```

**Workflow:**

1. **Split window:**
   ```
   nvim                    # Open Neovim
   C-b |                   # Split right
   npm test -- --watch     # Run tests in right pane
   ```

2. **Edit and watch tests:**
   ```
   C-h                     # Back to Neovim (vim-tmux-navigator!)
   # Edit code
   :w                      # Save
   C-l                     # See tests re-run
   ```

3. **Seamless navigation:**
   ```
   # In Neovim, split vertically:
   :vsplit other-file.js

   # Now you have:
   +-------+-------+----------+
   | Nvim  | Nvim  |  Tests   |
   | file1 | file2 |          |
   +-------+-------+----------+

   # Navigate:
   C-h/l                   # Between Neovim splits
   C-l (from right split)  # To tmux test pane
   C-h                     # Back to Neovim
   ```

### Workflow 3: Remote Development

**Scenario: SSH into remote server**

**Setup:**

```bash
# Local machine:
tmux new -s remote-dev

# Inside tmux:
ssh user@server

# On remote server:
tmux new -s project
nvim
```

**Now you have:**
- **Local tmux** session (survives local disconnects)
- **Remote tmux** session (survives SSH drops!)
- **Neovim** inside remote tmux

**Benefits:**
1. SSH drops? Local tmux persists, just reconnect:
   ```bash
   ssh user@server
   tmux attach -t project
   # Everything exactly as you left it!
   ```

2. Local reboot? Remote tmux still running:
   ```bash
   # After reboot:
   ssh user@server
   tmux attach -t project
   ```

3. Both tmux sessions auto-save:
   - Local: Every 15 min
   - Remote: Every 15 min (if configured)

**Nested tmux:**
- **Local prefix:** `C-b`
- **Remote prefix:** `C-b b` (send prefix to inner tmux)

**Example:**
```
C-b c                   # New window in LOCAL tmux
C-b b c                 # New window in REMOTE tmux
```

### Workflow 4: Learning New Codebase

**Setup:**

```
Tmux Session: learning-rust

Window 0: main
  +------------------+----------+
  | Neovim           |          |
  | (exploring code) | grep     |
  |                  | results  |
  +------------------+----------+

Window 1: docs
  +------------------+
  |  less docs.md    |
  |  or mdcat        |
  +------------------+

Window 2: repl
  +------------------+
  |  cargo run       |
  |  or rust REPL    |
  +------------------+

Window 3: notes
  +------------------+
  |  Neovim          |
  |  notes.md        |
  +------------------+
```

**Workflow:**

1. **Read docs** (Window 1)
2. **Switch to code** (Window 0)
   - Use Neovim's Telescope to explore
   - Split to see multiple files
3. **Try code in REPL** (Window 2)
4. **Take notes** (Window 3)
5. **Quick search across windows:**
   ```bash
   # In Window 0 right pane:
   rg "pattern" | less    # Search results always visible
   ```

### Workflow 5: Refactoring Session

**Setup:**

```
Window 0: code
  +------------------+
  | Neovim splits:   |
  | [old | new]      |
  +------------------+

Window 1: tests
  +------------------+
  |  npm test        |
  |  --watch         |
  +------------------+

Window 2: git
  +------------------+
  |  git diff        |
  +------------------+
```

**Workflow:**

1. **Open old and new files side-by-side** (Window 0)
   ```vim
   :vsplit new-file.js
   ```

2. **Refactor code**
   - `C-h` - Old file
   - `C-l` - New file
   - Copy/paste, modify

3. **Save and check tests** (Window 1)
   ```
   :w
   C-b 1                   # See tests run
   ```

4. **Review changes** (Window 2)
   ```
   C-b 2                   # See git diff
   ```

5. **Commit when done**
   ```
   C-b C-g                 # Floating lazygit
   ```

## Tips & Tricks

### 1. Maximize Neovim Pane Temporarily

**When you need full screen for editing:**

```
C-b m                   # Maximize Neovim pane
# Edit with full screen
C-b m                   # Restore layout
```

**Or use Neovim's splits for focused work:**
```vim
:only                   " Close all other splits
C-w v                   " When ready, split again
```

### 2. Copy Output Directly into Neovim

**From tmux pane to Neovim buffer:**

```bash
# In tmux pane (not Neovim):
some-command

# In Neovim:
:r !some-command        " Reads command output into buffer

# Or:
:read !tmux capture-pane -p -t 1
" Reads pane 1's output into Neovim
```

### 3. Send Commands from Neovim to Tmux Pane

**Automate running tests from Neovim:**

```vim
" In Neovim (add to your config):
nnoremap <leader>t :!tmux send-keys -t 2 "npm test" Enter<CR>
" Pressing <leader>t sends "npm test" to pane 2
```

**More advanced:**
```vim
" Run current file in pane 2:
nnoremap <leader>r :!tmux send-keys -t 2 "node %" Enter<CR>

" Run selected text in pane 2:
vnoremap <leader>e :!tmux send-keys -t 2 "$(cat)" Enter<CR>
```

### 4. Floating Neovim in Tmux

**Quick Neovim popup for notes:**

```bash
# In tmux.conf:
bind-key C-n display-popup -w 80% -h 80% -E "nvim ~/notes.md"

# Usage:
C-b C-n                 # Floating Neovim for quick notes
```

### 5. Shared History

**Use same shell history in all tmux panes:**

```bash
# In .zshrc:
setopt share_history
setopt inc_append_history

# Now all tmux panes share command history!
```

### 6. Project-Specific Tmux + Neovim

**Auto-start tmux session with Neovim for project:**

```bash
#!/bin/bash
# ~/scripts/start-project.sh

SESSION=$1
DIR=~/projects/$SESSION

tmux new-session -d -s $SESSION -c $DIR

# Window 0: Neovim
tmux rename-window -t $SESSION:0 'editor'
tmux send-keys -t $SESSION:0 'nvim' C-m

# Window 1: Tests
tmux new-window -t $SESSION:1 -n 'tests' -c $DIR
tmux send-keys -t $SESSION:1 'npm test -- --watch' C-m

# Window 2: Server
tmux new-window -t $SESSION:2 -n 'server' -c $DIR
tmux send-keys -t $SESSION:2 'npm run dev' C-m

# Attach to session
tmux attach -t $SESSION
```

**Usage:**
```bash
./start-project.sh myapp
```

### 7. Use Tmux Popups for Quick Edits

**Edit file from anywhere:**

```bash
# In tmux.conf:
bind-key e command-prompt -p "Edit file:" "display-popup -E -w 80% -h 80% 'nvim %%'"

# Usage:
C-b e
# Type: config.js
# Opens in popup Neovim!
```

### 8. Sync Neovim Config Across Sessions

**Your Neovim config is in `~/.config/nvim/`**

**All tmux sessions share the same config:**
- Edit config in one session
- Changes apply to all Neovim instances
- Use `:source $MYVIMRC` or restart to reload

**For session-specific settings:**
```vim
" In Neovim, use local settings:
:setlocal wrap          " Only affects current buffer
:setlocal number        " Only affects current buffer
```

### 9. Visual Separation

**Make it clear which pane is Neovim:**

**Neovim statusline** (you probably have lualine):
- Shows mode (INSERT, NORMAL, etc.)
- Shows file name
- Shows git branch

**Tmux panes:**
- Just terminal prompt
- Consider customizing prompt to distinguish

### 10. Background Jobs

**Run long commands in tmux while editing in Neovim:**

```bash
# In tmux pane (not Neovim):
long-running-command &

# Or:
nohup long-running-command > output.log 2>&1 &

# Check output from Neovim:
:e output.log
:set autoread           " Auto-reload when file changes
```

## Troubleshooting

### Problem: Navigation doesn't work

**Check:**
1. `vim-tmux-navigator` installed in **both** tmux and Neovim
2. `$TMUX` variable is set (you're in tmux)
3. No conflicting keymappings

**Fix:**
```bash
# Tmux:
C-b I (reinstall plugins)

# Neovim:
:Lazy sync
```

### Problem: Can't copy from tmux to Neovim

**Fix: Use system clipboard**

```bash
# Tmux (in tmux.conf):
bind-key -T copy-mode-vi y send-keys -X copy-pipe-and-cancel "pbcopy"

# Neovim (in init.lua):
vim.opt.clipboard = "unnamedplus"

# Now:
# Copy in tmux with y → paste in Neovim with "+p
```

### Problem: Colors look wrong in Neovim inside tmux

**Fix: Enable true color**

```bash
# In tmux.conf (already in your config):
set -g default-terminal "tmux-256color"
set -ag terminal-overrides ",xterm-256color:RGB"

# In Neovim (init.lua):
vim.opt.termguicolors = true

# Reload:
C-b r (tmux)
:source $MYVIMRC (Neovim)
```

### Problem: Escape key is slow in Neovim inside tmux

**Fix: Reduce escape time**

```bash
# In tmux.conf:
set -sg escape-time 10

# Reload:
C-b r
```

### Problem: Mouse doesn't work

**Fix: Enable mouse in both**

```bash
# Tmux (in tmux.conf, already set):
set -g mouse on

# Neovim (in init.lua):
vim.opt.mouse = "a"
```

### Problem: Sessions not restoring

**Check:**

**Tmux resurrect:**
```bash
ls ~/.config/tmux/.tmux/resurrect/
# Should show saved sessions
```

**Neovim auto-session:**
```vim
:echo stdpath("data") . "/sessions/"
# Should show saved sessions

# Or:
:Telescope session-lens
```

**Fix:**

```bash
# Tmux: Save manually
C-b Ctrl-s

# Neovim: Save manually
:SaveSession
```

### Problem: Pane splits look different

**Tmux panes** have borders, **Neovim splits** don't by default.

**To add borders in Neovim:**
```lua
-- In Neovim config:
vim.opt.fillchars = { vert = '│', horiz = '─' }
```

## Best Practices

### 1. One Neovim Instance per Tmux Window

**Don't open multiple Neovims in one window's panes.**

```
❌ Bad:
+-------+-------+
| Neovim| Neovim|
+-------+-------+

✅ Good:
Window 0: Neovim (with splits)
Window 1: Terminal tasks
```

**Why:**
- Confusing which Neovim instance you're in
- Can't use `C-h/j/k/l` navigation properly
- Separate configs/sessions

### 2. Use Neovim Splits for Code, Tmux Panes for Tools

```
✅ Good pattern:
+------------------+----------+
| Neovim           |  Tests   |
| [split | split]  |  (watch) |
+------------------+----------+

# Code files in Neovim splits
# Running processes in tmux panes
```

### 3. Name Your Windows

```bash
C-b ,                   # Rename window
# Type: editor, tests, server, etc.

# Status bar shows:
[myproject] editor | tests | server
# Easy to know where you are!
```

### 4. Save Often

**Neovim auto-session saves on exit, but:**
```vim
:w                      " Save file manually
:SaveSession            " Save session state
```

**Tmux auto-saves every 15 min, but:**
```
C-b Ctrl-s              " Manual save
```

### 5. Use Floating Windows for Temporary Tasks

```
C-b C-g                 " Lazygit (temporary)
C-b C-y                 " File browser (temporary)
C-b C-t                 " Quick shell (temporary)

# Don't create permanent panes for these!
```

### 6. Detach, Don't Close

**When switching projects:**
```
C-b D                   " Detach (capital D!) (everything persists)
# Not: exit, C-b &, etc.
```

**When changing branches:**
```vim
" In Neovim:
:SaveSession            " Save before checkout

" In tmux pane:
git checkout other-branch

" In Neovim:
:RestoreSession         " Different session per branch!
```

### 7. Leverage Both Persistence Systems

**Tmux resurrect** saves:
- Pane layout
- Working directories
- Running programs

**Neovim auto-session** saves:
- Open files
- Splits
- Cursor positions

**Together:** Complete workspace restoration!

---

**Pro Tip:** The magic of tmux + Neovim is the seamless navigation (`C-h/j/k/l`). Master this, and you'll never want to go back to separate terminal windows!

**Next Steps:**
- Practice the workflows above
- Customize keybindings to your preference
- Explore more tmux plugins
- Build your own tmux + Neovim automation scripts
