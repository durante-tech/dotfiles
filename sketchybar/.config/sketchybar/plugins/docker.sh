#!/bin/bash

source "$CONFIG_DIR/colors.sh"

# Count running containers (simpler check)
RUNNING=$(/usr/local/bin/docker ps -q 2>/dev/null | wc -l | xargs)

if [ -z "$RUNNING" ]; then
    # Docker not running
    sketchybar --set "$NAME" icon="🐳" label="Off" icon.color="$RED"
elif [ "$RUNNING" -eq 0 ]; then
    # Docker running, no containers
    sketchybar --set "$NAME" icon="🐳" label="0" icon.color="$GREY"
else
    # Docker running with containers
    sketchybar --set "$NAME" icon="🐳" label="$RUNNING" icon.color="$BLUE"
fi
