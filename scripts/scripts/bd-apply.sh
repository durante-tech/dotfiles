#!/usr/bin/env bash
# Canonical entry point: one persisted intent and lock for every managed write.
# The hardware implementation retains raw VCP dispatch for the Dell and
# readback/retry for software controls. See docs/DISPLAY.md for proof limits.
if [[ "${BASH_SOURCE[0]}" != "$0" ]]; then
    echo "bd-apply.sh is a command entry point; use status --json for saved state" >&2
    return 2
fi
set -u
[ -f "$HOME/.config/dotfiles/personal.env" ] && source "$HOME/.config/dotfiles/personal.env"
export DOTFILES_DIR DOTFILES_BD_CLI DOTFILES_DISPLAY_STATE_DIR DOTFILES_DISPLAY_LOCK_TIMEOUT
export DOTFILES_BD_DEV_SERIAL DOTFILES_BD_PORT_SERIAL DOTFILES_BD_HDR_BRIGHTNESS
export DOTFILES_BD_PORT_REF_CONTRAST DOTFILES_BD_PORT_REF_TEMP DOTFILES_BD_PORT_GAMMA
export DOTFILES_DISPLAY_PROFILES_FILE
export DOTFILES_BD_COMMAND_TIMEOUT
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
exec python3 -B "$SCRIPT_DIR/lib/display-control.py" "$@"
