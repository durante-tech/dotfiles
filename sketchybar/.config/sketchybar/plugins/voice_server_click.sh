#!/bin/bash

source "$CONFIG_DIR/colors.sh"

SERVER_URL="http://localhost:8888"
CTL="$HOME/.claude/VoiceServer/macos-service/voice-server-ctl.sh"

if curl -s --connect-timeout 1 --max-time 2 "${SERVER_URL}/health" > /dev/null 2>&1; then
    "$CTL" stop
    sketchybar --set "$NAME" icon="󰗌" label="Off" icon.color="$GREY" label.color="$GREY"
else
    "$CTL" start
    sleep 1
    sketchybar --set "$NAME" icon="󰗊" label="On" icon.color="$GREEN" label.color="$GREEN"
fi
