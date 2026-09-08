#!/usr/bin/env -S LC_ALL=C PYTHONUTF8=1 /bin/bash
# shellcheck shell=bash
# @raycast.schemaVersion 1
# @raycast.title Dotfiles · Set Preference
# @raycast.mode fullOutput
# @raycast.packageName Dotfiles
# @raycast.description Preview or apply one supported setting
# @raycast.argument1 {"type": "text", "placeholder": "Setting key"}
# @raycast.argument2 {"type": "text", "placeholder": "Value (JSON for numbers/arrays)"}
# @raycast.argument3 {"type": "dropdown", "placeholder": "Action", "data": [{"title": "Preview", "value": "preview"}, {"title": "Apply", "value": "apply"}]}
set -eu
entry="$HOME/scripts/dotfiles-preferences"
[ -x "$entry" ] || { echo 'Deploy the scripts package first: stow -t ~ scripts' >&2; exit 2; }
case "${3:-preview}" in
    preview) exec "$entry" --dry-run -- set "${1:?Setting key required}" "${2:?Value required}" ;;
    apply) exec "$entry" --apply -- set "${1:?Setting key required}" "${2:?Value required}" ;;
    *) echo 'Unknown action; choose Preview or Apply' >&2; exit 2 ;;
esac
