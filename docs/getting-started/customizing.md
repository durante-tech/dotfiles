# Customizing Your Setup

How to fork this dotfiles repo and make it your own.

## Fork and Clone

```bash
# 1. Fork on GitHub (click "Fork" on the repo page)

# 2. Clone your fork
git clone https://github.com/YOUR_USERNAME/dotfiles.git ~/dotfiles

# 3. Run the installer
cd ~/dotfiles
bash install.sh

# 4. Apply the manifest packages
./setup.sh --stow
```

## What to Customize First

### 1. Git Identity

The installer doesn't set your git identity. Do this immediately:

```bash
git config --global user.name "Your Name"
git config --global user.email "your@email.com"
```

### 2. Personal preferences and aliases

Use the supported preference interface before editing shared files:

```bash
./personalize.sh show
./personalize.sh list-apps
./personalize.sh set apps.browser com.apple.Safari          # preview
./personalize.sh set apps.browser com.apple.Safari --apply
```

Saved values live outside Git in `~/.config/dotfiles/preferences.json`.
Put personal aliases in `~/.zshrc.local`, which runs after initialization.
Initialization inputs such as SDK locations belong in
`~/.config/dotfiles/personal.env`.

### 3. Project picker roots

The tmux and Kitty pickers share the preferred roots setting. Spaces remain literal:

```bash
./personalize.sh set projects.roots '["~/Developer", "~/Work Projects"]' --apply
```

This projects `DOTFILES_SESSIONIZER_PATHS` as a newline-delimited exported value.
The older whitespace-delimited `TMUX_SESSIONIZER_PATHS` remains supported by the
pickers. Open a new shell after updating environment preferences.

See [personalization](../PERSONALIZE.md) for validation, previews, and undo.

### 4. Neovim Plugins

**Directory:** `nvim/.config/nvim/lua/sethy/plugins/`

**Add a plugin:** Create a new file, e.g., `my-plugin.lua`:

```lua
return {
  "author/plugin-name",
  event = "VeryLazy",
  config = function()
    require("plugin-name").setup({
      -- your config
    })
  end,
}
```

Lazy.nvim auto-discovers files in this directory. Restart Neovim and it installs automatically.

**Remove a plugin:** Delete or rename its `.lua` file. Restart Neovim, then `:Lazy clean` to remove cached files.

**Modify a plugin:** Edit the existing `.lua` file in the plugins directory. Most changes take effect on next Neovim start.

### 5. Apps and workspaces

Set preferred apps and their existing workspace destinations together:

```bash
./personalize.sh set workspaces.browser B --diff
./personalize.sh set workspaces.browser B --apply
aerospace reload-config
```

Launch bindings and routing share these preferences. Structural changes belong
in `aerospace/templates/aerospace.toml.template`; run
`scripts/scripts/render-aerospace.sh` afterward. Do not edit the generated TOML.

### 6. Karabiner Rules

**File:** `karabiner/.config/karabiner/karabiner.json`

The Hyper key sublayers (app launchers, window management) can be customized. The browser and notes launchers now read preferred-app settings. For structural
keyboard changes, edit the complex modifications section to:
- Change which apps open with which keys
- Add new sublayers
- Modify existing shortcuts

## Local Override Files

For machine-specific configuration that shouldn't be committed to git:

| File | Purpose |
|------|---------|
| `~/.zshrc.local` | Machine-specific aliases, env vars, secrets |
| `~/.zprofile.local` | Machine-specific PATH additions |

These hooks run after initialization in their respective startup files. The
existing interactive-agent safety guard follows `.zshrc.local`; project formatter
settings retain their separate authority.

### Example `.zshrc.local`

```bash
# Work-specific aliases
alias vpn="sudo openvpn /etc/work-vpn.conf"
alias staging="ssh deploy@staging.mycompany.com"

# API keys (never commit these)
export OPENAI_API_KEY="sk-..."
export DATABASE_URL="postgres://..."

# Machine-specific tool config
export DOCKER_HOST="tcp://localhost:2375"
```

### Example `.zprofile.local`

```bash
# Additional PATH entries for this machine
export PATH="$HOME/.local/share/my-tool/bin:$PATH"

# Override default editor for this machine
export EDITOR="nvim"
```

## Adding a New Tool

To add a new tool to the dotfiles system:

### Step 1: Create the Stow Package

```bash
# Create the directory structure mirroring where configs go
mkdir -p ~/dotfiles/mytool/.config/mytool

# Add your config files
nvim ~/dotfiles/mytool/.config/mytool/config.toml
```

Add the package to `stow-packages.txt` if it should be part of standard deployment.

### Step 2: Stow It

