#!/bin/bash

mic=(
  # Mute state only; nothing emits an event for input volume.
  update_freq=60
  updates=on
  script="$PLUGIN_DIR/mic.sh"
  click_script="$PLUGIN_DIR/mic_click.sh"
  label.drawing=off
  icon.padding_left=8
  icon.padding_right=8
  padding_left=10
  padding_right=0
  background.color="$PURE_BLACK"
  background.drawing=off
)

sketchybar --add item mic right \
           --set mic "${mic[@]}" \
           --subscribe mic volume_change
