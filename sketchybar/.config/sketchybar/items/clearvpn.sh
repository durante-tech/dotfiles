#!/bin/bash

clearvpn=(
  script="$PLUGIN_DIR/clearvpn.sh"
  icon="󰦝"
  label=""
  background.color="$PURE_BLACK"
  padding_right=5
  padding_left=5
  # Connection state changes rarely; a minute of lag is fine.
  update_freq=60
  updates=on
  click_script="open -a 'ClearVPN'"
)

sketchybar --add item clearvpn left \
           --set clearvpn "${clearvpn[@]}"
