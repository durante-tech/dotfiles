# Complete Keybindings Reference

Comprehensive list of all keybindings in this configuration, organized by category.

> **Legend:** `<leader>` = Space key | `Ctrl` = Control key | `Shift` = Shift key

## Essential Vim Keys

### Modes

| Key | Action |
|-----|--------|
| `Esc` | Return to NORMAL mode |
| `i` | INSERT mode before cursor |
| `a` | INSERT mode after cursor |
| `v` | VISUAL mode (character) |
| `V` | VISUAL LINE mode |
| `Ctrl-v` | VISUAL BLOCK mode |
| `:` | COMMAND mode |

### Basic Movement

| Key | Action |
|-----|--------|
| `h` `j` `k` `l` | Left, Down, Up, Right |
| `w` / `b` | Next/Previous word |
| `e` / `ge` | End of word forward/backward |
| `0` / `^` | Start of line / First non-blank |
| `$` | End of line |
| `gg` / `G` | Top / Bottom of file |
| `{` / `}` | Previous / Next paragraph |
| `Ctrl-u` / `Ctrl-d` | Scroll half page up/down |
| `Ctrl-b` / `Ctrl-f` | Scroll full page up/down |

### Editing

| Key | Action |
|-----|--------|
| `dd` | Delete line |
| `yy` | Yank (copy) line |
| `p` / `P` | Paste after/before |
| `u` | Undo |
| `Ctrl-r` | Redo |
| `x` | Delete character |
| `.` | Repeat last change |

## Custom Keybindings

### File & Project Management

| Key | Action | Plugin |
|-----|--------|--------|
| `<leader>ff` | Find files | Telescope |
| `<leader>fg` | Grep in files | Telescope |
| `<leader>pr` | Recent files | Telescope |
| `<leader>pWs` | Search word under cursor | Telescope |
| `<leader>pp` | Switch project | Project.nvim + Telescope |
| `<leader>ths` | Theme switcher | Telescope themes |
| `-` | Open file explorer | Oil |

### Session & Workspace Management

| Key | Action | Plugin |
|-----|--------|--------|
| `<leader>ws` | Save session | Auto-session |
| `<leader>wr` | Restore session | Auto-session |
| `<leader>wd` | Delete session | Auto-session |
| `<leader>wf` | Find session | Auto-session |
| `<leader>wl` | List all sessions | Auto-session + Telescope |

### LSP (Language Server)

| Key | Action | Context |
|-----|--------|---------|
| `gd` | Go to definition | Telescope |
| `gD` | Go to declaration | LSP |
| `gR` | Show references | Telescope |
| `gi` | Go to implementation | Telescope |
| `gt` | Go to type definition | Telescope |
| `K` | Hover documentation | LSP |
| `<leader>vca` | Code actions | LSP (Normal & Visual) |
| `<leader>rn` | Rename symbol | LSP |
| `<leader>d` | Show line diagnostics | LSP |
| `<leader>D` | Show buffer diagnostics | Telescope |
| `<leader>rs` | Restart LSP | LSP |
| `Ctrl-h` | Signature help | LSP (INSERT mode) |

### Navigation

| Key | Action |
|-----|--------|
| `Ctrl-o` | Jump to older position |
| `Ctrl-i` | Jump to newer position |
| `g;` | Jump to older change |
| `g,` | Jump to newer change |
| `*` | Search word under cursor forward |
| `#` | Search word under cursor backward |
| `/` | Search forward |
| `?` | Search backward |
| `n` / `N` | Next/Previous search match |
| `%` | Jump to matching bracket |

### Window Management

| Key | Action | Note |
|-----|--------|------|
| `Ctrl-h` | Move to left window | Works with tmux |
| `Ctrl-j` | Move to bottom window | Works with tmux |
| `Ctrl-k` | Move to top window | Works with tmux |
| `Ctrl-l` | Move to right window | Works with tmux |
| `<leader>sm` | Maximize window toggle | vim-maximizer |

### Commenting

| Key | Action | Mode |
|-----|--------|------|
| `gcc` | Toggle line comment | Normal |
| `gc{motion}` | Comment motion | Normal |
| `gc` | Comment selection | Visual |
| `gcap` | Comment paragraph | Normal |

