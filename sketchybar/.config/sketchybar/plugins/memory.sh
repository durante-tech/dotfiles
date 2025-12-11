#!/bin/bash

source "$CONFIG_DIR/colors.sh"

# Get memory usage using vm_stat
PAGES_FREE=$(vm_stat | grep "Pages free" | awk '{print $3}' | tr -d '.')
PAGES_INACTIVE=$(vm_stat | grep "Pages inactive" | awk '{print $3}' | tr -d '.')
PAGES_SPECULATIVE=$(vm_stat | grep "Pages speculative" | awk '{print $3}' | tr -d '.')

# Page size is 16384 on Apple Silicon, 4096 on Intel
PAGE_SIZE=$(pagesize)

# Total physical memory in bytes
TOTAL_MEM=$(sysctl -n hw.memsize)

# Calculate used memory (total - free - inactive - speculative)
FREE_PAGES=$((PAGES_FREE + PAGES_INACTIVE + PAGES_SPECULATIVE))
FREE_MEM=$((FREE_PAGES * PAGE_SIZE))
USED_MEM=$((TOTAL_MEM - FREE_MEM))

# Convert to percentage
MEM_PERCENT=$((USED_MEM * 100 / TOTAL_MEM))

if [ "$MEM_PERCENT" -gt 80 ]; then
    COLOR="$RED"
elif [ "$MEM_PERCENT" -gt 60 ]; then
    COLOR="$YELLOW"
else
    COLOR="$GREEN"
fi

sketchybar --set "$NAME" icon="󰍛" label="${MEM_PERCENT}%" icon.color="$COLOR"
