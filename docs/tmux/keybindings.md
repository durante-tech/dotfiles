# Tmux Keybindings Reference

Complete keyboard shortcut reference for your tmux configuration.

> **Prefix Key:** `Ctrl+Space` (referred to as `C-Space` below)
> **Usage:** Press `Ctrl+Space`, release, then press the command key

## Quick Index

- [Sessions](#sessions)
- [Windows](#windows)
- [Panes](#panes)
- [Copy Mode](#copy-mode)
- [Floating Windows](#floating-windows)
- [Configuration](#configuration)
- [System](#system)
- [Mouse](#mouse-interactions)
- [Vim-Tmux Navigator](#vim-tmux-navigator)

---

## Sessions

### Session Management

| Keys | Action | Notes |
|------|--------|-------|
| `C-Space D` | **Detach from session** | **Capital D!** Session keeps running |
| `C-Space d` | **Config menu** | **Custom:** Quick edit dotfiles |
| `C-Space (` | Switch to previous session | Cycles backward |
| `C-Space )` | Switch to next session | Cycles forward |
| `C-Space L` | Switch to last session | Toggle between two sessions |
| `C-Space s` | List sessions | Interactive tree view |
| `C-Space $` | Rename current session | Prompts for new name |
| `C-Space n` | Create new session | **Custom:** Prompts for name |

### Session Finding (Plugins)

| Keys | Action | Plugin | Notes |
|------|--------|--------|-------|
| `C-Space o` | SessionX fuzzy finder | sessionx | **Custom:** Switch/create sessions |
| `C-Space f` | Tmux sessionizer | script | **Custom:** Find projects, create sessions |

**From terminal (outside tmux):**
```bash
tmux                           # Start/attach to last session
tmux new -s name               # Create named session
tmux attach -t name            # Attach to session
tmux ls                        # List all sessions
tmux kill-session -t name      # Kill session
```

---

## Windows

### Window Creation & Navigation

| Keys | Action | Notes |
|------|--------|-------|
| `C-Space c` | Create new window | Starts in current path |
| `C-Space ,` | Rename window | Prompts for new name |
| `C-Space &` | Kill window | Confirmation prompt (y/n) |
| `C-Space n` | Next window | Cycles forward |
| `C-Space p` | Previous window | Cycles backward |
| `C-Space l` | Last window | Toggle between two windows |
| `C-Space 1-9` | Switch to window N | Direct access to windows 1-9 (starts at 1!) |
| `C-Space '` | Prompt for window index | For windows beyond 9 |
| `C-Space w` | List windows | Interactive tree with preview |
| `C-Space f` | Find window | Search by name |

### Window Management

| Keys | Action | Notes |
|------|--------|-------|
| `C-Space .` | Move window | Prompts for new index |
| `C-Space :swap-window -s 2 -t 5` | Swap window 2 with 5 | Command mode |
| `C-Space :move-window -t session:` | Move to another session | Command mode |

**Your config settings:**
- Base index starts at **1** (not 0)
- Automatic window renaming: **on**
- Auto-rename format: shows current command

---

## Panes

### Pane Creation

| Keys | Action | Notes |
|------|--------|-------|
| `C-Space \|` | Split vertical | **Custom:** Side by side |
| `C-Space -` | Split horizontal | **Custom:** Top and bottom |
| `C-Space %` | Split vertical | Standard binding (unused) |
| `C-Space "` | Split horizontal | Standard binding (unused) |

**Your config:** New panes open in current directory (`#{pane_current_path}`)

### Pane Navigation

| Keys | Action | Notes |
|------|--------|-------|
| `C-h` | Move to left pane | **Plugin:** vim-tmux-navigator |
| `C-j` | Move to pane below | **Plugin:** vim-tmux-navigator |
| `C-k` | Move to pane above | **Plugin:** vim-tmux-navigator |
| `C-l` | Move to right pane | **Plugin:** vim-tmux-navigator |
| `C-Space o` | Next pane | Cycles clockwise |
| `C-Space ;` | Last pane | Toggle between two panes |
| `C-Space q` | Show pane numbers | Brief display |
| `C-Space q 0-9` | Jump to pane N | While numbers showing |

**Note:** `C-h/j/k/l` works seamlessly between tmux panes and Neovim splits!

### Pane Resizing

| Keys | Action | Notes |
|------|--------|-------|
| `C-Space h` | Resize left (shrink right) | **Custom:** Repeatable |
| `C-Space j` | Resize down (shrink top) | **Custom:** Repeatable |
| `C-Space k` | Resize up (shrink bottom) | **Custom:** Repeatable |
| `C-Space l` | Resize right (shrink left) | **Custom:** Repeatable |
| `C-Space C-h/j/k/l` | Resize (arrow keys) | Standard bindings |

**Your config:**
- Resize step: **5 cells**
- **Repeatable (`-r` flag):** Can press quickly without prefix
- Example: `C-Space h h h h` (hold `C-Space`, tap `h` multiple times)

### Pane Management

| Keys | Action | Notes |
|------|--------|-------|
| `C-Space m` | Maximize/zoom pane | **Custom:** Toggle |
| `C-Space z` | Maximize/zoom pane | Standard binding |
| `C-Space x` | Kill pane | Confirmation prompt (y/n) |
| `C-Space !` | Break pane to new window | Converts pane to window |
| `C-Space {` | Swap pane left | Swap with previous |
| `C-Space }` | Swap pane right | Swap with next |
| `C-Space Space` | Cycle through layouts | Cycles: even, vertical, horizontal, etc. |
| `C-Space C-o` | Rotate panes clockwise | All panes shift positions |
| `C-Space M-o` | Rotate panes counter-clockwise | All panes shift positions |

### Pane Layouts

| Keys | Action | Layout Type |
|------|--------|-------------|
| `C-Space M-1` | Even horizontal | All panes equal width, side by side |
| `C-Space M-2` | Even vertical | All panes equal height, stacked |
| `C-Space M-3` | Main horizontal | One large top, small panes below |
| `C-Space M-4` | Main vertical | One large left, small panes right |
| `C-Space M-5` | Tiled | Grid layout, all equal size |

**Your config settings:**
- Pane base index starts at **1** (not 0)
- Pane border status: **off**

---

## Copy Mode

### Entering/Exiting

| Keys | Action | Notes |
|------|--------|-------|
| `C-Space v` | Enter copy mode | **Custom:** "v" for vim/visual |
| `C-Space [` | Enter copy mode | Standard binding |
| `q` | Exit copy mode | In copy mode |
| `C-c` | Exit copy mode | In copy mode |
| `Escape` | Exit copy mode | In copy mode |

### Navigation (Vi Mode)

Your config uses **vi mode keys** (`mode-keys vi`)

| Keys | Action | Movement |
|------|--------|----------|
| `h/j/k/l` | Move cursor | Left/Down/Up/Right |
| `w/b/e` | Word movement | Next word / Previous word / End word |
| `W/B/E` | WORD movement | Space-separated |
| `0` | Start of line | |
| `^` | First non-blank | |
| `$` | End of line | |
| `gg` | Top of buffer | Oldest history |
| `G` | Bottom of buffer | Most recent |
| `5G` | Go to line 5 | Absolute line |
| `50%` | Go to 50% of buffer | |
| `C-u` | Half page up | |
| `C-d` | Half page down | |
| `C-Space` | Full page up | (Not prefix in copy mode!) |
| `C-f` | Full page down | |
| `H` | Top of screen | High |
| `M` | Middle of screen | |
| `L` | Bottom of screen | Low |
| `{` | Previous paragraph | |
| `}` | Next paragraph | |

### Searching

| Keys | Action | Notes |
|------|--------|-------|
| `/` | Search forward | Type pattern, press Enter |
| `?` | Search backward | Type pattern, press Enter |
| `n` | Next match | Same direction |
| `N` | Previous match | Opposite direction |

### Selecting & Copying

| Keys | Action | Notes |
|------|--------|-------|
| `v` | Start visual selection | **Custom:** Character-wise |
| `V` | Start line selection | Select entire lines |
| `C-v` | Start block selection | Rectangular selection |
| `y` | Yank (copy) | **Custom:** Copies and exits |
| `Enter` | Copy selection | Copies and exits |
| `Escape` | Cancel selection | Without copying |

**Your config:**
- `v` - Begin selection (`begin-selection`)
- `y` - Copy selection (`copy-selection`)
- Mouse drag automatically copies (see Mouse section)

### Pasting

| Keys | Action | Notes |
|------|--------|-------|
| `C-Space ]` | Paste buffer | Outside copy mode |
| `C-Space =` | Choose buffer | List all buffers, select to paste |

---

## Floating Windows

Your config includes custom **popup/floating windows** for common tools.

| Keys | Tool | Size | Notes |
|------|------|------|-------|
| `C-Space C-g` | Lazygit | 90%x90% | **Custom:** Git UI |
| `C-Space C-y` | Yazi | 90%x90% | **Custom:** File manager |
| `C-Space C-t` | Zsh | 80%x80% | **Custom:** Quick terminal |
| `C-Space C-m` | RMPC | 95%x95% | **Custom:** Music player |
| `C-Space C-w` | W3m | 90%x90% | **Custom:** Text-based web browser |

**How to close floating windows:**
- `Escape` - Close popup
- `q` - Quit application (in most tools)
- `exit` - Exit shell (for zsh popup)

**Floating windows:**
- Overlay current pane
- Don't affect pane layout
- Great for temporary tasks
- Open in current directory (except RMPC)

---

## Configuration

### Config Menu

| Keys | Action | Notes |
|------|--------|-------|
| `C-Space d` | Config menu | **Custom:** Quick access to dotfiles |

**Config menu options:**
- `z` - Edit `.zshrc` (75% popup)
- `p` - Edit `.zprofile` (75% popup)
- `t` - Edit `.tmux.conf` (75% popup)
- `v` - Edit Neovim config (opens in `~/.config/nvim`)
- `q` - Quit menu

**After editing configs:**
```
# For zsh:
source ~/.zshrc

# For tmux:
C-Space r (reload config)

# For nvim:
:source % (or restart nvim)
```

### System Commands

| Keys | Action | Notes |
|------|--------|-------|
| `C-Space r` | Reload tmux config | **Custom:** Sources `~/.config/tmux/tmux.conf` |
| `C-Space ?` | Show all keybindings | Standard: Interactive list |
| `C-Space :` | Enter command mode | Type tmux commands |
| `C-Space t` | Show time | Large clock display |
| `C-Space ~` | Show messages | Recent tmux messages |

### Common Commands (via `C-Space :`)

| Command | Action |
|---------|--------|
| `:setw synchronize-panes on` | Type in all panes simultaneously |
| `:setw synchronize-panes off` | Disable synchronized typing |
| `:capture-pane -S -1000` | Capture last 1000 lines |
| `:save-buffer ~/file.txt` | Save buffer to file |
| `:list-keys` | List all keybindings |
| `:list-commands` | List all tmux commands |
| `:display-message "text"` | Show message in status bar |
| `:source-file ~/.config/tmux/tmux.conf` | Reload config |
| `:new-window -n name` | Create named window |
| `:kill-session -t name` | Kill specific session |
| `:swap-window -s 2 -t 5` | Swap windows |
| `:move-window -t session:` | Move window to another session |
| `:resize-pane -D 10` | Resize pane down 10 cells |
| `:select-layout tiled` | Apply tiled layout |

---

## Mouse Interactions

Your config has **mouse mode enabled** (`set -g mouse on`)

### What Mouse Can Do

| Action | How | Effect |
|--------|-----|--------|
| **Select pane** | Click on pane | Makes it active |
| **Resize pane** | Drag pane border | Adjusts size |
| **Scroll history** | Scroll wheel (in pane) | Enters copy mode automatically |
| **Select text** | Click and drag | Highlights text (in copy mode) |
| **Copy text** | Select, then `y` | Copies selection to buffer |
| **System copy** | Shift + click and drag | Copies to system clipboard (bypasses tmux) |
| **Paste** | Middle mouse button | Pastes from system clipboard |
| **Switch window** | Click window in status bar | Direct window switching |
| **Scroll in less/man** | Scroll wheel | Native program scrolling |

### Mouse Copy Behavior

**Your config has special mouse copy handling:**
```
unbind -T copy-mode-vi MouseDragEnd1Pane
```

**Effect:** Mouse drag doesn't automatically exit copy mode.

**To copy with mouse:**
1. Scroll up (enters copy mode automatically)
2. Click and drag to select
3. Press `y` to copy
4. Or use Shift+drag for system clipboard

### Disabling Mouse (temporarily)

```
C-Space :set -g mouse off
```

**Re-enable:**
```
C-Space :set -g mouse on
```

**Why disable?**
- Select text for system clipboard (bypass tmux)
- Use terminal's native copy/paste
- Avoid accidental pane switching

---

## Vim-Tmux Navigator

Your config uses the **vim-tmux-navigator** plugin for seamless navigation between tmux panes and Neovim splits.

### Seamless Navigation

| Keys | Action | Works In |
|------|--------|----------|
| `C-h` | Move left | Tmux panes AND Neovim splits |
| `C-j` | Move down | Tmux panes AND Neovim splits |
| `C-k` | Move up | Tmux panes AND Neovim splits |
| `C-l` | Move right | Tmux panes AND Neovim splits |

### How It Works

**No prefix needed!** Just press `C-h/j/k/l` directly.

**Intelligence:**
- In Neovim: Moves between splits
- At Neovim edge: Moves to tmux pane
- In tmux pane: Moves between panes
- At tmux edge: Wraps around

**Example workflow:**
```
+-----------------+----------+
|                 |          |
|  Neovim         |  Shell   |
|  [split | split]|          |
|                 |          |
+-----------------+----------+

C-l (in left nvim split)   → right nvim split
C-l (in right nvim split)  → shell pane
C-h (in shell pane)        → nvim
```

**No mental context switch!**

### Vim-Tmux Navigator Configuration

**Neovim side:** You must have the plugin installed in Neovim too!
```lua
-- In your Neovim config:
{ "christoomey/vim-tmux-navigator" }
```

**Tmux side:** Already configured in your `tmux.conf`:
```
set -g @plugin "christoomey/vim-tmux-navigator"
```

### Troubleshooting Navigation

**Navigation not working?**

1. **Check if plugin is installed:**
   ```
   C-Space :
   run-shell "echo $TMUX_PLUGIN_MANAGER_PATH"
   # Should show ~/.config/tmux/.tmux/plugins
   ```

2. **Reinstall plugins:**
   ```
   C-Space I (Shift+i)
   ```

3. **Check Neovim has the plugin:**
   ```
   :Lazy
   # Look for vim-tmux-navigator
   ```

4. **Reload configs:**
   ```
   # Tmux:
   C-Space r

   # Neovim:
   :source $MYVIMRC
   ```

---

## Plugin-Specific Keybindings

### SessionX (Session Manager)

| Keys | Action | Notes |
|------|--------|-------|
| `C-Space o` | Open SessionX | **Custom:** Fuzzy find sessions |

**In SessionX interface:**
- `Ctrl+n/p` or `j/k` - Navigate
- `Enter` - Switch to session
- `Ctrl+x` - Kill session
- `Ctrl+r` - Rename session
- `Ctrl+w` - Show windows preview
- `Escape` - Close SessionX

**Your config:**
```
set -g @sessionx-bind 'o'
```

### Tmux Resurrect & Continuum

**Automatic session saving/restoring.**

| Keys | Action | Plugin | Notes |
|------|--------|--------|-------|
| `C-Space Ctrl-s` | Save session | resurrect | Manual save |
| `C-Space Ctrl-r` | Restore session | resurrect | Manual restore |

**Your config:**
- **Auto-save:** Every 15 minutes (continuum)
- **Auto-restore:** On tmux start (continuum)
- **Captures:** Pane contents (`@resurrect-capture-pane-contents`)

**What gets saved:**
- Session names
- Window layout
- Pane layout and working directories
- Running programs (bash, nvim, less, etc.)

**What doesn't persist:**
- Running servers (npm run dev, etc.)
- SSH connections
- Interactive programs (might need restart)

### Tmux Plugin Manager (TPM)

| Keys | Action | Notes |
|------|--------|-------|
| `C-Space I` | Install plugins | Shift+i: Fetches new plugins |
| `C-Space U` | Update plugins | Shift+u: Updates all plugins |
| `C-Space M-u` | Uninstall plugins | Removes unlisted plugins |

**Plugin location:**
```
~/.config/tmux/.tmux/plugins/
```

**Your installed plugins:**
1. `tpm` - Plugin manager itself
2. `vim-tmux-navigator` - Seamless vim/tmux navigation
3. `tmux-sessionx` - Enhanced session management
4. `tmux-resurrect` - Save/restore sessions
5. `tmux-continuum` - Auto-save sessions
6. `catppuccin/tmux` - Theme
7. `tmux-online-status` - Network status indicator
8. `tmux-battery` - Battery indicator

---

## Custom Script: Tmux Sessionizer

| Keys | Action | Notes |
|------|--------|-------|
| `C-Space f` | Run tmux-sessionizer | **Custom:** Find projects and create/switch sessions |

**Your config:**
```bash
bind-key -r f run-shell "tmux neww ~/scripts/tmux-sessionizer"
```

**What it does:**
1. Fuzzy finds directories in your projects folder
2. Creates session if it doesn't exist
3. Switches to session if it already exists
4. Names session after directory name

**From command line:**
```bash
~/scripts/tmux-sessionizer
# Or if in PATH:
tmux-sessionizer
```

---

## Standard Tmux Keybindings

These are standard tmux bindings that still work (not overridden):

### Info & Help

| Keys | Action |
|------|--------|
| `C-Space ?` | Show all keybindings |
| `C-Space t` | Show large clock |
| `C-Space i` | Display pane info |

### Advanced

| Keys | Action |
|------|--------|
| `C-Space C-z` | Suspend tmux client |
| `C-Space #` | List paste buffers |
| `C-Space -` | Delete paste buffer (standard) |
| `C-Space =` | Choose paste buffer |
| `C-Space Page Up` | Enter copy mode and scroll up |

---

## Keybinding Conflicts

Some keys have **multiple functions** depending on context:

| Key | Context | Action |
|-----|---------|--------|
| `C-Space d` | **Your config** | **Config menu** (edit dotfiles) |
| `C-Space d` | Standard tmux | Detach session (overridden!) |
| `C-Space D` | **Your config** | **Detach session** (capital D!) |
| `C-Space o` | **Your config** | **SessionX** (fuzzy find) |
| `C-Space o` | Standard tmux | Next pane (overridden!) |
| `C-Space n` | **Your config** | **New session** (prompts for name) |
| `C-Space n` | Standard tmux | Next window (still works!) |

**To use these features:**
- **Detach:** Use `C-Space D` (capital D)
- **Config menu:** Use `C-Space d` (lowercase d)
- **Next pane:** Use `C-h/j/k/l` (vim-tmux-navigator) or mouse
- **Next window:** `C-Space n` still works for next window

**Check your bindings anytime:**
```
C-Space ?
# Or
C-Space :list-keys
```

---

## Cheat Sheet (Most Common)

**Print this section!**

```
PREFIX: Ctrl+Space (C-Space)

SESSIONS              WINDOWS              PANES
C-Space D  Detach         C-Space c  New           C-Space |  Split vert
C-Space d  Config menu    C-Space ,  Rename        C-Space -  Split horiz
C-Space o  SessionX       C-Space n  Next          C-Space m  Maximize
C-Space f  Sessionizer    C-Space p  Previous      C-Space x  Kill
C-Space n  New session    C-Space 1-9 Go to #      C-Space h/j/k/l Resize
C-Space $  Rename         C-Space l  Last          C-h/j/k/l Navigate
C-Space s  List           C-Space w  Tree          (no prefix!)
C-Space (  Previous       C-Space &  Kill
C-Space )  Next

COPY MODE             FLOATING             CONFIG
C-Space v  Enter          C-Space C-g Lazygit      C-Space r  Reload
h/j/k/l Navigate      C-Space C-y Yazi         C-Space ?  Help
/      Search         C-Space C-t Terminal     C-Space :  Command
v      Select         C-Space C-m Music        C-Space d  Menu
y      Copy           Esc     Close
q      Exit

MOUSE
Click:       Select pane
Drag border: Resize pane
Scroll:      Enter copy mode (scroll history)
Shift+drag:  System clipboard copy
```

---

## Remapping Keybindings

Want to change a keybinding? Edit your `~/.config/tmux/tmux.conf`:

**Pattern:**
```bash
# Unbind existing (optional)
unbind <key>

# Bind new command
bind <key> <command>

# For repeatable bindings (like resize):
bind -r <key> <command>

# For copy-mode-vi:
bind-key -T copy-mode-vi '<key>' send -X <action>
```

**Examples:**
```bash
# Change split to different keys:
unbind |
bind \ split-window -h

# Change maximize to different key:
unbind m
bind z resize-pane -Z

# Add new floating window:
bind C-f display-popup -w 80% -h 80% -E "ranger"
```

**After editing:**
```
C-Space r                   # Reload config
```

---

## Learning Path

**Week 1: Core navigation**
- Master `C-Space |` and `C-Space -` (splits)
- Use `C-h/j/k/l` (pane navigation - no prefix!)
- Practice `C-Space c`, `C-Space n/p` (windows)
- Use `C-Space D` (capital D!) to detach, `tmux attach` to return
- Try `C-Space d` (lowercase) for quick config edits

**Week 2: Workflows**
- Try `C-Space o` (SessionX) for project switching
- Use `C-Space v` (copy mode) for scrolling
- Practice `C-Space m` (maximize) when focusing
- Create multi-pane layouts

**Week 3: Advanced**
- Learn copy mode selection (`v`, `y`)
- Use floating windows (`C-Space C-g` for git)
- Try `C-Space f` (sessionizer) for projects
- Experiment with layouts (`C-Space Space`)

**Week 4: Mastery**
- Create custom keybindings
- Use command mode (`C-Space :`)
- Leverage mouse for quick actions
- Integrate with other tools

---

**Next:** [Tmux-Nvim Integration](integration/nvim.md) - Seamless workflow between tmux and Neovim
