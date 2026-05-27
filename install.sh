#!/bin/bash
#
# Dotfiles Installation Script
# Handles both fresh installs and updates to existing environments
#
# Usage:
#   ./install.sh              # Full install (safe to re-run)
#   ./install.sh --update     # Update only (skip slow installs)
#   ./install.sh --help       # Show all options
#

set -e  # Exit on error

# =============================================================================
# CONFIGURATION
# =============================================================================

DOTFILES_REPO="https://github.com/durante-tech/dotfiles.git"
DOTFILES_DIR="$HOME/dotfiles"
TPM_DIR="$HOME/.tmux/plugins/tpm"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Flags (defaults)
SKIP_BREW=false
SKIP_CASKS=false
SKIP_MACOS_DEFAULTS=false
UPDATE_ONLY=false
FORCE_STOW=false
VERBOSE=false
DRY_RUN=false

# =============================================================================
# HELPER FUNCTIONS
# =============================================================================

print_header() {
    echo ""
    echo -e "${BLUE}══════════════════════════════════════════════════════════════${NC}"
    echo -e "${BLUE}  $1${NC}"
    echo -e "${BLUE}══════════════════════════════════════════════════════════════${NC}"
}

print_step() {
    echo -e "${GREEN}▶${NC} $1"
}

print_skip() {
    echo -e "${YELLOW}⏭${NC} $1 (skipped - already installed)"
}

print_warn() {
    echo -e "${YELLOW}⚠${NC} $1"
}

print_error() {
    echo -e "${RED}✗${NC} $1"
}

print_success() {
    echo -e "${GREEN}✓${NC} $1"
}

print_dry() {
    echo -e "${BLUE}[DRY-RUN]${NC} Would: $1"
}

print_dry_skip() {
    echo -e "${YELLOW}[DRY-RUN]${NC} Skip: $1 (already installed)"
}

# Check if a command exists
cmd_exists() {
    command -v "$1" &>/dev/null
}

# Check if a brew formula is installed
brew_installed() {
    brew list "$1" &>/dev/null 2>&1
}

# Check if a brew cask is installed
cask_installed() {
    brew list --cask "$1" &>/dev/null 2>&1
}

# Install brew formula if not already installed
brew_install() {
    if brew_installed "$1"; then
        $VERBOSE && print_skip "$1"
        $DRY_RUN && print_dry_skip "$1"
        return 0
    fi
    if [ "$DRY_RUN" = true ]; then
        print_dry "brew install $1"
        return 0
    fi
    print_step "Installing $1..."
    brew install "$1"
}

# Install brew cask if not already installed
cask_install() {
    if cask_installed "$1"; then
        $VERBOSE && print_skip "$1 (cask)"
        $DRY_RUN && print_dry_skip "$1 (cask)"
        return 0
    fi
    if [ "$DRY_RUN" = true ]; then
        print_dry "brew install --cask $1"
        return 0
    fi
    print_step "Installing $1 (cask)..."
    brew install --cask "$1"
}

# Execute command (or show in dry-run mode)
run_cmd() {
    if [ "$DRY_RUN" = true ]; then
        print_dry "$*"
        return 0
    fi
    "$@"
}

show_help() {
    cat << EOF
Dotfiles Installation Script

Usage: ./install.sh [OPTIONS]

Options:
    --help, -h          Show this help message
    --dry-run, -n       Show what would be done without making changes
    --update, -u        Update mode: skip Homebrew installs, just sync plugins
    --skip-brew         Skip all Homebrew formula installations
    --skip-casks        Skip all Homebrew cask installations
    --skip-macos        Skip macOS defaults configuration
    --force-stow        Force stow to adopt existing files (--adopt flag)
    --verbose, -v       Show verbose output (including skipped packages)

Examples:
    ./install.sh                    # Full fresh install
    ./install.sh --dry-run          # Preview what would be installed
    ./update.sh                     # Quick update (alias of --update)
    ./install.sh --update           # Quick update (plugins only)
    ./install.sh --skip-casks       # Install without GUI apps
    ./install.sh --force-stow       # Re-stow and adopt existing configs

This script is idempotent - safe to run multiple times.
EOF
    exit 0
}

# =============================================================================
# PARSE ARGUMENTS
# =============================================================================

