#!/bin/bash

claude=(
  script="$PLUGIN_DIR/claude.sh"
  icon="󰚩"
  label=""
  background.color="$PURE_BLACK"
  padding_right=5
  padding_left=5
  update_freq=10
  updates=on
  click_script="$PLUGIN_DIR/claude_click.sh"
)

sketchybar --add item claude right \
           --set claude "${claude[@]}"
