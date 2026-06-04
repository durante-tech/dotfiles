#!/bin/bash

# Spotify popup transport actions. Invoked as:
#   spotify_action.sh <refresh|prev|next|playpause|open>
# Every AppleScript call is guarded by a running-check because
# `tell application "Spotify"` AUTO-LAUNCHES Spotify otherwise — the popup
# must never start the app, only control it when already open.
source "$CONFIG_DIR/colors.sh"

ACTION="$1"

running() { pgrep -x "Spotify" >/dev/null 2>&1; }

refresh_header() {
    if ! running; then
        sketchybar --set spotify.track label="Spotify not running" label.color="$GREY"
        return
    fi
    local state track artist
    state=$(osascript -e 'tell application "Spotify" to player state as string' 2>/dev/null)
    track=$(osascript -e 'tell application "Spotify" to name of current track as string' 2>/dev/null | cut -c1-30)
    artist=$(osascript -e 'tell application "Spotify" to artist of current track as string' 2>/dev/null | cut -c1-24)
    if [ -z "$track" ]; then
        sketchybar --set spotify.track label="—" label.color="$GREY"
    elif [ "$state" = "playing" ]; then
        sketchybar --set spotify.track label="${track} — ${artist}" label.color="$GREEN"
    else
        sketchybar --set spotify.track label="${track} — ${artist} (paused)" label.color="$YELLOW"
    fi
}

case "$ACTION" in
    refresh)
        refresh_header
        ;;
    prev)
        running && osascript -e 'tell application "Spotify" to previous track' >/dev/null 2>&1
        sleep 0.2; refresh_header
        ;;
    next)
        running && osascript -e 'tell application "Spotify" to next track' >/dev/null 2>&1
        sleep 0.2; refresh_header
        ;;
    playpause)
        running && osascript -e 'tell application "Spotify" to playpause' >/dev/null 2>&1
        sleep 0.2; refresh_header
        ;;
    open)
        open -a Spotify
        sketchybar --set spotify popup.drawing=off
        ;;
esac
