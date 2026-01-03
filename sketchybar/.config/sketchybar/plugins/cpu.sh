#!/bin/bash

source "$CONFIG_DIR/colors.sh"

# Get CPU usage using ps and normalize by core count
# ps sums all cores (e.g., 200% on 12-core = ~17% actual usage)
NCPU=$(sysctl -n hw.ncpu)
CPU_RAW=$(ps -A -o %cpu | awk '{s+=$1} END {print int(s)}')

# Normalize: divide by core count to get average usage percentage
CPU=$((CPU_RAW / NCPU))

if [ -z "$CPU" ]; then
    CPU=0
fi

# Cap at 100% just in case
if [ "$CPU" -gt 100 ]; then
    CPU=100
fi

if [ "$CPU" -gt 80 ]; then
    COLOR="$RED"
elif [ "$CPU" -gt 50 ]; then
    COLOR="$YELLOW"
else
    COLOR="$GREEN"
fi

sketchybar --set "$NAME" icon="󰻠" label="${CPU}%" icon.color="$COLOR"
