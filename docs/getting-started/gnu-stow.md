# GNU Stow Guide

How this dotfiles system deploys configurations using symlinks.

## What is GNU Stow?

Stow is a symlink farm manager. It creates symlinks from a source directory to a target directory, making files appear where programs expect them.

**In simple terms:** You keep all configs in `~/dotfiles/`, and Stow makes them appear in `~/.config/` (or wherever the program looks).

## How It Works

### The Directory Mirror Pattern

Each tool directory in `~/dotfiles/` mirrors the `$HOME` directory structure:

```
~/dotfiles/nvim/                    ~/
├── .config/                        ├── .config/
│   └── nvim/                       │   └── nvim → ~/dotfiles/nvim/.config/nvim (symlink!)
│       ├── init.lua                │
│       └── lua/                    │
│           └── sethy/              │
│               └── plugins/        │

~/dotfiles/zsh/                     ~/
├── .zshrc                          ├── .zshrc → ~/dotfiles/zsh/.zshrc (symlink!)
└── .zprofile                       └── .zprofile → ~/dotfiles/zsh/.zprofile (symlink!)
```

**The key insight:** The directory structure inside each stow package is relative to `$HOME`. Stow creates a symlink for each file, one level up from the package directory.

### Stow Command

```bash
cd ~/dotfiles

# Stow a single package
stow -t ~ nvim
# Creates: ~/.config/nvim → ~/dotfiles/nvim/.config/nvim

# Stow all packages
stow -t ~ aerospace atuin ghostty karabiner nvim tmux zsh ...

# Re-stow (update symlinks after changes)
stow -R -t ~ nvim

# Unstow (remove symlinks)
stow -D -t ~ nvim
```

**Flags:**
| Flag | Purpose |
|------|---------|
| `-t ~` | Target directory is home |
| `-R` | Re-stow (delete then re-create symlinks) |
| `-D` | Delete symlinks |
| `--adopt` | Adopt existing files into the package |
| `-n` | Dry run (show what would happen) |

## Understanding Symlinks

After stowing, you can edit configs from either location — they're the same file:

```bash
# These edit the SAME file:
nvim ~/dotfiles/nvim/.config/nvim/init.lua
nvim ~/.config/nvim/init.lua

# Verify symlink
ls -la ~/.config/nvim
# lrwxr-xr-x  nvim → ../dotfiles/nvim/.config/nvim
```

**Benefit:** All changes happen in `~/dotfiles/`, which is a git repository. Your configs are automatically version-controlled.

## All Packages in This Repo

| Package | Target | What It Configures |
|---------|--------|-------------------|
| `aerospace` | `~/.config/aerospace/` | Window manager |
| `atuin` | `~/.config/atuin/` | Shell history |
| `ghostty` | `~/.config/ghostty/` | Terminal emulator |
| `karabiner` | `~/.config/karabiner/` | Keyboard remapping |
| `kitty` | `~/.config/kitty/` | Backup terminal |
| `mpd` | `~/.config/mpd/` | Music daemon |
| `nvim` | `~/.config/nvim/` | Editor |
| `rmpc` | `~/.config/rmpc/` | Music player TUI |
| `scripts` | `~/scripts/` | Custom utilities |
| `sketchybar` | `~/.config/sketchybar/` | Status bar |
| `starship` | `~/.config/starship/` | Shell prompt |
| `tmux` | `~/.config/tmux/` | Terminal multiplexer |
| `w3m` | `~/.w3m/` | Terminal browser |
| `yazi` | `~/.config/yazi/` | File manager |
| `zed` | `~/.config/zed/` | Experimental editor |
| `zsh` | `~/.zshrc`, `~/.zprofile` | Shell config |

## Common Operations

### Adding a New Tool

```bash
# 1. Create the directory structure
mkdir -p ~/dotfiles/mytool/.config/mytool

# 2. Add your config file
vim ~/dotfiles/mytool/.config/mytool/config.toml

# 3. Stow it
cd ~/dotfiles
stow -t ~ mytool

# 4. Verify
ls -la ~/.config/mytool
# Should show symlink to ~/dotfiles/mytool/.config/mytool
```

### Handling Conflicts

If a real file already exists where Stow wants to create a symlink:

```bash
# Option 1: Back up and remove
mv ~/.config/mytool ~/.config/mytool.backup
stow -t ~ mytool

# Option 2: Adopt existing file into dotfiles
stow -t ~ --adopt mytool
# This MOVES the existing file into ~/dotfiles/mytool/
# and creates the symlink
```

### Selective Stowing

You don't have to stow everything. On a work machine you might skip personal tools:

```bash
# Only stow work-related configs
stow -t ~ zsh nvim tmux ghostty starship

# Skip media and window management
# (don't stow: mpd, rmpc, aerospace, sketchybar)
```

### Checking What's Stowed

```bash
# See all symlinks in .config pointing to dotfiles
ls -la ~/.config/ | grep dotfiles

# Check a specific package
ls -la ~/.config/nvim
```

## Forking This Repo

To create your own dotfiles based on this system:

```bash
# 1. Fork on GitHub (or clone and change remote)
git clone https://github.com/durante-tech/dotfiles.git ~/dotfiles
cd ~/dotfiles
git remote set-url origin git@github.com:YOUR_USER/dotfiles.git

# 2. Remove packages you don't want
rm -rf ~/dotfiles/mpd ~/dotfiles/rmpc  # Example: remove music tools

# 3. Modify configs to your taste
nvim ~/dotfiles/nvim/.config/nvim/lua/sethy/plugins/

# 4. Re-stow only what you want
stow -R -t ~ zsh nvim tmux ghostty

# 5. Commit your changes
git add -A && git commit -m "Customize dotfiles"
git push
```

## Gotchas

### Parent Directories Must Exist

Stow creates symlinks but not parent directories. If `~/.config/` doesn't exist, stow will fail:

```bash
mkdir -p ~/.config
```

The installer handles this, but if stowing manually, create parents first.

### Don't Edit in Both Places

Since both paths point to the same file, this isn't possible. But be aware: if you unstow and then edit `~/.config/nvim/`, you're editing a copy, not the git-tracked version.

### Git Tracks the Dotfiles Directory

Always commit from `~/dotfiles/`:

```bash
cd ~/dotfiles
git add -A
git commit -m "Update nvim config"
git push
```

### Local Overrides (Not Tracked)

Some configs support local overrides that aren't committed to git:

| File | Purpose |
|------|---------|
| `~/.zprofile.local` | Machine-specific PATH and env vars |
| `~/.zshrc.local` | Machine-specific aliases |

These are sourced at the end of their respective files.

---

**Next:** [Quick Start](quick-start.md) — start using the system
