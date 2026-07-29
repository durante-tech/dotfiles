#!/bin/bash

# Workspace list, DERIVED from AeroSpace rather than hardcoded.
#
# It used to be a literal array, which drifted the moment a workspace changed:
# workspace F was retired on 2026-07-28 and the bar kept drawing a dead `F`
# indicator that clicked through to nothing. Reading the live list means the bar
# can never disagree with the window manager again.
#
# PREFERRED_ORDER is presentation only — it fixes left-to-right order for the
# workspaces we know about. Any live workspace missing from it is appended, so a
# newly-added workspace shows up without editing this file; any entry in it that
# no longer exists is dropped. AeroSpace not running (first boot, crash) falls
# back to the literal list so the bar still renders.
PREFERRED_ORDER=("1" "2" "A" "B" "D" "M" "N" "T" "E")

SPACE_ICONS=()
LIVE_WORKSPACES=$(aerospace list-workspaces --all 2>/dev/null)
if [ -n "$LIVE_WORKSPACES" ]; then
    for w in "${PREFERRED_ORDER[@]}"; do
        grep -qx -- "$w" <<< "$LIVE_WORKSPACES" && SPACE_ICONS+=("$w")
    done
    while IFS= read -r w; do
        [ -z "$w" ] && continue
        printf '%s\n' "${PREFERRED_ORDER[@]}" | grep -qx -- "$w" || SPACE_ICONS+=("$w")
    done <<< "$LIVE_WORKSPACES"
else
    SPACE_ICONS=("${PREFERRED_ORDER[@]}")
fi

# Exported for the bracket in sketchybarrc, which otherwise carries its own
# second hardcoded copy of the same list — the exact drift this replaces.
SPACE_ITEMS=()
for id in "${SPACE_ICONS[@]}"; do SPACE_ITEMS+=("space.$id"); done
# background.color=0x44ffffff \

for i in "${!SPACE_ICONS[@]}"; do
    id="${SPACE_ICONS[i]}"
  space_item=(
    icon="$id"
    icon.padding_left=7
    icon.padding_right=7
    icon.y_offset=1
    label.drawing=off
    background.color=0xff939ab7
    background.corner_radius=3
    background.padding_left=5
    background.padding_right=5
    background.height=20
    icon.font="$FONT:Regular:14.0"
    drawing=on
    script="$CONFIG_DIR/plugins/aerospace.sh $id"
    click_script="aerospace workspace $id"
  )

  sketchybar --add item space.$id left \
             --set space.$id "${space_item[@]}" \
             --subscribe space.$id aerospace_workspace_change
done
