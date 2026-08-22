#!/bin/bash

source "$CONFIG_DIR/colors.sh"

# Detect active network interface (WiFi or Ethernet)
INTERFACE=$(route -n get default 2>/dev/null | awk '/interface:/ {print $2}')
INTERFACE="${INTERFACE:-en0}"

# Single netstat call instead of two (optimized)
NETSTAT_OUTPUT=$(netstat -ib | grep -E "^$INTERFACE" | head -1)
BYTES_IN=$(echo "$NETSTAT_OUTPUT" | awk '{print $7}')
BYTES_OUT=$(echo "$NETSTAT_OUTPUT" | awk '{print $10}')

# Cache file for previous values. Kept under TMPDIR (per-user, private under
# launchd) rather than world-writable /tmp: the cached values are fed straight
# into $(( )) below, and bash arithmetic evaluates its operands recursively —
# a line like `a[$(...)]` planted in a fixed, predictable /tmp path by any other
# local account would execute as this user on the next 15s tick.
CACHE_FILE="${TMPDIR:-/tmp}/sketchybar_network_cache"

PREV_IF=""
if [ -f "$CACHE_FILE" ]; then
    read -r PREV_IF PREV_IN PREV_OUT < "$CACHE_FILE"

    # Only trust an all-digits pair recorded against the SAME interface.
    # netstat counters are per-interface, so a Wi-Fi -> Ethernet switch would
    # otherwise subtract two unrelated counters and draw a phantom GB/s spike;
    # the digit check keeps anything non-numeric out of the arithmetic above.
    case "$PREV_IN$PREV_OUT" in
        '' | *[!0-9]*) PREV_IF="" ;;
    esac
fi

if [ "$PREV_IF" = "$INTERFACE" ]; then
    # Calculate speed in bytes/second — divisor must match the item's
    # update_freq (15s in items/network.sh); /5 inflated speeds 3x
    DIFF_IN=$(( (BYTES_IN - PREV_IN) / 15 ))
    DIFF_OUT=$(( (BYTES_OUT - PREV_OUT) / 15 ))

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

# Save current values (single line, space-separated - faster read). Interface
# first, so the next tick can tell whether the counters are even comparable.
echo "$INTERFACE $BYTES_IN $BYTES_OUT" > "$CACHE_FILE"
