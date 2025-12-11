#!/bin/bash

source "$CONFIG_DIR/colors.sh"

# Get next calendar event using icalBuddy (if installed) or AppleScript
if command -v icalBuddy &> /dev/null; then
    EVENT=$(icalBuddy -n -nc -ea -li 1 -ps "/ - /" -po "title,datetime" eventsToday 2>/dev/null | head -1)
else
    # Fallback: just show date
    EVENT=$(date "+%a %d")
fi

if [ -z "$EVENT" ]; then
    EVENT=$(date "+%a %d")
    sketchybar --set "$NAME" icon="󰃭" label="$EVENT" icon.color="$BLUE"
else
    sketchybar --set "$NAME" icon="󰃭" label="$EVENT" icon.color="$GREEN"
fi
