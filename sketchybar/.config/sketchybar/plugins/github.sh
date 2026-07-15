#!/bin/bash

source "$CONFIG_DIR/colors.sh"

# Nerd Font GitHub mark (Font Awesome U+F09B — works in Hack Nerd Font).
ICON=""

# Bare-icon path: gh not installed or not authenticated → grey icon, no label.
if ! command -v gh &> /dev/null; then
    sketchybar --set "$NAME" icon="$ICON" label="" icon.color="$GREY" label.drawing=off
    exit 0
fi

# gh's built-in jq gives one clean number (the old grep -c '"id"' overcounted
# ~3x and an earlier `|| echo 0` variant produced multi-line values)
COUNT=$(gh api notifications -q 'length' 2>/dev/null)
COUNT=${COUNT:-0}

if [ "$COUNT" -gt 0 ]; then
    sketchybar --set "$NAME" icon="$ICON" label="$COUNT" icon.color="$ORANGE" label.drawing=on
else
    # Zero unread — show the icon only, no label (keeps the item compact
    # instead of rendering as a wide PURE_BLACK rectangle).
    sketchybar --set "$NAME" icon="$ICON" label="" icon.color="$GREY" label.drawing=off
fi
