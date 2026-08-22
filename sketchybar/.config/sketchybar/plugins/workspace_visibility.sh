#!/usr/bin/env bash
# workspace_visibility — context-aware item visibility per AeroSpace workspace.
#
# Subscribed to: aerospace_workspace_change (fired by aerospace.toml exec-on-workspace-change)
# Reads:         $FOCUSED_WORKSPACE
#
# Single declarative table below — edit the VIS map to add/remove items or
# change which workspaces they appear in. No per-item plugin edits needed.
#
# Workspace map — must match persistent-workspaces in
# aerospace/templates/aerospace.toml.template. Workspace F was retired
# 2026-07-28 (items/space.sh now derives its list from the live AeroSpace
# workspaces for exactly that reason); the F entries that used to sit in the
# table below were dead weight $WS could never match.
#   1 = main           D = development (focus zone — strip clutter)
#   2 = secondary      M = messaging
#   A = AI             N = notes
#   B = browser        T = terminal (mirror DEV)
#   E = email

WS="${FOCUSED_WORKSPACE:-}"
if [[ -z "$WS" ]]; then
    WS="$(aerospace list-workspaces --focused 2>/dev/null | head -1)"
fi
[[ -z "$WS" ]] && exit 0

# item_name → space-separated list of workspaces where item is VISIBLE.
# Workspaces not listed → drawing=off.
#
# Items NOT in this table stay always-eligible-to-draw. Two of them genuinely
# self-hide, so listing them here would double-control them: obs
# (plugins/obs.sh sets drawing=off unless recording) and spotify
# (plugins/spotify.sh sets drawing=off when nothing is playing).
#
# mic and docker do NOT self-hide — neither plugin ever touches `drawing`, they
# only set icon/label/colour — so both stay visible on every workspace,
# including the D/T focus zones this table exists to declutter (docker parks a
# grey "Off" box there whenever Docker isn't running). Add rows for them above
# if that should change.
declare -A VIS=(
    # ambient cluster — distractions during focus work
    [weather]="1 2 N"              # ambient/thinking context only
    [calendar]="1 2 B M N E"       # meeting-adjacent contexts
    [macupdater]="1 2"             # never urgent
    [clearvpn]="1 2"               # status only

    # system_health cluster — relevant only on dev / transitional workspaces
    [cpu]="1 2 A D T"
    [memory]="1 2 A D T"
    [network]="1 2 A D T"

    # context-sensitive dev tools
    [github]="1 2 A B D T E"       # dev + AI + browser (PR review) + email
    [voice_server]="D T"           # DOS voice — only on development + terminal
)

for item in "${!VIS[@]}"; do
    if [[ " ${VIS[$item]} " == *" $WS "* ]]; then
        sketchybar --set "$item" drawing=on
    else
        sketchybar --set "$item" drawing=off
    fi
done
