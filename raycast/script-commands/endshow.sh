#!/usr/bin/env bash
# @raycast.schemaVersion 1
# @raycast.title DOS End-Show
# @raycast.mode silent
# @raycast.icon 🏁
# @raycast.packageName DOS · Stream
# @raycast.description Wrap the stream — computes runtime + commits, sets Outro Overlay, switches scene
# @raycast.argument1 { "type": "text", "placeholder": "Custom shipped list (pipe-sep, blank = git log)", "optional": true }
# @raycast.argument2 { "type": "text", "placeholder": "Runtime HH:MM:SS (blank = auto)", "optional": true }

# Raycast launches with no shell env — pick up DOTFILES_DIR from personal.env.
[ -f "$HOME/.config/dotfiles/personal.env" ] && source "$HOME/.config/dotfiles/personal.env"
# Raycast has no PATH — resolve bun, falling back to the default install.
BUN="$(command -v bun || echo "$HOME/.bun/bin/bun")"

"$BUN" "${DOTFILES_DIR:-$HOME/dotfiles}/scripts/scripts/dos-stream.ts" endshow "" "$1" "$2"
