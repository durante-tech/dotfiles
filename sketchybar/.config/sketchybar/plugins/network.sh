#!/bin/bash

source "$CONFIG_DIR/colors.sh"

# Get network interface (usually en0 for WiFi)
INTERFACE="en0"

# Single netstat call instead of two (optimized)
NETSTAT_OUTPUT=$(netstat -ib | grep -E "^$INTERFACE" | head -1)
BYTES_IN=$(echo "$NETSTAT_OUTPUT" | awk '{print $7}')
BYTES_OUT=$(echo "$NETSTAT_OUTPUT" | awk '{print $10}')

# Cache file for previous values
CACHE_FILE="/tmp/sketchybar_network_cache"

if [ -f "$CACHE_FILE" ]; then
    read -r PREV_IN PREV_OUT < "$CACHE_FILE"

    # Calculate speed (bytes per second, update every 5 seconds)
    DIFF_IN=$(( (BYTES_IN - PREV_IN) / 5 ))
    DIFF_OUT=$(( (BYTES_OUT - PREV_OUT) / 5 ))

    # Ensure non-negative values
    [ "$DIFF_IN" -lt 0 ] && DIFF_IN=0
    [ "$DIFF_OUT" -lt 0 ] && DIFF_OUT=0

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

# Save current values (single line, space-separated - faster read)
echo "$BYTES_IN $BYTES_OUT" > "$CACHE_FILE"
