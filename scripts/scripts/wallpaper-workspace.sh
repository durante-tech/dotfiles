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

# Skip-if-same guard: prevents wallpaper-cli from re-painting (and macOS
# WindowServer from cross-fading) when the focused screen already shows
# this image. Many workspaces symlink to the same source — without this
# guard every switch causes a visible blink.
STATE_DIR="$HOME/.cache/wallpaper-workspace"
mkdir -p "$STATE_DIR"
NEW_REAL=$(realpath "$PICK" 2>/dev/null || /usr/bin/python3 -c 'import os,sys; print(os.path.realpath(sys.argv[1]))' "$PICK")

# Resolve which screen index to set.
# AeroSpace returns "N | NAME"; subtract 1 for wallpaper-cli's 0-indexed --screen.
if [ -x "$AEROSPACE" ]; then
  AERO_IDX="$($AEROSPACE list-monitors --focused 2>/dev/null | awk -F'|' '{gsub(/ /,"",$1); print $1}')"
  if [[ "$AERO_IDX" =~ ^[0-9]+$ ]]; then
    SCREEN_IDX=$((AERO_IDX - 1))
    STATE_FILE="$STATE_DIR/screen-$SCREEN_IDX"
    LAST=$([ -f "$STATE_FILE" ] && cat "$STATE_FILE" || echo "")
    if [ "$LAST" != "$NEW_REAL" ]; then
      "$WALLPAPER" set "$PICK" --screen "$SCREEN_IDX" >/dev/null 2>&1 &
      echo "$NEW_REAL" > "$STATE_FILE"
    fi
    exit 0
  fi
fi

# Fallback: set on all screens if monitor lookup failed.
STATE_FILE="$STATE_DIR/all"
LAST=$([ -f "$STATE_FILE" ] && cat "$STATE_FILE" || echo "")
if [ "$LAST" != "$NEW_REAL" ]; then
  "$WALLPAPER" set "$PICK" >/dev/null 2>&1 &
  echo "$NEW_REAL" > "$STATE_FILE"
fi
exit 0
