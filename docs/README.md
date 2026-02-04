# Dotfiles Documentation

Complete documentation for this macOS dotfiles configuration.

## Getting Started

New to this setup? Start here:

| Guide | Description |
|-------|-------------|
| **[Quick Start](getting-started/quick-start.md)** | Get productive in 5 minutes |
| **[First Day](getting-started/first-day.md)** | Your first day with this config |
| **[Daily Workflow](getting-started/daily-workflow.md)** | Daily dev workflow reference (git, LSP workspaces, Hyper Key) |
| **[Adding New Tools](getting-started/new-tools-guide.md)** | How to add tools to this setup |

## Tool Documentation

Each configured tool has its own documentation:

### Core Tools

| Tool | Description | Key Features |
|------|-------------|--------------|
| **[Neovim](neovim/README.md)** | Modal editor with LSP | 40+ plugins, Snacks picker, Blink.cmp |
| **[Tmux](tmux/README.md)** | Terminal multiplexer | Sessions, floating popups, vim-navigator |
| **[Zsh](zsh/README.md)** | Shell configuration | 100+ aliases, vi-mode, modern CLI tools |

### Window Management

| Tool | Description | Key Features |
|------|-------------|--------------|
| **[AeroSpace](aerospace/README.md)** | Tiling window manager | Alt-based keys, workspace auto-assignment |
| **[Karabiner](karabiner/README.md)** | Keyboard remapping | Hyperkey (CapsLock), app launchers |
| **[SketchyBar](sketchybar/README.md)** | Custom status bar | System monitors, AeroSpace integration |

### Terminal

| Tool | Description | Key Features |
|------|-------------|--------------|
| **[Ghostty](ghostty/README.md)** | GPU terminal emulator | Tmux-style keys, Rose-pine theme |
| **[Starship](starship/README.md)** | Cross-shell prompt | Catppuccin Mocha, git status |
| **[Yazi](yazi/README.md)** | Terminal file manager | Async I/O, image preview |

### Utilities

| Tool | Description | Key Features |
|------|-------------|--------------|
| **[Scripts](scripts/README.md)** | Custom utilities | tmux-sessionizer, fzf-git |

## Quick Reference Cards

### Most Used Keybindings

| Context | Action | Key |
|---------|--------|-----|
| **Neovim** | Find files | `<leader>ff` |
| **Neovim** | Search in files | `<leader>fg` |
| **Neovim** | File explorer | `-` |
| **Tmux** | New session | `Ctrl+B > N` |
| **Tmux** | Lazygit | `Ctrl+B > Ctrl+G` |
| **Tmux** | Yazi | `Ctrl+B > Ctrl+Y` |
| **AeroSpace** | Focus left/right | `Alt+H/L` |
| **AeroSpace** | Workspace | `Alt+D/T/B/M` |
| **Ghostty** | Split right | `Cmd+B > \` |
| **Shell** | Directory jump | `z <partial>` |

### Color Themes

| Tool | Theme |
|------|-------|
| Terminal (tmux, starship, sketchybar) | Catppuccin Mocha |
| Editor (neovim, ghostty) | Rose-pine |

### Vi-Mode Everywhere

All tools configured with vi-style keybindings:
- Zsh: `set -o vi`
- Tmux: `mode-keys vi`
- Neovim: Native

## Architecture

```
~/dotfiles/
├── aerospace/    → ~/.config/aerospace/
├── ghostty/      → ~/.config/ghostty/
├── karabiner/    → ~/.config/karabiner/
├── nvim/         → ~/.config/nvim/
├── scripts/      → ~/scripts/
├── sketchybar/   → ~/.config/sketchybar/
├── starship/     → ~/.config/starship/
├── tmux/         → ~/.config/tmux/
├── yazi/         → ~/.config/yazi/
├── zsh/          → ~/.zshrc, ~/.zprofile
├── Brewfile      → Declarative packages
└── docs/         → This documentation
```

Managed with **GNU Stow**: `stow -t ~ <tool>`

## Package Management

All packages tracked in `Brewfile`:

```bash
# Install all packages
brew bundle install

# Update Brewfile from current state
brew bundle dump --force --describe
```

## Need Help?

- Check tool-specific docs above
- See [Neovim Troubleshooting](neovim/troubleshooting.md)
- Review [Tmux docs](tmux/README.md)

---

**Tip**: Keep [Neovim Daily Cheatsheet](neovim/daily-cheatsheet.md) open while learning!
