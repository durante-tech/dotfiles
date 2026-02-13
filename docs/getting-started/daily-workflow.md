# Daily Developer Workflow

Quick reference for your daily development workflow with all the tools configured.

## Morning Startup

### Option 1: Single Project

```bash
# Jump to project directory
z myproject        # zoxide fuzzy jump

# Start nvim
nvim .
```

### Option 2: Multi-Project (Multiple Folders)

```bash
# Open nvim with multiple paths
nvim ~/project1 ~/project2

# Each opens as a buffer, use LSP workspace folders:
<leader>wa        # Add each folder to LSP workspace

# Tab navigation
gt              # Next tab
gT              # Previous tab
```

### Option 3: Tmux Session

```bash
tns              # tmux-sessionizer - fuzzy find projects
# or
prefix + Ctrl+f  # From inside tmux
```

---

## Git Workflow

### See Only Changed Files (NEW!)

| Action                | Keys          | Description                                                  |
| --------------------- | ------------- | ------------------------------------------------------------ |
| **Git changed files** | `<leader>gf`  | Shows ONLY modified/staged/untracked files with diff preview |
| Git branches          | `<leader>gbr` | Switch branches                                              |
| Lazygit (full UI)     | `<leader>lg`  | Complete git interface                                       |
| Lazygit logs          | `<leader>gl`  | Browse commit history                                        |

**`<leader>gf` is your go-to** for "what did I change?" - much faster than the file explorer.

> **Note:** `<leader>gf` is Gitsigns "stage hunk", `<leader>gf` is the Snacks "git changed files" picker.

### Inside Git Status Picker

| Key          | Action                       |
| ------------ | ---------------------------- |
| `j/k`        | Navigate files               |
| `Enter`      | Open file                    |
| `<C-v>`      | Open in vertical split       |
| `<C-x>`      | Open in horizontal split     |
| Preview pane | Shows the diff automatically |

### Git Status Icons

| Icon | Meaning                   |
| ---- | ------------------------- |
| `M`  | Modified                  |
| `A`  | Added (staged)            |
| `D`  | Deleted                   |
| `??` | Untracked                 |
| `MM` | Modified + staged changes |

---

## LSP Workspace Folders (Multi-Root Projects)

When working across multiple project folders:

| Action                       | Keys         |
| ---------------------------- | ------------ |
| **Add folder to workspace**  | `<leader>wa` |
| Remove folder from workspace | `<leader>wx` |
| List workspace folders       | `<leader>wl` |

### Workflow Example

```
1. Open file from project A      :e ~/projectA/src/main.ts
2. Add it to workspace           <leader>wa
3. Open file from project B      :e ~/projectB/lib/utils.ts
4. Add it to workspace           <leader>wa
5. Now LSP works across both:
   - Go to definition jumps between projects
   - Find references searches both
   - Rename refactors everywhere
```

---

## File Navigation

### Quick Access

| Action                   | Keys          | Description                   |
| ------------------------ | ------------- | ----------------------------- |
| Find files               | `<leader>pf`  | Fuzzy find by filename        |
| Recent files             | `<leader>pr`  | Recently opened files         |
| Search in files          | `<leader>ps`  | Grep across project           |
| Search word under cursor | `<leader>pws` | Search current word           |
| File explorer            | `<leader>ee`  | Toggle sidebar explorer       |
| Reveal current file      | `<leader>ef`  | Show current file in explorer |
| Config files             | `<leader>pc`  | Quick access to nvim config   |

### Explorer (`<leader>ee`)

| Key     | Action          |
| ------- | --------------- |
| `a`     | Add file/folder |
| `r`     | Rename          |
| `d`     | Delete          |
| `y`     | Copy            |
| `x`     | Cut             |
| `p`     | Paste           |
| `Enter` | Open            |
| `-`     | Go up directory |

---

## Code Navigation

