#!/usr/bin/env bash
# @raycast.schemaVersion 1
# @raycast.title Brightness · Manual hold
# @raycast.mode compact
# @raycast.packageName DOS · Screen
# @raycast.description Hold the current managed brightness until Auto is selected
[ -f "$HOME/.config/dotfiles/personal.env" ] && source "$HOME/.config/dotfiles/personal.env"
DOTFILES_DIR="${DOTFILES_DIR:-$HOME/dotfiles}"
BD_SOURCE=raycast exec "$DOTFILES_DIR/scripts/scripts/bd-apply.sh" manual
