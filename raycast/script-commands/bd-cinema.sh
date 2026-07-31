#!/usr/bin/env bash
# @raycast.schemaVersion 1
# @raycast.title DOS Cinema
# @raycast.mode silent
# @raycast.icon 🎬
# @raycast.packageName DOS · Screen
# @raycast.description Switch displays to Cinema mode (XDR 150%, video viewing)

# Raycast launches with no shell env — pick up DOTFILES_DIR from personal.env.
[ -f "$HOME/.config/dotfiles/personal.env" ] && source "$HOME/.config/dotfiles/personal.env"

exec "${DOTFILES_DIR:-$HOME/dotfiles}/scripts/scripts/bd-apply.sh" cinema
