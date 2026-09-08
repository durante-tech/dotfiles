#!/usr/bin/env -S LC_ALL=C PYTHONUTF8=1 /bin/bash
# shellcheck shell=bash
# @raycast.schemaVersion 1
# @raycast.title Dotfiles · Save Profile
# @raycast.mode fullOutput
# @raycast.packageName Dotfiles
# @raycast.description Capture only the setting keys you name into a local profile
# @raycast.argument1 {"type": "text", "placeholder": "Profile name"}
# @raycast.argument2 {"type": "text", "placeholder": "Owned keys, separated by spaces"}
# @raycast.argument3 {"type": "dropdown", "placeholder": "Action", "data": [{"title": "Preview", "value": "preview"}, {"title": "Save new", "value": "save"}, {"title": "Replace existing", "value": "replace"}]}
set -eu
entry="$HOME/scripts/dotfiles-preferences"
[ -x "$entry" ] || { echo 'Deploy the scripts package first: stow -t ~ scripts' >&2; exit 2; }
read -r -a fields <<< "${2:?Owned setting keys required}"
case "${3:-preview}" in
    preview) exec "$entry" --dry-run -- profile save "${1:?Profile name required}" "${fields[@]}" ;;
    save) exec "$entry" --apply -- profile save "${1:?Profile name required}" "${fields[@]}" ;;
    replace) exec "$entry" --replace --apply -- profile save "${1:?Profile name required}" "${fields[@]}" ;;
    *) echo 'Unknown action; choose Preview, Save new, or Replace existing' >&2; exit 2 ;;
esac