```bash
cd ~/dotfiles
stow -t ~ mytool
# Creates: ~/.config/mytool → ~/dotfiles/mytool/.config/mytool
```

### Step 3: Add to Brewfile (if installable via Homebrew)

```bash
# Declare the tool in Brewfile, then provision explicitly:
./update.sh --with-tools
```

### Step 4: Add Documentation

Create `docs/mytool/README.md` following the pattern of existing docs.

## Adding New LSP Servers

**File:** `nvim/.config/nvim/lua/sethy/plugins/lsp/lspconfig.lua`

```lua
-- Add before the existing server configs:
vim.lsp.config.new_server = {
    capabilities = capabilities,
    filetypes = { "filetype1", "filetype2" },
    settings = {
        -- Server-specific settings from the LSP docs
    },
}
vim.lsp.enable("new_server")
```

Then install the server:
```vim
:Mason
" Search for the server, press 'i' to install
```

## Adding Custom Scripts

**Directory:** `scripts/scripts/`

`~/scripts` is on PATH. New files need a package Stow pass to create their links.

```bash
# Create the script
nvim ~/dotfiles/scripts/scripts/my-script

# Make it executable
chmod +x ~/dotfiles/scripts/scripts/my-script

# Link the new script from its package, then use it
cd ~/dotfiles
stow -t ~ scripts
my-script
```

### Script Template

```bash
#!/usr/bin/env bash
# my-script - Brief description of what it does

set -euo pipefail

# Your script logic here
echo "Hello from my-script"
```

## Customizing Themes

### Color Scheme Convention

| Context | Theme | Where to Change |
|---------|-------|----------------|
| Terminal tools (tmux, starship, sketchybar) | Catppuccin Mocha | Each tool's config |
| Editor (Neovim) | Rose-pine | `nvim/.config/nvim/lua/sethy/plugins/colorscheme.lua` |
| Terminal emulator (Ghostty) | Rose-pine | `ghostty/.config/ghostty/config` |

### Changing Neovim Colorscheme

Edit `nvim/.config/nvim/lua/sethy/plugins/colorscheme.lua`:

```lua
return {
  "your/colorscheme-plugin",
  priority = 1000,
  config = function()
    vim.cmd.colorscheme("your-theme")
  end,
}
```

### Changing Tmux Theme

In `tmux/.config/tmux/tmux.conf`, the theme is set via:

```
set -g @catppuccin_flavor "mocha"
```

Options: `mocha`, `macchiato`, `frappe`, `latte`

## Keeping Your Fork Updated

```bash
# Add the original repo as upstream
git remote add upstream https://github.com/ORIGINAL_OWNER/dotfiles.git

# Fetch upstream changes
git fetch upstream

# Merge upstream changes into your branch
git merge upstream/main

# Resolve any conflicts (your customizations vs upstream changes)
# Then push to your fork
git push origin main
```

### What Typically Conflicts

- `.zshrc` aliases (if you added in the same area)
- Plugin configs (if upstream added/removed plugins)
- Keybinding files (if upstream changed mappings)

**Tip:** Keep your customizations in separate sections or local override files to minimize conflicts.

## Tips

### Keep Secrets Out of Git

Never commit API keys, passwords, or tokens. Use local override files:

```bash
# In ~/.zshrc.local (not tracked):
export API_KEY="secret"

# In .zshrc (tracked), at the end:
[[ -f ~/.zshrc.local ]] && source ~/.zshrc.local  # Already there
```

### Test Changes Before Committing

```bash
# Shell changes:
source ~/.zshrc              # Reload and test

# Tmux changes:
prefix + r                   # Reload tmux config

# Neovim changes:
:source %                    # Reload current file
# or restart Neovim

# AeroSpace changes:
Alt+R                        # Reload config
```

### Use Git Branches for Experiments

```bash
gcb experiment/new-plugin    # Try something new
# ... test it out ...
gco main                     # Didn't like it? Switch back
git branch -D experiment/new-plugin  # Clean up
```

## Quick Reference

| Task | How |
|------|-----|
| Add alias | Edit `zsh/.zshrc`, then `source ~/.zshrc` |
| Add plugin | Create file in `nvim/.config/nvim/lua/sethy/plugins/` |
| Add script | Create in `scripts/scripts/`, `chmod +x` |
| Add tool config | `mkdir -p <tool>/.config/<tool>`, then `stow -t ~ <tool>` |
| Machine-specific config | Use `~/.zshrc.local` or `~/.zprofile.local` |
| Add LSP server | Edit `lspconfig.lua` + `:Mason` install |
| Change theme | Edit colorscheme plugin or tool config |

---

**Next:** [Daily Workflow](daily-workflow.md)
