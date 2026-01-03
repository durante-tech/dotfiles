#!/bin/bash

cpu=(
  script="$PLUGIN_DIR/cpu.sh"
  icon="󰻠"
  label="..."
  background.color="$PURE_BLACK"
  padding_right=5
  padding_left=5
  update_freq=10
  updates=on
)

sketchybar --add item cpu right \
           --set cpu "${cpu[@]}"
