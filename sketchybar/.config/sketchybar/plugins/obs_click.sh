#!/usr/bin/env bash

# OBS item click router:
#   left-click           → open OBS (original behavior)
#   right / shift-click  → refresh status header + toggle the control popup
source "$CONFIG_DIR/colors.sh"

if [ "$BUTTON" = "right" ] || [ "$MODIFIER" = "shift" ]; then
    "$CONFIG_DIR/plugins/obs_action.sh" refresh
    sketchybar --set obs popup.drawing=toggle
else
    open -a OBS
fi
