# Tmux Keybindings Reference

Complete keyboard shortcut reference for your tmux configuration.

> **Prefix Key:** `Ctrl+b` (referred to as `C-b` below)
> **Usage:** Press `Ctrl+b`, release, then press the command key

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
| `C-b D` | **Detach from session** | **Capital D!** Session keeps running |
| `C-b d` | **Config menu** | **Custom:** Quick edit dotfiles |
| `C-b (` | Switch to previous session | Cycles backward |
| `C-b )` | Switch to next session | Cycles forward |
| `C-b L` | Switch to last session | Toggle between two sessions |
| `C-b s` | List sessions | Interactive tree view |
| `C-b $` | Rename current session | Prompts for new name |
| `C-b n` | Create new session | **Custom:** Prompts for name |

### Session Finding (Plugins)

| Keys | Action | Plugin | Notes |
|------|--------|--------|-------|
| `C-b o` | SessionX fuzzy finder | sessionx | **Custom:** Switch/create sessions |
| `C-b f` | Tmux sessionizer | script | **Custom:** Find projects, create sessions |

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
| `C-b c` | Create new window | Starts in current path |
| `C-b ,` | Rename window | Prompts for new name |
| `C-b &` | Kill window | Confirmation prompt (y/n) |
| `C-b n` | Next window | Cycles forward |
| `C-b p` | Previous window | Cycles backward |
| `C-b l` | Last window | Toggle between two windows |
| `C-b 1-9` | Switch to window N | Direct access to windows 1-9 (starts at 1!) |
| `C-b '` | Prompt for window index | For windows beyond 9 |
| `C-b w` | List windows | Interactive tree with preview |
| `C-b f` | Find window | Search by name |

### Window Management

| Keys | Action | Notes |
|------|--------|-------|
| `C-b .` | Move window | Prompts for new index |
| `C-b :swap-window -s 2 -t 5` | Swap window 2 with 5 | Command mode |
| `C-b :move-window -t session:` | Move to another session | Command mode |

**Your config settings:**
- Base index starts at **1** (not 0)
- Automatic window renaming: **on**
- Auto-rename format: shows current command

---

## Panes

### Pane Creation

| Keys | Action | Notes |
|------|--------|-------|
| `C-b \|` | Split vertical | **Custom:** Side by side |
| `C-b -` | Split horizontal | **Custom:** Top and bottom |
| `C-b %` | Split vertical | Standard binding (unused) |
| `C-b "` | Split horizontal | Standard binding (unused) |

**Your config:** New panes open in current directory (`#{pane_current_path}`)

### Pane Navigation

| Keys | Action | Notes |
|------|--------|-------|
| `C-h` | Move to left pane | **Plugin:** vim-tmux-navigator |
| `C-j` | Move to pane below | **Plugin:** vim-tmux-navigator |
| `C-k` | Move to pane above | **Plugin:** vim-tmux-navigator |
| `C-l` | Move to right pane | **Plugin:** vim-tmux-navigator |
| `C-b o` | Next pane | Cycles clockwise |
| `C-b ;` | Last pane | Toggle between two panes |
| `C-b q` | Show pane numbers | Brief display |
| `C-b q 0-9` | Jump to pane N | While numbers showing |

**Note:** `C-h/j/k/l` works seamlessly between tmux panes and Neovim splits!

### Pane Resizing

| Keys | Action | Notes |
|------|--------|-------|
| `C-b h` | Resize left (shrink right) | **Custom:** Repeatable |
| `C-b j` | Resize down (shrink top) | **Custom:** Repeatable |
| `C-b k` | Resize up (shrink bottom) | **Custom:** Repeatable |
| `C-b l` | Resize right (shrink left) | **Custom:** Repeatable |
| `C-b C-h/j/k/l` | Resize (arrow keys) | Standard bindings |

**Your config:**
- Resize step: **5 cells**
- **Repeatable (`-r` flag):** Can press quickly without prefix
- Example: `C-b h h h h` (hold `C-b`, tap `h` multiple times)

