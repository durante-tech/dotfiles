#!/bin/bash
source "$CONFIG_DIR/colors.sh"

# The process guard and JXA running check avoid launching a stopped application.
if ! pgrep -x Spotify >/dev/null; then
    sketchybar --set "$NAME" icon="󰓇" label="Off" icon.color="$GREY" drawing=off
    exit 0
fi
DATA=$(osascript -l JavaScript <<'JS' 2>/dev/null
const app = Application('Spotify');
if (!app.running()) {
  JSON.stringify({state: 'stopped'});
} else {
  const state = app.playerState();
  const active = state === 'playing' || state === 'paused';
  JSON.stringify({state, track: active ? app.currentTrack.name() : '', artist: active ? app.currentTrack.artist() : ''});
}
JS
)
# JSON is data, never shell code. jq escapes embedded newlines in the JSON;
# normalize label control characters before reading the three output lines.
FIELDS=$(printf '%s' "$DATA" | jq -er '[.state, ((.track // "") | gsub("[\\r\\n\\t]"; " ") | .[0:30]), ((.artist // "") | gsub("[\\r\\n\\t]"; " ") | .[0:20])] | .[]' 2>/dev/null) || FIELDS="unavailable"
{ IFS= read -r PLAYER_STATE; IFS= read -r TRACK; IFS= read -r ARTIST; } <<< "$FIELDS"
case "$PLAYER_STATE" in
    playing) sketchybar --set "$NAME" icon="󰓇" label="${TRACK} - ${ARTIST}" icon.color="$GREEN" drawing=on ;;
    paused) sketchybar --set "$NAME" icon="󰓇" label="${TRACK} (paused)" icon.color="$YELLOW" drawing=on ;;
    unavailable) sketchybar --set "$NAME" icon="󰓇" label="?" icon.color="$GREY" drawing=on ;;
    *) sketchybar --set "$NAME" icon="󰓇" label="" icon.color="$GREY" drawing=off ;;
esac
