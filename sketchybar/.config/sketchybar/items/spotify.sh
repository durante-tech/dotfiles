#!/bin/bash

spotify=(
  script="$PLUGIN_DIR/spotify.sh"
  icon="󰓇"
  label=""
  background.color="$PURE_BLACK"
  padding_right=5
  padding_left=5
  update_freq=5
  updates=on
  click_script="open -a Spotify"
)

sketchybar --add item spotify right \
           --set spotify "${spotify[@]}"