### Diagnostics & Trouble

| Key | Action | Plugin |
|-----|--------|--------|
| `<leader>xw` | Workspace diagnostics | Trouble |
| `<leader>xq` | Quickfix list | Trouble |
| `<leader>xl` | Location list | Trouble |

### Auto-completion (INSERT mode)

| Key | Action | Plugin |
|-----|--------|--------|
| `Ctrl-n` | Next completion | nvim-cmp |
| `Ctrl-p` | Previous completion | nvim-cmp |
| `Ctrl-e` | Close completion | nvim-cmp |
| `Ctrl-y` | Confirm selection | nvim-cmp |
| `Enter` | Confirm selection | nvim-cmp |
| `Tab` | Next snippet field | LuaSnip |
| `Shift-Tab` | Previous snippet field | LuaSnip |
| `Ctrl-E` | Accept autosuggestion | zsh-autosuggestions |

## Telescope Keybindings

**When Telescope is open:**

| Key | Action |
|-----|--------|
| `Ctrl-j` / `Ctrl-k` | Move down/up |
| `Ctrl-n` / `Ctrl-p` | Move down/up (alternative) |
| `Enter` | Select item |
| `Ctrl-x` | Open in horizontal split |
| `Ctrl-v` | Open in vertical split |
| `Ctrl-t` | Open in new tab |
| `Ctrl-u` | Scroll preview up |
| `Ctrl-d` | Scroll preview down |
| `Ctrl-c` / `Esc` | Close Telescope |
| `Ctrl-/` | Show keybindings help |

## Oil (File Explorer) Keybindings

**When Oil is open:**

| Key | Action |
|-----|--------|
| `Enter` | Open file/directory |
| `-` | Go to parent directory |
| `_` | Open in horizontal split |
| `Ctrl-v` | Open in vertical split |
| `Ctrl-t` | Open in new tab |
| `g.` | Toggle hidden files |
| `g?` | Show help |
| `q` | Close Oil |

## Text Objects

Use with operators (`d`, `c`, `y`, `v`):

| Text Object | Description |
|-------------|-------------|
| `iw` / `aw` | inner/around word |
| `iW` / `aW` | inner/around WORD |
| `is` / `as` | inner/around sentence |
| `ip` / `ap` | inner/around paragraph |
| `i"` / `a"` | inside/around double quotes |
| `i'` / `a'` | inside/around single quotes |
| `i`` / `a`` | inside/around backticks |
| `i(` / `a(` | inside/around parentheses |
| `i[` / `a[` | inside/around brackets |
| `i{` / `a{` | inside/around braces |
| `i<` / `a<` | inside/around angle brackets |
| `it` / `at` | inside/around HTML tag |

**Examples:**
- `ciw` - Change inner word
- `da"` - Delete around quotes (including quotes)
- `yip` - Yank inner paragraph
- `vi{` - Visual select inside braces

## Search & Replace

| Command | Action |
|---------|--------|
| `:s/old/new/` | Replace first in line |
| `:s/old/new/g` | Replace all in line |
| `:%s/old/new/g` | Replace all in file |
| `:%s/old/new/gc` | Replace with confirmation |
| `:10,20s/old/new/g` | Replace in lines 10-20 |

## Ex Commands

### File Operations

| Command | Action |
|---------|--------|
| `:w` | Save |
| `:w filename` | Save as |
| `:wa` | Save all |
| `:q` | Quit |
| `:qa` | Quit all |
| `:wq` | Save and quit |
| `:q!` | Quit without saving |
| `:e filename` | Open file |
| `:e!` | Reload file (discard changes) |

### Buffer Management

| Command | Action |
|---------|--------|
| `:bn` / `:bnext` | Next buffer |
| `:bp` / `:bprev` | Previous buffer |
| `:bd` | Delete (close) buffer |
| `:ls` / `:buffers` | List buffers |
| `:b{N}` | Switch to buffer N |
| `:b{name}` | Switch to buffer by name |

### Window Management

| Command | Action |
|---------|--------|
| `:split` / `:sp` | Horizontal split |
| `:vsplit` / `:vs` | Vertical split |
| `:only` | Close all other windows |
| `:close` | Close current window |

