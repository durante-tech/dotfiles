# Installation Guide

From a fresh macOS to a fully working system, step by step.

## Prerequisites

- macOS (Apple Silicon or Intel)
- Admin access (for Homebrew and system preferences)
- Internet connection
- ~30 minutes for full install

## Quick Install (Automated)

If you just want everything installed:

```bash
# 1. Clone the repository
git clone https://github.com/durante-tech/dotfiles.git ~/dotfiles

# 2. Run the installer
cd ~/dotfiles
./install.sh
```

The script is **idempotent** — safe to run multiple times. It skips already-installed packages.

## What the Installer Does

The install script runs 10 steps in order:

### Step 1: Xcode Command Line Tools

```bash
xcode-select --install
```

Installs Apple's developer tools (git, make, clang). Required for everything else. If you see a popup, click "Install" and wait.

### Step 2: Homebrew

The macOS package manager. Installs to `/opt/homebrew` (Apple Silicon) or `/usr/local` (Intel).

```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```

### Step 3: Homebrew Formulae (79 packages)

Installs all CLI tools in categories:

| Category | Packages | Purpose |
|----------|----------|---------|
| **Shell** | zsh-autosuggestions, zsh-syntax-highlighting, stow, starship, atuin, zoxide, fzf | Shell plugins and prompt |
| **File tools** | bat, fd, ripgrep, eza, tree, jq, yazi, broot, w3m | Modern file operations |
| **Development** | git, lazygit, git-delta, neovim, tmux, tree-sitter, prettier | Core dev tools |
| **Languages** | node, fnm, pyenv, go, deno, sqlite, lua, luarocks | Language runtimes |
| **Modern CLI** | procs, bottom, curlie, dust, duf, onefetch, fx, navi, tldr, direnv | Rust/Go replacements |
| **Image/PDF** | pngpaste, imagemagick, poppler, ghostscript | For Neovim plugins |
| **Window mgmt** | borders, sketchybar | macOS UI |
| **Media** | mpd, rmpc | Music player |
| **AI** | aider | AI coding assistant |

### Step 4: Homebrew Casks (GUI Apps)

| App | Purpose |
|-----|---------|
| Raycast | Launcher (Spotlight replacement) |
| Karabiner-Elements | Keyboard remapping (Hyperkey) |
| Ghostty | Primary terminal emulator |
| Kitty | Backup terminal |
| AeroSpace | Tiling window manager |
| KeyCastr | Show keystrokes on screen |
| BetterDisplay | External monitor management |
| LinearMouse | Mouse customization |
| Nerd Fonts | JetBrainsMono, Hack, SF Pro |

### Step 5: Non-Homebrew Tools

- **Bun** — Fast JavaScript runtime (`curl -fsSL https://bun.sh/install | bash`)
- **Fabric AI** — AI patterns tool (`go install github.com/danielmiessler/fabric/cmd/fabric@latest`)

### Step 6: Dotfiles Clone & Stow

Clones this repository and creates symlinks with GNU Stow:

```bash
# Stows all packages:
# aerospace, atuin, ghostty, karabiner, kitty, mpd, nvim, rmpc,
# scripts, sketchybar, starship, tmux, w3m, yazi, zed, zsh
```

Each package directory mirrors `$HOME` structure. Stow creates symlinks so configs appear in the right place. See [GNU Stow Guide](gnu-stow.md) for details.

### Step 7: Tmux Plugin Manager (TPM)

```bash
# TPM lives at a NON-DEFAULT path: tmux.conf sets TMUX_PLUGIN_MANAGER_PATH to
# ~/.config/tmux/.tmux/plugins, so a clone into ~/.tmux/plugins/tpm is never read.
git clone https://github.com/tmux-plugins/tpm ~/.config/tmux/.tmux/plugins/tpm
```

### Step 8: Neovim Plugins (Lazy.nvim)

```bash
nvim --headless "+Lazy! sync" +qa
```

Installs ~40 plugins automatically.

### Step 9: macOS Defaults

Configures system preferences:
- Auto-hide Dock
- Fast key repeat (KeyRepeat=2, InitialKeyRepeat=15)

