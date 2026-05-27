---
name: dotfiles
pack-id: durante-tech-dotfiles-v2.0.0
version: 2.0.0
author: durante-tech (Lucas Gertel)
description: macOS terminal-first, keyboard-driven development environment. 22 stowable packages, 77 brew formulas + 22 casks, mise polyglot version manager, hourly Durante-themed wallpaper rotation, sketchybar Claude Code billing-block indicator, espanso :llm trigger to local Ollama. USE WHEN install dotfiles, set up new mac, clone dotfiles, install lucas dotfiles, configure new development machine, restore dotfiles, update dotfiles, repair dotfiles, fresh mac setup, dotfile installation, durante dotfiles, dotfiles new machine, terminal-first setup, install brewfile, mise migration, durante setup.
type: dotfiles
role: environment
visibility: public
category: DevEnvironment
platform: macOS-AppleSilicon
dependencies: [Homebrew, GNU Stow]
keywords: [dotfiles, install dotfiles, set up new mac, clone dotfiles, install lucas dotfiles, configure new development machine, restore dotfiles, update dotfiles, repair dotfiles, fresh mac setup, durante dotfiles, mise, ollama, sketchybar, aerospace, espanso, neovim, tmux, ghostty]
---

<div align="center">

# ⌨️ Dotfiles

**macOS terminal-first, keyboard-driven development environment**

