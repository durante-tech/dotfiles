#!/usr/bin/env bash
# @raycast.schemaVersion 1
# @raycast.title DOS Layout · Portrait
# @raycast.mode silent
# @raycast.icon 📐
# @raycast.packageName DOS · Screen
# @raycast.description Rotate Samsung to true-2x 1080x1920 portrait

# Raycast launches with no shell env — pick up DOTFILES_DIR from personal.env.
[ -f "$HOME/.config/dotfiles/personal.env" ] && source "$HOME/.config/dotfiles/personal.env"
exec "${DOTFILES_DIR:-$HOME/dotfiles}/scripts/scripts/display-restore.sh" --portrait
