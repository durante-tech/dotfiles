# Dotfiles

macOS-focused dotfiles using GNU Stow for symlink management. Terminal-centric, keyboard-driven development workflow.

## Quick Start

### Fresh Install (New Machine)

```bash
# 1. Install Xcode CLI tools
xcode-select --install

# 2. Clone repository
git clone https://github.com/Sin-cy/dotfiles.git ~/dotfiles
cd ~/dotfiles

# 3. Run installer (installs brew, packages, stows configs)
chmod +x install.sh
./install.sh

# 4. Configure for your machine
./setup.sh --configure
```

### Update (Existing Machine)

```bash
cd ~/dotfiles

# Pull latest changes
git pull

# Re-stow and verify
./setup.sh --all
```

### Setup Script Options

```bash
./setup.sh --check      # Check dependencies and verify symlinks
./setup.sh --stow       # Re-stow all packages
./setup.sh --configure  # Configure for current machine (monitors, paths)
./setup.sh --all        # Run all steps (default)
```

## Post-Install Configuration

### 1. Monitor Setup (AeroSpace)

After install, configure workspace-to-monitor mapping:

```bash
# List your monitors
aerospace list-monitors

# Edit config with your monitor names
nvim ~/.config/aerospace/aerospace.toml
```

Update the `[workspace-to-monitor-force-assignment]` section.

### 2. Project Paths (tmux-sessionizer)

Customize project directories for `prefix + f`:

```bash
# Add to ~/.zshrc or ~/.zprofile
export TMUX_SESSIONIZER_PATHS="$HOME/Projects $HOME/Developer $HOME/dotfiles"
```

### 3. Reload Services

```bash
# Shell
source ~/.zprofile && source ~/.zshrc

# Window manager
aerospace reload-config

# Status bar
sketchybar --reload

# Tmux (inside tmux)
prefix + r

# Neovim plugins
nvim +Lazy sync +qa
```

## What's Included

| Tool | Description |
|------|-------------|
| **zsh** | Shell with starship prompt, vi mode, 70+ aliases |
| **neovim** | IDE-like editor with LSP, Snacks picker, auto-session |
| **tmux** | Terminal multiplexer with session persistence |
| **aerospace** | Tiling window manager |
| **sketchybar** | Custom status bar |
| **ghostty** | Primary terminal emulator |
| **karabiner** | Keyboard remapping (Hyperkey system) |

## Key Bindings

### Tmux (prefix: Ctrl+B)

| Key | Action |
|-----|--------|
| `\|` / `-` | Split h/v |
| `h/j/k/l` | Resize panes |
| `Ctrl+g` | Lazygit (float) |
| `Ctrl+y` | Yazi (float) |
| `f` | tmux-sessionizer |
| `o` | Session picker |

### Neovim (leader: Space)

| Key | Action |
|-----|--------|
| `<leader>pf` | Find files |
| `<leader>ps` | Grep |
| `<leader>pp` | Switch project |
| `<leader>lg` | Lazygit |
| `<leader>ee` | File explorer |

### AeroSpace (Alt-based)

| Key | Action |
|-----|--------|
| `alt+h/j/k/l` | Focus window |
| `alt+shift+h/j/k/l` | Move window |
| `alt+1-2, b,d,f,m,n,t` | Switch workspace |
| `alt+enter` | New terminal |

## Directory Structure

```
dotfiles/
├── aerospace/     → ~/.config/aerospace/
├── ghostty/       → ~/.config/ghostty/
├── karabiner/     → ~/.config/karabiner/
├── nvim/          → ~/.config/nvim/
├── scripts/       → ~/scripts/
├── sketchybar/    → ~/.config/sketchybar/
├── starship/      → ~/.config/starship/
├── tmux/          → ~/.config/tmux/
├── zsh/           → ~/.zshrc, ~/.zprofile
├── install.sh     # Fresh install script
├── setup.sh       # Post-clone configuration
└── CLAUDE.md      # AI assistant context
```

## Manual Stow Commands

```bash
cd ~/dotfiles

# Stow individual package
stow -t ~ nvim

# Re-stow (updates symlinks)
stow -R -t ~ nvim

# Unstow
stow -D -t ~ nvim

# Stow all
stow -t ~ aerospace atuin ghostty karabiner mpd nvim rmpc scripts sketchybar starship tmux w3m yazi zed zsh
```

## Troubleshooting

### Stow Conflicts

```bash
# Backup existing and re-stow
mv ~/.config/nvim ~/.config/nvim.bak
stow -t ~ nvim
```

### Commands Not Found

```bash
source ~/.zprofile && source ~/.zshrc
# or restart terminal
```

### Neovim Plugins

```bash
nvim +Lazy sync +qa
```

### Tmux Plugins

```bash
# Inside tmux: prefix + I
```
