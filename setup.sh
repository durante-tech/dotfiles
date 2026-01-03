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

    # List of packages to stow
    local packages=(
        aerospace
        atuin
        ghostty
        karabiner
        mpd
        nvim
        rmpc
        scripts
        sketchybar
        starship
        tmux
        w3m
        yazi
        zed
        zsh
    )

    # Ensure .config exists
    mkdir -p "$HOME/.config"

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
