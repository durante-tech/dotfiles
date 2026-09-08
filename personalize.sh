#!/usr/bin/env bash
# Validated preference editing: preview first, preserve unknown settings, no reloads.
set -eu
DOTFILES_DIR="${DOTFILES_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)}"
export DOTFILES_DIR
exec python3 -B "$DOTFILES_DIR/scripts/scripts/lib/preferences-cli.py" "$@"