### Step 10: Verification

Checks that all critical tools are installed: git, nvim, tmux, stow, starship, zoxide, fzf.

## Post-Install Steps

After the installer finishes, do these manually:

### 1. Restart Your Terminal

```bash
# Or reload shell config
source ~/.zprofile && source ~/.zshrc
```

### 2. Install Tmux Plugins

```bash
# Open tmux
tmux

# Press: Ctrl+b, then Shift+I
# Wait for plugins to install
```

### 3. Install LSP Servers

```bash
# Open Neovim
nvim

# Inside Neovim:
:Mason
# Browse and install servers for your languages
# Press 'i' on a server to install
```

**Recommended servers:**
| Language | Server |
|----------|--------|
| JavaScript/TypeScript | `ts_ls` |
| Go | `gopls` |
| Lua | `lua_ls` |
| HTML | `emmet_ls` |
| CSS | `css-lsp` |

### 4. Grant macOS Permissions

Go to **System Settings > Privacy & Security** and grant access to:

| App | Permission Needed |
|-----|-------------------|
| AeroSpace | Accessibility |
| Karabiner-Elements | Input Monitoring, Accessibility |
| Raycast | Accessibility |

### 5. Configure 1Password SSH (Optional)

If you use 1Password for SSH keys, the config already points to the right socket. Just enable the SSH agent in 1Password settings.

### 6. Set Up Node.js

```bash
# FNM is already installed, install a Node version:
fnm install --lts
fnm default lts-latest

# Verify
node --version
```

## Installer Options

The install script supports flags for partial installs:

```bash
./install.sh --help           # Show all options
./install.sh --dry-run        # Preview without installing
./install.sh --update         # Update only (skip installs)
./install.sh --skip-casks     # Skip GUI apps
./install.sh --skip-brew      # Skip formulae; casks have their own flag
./install.sh --force-stow     # Re-stow (adopt existing configs)
./install.sh --verbose        # Show all output
```

## Updating

```bash
cd ~/dotfiles
git pull --ff-only           # Explicitly fetch the checkout
./update.sh --dry-run        # Preview configuration/plugin work
./update.sh
```

`update.sh` applies the current checkout, prepares AeroSpace and terminal include
files, re-stows packages, and synchronizes plugins. It does not fetch the repository
or provision tools. Use `./update.sh --with-tools` to opt into declared tool
provisioning. `--skip-brew` and `--skip-casks` control formulae and GUI installs
separately. Reload instructions are printed without triggering extra restarts.

## First personalization

After install or update:

```bash
./personalize.sh check
./personalize.sh status
./personalize.sh             # Optional monitor/app/workspace wizard
```

The installer/update prepares harmless terminal includes before deploying Ghostty
or Kitty, so no separate seeding command is needed. Personal settings stay outside
Git. No profile or visual override is selected automatically.

In Raycast, add `~/dotfiles/raycast/script-commands` under Settings → Extensions →
Script Commands if that directory is not registered, then search for
**Dotfiles · Preferences**. Follow [Personalization](../PERSONALIZE.md) for
readability, profiles, backups, and the shortcut reference. Choose monitor
patterns and installed apps appropriate to your own machine.

## Troubleshooting Installation

### "stow: CONFLICT" errors

Existing config files block stow symlinks:

```bash
# Back up existing configs
mkdir ~/config_backup
mv ~/.config/nvim ~/config_backup/
mv ~/.zshrc ~/config_backup/

# Re-run stow
cd ~/dotfiles
./install.sh --force-stow
```

### "command not found" after install

```bash
# Reload shell
source ~/.zprofile && source ~/.zshrc

# Or restart terminal entirely
exec zsh
```

### Xcode popup won't dismiss

Wait for the download to complete (can take 10+ minutes on slow connections). Then re-run `./install.sh`.

### Homebrew install hangs

Check your internet connection. If behind a proxy:
```bash
export ALL_PROXY=http://proxy:port
```

---

**Next:** [GNU Stow Guide](gnu-stow.md) — understand how configs are deployed