while [[ $# -gt 0 ]]; do
    case $1 in
        --help|-h)
            show_help
            ;;
        --dry-run|-n)
            DRY_RUN=true
            VERBOSE=true  # Show all in dry-run
            shift
            ;;
        --update|-u)
            UPDATE_ONLY=true
            SKIP_BREW=true
            SKIP_CASKS=true
            SKIP_MACOS_DEFAULTS=true
            shift
            ;;
        --skip-brew)
            SKIP_BREW=true
            shift
            ;;
        --skip-casks)
            SKIP_CASKS=true
            shift
            ;;
        --skip-macos)
            SKIP_MACOS_DEFAULTS=true
            shift
            ;;
        --force-stow)
            FORCE_STOW=true
            shift
            ;;
        --verbose|-v)
            VERBOSE=true
            shift
            ;;
        *)
            print_error "Unknown option: $1"
            echo "Use --help for usage information"
            exit 1
            ;;
    esac
done

# =============================================================================
# MAIN INSTALLATION
# =============================================================================

print_header "Dotfiles Installation"
if [ "$DRY_RUN" = true ]; then
    echo -e "${BLUE}═══ DRY-RUN MODE - No changes will be made ═══${NC}"
fi
echo "Mode: $([ "$UPDATE_ONLY" = true ] && echo "Update" || echo "Full Install")"
echo ""

# -----------------------------------------------------------------------------
# 1. XCODE COMMAND LINE TOOLS (macOS only)
# -----------------------------------------------------------------------------

if [[ "$(uname)" == "Darwin" ]]; then
    print_header "1. Xcode Command Line Tools"

    if xcode-select -p &>/dev/null; then
        print_success "Xcode CLI tools already installed"
    else
        print_step "Installing Xcode CLI tools..."
        xcode-select --install
        echo "Please complete the Xcode installation and re-run this script."
        exit 0
    fi
fi

# -----------------------------------------------------------------------------
# 2. HOMEBREW
# -----------------------------------------------------------------------------

print_header "2. Homebrew"

if cmd_exists brew; then
    print_success "Homebrew already installed"
    # Update Homebrew
    if [ "$UPDATE_ONLY" = true ] && [ "$DRY_RUN" = false ]; then
        print_step "Updating Homebrew..."
        brew update
    elif [ "$UPDATE_ONLY" = true ] && [ "$DRY_RUN" = true ]; then
        print_dry "brew update"
    fi
else
    if [ "$DRY_RUN" = true ]; then
        print_dry "Install Homebrew"
    else
        print_step "Installing Homebrew..."
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

        # Add brew to PATH for this session
        if [[ -f /opt/homebrew/bin/brew ]]; then
            eval "$(/opt/homebrew/bin/brew shellenv)"
        elif [[ -f /usr/local/bin/brew ]]; then
            eval "$(/usr/local/bin/brew shellenv)"
        fi
    fi
fi

if [ "$DRY_RUN" = false ]; then
    brew analytics off
fi

# Taps
print_step "Configuring Homebrew taps..."
if [ "$DRY_RUN" = true ]; then
    print_dry "brew tap FelixKratz/formulae"
    print_dry "brew tap nikitabobko/tap"
else
    brew tap FelixKratz/formulae 2>/dev/null || true
    brew tap nikitabobko/tap 2>/dev/null || true
fi

# -----------------------------------------------------------------------------
# 3. HOMEBREW FORMULAE
# -----------------------------------------------------------------------------

