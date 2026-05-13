#!/usr/bin/env bash
# kitty-font-per-workspace — resize kitty font live based on focused AeroSpace workspace.
#
# Different displays have different effective resolutions; the same 16pt font that
# reads right on PORTRAIT (1440×2560, tall) feels oversized on Built-in (1728×1117,
# wide). This script flips font_size whenever the focused workspace changes.
#
# Workspace → display map (from aerospace.toml):
#   T, 2          = PORTRAIT (Dell U2718Q rotated)
#   D, B, M, N, E, 1, F = Built-in Retina (MBP 14")
#
# Reads $1 (focused workspace) or $AEROSPACE_FOCUSED_WORKSPACE env var.
# Requires kitty's allow_remote_control + listen_on socket settings.

WS="${1:-${AEROSPACE_FOCUSED_WORKSPACE:-}}"
[[ -z "$WS" ]] && exit 0

# Font size targets — edit to taste
case "$WS" in
    T|2)        SIZE=16 ;;
    *)          SIZE=14 ;;
esac

shopt -s nullglob
for sock in /tmp/kitty-*; do
    [[ -S "$sock" ]] || continue
    kitty @ --to "unix:$sock" set-font-size "$SIZE" 2>/dev/null &
done
wait
exit 0
