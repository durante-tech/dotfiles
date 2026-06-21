#!/usr/bin/env bash
# OBS recording widget — shows REC + size when recording, hidden otherwise.
# Left-click opens OBS; right-click / shift-click opens a control popup
# (rec/stream toggle, marker). NOTE: the item hides itself when not recording
# (see plugins/obs.sh), so the popup is reachable only while recording.
source "$CONFIG_DIR/colors.sh"

sketchybar --add item obs right \
           --set obs \
              update_freq=5 \
              icon="" \
              icon.font="$FONT:Bold:14.0" \
              icon.color=$WHITE \
              label="" \
              script="$PLUGIN_DIR/obs.sh" \
              click_script="$PLUGIN_DIR/obs_click.sh" \
              popup.background.color="$POPUP_BACKGROUND_COLOR" \
              popup.background.border_color="$POPUP_BORDER_COLOR" \
              popup.background.border_width=2 \
              popup.background.corner_radius=6 \
              popup.horizontal=off \
              popup.align=left \
              popup.y_offset=5

##### Popup control rows (status header refreshed on open) #####
sketchybar --add item obs.status popup.obs \
           --set obs.status label="…" label.color="$WHITE" \
                 icon.drawing=off background.drawing=off \
                 click_script="sketchybar --set obs popup.drawing=off"

sketchybar --add item obs.rec popup.obs \
           --set obs.rec label="Toggle Recording" label.color="$RED" \
                 icon.drawing=off background.color="$PURE_BLACK" background.drawing=on \
                 click_script="$PLUGIN_DIR/obs_action.sh rec"

sketchybar --add item obs.stream popup.obs \
           --set obs.stream label="Toggle Streaming" label.color="$MAGENTA" \
                 icon.drawing=off background.color="$PURE_BLACK" background.drawing=on \
                 click_script="$PLUGIN_DIR/obs_action.sh stream"

sketchybar --add item obs.marker popup.obs \
           --set obs.marker label="Drop Marker" label.color="$YELLOW" \
                 icon.drawing=off background.color="$PURE_BLACK" background.drawing=on \
                 click_script="$PLUGIN_DIR/obs_action.sh marker"

sketchybar --add item obs.open popup.obs \
           --set obs.open label="Open OBS" label.color="$BLUE" \
                 icon.drawing=off background.color="$PURE_BLACK" background.drawing=on \
                 click_script="$PLUGIN_DIR/obs_action.sh open"
