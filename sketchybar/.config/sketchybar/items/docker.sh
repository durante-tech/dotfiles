#!/bin/bash

docker=(
  script="$PLUGIN_DIR/docker.sh"
  icon="󰡨"
  label=""
  background.color="$PURE_BLACK"
  padding_right=5
  padding_left=5
  update_freq=30
  updates=on
  click_script="open -a 'Docker Desktop' && sleep 0.3 && open docker-desktop://dashboard/containers"
)

sketchybar --add item docker left \
           --set docker "${docker[@]}"
