# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Overview

This is a macOS-focused dotfiles repository using **GNU Stow** for symlink management. The configuration emphasizes terminal-based development workflows with Neovim, Tmux, and keyboard-driven productivity tools.

**Key Architecture Pattern**: Each top-level directory represents a tool/application and mirrors the intended `$HOME` structure. When stowed, these create symlinks from `~/dotfiles/<tool>/.config/<tool>` to `~/.config/<tool>`.

## Core Commands

### Installation & Setup

```bash
# Full automated installation (runs install.sh)
/bin/bash install.sh

# Manual stow all packages from dotfiles directory
stow -t ~ .

# Stow individual packages
stow -t ~ zsh nvim tmux starship aerospace ghostty w3m yazi sketchybar

# Re-stow after configuration changes
stow -R -t ~ zsh nvim tmux w3m

# Unstow a package
stow -D -t ~ zsh
```

**Important**: Before stowing, ensure parent directories exist in `$HOME` (especially `~/.config/`). Stow will fail if these don't exist.

### Development Workflow

```bash
# Testing shell configuration changes
source ~/.zprofile && source ~/.zshrc

# Reload Tmux configuration
# Inside tmux: prefix + r (Ctrl+b, then r)

# Update Neovim plugins
nvim +Lazy sync +qa

# Install Tmux plugins
# Inside tmux: prefix + I (Ctrl+b, then Shift+i)

# Update Homebrew packages
brew update && brew upgrade

# Check Neovim health
nvim -c "checkhealth"
```

## Architecture & Structure

### Deployment System: GNU Stow

Each directory follows this pattern:
```
nvim/
  .config/
    nvim/
      init.lua
      lua/sethy/...

# Stowing creates:
~/.config/nvim → ~/dotfiles/nvim/.config/nvim
```

### Key Configuration Locations

| Tool | Config Path | Description |
|------|-------------|-------------|
| **Zsh** | `zsh/.zprofile` | Login shell initialization, PATH setup, env vars |
| | `zsh/.zshrc` | Interactive shell config, aliases, plugins |
| **Neovim** | `nvim/.config/nvim/init.lua` | Entry point requiring core and plugins |
| | `nvim/.config/nvim/lua/sethy/` | Modular plugin configs (~30 files) |
| **Tmux** | `tmux/.config/tmux/tmux.conf` | Multiplexer config with TPM plugins |
| **Starship** | `starship/.config/starship/starship.toml` | Shell prompt with Catppuccin theme |
| **AeroSpace** | `aerospace/.config/aerospace/aerospace.toml` | macOS window manager, multi-monitor setup |
| **Ghostty** | `ghostty/.config/ghostty/config` | Primary terminal emulator |
| **Yazi** | `yazi/.config/yazi/` | Terminal file manager (keymap, yazi.toml, theme) |
| **W3m** | `w3m/.w3m/config` + `keymap` | Terminal web browser with vi-keys |
| **Sketchybar** | `sketchybar/.config/sketchybar/` | macOS top bar with 20+ status plugins |
| **Scripts** | `scripts/scripts/` | Custom utilities (tmux-sessionizer, fzf helpers) |

---

## Zsh Configuration

### Shell Initialization Order

1. **`.zprofile`** (login shell)
   - Homebrew environment
   - PATH setup (coreutils, uv, scripts, Mason, Go, Fabric, Bun, Deno)
   - Environment variables (STARSHIP_CONFIG, FZF_*, ATUIN_NOBIND, SSH_AUTH_SOCK)
   - SSH agent via **1Password** (macOS socket at `~/Library/Group Containers/...`)
   - FZF configuration (fd-based with .git/node_modules/.venv exclusions)
   - Bun, Deno completions (Node + Python via **mise**, activated in `.zshrc`)

2. **`.zshrc`** (interactive shell)
   - Vi mode (`set -o vi`) + Starship prompt
   - Plugin loading: zoxide, fzf, atuin, **mise** (Node + Python)
   - Keybindings (Ctrl+E accept suggestion, Ctrl+P/N history)
   - Shell functions (web search, yazi, yt)
   - All alias definitions
   - zsh-autosuggestions + zsh-syntax-highlighting
   - Fabric AI dynamic alias generation (cached for performance)
   - Local overrides: `~/.zprofile.local` and `~/.zshrc.local` (machine-specific, not in git)

### Shell Plugins & Integrations

| Plugin | Purpose | Trigger |
|--------|---------|---------|
| **Zoxide** | Smart directory jumping | `z <partial>` |
| **FZF** | Fuzzy finder | `Ctrl+T` (files), `Alt+C` (dirs) |
| **Atuin** | Shell history search | `Ctrl+R` |
| **mise** | Polyglot version manager — Node + Python (replaces fnm/pyenv/nvm) | Auto-switches per `.mise.toml`/`.tool-versions`/`.nvmrc`/`.python-version` |
| **Starship** | Shell prompt | Auto-initialized with vi-mode support |
| **zsh-autosuggestions** | Command suggestions | `Ctrl+E` to accept |
| **zsh-syntax-highlighting** | Syntax coloring | Automatic |

