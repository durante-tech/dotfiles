#!/usr/bin/env bash
# @raycast.schemaVersion 1
# @raycast.title Brightness · Increase
# @raycast.mode compact
# @raycast.packageName DOS · Screen
# @raycast.description Increase both managed displays by 10 percentage points and hold
[ -f "$HOME/.config/dotfiles/personal.env" ] && source "$HOME/.config/dotfiles/personal.env"
DOTFILES_DIR="${DOTFILES_DIR:-$HOME/dotfiles}"
BD_SOURCE=raycast exec "$DOTFILES_DIR/scripts/scripts/bd-apply.sh" up