[![CI](https://github.com/durante-tech/dotfiles/actions/workflows/lint.yml/badge.svg)](https://github.com/durante-tech/dotfiles/actions/workflows/lint.yml)
![macOS](https://img.shields.io/badge/macOS-Sequoia-000000?logo=apple&logoColor=white)
![Neovim](https://img.shields.io/badge/Neovim-0.12+-57A143?logo=neovim&logoColor=white)
![Shell](https://img.shields.io/badge/Shell-Zsh-4EAA25?logo=gnubash&logoColor=white)

<!-- Replace with your actual screenshot -->
![Terminal Setup](assets/hero.png)

*Catppuccin Mocha terminals · Rose-pine Neovim · Sketchybar · AeroSpace tiling*

</div>

---

## For AI Agents — Install / Update / Repair

**If you're an AI agent (Claude Code, etc.) and the user asked you to install, update, or repair this dotfiles environment, here's the contract:**

1. **Read [`INSTALL.md`](INSTALL.md)** — wizard-style 5-phase guide (System Analysis → User Questions → Backup → Install → Verify) using `AskUserQuestion` + `TodoWrite`.
2. **Drive [`install.sh`](install.sh)** with the right flags based on user's answers — don't re-implement install logic. The script is canonical and idempotent.
3. **Walk [`VERIFY.md`](VERIFY.md)** end-to-end after install — 11 sections of bash one-liners that emit `OK` / `FAIL` / `WARN`. Each `FAIL` has a paired "If this fails" repair note.
4. **Surface manual steps** the user must do (5 things that can't be automated): Accessibility grants for Espanso/Maccy/Übersicht/boring.notch/AeroSpace, `atuin register` (interactive password), `ollama pull qwen3-coder:30b`, install Plash from the Mac App Store, and 1Password account setup.

### Quick agent-driven install

```
"Install Lucas's dotfiles from this repo" → Read INSTALL.md → run wizard
"Update my dotfiles"                       → Read INSTALL.md → choose Update mode
"Verify my dotfiles install"               → Read VERIFY.md → run all checks
"Set up a fresh Mac with these dotfiles"   → Read INSTALL.md → choose Fresh install
```

The full 12-step install runs `install.sh` which internally drives: Xcode CLT → Homebrew → 77 formulas → 22 casks → Bun + ccusage + Fabric → stow 22 packages → `mise install` → `setup.sh --configure` (renders 9 LaunchAgent templates with `__USER__` substitution) → Espanso service register → TPM tmux plugins → Neovim Lazy sync → `./macos/.macos` (44 defaults entries) → verification.

> **For human readers:** the rest of this README is the standard overview. AI agents can skip to `INSTALL.md`.

---

## Preview

<!-- Take these screenshots and add to assets/ -->

| Terminal + Sketchybar | Neovim IDE |
|:---:|:---:|
| ![Terminal](assets/terminal.png) | ![Neovim](assets/neovim.png) |

| Tmux Sessions | File Manager (Yazi) |
|:---:|:---:|
| ![Tmux](assets/tmux.png) | ![Yazi](assets/yazi.png) |

---

## What's Included

22 stowable packages — install everything or pick what you need.

### Core

| Tool | Description | Theme |
|------|-------------|-------|
| **[Zsh](docs/zsh/README.md)** | Shell with vi-mode, 70+ aliases, Starship prompt | Catppuccin Mocha |
| **[Neovim](docs/neovim/README.md)** | IDE-like editor — LSP, Snacks picker, 30+ plugins | Rose-pine |
| **[Tmux](docs/tmux/README.md)** | Multiplexer with session persistence, floating tools | Catppuccin Mocha |
| **[Ghostty](docs/ghostty/README.md)** | Primary terminal — 75% opacity, 23px blur | Catppuccin Mocha |

### Window Management & UI

| Tool | Description |
|------|-------------|
| **[AeroSpace](docs/aerospace/README.md)** | i3-like tiling WM with workspace-to-monitor pinning |
| **[Sketchybar](docs/sketchybar/README.md)** | Custom status bar — workspaces, weather, CPU, media, git |
| **[Karabiner](docs/karabiner/README.md)** | Key remapping |
| **[Wallpapers](wallpapers/README.md)** | 10-piece Durante gallery, hourly time-banded rotation (LaunchAgent), GLSL shaders for Plash |
| **Übersicht** | Webview widgets above wallpaper, below windows |
| **boring.notch** | Notch → Dynamic-Island-style music/calendar/camera (OSS) |

### CLI Tools

| Tool | Description |
|------|-------------|
| **[Yazi](docs/yazi/README.md)** | Terminal file manager with image preview |
| **[Starship](docs/starship/README.md)** | Cross-shell prompt with vi-mode indicators |
| **[Atuin](docs/atuin/README.md)** | Encrypted shell history sync |
| **[W3m](docs/w3m/README.md)** | Terminal web browser with vi-keys |

### Additional Terminals

| Tool | Status |
|------|--------|
| **Alacritty** | Configured, secondary |
| **Kitty** | Configured, secondary |
| **WezTerm** | Configured, secondary |

### Media & Extras

| Tool | Description |
|------|-------------|
| **MPD + rmpc** | Music daemon + TUI player |
| **Zed** | Editor config (lightweight alternative) |
| **Scripts** | tmux-sessionizer, FZF helpers, git integrations |

### AI / Productivity

| Tool | Description |
|------|-------------|
| **mise** | Polyglot version manager — replaces fnm + pyenv |
| **gum** | Glamorous shell-script TUI components (Charmbracelet) |
| **glow** | Terminal markdown renderer (`gm` alias, Charmbracelet) |
| **ollama** | Local LLMs — `ollama-up` to start daemon |
| **[espanso](espanso/README.md)** | System-wide text expander (`:dt`, `:ts`, `:sig`, `:llm`) |
| **maccy** | Clipboard history manager (Cmd+Shift+C / Cmd+Shift+V) |
| **gh-dash** | Terminal PR/issue dashboard (`ghd` alias) |
| **atuin** | Encrypted shell-history sync ([setup](docs/tier5-setup.md)) |

---

## Quick Start

### Fresh Install (New Machine)

**Option A — AI-assisted wizard (recommended):**
After cloning, point your AI assistant at the repo and ask it to install. It reads [`INSTALL.md`](INSTALL.md) and walks you through a 5-phase wizard with confirmations at each step.

```bash
git clone https://github.com/durante-tech/dotfiles.git ~/dotfiles
cd ~/dotfiles

# Then in Claude Code:
"Install these dotfiles using INSTALL.md"
```

**Option B — Manual one-shot:**

```bash
# 1. Clone
git clone https://github.com/durante-tech/dotfiles.git ~/dotfiles
cd ~/dotfiles

# 2. Install everything (Homebrew, packages, configs, plugins, LaunchAgents,
#    macOS defaults — all 12 phases auto-driven by install.sh)
./install.sh

# 3. Verify (optional)
# Use VERIFY.md as a checklist or ask your AI to walk it.
```

### Options

```bash
./install.sh --dry-run       # Preview without changes
./update.sh                  # Update existing install (wraps install.sh --update)
./smart-pull.sh              # Pull + open DOS with upgrade prompt (Claude reads diff, runs update.sh, asks smart questions)
./install.sh --skip-casks    # Skip GUI apps
./setup.sh --check           # Verify dependencies
./setup.sh --stow            # Re-stow all packages
./personalize.sh             # Interactive: write ~/.config/dotfiles/personal.env (monitor names, BD tagIDs, keyboard layout)
```

See `docs/UPGRADE.md` for the post-pull checklist (which tools auto-reload,
which need a manual nudge, how to clean up tools retired between versions).

**Forking?** See [`docs/PERSONALIZE.md`](docs/PERSONALIZE.md) for the catalog
of machine-specific values (monitor names, BetterDisplay hardware tagIDs,
keyboard layout, personal app preferences). Run `./personalize.sh` for an
interactive prompt that writes `~/.config/dotfiles/personal.env` for you.

**Pulling updates?** Just `git pull` — the tracked `post-merge` hook prints
a copy-pasteable upgrade prompt to your terminal. Paste it into your
already-open Claude / DOS session and it'll classify the changes, run
`./update.sh`, and ask you only about decisions it can't safely make
on its own. See [`docs/UPGRADE.md`](docs/UPGRADE.md) for paths A/B/C.

---

## Key Bindings

### Tmux (`Ctrl+Space` prefix)

| Key | Action |
|-----|--------|
| `\|` / `-` | Split horizontal / vertical |
| `H/J/K/L` | Resize panes |
| `Ctrl+g` | Lazygit (floating) |
| `Ctrl+y` | Yazi (floating) |
| `f` | tmux-sessionizer |
| `o` | Session picker |

### Neovim (`Space` leader)

| Key | Action |
|-----|--------|
| `<leader>pf` | Find files |
| `<leader>ps` | Grep search |
| `<leader>pp` | Switch project |
| `<leader>lg` | Lazygit |
| `<leader>ee` | File explorer |
| `s` | Flash jump |
| `<C-e>` | Harpoon menu |

### AeroSpace (`Alt` prefix)

| Key | Action |
|-----|--------|
| `Alt+h/j/k/l` | Focus window |
| `Alt+Shift+h/j/k/l` | Move window |
| `Alt+1/2/B/D/T/M/N` | Switch workspace |
| `Alt+Enter` | New terminal |
| `Alt+Shift+Space` | Fullscreen |

> **Full keybinding reference**: See [CLAUDE.md](CLAUDE.md) for every alias, keybinding, and plugin documented.

---

## Design Principles

- **Vi-mode everywhere** — Zsh, Tmux, Neovim, Yazi, W3m, AeroSpace all use hjkl
- **Keyboard-driven** — Mouse optional, everything reachable via keybindings
- **Consistent theming** — Catppuccin Mocha (terminal tools) + Rose-pine (Neovim)
- **Transparent terminals** — 75% opacity + 23px blur, wallpaper shows through
- **Modular** — Each tool independently stowable via GNU Stow
- **Reproducible** — Brewfile + install script + macOS defaults = full setup in one command

---

## Directory Structure

```
dotfiles/
├── aerospace/        → ~/.config/aerospace/
├── alacritty/        → ~/.config/alacritty/
├── atuin/            → ~/.config/atuin/
├── ghostty/          → ~/.config/ghostty/
├── karabiner/        → ~/.config/karabiner/
├── kitty/            → ~/.config/kitty/
├── macos/            → macOS system defaults script
├── mpd/              → ~/.config/mpd/
├── nvim/             → ~/.config/nvim/
├── rmpc/             → ~/.config/rmpc/
├── scripts/          → ~/scripts/
├── sketchybar/       → ~/.config/sketchybar/
├── starship/         → ~/.config/starship/
├── tmux/             → ~/.config/tmux/
├── w3m/              → ~/.w3m/
├── wallpapers/       → GLSL shader pages for Plash + Durante gallery README
├── launchagents/     → ~/Library/LaunchAgents/ (com.lucas.wallpaper-rotate)
├── wezterm/          → ~/.config/wezterm/
├── yazi/             → ~/.config/yazi/
├── zed/              → ~/.config/zed/
├── zsh/              → ~/.zshrc, ~/.zprofile
├── Brewfile          # All Homebrew packages
├── install.sh        # Automated installer
├── setup.sh          # Post-clone configuration
├── CLAUDE.md         # AI assistant context (full reference)
└── docs/             # Per-tool documentation
```

---

## Stow Commands

```bash
cd ~/dotfiles

# Stow one package
stow -t ~ nvim

# Re-stow (update symlinks)
stow -R -t ~ nvim

# Unstow
stow -D -t ~ nvim

# Stow everything
stow -t ~ aerospace atuin ghostty karabiner mpd nvim rmpc \
         scripts sketchybar starship tmux w3m yazi zed zsh
```

---

## Monitor Setup

Dual-monitor with AeroSpace workspace pinning:

| Monitor | Type | Workspaces |
|---------|------|-----------|
| **DEV-MAIN** | Built-in Retina XDR (3456×2234) | 1, B(rowser), D(ev), M(essaging), N(otes), E(mail) |
| **PORTRAIT** | External 90° (2880×5120) | 2, T(erminal) |

Edit `~/.config/aerospace/aerospace.toml` with your monitor names after install.

---

## Documentation

Full reference for every tool, keybinding, alias, and plugin is in **[CLAUDE.md](CLAUDE.md)** — designed as both human documentation and AI assistant context.

Per-tool docs are in the [`docs/`](docs/) directory.

---

## Troubleshooting

<details>
<summary><b>Stow conflicts</b></summary>

```bash
mv ~/.config/nvim ~/.config/nvim.bak
stow -t ~ nvim
```

</details>

<details>
<summary><b>Commands not found</b></summary>

```bash
source ~/.zprofile && source ~/.zshrc
```

</details>

<details>
<summary><b>Neovim plugins not loading</b></summary>

```bash
nvim +Lazy sync +qa
```

</details>

<details>
<summary><b>Tmux plugins not loading</b></summary>

```bash
# Inside tmux: prefix + I (Ctrl+Space, Shift+I)
```

</details>

---

<div align="center">

**[INSTALL.md](INSTALL.md)** (wizard) · **[VERIFY.md](VERIFY.md)** (checks) · **[CLAUDE.md](CLAUDE.md)** (full reference) · **[README_NEW_MACOS.md](README_NEW_MACOS.md)** (manual onboarding)

</div>

---

## Customization

User customizations live separately and are never overwritten by updates.

For machine-specific overrides (gitignored):

```bash
~/.zshrc.local        # sourced after .zshrc
~/.zprofile.local     # sourced after .zprofile
```

For agent-driven personalization (template substitutions, signature edits):

```bash
~/dotfiles/espanso/Library/Application Support/espanso/match/base.yml   # edit :sig trigger to your name/email
~/dotfiles/launchagents/Library/LaunchAgents/*.plist.template            # __USER__ rendered at install time
```

---

## Credits

- **Pack family:** durante-tech / DOS
- **Distribution protocol:** [RFC-0011](https://github.com/durante-tech/dos) (Packs Distribution)
- **Forked from:** [Sin-cy/dotfiles](https://github.com/Sin-cy/dotfiles)
- **Themes:** Catppuccin Mocha · Rose Pine
- **AI installation:** wizard pattern after [MakerkitTeam](https://github.com/durante-tech/dos)

---

## Changelog

### 2.0.0 — 2026-04-30

- Added wizard-style AI installation: `INSTALL.md` + `VERIFY.md` for Claude Code-driven setup
- Replaced fnm + pyenv with **mise** polyglot version manager (52% faster shell startup: 290ms → 140ms)
- Added Tier 3 productivity stack: gum, glow, ollama, espanso, ccusage
- Added Tier 5 stack: maccy, gh-dash, atuin sync support
- New Sketchybar **Claude Code billing-block indicator** (5-hour rolling spend + time remaining)
- New 10-piece Durante wallpaper gallery with hourly time-banded rotation (LaunchAgent)
- 3 GLSL shaders for Plash live wallpapers (matrix / aurora / flowfield)
- Ghostty added to Brewfile (was previously a manual install gap)
- Espanso `:llm` + `:llmf` triggers wired to local `qwen3-coder:30b` Ollama model
- LaunchAgent plists converted to `__USER__` templates rendered at install time (dev-agnostic)
- Hardcoded `/Users/lgertel` paths in shell startup (`zsh/.zshrc`), AeroSpace bd-mode chord, and fastfetch logo replaced with `$HOME` + existence guards. Ubersicht widgets and some scripts still read DOS-private `~/Durante/` paths — those gracefully no-op when absent.
- Drift cleanup: removed nvm/htop/btop/duplicate compinit/duplicate Antigravity PATH
- Updated `README_NEW_MACOS.md` to use mise instead of nvm
- New documentation: `docs/zsh/aliases-and-functions.md` (Wallpaper / Charmbracelet / LLM / GitHub Dashboard sections), `docs/tier5-setup.md` (manual steps for Maccy + Atuin)
- New stow packages: `mise/`, `espanso/`, `wallpapers/`, `launchagents/` (templated)

### 1.x — pre-2026-04
- Forked from Sin-cy/dotfiles
- See git history for incremental changes
