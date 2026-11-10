#!/bin/bash

network=(
  script="$PLUGIN_DIR/network.sh"
  icon="󰛳"
  label=""
  background.color="$PURE_BLACK"
  padding_right=5
  padding_left=5
  # Only drawn above 1 MiB/s; the plugin divides by the real elapsed time.
  update_freq=60
  updates=on
)

sketchybar --add item network right \
           --set network "${network[@]}"
