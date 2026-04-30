#!/bin/bash

memory=(
  script="$PLUGIN_DIR/memory.sh"
  icon="󰍛"
  label=""
  background.color="$PURE_BLACK"
  padding_right=5
  padding_left=5
  update_freq=10
  updates=on
)

sketchybar --add item memory right \
           --set memory "${memory[@]}"
