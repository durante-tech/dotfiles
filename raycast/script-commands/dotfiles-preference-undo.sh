#!/usr/bin/env -S LC_ALL=C PYTHONUTF8=1 /bin/bash
# shellcheck shell=bash
# @raycast.schemaVersion 1
# @raycast.title Dotfiles · Undo Preferences
# @raycast.mode fullOutput
# @raycast.packageName Dotfiles
# @raycast.description Preview or restore an unchanged personalization backup
# @raycast.argument1 {"type": "text", "placeholder": "Backup name (from Preferences)"}
# @raycast.argument2 {"type": "dropdown", "placeholder": "Action", "data": [{"title": "Preview", "value": "preview"}, {"title": "Apply", "value": "apply"}]}
set -eu
entry="$HOME/scripts/dotfiles-preferences"
[ -x "$entry" ] || { echo 'Deploy the scripts package first: stow -t ~ scripts' >&2; exit 2; }
case "${2:-preview}" in
    preview) exec "$entry" --dry-run -- undo "${1:?Backup name required}" ;;
    apply) exec "$entry" --apply -- undo "${1:?Backup name required}" ;;
    *) echo 'Unknown action; choose Preview or Apply' >&2; exit 2 ;;
esac
