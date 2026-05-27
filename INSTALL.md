# Dotfiles v2.0 — Installation Guide

**This guide is designed for AI agents installing/updating these dotfiles on a user's Mac.**

The repo is the personal dev environment for Lucas Gertel: terminal-first, keyboard-driven macOS setup with Neovim, Tmux, AeroSpace, Sketchybar, and a Catppuccin/Rose-pine theme stack. Includes a Claude Code session indicator on the bar, hourly Durante-themed wallpaper rotation, espanso `:llm` triggers piped to local Ollama, and 99 brew packages (77 formulas + 22 casks).

---

## AI Agent Instructions

**This is a wizard-style installation.** Use Claude Code's native tools to guide the user through installation:

1. **AskUserQuestion** — for user decisions and confirmations
2. **TodoWrite** — for progress tracking across the 12-step install
3. **Bash/Read/Write** — for actual installation
4. **VERIFY.md** — for final validation

### Welcome Message

Before starting, greet the user:

```
"I'm installing your dotfiles — a macOS terminal-first development environment featuring:

  • Zsh + Starship + Atuin + FZF + Zoxide
  • Neovim 0.12 with 36 plugins (Lazy.nvim + snacks.nvim + mini.nvim)
  • Tmux with TPM, AeroSpace tiling WM, Sketchybar
  • Ghostty primary terminal, Catppuccin Mocha
  • mise polyglot version manager (Node + Python)
  • Espanso text expander with :llm trigger to local Ollama (qwen3-coder:30b)
  • Hourly Durante-themed wallpaper rotation (10-piece gallery)
  • Sketchybar Claude Code 5-hour billing block indicator (via ccusage)

This pack installs 77 Homebrew formulas, 22 GUI casks, and 22 stowable dotfile directories. Plus 9 LaunchAgents — BetterDisplay time-of-day chord (5 modes), display-monitor watcher, Sketchybar firstboot, Übersicht, and hourly wallpaper rotation — all rendered from templates with your $USER.

Let me analyze your system and guide you through installation."
```

---

## Phase 1: System Analysis

**Execute this analysis BEFORE any file operations.**

### 1.1 Run These Commands

```bash
DOTFILES_DIR="$HOME/dotfiles"
echo "Dotfiles directory: $DOTFILES_DIR"

# Existing installation check
if [ -d "$DOTFILES_DIR/.git" ]; then
  echo "WARNING Existing dotfiles repo found at: $DOTFILES_DIR"
  echo "  Branch: $(cd "$DOTFILES_DIR" && git branch --show-current)"
  echo "  Last commit: $(cd "$DOTFILES_DIR" && git log -1 --oneline)"
  echo "  Behind origin by: $(cd "$DOTFILES_DIR" && git rev-list --count HEAD..@{u} 2>/dev/null || echo 'unknown') commits"
else
  echo "OK No existing dotfiles repo (clean install)"
fi

# macOS check
if [[ "$(uname)" != "Darwin" ]]; then
  echo "ERROR This pack is macOS-only (you're on $(uname))"
  exit 1
fi
ARCH=$(uname -m)
echo "OK macOS $(sw_vers -productVersion) on $ARCH"

# Apple Silicon check
if [[ "$ARCH" != "arm64" ]]; then
  echo "WARNING Intel Mac detected. Brewfile assumes Apple Silicon paths (/opt/homebrew). Some tools may need manual adjustment."
fi

# Prereq checks
command -v xcode-select &>/dev/null && xcode-select -p &>/dev/null && \
  echo "OK Xcode CLT installed" || echo "INFO Xcode CLT will be installed"

command -v brew &>/dev/null && \
  echo "OK Homebrew installed: $(brew --version | head -1)" || echo "INFO Homebrew will be installed"

command -v stow &>/dev/null && \
  echo "OK GNU Stow installed" || echo "INFO Stow will be installed via Homebrew"

# Conflict checks — files that would block stow
for path in ~/.zshrc ~/.zprofile ~/.config/nvim ~/.config/tmux ~/.config/aerospace; do
  if [ -e "$path" ] && [ ! -L "$path" ]; then
    echo "WARNING Existing non-symlink at $path (will conflict with stow)"
  fi
done

# Disk space (need ~5GB for brew + plugins + ollama models)
AVAIL_GB=$(df -g ~ | awk 'NR==2 {print $4}')
if [ "$AVAIL_GB" -lt 10 ]; then
  echo "WARNING Only ${AVAIL_GB}GB free. Recommended: 20GB+ (Brew packages + Ollama models)."
else
  echo "OK ${AVAIL_GB}GB free disk space"
fi
```

