#!/usr/bin/env -S LC_ALL=C PYTHONUTF8=1 /bin/bash
# shellcheck shell=bash
# @raycast.schemaVersion 1
# @raycast.title DOS Evening
# @raycast.mode silent
# @raycast.icon 🌆
# @raycast.packageName DOS · Screen
# @raycast.description Select your Evening preset and hold until Auto is selected

# Raycast launches with no shell env — pick up DOTFILES_DIR from personal.env.
[ -f "$HOME/.config/dotfiles/personal.env" ] && source "$HOME/.config/dotfiles/personal.env"

BD_SOURCE=raycast exec "${DOTFILES_DIR:-$HOME/dotfiles}/scripts/scripts/bd-apply.sh" evening
