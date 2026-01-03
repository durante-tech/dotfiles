#!/bin/bash

source "$CONFIG_DIR/colors.sh"

DOCKER="/usr/local/bin/docker"

# Check if Docker is running (with timeout to prevent blocking)
if ! timeout 2s $DOCKER info >/dev/null 2>&1; then
    sketchybar --set "$NAME" icon="󰡨" label="Off" icon.color="$GREY"
    exit 0
fi

# Single docker command to get all info we need (optimized from 4 commands to 1)
# Format: ID|Status|MemPerc
CONTAINER_DATA=$(timeout 3s $DOCKER ps --format "{{.ID}}|{{.Status}}" 2>/dev/null)

if [ -z "$CONTAINER_DATA" ]; then
    sketchybar --set "$NAME" icon="󰡨" label="0" icon.color="$GREY"
    exit 0
fi

RUNNING=$(echo "$CONTAINER_DATA" | wc -l | xargs)

if [ "$RUNNING" -eq 0 ]; then
    sketchybar --set "$NAME" icon="󰡨" label="0" icon.color="$GREY"
    exit 0
fi

# Count healthy vs unhealthy from cached data
HEALTHY=$(echo "$CONTAINER_DATA" | grep -c "(healthy)") || HEALTHY=0
UNHEALTHY=$(echo "$CONTAINER_DATA" | grep -c "(unhealthy)") || UNHEALTHY=0

# Get memory only if containers are running (with timeout)
MEM_TOTAL=$(timeout 2s $DOCKER stats --no-stream --format "{{.MemPerc}}" 2>/dev/null | awk '{gsub(/%/,""); sum += $1} END {printf "%.0f", sum}')

# Build label
if [ "$UNHEALTHY" -gt 0 ]; then
    LABEL="$RUNNING (${UNHEALTHY}!)"
    ICON_COLOR="$ORANGE"
elif [ "$HEALTHY" -gt 0 ]; then
    LABEL="$RUNNING"
    ICON_COLOR="$GREEN"
else
    LABEL="$RUNNING"
    ICON_COLOR="$BLUE"
fi

# Add memory if significant (>5%)
if [ -n "$MEM_TOTAL" ] && [ "$MEM_TOTAL" -gt 5 ]; then
    LABEL="${LABEL} ${MEM_TOTAL}%"
fi

sketchybar --set "$NAME" icon="󰡨" label="$LABEL" icon.color="$ICON_COLOR"
