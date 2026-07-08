#!/usr/bin/env bash
# @raycast.schemaVersion 1
# @raycast.title DOS Layout · Native
# @raycast.mode silent
# @raycast.icon 🔲
# @raycast.packageName DOS · Screen
# @raycast.description Both panels 1x pixel-perfect native (UI renders tiny)

# Raycast launches with no shell env — pick up DOTFILES_DIR from personal.env.
[ -f "$HOME/.config/dotfiles/personal.env" ] && source "$HOME/.config/dotfiles/personal.env"
exec "${DOTFILES_DIR:-$HOME/dotfiles}/scripts/scripts/display-restore.sh" --native
