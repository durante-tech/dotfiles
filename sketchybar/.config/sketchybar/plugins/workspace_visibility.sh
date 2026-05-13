#!/usr/bin/env bash
# workspace_visibility — context-aware item visibility per AeroSpace workspace.
#
# Subscribed to: aerospace_workspace_change (fired by aerospace.toml exec-on-workspace-change)
# Reads:         $FOCUSED_WORKSPACE
#
# Single declarative table below — edit the VIS map to add/remove items or
# change which workspaces they appear in. No per-item plugin edits needed.
#
# Workspace map (from aerospace.toml):
#   1 = main           D = development (focus zone — strip clutter)
#   2 = secondary      F = finder (transitional, show everything)
#   B = browser        M = messaging
#   N = notes          T = terminal (mirror DEV)
#   E = email

WS="${FOCUSED_WORKSPACE:-}"
if [[ -z "$WS" ]]; then
    WS="$(aerospace list-workspaces --focused 2>/dev/null | head -1)"
fi
[[ -z "$WS" ]] && exit 0

# item_name → space-separated list of workspaces where item is VISIBLE.
# Workspaces not listed → drawing=off.
declare -A VIS=(
    [weather]="1 2 B N F E"
    [calendar]="1 2 B M N F E"
    [macupdater]="1 2 B M N F E"
    [clearvpn]="1 2 B M N F E"
)

for item in "${!VIS[@]}"; do
    if [[ " ${VIS[$item]} " == *" $WS "* ]]; then
        sketchybar --set "$item" drawing=on
    else
        sketchybar --set "$item" drawing=off
    fi
done
