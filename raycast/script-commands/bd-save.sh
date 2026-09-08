#!/usr/bin/env bash
# @raycast.schemaVersion 1
# @raycast.title Brightness · Save preset
# @raycast.mode compact
# @raycast.packageName DOS · Screen
# @raycast.description Save current successfully managed values as a personal preset
# @raycast.argument1 {"type":"text","placeholder":"Preset name, e.g. night"}
[ -f "$HOME/.config/dotfiles/personal.env" ] && source "$HOME/.config/dotfiles/personal.env"
DOTFILES_DIR="${DOTFILES_DIR:-$HOME/dotfiles}"
BD_SOURCE=raycast exec "$DOTFILES_DIR/scripts/scripts/bd-apply.sh" save-preset "${1:-}"
