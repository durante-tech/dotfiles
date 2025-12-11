#!/bin/bash

weather=(
  script="$PLUGIN_DIR/weather.sh"
  icon="󰖐"
  label="..."
  background.color="$PURE_BLACK"
  padding_right=5
  padding_left=5
  update_freq=1800
  updates=on
)

sketchybar --add item weather right \
           --set weather "${weather[@]}"
