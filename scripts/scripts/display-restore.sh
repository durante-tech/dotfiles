#!/usr/bin/env bash
# Layout writes share the display-controller lock; dry-run remains read-only.
set -u
[ -f "$HOME/.config/dotfiles/personal.env" ] && source "$HOME/.config/dotfiles/personal.env"
DOTFILES_DIR="${DOTFILES_DIR:-$HOME/dotfiles}"
exec "$DOTFILES_DIR/scripts/scripts/bd-apply.sh" layout "$@"
