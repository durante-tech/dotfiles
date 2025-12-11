#!/bin/bash

source "$CONFIG_DIR/colors.sh"

# GitHub notifications (requires gh CLI to be authenticated)
if ! command -v gh &> /dev/null; then
    sketchybar --set "$NAME" icon="" label="?" icon.color="$GREY"
    exit 0
fi

COUNT=$(gh api notifications 2>/dev/null | grep -c '"id"' || echo "0")

if [ "$COUNT" -eq 0 ]; then
    sketchybar --set "$NAME" icon="" label="0" icon.color="$GREY"
elif [ "$COUNT" -gt 0 ]; then
    sketchybar --set "$NAME" icon="" label="$COUNT" icon.color="$ORANGE"
fi
