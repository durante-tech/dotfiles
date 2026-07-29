#!/usr/bin/env bash
# @raycast.schemaVersion 1
# @raycast.title DOS Day
# @raycast.mode silent
# @raycast.icon ☀️
# @raycast.packageName DOS · Screen
# @raycast.description Switch displays to Day mode (XDR 130%, daylight baseline)

# Raycast launches with no shell env — pick up DOTFILES_DIR from personal.env.
[ -f "$HOME/.config/dotfiles/personal.env" ] && source "$HOME/.config/dotfiles/personal.env"

exec "${DOTFILES_DIR:-$HOME/dotfiles}/scripts/scripts/bd-apply.sh" day
