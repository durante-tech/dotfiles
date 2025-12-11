#!/bin/bash

network=(
  script="$PLUGIN_DIR/network.sh"
  icon="󰛳"
  label="..."
  background.color="$PURE_BLACK"
  padding_right=5
  padding_left=5
  update_freq=5
  updates=on
)

sketchybar --add item network right \
           --set network "${network[@]}"
