#!/bin/bash

# Opens the voice-server popup menu. Refreshes the status header + engine name
# from the live /health response, shows only the contextually-relevant
# Start/Stop row, then toggles the popup open/closed.
source "$CONFIG_DIR/colors.sh"

SERVER_URL="http://localhost:8888"

HEALTH="$(curl -s --connect-timeout 1 --max-time 2 "${SERVER_URL}/health" 2>/dev/null)"

if [ -n "$HEALTH" ]; then
    # Extract "voice_system":"<engine>" without requiring jq.
    ENGINE="$(printf '%s' "$HEALTH" | sed -n 's/.*"voice_system":"\([^"]*\)".*/\1/p')"
    [ -z "$ENGINE" ] && ENGINE="Unknown"
    sketchybar --set voice_server.status label="Running · $ENGINE" label.color="$GREEN" \
               --set voice_server.start  drawing=off \
               --set voice_server.stop   drawing=on
else
    sketchybar --set voice_server.status label="Stopped" label.color="$GREY" \
               --set voice_server.start  drawing=on \
               --set voice_server.stop   drawing=off
fi

sketchybar --set voice_server popup.drawing=toggle
