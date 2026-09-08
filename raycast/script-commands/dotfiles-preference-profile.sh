#!/usr/bin/env -S LC_ALL=C PYTHONUTF8=1 /bin/bash
# shellcheck shell=bash
# @raycast.schemaVersion 1
# @raycast.title Dotfiles · Profile
# @raycast.mode fullOutput
# @raycast.packageName Dotfiles
# @raycast.description List profiles or preview/apply an explicitly saved profile
# @raycast.argument1 {"type": "text", "placeholder": "Profile name (blank lists profiles)", "optional": true}
# @raycast.argument2 {"type": "dropdown", "placeholder": "Action", "data": [{"title": "Preview", "value": "preview"}, {"title": "Apply", "value": "apply"}], "optional": true}
set -eu
entry="$HOME/scripts/dotfiles-preferences"
[ -x "$entry" ] || { echo 'Deploy the scripts package first: stow -t ~ scripts' >&2; exit 2; }
if [ -z "${1:-}" ]; then exec "$entry" profile list; fi
case "${2:-preview}" in
    preview) exec "$entry" --dry-run -- profile use "$1" ;;
    apply) exec "$entry" --apply -- profile use "$1" ;;
    *) echo 'Unknown action; choose Preview or Apply' >&2; exit 2 ;;
esac
