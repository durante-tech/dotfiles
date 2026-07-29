#!/usr/bin/env bash
# kitty-font-per-workspace — resize kitty font live based on focused AeroSpace workspace.
#
# Different displays have different effective resolutions; the same 16pt font that
# reads right on PORTRAIT (1440×2560, tall) feels oversized on Built-in (1728×1117,
# wide). This script flips font_size whenever the focused workspace changes.
#
# ORPHANED as of 2026-07-28 — nothing invokes this script. Verified: no caller in
# the repo, in ~/Library/LaunchAgents, or in ~/.config, and aerospace.toml's
# exec-on-workspace-change fires only `sketchybar --trigger` and
# wallpaper-workspace.sh. It runs only if you call it by hand.
#
# To make it live, append to exec-on-workspace-change in
# aerospace/templates/aerospace.toml.template:
#   ~/scripts/kitty-font-per-workspace.sh "$AEROSPACE_FOCUSED_WORKSPACE" &
# (then re-render + reload). Note the measured cost of that hook — each command
# added there is ~15-20ms on every workspace switch; see memory
# aerospace-workspace-hook-latency.
#
# Workspace → display map (from aerospace.toml, re-verified 2026-07-28):
#   2, B, T, M       = PORTRAIT (Dell 28" 4K rotated 90 — logical 1440x2560)
#   1, A, D, E, F, N = Built-in Retina (MBP 16" — logical 1728x1117)
#
# The case below sizes up only for T and 2. B has been on PORTRAIT since the pins
# were written and M moved there 2026-07-28, so IF this script is ever wired up,
# both would get the built-in's 14pt while sitting on the portrait panel. Add B|M
# to the first branch at that point — it is a font preference, not a map bug, and
# is left alone rather than guessed at.
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