### Pane Management

| Keys | Action | Notes |
|------|--------|-------|
| `C-b m` | Maximize/zoom pane | **Custom:** Toggle |
| `C-b z` | Maximize/zoom pane | Standard binding |
| `C-b x` | Kill pane | Confirmation prompt (y/n) |
| `C-b !` | Break pane to new window | Converts pane to window |
| `C-b {` | Swap pane left | Swap with previous |
| `C-b }` | Swap pane right | Swap with next |
| `C-b Space` | Cycle through layouts | Cycles: even, vertical, horizontal, etc. |
| `C-b C-o` | Rotate panes clockwise | All panes shift positions |
| `C-b M-o` | Rotate panes counter-clockwise | All panes shift positions |

### Pane Layouts

| Keys | Action | Layout Type |
|------|--------|-------------|
| `C-b M-1` | Even horizontal | All panes equal width, side by side |
| `C-b M-2` | Even vertical | All panes equal height, stacked |
| `C-b M-3` | Main horizontal | One large top, small panes below |
| `C-b M-4` | Main vertical | One large left, small panes right |
| `C-b M-5` | Tiled | Grid layout, all equal size |

**Your config settings:**
- Pane base index starts at **1** (not 0)
- Pane border status: **off**

---

## Copy Mode

### Entering/Exiting

| Keys | Action | Notes |
|------|--------|-------|
| `C-b v` | Enter copy mode | **Custom:** "v" for vim/visual |
| `C-b [` | Enter copy mode | Standard binding |
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
| `C-b` | Full page up | (Not prefix in copy mode!) |
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
| `C-b ]` | Paste buffer | Outside copy mode |
| `C-b =` | Choose buffer | List all buffers, select to paste |

---

## Floating Windows

Your config includes custom **popup/floating windows** for common tools.

| Keys | Tool | Size | Notes |
|------|------|------|-------|
| `C-b C-g` | Lazygit | 90%x90% | **Custom:** Git UI |
| `C-b C-y` | Yazi | 90%x90% | **Custom:** File manager |
| `C-b C-t` | Zsh | 80%x80% | **Custom:** Quick terminal |
| `C-b C-m` | RMPC | 95%x95% | **Custom:** Music player |
| `C-b C-w` | W3m | 90%x90% | **Custom:** Text-based web browser |

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
| `C-b d` | Config menu | **Custom:** Quick access to dotfiles |

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
C-b r (reload config)

# For nvim:
:source % (or restart nvim)
```

### System Commands

| Keys | Action | Notes |
|------|--------|-------|
| `C-b r` | Reload tmux config | **Custom:** Sources `~/.config/tmux/tmux.conf` |
| `C-b ?` | Show all keybindings | Standard: Interactive list |
| `C-b :` | Enter command mode | Type tmux commands |
| `C-b t` | Show time | Large clock display |
| `C-b ~` | Show messages | Recent tmux messages |

### Common Commands (via `C-b :`)

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
C-b :set -g mouse off
```

**Re-enable:**
```
C-b :set -g mouse on
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
   C-b :
   run-shell "echo $TMUX_PLUGIN_MANAGER_PATH"
   # Should show ~/.config/tmux/.tmux/plugins
   ```

2. **Reinstall plugins:**
   ```
   C-b I (Shift+i)
   ```

3. **Check Neovim has the plugin:**
   ```
   :Lazy
   # Look for vim-tmux-navigator
   ```

4. **Reload configs:**
   ```
   # Tmux:
   C-b r

   # Neovim:
   :source $MYVIMRC
   ```

---

## Plugin-Specific Keybindings

### SessionX (Session Manager)