### Navigation

| Command | Action |
|---------|--------|
| `:N` | Go to line N |
| `:$` | Go to last line |
| `:jumps` | Show jump list |
| `:changes` | Show change list |
| `:marks` | Show marks |

### Help & Info

| Command | Action |
|---------|--------|
| `:help {topic}` | Open help for topic |
| `:checkhealth` | Check Neovim health |
| `:version` | Show version info |
| `:messages` | Show message history |

### Plugin Management

| Command | Action |
|---------|--------|
| `:Lazy` | Open Lazy.nvim (plugin manager) |
| `:Lazy sync` | Update all plugins |
| `:Mason` | Open Mason (LSP installer) |
| `:LspInfo` | Show LSP information |
| `:LspRestart` | Restart LSP servers |

## Marks

| Key | Action |
|-----|--------|
| `m{a-z}` | Set local mark |
| `m{A-Z}` | Set global mark |
| `'{mark}` | Jump to mark (line) |
| `` `{mark} `` | Jump to mark (exact position) |
| `''` | Jump to last jump |
| ``` `` ``` | Jump to last position |

## Macros

| Key | Action |
|-----|--------|
| `q{register}` | Start recording macro |
| `q` | Stop recording |
| `@{register}` | Play macro |
| `@@` | Repeat last macro |
| `{N}@{register}` | Play macro N times |

## Terminal Mode

| Key | Action |
|-----|--------|
| `Ctrl-\` `Ctrl-n` | Exit terminal mode to NORMAL |
| `i` | Enter terminal mode (from NORMAL) |

## Tmux Integration

These work seamlessly between Neovim and tmux:

| Key | Action |
|-----|--------|
| `Ctrl-h` | Navigate left (vim/tmux) |
| `Ctrl-j` | Navigate down (vim/tmux) |
| `Ctrl-k` | Navigate up (vim/tmux) |
| `Ctrl-l` | Navigate right (vim/tmux) |

## Advanced Vim Keys

### Case Conversion

| Key | Action |
|-----|--------|
| `~` | Toggle case |
| `gU{motion}` | Uppercase |
| `gu{motion}` | Lowercase |
| `gUU` | Uppercase line |
| `guu` | Lowercase line |

### Indentation

| Key | Action |
|-----|--------|
| `>>` | Indent right |
| `<<` | Indent left |
| `==` | Auto-indent |
| `={motion}` | Auto-indent motion |
| `gg=G` | Auto-indent entire file |

**Visual Mode:**
- `>` - Indent selection
- `<` - Unindent selection
- `.` - Repeat indent

### Joining & Splitting

| Key | Action |
|-----|--------|
| `J` | Join next line |
| `gJ` | Join without adding space |

### Numbers

| Key | Action |
|-----|--------|
| `Ctrl-a` | Increment number |
| `Ctrl-x` | Decrement number |
| `{N} Ctrl-a` | Increment by N |

### Folding (if enabled)

| Key | Action |
|-----|--------|
| `zo` | Open fold |
| `zc` | Close fold |
| `za` | Toggle fold |
| `zR` | Open all folds |
| `zM` | Close all folds |

## Quick Reference Card Format

**Most Essential (Print This!):**

```
MODES:           FILES:              CODE:
Esc - Normal     <leader>ff - Find   gd - Definition
i   - Insert     <leader>fg - Grep   K  - Docs
v   - Visual     <leader>pp - Proj   <leader>rn - Rename
:   - Command    -          - Explr  <leader>vca - Actions

EDIT:            NAVIGATE:           WINDOW:
dd  - Del line   w  - Next word      Ctrl-h/j/k/l - Move
yy  - Copy line  /  - Search         <leader>sm   - Max
p   - Paste      gd - Go to def      :split/:vs   - Split
u   - Undo       *  - Find word
.   - Repeat     Ctrl-o - Jump back

SAVE/QUIT:
:w  - Save
:wq - Save & quit
:q! - Quit no save
```

---

**Pro Tip:** Don't memorize everything! Learn 5-10 keys per week, practice them until they're muscle memory, then add more.

**Print or bookmark this page** for quick reference while coding!
