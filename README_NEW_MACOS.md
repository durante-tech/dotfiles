# New macOS Setup Guide (Apple Silicon)

Complete installation guide for setting up a new Apple Silicon Mac with these dotfiles.

## Prerequisites

- Apple Silicon Mac (M1/M2/M3/M4)
- macOS Sonoma or later recommended
- Internet connection

---

## Quick Start (Automated)

Run this one-liner to install everything:

```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Sin-cy/dotfiles/main/install.sh)"
```

This will:
1. Install Xcode Command Line Tools
2. Install Homebrew
3. Install all packages and applications
4. Clone dotfiles and symlink configs
5. Apply macOS defaults

**Then proceed to [Post-Installation Steps](#post-installation-steps)**

---

## Manual Installation

### Step 1: Install Xcode Command Line Tools

```bash
xcode-select --install
```

Wait for installation to complete.

### Step 2: Install Homebrew

```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
eval "$(/opt/homebrew/bin/brew shellenv)"
```

### Step 3: Clone Dotfiles

```bash
brew install git
git clone https://github.com/Sin-cy/dotfiles.git ~/dotfiles
cd ~/dotfiles
```

### Step 4: Run Install Script

```bash
chmod +x install.sh
./install.sh
```

---

## Post-Installation Steps

### 1. Install Additional Environment Managers

#### Bun (JavaScript Runtime)
```bash
curl -fsSL https://bun.sh/install | bash
```

#### Deno (JavaScript/TypeScript Runtime)
```bash
curl -fsSL https://deno.land/install.sh | sh
```

#### UV (Python Package Manager)
```bash
curl -LsSf https://astral.sh/uv/install.sh | sh
```

#### Python 3.11 (Optional - System Framework)
Download from [python.org](https://www.python.org/downloads/) or:
```bash
brew install python@3.11
```

### 2. Install Node.js + Python via mise

mise is the polyglot version manager (replaces fnm + pyenv + nvm). It reads
`mise.toml`, `.tool-versions`, `.nvmrc`, and `.python-version` natively.

```bash
# Restart terminal first
source ~/.zprofile

# mise is configured globally via dotfiles/mise/.config/mise/config.toml.
# Just run:
mise install            # installs versions pinned in the global config

# Or pin a specific version manually:
mise use --global node@latest python@3.12
```

### 3. Install Tmux Plugin Manager

```bash
git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
```

Then in tmux: `prefix + I` (capital i) to install plugins.

### 4. Install FZF Git Integration

```bash
git clone https://github.com/junegunn/fzf-git.sh.git ~/scripts/fzf-git
ln -s ~/scripts/fzf-git/fzf-git.sh ~/scripts/fzf-git.sh
```

### 5. Setup Scripts Directory

Create the scripts directory if it doesn't exist:
```bash
mkdir -p ~/scripts
```

The dotfiles include these scripts in `scripts/scripts/`:
- `tmux-sessionizer` - Fuzzy find and switch tmux sessions
- `fzf_listoldfiles.sh` - Open recent files in Neovim
- `zoxide_openfiles_nvim.sh` - Zoxide integration with Neovim

Make sure they're executable:
```bash
chmod +x ~/scripts/*
```

### 6. Restart Terminal

Close and reopen your terminal (or run `exec zsh`) to load all configurations.

### 7. Open Neovim

```bash
nvim
```

Mason will automatically install LSP servers on first launch. Wait for installations to complete.

---

## Installed Software

### CLI Tools
- **Core Utils**: coreutils, bat, fd, ripgrep, tree, fzf, zoxide
- **Development**: neovim, git, lazygit, tmux, node, mise, fnm, pyenv, lua, sqlite
- **Shell**: zsh-autosuggestions, zsh-syntax-highlighting, starship

### GUI Applications (via Homebrew Cask)
- **Terminal**: WezTerm
- **Productivity**: Raycast, AeroSpace (window manager)
- **Utilities**: KeyCastr, BetterDisplay, LinearMouse
- **Fonts**: Hack Nerd Font, JetBrains Mono Nerd Font, SF Pro

### Language/Version Managers
- **mise**: Polyglot version manager (primary — replaces fnm + pyenv + nvm)
- **fnm**: Fast Node manager (kept as fallback during mise rollout)
- **pyenv**: Python version manager (kept as fallback)
- **Bun**: Alternative JavaScript runtime
- **Deno**: JavaScript/TypeScript runtime
- **UV**: Python package manager
- **Go**: Standard toolchain with GOPATH
- **Mason**: Neovim LSP/tool manager

---

## Configuration Customization

### Custom Project Paths (Optional)

Add to your `~/.zprofile` (or create `~/.zshenv` for user-specific settings):

```bash
# Customize tmux-sessionizer search paths
export TMUX_SESSIONIZER_PATHS="$HOME/dotfiles $HOME/Projects $HOME/Work"

# Customize Obsidian vault (if using)
export OBSIDIAN_VAULT_NAME="YourVaultName"
```

### Custom Obsidian Vault Alias (Optional)

Uncomment and customize in `~/.zshrc`:

```bash
# Replace YourVaultName with your actual vault
alias vault="cd ~/Library/Mobile\ Documents/iCloud~md~obsidian/Documents/YourVaultName/"
```

### WezTerm Custom Workspace (Optional)

Edit `~/dotfiles/wezterm/wezterm.lua` and uncomment the example workspace keybinding, then customize the path.

---

## macOS System Settings Applied

The install script automatically configures:

- **Dock**: Auto-hide enabled
- **Keyboard**:
  - Key repeat rate: 2 (fast)
  - Initial key repeat: 15 (short delay)

### Additional Recommended Settings (Manual)

#### 1. Trackpad
- System Settings → Trackpad → Point & Click → Enable "Tap to click"
- System Settings → Trackpad → Scroll & Zoom → Enable "Natural scrolling"

#### 2. Keyboard
- System Settings → Keyboard → Keyboard Shortcuts → Modifier Keys → Remap Caps Lock to Control

#### 3. 1Password SSH Agent (if using 1Password)
- Enable 1Password SSH Agent in 1Password Settings
- The dotfiles are already configured to use it (`.zprofile` line 23)

#### 4. Permissions
Grant permissions when prompted for:
- Raycast (Accessibility)
- AeroSpace (Accessibility)
- WezTerm (Full Disk Access if needed)

---

## Verify Installation

### Check Homebrew packages:
```bash
brew list
```

### Check environment managers:
```bash
mise --version
node --version
bun --version
deno --version
uv --version
go version
```

### Check shell plugins:
```bash
# Should show suggestions and syntax highlighting
ls
```

### Check Neovim:
```bash
nvim --version
# Then open nvim and run:
# :checkhealth
```

---

## Troubleshooting

### Issue: Command not found after installation

**Solution**: Restart your terminal or run:
```bash
source ~/.zprofile
source ~/.zshrc
```

### Issue: `node` / `python` command not found

**Solution**: mise should have activated automatically via `eval "$(mise activate zsh)"`
in `.zshrc`. If `which node` returns nothing:
```bash
mise doctor              # diagnose mise setup
mise install             # install versions pinned in config
mise use --global node@latest python@3.12   # pin globally if config absent
```

### Issue: Neovim LSP not working

**Solution**: Open Neovim and run:
```vim
:Mason
```
Install missing servers manually or run `:MasonInstallAll`

### Issue: Tmux plugins not loading

**Solution**:
1. Make sure TPM is installed: `ls ~/.tmux/plugins/tpm`
2. In tmux, press `prefix + I` (Ctrl+a, then Shift+i)

### Issue: Stow conflicts

**Solution**: Backup existing configs:
```bash
mkdir ~/dotfiles_backup
mv ~/.config/nvim ~/dotfiles_backup/
mv ~/.zshrc ~/dotfiles_backup/
# Then re-run stow
cd ~/dotfiles
stow -t ~ zsh nvim tmux starship wezterm aerospace
```

### Issue: Scripts not executable

**Solution**:
```bash
chmod +x ~/scripts/*
```

---

## Next Steps

1. Configure Git:
   ```bash
   git config --global user.name "Your Name"
   git config --global user.email "your.email@example.com"
   ```

2. Set up SSH keys (or use 1Password SSH agent)

3. Customize Neovim:
   - Edit colorscheme in `~/.config/nvim/lua/sethy/plugins/colorscheme.lua`
   - Add custom keymaps in `~/.config/nvim/lua/sethy/core/keymaps.lua`

4. Explore AeroSpace window management:
   - Read config at `~/.config/aerospace/aerospace.toml`
   - Default modifier: `Alt` (Option key)

5. Configure Raycast:
   - Import settings or customize manually
   - Set up hotkey (recommended: Cmd+Space)

---

## Useful Commands

### Dotfiles Management

```bash
# Update dotfiles from remote
cd ~/dotfiles && git pull

# Re-stow after changes
cd ~/dotfiles
stow -R -t ~ zsh nvim tmux starship wezterm aerospace

# Edit configs quickly (using aliases)
vim ~/.zshrc        # Shell config
vim ~/.config/nvim  # Neovim config
```

### Package Management

```bash
# Update Homebrew packages
brew update && brew upgrade

# Update Node packages
npm update -g

# Update Neovim plugins
nvim +Lazy sync +qa
```

---

## Resources

- [Neovim Documentation](https://neovim.io/doc/)
- [Tmux Cheat Sheet](https://tmuxcheatsheet.com/)
- [AeroSpace Guide](https://github.com/nikitabobko/AeroSpace)
- [Starship Config](https://starship.rs/config/)
- [GNU Stow Guide](https://www.gnu.org/software/stow/manual/stow.html)

---

## Credits

Based on dotfiles by [Sin-cy](https://github.com/Sin-cy/dotfiles)

---

## License

See repository license
