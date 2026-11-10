#!/bin/bash

source "$CONFIG_DIR/colors.sh"

# Detect active network interface (WiFi or Ethernet)
INTERFACE=$(route -n get default 2>/dev/null | awk '/interface:/ {print $2}')
INTERFACE="${INTERFACE:-en0}"

# Single netstat call instead of two (optimized)
# -n: without it netstat resolves every address and took 5 s of wall clock per
# run here; -I asks for the one interface instead of grepping all of them.
NETSTAT_OUTPUT=$(netstat -ibn -I "$INTERFACE" 2>/dev/null | sed -n 2p)
# Count from the END of the row. A link row normally has an Address column
# (11 fields) but a utun* default route — a full-tunnel VPN — has none (10), so
# fixed $7/$10 read Opkts and Coll there and the item showed packet counts.
# Ibytes is always 4 fields before the last (Coll), Obytes always 1 before it.
BYTES_IN=$(echo "$NETSTAT_OUTPUT" | awk '{print $(NF-4)}')
BYTES_OUT=$(echo "$NETSTAT_OUTPUT" | awk '{print $(NF-1)}')

# Cache file for previous values. Kept under TMPDIR (per-user, private under
# launchd) rather than world-writable /tmp: the cached values are fed straight
# into $(( )) below, and bash arithmetic evaluates its operands recursively —
# a line like `a[$(...)]` planted in a fixed, predictable /tmp path by any other
# local account would execute as this user on the next 15s tick.
CACHE_FILE="${TMPDIR:-/tmp}/sketchybar_network_cache"

PREV_IF=""
if [ -f "$CACHE_FILE" ]; then
    read -r PREV_IF PREV_IN PREV_OUT PREV_AT < "$CACHE_FILE"

    # Only trust an all-digits pair recorded against the SAME interface.
    # netstat counters are per-interface, so a Wi-Fi -> Ethernet switch would
    # otherwise subtract two unrelated counters and draw a phantom GB/s spike;
    # the digit check keeps anything non-numeric out of the arithmetic above.
    case "$PREV_IN$PREV_OUT$PREV_AT" in
        '' | *[!0-9]*) PREV_IF="" ;;
    esac
fi

# Rate over the time that actually passed, not an assumed tick: a reload or a
# changed update_freq otherwise misreports the first sample. A cache without a
# timestamp (written by an older version) counts as no previous sample.
NOW=$(date +%s)
ELAPSED=$(( NOW - ${PREV_AT:-NOW} ))
if [ "$PREV_IF" = "$INTERFACE" ] && [ "$ELAPSED" -gt 0 ]; then
    DIFF_IN=$(( (BYTES_IN - PREV_IN) / ELAPSED ))
    DIFF_OUT=$(( (BYTES_OUT - PREV_OUT) / ELAPSED ))

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

    # Quiet by default: the item is drawn only while it has something to say.
    if [ "$DIFF_IN" -gt 1048576 ] || [ "$DIFF_OUT" -gt 1048576 ]; then DRAWING=on; else DRAWING=off; fi
    sketchybar --set "$NAME" icon="󰛳" label="↓${IN_LABEL} ↑${OUT_LABEL}" icon.color="$BLUE" drawing="$DRAWING"
else
    sketchybar --set "$NAME" icon="󰛳" label="..." icon.color="$GREY" drawing=off
fi

# Save current values (single line, space-separated - faster read). Interface
# first, so the next tick can tell whether the counters are even comparable.
echo "$INTERFACE $BYTES_IN $BYTES_OUT $NOW" > "$CACHE_FILE"
