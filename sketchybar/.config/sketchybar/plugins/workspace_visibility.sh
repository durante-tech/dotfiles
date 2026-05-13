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
#
# Items with their own auto-hide logic (obs, mic, docker) are NOT in this table
# to avoid double-control. They remain always-eligible-to-draw; their plugins
# decide based on internal state (recording? muted? container running?).
declare -A VIS=(
    # ambient cluster — distractions during focus work
    [weather]="1 2 N F"            # ambient/thinking context only
    [calendar]="1 2 B M N F E"     # meeting-adjacent contexts
    [macupdater]="1 2 F"           # never urgent
    [clearvpn]="1 2 F"             # status only

    # system_health cluster — relevant only on dev / transitional workspaces
    [cpu]="1 2 D T F"
    [memory]="1 2 D T F"
    [network]="1 2 D T F"

    # context-sensitive dev tools
    [github]="1 2 B D T F E"       # dev + browser (PR review) + email
    [claude]="1 2 D T F"           # active dev context only
)

for item in "${!VIS[@]}"; do
    if [[ " ${VIS[$item]} " == *" $WS "* ]]; then
        sketchybar --set "$item" drawing=on
    else
        sketchybar --set "$item" drawing=off
    fi
done