| Action                  | Keys     |
| ----------------------- | -------- |
| Go to definition        | `gd`     |
| Go to declaration       | `gD`     |
| Find references         | `gR`     |
| Show implementations    | `gi`     |
| Type definition         | `gt`     |
| Hover documentation     | `K`      |
| Signature help (insert) | `Ctrl-h` |
| Jump back               | `Ctrl-o` |
| Jump forward            | `Ctrl-i` |

---

## Code Actions

| Action             | Keys          |
| ------------------ | ------------- |
| Code actions       | `<leader>vca` |
| Rename symbol      | `<leader>rn`  |
| Fast rename file   | `<leader>rN`  |
| Format file        | `<leader>f`   |
| Toggle diagnostics | `<leader>lx`  |

---

## PAI Integration (claudecode.nvim)

PAI (Personal AI Infrastructure) integrates with Neovim via claudecode.nvim.

### Launch PAI
| Action | Keys | Command |
|--------|------|---------|
| Toggle PAI | `<leader>ac` | `pai` |
| Focus PAI | `<leader>af` | Focus terminal |
| Local dir | `<leader>al` | `pai -l` |
| Full MCPs | `<leader>am` | `pai -l -m full` |
| Dev-work | `<leader>aw` | `pai -l -m dev-work` |
| Resume | `<leader>ar` | `pai --resume` |
| Full + Resume | `<leader>aM` | `pai -l -m full --resume` |
| Dev-work + Resume | `<leader>aW` | `pai -l -m dev-work --resume` |

### Selection & Diffs
| Action | Keys | Mode |
|--------|------|------|
| Send to PAI | `<leader>as` | Visual |
| Accept diff | `<leader>aa` | Normal |
| Reject diff | `<leader>ad` | Normal |

### Command Line Options
```vim
:ClaudeCode                    " Basic PAI
:ClaudeCode -l                 " Stay in current directory
:ClaudeCode -m full            " Load full MCP servers
:ClaudeCode --resume           " Resume last session
:ClaudeCode -l -m dev-work     " Combine options
```

### Snacks Terminal Split Options
Configure the PAI terminal position in `claudecode.lua`:

```lua
snacks_win_opts = {
    position = "right",  -- or "left", "bottom", "top"
    width = 0.40,        -- for vertical splits (left/right)
    -- height = 0.30,    -- for horizontal splits (top/bottom)
}
```

| Position | Split Type | Size Option |
|----------|------------|-------------|
| `"right"` | Vertical | `width = 0.40` |
| `"left"` | Vertical | `width = 0.40` |
| `"bottom"` | Horizontal | `height = 0.30` |
| `"top"` | Horizontal | `height = 0.30` |

### Configuration Note
The plugin uses **full paths** instead of aliases because Neovim's terminal doesn't load `.zshrc`:

```lua
-- In claudecode.lua (uses vim.fn.expand for portability)
terminal_cmd = vim.fn.expand("~") .. "/.bun/bin/bun " .. vim.fn.expand("~") .. "/.claude/skills/CORE/Tools/pai.ts"
```

If you get "exit code 127" (command not found), ensure bun and PAI are installed in your home directory.

### Content Features (PAI ↔ Neovim)

claudecode.nvim creates a **two-way bridge** between PAI and Neovim via WebSocket/MCP protocol.

#### Send Selection to PAI
Select code in visual mode and send it to PAI for discussion:
```
1. Visual select code (v, V, or Ctrl+v)
2. Press <leader>as
3. Selection is sent to PAI with file context
4. PAI can analyze, explain, or suggest changes
```

#### PAI Opens Files in Neovim
When PAI references a file, it can open it directly in your editor:
- PAI says "let me show you line 42 of config.lua"
- File opens in Neovim at that line
- No manual navigation needed

#### PAI Proposes Diffs
When PAI suggests code changes, they appear as a diff view:
```
1. PAI proposes changes → diff view opens
2. Review the diff (side-by-side comparison)
3. <leader>aa → Accept changes
4. <leader>ad → Reject changes
5. Diff view closes automatically on accept
```

