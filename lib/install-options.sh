#!/usr/bin/env bash
# Parse first, derive effects second: option order never grants provisioning.
dotfiles_options() {
    UPDATE_ONLY=false
    WITH_TOOLS=false
    SKIP_BREW=false
    SKIP_CASKS=false
    SKIP_MACOS_DEFAULTS=false
    FORCE_STOW=false
    VERBOSE=false
    DRY_RUN=false
    SHOW_HELP=false
    local arg
    for arg in "$@"; do
        case "$arg" in
            --update|-u) UPDATE_ONLY=true ;;
            --with-tools) WITH_TOOLS=true ;;
            --skip-brew) SKIP_BREW=true ;;
            --skip-casks) SKIP_CASKS=true ;;
            --skip-macos) SKIP_MACOS_DEFAULTS=true ;;
            --force-stow) FORCE_STOW=true ;;
            --verbose|-v) VERBOSE=true ;;
            --dry-run|-n) DRY_RUN=true; VERBOSE=true ;;
            --help|-h) SHOW_HELP=true ;;
            *) printf 'Unknown option: %s\n' "$arg" >&2; return 2 ;;
        esac
    done
    PROVISION_TOOLS=true
    if "$UPDATE_ONLY"; then
        SKIP_MACOS_DEFAULTS=true
        if ! "$WITH_TOOLS"; then
            PROVISION_TOOLS=false
            SKIP_BREW=true
            SKIP_CASKS=true
        fi
    fi
}

dotfiles_bundle_args() {
    BUNDLE_ARGS=(bundle install --file="$DOTFILES_DIR/Brewfile")
    "$SKIP_BREW" && BUNDLE_ARGS+=(--no-formula)
    "$SKIP_CASKS" && BUNDLE_ARGS+=(--no-cask)
    return 0
}
