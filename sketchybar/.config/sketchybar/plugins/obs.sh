#!/usr/bin/env bash
# OBS status plugin — turns red and shows "REC NNm" when recording, hides otherwise.

# Bail silently if obs CLI not on PATH (during early boot or if OBS not installed)
command -v obs >/dev/null 2>&1 || {
  sketchybar --set "$NAME" drawing=off
  exit 0
}

status_json=$(obs rec status 2>/dev/null || echo "")

if [[ -z "$status_json" ]] || ! echo "$status_json" | grep -q '"outputActive":\s*true'; then
  sketchybar --set "$NAME" drawing=off
  exit 0
fi

# Parse outputDuration (ms) and outputBytes if present
duration_ms=$(echo "$status_json" | grep -oE '"outputDuration":\s*[0-9]+' | grep -oE '[0-9]+' | head -1)
bytes=$(echo "$status_json" | grep -oE '"outputBytes":\s*[0-9]+' | grep -oE '[0-9]+' | head -1)

mins=$(( ${duration_ms:-0} / 60000 ))
mb=$(( ${bytes:-0} / 1048576 ))

sketchybar --set "$NAME" \
              drawing=on \
              icon="" \
              icon.color=$RED \
              label="REC ${mins}m · ${mb}MB" \
              label.color=$RED \
              background.color=$ITEM_BG_COLOR
