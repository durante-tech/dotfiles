#!/bin/bash

# Spotify item click router:
#   left-click           → launch Spotify (original behavior)
#   right / shift-click  → refresh transport header + toggle the popup menu
source "$CONFIG_DIR/colors.sh"

if [ "$BUTTON" = "right" ] || [ "$MODIFIER" = "shift" ]; then
    "$CONFIG_DIR/plugins/spotify_action.sh" refresh
    sketchybar --set spotify popup.drawing=toggle
else
    open -a Spotify
fi
