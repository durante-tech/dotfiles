#!/bin/bash

clearvpn=(
  script="$PLUGIN_DIR/clearvpn.sh"
  icon="󰦝"
  label="..."
  background.color="$PURE_BLACK"
  padding_right=5
  padding_left=5
  update_freq=10
  updates=on
  click_script="open -a 'ClearVPN'"
)

sketchybar --add item clearvpn right \
           --set clearvpn "${clearvpn[@]}"
