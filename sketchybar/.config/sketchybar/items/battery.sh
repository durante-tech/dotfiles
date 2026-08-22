#!/bin/bash

battery=(
  script="$PLUGIN_DIR/battery.sh"
  icon.font="$FONT:Regular:19.0"
  background.color="$PURE_BLACK"
  padding_right=0
  padding_left=0
  update_freq=120
  updates=on
  background.drawing=off
)
sketchybar --add item battery right \
           --set battery "${battery[@]}" \
           --subscribe battery power_source_change system_woke
