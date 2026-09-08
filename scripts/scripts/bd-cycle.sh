#!/usr/bin/env bash
# Select the next/previous preset as a manual choice, inside the controller lock.
set -u
[ -f "$HOME/.config/dotfiles/personal.env" ] && source "$HOME/.config/dotfiles/personal.env"
DOTFILES_DIR="${DOTFILES_DIR:-$HOME/dotfiles}"
BD_SOURCE=click exec "$DOTFILES_DIR/scripts/scripts/bd-apply.sh" cycle "${1:-next}"