if [ "$SKIP_BREW" = false ]; then
    print_header "3. Homebrew Formulae"

    # Core Utils
    print_step "Installing core utilities..."
    brew_install coreutils

    # Shell & Plugins
    print_step "Installing shell tools..."
    brew_install zsh-autosuggestions
    brew_install zsh-syntax-highlighting
    brew_install stow
    brew_install starship
    brew_install atuin
    brew_install zoxide
    brew_install fzf

    # File & Text Tools
    print_step "Installing file/text tools..."
    brew_install bat
    brew_install fd
    brew_install ripgrep
    brew_install eza
    brew_install tree
    brew_install jq
    brew_install yazi
    brew_install broot
    brew_install w3m

    # Development
    print_step "Installing development tools..."
    brew_install git
    brew_install lazygit
    brew_install git-delta
    brew_install neovim
    brew_install tmux
    brew_install tree-sitter
    brew_install lua
    brew_install luajit
    brew_install luarocks
    brew_install prettier
    brew_install make

    # Languages & Version Managers
    # mise is the polyglot manager — replaces fnm + pyenv + nvm + asdf.
    # node here is just the bootstrap binary; per-project versions managed by mise.
    print_step "Installing languages & version managers..."
    brew_install mise
    brew_install node
    brew_install go
    brew_install deno
    brew_install sqlite

    # Modern CLI Replacements
    print_step "Installing modern CLI tools..."
    brew_install procs
    brew_install bottom
    brew_install curlie
    brew_install dust
    brew_install duf
    brew_install onefetch
    brew_install fx
    brew_install navi
    brew_install tldr
    brew_install direnv

    # Image & PDF Tools (for Neovim plugins)
    print_step "Installing image/PDF tools..."
    brew_install pngpaste
    brew_install imagemagick
    brew_install poppler
    brew_install ghostscript

    # macOS Window Management & UI
    print_step "Installing window management tools..."
    brew_install borders
    brew_install sketchybar

    # Media
    print_step "Installing media tools..."
    brew_install mpd
    brew_install rmpc

    # AI & Productivity
    print_step "Installing AI/productivity tools..."
    brew_install aider
    brew_install ollama          # local LLM runtime
    brew_install gum             # glamorous shell scripts
    brew_install glow            # terminal markdown renderer
    brew_install wallpaper       # macOS wallpaper CLI (used by hourly rotation)

    # Misc
    brew_install qmk

    print_success "Homebrew formulae complete"
else
    print_header "3. Homebrew Formulae (SKIPPED)"
fi

# -----------------------------------------------------------------------------
# 3.5 BREWFILE RECONCILIATION (fires in BOTH full-install AND --update modes)
# -----------------------------------------------------------------------------
# Idempotent — brew bundle skips already-installed packages. This is what
# picks up new additions (gptcommit, osv-scanner, custom taps, casks) for
# existing devs running `./install.sh --update` after a git pull.
#
# Note: brew bundle is ADDITIVE only — it does not uninstall tools that were
# removed from the Brewfile. See docs/UPGRADE.md "Removing retired tools" for
# the opt-in cleanup path.

if cmd_exists brew && [ -f "$DOTFILES_DIR/Brewfile" ]; then
    print_header "3.5 Brewfile Reconciliation"
    if [ "$DRY_RUN" = true ]; then
        print_dry "brew bundle install --file=$DOTFILES_DIR/Brewfile --no-lock"
    else
        print_step "Installing anything missing from Brewfile..."
        brew bundle install --file="$DOTFILES_DIR/Brewfile" --no-lock || \
            print_warning "brew bundle had failures (check output above)"
    fi
fi

# -----------------------------------------------------------------------------
# 4. HOMEBREW CASKS (GUI Applications)
# -----------------------------------------------------------------------------

if [ "$SKIP_CASKS" = false ]; then
    print_header "4. Homebrew Casks (GUI Apps)"

    cask_install raycast
    cask_install karabiner-elements
    cask_install ghostty
    cask_install kitty
    cask_install aerospace
    cask_install keycastr
    cask_install betterdisplay
    cask_install linearmouse
    cask_install ubersicht       # webview widgets above wallpaper
    cask_install espanso         # system-wide text expander
    cask_install maccy           # clipboard history manager
    # boring.notch — Dynamic-Island-style notch utility (custom tap)
    if ! brew tap | grep -q "theboredteam/boring-notch"; then
        run_cmd brew tap theboredteam/boring-notch
    fi
    cask_install boring-notch

    # Fonts
    print_step "Installing fonts..."
    cask_install font-hack-nerd-font
    cask_install font-jetbrains-mono-nerd-font
    cask_install font-sf-pro

    print_success "Homebrew casks complete"
else
    print_header "4. Homebrew Casks (SKIPPED)"
fi

# -----------------------------------------------------------------------------
# 5. NON-HOMEBREW INSTALLATIONS
# -----------------------------------------------------------------------------

print_header "5. Non-Homebrew Tools"

# Bun
if cmd_exists bun; then
    print_success "Bun already installed ($(bun --version 2>/dev/null || echo 'unknown'))"
    if [ "$UPDATE_ONLY" = true ]; then
        if [ "$DRY_RUN" = true ]; then
            print_dry "bun upgrade"
        else
            print_step "Updating Bun..."
            bun upgrade || true
        fi
    fi
