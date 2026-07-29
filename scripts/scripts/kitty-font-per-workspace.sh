#!/usr/bin/env bash
# kitty-font-per-workspace — resize kitty font live based on focused AeroSpace workspace.
#
# Different displays have different effective resolutions; the same 16pt font that
# reads right on PORTRAIT (1440×2560, tall) feels oversized on Built-in (1728×1117,
# wide). This script flips font_size whenever the focused workspace changes.
#
# Workspace → display map (from aerospace.toml, re-verified 2026-07-28):
#   2, B, T, M    = PORTRAIT (Dell 28" 4K rotated 90 — logical 1440x2560)
#   1, A, D, E, F, N = Built-in Retina (MBP 16" — logical 1728x1117)
#
# NOTE the case below only sizes up for T and 2. B has been on PORTRAIT since the
# workspace pins were written, and M moved there 2026-07-28, so both currently get
# the built-in's 14pt while sitting on the portrait panel. That is a font-size
# preference, not a bug in the map — kitty normally lives on T — so it is left
# alone deliberately. Add B|M to the first branch if you start running kitty there.
#
# Reads $1 (focused workspace) or $AEROSPACE_FOCUSED_WORKSPACE env var.
# Requires kitty's allow_remote_control + listen_on socket settings.

WS="${1:-${AEROSPACE_FOCUSED_WORKSPACE:-}}"
[[ -z "$WS" ]] && exit 0

# Font size + window padding targets — edit to taste
case "$WS" in
    T|2)        SIZE=16; PAD=10 ;;
    *)          SIZE=14; PAD=4 ;;
esac

shopt -s nullglob
for sock in /tmp/kitty-*; do
    [[ -S "$sock" ]] || continue
    {
        kitty @ --to "unix:$sock" set-font-size "$SIZE"
        kitty @ --to "unix:$sock" set-spacing "padding=$PAD"
    } 2>/dev/null &
done
wait
exit 0
