# Dotfiles Enhancement Action Plan

> **Generated**: December 2024
> **Purpose**: Comprehensive improvement plan for dotfiles repository
> **Estimated Impact**: 10x shell startup improvement, cleaner Neovim config, removal of ~300 lines dead code

---

## Table of Contents

1. [Executive Summary](#executive-summary)
2. [Phase 1: Shell Performance (Critical)](#phase-1-shell-performance-critical)
3. [Phase 2: Neovim Optimization](#phase-2-neovim-optimization)
4. [Phase 3: Cleanup & Polish](#phase-3-cleanup--polish)
5. [Phase 4: Future Enhancements](#phase-4-future-enhancements)
6. [Reference: Current Issues Detail](#reference-current-issues-detail)
7. [Reference: Research Findings](#reference-research-findings)

---

## Executive Summary

### Current State
- Shell startup: ~500ms+ (NVM, Oh-My-Zsh overhead)
- Neovim: Redundant plugins (Telescope + Snacks Picker), nvim-cmp instead of faster blink.cmp
- Dead code: neo-tree.lua (disabled), duplicate initializations

### Target State
- Shell startup: ~50ms
- Neovim: Single picker (Snacks), blink.cmp for completions
- Clean config: No dead code, no redundancy

### What's Already Good (Don't Change)
- [x] AeroSpace window manager (best choice for macOS)
- [x] Ghostty terminal (1.0 stable, GPU-accelerated)
- [x] Snacks.nvim (dashboard, explorer, picker)
- [x] Starship prompt (Rust-based, fast)
- [x] Zoxide, FZF, Atuin integrations
- [x] Catppuccin/Rose-pine theming
- [x] Vi-mode everywhere
- [x] tmux with resurrect + continuum

---

## Phase 1: Shell Performance (Critical)

**Priority**: HIGH
**Impact**: ~10x shell startup improvement
**Risk**: LOW (reversible changes)

### Task 1.1: Remove Duplicate NVM Loading

**File**: `zsh/.zprofile`

**Problem**: NVM is loaded TWICE, adding ~400ms to startup.

**Current Code (lines 1-2)**:
```bash
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
```

**Also at (lines 58-61)**:
```bash
export NVM_DIR="$HOME/.nvm"
[ -s "/opt/homebrew/opt/nvm/nvm.sh" ] && \. "/opt/homebrew/opt/nvm/nvm.sh"
[ -s "/opt/homebrew/opt/nvm/etc/bash_completion.d/nvm" ] && \. "/opt/homebrew/opt/nvm/etc/bash_completion.d/nvm"
```

**Action**: Remove lines 1-2 (keep the Homebrew version at lines 58-61)

---

### Task 1.2: Remove Duplicate brew shellenv

**Problem**: `brew shellenv` called twice.

**Location 1** - `zsh/.zprofile` line 4:
```bash
eval "$(/opt/homebrew/bin/brew shellenv)"
```

**Location 2** - `zsh/.zshrc` line 9:
```bash
eval "$(brew shellenv)"
```

**Action**: Remove line 9 from `.zshrc` (keep in `.zprofile` only)

---

### Task 1.3: Remove Duplicate Pyenv Initialization

**Problem**: Pyenv initialized twice.

**Location 1** - `zsh/.zprofile` line 80:
```bash
eval "$(pyenv init --path)"
```

**Location 2** - `zsh/.zshrc` line 85:
```bash
eval "$(pyenv init -)"
```

**Action**: Keep ONLY the `.zshrc` version (`pyenv init -` handles both path and shell integration in modern pyenv)

---

### Task 1.4: Replace NVM with FNM (Recommended)

**Problem**: NVM adds 200-500ms to every shell startup.

**Solution**: FNM (Fast Node Manager) - Rust-based, ~10ms startup.

**Installation**:
```bash
# Remove NVM
rm -rf ~/.nvm
brew uninstall nvm

# Install FNM
brew install fnm

# Update .zprofile - replace NVM section with:
eval "$(fnm env --use-on-cd)"
```

**Migration**:
```bash
# Install your current Node version
fnm install 23.3.0
fnm default 23.3.0
```

**Compatibility**: FNM reads `.nvmrc` and `.node-version` files automatically.

**Alternative** (if keeping NVM): Lazy-load NVM:
```bash
# Replace NVM loading with lazy version
export NVM_DIR="$HOME/.nvm"
nvm() {
  unset -f nvm node npm npx
  [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
  nvm "$@"
}
node() { nvm use default; node "$@"; }
npm() { nvm use default; npm "$@"; }
npx() { nvm use default; npx "$@"; }
```

---

### Task 1.5: Remove Oh-My-Zsh

**Problem**: Loading entire Oh-My-Zsh framework for only 2 plugins (`git`, `web-search`).

**Research Finding**: Oh-My-Zsh consumes 55%+ of shell startup time.

**Current Usage** (`zsh/.zshrc` lines 107-113):
```bash
plugins=(
    git
    web-search
)
```

**Action - Option A (Recommended)**: Remove Oh-My-Zsh entirely

1. Delete Oh-My-Zsh:
```bash
rm -rf ~/.oh-my-zsh
```

2. Remove from `.zprofile`:
```bash
# DELETE this line (around line 37):
export ZSH="$HOME/.oh-my-zsh"
```

3. Remove from `.zshrc`:
```bash
# DELETE this line (around line 15):
source $ZSH/oh-my-zsh.sh

# DELETE the plugins block (lines 107-113)
```

4. Replace `git` plugin with manual aliases (you already have most in your config):
```bash
# Add to .zshrc if missing any you use:
alias g='git'
alias gst='git status'
alias gco='git checkout'
alias gcb='git checkout -b'
alias gp='git push'
alias gl='git pull'
```

5. Replace `web-search` plugin (if you use it):
```bash
# Add to .zshrc:
function google() { open "https://www.google.com/search?q=$*" }
function ddg() { open "https://duckduckgo.com/?q=$*" }
```

**Action - Option B**: Use Zinit (lightweight plugin manager)

```bash
# Install Zinit
bash -c "$(curl --fail --show-error --silent --location https://raw.githubusercontent.com/zdharma-continuum/zinit/HEAD/scripts/install.sh)"

# Replace Oh-My-Zsh in .zshrc with:
source "$HOME/.local/share/zinit/zinit.git/zinit.zsh"

# Load only what you need:
zinit snippet OMZP::git
zinit snippet OMZP::web-search
```

---

### Task 1.6: Optimize Fabric Aliases

**File**: `zsh/.zshrc` lines 199-211

**Problem**: Loops through ALL Fabric patterns on EVERY shell start.

**Current Code**:
```bash
for pattern_file in $HOME/.config/fabric/patterns/*; do
    pattern_name="$(basename "$pattern_file")"
    alias_command="alias $alias_name='fabric --pattern $pattern_name'"
    eval "$alias_command"
done
```

**Solution**: Cache the aliases

```bash
# Create cache file location
FABRIC_ALIAS_CACHE="$HOME/.cache/fabric-aliases.zsh"

# Regenerate if patterns directory is newer than cache
if [[ ! -f "$FABRIC_ALIAS_CACHE" ]] || [[ "$HOME/.config/fabric/patterns" -nt "$FABRIC_ALIAS_CACHE" ]]; then
    mkdir -p "$(dirname "$FABRIC_ALIAS_CACHE")"
    echo "# Auto-generated Fabric aliases" > "$FABRIC_ALIAS_CACHE"
    for pattern_file in $HOME/.config/fabric/patterns/*; do
        pattern_name="$(basename "$pattern_file")"
        echo "alias ${pattern_name}='fabric --pattern ${pattern_name}'" >> "$FABRIC_ALIAS_CACHE"
    done
fi

# Source cached aliases
[[ -f "$FABRIC_ALIAS_CACHE" ]] && source "$FABRIC_ALIAS_CACHE"
```

---

### Task 1.7: Verify Shell Startup Time

**Before changes**, measure current startup:
```bash
time zsh -i -c exit
# or more detailed:
zmodload zsh/zprof  # Add to TOP of .zshrc
zprof               # Add to BOTTOM of .zshrc
# Then open new shell and check output
```

**After changes**, measure again to verify improvement.

**Target**: < 100ms (ideally < 50ms)

---

## Phase 2: Neovim Optimization

**Priority**: HIGH
**Impact**: Faster completions, cleaner config
**Risk**: MEDIUM (test thoroughly)

### Task 2.1: Enable blink.cmp (Replace nvim-cmp)

**Background**: blink.cmp is a Rust-based completion engine that's significantly faster than nvim-cmp. It reached 1.0 stable in late 2024 and is now the default in LazyVim.

**Files to Modify**:
- `nvim/.config/nvim/lua/sethy/plugins/lsp/mason.lua`
- `nvim/.config/nvim/lua/sethy/plugins/lsp/lspconfig.lua`
- `nvim/.config/nvim/lua/sethy/plugins/nvim-cmp.lua`

**Step 1**: Create new blink.cmp config file

Create `nvim/.config/nvim/lua/sethy/plugins/blink-cmp.lua`:
```lua
return {
    "saghen/blink.cmp",
    dependencies = {
        "rafamadriz/friendly-snippets",
        "L3MON4D3/LuaSnip",
    },
    version = "1.*",
    opts = {
        keymap = {
            preset = "default",
            ["<C-k>"] = { "select_prev", "fallback" },
            ["<C-j>"] = { "select_next", "fallback" },
            ["<C-y>"] = { "accept", "fallback" },
            ["<CR>"] = { "accept", "fallback" },
            ["<Tab>"] = { "snippet_forward", "fallback" },
            ["<S-Tab>"] = { "snippet_backward", "fallback" },
            ["<C-space>"] = { "show", "show_documentation", "hide_documentation" },
            ["<C-e>"] = { "cancel", "fallback" },
        },
        appearance = {
            use_nvim_cmp_as_default = true,
            nerd_font_variant = "mono",
        },
        sources = {
            default = { "lsp", "path", "snippets", "buffer" },
        },
        completion = {
            documentation = {
                auto_show = true,
                auto_show_delay_ms = 200,
            },
            menu = {
                draw = {
                    columns = { { "label", "label_description", gap = 1 }, { "kind_icon", "kind" } },
                },
            },
        },
        signature = {
            enabled = true,
        },
    },
    opts_extend = { "sources.default" },
}
```

**Step 2**: Update LSP config to use blink.cmp capabilities

In `nvim/.config/nvim/lua/sethy/plugins/lsp/lspconfig.lua`, uncomment/update:
```lua
-- Change this:
local capabilities = require("cmp_nvim_lsp").default_capabilities()

-- To this:
local capabilities = require("blink.cmp").get_lsp_capabilities()
```

**Step 3**: Disable nvim-cmp

In `nvim/.config/nvim/lua/sethy/plugins/nvim-cmp.lua`, add at top:
```lua
return {
    "hrsh7th/nvim-cmp",
    enabled = false,  -- ADD THIS LINE
    -- ... rest of config
}
```

**Step 4**: Test thoroughly before removing nvim-cmp.lua entirely

---

### Task 2.2: Fix Keybinding Conflict `<leader>pf`

**Problem**: Defined in TWO places:
- `snacks.lua` line 161: `Snacks.picker.files()`
- `telescope.lua` line 49: `builtin.find_files()`

**Action**: Remove from `telescope.lua` (keep Snacks version)

---

### Task 2.3: Migrate Telescope to Snacks Picker

**Current Telescope keymaps** (`telescope.lua`):
- `<leader>pf` - Find files (CONFLICT - remove)
- `<leader>pr` - Recent files
- `<leader>pWs` - Grep word under cursor
- `<leader>ths` - Theme switcher

**Migration**:

Add to `snacks.lua` keys section:
```lua
-- Recent files (replaces Telescope oldfiles)
{ "<leader>pr", function() require("snacks").picker.recent() end, desc = "Recent Files" },

-- Grep word (replaces Telescope grep_string)
{ "<leader>pWs", function() require("snacks").picker.grep_word() end, desc = "Grep Word under cursor", mode = { "n", "x" } },
```

**Theme Switcher**: Keep Telescope ONLY for the theme switcher (telescope-themes extension), OR use Snacks:
```lua
{ "<leader>ths", function() require("snacks").picker.colorschemes() end, desc = "Theme Switcher" },
```

---

### Task 2.4: Delete Telescope (After Migration)

Once all keymaps are migrated:

1. Delete file: `nvim/.config/nvim/lua/sethy/plugins/telescope.lua`

2. Or disable it:
```lua
return {
    "nvim-telescope/telescope.nvim",
    enabled = false,
    -- ...
}
```

---

### Task 2.5: Delete neo-tree.lua

**File**: `nvim/.config/nvim/lua/sethy/plugins/neo-tree.lua`

**Status**: Already `enabled = false` (line 3), but 140 lines of dead code.

**Action**: Delete the entire file:
```bash
rm nvim/.config/nvim/lua/sethy/plugins/neo-tree.lua
```

---

### Task 2.6: Check nvim-tree.lua

**File**: `nvim/.config/nvim/lua/sethy/plugins/nvim-tree.lua`

**Action**: Check if this is also disabled/unused. If so, delete it.

---

### Task 2.7: Review File Explorers

After cleanup, you should have ONLY:
- **Snacks Explorer** (`<leader>ee`) - file tree
- **Oil.nvim** (`-`) - edit filesystem like a buffer
- **mini.files** (optional) - if you use it

Remove any others.

---

## Phase 3: Cleanup & Polish

**Priority**: MEDIUM
**Impact**: Cleaner config, slight performance gains
**Risk**: LOW

### Task 3.1: Optimize Sketchybar Update Frequencies

**File**: `sketchybar/.config/sketchybar/sketchybarrc` and items/*.sh

**Current vs Recommended**:
| Plugin | Current | Recommended | File |
|--------|---------|-------------|------|
| mic.sh | 3s | 10s | items/media_block.sh |
| cpu.sh | 5s | 15s | items/*.sh |
| memory.sh | 10s | 15s | items/*.sh |
| weather.sh | 1800s | 1800s (OK) | - |
| docker.sh | 15s | 30s | items/docker.sh |

**Action**: Update `update_freq` values in respective files.

---

### Task 3.2: Clean Up Terminal Emulator Configs

You have THREE terminal configs:
- `ghostty/` - PRIMARY (keep)
- `wezterm/` - backup (consider removing if unused)
- `alacritty/` - backup (consider removing if unused)

**Action**: If you only use Ghostty, consider:
1. Archiving wezterm/alacritty configs
2. Or removing from stow deployment

---

### Task 3.3: Verify Stow Deployment

After all changes:
```bash
cd ~/dotfiles
stow -R -t ~ zsh nvim tmux
```

---

## Phase 4: Future Enhancements

**Priority**: LOW
**Impact**: Nice to have
**Risk**: MEDIUM (bigger changes)

### Task 4.1: Consider asdf for Version Management

**Current**: NVM (Node) + pyenv (Python) = 2 tools

**Alternative**: asdf = 1 universal tool

```bash
brew install asdf

# Add to .zshrc
. $(brew --prefix asdf)/libexec/asdf.sh

# Install plugins
asdf plugin add nodejs
asdf plugin add python

# Install versions
asdf install nodejs 23.3.0
asdf install python 3.11.0
```

**Pros**: One tool, consistent interface
**Cons**: Migration effort, learning curve

---

### Task 4.2: Consider Zellij as tmux Alternative

**Current**: tmux with TPM plugins

**Alternative**: Zellij (Rust-based, better discoverability)

**Evaluation**: Try Zellij for a week before deciding:
```bash
brew install zellij
zellij
```

**Note**: Your tmux setup is solid. Only switch if Zellij provides clear benefits for your workflow.

---

### Task 4.3: Explore Ghostty Native Splits

Ghostty has native tabs and splits. For simple workflows, you might not need tmux.

**Test**: Try using Ghostty's `Cmd+B` prefix bindings for a session without tmux.

**Keep tmux if**: You need session persistence, complex layouts, or remote work.

---

## Reference: Current Issues Detail

### Shell Issues Summary

| Issue | File | Lines | Impact |
|-------|------|-------|--------|
| NVM loaded twice | .zprofile | 1-2, 58-61 | ~400ms |
| brew shellenv twice | .zprofile, .zshrc | 4, 9 | ~50ms |
| pyenv init twice | .zprofile, .zshrc | 80, 85 | ~100ms |
| Oh-My-Zsh overhead | .zshrc | 15, 107-113 | ~200ms |
| Fabric loop | .zshrc | 199-211 | Variable |

### Neovim Issues Summary

| Issue | File | Impact |
|-------|------|--------|
| blink.cmp disabled | mason.lua, lspconfig.lua | Slower completions |
| `<leader>pf` conflict | snacks.lua, telescope.lua | Unpredictable behavior |
| Telescope redundant | telescope.lua | Extra code, confusion |
| neo-tree dead code | neo-tree.lua | 140 lines unused |

---

## Reference: Research Findings

### Shell Tools Comparison (2024-2025)

| Tool | Speed | Recommendation |
|------|-------|----------------|
| NVM | Slow (200-500ms) | Replace with FNM |
| FNM | Fast (<10ms) | **Recommended** |
| Oh-My-Zsh | Slow (55% startup) | Remove or use Zinit |
| Zinit | Fast | Alternative to OMZ |

### Neovim Completion Comparison

| Plugin | Speed | Status |
|--------|-------|--------|
| nvim-cmp | Good | Mature but slower |
| blink.cmp | Excellent | **1.0 stable, Rust-based** |

### Picker Comparison

| Plugin | Features | Performance |
|--------|----------|-------------|
| Telescope | Many extensions | Good |
| fzf-lua | Fast | No normal mode |
| Snacks Picker | Frecency, normal mode | **Best of both** |

---

## Checklist

### Phase 1: Shell Performance
- [ ] 1.1: Remove duplicate NVM loading
- [ ] 1.2: Remove duplicate brew shellenv
- [ ] 1.3: Remove duplicate pyenv init
- [ ] 1.4: Replace NVM with FNM (or lazy-load)
- [ ] 1.5: Remove Oh-My-Zsh
- [ ] 1.6: Cache Fabric aliases
- [ ] 1.7: Verify shell startup time (<100ms)

### Phase 2: Neovim
- [ ] 2.1: Enable blink.cmp
- [ ] 2.2: Fix `<leader>pf` conflict
- [ ] 2.3: Migrate Telescope keymaps to Snacks
- [ ] 2.4: Delete/disable Telescope
- [ ] 2.5: Delete neo-tree.lua
- [ ] 2.6: Check nvim-tree.lua
- [ ] 2.7: Verify single file explorer

### Phase 3: Cleanup
- [ ] 3.1: Optimize Sketchybar frequencies
- [ ] 3.2: Clean up unused terminal configs
- [ ] 3.3: Re-stow configurations

### Phase 4: Future (Optional)
- [ ] 4.1: Evaluate asdf
- [ ] 4.2: Try Zellij
- [ ] 4.3: Test Ghostty native splits

---

## Notes for Implementation

1. **Make backups** before each phase:
   ```bash
   cp ~/.zshrc ~/.zshrc.backup
   cp ~/.zprofile ~/.zprofile.backup
   ```

2. **Test incrementally** - make one change, test, commit, repeat

3. **Git commits** - commit after each successful task:
   ```bash
   git add -A
   git commit -m "perf(zsh): remove duplicate NVM loading"
   ```

4. **Rollback** if needed:
   ```bash
   git checkout -- path/to/file
   ```

---

*Document generated from comprehensive dotfiles analysis. Last updated: December 2024*
