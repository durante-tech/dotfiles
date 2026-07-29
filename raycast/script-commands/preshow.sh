#!/usr/bin/env bash
# @raycast.schemaVersion 1
# @raycast.title DOS Pre-Show
# @raycast.mode silent
# @raycast.icon ⚡
# @raycast.packageName DOS · Stream
# @raycast.description Start the 5-min pre-show — sets Intro Overlay + switches scene
# @raycast.argument1 { "type": "text", "placeholder": "Session # (blank = auto-increment)", "optional": true }
# @raycast.argument2 { "type": "text", "placeholder": "Agenda (pipe-separated)", "optional": true }

# Raycast launches with no shell env — pick up DOTFILES_DIR from personal.env.
[ -f "$HOME/.config/dotfiles/personal.env" ] && source "$HOME/.config/dotfiles/personal.env"
# Raycast has no PATH — resolve bun, falling back to the default install.
BUN="$(command -v bun || echo "$HOME/.bun/bin/bun")"

"$BUN" "${DOTFILES_DIR:-$HOME/dotfiles}/scripts/scripts/dos-stream.ts" preshow "$1" "$2"
"$BUN" "${DOTFILES_DIR:-$HOME/dotfiles}/scripts/scripts/dos-stream.ts" session-start
