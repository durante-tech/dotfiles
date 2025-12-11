#!/bin/bash

source "$CONFIG_DIR/colors.sh"

# Check if Spotify is running
if ! pgrep -x "Spotify" > /dev/null; then
    sketchybar --set "$NAME" icon="󰓇" label="Off" icon.color="$GREY" drawing=off
    exit 0
fi

# Get current track info
PLAYER_STATE=$(osascript -e 'tell application "Spotify" to player state as string' 2>/dev/null)

if [ "$PLAYER_STATE" = "playing" ]; then
    TRACK=$(osascript -e 'tell application "Spotify" to name of current track as string' 2>/dev/null | cut -c1-30)
    ARTIST=$(osascript -e 'tell application "Spotify" to artist of current track as string' 2>/dev/null | cut -c1-20)
    sketchybar --set "$NAME" icon="󰓇" label="${TRACK} - ${ARTIST}" icon.color="$GREEN" drawing=on
elif [ "$PLAYER_STATE" = "paused" ]; then
    TRACK=$(osascript -e 'tell application "Spotify" to name of current track as string' 2>/dev/null | cut -c1-30)
    sketchybar --set "$NAME" icon="󰓇" label="${TRACK} (paused)" icon.color="$YELLOW" drawing=on
else
    sketchybar --set "$NAME" icon="󰓇" label="" icon.color="$GREY" drawing=off
fi
