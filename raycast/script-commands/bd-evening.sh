#!/usr/bin/env bash
# @raycast.schemaVersion 1
# @raycast.title DOS Evening
# @raycast.mode silent
# @raycast.icon 🌆
# @raycast.packageName DOS · Screen
# @raycast.description Switch displays to Evening mode (XDR 80%, warm shift)

# Raycast launches with no shell env — pick up DOTFILES_DIR from personal.env.
[ -f "$HOME/.config/dotfiles/personal.env" ] && source "$HOME/.config/dotfiles/personal.env"

exec "${DOTFILES_DIR:-$HOME/dotfiles}/scripts/scripts/bd-apply.sh" evening
