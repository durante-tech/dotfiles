#!/usr/bin/env bash
# @raycast.schemaVersion 1
# @raycast.title DOS Night
# @raycast.mode silent
# @raycast.icon 🌙
# @raycast.packageName DOS · Screen
# @raycast.description Select your Night preset and hold until Auto is selected

# Raycast launches with no shell env — pick up DOTFILES_DIR from personal.env.
[ -f "$HOME/.config/dotfiles/personal.env" ] && source "$HOME/.config/dotfiles/personal.env"

BD_SOURCE=raycast exec "${DOTFILES_DIR:-$HOME/dotfiles}/scripts/scripts/bd-apply.sh" night