| Keys | Action | Notes |
|------|--------|-------|
| `C-b o` | Open SessionX | **Custom:** Fuzzy find sessions |

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
| `C-b Ctrl-s` | Save session | resurrect | Manual save |
| `C-b Ctrl-r` | Restore session | resurrect | Manual restore |

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
| `C-b I` | Install plugins | Shift+i: Fetches new plugins |
| `C-b U` | Update plugins | Shift+u: Updates all plugins |
| `C-b M-u` | Uninstall plugins | Removes unlisted plugins |

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
| `C-b f` | Run tmux-sessionizer | **Custom:** Find projects and create/switch sessions |

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
| `C-b ?` | Show all keybindings |
| `C-b t` | Show large clock |
| `C-b i` | Display pane info |

### Advanced

| Keys | Action |
|------|--------|
| `C-b C-z` | Suspend tmux client |
| `C-b #` | List paste buffers |
| `C-b -` | Delete paste buffer (standard) |
| `C-b =` | Choose paste buffer |
| `C-b Page Up` | Enter copy mode and scroll up |

---

## Keybinding Conflicts

Some keys have **multiple functions** depending on context:

| Key | Context | Action |
|-----|---------|--------|
| `C-b d` | **Your config** | **Config menu** (edit dotfiles) |
| `C-b d` | Standard tmux | Detach session (overridden!) |
| `C-b D` | **Your config** | **Detach session** (capital D!) |
| `C-b o` | **Your config** | **SessionX** (fuzzy find) |
| `C-b o` | Standard tmux | Next pane (overridden!) |
| `C-b n` | **Your config** | **New session** (prompts for name) |
| `C-b n` | Standard tmux | Next window (still works!) |

**To use these features:**
- **Detach:** Use `C-b D` (capital D)
- **Config menu:** Use `C-b d` (lowercase d)
- **Next pane:** Use `C-h/j/k/l` (vim-tmux-navigator) or mouse
- **Next window:** `C-b n` still works for next window

**Check your bindings anytime:**
```
C-b ?
# Or
C-b :list-keys
```

---

## Cheat Sheet (Most Common)

**Print this section!**

```
PREFIX: Ctrl+b (C-b)

SESSIONS              WINDOWS              PANES
C-b D  Detach         C-b c  New           C-b |  Split vert
C-b d  Config menu    C-b ,  Rename        C-b -  Split horiz
C-b o  SessionX       C-b n  Next          C-b m  Maximize
C-b f  Sessionizer    C-b p  Previous      C-b x  Kill
C-b n  New session    C-b 1-9 Go to #      C-b h/j/k/l Resize
C-b $  Rename         C-b l  Last          C-h/j/k/l Navigate
C-b s  List           C-b w  Tree          (no prefix!)
C-b (  Previous       C-b &  Kill
C-b )  Next

COPY MODE             FLOATING             CONFIG
C-b v  Enter          C-b C-g Lazygit      C-b r  Reload
h/j/k/l Navigate      C-b C-y Yazi         C-b ?  Help
/      Search         C-b C-t Terminal     C-b :  Command
v      Select         C-b C-m Music        C-b d  Menu
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
C-b r                   # Reload config
```

---

## Learning Path

**Week 1: Core navigation**
- Master `C-b |` and `C-b -` (splits)
- Use `C-h/j/k/l` (pane navigation - no prefix!)
- Practice `C-b c`, `C-b n/p` (windows)
- Use `C-b D` (capital D!) to detach, `tmux attach` to return
- Try `C-b d` (lowercase) for quick config edits

**Week 2: Workflows**
- Try `C-b o` (SessionX) for project switching
- Use `C-b v` (copy mode) for scrolling
- Practice `C-b m` (maximize) when focusing
- Create multi-pane layouts

**Week 3: Advanced**
- Learn copy mode selection (`v`, `y`)
- Use floating windows (`C-b C-g` for git)
- Try `C-b f` (sessionizer) for projects
- Experiment with layouts (`C-b Space`)

**Week 4: Mastery**
- Create custom keybindings
- Use command mode (`C-b :`)
- Leverage mouse for quick actions
- Integrate with other tools

---

**Next:** [Tmux-Nvim Integration](integration/nvim.md) - Seamless workflow between tmux and Neovim