#### Selection Tracking
PAI always knows what you're looking at:
- Current file path
- Cursor position
- Visual selection (if any)
- Open buffers

This enables context-aware responses like "in the function you're viewing..." or "for the selected code...".

#### File Tree Integration
PAI can see your project structure:
- All open files
- Project file tree
- Navigate between files programmatically

#### Diagnostics Access
PAI can read LSP diagnostics:
- Errors and warnings in current file
- Across all open buffers
- Enables "fix this error" workflows

#### MCP Tools Reference

| Tool | Description |
|------|-------------|
| `openFile` | Open a file at specific line in Neovim |
| `getOpenFiles` | List all open buffers |
| `getCurrentSelection` | Get visual selection with file context |
| `getDiagnostics` | Get LSP errors/warnings |
| `saveDocument` | Save the current buffer |
| `closeDiff` | Close diff view after accept/reject |

---

## Window Management

### Splits

| Action            | Keys           |
| ----------------- | -------------- |
| Split vertical    | `<leader>sv`   |
| Split horizontal  | `<leader>sh`   |
| Equal size splits | `<leader>se`   |
| Close split       | `<leader>sx`   |
| Navigate splits   | `Ctrl-h/j/k/l` |
| Maximize split    | `<leader>sm`   |

### Tabs

| Action                  | Keys                 |
| ----------------------- | -------------------- |
| New tab                 | `<leader>to`         |
| Close tab               | `<leader>tx`         |
| Next tab                | `gt` or `<leader>tn` |
| Previous tab            | `gT` or `<leader>tp` |
| Current file in new tab | `<leader>tf`         |

---

## Tmux Integration

### From Inside Tmux (prefix = `Ctrl+b`)

| Action                | Keys              |
| --------------------- | ----------------- |
| **Lazygit**           | `prefix + Ctrl+g` |
| **Yazi file manager** | `prefix + Ctrl+y` |
| Quick terminal        | `prefix + Ctrl+t` |
| Music player (rmpc)   | `prefix + Ctrl+m` |
| W3m browser           | `prefix + Ctrl+w` |
| Session picker        | `prefix + Ctrl+f` |
| Split vertical        | `prefix + \|`     |
| Split horizontal      | `prefix + -`      |

### Pane Resize (Shift + vim keys)

| Action       | Keys          |
| ------------ | ------------- |
| Resize down  | `prefix + H`  |
| Resize up    | `prefix + J`  |
| Resize left  | `prefix + K`  |
| Resize right | `prefix + L`  |
| Maximize     | `prefix + m`  |

> **Note:** Resize uses uppercase `H/J/K/L` to avoid conflict with vim-tmux-navigator's lowercase `h/j/k/l` for pane navigation.

### Session Management

| Action         | Keys              |
| -------------- | ----------------- |
| New session    | `prefix + N`      |
| Session picker | `prefix + f`      |
| Detach         | `prefix + D`      |
| List sessions  | `prefix + s`      |

---

## Terminal Tuning for Claude Code

Custom shell/terminal settings that can break Claude Code's TUI rendering. These were identified and fixed — documented here for reference.

### Ghostty Settings

| Setting | Bad Value | Fixed Value | Why |
| ------- | --------- | ----------- | --- |
| `adjust-cell-width` | `-5%` | commented out | Shrinks character cells, breaks TUI column math — text wraps at wrong positions |
| `window-padding-balance` | `false` | `true` | Dumps all leftover pixel space to bottom, creating blank gaps |
| `window-padding-y` | `10` | `5` | Less padding = less size-reporting mismatch (Ghostty includes padding in reported terminal size) |
| `shift+enter` keybind | `text:\x1b\x0d` | commented out | Sends ESC+CR which conflicts with Claude Code's multi-line input |

### Zsh Settings

