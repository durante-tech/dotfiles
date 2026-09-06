#!/bin/bash
source "$CONFIG_DIR/colors.sh"

# Derive every page counter from one consistent snapshot.
SNAPSHOT=$(vm_stat 2>/dev/null)
PAGE_SIZE=$(pagesize 2>/dev/null)
TOTAL_MEM=$(sysctl -n hw.memsize 2>/dev/null)
MEM_PERCENT=$(printf '%s\n' "$SNAPSHOT" | awk -v page="$PAGE_SIZE" -v total="$TOTAL_MEM" '
  /^Pages (free|inactive|speculative):/ {
    value=$3; sub(/\.$/, "", value)
    if (value !~ /^[0-9]+$/) bad=1
    count++; free+=value
  }
  END {
    if (bad || count != 3 || page !~ /^[0-9]+$/ || total !~ /^[0-9]+$/ || page <= 0 || total <= 0 || free*page > total) exit 1
    printf "%d", (total-free*page)*100/total
  }')
if [[ -z "$MEM_PERCENT" ]]; then
    sketchybar --set "$NAME" icon="󰍛" label="?" icon.color="$GREY"
    exit 0
fi
if (( MEM_PERCENT > 80 )); then COLOR="$RED"
elif (( MEM_PERCENT > 60 )); then COLOR="$YELLOW"
else COLOR="$GREEN"; fi
sketchybar --set "$NAME" icon="󰍛" label="${MEM_PERCENT}%" icon.color="$COLOR"