### 1.2 Present Findings

Tell the user what you found. Highlight any WARNING or ERROR lines specifically.

---

## Phase 2: User Questions

### Question 1: Install Mode (always asked)

```json
{
  "header": "Install Mode",
  "question": "How should I run this installation?",
  "multiSelect": false,
  "options": [
    {"label": "Fresh install (Recommended)", "description": "Full install: Xcode CLT, Homebrew, all packages, dotfiles, plugins, LaunchAgents, macOS defaults"},
    {"label": "Update existing", "description": "Pull latest, re-stow packages, sync plugins, render LaunchAgents (skip Homebrew installs)"},
    {"label": "Repair only", "description": "Re-stow packages, re-render LaunchAgents, re-bootstrap services. No git pull, no installs."},
    {"label": "Show me the plan first", "description": "Run install.sh --dry-run to preview every step without changes"},
    {"label": "Cancel", "description": "Abort"}
  ]
}
```

### Question 2: Conflict Resolution (only if existing dotfiles found)

```json
{
  "header": "Conflict — Existing Dotfiles",
  "question": "An existing dotfiles checkout was found. How should I proceed?",
  "multiSelect": false,
  "options": [
    {"label": "Backup and Replace (Recommended)", "description": "Creates timestamped backup of ~/dotfiles + key config files, then re-clones latest"},
    {"label": "Keep and Update", "description": "git pull origin main + re-stow (preserves uncommitted local changes if any)"},
    {"label": "Force Replace", "description": "Hard reset to origin/main (DESTROYS uncommitted changes)"},
    {"label": "Abort Installation", "description": "Cancel installation, leave current dotfiles intact"}
  ]
}
```

### Question 3: macOS Defaults Scope (always asked on fresh install)

```json
{
  "header": "macOS Defaults",
  "question": "The repo includes a 44-entry ./macos/.macos script that configures Dock, Finder, keyboard, trackpad, screenshots, and more. Apply it?",
  "multiSelect": false,
  "options": [
    {"label": "Yes, apply all (Recommended)", "description": "Runs ./macos/.macos. Asks for sudo. Will modify Finder/Dock/keyboard preferences."},
    {"label": "Skip macOS defaults", "description": "Install dotfiles only. User can run ./macos/.macos manually later."}
  ]
}
```

### Question 4: Optional GUI Apps (always asked)

```json
{
  "header": "GUI Apps (Casks)",
  "question": "Install all GUI app casks? Includes: Ghostty terminal, Espanso, Maccy clipboard, Übersicht widgets, boring.notch, Raycast, Karabiner-Elements, Stats, KeyCastr, BetterDisplay.",
  "multiSelect": false,
  "options": [
    {"label": "Yes, install all (Recommended)", "description": "Full setup. Most casks are free; some need first-launch Accessibility grants."},
    {"label": "Skip casks", "description": "Install CLI tools only. User can run brew bundle later."}
  ]
}
```

### Question 5: Final Confirmation

```json
{
  "header": "Install",
  "question": "Ready to install dotfiles?",
  "multiSelect": false,
  "options": [
    {"label": "Yes, install now (Recommended)", "description": "Runs install.sh with selected options"},
    {"label": "Show me what will change", "description": "Re-runs ./install.sh --dry-run for full preview"},
    {"label": "Cancel", "description": "Abort installation"}
  ]
}
```

---

## Phase 3: Backup (If Needed)

**Only execute if user chose "Backup and Replace":**

