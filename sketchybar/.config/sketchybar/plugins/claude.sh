#!/usr/bin/env bash
# Claude Code plan-usage indicator for SketchyBar.
#
# Aggregates *all* active sessions (across every project) into 5-hour billing
# blocks via ccusage. Shows current block's spend + remaining time. Solves the
# "multiple parallel sessions" problem where per-session context % is meaningless.
#
# Architecture: ccusage takes ~8s to enumerate JSONLs across all projects, so
# we cache its output to /tmp/ccusage-cache.json with a 60s TTL. SketchyBar
# polls the cache (instant); the plugin refreshes the cache in the background
# when it's stale, never blocking the bar.
#
# Click handler: claude_click.sh shows projection in a macOS notification.

source "$CONFIG_DIR/colors.sh"

CACHE="/tmp/ccusage-cache.json"
CCUSAGE="/Users/lgertel/.bun/bin/ccusage"

# ── Refresh cache in background if missing or > 60s old ─────────────────────
NEEDS_REFRESH=0
if [ ! -f "$CACHE" ] || [ ! -s "$CACHE" ]; then
  NEEDS_REFRESH=1
elif [ -n "$(find "$CACHE" -mmin +1 2>/dev/null)" ]; then
  NEEDS_REFRESH=1
fi

if [ "$NEEDS_REFRESH" -eq 1 ] && [ -x "$CCUSAGE" ]; then
  ( "$CCUSAGE" blocks --active --json > "$CACHE.tmp" 2>/dev/null \
    && mv "$CACHE.tmp" "$CACHE" ) &
fi

# ── If cache still missing (first ever run), show loading state ─────────────
if [ ! -f "$CACHE" ] || [ ! -s "$CACHE" ]; then
  sketchybar --set "$NAME" \
    icon="󰚩" label="..." \
    label.color="$GREY" icon.color="$GREY"
  exit 0
fi

# ── Parse cache and format label ────────────────────────────────────────────
STATE=$(python3 -c '
import json, sys
from datetime import datetime, timezone

try:
    d = json.load(sys.stdin)
except Exception:
    print("ERROR")
    sys.exit(0)

blocks = d.get("blocks", [])
active = [b for b in blocks if b.get("isActive")]
if not active:
    print("IDLE")
    sys.exit(0)

b = active[0]
cost = b.get("costUSD", 0)
proj_cost = (b.get("projection") or {}).get("totalCost", 0)

# Remaining minutes in the 5-hour block.
end = datetime.fromisoformat(b["endTime"].replace("Z", "+00:00"))
now = datetime.now(timezone.utc)
remaining = max(0, int((end - now).total_seconds() / 60))
hours, mins = divmod(remaining, 60)
if hours > 0:
    time_left = f"{hours}h{mins:02d}m"
else:
    time_left = f"{mins}m"

print(f"OK|{cost:.0f}|{proj_cost:.0f}|{time_left}|{remaining}")
' < "$CACHE" 2>/dev/null)

case "$STATE" in
  IDLE|"")
    sketchybar --set "$NAME" \
      icon="󰚩" label="idle" \
      label.color="$GREY" icon.color="$GREY"
    ;;
  ERROR)
    sketchybar --set "$NAME" \
      icon="󰚩" label="?" \
      label.color="$ORANGE" icon.color="$ORANGE"
    ;;
  *)
    COST=$(echo "$STATE" | cut -d'|' -f2)
    PROJ=$(echo "$STATE" | cut -d'|' -f3)
    LEFT=$(echo "$STATE" | cut -d'|' -f4)
    REMAINING=$(echo "$STATE" | cut -d'|' -f5)

    # Color thresholds by current block cost.
    if   [ "$COST" -ge 100 ]; then COLOR="$RED"
    elif [ "$COST" -ge 25  ]; then COLOR="$YELLOW"
    else                            COLOR="$GREEN"
    fi

    # If projection >> 2x current and burning fast, also flag.
    if [ "$PROJ" -gt $((COST * 3)) ] && [ "$REMAINING" -gt 60 ]; then
      COLOR="$YELLOW"
    fi

    sketchybar --set "$NAME" \
      icon="󰚩" label="\$${COST} • ${LEFT}" \
      label.color="$COLOR" icon.color="$COLOR"

    # Stash projection for click handler.
    echo "${COST}|${PROJ}|${LEFT}" > "$HOME/.cache/sketchybar-claude-block.txt" 2>/dev/null
    ;;
esac