else
    if [ "$DRY_RUN" = true ]; then
        print_dry "curl -fsSL https://bun.sh/install | bash"
    else
        print_step "Installing Bun..."
        curl -fsSL https://bun.sh/install | bash
        export BUN_INSTALL="$HOME/.bun"
        export PATH="$BUN_INSTALL/bin:$PATH"
    fi
fi

# ccusage — Claude Code session/billing usage parser (used by SketchyBar
# claude indicator). Requires bun (installed above).
if cmd_exists bun; then
    if cmd_exists ccusage; then
        print_success "ccusage already installed"
    else
        if [ "$DRY_RUN" = true ]; then
            print_dry "bun install -g ccusage"
        else
            print_step "Installing ccusage globally via bun..."
            bun install -g ccusage 2>/dev/null || print_warn "ccusage install failed"
        fi
    fi
fi

# gh-dash — terminal PR/issue dashboard (used by `ghd` alias in .zshrc).
# Installed as a `gh` extension (not a brew formula). Requires `gh` from §3.
if cmd_exists gh; then
    if gh extension list 2>/dev/null | grep -q dlvhdr/gh-dash; then
        print_success "gh-dash extension already installed"
    else
        if [ "$DRY_RUN" = true ]; then
            print_dry "gh extension install dlvhdr/gh-dash"
        else
            print_step "Installing gh-dash extension..."
            gh extension install dlvhdr/gh-dash 2>/dev/null || \
                print_warn "gh-dash install failed (gh auth required first?)"
        fi
    fi
fi

# opencode — multi-provider AI CLI (sst/opencode). Requires bun OR npm.
if cmd_exists opencode; then
    print_success "opencode already installed ($(opencode --version 2>/dev/null | head -1))"
elif cmd_exists npm; then
    if [ "$DRY_RUN" = true ]; then
        print_dry "npm install -g opencode-ai"
    else
        print_step "Installing opencode globally via npm..."
        npm install -g opencode-ai 2>/dev/null || print_warn "opencode install failed"
    fi
fi

# Fabric AI (requires Go)
if cmd_exists fabric; then
    print_success "Fabric already installed"
    if [ "$UPDATE_ONLY" = true ]; then
        if [ "$DRY_RUN" = true ]; then
            print_dry "go install github.com/danielmiessler/fabric@latest"
        else
            print_step "Updating Fabric..."
            go install github.com/danielmiessler/fabric@latest || true
        fi
    fi
else
    if cmd_exists go; then
        if [ "$DRY_RUN" = true ]; then
            print_dry "go install github.com/danielmiessler/fabric@latest"
        else
            print_step "Installing Fabric AI..."
            go install github.com/danielmiessler/fabric@latest
        fi
    else
        print_warn "Go not found - skipping Fabric installation"
    fi
fi

# -----------------------------------------------------------------------------
# 6. DOTFILES CLONE & STOW
# -----------------------------------------------------------------------------

print_header "6. Dotfiles"

# Clone if not exists
if [ ! -d "$DOTFILES_DIR" ]; then
    if [ "$DRY_RUN" = true ]; then
        print_dry "git clone $DOTFILES_REPO $DOTFILES_DIR"
    else
        print_step "Cloning dotfiles repository..."
        git clone "$DOTFILES_REPO" "$DOTFILES_DIR"
    fi
else
    print_success "Dotfiles already cloned"
    if [ "$UPDATE_ONLY" = true ]; then
        if [ "$DRY_RUN" = true ]; then
            print_dry "cd $DOTFILES_DIR && git pull"
        else
            print_step "Pulling latest changes..."
            cd "$DOTFILES_DIR" && git pull || true
        fi
    fi
fi

# Ensure we're in dotfiles directory (skip in dry-run if not cloned)
if [ -d "$DOTFILES_DIR" ]; then
    cd "$DOTFILES_DIR" || exit 1
fi

# Stow packages
print_step "Stowing dotfiles packages..."

STOW_OPTS="-t ~"
if [ "$FORCE_STOW" = true ]; then
    STOW_OPTS="$STOW_OPTS --adopt"
    print_warn "Using --adopt flag (existing files will be adopted)"
fi

