#!/usr/bin/env bash
# @raycast.schemaVersion 1
# @raycast.title Phase · Observe
# @raycast.mode silent
# @raycast.icon 🔎
# @raycast.packageName DOS · Stream
# @raycast.description Set Terminal Frame phase rail to OBSERVE

# Raycast launches with no shell env — pick up DOTFILES_DIR from personal.env.
[ -f "$HOME/.config/dotfiles/personal.env" ] && source "$HOME/.config/dotfiles/personal.env"
# Raycast has no PATH — resolve bun, falling back to the default install.
BUN="$(command -v bun || echo "$HOME/.bun/bin/bun")"

"$BUN" "${DOTFILES_DIR:-$HOME/dotfiles}/scripts/scripts/dos-stream.ts" phase observe
