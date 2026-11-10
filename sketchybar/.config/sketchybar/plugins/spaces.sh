#!/usr/bin/env bash
# spaces — show only the workspaces in use: every workspace that holds a window,
# plus the focused one. One AeroSpace query and one sketchybar call per event,
# instead of a script per workspace item.
#
# Subscribed to: aerospace_workspace_change (fired by aerospace.toml
# exec-on-workspace-change, carries $FOCUSED_WORKSPACE) and front_app_switched.
# Neither fires when a window is MOVED to another workspace without following
# it, so the item also polls on a short update_freq.
#
# Fails open: if AeroSpace cannot be asked, every workspace is shown, because a
# bar with no workspaces looks like a broken bar.
source "$CONFIG_DIR/colors.sh"

FOCUSED="${FOCUSED_WORKSPACE:-}"
[[ -n "$FOCUSED" ]] || FOCUSED="$(aerospace list-workspaces --focused 2>/dev/null | head -1)"
if OCCUPIED="$(aerospace list-workspaces --monitor all --empty no 2>/dev/null)"; then
    KNOWN=true
else
    KNOWN=false
fi

args=()
while IFS= read -r item; do
    [[ -n "$item" ]] || continue
    id="${item#space.}"
    if [[ "$id" == "$FOCUSED" ]]; then
        args+=(--set "$item" drawing=on background.drawing=on icon.color=0xff1e1e2e)
    elif [[ "$KNOWN" == false ]] || grep -qx -- "$id" <<< "$OCCUPIED"; then
        args+=(--set "$item" drawing=on background.drawing=off icon.color="$WHITE")
    else
        args+=(--set "$item" drawing=off)
    fi
done < <(sketchybar --query bar 2>/dev/null | jq -r '.items[] | select(startswith("space."))')

(( ${#args[@]} )) && sketchybar "${args[@]}"
exit 0