| Setting | Issue | Fix |
| ------- | ----- | --- |
| Yellow cursor OSC 12 escapes (`\e]12;...`) | Injected on every prompt draw via `precmd`, `zle-keymap-select`, `zle-line-init`, `zle-line-finish` — corrupts TUI rendering | Removed all hooks. Ghostty's `cursor-color = #ffff00` handles this natively |
| Starship widget override | `zle -N zle-keymap-select ""` unregistered Starship's handler, replaced with cursor escape emitter | Removed — let Starship manage its own vi-mode indicator |
| Shift+Enter zsh bindings | `^[^M` and `^[[27;2;13~` bound to `accept-line` — intercepts Claude Code's multi-line sequences | Commented out |

### Tmux Settings

| Setting | Issue | Fix |
| ------- | ----- | --- |
| `escape-time` (missing) | Default 500ms delay after Escape — creates input lag when switching panes | Added `set -g escape-time 0` |
| `focus-events` (missing) | Apps don't receive FocusIn/FocusOut — Claude Code can't redraw on pane switch | Added `set -g focus-events on` |
| `-r` flag on resize `h/j/k/l` | Repeat timer shadows vim-tmux-navigator keys — pane feels "stuck" until Enter | Moved resize to uppercase `H/J/K/L` |
| `-r` flag on maximize `m` | Repeat timer after one-shot action | Removed `-r` |
| `-r` flag on sessionizer `f` | Repeat timer after one-shot action | Removed `-r` |

### Quick Diagnostic Checklist

If Claude Code displays incorrectly, check:

1. **Blank gap at bottom?** → `window-padding-balance` must be `true` in Ghostty
2. **Text wrapping wrong?** → Remove any `adjust-cell-width` in Ghostty
3. **Pane won't focus?** → Check for `-r` flags on tmux bindings + add `escape-time 0`
4. **Garbled output?** → Remove any shell hooks emitting raw escape sequences (OSC 12, cursor manipulation)
5. **Shift+Enter broken?** → Don't override it in Ghostty keybinds or zsh `bindkey`

---

## AeroSpace Window Management

AeroSpace is your tiling window manager. All keybindings use **Alt (⌥)** as the modifier.

### Focus & Navigation (Vim-style)

| Action      | Keys    | Description                 |
| ----------- | ------- | --------------------------- |
| Focus left  | `Alt+H` | Move focus to left window   |
| Focus down  | `Alt+J` | Move focus to window below  |
| Focus up    | `Alt+K` | Move focus to window above  |
| Focus right | `Alt+L` | Move focus to right window  |
| Cycle next  | `Alt+]` | DFS next window (cycle all) |
| Cycle prev  | `Alt+[` | DFS prev window (cycle all) |

### Move Windows

| Action     | Keys          | Description       |
| ---------- | ------------- | ----------------- |
| Move left  | `Alt+Shift+H` | Move window left  |
| Move down  | `Alt+Shift+J` | Move window down  |
| Move up    | `Alt+Shift+K` | Move window up    |
| Move right | `Alt+Shift+L` | Move window right |

### Swap Windows

| Action     | Keys         | Description            |
| ---------- | ------------ | ---------------------- |
| Swap left  | `Alt+Ctrl+H` | Swap with left window  |
| Swap down  | `Alt+Ctrl+J` | Swap with window below |
| Swap up    | `Alt+Ctrl+K` | Swap with window above |
| Swap right | `Alt+Ctrl+L` | Swap with right window |

### Workspaces (Named)

| Workspace | Go To   | Move Window To | Purpose             |
| --------- | ------- | -------------- | ------------------- |
| **1**     | `Alt+1` | `Alt+Shift+1`  | General (laptop)    |
| **2**     | `Alt+2` | `Alt+Shift+2`  | General (portrait)  |
| **D**     | `Alt+D` | `Alt+Shift+D`  | Development/IDEs    |
| **T**     | `Alt+T` | `Alt+Shift+T`  | Terminal (portrait) |
| **B**     | `Alt+B` | `Alt+Shift+B`  | Browser             |
| **M**     | `Alt+M` | `Alt+Shift+M`  | Messaging           |
| **F**     | `Alt+F` | `Alt+Shift+F`  | Finder (floats)     |

