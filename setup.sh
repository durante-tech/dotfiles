#!/bin/bash

# setup.sh - Configure dotfiles for current environment
# Run after cloning or pulling updates
# Usage: ./setup.sh [--check | --stow | --configure | --all]

set -e

DOTFILES_DIR="$HOME/dotfiles"
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# ============================================================================
# Helper Functions
# ============================================================================

print_header() {
    echo -e "\n${BLUE}══════════════════════════════════════════════════════════════${NC}"
    echo -e "${BLUE}  $1${NC}"
    echo -e "${BLUE}══════════════════════════════════════════════════════════════${NC}\n"
}

print_success() { echo -e "${GREEN}✓${NC} $1"; }
print_warning() { echo -e "${YELLOW}⚠${NC} $1"; }
print_error() { echo -e "${RED}✗${NC} $1"; }
print_info() { echo -e "${BLUE}ℹ${NC} $1"; }

check_command() {
    if command -v "$1" &>/dev/null; then
        print_success "$1 installed"
        return 0
    else
        print_error "$1 not found"
        return 1
    fi
}

# ============================================================================
# Dependency Check
# ============================================================================

check_dependencies() {
    print_header "Checking Dependencies"

    local missing=0

    # Essential tools
    echo "Essential tools:"
    check_command "brew" || missing=$((missing + 1))
    check_command "git" || missing=$((missing + 1))
    check_command "stow" || missing=$((missing + 1))

    echo -e "\nShell tools:"
    check_command "zsh" || missing=$((missing + 1))
    check_command "starship" || missing=$((missing + 1))
    check_command "fzf" || missing=$((missing + 1))
    check_command "zoxide" || missing=$((missing + 1))
    check_command "atuin" || missing=$((missing + 1))

    echo -e "\nDevelopment tools:"
    check_command "nvim" || missing=$((missing + 1))
    check_command "tmux" || missing=$((missing + 1))
    check_command "lazygit" || missing=$((missing + 1))
    check_command "fd" || missing=$((missing + 1))
    check_command "bat" || missing=$((missing + 1))
    check_command "eza" || missing=$((missing + 1))

    echo -e "\nmacOS tools:"
    check_command "aerospace" || print_warning "aerospace not found (optional)"
    check_command "sketchybar" || print_warning "sketchybar not found (optional)"

    echo -e "\nLanguage managers:"
    check_command "fnm" || print_warning "fnm not found (Node.js)"
    check_command "pyenv" || print_warning "pyenv not found (Python)"

    if [[ $missing -gt 0 ]]; then
        echo -e "\n${YELLOW}$missing essential tools missing. Run ./install.sh first.${NC}"
        return 1
    fi

    print_success "All essential dependencies installed"
    return 0
}

# ============================================================================
# Stow Packages
# ============================================================================

stow_packages() {
    print_header "Stowing Packages"

    cd "$DOTFILES_DIR" || exit 1

    # List of packages to stow — keep in sync with install.sh PACKAGES.
    local packages=(
        aerospace
        atuin
        espanso
        fastfetch
        ghostty
        karabiner
        kitty
        mise
        mpd
        nvim
        rmpc
        scripts
        sketchybar
        starship
        tmux
        ubersicht
        w3m
        wallpapers
        wezterm
        yazi
        zed
        zsh
    )

    # Ensure .config exists
    mkdir -p "$HOME/.config"
    # Ensure deep parent dirs exist for non-XDG stow packages
    mkdir -p "$HOME/Library/Application Support/Übersicht"

    for pkg in "${packages[@]}"; do
        if [[ -d "$DOTFILES_DIR/$pkg" ]]; then
            if stow -t ~ -R "$pkg" 2>/dev/null; then
                print_success "Stowed $pkg"
            else
                print_warning "Failed to stow $pkg (may have conflicts)"
            fi
        else
            print_info "Skipping $pkg (directory not found)"
        fi
    done

    # Übersicht caveat: its internal server.js doesn't follow relative
    # symlinks. Stow produces ../../../dotfiles/... which crashes the app.
    # Replace with an absolute symlink so server.js can resolve it.
    local uber_link="$HOME/Library/Application Support/Übersicht/widgets"
    local uber_target="$DOTFILES_DIR/ubersicht/Library/Application Support/Übersicht/widgets"
    if [[ -L "$uber_link" && -d "$uber_target" ]]; then
        ln -sfn "$uber_target" "$uber_link"
        print_success "Übersicht widgets symlink rewritten to absolute"
    fi
}

# ============================================================================
# Environment Configuration
# ============================================================================

