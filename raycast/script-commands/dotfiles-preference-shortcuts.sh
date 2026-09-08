#!/usr/bin/env -S LC_ALL=C PYTHONUTF8=1 /bin/bash
# shellcheck shell=bash
# @raycast.schemaVersion 1
# @raycast.title Dotfiles · Personal Shortcuts
# @raycast.mode fullOutput
# @raycast.packageName Dotfiles
# @raycast.description Read shortcuts generated from selected settings and source bindings
set -eu
entry="$HOME/scripts/dotfiles-preferences"
[ -x "$entry" ] || { echo 'Deploy the scripts package first: stow -t ~ scripts' >&2; exit 2; }
exec "$entry" shortcuts
