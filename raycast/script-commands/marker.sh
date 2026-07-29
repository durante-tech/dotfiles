#!/usr/bin/env bash
# @raycast.schemaVersion 1
# @raycast.title DOS Marker (with label)
# @raycast.mode silent
# @raycast.icon 🔖
# @raycast.packageName DOS · Stream
# @raycast.description Drop a labeled OBS recording chapter marker
# @raycast.argument1 { "type": "text", "placeholder": "Marker label (blank = prompt)", "optional": true }

# Raycast launches with no shell env — pick up DOTFILES_DIR from personal.env.
[ -f "$HOME/.config/dotfiles/personal.env" ] && source "$HOME/.config/dotfiles/personal.env"
# Raycast has no PATH — resolve bun, falling back to the default install.
BUN="$(command -v bun || echo "$HOME/.bun/bin/bun")"

"$BUN" "${DOTFILES_DIR:-$HOME/dotfiles}/scripts/scripts/dos-stream.ts" marker "$1"
