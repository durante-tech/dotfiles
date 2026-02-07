#!/bin/bash

source "$CONFIG_DIR/colors.sh"

LOG_FILE="$HOME/Library/Application Support/MacUpdater/MacUpdater.log"

# Check if MacUpdater is running
if ! pgrep -f "MacUpdater" > /dev/null 2>&1; then
    sketchybar --set "$NAME" icon="󰚰" label="Off" icon.color="$GREY"
    exit 0
fi

# Parse the log file for the last scan result
if [ -f "$LOG_FILE" ]; then
    # Get the last "Scan Finished" line to find update count
    LAST_SCAN=$(grep "Scan Finished" "$LOG_FILE" | tail -1)

    if [ -n "$LAST_SCAN" ]; then
        # Extract the number of updates found
        # Format: "has found X new update(s)"
        UPDATES=$(echo "$LAST_SCAN" | grep -oE "found [0-9]+ new" | grep -oE "[0-9]+")

        if [ -z "$UPDATES" ]; then
            UPDATES=0
        fi

        if [ "$UPDATES" -eq 0 ]; then
            sketchybar --set "$NAME" icon="󰚰" label="✓" icon.color="$GREEN"
        elif [ "$UPDATES" -eq 1 ]; then
            sketchybar --set "$NAME" icon="󰚰" label="1" icon.color="$YELLOW"
        else
            sketchybar --set "$NAME" icon="󰚰" label="${UPDATES}" icon.color="$ORANGE"
        fi
    else
        sketchybar --set "$NAME" icon="󰚰" label="..." icon.color="$GREY"
    fi
else
    sketchybar --set "$NAME" icon="󰚰" label="No log" icon.color="$GREY"
fi