### Shell Keybindings

| Binding | Action |
|---------|--------|
| Vi mode | `set -o vi` (hjkl navigation in command mode) |
| `Ctrl+E` | Accept autosuggestion |
| `Ctrl+P` / `Ctrl+N` | Previous/next history |
| `Ctrl+R` | Atuin history search |
| `Ctrl+T` | FZF file finder |
| `Alt+C` | FZF directory finder |

### Shell Functions

| Function | Usage | Description |
|----------|-------|-------------|
| `google` | `google "search term"` | Open Google search in browser |
| `ddg` | `ddg "search term"` | Open DuckDuckGo search in browser |
| `github` | `github "search term"` | Open GitHub search in browser |
| `ya` | `ya` | Yazi file manager with cd-on-exit |
| `yt` | `yt <url>` or `yt -t <url>` | Download YouTube transcript via Fabric |

### Complete Alias Reference

**Core & Navigation:**

| Alias | Command | Description |
|-------|---------|-------------|
| `c` | `clear` | Clear terminal |
| `e` | `exit` | Exit shell |
| `vim` | `nvim` | Always use Neovim |

**File Listing (Eza):**

| Alias | Description |
|-------|-------------|
| `ls` | Long format with icons and git status |
| `la` | Long format, all files, icons, git |
| `ll` | Long format, all files, headers, groups, sizes |
| `lt` | Tree view (2 levels, git-ignored files hidden) |
| `lt3` | Tree view (3 levels) |
| `lsd` | Directories only |
| `lm` | Sort by modified time (newest first) |
| `lz` | Sort by size (largest first) |
| `lsg` | Git-modified files only |
| `tree` | tree -L 3 (excludes .git) |
| `dtree` | tree -L 3 directories only |

**Modern CLI Replacements (Rust/Go):**

| Alias | Replaces | Tool |
|-------|----------|------|
| `cat` | cat | `bat` (syntax highlighting) |
| `ps` | ps | `procs` |
| `top` / `htop` | top/htop | `btm` (bottom) |
| `curl` | curl | `curlie` (syntax-highlighted HTTP) |
| `du` | du | `dust` (visual disk usage) |

**Productivity Tools:**

| Alias | Tool | Description |
|-------|------|-------------|
| `y` | yazi | Fast terminal file manager |
| `br` | broot | Interactive tree navigation |
| `json` | fx | Interactive JSON viewer |
| `cheat` | navi | Interactive cheatsheets |
| `ginfo` | onefetch | Git repo info (neofetch for repos) |

**Tmux:**

| Alias | Command |
|-------|---------|
| `tmux` | `tmux -f $TMUX_CONF` |
| `a` | `tmux attach` |
| `tns` | `tmux-sessionizer` (FZF project picker) |

**Git:**

| Alias | Command |
|-------|---------|
| `gt` | `git` |
| `ga` | `git add .` |
| `gs` | `git status -s` |
| `gc` | `git commit -m` |
| `gco` | `git checkout` |
| `gcb` | `git checkout -b` |
| `gp` | `git push` |
| `gl` | `git pull` |
| `gd` | `git diff` |
| `gds` | `git diff --staged` |
| `gb` | `git branch` |
| `gba` | `git branch -a` |
| `glog` | `git log --oneline --graph --all` |
| `lg` | `lazygit` |
| `gh-create` | Create private repo + push + open in browser |

**FZF Integrations:**

| Alias | Description |
|-------|-------------|
| `nlof` | FZF recent Neovim files, open selected |
| `fman` | FZF man pages |
| `nzo` | Zoxide + FZF + Neovim combo file opener |

**Claude CLI:**

| Alias | Command |
|-------|---------|
| `cld` | `claude` |
| `cldp` | `claude -p` (project mode) |
| `cldo` | `claude --model opus` |
| `clds` | `claude --model sonnet` |
| `cldy` | `claude --dangerously-skip-permissions --model sonnet` |
| `cldyo` / `lfg` | `claude --dangerously-skip-permissions --model opus` |
| `cldr` | `claude --resume` |

**Fabric AI:**

| Alias | Command |
|-------|---------|
| `fb` | `fabric` |
| `fbp` | `fabric --pattern` |
| `fbl` | `fabric --listpatterns` |
| `fbs` | `fabric --stream` |
| `fbsp` | `fabric --stream --pattern` |
| `{pattern}` | Auto-generated per-pattern aliases (cached in `~/.cache/fabric-aliases.zsh`) |

**Other:**

| Alias | Description |
|-------|-------------|
| `nvim-scratch` | Launch nvim with separate NVIM_APPNAME config |
| `air` | Go live-reload server |
| `mpds` | Start mpd music daemon |
| `pai` | PAI tool (bun ~/.claude/skills/PAI/Tools/pai.ts) |

---

## Neovim Configuration

**Leader Key**: `<Space>`

