#!/bin/bash

source "$CONFIG_DIR/colors.sh"

# Get CPU usage
CPU=$(top -l 1 | grep -E "^CPU" | awk '{print int($3)}')

if [ -z "$CPU" ]; then
    CPU=0
fi

if [ "$CPU" -gt 80 ]; then
    COLOR="$RED"
elif [ "$CPU" -gt 50 ]; then
    COLOR="$YELLOW"
else
    COLOR="$GREEN"
fi

sketchybar --set "$NAME" icon="󰻠" label="${CPU}%" icon.color="$COLOR"
