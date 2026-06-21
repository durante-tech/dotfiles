#!/bin/bash

source "$CONFIG_DIR/colors.sh"

# Left-click opens the Docker Desktop dashboard; right-click / shift-click opens
# a popup listing running containers (rebuilt on each open, mic/volume-style).
docker=(
  script="$PLUGIN_DIR/docker.sh"
  icon="󰡨"
  label=""
  background.color="$PURE_BLACK"
  padding_right=5
  padding_left=5
  update_freq=30
  updates=on
  click_script="$PLUGIN_DIR/docker_click.sh"
  popup.background.color="$POPUP_BACKGROUND_COLOR"
  popup.background.border_color="$POPUP_BORDER_COLOR"
  popup.background.border_width=2
  popup.background.corner_radius=6
  popup.horizontal=off
  popup.align=left
  popup.y_offset=5
)

sketchybar --add item docker left \
           --set docker "${docker[@]}"
