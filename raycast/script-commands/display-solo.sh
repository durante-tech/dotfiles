#!/usr/bin/env -S LC_ALL=C PYTHONUTF8=1 /bin/bash
# shellcheck shell=bash
# @raycast.schemaVersion 1
# @raycast.title DOS Layout · Solo
# @raycast.mode silent
# @raycast.icon 🖥️
# @raycast.packageName DOS · Screen
# @raycast.description Single display (clamshell) at 2560x1440 HiDPI — UUID detected live

# Raycast launches with no shell env — pick up DOTFILES_DIR from personal.env.
[ -f "$HOME/.config/dotfiles/personal.env" ] && source "$HOME/.config/dotfiles/personal.env"
exec "${DOTFILES_DIR:-$HOME/dotfiles}/scripts/scripts/display-restore.sh" --solo
