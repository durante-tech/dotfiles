#!/usr/bin/env bash
# HDR is an explicit override of the saved base intent, under the same lock.
set -u
[ -f "$HOME/.config/dotfiles/personal.env" ] && source "$HOME/.config/dotfiles/personal.env"
DOTFILES_DIR="${DOTFILES_DIR:-$HOME/dotfiles}"
exec "$DOTFILES_DIR/scripts/scripts/bd-apply.sh" hdr "${1:-toggle}"
