#!/usr/bin/env bash
# @raycast.schemaVersion 1
# @raycast.title DOS Layout · HDR Toggle
# @raycast.mode silent
# @raycast.icon 🌈
# @raycast.packageName DOS · Screen
# @raycast.description Flip HDR on the external panel — on for graded video, off for SDR desktop

# Raycast launches with no shell env — pick up DOTFILES_DIR from personal.env.
[ -f "$HOME/.config/dotfiles/personal.env" ] && source "$HOME/.config/dotfiles/personal.env"
exec "${DOTFILES_DIR:-$HOME/dotfiles}/scripts/scripts/bd-hdr-toggle.sh" toggle
