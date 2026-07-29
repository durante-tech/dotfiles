#!/usr/bin/env bash
# @raycast.schemaVersion 1
# @raycast.title DOS Meeting
# @raycast.mode silent
# @raycast.icon 📞
# @raycast.packageName DOS · Screen
# @raycast.description Switch displays to Meeting mode (XDR 130%, video-call ready)

# Raycast launches with no shell env — pick up DOTFILES_DIR from personal.env.
[ -f "$HOME/.config/dotfiles/personal.env" ] && source "$HOME/.config/dotfiles/personal.env"

exec "${DOTFILES_DIR:-$HOME/dotfiles}/scripts/scripts/bd-apply.sh" meeting
