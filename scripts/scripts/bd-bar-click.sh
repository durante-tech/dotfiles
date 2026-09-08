#!/usr/bin/env bash
# Left/right cycle presets; middle click explicitly resumes ambient control.
set -u
[ -f "$HOME/.config/dotfiles/personal.env" ] && source "$HOME/.config/dotfiles/personal.env"
DOTFILES_DIR="${DOTFILES_DIR:-$HOME/dotfiles}"
export BD_SOURCE=click
case "${BUTTON:-left}" in
    right) exec "$DOTFILES_DIR/scripts/scripts/bd-apply.sh" cycle prev ;;
    middle) exec "$DOTFILES_DIR/scripts/scripts/bd-apply.sh" auto ;;
    *) exec "$DOTFILES_DIR/scripts/scripts/bd-apply.sh" cycle next ;;
esac
