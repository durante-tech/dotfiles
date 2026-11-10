#!/usr/bin/env bash
# wallpaper-cycle.sh — pick a random wallpaper from ~/Pictures/Wallpapers
#
# Usage: wallpaper-cycle.sh [directory]
# Default directory: ~/Pictures/Wallpapers
# Excludes files starting with "workspace-" (those are reserved for the
# AeroSpace per-workspace hook) and any .mp4 (wallpaper-cli is image-only).

set -eu

DIR="${1:-$HOME/Pictures/Wallpapers}"
[ -d "$DIR" ] || { echo "no such dir: $DIR" >&2; exit 1; }

# Collect candidates: jpg/jpeg/png/heic, exclude workspace-* and default.*
# Read line-wise: `mapfile` is bash 4+, and `env bash` here is macOS bash 3.2.
IMGS=()
while IFS= read -r img; do
  IMGS+=("$img")
done < <(find "$DIR" -maxdepth 1 -type f \
  \( -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" -o -iname "*.heic" \) \
  ! -iname "workspace-*" ! -iname "default.*" 2>/dev/null)

[ "${#IMGS[@]}" -gt 0 ] || { echo "no images in $DIR" >&2; exit 1; }

PICK="${IMGS[$((RANDOM % ${#IMGS[@]}))]}"
/opt/homebrew/bin/wallpaper set "$PICK"
echo "wallpaper → $(basename "$PICK")"
