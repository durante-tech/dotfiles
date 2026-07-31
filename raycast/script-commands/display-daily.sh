#!/usr/bin/env bash
# @raycast.schemaVersion 1
# @raycast.title DOS Layout · Daily
# @raycast.mode silent
# @raycast.icon 🖥️
# @raycast.packageName DOS · Screen
# @raycast.description Landscape daily — built-in 1728x1117 + Dell 1920x1080 true 2x

# Raycast launches with no shell env — pick up DOTFILES_DIR from personal.env.
[ -f "$HOME/.config/dotfiles/personal.env" ] && source "$HOME/.config/dotfiles/personal.env"
exec "${DOTFILES_DIR:-$HOME/dotfiles}/scripts/scripts/display-restore.sh" --daily
