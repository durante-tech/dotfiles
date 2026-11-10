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

# Homebrew 7 dropped the type switches: `brew bundle install --no-cask` and
# `--no-formula` both exit "Invalid usage". Its replacement skip variables
# (HOMEBREW_BUNDLE_*_SKIP) take entry names, not a whole type, so a skipped type
# is removed from the Brewfile instead and the remainder is piped in on stdin.
dotfiles_bundle_args() {
    BUNDLE_SKIP_TYPES=()
    "$SKIP_BREW" && BUNDLE_SKIP_TYPES+=(brew)
    "$SKIP_CASKS" && BUNDLE_SKIP_TYPES+=(cask)
    if (( ${#BUNDLE_SKIP_TYPES[@]} )); then
        BUNDLE_ARGS=(bundle install --file=-)
    else
        BUNDLE_ARGS=(bundle install --file="$DOTFILES_DIR/Brewfile")
    fi
    return 0
}

# Print the Brewfile without the skipped entry types. Every entry in this
# Brewfile is a single line, which is what makes a line filter sufficient.
dotfiles_bundle_brewfile() {
    local types
    types="$(IFS='|'; printf '%s' "${BUNDLE_SKIP_TYPES[*]}")"
    sed -E "/^[[:space:]]*(${types})[[:space:]]/d" "$DOTFILES_DIR/Brewfile"
}

dotfiles_bundle_install() {
    dotfiles_bundle_args
    if (( ${#BUNDLE_SKIP_TYPES[@]} )); then
        dotfiles_bundle_brewfile | brew "${BUNDLE_ARGS[@]}"
    else
        brew "${BUNDLE_ARGS[@]}"
    fi
}
