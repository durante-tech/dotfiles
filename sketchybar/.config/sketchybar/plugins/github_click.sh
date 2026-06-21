#!/bin/bash

# GitHub item click router:
#   left-click           → open notifications (original behavior)
#   right / shift-click  → refresh unread count header + toggle quick-links popup
source "$CONFIG_DIR/colors.sh"

if [ "$BUTTON" != "right" ] && [ "$MODIFIER" != "shift" ]; then
    open https://github.com/notifications
    exit 0
fi

# Refresh the unread-count header (best-effort; gh may be missing/unauthed).
if command -v gh >/dev/null 2>&1; then
    COUNT=$(gh api notifications 2>/dev/null | grep -c '"id"' 2>/dev/null)
    COUNT=${COUNT:-0}
    if [ "$COUNT" -gt 0 ]; then
        sketchybar --set github.count label="$COUNT unread" label.color="$ORANGE"
    else
        sketchybar --set github.count label="No unread notifications" label.color="$GREY"
    fi
else
    sketchybar --set github.count label="gh CLI not available" label.color="$GREY"
fi

sketchybar --set github popup.drawing=toggle
