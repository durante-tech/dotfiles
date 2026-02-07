#!/bin/bash

voice_server=(
  script="$PLUGIN_DIR/voice_server.sh"
  click_script="$PLUGIN_DIR/voice_server_click.sh"
  icon="󰗊"
  label="..."
  background.color="$PURE_BLACK"
  padding_right=5
  padding_left=5
  update_freq=5
  updates=on
)

sketchybar --add item voice_server left \
           --set voice_server "${voice_server[@]}"
