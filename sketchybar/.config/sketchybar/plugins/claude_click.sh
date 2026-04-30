#!/usr/bin/env bash
# Click handler for the claude SketchyBar item.
# Shows a macOS notification with current block spend + projection + time left.

CACHE="$HOME/.cache/sketchybar-claude-block.txt"

if [ -f "$CACHE" ]; then
  IFS='|' read -r COST PROJ LEFT < "$CACHE"
  osascript -e "display notification \"\$$COST now → projected \$$PROJ • $LEFT remaining in this 5-hour block\" with title \"Claude Code usage\"" 2>/dev/null
else
  osascript -e 'display notification "No active Claude session in last 5h" with title "Claude Code usage"' 2>/dev/null
fi
