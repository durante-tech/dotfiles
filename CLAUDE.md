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
stow -t ~ zsh nvim tmux starship aerospace ghostty karabiner w3m

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

### Workspace Management (Neovim)

This configuration provides VSCode-like workspace functionality:

**Keybindings**:
- `<leader>pp` - Switch between projects (Telescope)
- `<leader>wr` - Restore session for current directory
- `<leader>ws` - Save session for current directory
- `<leader>wd` - Delete session for current directory
- `<leader>wf` - Find and switch to a session
- `<leader>wl` - List all sessions (Telescope)

**Features**:
- Automatic project detection (looks for .git, package.json, Cargo.toml, etc.)
- Per-project session management (saves buffer state, window layout, etc.)
- Git branch-specific sessions (different session per branch)
- Auto-save on exit, auto-restore on open (for project directories)
- Integration with Telescope for fuzzy finding projects and sessions

### Common Zsh Aliases (from .zshrc)

```bash
# Navigation
ls → eza (with icons)
tree → eza --tree
z <partial> → zoxide jump to directory

# Git shortcuts
gs → git status
ga → git add
gc → git commit
glog → git log --oneline --graph
lg → lazygit

# Tmux
tns → tmux-sessionizer (fzf session finder)
a → tmux attach

# FZF utilities
nlof → fzf recent files and open in nvim
fman → fzf man pages
nzo → zoxide + nvim integration

# Fabric AI (dynamic aliases)
# All patterns from ~/.config/fabric/patterns/* auto-aliased
# e.g., fabric --pattern summarize → fab_summarize

# Claude CLI
c → claude (if installed)
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
| **Karabiner** | `karabiner/.config/karabiner/` | Keyboard remapping with hyperkey system |
| **Scripts** | `scripts/scripts/` | Custom utilities (tmux-sessionizer, fzf helpers) |

### Multi-Monitor Workspace Configuration (AeroSpace)

The aerospace.toml defines workspace-to-monitor mappings:
- **D** (Development) → DEV-MAIN
- **T** (Terminal) → PORTRAIT-MONITOR
- **B** (Browser), **N** (Notes), **M** (Messaging) → DEV-SECOND
- **F** (Finder), **E** (Email) → DEV-SECOND

When modifying workspace assignments, update the `[workspace-to-monitor-force-assignment]` section.

### Neovim Plugin Architecture

**Structure**: Lazy.nvim plugin manager with modular configs in `lua/sethy/plugins/`.

**Key Plugin Categories**:
- UI: noice, lualine, incline, rose-pine colorscheme
- Navigation: telescope, oil (file browser), vim-maximizer
- LSP: Mason (auto-installer), native vim.lsp.config (Neovim 0.11+), formatting, linting
- Git: gitstuff, gitworktree
- Completion: nvim-cmp with LSP integration
- Productivity: trouble, todo-comments, auto-session, snacks
- Workspaces: project.nvim (project detection/switching), auto-session (session management)

**LSP Configuration (Neovim 0.11+)**:
This configuration uses the modern `vim.lsp.config` API instead of the deprecated `require('lspconfig').setup()` pattern. LSP servers are configured in `lua/sethy/plugins/lsp/lspconfig.lua` using:
```lua
vim.lsp.config.server_name = { capabilities, settings, ... }
vim.lsp.enable("server_name")
```

**Adding New Plugins**: Create `lua/sethy/plugins/<plugin-name>.lua` with lazy.nvim spec. It will auto-load on next Neovim launch.

### Tmux Key Bindings

**Prefix**: `Ctrl+b`

**Custom Bindings**:
- `prefix + |` → Split horizontal
- `prefix + -` → Split vertical
- `prefix + h/j/k/l` → Resize panes (vim-style)
- `prefix + m` → Maximize pane
- `prefix + d` → Config menu (quick access to dotfiles)
- `prefix + Ctrl+f` → tmux-sessionizer (fzf session picker)
- **Floating windows** (popup display-popup):
  - `prefix + Ctrl+g` → Lazygit (Git UI)
  - `prefix + Ctrl+y` → Yazi (file manager)
  - `prefix + Ctrl+t` → Zsh (quick terminal)
  - `prefix + Ctrl+m` → rmpc (music player)
  - `prefix + Ctrl+w` → W3m (web browser)

**Plugins** (via TPM):
- vim-tmux-navigator
- tmux-sessionx (enhanced session management)
- tmux-resurrect + continuum (session persistence, auto-save every 15min)
- Catppuccin theme (mocha)

### Ghostty Terminal Key Bindings

**Prefix**: `Cmd+B` (tmux-style)

**Custom Bindings**:
- `Cmd+B > r` → Reload config
- `Cmd+B > c` → New tab
- `Cmd+B > n` → New window
- `Cmd+B > 1-9` → Go to tab N
- `Cmd+B > \` → Split right
- `Cmd+B > -` → Split down
- `Cmd+B > e` → Equalize splits
- `Cmd+B > ,` → Quick terminal
- `Cmd+I` → Inspector toggle

### Shell Initialization Order

1. **`.zprofile`** (login shell)
   - Homebrew environment
   - PATH setup (coreutils, uv, scripts, Mason, Go, Fabric)
   - Environment variables (STARSHIP_CONFIG, FZF_*, NVM_DIR, SSH_AUTH_SOCK)

2. **`.zshrc`** (interactive shell)
   - Starship prompt initialization
   - Plugin loading (zoxide, fzf, atuin)
   - Vim mode setup
   - Alias definitions
   - Fabric AI dynamic alias generation

## Development Patterns

### Making Configuration Changes

**General workflow**:
1. Edit config in `~/dotfiles/<tool>/.config/<tool>/`
2. Test changes (source/reload as needed)
3. Commit changes to git
4. No need to re-stow unless adding new files

**Exception**: If you add NEW files or directories, you may need to re-stow:
```bash
cd ~/dotfiles
stow -R -t ~ <tool>
```

### Adding New Shell Aliases

**Location**: `zsh/.zshrc`

**Pattern**:
```bash
# Add near other aliases (around line 60-120)
alias myalias="command here"

