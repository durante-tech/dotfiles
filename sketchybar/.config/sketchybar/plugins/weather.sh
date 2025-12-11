#!/bin/bash

source "$CONFIG_DIR/colors.sh"

# Get weather from wttr.in (free, no API key needed)
# Format: %c = condition icon, %t = temperature
WEATHER=$(curl -s "wttr.in/Sao+Paulo?format=%c+%t" 2>/dev/null | head -1)

if [ -z "$WEATHER" ] || [[ "$WEATHER" == *"Unknown"* ]] || [[ "$WEATHER" == *"Sorry"* ]]; then
    sketchybar --set "$NAME" icon="󰖐" label="--" icon.color="$GREY"
else
    # Extract icon (first field) and temp (second field) - space separated
    ICON=$(echo "$WEATHER" | awk '{print $1}')
    TEMP=$(echo "$WEATHER" | awk '{print $2}')
    sketchybar --set "$NAME" icon="$ICON" label="$TEMP" icon.color="$BLUE"
fi
