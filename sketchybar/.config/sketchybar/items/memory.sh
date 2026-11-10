#!/bin/bash

memory=(
  script="$PLUGIN_DIR/memory.sh"
  icon="󰍛"
  label=""
  background.color="$PURE_BLACK"
  padding_right=5
  padding_left=5
  # A hidden warning light, not a live meter: one sample a minute is enough.
  update_freq=60
  updates=on
)

sketchybar --add item memory right \
           --set memory "${memory[@]}"