# Then reload
source ~/.zshrc
```

### Adding New Neovim Plugins

**Location**: `nvim/.config/nvim/lua/sethy/plugins/`

**Pattern**:
```lua
-- Create: lua/sethy/plugins/my-plugin.lua
return {
  "author/plugin-name",
  event = "VeryLazy", -- or appropriate lazy-loading event
  config = function()
    -- Plugin setup here
  end,
}
```

Lazy.nvim will auto-detect and load on next Neovim start.

### Adding New LSP Servers (Neovim 0.11+)

**Location**: `nvim/.config/nvim/lua/sethy/plugins/lsp/lspconfig.lua`

**Pattern**:
```lua
-- Get capabilities from cmp (already defined in the file)
-- Add before the Blink.cmp comment section

vim.lsp.config.server_name = {
    capabilities = capabilities,
    filetypes = { "filetype1", "filetype2" },
    settings = {
        -- Server-specific settings
    },
}
vim.lsp.enable("server_name")
```

**Note**: Install the LSP server via Mason (`:Mason`) or manually before enabling.

### Custom Scripts

**Location**: `scripts/scripts/` (automatically in PATH via `.zprofile`)

**Existing Scripts**:
- `tmux-sessionizer` - Fuzzy find projects and create/switch tmux sessions
- `fzf_listoldfiles.sh` - FZF interface for Neovim recent files
- `zoxide_openfiles_nvim.sh` - Zoxide integration with Neovim

**Adding New Scripts**:
1. Create script in `scripts/scripts/`
2. Make executable: `chmod +x scripts/scripts/myscript`
3. No re-stow needed (stowed into `~/scripts/`)
4. Available immediately in PATH

### Language Environment Setup

**Node.js** (via NVM):
```bash
nvm install v23.3.0  # or desired version
nvm use v23.3.0
nvm alias default v23.3.0
```

**Python** (via uv):
```bash
curl -LsSf https://astral.sh/uv/install.sh | sh
# Already in PATH via .zprofile
```

**Go**:
- GOPATH set to `$HOME/go` in `.zprofile`
- Go bin automatically in PATH

**Deno & Bun**:
```bash
# Deno
curl -fsSL https://deno.land/install.sh | sh

