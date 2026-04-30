#!/usr/bin/env bash
# wallpaper-workspace.sh — set wallpaper based on AeroSpace workspace name,
# scoped to the monitor that workspace is pinned to.
#
# Called from aerospace.toml exec-on-workspace-change. Reads the workspace
# name from $1 (or $AEROSPACE_FOCUSED_WORKSPACE), looks up which monitor
# that workspace lives on (AeroSpace assignment), and updates only that
# screen — so switching to workspace D doesn't disturb workspace T's
# wallpaper on the portrait monitor.
#
# Lookup chain (first hit wins):
#   1. ~/Pictures/Wallpapers/workspace-<NAME>.{jpg,png,jpeg,heic}
#   2. ~/Pictures/Wallpapers/default.{jpg,png}
#   3. (no-op — leave current wallpaper alone)
#
# Drop named files into ~/Pictures/Wallpapers/ to assign per-workspace
# imagery. No restart or stow re-run needed.
#
# Note: AeroSpace lists monitors 1-indexed; wallpaper-cli is 0-indexed.

set -u

WS="${1:-${AEROSPACE_FOCUSED_WORKSPACE:-}}"
[ -z "$WS" ] && exit 0

DIR="$HOME/Pictures/Wallpapers"
WALLPAPER="/opt/homebrew/bin/wallpaper"
AEROSPACE="/opt/homebrew/bin/aerospace"

# Resolve the image to set.
PICK=""
for ext in jpg png jpeg heic; do
  if [ -f "$DIR/workspace-$WS.$ext" ]; then
    PICK="$DIR/workspace-$WS.$ext"
    break
  fi
done
if [ -z "$PICK" ]; then
  for ext in jpg png; do
    if [ -f "$DIR/default.$ext" ]; then PICK="$DIR/default.$ext"; break; fi
  done
fi
[ -z "$PICK" ] && exit 0

# Resolve which screen index to set.
# AeroSpace returns "N | NAME"; subtract 1 for wallpaper-cli's 0-indexed --screen.
if [ -x "$AEROSPACE" ]; then
  AERO_IDX="$($AEROSPACE list-monitors --focused 2>/dev/null | awk -F'|' '{gsub(/ /,"",$1); print $1}')"
  if [[ "$AERO_IDX" =~ ^[0-9]+$ ]]; then
    SCREEN_IDX=$((AERO_IDX - 1))
    "$WALLPAPER" set "$PICK" --screen "$SCREEN_IDX" >/dev/null 2>&1 &
    exit 0
  fi
fi

# Fallback: set on all screens if monitor lookup failed.
"$WALLPAPER" set "$PICK" >/dev/null 2>&1 &
exit 0