```bash
DOTFILES_DIR="$HOME/dotfiles"
BACKUP_DIR="$HOME/.dotfiles-backup-$(date +%Y%m%d-%H%M%S)"
mkdir -p "$BACKUP_DIR"

# Backup the repo if it exists
[ -d "$DOTFILES_DIR" ] && cp -R "$DOTFILES_DIR" "$BACKUP_DIR/dotfiles"

# Backup any non-symlink configs that would conflict
for path in ~/.zshrc ~/.zprofile ~/.gitconfig; do
  [ -f "$path" ] && [ ! -L "$path" ] && cp "$path" "$BACKUP_DIR/"
done

for dir in ~/.config/nvim ~/.config/tmux ~/.config/aerospace ~/.config/sketchybar; do
  [ -d "$dir" ] && [ ! -L "$dir" ] && cp -R "$dir" "$BACKUP_DIR/$(basename "$dir")"
done

echo "Backup created at: $BACKUP_DIR"
echo "Restore with: rm -rf ~/dotfiles && mv $BACKUP_DIR/dotfiles ~/dotfiles"
```

---

## Phase 4: Installation

The repo ships **install.sh** as the canonical installer. Wizard agents should drive it with the right flags rather than re-implementing the logic.

### 4.1 Clone the Repo (if not present)

```bash
if [ ! -d "$HOME/dotfiles/.git" ]; then
  git clone https://github.com/durante-tech/dotfiles.git "$HOME/dotfiles"
fi
cd "$HOME/dotfiles"
```

### 4.2 Run Install Script

**Mark todo "Run install.sh" as in_progress.**

Pick the right flag based on user's Phase 2 answers:

```bash
cd "$HOME/dotfiles"

# Fresh install — full pipeline
./install.sh

# OR — Update mode (skip brew installs, just pull + re-stow + re-sync)
./install.sh --update

# OR — Skip GUI apps
./install.sh --skip-casks

# OR — Skip macOS defaults
./install.sh --skip-macos

# OR — Preview only
./install.sh --dry-run
```

**install.sh runs these phases internally** (mirror as todos via TodoWrite):

| # | Phase | What |
|---|-------|------|
| 1 | Xcode CLT | Installs if missing |
| 2 | Homebrew | Installs if missing |
| 3 | Brew formulae | 77 CLI tools (mise, neovim, tmux, fzf, atuin, ollama, gum, glow, wallpaper, etc.) |
| 4 | Brew casks | 22 GUI apps (Ghostty, Espanso, Maccy, Übersicht, boring.notch, etc.) |
| 5 | Bun + ccusage + Fabric | Non-Homebrew tools |
| 6 | Stow dotfiles | Symlinks 22 packages into `~/.config/`, `~/Library/`, and `~/` |
| 6b | `mise install` | Pulls Node + Python versions pinned in `mise/.config/mise/config.toml` |
| 6c | `setup.sh --configure` | Renders LaunchAgent plists from templates (substitutes `$USER`), creates dirs, installs TPM |
| 6d | Espanso service | `espanso service register && espanso start` |
| 7 | TPM tmux plugins | Auto-installs via `~/.tmux/plugins/tpm/bin/install_plugins` |
| 8 | Neovim plugins | `nvim --headless +Lazy! sync +qa` |
| 9 | macOS defaults | Runs `./macos/.macos` (44 entries) — needs sudo |
| 10 | Verification | Checks critical CLI tools resolve |

**Mark todo as completed after install.sh finishes.**

### 4.3 Manual Steps That Require User Interaction

These cannot be automated — surface them clearly:

**Accessibility permissions** (System Settings → Privacy & Security → Accessibility):
- Espanso (for `:dt`, `:ts`, `:llm` triggers)
- Maccy (for clipboard history Cmd+Shift+C)
- Übersicht (for desktop widgets)
- boring.notch (for notch utility)
- AeroSpace (for window management)
- Karabiner-Elements (for key remapping)

**Atuin sync registration** (interactive password):

```bash
atuin register -u <username> -e <email>   # prompts for password
atuin sync
atuin key                                  # SAVE in 1Password — needed on a 2nd machine
```

**Ollama model pull** (optional, ~18GB):

```bash
ollama-up                          # start daemon (session-only, no boot persistence)
ollama pull qwen3-coder:30b        # for the espanso :llm trigger
```

**Plash from Mac App Store** (no Homebrew cask exists):

Visit https://apps.apple.com/app/plash/id1494023538, install, then drag `~/dotfiles/wallpapers/shaders/*.html` files into Plash for live shader wallpapers.

**API keys for AI tooling** (export in `~/.zshrc.local` so they survive pulls):

