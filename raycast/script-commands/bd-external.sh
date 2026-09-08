#!/usr/bin/env -S LC_ALL=C PYTHONUTF8=1 /bin/bash
# shellcheck shell=bash
# @raycast.schemaVersion 1
# @raycast.title Brightness · External level
# @raycast.mode compact
# @raycast.packageName DOS · Screen
# @raycast.description Set external luminance and hold
# @raycast.argument1 {"type":"text","placeholder":"Percent (0–100)"}
[ -f "$HOME/.config/dotfiles/personal.env" ] && source "$HOME/.config/dotfiles/personal.env"
DOTFILES_DIR="${DOTFILES_DIR:-$HOME/dotfiles}"
BD_SOURCE=raycast exec "$DOTFILES_DIR/scripts/scripts/bd-apply.sh" set port "${1:-}"
