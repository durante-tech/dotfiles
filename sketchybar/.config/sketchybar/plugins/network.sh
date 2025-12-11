#!/bin/bash

source "$CONFIG_DIR/colors.sh"

# Get network interface (usually en0 for WiFi)
INTERFACE="en0"

# Get current bytes
BYTES_IN=$(netstat -ib | grep -E "^$INTERFACE" | head -1 | awk '{print $7}')
BYTES_OUT=$(netstat -ib | grep -E "^$INTERFACE" | head -1 | awk '{print $10}')

# Cache file for previous values
CACHE_FILE="/tmp/sketchybar_network_cache"

if [ -f "$CACHE_FILE" ]; then
    PREV_IN=$(cat "$CACHE_FILE" | head -1)
    PREV_OUT=$(cat "$CACHE_FILE" | tail -1)

    # Calculate speed (bytes per second, update every 5 seconds)
    DIFF_IN=$(( (BYTES_IN - PREV_IN) / 5 ))
    DIFF_OUT=$(( (BYTES_OUT - PREV_OUT) / 5 ))

    # Convert to human readable
    if [ "$DIFF_IN" -gt 1048576 ]; then
        IN_LABEL="$(( DIFF_IN / 1048576 ))M"
    elif [ "$DIFF_IN" -gt 1024 ]; then
        IN_LABEL="$(( DIFF_IN / 1024 ))K"
    else
        IN_LABEL="${DIFF_IN}B"
    fi

    if [ "$DIFF_OUT" -gt 1048576 ]; then
        OUT_LABEL="$(( DIFF_OUT / 1048576 ))M"
    elif [ "$DIFF_OUT" -gt 1024 ]; then
        OUT_LABEL="$(( DIFF_OUT / 1024 ))K"
    else
        OUT_LABEL="${DIFF_OUT}B"
    fi

    sketchybar --set "$NAME" icon="󰛳" label="↓${IN_LABEL} ↑${OUT_LABEL}" icon.color="$BLUE"
else
    sketchybar --set "$NAME" icon="󰛳" label="..." icon.color="$GREY"
fi

# Save current values
echo "$BYTES_IN" > "$CACHE_FILE"
echo "$BYTES_OUT" >> "$CACHE_FILE"