### Layout & System

| Action          | Keys              | Description                     |
| --------------- | ----------------- | ------------------------------- |
| Toggle layout   | `Alt+/`           | Cycle tiles horizontal/vertical |
| Accordion       | `Alt+,`           | Toggle accordion layout         |
| Float/Tile      | `Alt+.`           | Toggle floating/tiling          |
| Fullscreen      | `Alt+Shift+Space` | Toggle fullscreen               |
| Close window    | `Alt+Shift+C`     | Close current window            |
| New terminal    | `Alt+Enter`       | Open Ghostty                    |
| Back & forth    | `Alt+Tab`         | Switch to last workspace        |
| Move to monitor | `Alt+Shift+Tab`   | Move workspace to next monitor  |
| Reload config   | `Alt+R`           | Reload AeroSpace config         |
| Toggle bar      | `Alt+S`           | Toggle SketchyBar visibility    |

### Resize Mode

| Action            | Keys             |
| ----------------- | ---------------- |
| Enter resize mode | `Alt+Shift+R`    |
| Shrink width      | `H`              |
| Grow height       | `J`              |
| Shrink height     | `K`              |
| Grow width        | `L`              |
| Balance sizes     | `B`              |
| Exit resize mode  | `Enter` or `Esc` |

### Quick Resize (Outside Resize Mode)

| Action | Keys          |
| ------ | ------------- |
| Shrink | `Alt+Shift+-` |
| Grow   | `Alt+Shift+=` |

---

## Karabiner Hyper Key System

**CapsLock** is your Hyper Key (⌃⌥⇧⌘):

- **Tap** CapsLock → Escape
- **Hold** CapsLock → Hyper modifier

### Direct Shortcuts (Hyper + Key)

**Workspace Switching (→ AeroSpace):**
| Key | Action                |
| --- | --------------------- |
| `T` | Workspace T (Terminal) |
| `B` | Workspace B (Browser)  |
| `D` | Workspace D (Dev/IDEs) |
| `M` | Workspace M (Messaging)|
| `F` | Workspace F (Finder)   |
| `1` | Workspace 1 (General)  |
| `2` | Workspace 2 (Portrait) |

**Raycast & Utilities:**
| Key | Action                |
| --- | --------------------- |
| `X` | AI Chat (Raycast)     |
| `,` | Start Focus Session   |
| `.` | Raycast Notes         |

### Sublayers (HOLD Hyper + Key, then tap another Key)

**⚠️ IMPORTANT: Sublayers require HOLDING, not sequential pressing!**

```
WRONG:  Press Hyper+O → Release O → Press M
RIGHT:  HOLD Hyper → HOLD O → TAP M → Release all
```

Think of it like a **piano chord** - hold the modifier keys, tap the action key.

**`Hyper+O` → Apps:**
| Key | App |
|-----|-----|
| `m` | Obsidian |
| `n` | Notion |
| `d` | Discord |
| `i` | Messages |
| `p` | Music |
| `v` | VSCode |
| `c` | Chrome |
| `w` | WezTerm |

**`Hyper+W` → Window Management:**
| Key | Action |
|-----|--------|
| `h` | Left half |
| `j` | Bottom half |
| `k` | Top half |
| `l` | Right half |
| `Enter` | Maximize |
| `y` | Previous desktop |
| `o` | Next desktop |
| `u` | Previous tab |
| `i` | Next tab |
| `n` | Next window |
| `m` | Focus next window (macOS) |
| `;` | Hide window |
| `b` | Back |
| `f` | Forward |
| `d` | Next display |

**`Hyper+S` → System Controls:**
| Key | Action |
|-----|--------|
| `u` | Volume up |
| `j` | Volume down |
| `i` | Brightness up |
| `k` | Brightness down |
| `l` | Lock screen (⌃⌘Q) |
| `p` | Play/pause |
| `;` | Fast forward |
| `d` | Do Not Disturb toggle |
| `t` | Toggle dark/light mode |
| `c` | Open camera |

