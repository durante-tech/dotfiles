#!/bin/bash

source "$CONFIG_DIR/colors.sh"

# Nerd Font GitHub mark (Font Awesome U+F09B — works in Hack Nerd Font).
ICON=""

# Bare-icon path: gh not installed or not authenticated → grey icon, no label.
if ! command -v gh &> /dev/null; then
    sketchybar --set "$NAME" icon="$ICON" label="" icon.color="$GREY" label.drawing=off
    exit 0
fi

# `grep -c '"id"'` exits with status 1 (and output "0") when there are no
# matches. The prior `|| echo "0"` then appended a second "0", producing a
# multi-line value that broke `[ "$COUNT" -eq 0 ]` with "integer expression
# expected". Capture cleanly and default to 0.
COUNT=$(gh api notifications 2>/dev/null | grep -c '"id"' 2>/dev/null)
COUNT=${COUNT:-0}

if [ "$COUNT" -gt 0 ]; then
    sketchybar --set "$NAME" icon="$ICON" label="$COUNT" icon.color="$ORANGE" label.drawing=on
else
    # Zero unread — show the icon only, no label (keeps the item compact
    # instead of rendering as a wide PURE_BLACK rectangle).
    sketchybar --set "$NAME" icon="$ICON" label="" icon.color="$GREY" label.drawing=off
fi
