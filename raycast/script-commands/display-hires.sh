#!/usr/bin/env bash
# @raycast.schemaVersion 1
# @raycast.title DOS Layout · Hi-Res
# @raycast.mode silent
# @raycast.icon 🔳
# @raycast.packageName DOS · Screen
# @raycast.description Samsung 2560x1440 HiDPI — ~78% more desktop, still retina-scaled

# Raycast launches with no shell env — pick up DOTFILES_DIR from personal.env.
[ -f "$HOME/.config/dotfiles/personal.env" ] && source "$HOME/.config/dotfiles/personal.env"
exec "${DOTFILES_DIR:-$HOME/dotfiles}/scripts/scripts/display-restore.sh" --hires