### Core Keymaps (`lua/sethy/core/keymaps.lua`)

**Movement:**

| Binding | Mode | Action |
|---------|------|--------|
| `J` / `K` | Visual | Move selected lines down/up |
| `<C-d>` / `<C-u>` | Normal | Half-page down/up (centered) |
| `n` / `N` | Normal | Next/prev search result (centered) |
| `j` / `k` | Normal | Visual line navigation (respects wrapping) |

**Editing:**

| Binding | Mode | Action |
|---------|------|--------|
| `<leader>p` | Visual | Paste without losing clipboard |
| `<leader>Y` | Normal | Copy to system clipboard |
| `<leader>dd` | Normal | Delete without clipboard |
| `x` | Normal | Delete char without clipboard |
| `<leader>s` | Normal | Find-replace word under cursor |

**File Operations:**

| Binding | Mode | Action |
|---------|------|--------|
| `<C-c>` | Normal | Clear search highlight |
| `<leader>f` | Normal | Format file (LSP) |
| `<leader>x` | Normal | Make file executable |
| `<leader>fp` | Normal | Copy file path to clipboard |

**Splits & Tabs:**

| Binding | Action |
|---------|--------|
| `<leader>sv` / `sh` / `se` / `sx` | Vertical / horizontal / equalize / close split |
| `<leader>sm` | Maximize/restore split (vim-maximizer) |
| `<leader>to` / `tx` / `tn` / `tp` / `tf` | New / close / next / prev / current-file tab |
| `<leader>tw` | Toggle line wrapping |
| `<leader>lx` | Toggle diagnostics visibility |

**Auto-Features:**
- Highlight yanked text on copy
- `<C-f>` opens tmux-sessionizer in new tmux window

### Navigation & Selection

**Flash** (`flash.lua`) - Jump anywhere instantly:

| Binding | Mode | Action |
|---------|------|--------|
| `s` | Normal | Flash jump (press 2 chars to jump) |
| `S` | Normal | Treesitter flash (jump to code structures) |
| `r` | Operator-pending | Remote flash |
| `R` | Operator-pending/Visual | Treesitter search |
| `<leader>fl` | Normal | Jump to line |
| `<leader>fw` | Normal | Jump to word |

**Harpoon** (`harpoon.lua`) - Quick file marks:

| Binding | Action |
|---------|--------|
| `<leader>a` | Add file to harpoon |
| `<C-e>` | Toggle quick menu |
| `<C-y>` / `<M-i>` / `<C-n>` / `<C-s>` | Jump to mark 1 / 2 / 3 / 4 |
| `<C-S-P>` / `<C-S-N>` | Previous / next mark |

**Oil** (`oil.lua`) - File browser:

| Binding | Action |
|---------|--------|
| `-` | Open parent directory |
| `<leader>-` | Open parent in float |
| `q` | Close oil |

### Picker / Fuzzy Finding (Snacks Picker)

| Binding | Action |
|---------|--------|
| `<leader>pf` | Find files |
| `<leader>pr` | Recent files |
| `<leader>pc` | Find config file |
| `<leader>ps` | Grep word |
| `<leader>pws` | Search visual selection or word under cursor |
| `<leader>pk` | Search keymaps |
| `<leader>pT` | Find TODO/FIXME comments |
| `<leader>pt` | Find all todo comments |
| `<leader>th` | Pick colorscheme |
| `<leader>vh` | Help pages |

### File Explorers

| Binding | Action |
|---------|--------|
| `<leader>ee` | Toggle Snacks explorer |
| `<leader>ef` | Reveal current file in explorer |
| `<leader>em` | Mini files browser |
| `<leader>eM` | Reveal current file in Mini files |

### Git Integration

**Fugitive:**

| Binding | Action |
|---------|--------|
| `<leader>gg` | Open git status |
| `<leader>P` | Push (in fugitive buffer) |
| `<leader>p` | Pull with rebase (in fugitive buffer) |

**Gitsigns** (line-by-line git):

| Binding | Action |
|---------|--------|
| `]h` / `[h` | Next / previous hunk |
| `<leader>gs` | Stage hunk (or visual range) |
| `<leader>gr` | Reset hunk (or visual range) |
| `<leader>gS` / `<leader>gR` | Stage / reset buffer |
| `<leader>gu` | Undo stage |
| `<leader>gp` | Preview hunk |
| `<leader>gbl` | Blame line |
| `<leader>gB` | Toggle current line blame |
| `<leader>gd` / `<leader>gD` | Diff this / diff against ~ |

**Snacks Git:**

| Binding | Action |
|---------|--------|
| `<leader>lg` | Open lazygit |
| `<leader>gl` | View git logs |
| `<leader>gf` | Git changed files |
| `<leader>gbr` | Pick and switch git branches |

### Workspace & Session Management