# Re-stow to handle updates (-R flag)
PACKAGES="aerospace atuin espanso fastfetch ghostty karabiner kitty mise mpd nvim rmpc scripts sketchybar starship tmux ubersicht w3m wallpapers wezterm yazi zed zsh"
# Note: launchagents/ is intentionally NOT in this list — it contains
# .plist.template files rendered by setup.sh's render_launchagents().
# wallpapers/ stows the shaders/README into ~/Pictures (not strictly XDG).

for pkg in $PACKAGES; do
    if [ -d "$DOTFILES_DIR/$pkg" ]; then
        if [ "$DRY_RUN" = true ]; then
            print_dry "stow -R $STOW_OPTS $pkg"
        else
            stow -R $STOW_OPTS "$pkg" 2>/dev/null || {
                print_warn "Conflict stowing $pkg - try running with --force-stow"
            }
        fi
    fi
done

print_success "Dotfiles stowed"

# -----------------------------------------------------------------------------
# 6a. PERSONALIZATION — invite the user to set machine-specific values
# -----------------------------------------------------------------------------
# Only fires on fresh installs (UPDATE_ONLY=false), when personal.env doesn't
# yet exist, and only if we're attached to a TTY (so non-interactive CI runs
# don't hang on the prompt). The maintainer's defaults work standalone — this
# is purely an invitation to personalize, not a requirement.

PERSONAL_ENV_PATH="$HOME/.config/dotfiles/personal.env"
if [ "$UPDATE_ONLY" = false ] && [ ! -f "$PERSONAL_ENV_PATH" ] && [ -t 0 ] && [ "$DRY_RUN" = false ]; then
    print_header "6a. Personalization (optional)"
    echo "This repo ships with the maintainer's monitor + hardware values."
    echo "Run ./personalize.sh now to set yours (you can also do this later)."
    echo "See docs/PERSONALIZE.md for the full catalog of machine-specific values."
    echo
    read -r -p "Run ./personalize.sh now? [Y/n]: " run_p
    if [ -z "$run_p" ] || [ "$run_p" = "y" ] || [ "$run_p" = "Y" ]; then
        "$DOTFILES_DIR/personalize.sh" || print_warning "personalize.sh exited non-zero (skip is fine)"
    else
        print_info "Skipping personalize.sh — run it later with ./personalize.sh"
    fi
fi

# -----------------------------------------------------------------------------
# 6b. MISE — install pinned tool versions
# -----------------------------------------------------------------------------
# Runs AFTER stow so that mise/.config/mise/config.toml is in place.
# Pulls node@25.5.0 + python@3.12.12 (or whatever is pinned in config).

if cmd_exists mise; then
    if [ "$DRY_RUN" = true ]; then
        print_dry "mise install"
    else
        print_step "Installing pinned tool versions via mise..."
        mise install 2>&1 | tail -5 || print_warn "mise install had issues"
        print_success "mise versions installed"
    fi
else
    print_warn "mise not found - skipping language version install"
fi

# -----------------------------------------------------------------------------
# 6c. RENDER + BOOTSTRAP LaunchAgents
# -----------------------------------------------------------------------------
# Plists in launchagents/ are templates with __USER__ placeholders. Delegate
# to setup.sh's render function which substitutes $USER and runs launchctl
# bootstrap so wallpaper-rotate + sketchybar-firstboot fire on next login.

if [ -f "$DOTFILES_DIR/setup.sh" ]; then
    if [ "$DRY_RUN" = true ]; then
        print_dry "$DOTFILES_DIR/setup.sh --configure"
    else
        print_step "Configuring environment (LaunchAgents, dirs, TPM)..."
        # --configure runs configure_environment (which calls render_launchagents)
        # + verify_config + post_update. It does NOT re-stow (we did that above).
        bash "$DOTFILES_DIR/setup.sh" --configure 2>&1 | grep -vE "^$" | tail -30 || true
    fi
fi

# -----------------------------------------------------------------------------
# 6d. ESPANSO — register and start
# -----------------------------------------------------------------------------

if cmd_exists espanso; then
    if [ "$DRY_RUN" = true ]; then
        print_dry "espanso service register && espanso start"
    else
        print_step "Registering Espanso service..."
        espanso service register 2>/dev/null || true
        espanso start 2>/dev/null || \
            print_warn "Espanso start failed — grant Accessibility in System Settings then run: espanso start"
    fi
fi

# -----------------------------------------------------------------------------
# 7. TMUX PLUGIN MANAGER (TPM)
# -----------------------------------------------------------------------------