# Bun
curl -fsSL https://bun.sh/install | bash
```

### Package Management

**Homebrew packages** (formulae/casks):
- Edit `install.sh` to add new packages
- Or install manually: `brew install <package>`
- Track important packages in install.sh for reproducibility

**Neovim LSP servers** (via Mason):
- Open Neovim: `:Mason`
- Browse and install servers with `i`
- Automatically configured via `lua/sethy/plugins/lsp/lspconfig.lua`

## Special Conventions

### Color Scheme Consistency

**Primary**: Catppuccin Mocha (starship, tmux, ghostty)
**Alternative**: Rose-pine (neovim, wezterm, alacritty)

When adding new tools, prefer Catppuccin Mocha for terminal tools and Rose-pine for editors.

### VI Mode Everywhere

This configuration uses vi-mode keybindings across:
- Zsh (`set -o vi`)
- Tmux copy-mode (`set-window-option -g mode-keys vi`)
- Neovim (native)

When adding new tools, configure vi-mode keybindings where available.

### FZF Integration Pattern

FZF is integrated across multiple tools. When adding new scripts or tools:
1. Use FZF for interactive selection
2. Preview windows with `bat` for file contents
3. Bind to convenient keymaps (see existing patterns in `.zshrc`)

### Hyperkey System (Karabiner)

**Caps Lock** → Hyper (Ctrl+Shift+Cmd+Alt)
- **Hyper alone** → Escape
- **Hyper+Q** → Control key
- **Hyper+[key]** → App launcher shortcuts

See `karabiner/.config/karabiner/README.md` for full keybinding documentation.

## Important Notes

### Git Repository Structure

The repository tracks the dotfiles directory itself. When working with configs:
- Changes to configs are git changes in `~/dotfiles/`
- Symlinked files in `~/.config/` point to `~/dotfiles/`, so edits in either location affect the same files
- Always commit from `~/dotfiles/` directory

### Backup Files

Ghostty and other tools may create `.bak` files (e.g., `config.3ed30444.bak`). These are auto-generated and should be gitignored. Check `.gitignore` if you see unexpected backup files in git status.

### macOS-Specific Configuration

Many configs are macOS-specific (AeroSpace, Karabiner, Ghostty macOS options). When adapting for Linux:
- Replace AeroSpace with i3/sway
- Replace Karabiner with xmodmap/xcape
- Adjust PATH for Linux package managers
- Update coreutils paths (no `/opt/homebrew/`)

### Permission Requirements

Several tools require accessibility permissions on macOS:
- Karabiner Elements (input monitoring, accessibility)
- Raycast (accessibility)
- AeroSpace (accessibility)

Grant these in System Settings → Privacy & Security after first launch.

## Troubleshooting

### Stow Conflicts

If stow reports conflicts, existing files/symlinks are in the way:
```bash
# Backup existing configs
mkdir ~/config_backup
mv ~/.config/nvim ~/config_backup/
mv ~/.zshrc ~/config_backup/

# Then stow
cd ~/dotfiles
stow -t ~ zsh nvim
```

### Command Not Found After Changes

```bash
# Reload shell configuration
source ~/.zprofile
source ~/.zshrc

# Or restart terminal
exec zsh
```

### Neovim Plugins Not Loading

```bash
# Sync plugins
nvim +Lazy sync +qa

# Or inside Neovim
:Lazy sync
```

### Tmux Plugins Not Loading

```bash
# Ensure TPM is installed
git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm

# Inside tmux: prefix + I (Ctrl+b, then Shift+i)
```

### Scripts Not Executable

```bash
chmod +x ~/scripts/*
```

## References

- Repository: [Sin-cy/dotfiles](https://github.com/Sin-cy/dotfiles)
- Main branch: `main`
- Installation guide: `README_NEW_MACOS.md`
- Install script: `install.sh`