| Binding | Action |
|---------|--------|
| `<leader>pp` | Switch between projects (auto-detects .git, package.json, Cargo.toml, go.mod, etc.) |
| `<leader>wr` | Restore session for cwd |
| `<leader>ws` | Save session for cwd |
| `<leader>wd` | Delete session for cwd |
| `<leader>wf` | Find and switch session |

Sessions are git-branch-specific, auto-save on exit, auto-restore on open.

### LSP & Completion

**LSP Keybindings** (active when LSP attaches):

| Binding | Action |
|---------|--------|
| `gR` | Show references |
| `gD` | Go to declaration |
| `gd` | Go to definition |
| `gi` | Go to implementation |
| `gt` | Go to type definition |
| `K` | Hover documentation |
| `<leader>vca` | Code actions |
| `<leader>rn` | Rename symbol |
| `<leader>D` | Buffer diagnostics |
| `<leader>d` | Line diagnostic float |
| `<leader>rs` | Restart LSP |
| `<C-h>` (insert) | Signature help |

**Configured LSP Servers**: lua_ls, ts_ls, emmet_language_server, denols, gopls

**Mason Auto-installs**: lua_ls, ts_ls, html, cssls, tailwindcss, gopls, angularls, emmet_language_server, marksman

**Blink.cmp** (Rust-based completion):

| Binding | Action |
|---------|--------|
| `<C-j>` / `<C-k>` or `<C-n>` / `<C-p>` | Navigate completions |
| `<C-y>` or `<CR>` | Accept |
| `<Tab>` / `<S-Tab>` | Navigate snippets / completions |
| `<C-space>` | Toggle documentation |
| `<C-b>` / `<C-f>` | Scroll documentation |
| `<C-e>` | Cancel |

### Formatting & Linting

**Conform** (format on save enabled):

| Language | Formatter |
|----------|-----------|
| JS/TS | biome (primary) or prettier |
| HTML/CSS/YAML/JSON | prettier |
| Python | black + isort |
| Go | goimports + gofumpt |
| Rust | rustfmt |
| Lua | stylua |
| Shell | shfmt |
| TOML | taplo |
| SQL | sql-formatter |

| Binding | Action |
|---------|--------|
| `<leader>mp` | Format file/range (async, 3s timeout) |
| `<leader>mf` | Format injected code |

**Nvim-Lint**: biomejs (JS/TS), pylint (Python). Auto-lints on save/enter/leave-insert. `<leader>l` for manual lint.

### Code Editing Features

**Mini.surround** - Surround text with pairs:

| Binding | Action | Example |
|---------|--------|---------|
| `sa` | Add surrounding | `saiw"` wraps word in quotes |
| `ds` | Delete surrounding | `ds"` removes quotes |
| `sr` | Replace surrounding | `sr"'` changes `"` to `'` |

**Mini.splitjoin**: `sj` join arguments, `sk` split arguments

**Mini.trailspace**: `<leader>cw` erase trailing whitespace

**Emmet**: `<leader>xe` wrap with abbreviation (visual mode)

**Auto-features**: autopairs (treesitter-aware), auto-close HTML/JSX tags, auto-rename matching tags

### Diagnostics & Folding

**Trouble:**

| Binding | Action |
|---------|--------|
| `<leader>xw` | Workspace diagnostics |
| `<leader>xd` | Document diagnostics |
| `<leader>xq` | Quickfix list |
| `<leader>xl` | Location list |
| `<leader>xt` | TODO comments |

**UFO Folding**: `zR` open all, `zM` close all, `za` toggle at cursor

**Todo Comments**: `]t` / `[t` to jump. Keywords: FIX, TODO, HACK, WARN, PERF, NOTE, TEST, FORGETNOT

### Markdown Features

**Render Markdown** (`render-markdown.nvim`): Beautiful in-buffer rendering with colored headings, checkboxes, bullets, styled code blocks

**Markdown Preview** (`markdown-preview.nvim`): `<leader>mp` opens browser preview with **Mermaid diagram support** (dark theme)

**Markdown Filetype Bindings** (`after/ftplugin/markdown.lua`):

| Binding | Mode | Action |
|---------|------|--------|
| `tn` | Normal/Visual | Toggle numbers |
| `tb` | Normal/Visual | Toggle bullets |
| `tc` | Normal/Visual | Toggle checkboxes |
| `tt` | Normal/Visual | Toggle task state |
| `tl` | Normal/Visual | Smart list toggle (cycles: bullets > checkboxes > numbers > plain) |
| `<leader>tc` | Normal | Mark all tasks done |
| `<leader>tu` | Normal | Mark all tasks undone |

Spell checking enabled, textwidth 80 for markdown files.

### Advanced Features

**Molten** (Jupyter notebooks in nvim):

| Binding | Action |
|---------|--------|
| `<leader>mi` / `<leader>mI` | Initialize kernel / Python3 |
| `<leader>me` / `<leader>ml` / `<leader>mv` | Evaluate operator / line / visual |
| `<leader>mc` / `<leader>mr` | Evaluate cell / re-evaluate |
| `<leader>mo` / `<leader>mh` | Show / hide output |
| `[m` / `]m` | Previous / next cell |
| `<leader>rr` / `<leader>ra` | Run cell / run all |

