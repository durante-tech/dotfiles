#!/bin/bash

source "$CONFIG_DIR/colors.sh"

SERVER_URL="http://localhost:8888"

if curl -s --connect-timeout 1 --max-time 2 "${SERVER_URL}/health" > /dev/null 2>&1; then
    sketchybar --set "$NAME" icon="󰗊" label="On" icon.color="$GREEN" label.color="$GREEN"
else
    sketchybar --set "$NAME" icon="󰗌" label="Off" icon.color="$GREY" label.color="$GREY"
fi