**`Hyper+V` → Vim Arrow Keys:**
| Key | Action |
|-----|--------|
| `h` | Left arrow |
| `j` | Down arrow |
| `k` | Up arrow |
| `l` | Right arrow |
| `u` | Page down |
| `i` | Page up |

**`Hyper+C` → Media Controls:**
| Key | Action |
|-----|--------|
| `p` | Play/pause |
| `n` | Fast forward |
| `b` | Rewind |

**`Hyper+R` → Raycast Tools:**
| Key | Action |
|-----|--------|
| `1` | Connect Bluetooth device 1 |
| `2` | Connect Bluetooth device 2 |
| `c` | Color picker |
| `e` | Emoji picker |
| `n` | Raycast notes |
| `p` | Confetti 🎉 |
| `h` | Clipboard history |

**`Hyper+P` → Search:**
| Key | Action |
|-----|--------|
| `s` | Search files |
| `f` | Search folders |

**`Hyper+M` → File Manager:**
| Key | Action |
|-----|--------|
| `f` | Open file manager |

---

## Shell Aliases

### Navigation

```bash
z <partial>     # Zoxide jump
ls              # eza with icons
la              # All files
ll              # Long format
lt              # Tree view
```

### Git

```bash
gs              # git status -s
ga              # git add .
gc "msg"        # git commit -m
gp              # git push
gl              # git pull
lg              # lazygit
glog            # git log graph
```

### Tmux

```bash
tns             # tmux-sessionizer
a               # tmux attach
```

### Quick Tools

```bash
y               # yazi file manager
nlof            # fzf recent files → nvim
nzo             # zoxide → nvim
```

---

## Common Workflows

### 1. Start of Day

```bash
z myproject                    # Jump to project
nvim .                         # Open nvim
# or
tns                            # Pick project via tmux-sessionizer

# In nvim:
<leader>gf                     # Check what changed (git status)
<leader>pr                     # Recent files from yesterday
```

### 2. Working on a Feature

```bash
# Find the file
<leader>pf                     # Find by name
# or
<leader>ps                     # Search for code

# Navigate code
gd                             # Go to definition
K                              # Read docs
gR                             # Find all usages

# Make changes
<leader>rn                     # Rename symbol (refactor)
<leader>vca                    # Code actions (auto-fix)

# Check your changes
<leader>gf                     # Only changed files
```

### 3. Quick Multi-File Edit

```bash
<leader>ps                     # Search for pattern
# Select result → opens file
# Make edit
<leader>gf                     # See all changes
# Jump between changed files
```

### 4. End of Day

```bash
<leader>gf                     # Review all changes
<leader>lg                     # Lazygit for commit
# or in terminal:
lg                             # Lazygit alias
```

---

## Quick Reference Card

**File Finding:**

- `<leader>pf` - Find files
- `<leader>ps` - Search in files
- `<leader>pr` - Recent files
- `<leader>gf` - Git changed files only

**Code Navigation:**

- `gd` - Definition
- `gR` - References
- `K` - Docs
- `Ctrl-o` - Jump back

**Git:**

- `<leader>gf` - Git changed files picker
- `<leader>lg` - Lazygit
- `<leader>gbr` - Switch branch

**Multi-Project:**

- `<leader>wa` - Add workspace folder
- `<leader>wl` - List workspaces
- `gt/gT` - Switch tabs

**Hyper Key (CapsLock) → AeroSpace Workspaces:**

- Tap → Escape
- `Hyper+T` → Workspace T (Terminal)
- `Hyper+B` → Workspace B (Browser)
- `Hyper+D` → Workspace D (Dev)
- `Hyper+M` → Workspace M (Messaging)
- `Hyper+F` → Workspace F (Finder)
- `Hyper+1/2` → Workspace 1/2

---
