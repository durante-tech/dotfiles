#!/bin/bash

github=(
  script="$PLUGIN_DIR/github.sh"
  icon=""
  label=""
  background.color="$PURE_BLACK"
  padding_right=5
  padding_left=5
  update_freq=300
  updates=on
  click_script="open https://github.com/notifications"
)

sketchybar --add item github right \
           --set github "${github[@]}"