**Image Support**: `<leader>pi` paste image from clipboard (requires `brew install pngpaste`)

**PDF Reader**: `<leader>pb` bookmarks, `<leader>pt` TOC, `<leader>pd` dark mode

**Debugging (DAP)**: `<leader>db` toggle breakpoint, `<leader>dc` continue. Go debugging via dap-go.

**Undo Tree**: `<leader>u` toggle visual undo history

**Showkeys**: `ShowkeysToggle` displays last 3 keypresses in floating window

**Faster.nvim**: Auto-disables expensive features for files >1MB

### Claude Code Integration

| Binding | Action |
|---------|--------|
| `<leader>ac` | Toggle Claude Code terminal |
| `<leader>af` | Focus Claude Code |
| `<leader>as` | Send selection to Claude (visual) |
| `<leader>aa` / `<leader>ad` | Accept / reject diff |
| `<leader>al` | Local mode |
| `<leader>am` / `<leader>aM` | Full MCPs / full + resume |
| `<leader>aw` / `<leader>aW` | Dev-work MCPs / dev-work + resume |
| `<leader>ar` | Resume session |

### Plugin Architecture

**Structure**: Lazy.nvim plugin manager with modular configs in `lua/sethy/plugins/`.

**Key Plugin Categories**:
- UI: noice, lualine, incline, rose-pine colorscheme
- Navigation: flash (jump), oil (file browser), snacks explorer, harpoon (marks), vim-maximizer
- Picker: snacks.nvim picker (fuzzy finding, replaces telescope)
- LSP: Mason (auto-installer), native vim.lsp.config (Neovim 0.11+), formatting (conform), linting (nvim-lint)
- Git: fugitive, gitsigns, lazygit (via snacks)
- Completion: blink.cmp (Rust-based, fast) with LSP/path/snippet/buffer sources
- Editing: mini.surround, mini.comment, mini.splitjoin, autopairs, treesitter auto-tag, emmet
- Diagnostics: trouble, todo-comments
- Markdown: render-markdown, markdown-preview (with Mermaid), custom filetype bindings
- Jupyter: molten.nvim
- Productivity: auto-session, project.nvim, undotree, snacks
- AI: claudecode.nvim

**LSP Configuration (Neovim 0.11+)**:
Uses the modern `vim.lsp.config` API:
```lua
vim.lsp.config.server_name = { capabilities, settings, ... }
vim.lsp.enable("server_name")
```

**Adding New Plugins**: Create `lua/sethy/plugins/<plugin-name>.lua` with lazy.nvim spec. Auto-loads on next launch.

**Treesitter Parsers**: json, javascript, typescript, tsx, go, yaml, html, css, python, http, prisma, markdown, markdown_inline, svelte, graphql, bash, lua, vim, dockerfile, gitignore, rust, java, and more.

---

## Tmux Configuration

**Prefix**: `Ctrl+b` (tmux default)

### Core Bindings

| Binding | Action |
|---------|--------|
| `prefix + r` | Reload tmux config |
| `prefix + D` | Detach session |
| `prefix + \|` | Split horizontal (preserves path) |
| `prefix + -` | Split vertical (preserves path) |
| `prefix + v` | Enter copy-mode |
| `prefix + m` | Maximize/restore pane (zoom) |
| `prefix + Ctrl+k` | Clear pane (reset terminal + wipe scrollback) |

### Pane Resizing (Repeatable)

| Binding | Action |
|---------|--------|
| `prefix + H/J/K/L` | Resize pane left/down/up/right (5 units) |

### Session Management

| Binding | Action |
|---------|--------|
| `prefix + f` | tmux-sessionizer (FZF project picker) |
| `prefix + n` | New session with custom name |
| `prefix + o` | SessionX (enhanced session switcher) |

### Floating Windows (display-popup)

| Binding | Tool | Size |
|---------|------|------|
| `prefix + Ctrl+y` | Yazi (file manager) | 90% |
| `prefix + Ctrl+g` | Lazygit (Git UI) | 90% |
| `prefix + Ctrl+t` | Quick zsh terminal | 80% |
| `prefix + Ctrl+m` | rmpc (music player) | 95% |
| `prefix + Ctrl+w` | W3m (web browser at DuckDuckGo) | 90% |

### Config Menu

`prefix + d` opens a menu for quick dotfile editing:
- `z` → ~/.zshrc
- `p` → ~/.zprofile
- `t` → tmux.conf
- `v` → ~/.config/nvim

### Layout Presets

| Binding | Layout |
|---------|--------|
| `Alt+1` | Main-vertical (main left, stack right) |
| `Alt+2` | Main-horizontal (main top, stack bottom) |
| `Alt+3` | Tiled (equal grid) |
| `Alt+4` | Even-horizontal (side by side) |
| `Alt+5` | Even-vertical (stacked) |
| `prefix + F2` | Layout selection menu |