| Var | Used by | Required for |
|-----|---------|--------------|
| `ANTHROPIC_API_KEY` | `avante.nvim` (`<leader>v*` keys) | In-buffer Claude editing inside Neovim |
| `OPENAI_API_KEY` | `gptcommit`, `opencode` (when routed to OpenAI) | AI commit messages + multi-provider terminal agent |

```bash
# in ~/.zshrc.local (NOT tracked in git)
export ANTHROPIC_API_KEY="sk-ant-..."
export OPENAI_API_KEY="sk-..."
```

Per-tool one-time setup (opt-in):
- `gptcommit install` inside any repo where you want auto-generated commit messages (writes a `prepare-commit-msg` hook to that repo only).
- `opencode auth login` first time you run `opencode` (provider picker).

**Stream Deck profile + Mac Automation plugin** (only if you use a Stream Deck):

1. Install the Stream Deck app from Elgato.
2. Install the **Mac Automation** plugin (free): https://marketplace.elgato.com/product/mac-automation-8468fc12-644b-427a-84cb-127c82c5bb30 — required because Stream Deck 7.x broke custom URL schemes like `raycast://` in the built-in Website action.
3. Build the profile: `bun ~/dotfiles/scripts/scripts/streamdeck-build.ts <source.streamDeckProfile> <output.streamDeckProfile>` then `open <output>` to import.

---

## Phase 5: Verification

**Execute all checks from VERIFY.md.**