configure_environment() {
    print_header "Configuring Environment"

    # Detect monitors for AeroSpace
    echo "Detecting monitors..."
    if command -v aerospace &>/dev/null; then
        local monitors
        monitors=$(aerospace list-monitors 2>/dev/null || echo "")

        if [[ -n "$monitors" ]]; then
            echo -e "\nConnected monitors:"
            echo "$monitors"

            echo -e "\n${YELLOW}Action needed:${NC}"
            echo "Edit ~/.config/aerospace/aerospace.toml"
            echo "Update [workspace-to-monitor-force-assignment] with your monitor names"
            echo ""
            echo "Example:"
            echo "  1 = 'Built-in Retina Display'"
            echo "  2 = 'Your-External-Monitor'"
        else
            print_warning "No monitors detected or aerospace not running"
        fi
    else
        print_info "AeroSpace not installed, skipping monitor config"
    fi

    # tmux-sessionizer paths
    echo -e "\n${YELLOW}Optional:${NC} Set custom project paths for tmux-sessionizer"
    echo "Add to ~/.zshrc or ~/.zprofile:"
    echo "  export TMUX_SESSIONIZER_PATHS=\"\$HOME/Projects \$HOME/Developer \$HOME/dotfiles\""

    # Create necessary directories
    echo -e "\nCreating directories..."
    mkdir -p "$HOME/.config"
    mkdir -p "$HOME/.local/bin"
    mkdir -p "$HOME/.local/share/nvim/mason/bin"
    mkdir -p "$HOME/scripts"
    mkdir -p "$HOME/.cache"
    mkdir -p "$HOME/.zsh/completions"
    print_success "Directories created"

    # Make scripts executable
    if [[ -d "$HOME/scripts" ]]; then
        chmod +x "$HOME/scripts"/* 2>/dev/null || true
        print_success "Scripts made executable"
    fi

    # Install tmux plugins
    if [[ -d "$HOME/.config/tmux/.tmux/plugins/tpm" ]]; then
        print_info "TPM already installed"
    else
        echo "Installing TPM (Tmux Plugin Manager)..."
        git clone https://github.com/tmux-plugins/tpm "$HOME/.config/tmux/.tmux/plugins/tpm" 2>/dev/null || true
        print_success "TPM installed - press prefix + I in tmux to install plugins"
    fi

    # Compile native helper binaries (unlock-watch) before the agents that run
    # them are bootstrapped.
    build_native_helpers

    # Render LaunchAgent plists from templates and bootstrap them.
    render_launchagents

    # Symlink dotfiles-tracked Raycast script-commands into the indexed dir.
    link_raycast_commands

    # Wire the rtk token-saver hook into Claude Code's PreToolUse:Bash chain.
    configure_rtk_hook
}

# ============================================================================
# Native Helper Binaries
# ============================================================================
#
# A repo feature needs a tiny compiled listener that launchd cannot express as
# a plain plist: launchd has no trigger for distributed notifications.
# unlock-watch.swift observes com.apple.screenIsUnlocked and runs ~/.wakeup so
# the external monitor recovers on unlock (sleepwatcher's -W display-wake hook
# is unreliable on Apple Silicon). Compiled to ~/.local/bin so the LaunchAgent
# runs an absolute path. Guarded on swiftc: a machine without the Swift
# toolchain skips the helper and com.lucas.unlock-watch simply no-ops.

build_native_helpers() {
    print_header "Building Native Helpers"

    if ! command -v swiftc >/dev/null 2>&1; then
        print_info "swiftc not found — skipping native helpers (unlock-watch)"
        return 0
    fi

    local SRC="$DOTFILES_DIR/scripts/scripts/unlock-watch.swift"
    local OUT="$HOME/.local/bin/unlock-watch"

    if [[ ! -f "$SRC" ]]; then
        print_info "No unlock-watch.swift — skipping"
        return 0
    fi

    mkdir -p "$HOME/.local/bin"
    if swiftc -O "$SRC" -o "$OUT" 2>/dev/null; then
        print_success "Built unlock-watch -> $OUT"
    else
        print_warning "Failed to build unlock-watch (unlock-recovery for external monitor disabled)"
    fi
}

# ============================================================================
# LaunchAgent Templates
# ============================================================================
#
# macOS launchd reads plists literally — no env var expansion. Repo holds
# *.plist.template files with __USER__ placeholders; this function substitutes
# the running user and copies real plists to ~/Library/LaunchAgents/, then
# bootstraps each agent into the user's gui session.

render_launchagents() {
    print_header "Rendering LaunchAgent Plists"

    local TPL_DIR="$DOTFILES_DIR/launchagents/Library/LaunchAgents"
    local DEST_DIR="$HOME/Library/LaunchAgents"

    if [[ ! -d "$TPL_DIR" ]]; then
        print_info "No launchagents/ directory — skipping"
        return 0
    fi

    mkdir -p "$DEST_DIR"
    mkdir -p "$HOME/Library/Logs"

    local rendered=0
    for tpl in "$TPL_DIR"/*.plist.template; do
        [[ -f "$tpl" ]] || continue
        local base
        base="$(basename "$tpl" .template)"
        local dest="$DEST_DIR/$base"

        sed "s|__USER__|$USER|g" "$tpl" > "$dest"

        # Bootstrap (or re-bootstrap) the agent so changes take effect now.
        launchctl bootout "gui/$(id -u)" "$dest" 2>/dev/null || true
        if launchctl bootstrap "gui/$(id -u)" "$dest" 2>/dev/null; then
            print_success "Loaded $base"
        else
            print_warning "Could not bootstrap $base (may already be loaded)"
        fi
        rendered=$((rendered + 1))
    done

    if [[ $rendered -eq 0 ]]; then
        print_info "No .plist.template files found"
    else
        print_success "Rendered $rendered LaunchAgent plist(s)"
    fi
}

# ============================================================================
# Raycast Script-Command Symlinks
# ============================================================================
#
# The Stream Deck SCREENS folder fires Raycast script-commands (display-* layout
# profiles + bd-* brightness modes). Raycast only indexes scripts in directories
# registered in its Script Commands settings. The display-* wrappers are tracked
# in dotfiles (raycast/script-commands/); this symlinks them into the Raycast
# indexed dir so they resolve without copying. Override the target with
# DOTFILES_RAYCAST_DIR (default: ~/Durante/scripts/raycast).

link_raycast_commands() {
    print_header "Linking Raycast Script Commands"

    local SRC_DIR="$DOTFILES_DIR/raycast/script-commands"
    local RAYCAST_DIR="${DOTFILES_RAYCAST_DIR:-$HOME/Durante/scripts/raycast}"

    if [[ ! -d "$SRC_DIR" ]]; then
        print_info "No raycast/script-commands/ directory — skipping"
        return 0
    fi

    mkdir -p "$RAYCAST_DIR"

    local linked=0
    for src in "$SRC_DIR"/*.sh; do
        [[ -f "$src" ]] || continue
        ln -sf "$src" "$RAYCAST_DIR/$(basename "$src")"
        linked=$((linked + 1))
    done

    if [[ $linked -eq 0 ]]; then
        print_info "No raycast script-commands found"
    else
        print_success "Linked $linked Raycast script-command(s) into $RAYCAST_DIR"
        print_info "Enable in Raycast → Extensions → Script Commands (add $RAYCAST_DIR if needed)"
    fi
}

# ============================================================================
# RTK Agent Hook (Claude Code token-saver)
# ============================================================================
#
# rtk (Rust Token Killer, installed via Brewfile) proxies verbose dev-command
# output into compact form before it reaches the agent context. Its Claude Code
# integration is a PreToolUse:Bash hook (`rtk hook claude`) that transparently
# rewrites known commands (git/cargo/npm/ls/...) to their `rtk <cmd>` proxy;
# unknown/unsafe commands (e.g. rm) pass through untouched. We append it as the
# LAST hook in the existing Bash chain so every DOS guard validates the ORIGINAL
# command first — rtk only compacts the final proxy form. Hook-only: it does NOT
# create RTK.md or mutate ~/.claude/CLAUDE.md. Idempotent; gated on rtk + jq +
# an existing settings.json; skips gracefully otherwise. Override the settings
# path with DOTFILES_CLAUDE_SETTINGS.

configure_rtk_hook() {
    print_header "Wiring RTK Agent Hook (Claude Code)"

    if ! command -v rtk >/dev/null 2>&1; then
        print_info "rtk not installed — skipping (comes from Brewfile)"
        return 0
    fi
    if ! command -v jq >/dev/null 2>&1; then
        print_warning "jq not found — cannot patch settings.json safely; skipping rtk hook"
        return 0
    fi

    local SETTINGS="${DOTFILES_CLAUDE_SETTINGS:-$HOME/.claude/settings.json}"
    if [[ ! -f "$SETTINGS" ]]; then
        print_info "No $SETTINGS — skipping rtk hook (Claude Code not configured here)"
        return 0
    fi

    # Already wired? (idempotent)
    if jq -e '[.hooks.PreToolUse[]? | select(.matcher=="Bash") | .hooks[]? | select(.command=="rtk hook claude")] | length > 0' "$SETTINGS" >/dev/null 2>&1; then
        print_success "rtk hook already present in $SETTINGS"
        return 0
    fi

    # Need an existing PreToolUse:Bash block to append to.
    if ! jq -e '[.hooks.PreToolUse[]? | select(.matcher=="Bash")] | length > 0' "$SETTINGS" >/dev/null 2>&1; then
        print_warning "No PreToolUse:Bash block in $SETTINGS — skipping (unexpected layout)"
        return 0
    fi

    local TMP
    TMP="$(mktemp)"
    if jq '.hooks.PreToolUse = ([.hooks.PreToolUse[] |
            if .matcher=="Bash" and ((.hooks // []) | any(.command=="rtk hook claude") | not)
            then .hooks += [{"type":"command","command":"rtk hook claude"}]
            else . end])' "$SETTINGS" > "$TMP" 2>/dev/null && jq -e . "$TMP" >/dev/null 2>&1; then
        cp "$SETTINGS" "$SETTINGS.bak"
        mv "$TMP" "$SETTINGS"
        print_success "Appended 'rtk hook claude' as last Bash hook (backup: $SETTINGS.bak)"
    else
        rm -f "$TMP"
        print_warning "Failed to patch $SETTINGS with rtk hook — left unchanged"
    fi
}

# ============================================================================
# Verify Configuration
# ============================================================================

verify_config() {
    print_header "Verifying Configuration"

    local issues=0

    # Check symlinks
    echo "Checking symlinks..."

    local symlinks=(
        "$HOME/.zshrc:zsh/.zshrc"
        "$HOME/.zprofile:zsh/.zprofile"
        "$HOME/.config/nvim:nvim/.config/nvim"
        "$HOME/.config/tmux:tmux/.config/tmux"
        "$HOME/.config/starship:starship/.config/starship"
    )

    for link in "${symlinks[@]}"; do
        local target="${link%%:*}"
        local source="${link##*:}"

        if [[ -L "$target" ]]; then
            print_success "$target linked"
        elif [[ -e "$target" ]]; then
            print_warning "$target exists but is not a symlink"
            issues=$((issues + 1))
        else
            print_error "$target missing"
            issues=$((issues + 1))
        fi
    done

    # Check shell
    echo -e "\nChecking shell..."
    if [[ "$SHELL" == *"zsh"* ]]; then
        print_success "Default shell is zsh"
    else
        print_warning "Default shell is not zsh (current: $SHELL)"
        echo "  Run: chsh -s \$(which zsh)"
    fi

    # Check Neovim health
    echo -e "\nNeovim quick check..."
    if nvim --version &>/dev/null; then
        local nvim_version
        nvim_version=$(nvim --version | head -1)
        print_success "$nvim_version"
    else
        print_error "Neovim not working"
        issues=$((issues + 1))
    fi

    if [[ $issues -eq 0 ]]; then
        print_success "All checks passed!"
    else
        print_warning "$issues issues found"
    fi

    return $issues
}

# ============================================================================
# Post-Update Tasks
# ============================================================================

post_update() {
    print_header "Post-Update Tasks"

    # Reload shell config hint
    echo "To apply shell changes:"
    echo "  source ~/.zprofile && source ~/.zshrc"
    echo "  OR restart your terminal"

    # Reload services
    echo -e "\nTo reload services:"
    echo "  aerospace reload-config  # Window manager"
    echo "  sketchybar --reload      # Status bar"
    echo "  tmux source ~/.config/tmux/tmux.conf  # Tmux (if running)"

    # Neovim plugins
    echo -e "\nTo update Neovim plugins:"
    echo "  nvim +Lazy sync +qa"

    # Tmux plugins
    echo -e "\nTo install Tmux plugins:"
    echo "  Inside tmux: prefix + I"
}

# ============================================================================
# Main
# ============================================================================

main() {
    echo -e "${BLUE}"
    echo "  ╔═══════════════════════════════════════╗"
    echo "  ║       Dotfiles Setup Script           ║"
    echo "  ╚═══════════════════════════════════════╝"
    echo -e "${NC}"

    case "${1:-}" in
        --check)
            check_dependencies
            verify_config
            ;;
        --stow)
            stow_packages
            ;;
        --configure)
            configure_environment
            verify_config
            post_update
            ;;
        --all|"")
            check_dependencies
            stow_packages
            configure_environment
            verify_config
            post_update
            ;;
        --help|-h)
            echo "Usage: ./setup.sh [OPTION]"
            echo ""
            echo "Options:"
            echo "  --check      Check dependencies and verify config"
            echo "  --stow       Stow all packages"
            echo "  --configure  Configure environment for this machine"
            echo "  --all        Run all steps (default)"
            echo "  --help       Show this help"
            ;;
        *)
            echo "Unknown option: $1"
            echo "Run ./setup.sh --help for usage"
            exit 1
            ;;
    esac
}

main "$@"