print_header "7. Tmux Plugin Manager"

if [ -d "$TPM_DIR" ]; then
    print_success "TPM already installed"
    if [ "$UPDATE_ONLY" = true ]; then
        if [ "$DRY_RUN" = true ]; then
            print_dry "cd $TPM_DIR && git pull"
        else
            print_step "Updating TPM..."
            cd "$TPM_DIR" && git pull || true
        fi
    fi
else
    if [ "$DRY_RUN" = true ]; then
        print_dry "git clone https://github.com/tmux-plugins/tpm $TPM_DIR"
    else
        print_step "Installing TPM..."
        git clone https://github.com/tmux-plugins/tpm "$TPM_DIR"
    fi
fi

# Install tmux plugins (if tmux is running or available)
if cmd_exists tmux; then
    if [ "$DRY_RUN" = true ]; then
        print_dry "$TPM_DIR/bin/install_plugins"
    else
        print_step "Installing tmux plugins..."
        # Run TPM install script (works even if tmux isn't running)
        "$TPM_DIR/bin/install_plugins" 2>/dev/null || {
            print_warn "Could not auto-install tmux plugins"
            echo "    Run 'prefix + I' inside tmux to install plugins"
        }
    fi
fi

# -----------------------------------------------------------------------------
# 8. NEOVIM PLUGINS (Lazy.nvim)
# -----------------------------------------------------------------------------

print_header "8. Neovim Plugins"

if cmd_exists nvim; then
    if [ "$DRY_RUN" = true ]; then
        print_dry "nvim --headless '+Lazy! sync' +qa"
    else
        print_step "Syncing Neovim plugins (Lazy.nvim)..."
        nvim --headless "+Lazy! sync" +qa 2>/dev/null || {
            print_warn "Could not sync Neovim plugins automatically"
            echo "    Run ':Lazy sync' inside Neovim"
        }
        print_success "Neovim plugins synced"
    fi
else
    print_warn "Neovim not found - skipping plugin sync"
fi

# -----------------------------------------------------------------------------
# 9. MACOS DEFAULTS
# -----------------------------------------------------------------------------

if [[ "$(uname)" == "Darwin" ]] && [ "$SKIP_MACOS_DEFAULTS" = false ]; then
    print_header "9. macOS Defaults"

    # Run the full ./macos/.macos script (60+ defaults entries) instead of
    # the 4-line subset that used to live here. Asks for sudo upfront.
    if [ -x "$DOTFILES_DIR/macos/.macos" ]; then
        if [ "$DRY_RUN" = true ]; then
            print_dry "$DOTFILES_DIR/macos/.macos"
        else
            print_step "Applying full macOS defaults from ./macos/.macos..."
            "$DOTFILES_DIR/macos/.macos" || print_warn "macOS defaults script had issues"
            print_success "macOS defaults configured"
        fi
    else
        print_warn "macos/.macos not found or not executable"
    fi

    # Check SIP status
    echo ""
    csrutil status
else
    if [[ "$(uname)" == "Darwin" ]]; then
        print_header "9. macOS Defaults (SKIPPED)"
    fi
fi

# -----------------------------------------------------------------------------
# 10. POST-INSTALL VERIFICATION
# -----------------------------------------------------------------------------

print_header "10. Verification"

echo ""
echo "Checking critical tools..."

CRITICAL_TOOLS="git nvim tmux stow starship zoxide fzf"
ALL_OK=true

for tool in $CRITICAL_TOOLS; do
    if cmd_exists "$tool"; then
        print_success "$tool"
    else
        print_error "$tool not found"
        ALL_OK=false
    fi
done

echo ""

if [ "$ALL_OK" = true ]; then
    print_success "All critical tools installed!"
else
    print_warn "Some tools missing - check errors above"
fi

# =============================================================================
# COMPLETION
# =============================================================================

print_header "Installation Complete!"

cat << EOF

Next steps:
  1. Restart your terminal (or run: source ~/.zprofile && source ~/.zshrc)
  2. Inside tmux: Press 'prefix + I' to install tmux plugins
  3. Inside Neovim: Run ':Mason' to install LSP servers
  4. Configure monitors: See README.md for AeroSpace setup

For updates, run:
  ./update.sh                   # or: ./install.sh --update

EOF

print_success "Done!"