If any verification fails, surface the specific check that failed and suggest the matching repair command (most are documented in VERIFY.md's "If this fails" notes).

---

## Success/Failure Messages

### On Success

```
"Dotfiles installed successfully.

What's now active:
  • Shell: open a new terminal — startup ~140ms
  • Wallpaper: rotates hourly via com.lucas.wallpaper-rotate LaunchAgent
  • Sketchybar: Claude Code 5-hour billing block indicator (label `$X • XhYm`)
  • Espanso: type :dt anywhere → today's ISO date

Manual steps remaining (5 min total):
  1. System Settings → Privacy & Security → Accessibility → toggle on:
     Espanso, Maccy, Übersicht, boring.notch, AeroSpace
  2. atuin register -u YOU -e you@email.com (then atuin key — save in 1Password)
  3. ollama-up && ollama pull qwen3-coder:30b (for :llm trigger)
  4. Install Plash from Mac App Store (for shader wallpapers)
  5. Restart your terminal (or: source ~/.zprofile && source ~/.zshrc)

Customization: edit ~/.zshrc.local (gitignored) for machine-specific overrides.
Update later with: cd ~/dotfiles && ./install.sh --update"
```

### On Failure

```
"Installation encountered issues. Common fixes:

  • brew install fails: 'xcode-select --install' first, then re-run
  • stow conflicts: re-run with './install.sh --force-stow' (uses --adopt)
  • LaunchAgents not loading: 'cd ~/dotfiles && ./setup.sh --configure'
  • Espanso won't start: grant Accessibility in System Settings, then 'espanso start'
  • Neovim plugins broken: 'nvim +Lazy sync +qa' inside Neovim

Run the verification commands in VERIFY.md to pinpoint what's broken.
Need help? Open an issue at https://github.com/durante-tech/dotfiles/issues"
```

---

## Update / Repair Workflows

### Update an existing install

```bash
cd "$HOME/dotfiles"
git pull origin main
./install.sh --update
```

This skips Homebrew installs (faster) but re-stows packages, re-renders LaunchAgents, syncs Tmux + Neovim plugins.

### Repair a broken install

```bash
cd "$HOME/dotfiles"
./setup.sh --all       # re-stow + re-render LaunchAgents + verify
```

### Clean up packages dropped from Brewfile

```bash
cd "$HOME/dotfiles"
brew bundle cleanup    # shows what would be removed
brew bundle cleanup --force   # actually remove (destructive)
```

---

## What's Included

### Top-level
- `install.sh` — automated installer (canonical entrypoint)
- `setup.sh` — post-install configuration (called by install.sh)
- `Brewfile` — declarative package manifest (~67 entries)
- `README.md` — overview + key bindings reference
- `README_NEW_MACOS.md` — onboarding guide (uses mise, not nvm)
- `INSTALL.md` — this file
- `VERIFY.md` — verification checks (companion)
- `CLAUDE.md` — full reference for AI assistants
- `macos/.macos` — 44 macOS defaults entries

### Stowable packages (18)
- `aerospace/` → `~/.config/aerospace/` — i3-like tiling window manager
- `atuin/` → `~/.config/atuin/` — encrypted shell history sync
- `espanso/` → `~/Library/Application Support/espanso/` — text expander config
- `ghostty/` → `~/.config/ghostty/` — primary terminal config
- `karabiner/` → `~/.config/karabiner/` — key remapping
- `kitty/` → `~/.config/kitty/` — secondary terminal
- `mise/` → `~/.config/mise/` — polyglot version manager (replaces fnm + pyenv)
- `mpd/` → `~/.config/mpd/` — music daemon
- `nvim/` → `~/.config/nvim/` — Neovim 0.12 config (36 plugins)
- `rmpc/` → `~/.config/rmpc/` — TUI music player
- `scripts/` → `~/scripts/` — tmux-sessionizer, fzf helpers, wallpaper-rotate, wallpaper-cycle, wallpaper-workspace
- `sketchybar/` → `~/.config/sketchybar/` — custom status bar (incl. claude.sh plugin for billing-block indicator)
- `starship/` → `~/.config/starship/` — shell prompt
- `tmux/` → `~/.config/tmux/` — multiplexer config + TPM plugins
- `w3m/` → `~/.w3m/` — terminal browser
- `wallpapers/` → stowed (Plash shaders + gallery README live in-repo; the 10-piece JPG gallery itself is NOT in the repo — regenerate via Media skill or copy from another machine)
- `yazi/` → `~/.config/yazi/` — terminal file manager
- `zed/` → `~/.config/zed/` — editor config
- `zsh/` → `~/.zshrc`, `~/.zprofile` — shell init

### Templates rendered at install time

All nine `.plist.template` files in `launchagents/Library/LaunchAgents/` are
rendered into `~/Library/LaunchAgents/` with `__USER__` substituted for the
current `$USER` (macOS launchd doesn't expand env vars in plist contents —
templating is the only way). `setup.sh::render_launchagents()` handles this
and `launchctl bootstrap`s each agent so they fire on next login.

| Template | What it does |
|----------|--------------|
| `com.lucas.bd-dawn.plist.template` | BetterDisplay → dawn mode (early morning) |
| `com.lucas.bd-day.plist.template` | BetterDisplay → day mode |
| `com.lucas.bd-afternoon.plist.template` | BetterDisplay → afternoon mode |
| `com.lucas.bd-evening.plist.template` | BetterDisplay → evening mode |
| `com.lucas.bd-night.plist.template` | BetterDisplay → night mode |
| `com.lucas.bd-lmu-watch.plist.template` | Light-metering watcher (sets bd mode on ambient-light change) |
| `com.lucas.sketchybar-firstboot.plist.template` | Sketchybar warm-up at first login |
| `com.lucas.ubersicht.plist.template` | Übersicht autostart |
| `com.lucas.wallpaper-rotate.plist.template` | Hourly wallpaper rotation |

> Note: filenames carry the `com.lucas.` prefix. Renaming to `com.${USER}.`
> is on the roadmap (would require coordinated changes in setup.sh,
> VERIFY.md, and the wallpaper README) — not done yet.

### Documentation pack
- `docs/README.md` — docs index
- `docs/getting-started/` — quick-start, philosophy, gnu-stow, daily-workflow
- `docs/zsh/aliases-and-functions.md` — full alias reference
- `docs/tier5-setup.md` — Maccy + gh-dash + Atuin manual setup
- `docs/archive/2025-12_action-plan-enhancement.md` — historical planning record
- Per-tool docs: `docs/aerospace/`, `docs/sketchybar/`, `docs/yazi/`, etc.

### What's NOT included (manual install required)
- **Plash** — Mac App Store only (free): https://apps.apple.com/app/plash/id1494023538
- **Ollama models** — chosen by user based on RAM budget. Recommended: `qwen3-coder:30b` (18GB, requires 64GB RAM) for the `:llm` espanso trigger.
- **Atuin sync account** — user runs `atuin register` interactively (password)
- **1Password account** — for SSH agent + secrets management