### Copy-Mode (Vi-Mode)

| Binding | Action |
|---------|--------|
| `v` | Begin selection |
| `y` | Copy selection (to system clipboard via pbcopy) |
| `Y` | Copy cursor to end of line |
| `Ctrl+v` | Toggle rectangle/block selection |
| Drag mouse | Select and auto-copy |
| Double-click | Select word and copy |
| Triple-click | Select line and copy |
| Middle-click | Paste from clipboard |

### Status Bar

**Left**: Session name (red when prefix active), current path, git branch, zoom indicator, window/pane count
**Right**: Battery (red if <=10%), online status, date/time

### Plugins (TPM)

- **vim-tmux-navigator**: Seamless vim/tmux pane navigation
- **tmux-sessionx**: Enhanced session management (`prefix + o`)
- **tmux-resurrect + continuum**: Session persistence (auto-save every 15min)
- **Catppuccin theme** (mocha flavor)
- **tmux-online-status**: Network indicator
- **tmux-battery**: Battery display

---

## AeroSpace (Window Manager)

### Workspace-to-Monitor Mapping

| Workspace | Monitor | Apps |
|-----------|---------|------|
| **1** | Built-in Retina | Main workspace |
| **2** | Portrait Monitor | Secondary |
| **D** (Development) | Built-in | IDEs, Cursor, VS Code |
| **T** (Terminal) | Portrait Monitor | Ghostty, terminals |
| **B** (Browser) | Built-in | Chrome, Safari, Firefox |
| **M** (Messaging) | Built-in | Slack, Discord, Telegram |
| **N** (Notes) | Built-in | Notion, Obsidian, ChatGPT, Claude |
| **F** (Finder) | Floating layout | Finder |
| **E** (Email) | Built-in | Spark, Apple Mail |

### Main Keybindings (Alt key prefix)

| Binding | Action |
|---------|--------|
| `Alt+h/j/k/l` | Focus window left/down/up/right |
| `Alt+Shift+h/j/k/l` | Move window left/down/up/right |
| `Alt+Ctrl+h/j/k/l` | Swap adjacent windows |
| `Alt+[` / `Alt+]` | Cycle through windows |
| `Alt+1/2/B/D/T/M/N/F` | Switch to workspace |
| `Alt+Shift+1/2/B/D/T/M/N/F` | Move window to workspace |
| `Alt+Tab` | Workspace back-and-forth |
| `Alt+Shift+Tab` | Move workspace to other monitor |
| `Alt+Enter` | Open Ghostty |
| `Alt+Shift+Space` | Fullscreen toggle |
| `Alt+/` | Toggle layout (tiles/horiz/vert) |
| `Alt+,` | Accordion layout |
| `Alt+.` | Floating layout |
| `Alt+Shift+c` | Close window |
| `Alt+r` | Reload config |
| `Alt+s` | Toggle sketchybar |

### Resize Mode

Enter with `Alt+Shift+r`, then:
- `h/j/k/l` to resize (50 units per press)
- `b` to balance sizes
- `Enter` / `Esc` to exit

### Gaps & Spacing

Inner/outer gaps: 15px. Accordion padding: 30px. Portrait monitor top gap: 50px.

---

## Ghostty Terminal

**Prefix**: `Cmd+B` (tmux-style chord keybindings)

