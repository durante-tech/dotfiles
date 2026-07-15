#!/usr/bin/env bash
# OBS status plugin — turns red and shows "REC NNm" when recording, hides otherwise.

# launchd PATH lacks ~/scripts AND ~/.bun/bin (the obs script's interpreter),
# so provide both. Resolve the obs CLI with a fallback
# (same pattern as obs_action.sh); bail silently only if truly absent
export PATH="$HOME/.bun/bin:$PATH"
OBS_BIN="$(command -v obs || echo "$HOME/scripts/obs")"
[ -x "$OBS_BIN" ] || {
  sketchybar --set "$NAME" drawing=off
  exit 0
}

status_json=$("$OBS_BIN" rec status 2>/dev/null || echo "")

if [[ -z "$status_json" ]] || ! echo "$status_json" | tr -d ' ' | grep -q '"outputActive":true'; then
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
