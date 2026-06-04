#!/bin/bash

# Handles voice-server popup menu actions. Invoked as:
#   voice_server_action.sh <start|stop|restart|test|logs|folder>
# Mirrors the old SwiftBar plugin's menu commands. Closes the popup and
# refreshes the bar icon immediately rather than waiting for the 5s poll.
source "$CONFIG_DIR/colors.sh"

SERVER_URL="http://localhost:8888"
VOICE_DIR="$HOME/.claude/VoiceServer"
LOG="$HOME/Library/Logs/dos-voice-server.log"

ACTION="$1"

case "$ACTION" in
    start)   "$VOICE_DIR/start.sh"   >/dev/null 2>&1 & ;;
    stop)    "$VOICE_DIR/stop.sh"    >/dev/null 2>&1 & ;;
    restart) "$VOICE_DIR/restart.sh" >/dev/null 2>&1 & ;;
    test)
        curl -s -X POST "${SERVER_URL}/notify" \
             -H "Content-Type: application/json" \
             -d '{"message":"Testing voice server"}' >/dev/null 2>&1 &
        ;;
    logs)    open -a Console "$LOG" 2>/dev/null || open "$LOG" ;;
    folder)  open "$VOICE_DIR" ;;
esac

# Close the popup.
sketchybar --set voice_server popup.drawing=off

# Refresh the bar icon now (start/stop/restart change state). Give the server a
# moment to come up or down before re-polling so the icon reflects reality.
case "$ACTION" in
    start|stop|restart)
        ( sleep 1; NAME=voice_server "$CONFIG_DIR/plugins/voice_server.sh" ) &
        ;;
esac