| Binding | Action |
|---------|--------|
| `Cmd+B > r` | Reload config |
| `Cmd+B > x` | Close tab |
| `Cmd+B > c` | New tab |
| `Cmd+B > n` | New window |
| `Cmd+B > 1-9` | Go to tab N |
| `Cmd+B > \` | Split right |
| `Cmd+B > -` | Split down |
| `Cmd+B > e` | Equalize splits |
| `Cmd+B > h/j/k/l` | Navigate splits (vim-style) |
| `Cmd+B > ,` | Quick terminal |
| `Cmd+I` | Inspector toggle |

**Visual**: Rose-pine theme, 75% opacity, 23px blur, JetBrainsMono Nerd Font (16pt), yellow blinking cursor.

---

## Yazi (Terminal File Manager)

Vi-style keybindings. Hidden files shown by default. Directories first, natural sort.

### Navigation

| Keys | Action |
|------|--------|
| `h/j/k/l` | Parent / down / up / enter |
| `gg` / `G` | Top / bottom |
| `Ctrl+u` / `Ctrl+d` | Half-page up / down |

### File Operations

| Keys | Action |
|------|--------|
| `y` / `x` / `p` | Copy / cut / paste |
| `P` | Paste (overwrite) |
| `a` | Create file/directory |
| `r` | Rename |
| `d` / `D` | Trash / permanently delete |
| `Space` | Toggle selection |
| `v` / `V` | Visual mode / visual unset |
| `Ctrl+a` | Select all |

### Quick Navigation (g prefix)

| Keys | Destination |
|------|-------------|
| `gh` | Home |
| `gc` | Config (~/.config) |
| `gd` | Dotfiles |
| `gD` | Downloads |
| `gp` | Projects |
| `gt` | Temp |

### Searching

| Keys | Action |
|------|--------|
| `f` | Filter files |
| `s` / `S` | Search by name (fd) / content (ripgrep) |
| `z` / `Z` | Zoxide jump / FZF jump |

### Sorting (comma prefix)

`,m` modified, `,s` size, `,a` alpha, `,e` extension, `,n` natural. Uppercase reverses.

### Copy Paths

`cc` absolute path, `cd` parent directory, `cf` filename, `cn` filename without extension.

### Tabs

`t` create, `1/2/3` switch, `[/]` prev/next, `{/}` swap.

---

## W3m (Terminal Web Browser)

Vi-style keybindings. Catppuccin Mocha colors. Image display enabled.

| Keys | Action |
|------|--------|
| `h/j/k/l` | Navigate |
| `Ctrl+f/b` | Page forward/back |
| `gg` / `G` | Top / bottom |
| `f` / `F` | Move to link / link list |
| `t` / `T` | New tab / tab menu |
| `Ctrl+h/l` | Previous / next tab |
| `d` | Close tab |
| `/` / `?` | Search forward / back |
| `H` / `L` | History back / forward |
| `o` / `O` | Go to URL / tab go to URL |
| `v` | View source |
| `a` / `b` | Add / view bookmarks |
| `M` | Open in default browser |
| `q` / `Q` | Quit |

---

## Starship Prompt

**Theme**: Catppuccin Mocha. Shows directory (with icon substitutions), git branch (with remote provider icon), git status, programming language versions.

### Vi-Mode Character Indicators

| Mode | Character | Color |
|------|-----------|-------|
| Normal (command) | `>` | Green |
| Insert | `x` | Green (success) / Red (error) |
| Replace | `>` | Purple |
| Visual | `>` | Lavender |

### Directory Substitutions

Documents -> icon, Downloads -> icon, Music -> icon, Pictures -> icon, Github -> icon, Developer -> icon, Durante -> icon, Study -> icon.

### Language Detection

Auto-detects and shows versions for: Node.js, C, Rust, Go, PHP, Java, Kotlin, Haskell, Python, Docker context.

---

## Sketchybar (macOS Top Bar)

Modular plugin architecture with Catppuccin colors and Hack Nerd Font.

### Sections

**Left**: Workspace indicators (AeroSpace integration), front app, Docker status
**Left-Middle**: MacUpdater, ClearVPN, voice server, calendar
**Right**: Clock, weather, CPU, memory, microphone, network, GitHub notifications, media player (Spotify/Music), battery

Hot-reloads on config change. Receives `aerospace_workspace_change` events.

---

## Custom Scripts

**Location**: `scripts/scripts/` (in PATH via `.zprofile`)

| Script | Alias | Description |
|--------|-------|-------------|
| `tmux-sessionizer` | `tns` | FZF project picker, creates/switches tmux sessions. Searches ~/dotfiles, ~/Projects, ~/Developer. Runs `.tmux-sessionizer` in project root if present. |
| `fzf_listoldfiles.sh` | `nlof` | FZF recent Neovim files with bat preview, opens in nvim |
| `zoxide_openfiles_nvim.sh` | `nzo` | Zoxide + fd + FZF + bat preview, opens in nvim |
| `fzf-git.sh` | (sourced) | FZF-enhanced git: branch browser, commit viewer, ref inspector. `Ctrl+O` open in browser, `Ctrl+D` show diff |

**Adding New Scripts**: Create in `scripts/scripts/`, `chmod +x`, available immediately (no re-stow needed).

---

## Development Patterns

### Making Configuration Changes

1. Edit config in `~/dotfiles/<tool>/.config/<tool>/`
2. Test changes (source/reload as needed)
3. Commit changes to git
4. No need to re-stow unless adding new files

**Exception**: New files/directories require re-stow: `stow -R -t ~ <tool>`

### Adding New Shell Aliases

**Location**: `zsh/.zshrc` (near existing aliases). Then `source ~/.zshrc`.

### Adding New Neovim Plugins

Create `lua/sethy/plugins/<plugin-name>.lua` with lazy.nvim spec. Auto-loads on next launch.

### Adding New LSP Servers (Neovim 0.11+)

**Location**: `nvim/.config/nvim/lua/sethy/plugins/lsp/lspconfig.lua`

```lua
vim.lsp.config.server_name = {
    capabilities = capabilities,
    filetypes = { "filetype1", "filetype2" },
    settings = { },
}
vim.lsp.enable("server_name")
```

Install via Mason (`:Mason`) or manually before enabling.

### Language Environment Setup

**Node.js & Python** (via **mise** — polyglot manager, replaces fnm/pyenv/nvm; auto-switches per `.mise.toml`/`.tool-versions`/`.nvmrc`/`.python-version`):
```bash
mise use -g node@lts     # or a pinned version, e.g. node@24
mise use -g python@3.12
mise install             # install everything a project's config pins
mise current             # show active versions
```
Python packaging uses **uv** (already in PATH via `.zprofile`).

**Go**: GOPATH at `$HOME/go`, bin in PATH.

**Deno & Bun**: Auto-sourced from `.deno/env` and `.bun` if installed.

---

## Special Conventions

### Color Scheme Consistency

**Terminal tools**: Catppuccin Mocha (starship, tmux, ghostty, sketchybar, w3m)
**Editor**: Rose-pine (neovim)

When adding new tools, follow this pattern.

### VI Mode Everywhere

Vi-mode keybindings across: Zsh, Tmux copy-mode, Neovim, Yazi, W3m, AeroSpace (hjkl navigation). Configure vi-mode for any new tools.

### FZF Integration Pattern

FZF is integrated across: zsh (Ctrl+T, Alt+C), tmux-sessionizer, Neovim pickers, Yazi (Z key), fzf-git.sh. Use FZF with bat previews for any new scripts.

---

## Important Notes

### Git Repository Structure

- Changes to configs are git changes in `~/dotfiles/`
- Symlinked files in `~/.config/` point to `~/dotfiles/`, edits in either location affect the same files
- Always commit from `~/dotfiles/` directory

### Local Override Files

- `~/.zprofile.local` and `~/.zshrc.local` are sourced if they exist (machine-specific, not in git)

### 1Password SSH Agent

SSH_AUTH_SOCK points to 1Password's agent socket for SSH key management. Keys managed in 1Password, not as files on disk.

### macOS-Specific Configuration

AeroSpace, Ghostty macOS options, Sketchybar are macOS-only. For Linux: replace AeroSpace with i3/sway, adjust PATH (no `/opt/homebrew/`), replace pbcopy/pbpaste.

### Permission Requirements

- AeroSpace (accessibility)
- Raycast (accessibility)

Grant in System Settings > Privacy & Security after first launch.

---

## Troubleshooting

### Stow Conflicts

```bash
mkdir ~/config_backup
mv ~/.config/nvim ~/config_backup/
mv ~/.zshrc ~/config_backup/
cd ~/dotfiles && stow -t ~ zsh nvim
```

### Command Not Found After Changes

```bash
source ~/.zprofile && source ~/.zshrc
# Or: exec zsh
```

### Neovim Plugins Not Loading

```bash
nvim +Lazy sync +qa
# Or inside Neovim: :Lazy sync
```

### Tmux Plugins Not Loading

```bash
git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
# Inside tmux: prefix + I (Ctrl+b, then Shift+i)
```

### Scripts Not Executable

```bash
chmod +x ~/scripts/*
```

## References

- Repository: [durante-tech/dotfiles](https://github.com/durante-tech/dotfiles) (forked from [Sin-cy/dotfiles](https://github.com/Sin-cy/dotfiles))
- Main branch: `main`
- Installation guide: `README_NEW_MACOS.md`
- Install script: `install.sh`

## Sentinel Conventions
<!-- Auto-generated body lives in docs/Sentinel/SNAPSHOT.md. Next sentinel scan writes there, not back into this section. -->

- **Stack:** macOS-only dotfiles deployed via GNU Stow across ~22 packages; polyglot — Zsh/Bash (config + automation), Lua (Neovim/lazy.nvim), TOML (AeroSpace/Starship), plus Bun-run TypeScript scripts and an Astro/React docs site under `site/`.
- **Test:** `# no automated suite — verify manually`. **Lint:** `# CI: .github/workflows/lint.yml`.
- **Health:** 100% (21 healthy / 21 conventions, 3 debt indicators) — last scan 2026-06-24.
- **Enforced patterns:** kebab-case script names; `snake_case()` shell functions; `DOTFILES_`-prefixed override vars; `set -e`/`set -u` after shebang; `#!/usr/bin/env bash` (`#!/bin/bash` for launchd/bash-3.2 scripts); `#!/usr/bin/env bun` for TS scripts; `command -v <tool> && eval` guards in `.zshrc`; one-file-per-plugin `return { ... }` Neovim specs; `personal.env` existence-guarded sourcing; LaunchAgents as `.plist.template` (`__USER__` placeholder, rendered by setup.sh; repo-owned `com.lucas.*` supersedes brew-services); Raycast script-commands `exec`-delegate to canonical scripts; compiled native helpers (Swift, e.g. `unlock-watch.swift`) built to `~/.local/bin` by setup.sh `build_native_helpers()` (`swiftc`-guarded) for triggers launchd can't express (distributed notifications).
- **Full snapshot** (Tech Stack, Architecture, Conventions, Key Decisions, Setup, Health, open debt): [`docs/Sentinel/SNAPSHOT.md`](docs/Sentinel/SNAPSHOT.md).
- **Architecture artifacts:** `docs/Sentinel/MODULE-MAP.md`, `C4-CONTEXT.md`, `C4-CONTAINER.md`, `ADRS.md`, `TECH-DEBT.md`, `DURANTE-NATIVE.md`.
