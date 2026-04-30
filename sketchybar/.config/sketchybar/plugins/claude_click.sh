#!/usr/bin/env bash
# Click handler for the claude SketchyBar item.
# Copies the active session file path to the clipboard.

SESSION_FILE="$HOME/.cache/sketchybar-claude-session.txt"

if [ -f "$SESSION_FILE" ]; then
  SESSION_PATH=$(cat "$SESSION_FILE")
  if [ -f "$SESSION_PATH" ]; then
    echo -n "$SESSION_PATH" | pbcopy
    osascript -e "display notification \"$(basename "$SESSION_PATH")\" with title \"Claude session path copied\"" 2>/dev/null
    exit 0
  fi
fi

osascript -e 'display notification "No active Claude session" with title "Claude"' 2>/dev/null
