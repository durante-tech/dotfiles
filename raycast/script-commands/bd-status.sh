#!/usr/bin/env bash
# @raycast.schemaVersion 1
# @raycast.title Brightness · Status
# @raycast.mode fullOutput
# @raycast.packageName DOS · Screen
# @raycast.description Show ownership, requested brightness, and apply outcome
[ -f "$HOME/.config/dotfiles/personal.env" ] && source "$HOME/.config/dotfiles/personal.env"
DOTFILES_DIR="${DOTFILES_DIR:-$HOME/dotfiles}"
BD_SOURCE=raycast exec "$DOTFILES_DIR/scripts/scripts/bd-apply.sh" status
