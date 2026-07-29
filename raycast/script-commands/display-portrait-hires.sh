#!/usr/bin/env bash
# @raycast.schemaVersion 1
# @raycast.title DOS Layout · Portrait Hi-Res
# @raycast.mode silent
# @raycast.icon 📐
# @raycast.packageName DOS · Screen
# @raycast.description Canonical — Dell rotated 90 at 1440x2560 (2560px vertical)

# Raycast launches with no shell env — pick up DOTFILES_DIR from personal.env.
[ -f "$HOME/.config/dotfiles/personal.env" ] && source "$HOME/.config/dotfiles/personal.env"
exec "${DOTFILES_DIR:-$HOME/dotfiles}/scripts/scripts/display-restore.sh" --portrait-hires
