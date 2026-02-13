# Dotfiles Documentation

Complete documentation for this macOS dotfiles configuration.

## The Dotfiles Mastery Course

New here? Follow the structured learning path from zero to productive:

**[Start the Course](course/README.md)** — 7 levels, from installation to mastery.

## Getting Started

| Guide | Description |
|-------|-------------|
| **[Philosophy](getting-started/philosophy.md)** | Why this system, design decisions |
| **[Installation](getting-started/installation.md)** | Fresh macOS to running system |
| **[GNU Stow](getting-started/gnu-stow.md)** | How configs are deployed (symlinks) |
| **[Quick Start](getting-started/quick-start.md)** | Get productive in 5 minutes |
| **[First Day](getting-started/first-day.md)** | Your first day with this config |
| **[Daily Workflow](getting-started/daily-workflow.md)** | Daily dev workflow reference |
| **[Customizing](getting-started/customizing.md)** | Fork and make it yours |
| **[New Tools Guide](getting-started/new-tools-guide.md)** | Modern CLI tools reference |

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

### Shell Enhancements

| Tool | Description | Key Features |
|------|-------------|--------------|
| **[Atuin](atuin/README.md)** | Shell history search | Fuzzy search, vim-mode, secrets filter |
| **[w3m](w3m/README.md)** | Terminal web browser | Vi keybindings, tmux popup (`Ctrl+B > Ctrl+W`) |

### Music

| Tool | Description | Key Features |
|------|-------------|--------------|
| **[MPD](mpd/README.md)** | Music player daemon | CoreAudio, auto-update library |
| **[rmpc](rmpc/README.md)** | MPD TUI client | Vim controls, tmux popup (`Ctrl+B > Ctrl+M`) |

### Workflows & Integration

| Guide | Description | Key Features |
|-------|-------------|--------------|
| **[Shell Navigation](zsh/navigation-stack.md)** | FZF + Zoxide + Atuin | Fuzzy finding, smart jump, history search |
| **[Aliases & Functions](zsh/aliases-and-functions.md)** | All 70+ shell aliases | Categorized reference with examples |
| **[Git Workflow](git/workflow.md)** | Lazygit + FZF-git + aliases | Shell, TUI, and editor git integration |
| **[Window Management](window-management/workflow.md)** | AeroSpace + Karabiner daily use | Workspaces, Hyper key, sublayers |
| **[Development Stack](integration/development-stack.md)** | Nvim + Tmux + Git | End-to-end integrated workflow |

### Utilities

| Tool | Description | Key Features |
|------|-------------|--------------|
| **[Scripts](scripts/README.md)** | Custom utilities | tmux-sessionizer, fzf-git |

### Alternative/Legacy Terminals

Configurations kept for reference or as backups:

| Tool | Status | Description |
|------|--------|-------------|
| **[Kitty](kitty/README.md)** | Backup | Mirrors Ghostty config, available as fallback |
| **[Alacritty](alacritty/README.md)** | Legacy | Original GPU terminal, replaced by Ghostty |
| **[WezTerm](wezterm/README.md)** | Legacy | Lua-configurable terminal, replaced by Ghostty |

### Alternative Editor

| Tool | Status | Description |
|------|--------|-------------|
| **[Zed](zed/README.md)** | Experimental | Fast Rust editor with vim mode |

## Quick Reference Cards

### Most Used Keybindings

| Context | Action | Key |
|---------|--------|-----|
| **Neovim** | Find files | `<leader>pf` |
| **Neovim** | Search in files | `<leader>ps` |
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
- Atuin: `keymap_mode = "vim-insert"`
- w3m: Custom vi keymap
- Yazi: Built-in vi mode

## Architecture

```
~/dotfiles/
├── aerospace/    → ~/.config/aerospace/
├── alacritty/    → ~/.config/alacritty/       (legacy)
├── atuin/        → ~/.config/atuin/
├── ghostty/      → ~/.config/ghostty/
├── karabiner/    → ~/.config/karabiner/
├── kitty/        → ~/.config/kitty/           (backup)
├── mpd/          → ~/.config/mpd/
├── nvim/         → ~/.config/nvim/
├── rmpc/         → ~/.config/rmpc/
├── scripts/      → ~/scripts/
├── sketchybar/   → ~/.config/sketchybar/
├── starship/     → ~/.config/starship/
├── tmux/         → ~/.config/tmux/
├── w3m/          → ~/.w3m/
├── wezterm/      → ~/.config/wezterm/         (legacy)
├── yazi/         → ~/.config/yazi/
├── zed/          → ~/.config/zed/             (experimental)
├── zsh/          → ~/.zshrc, ~/.zprofile
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
