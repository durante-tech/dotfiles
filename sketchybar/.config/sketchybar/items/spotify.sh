#!/bin/bash

source "$CONFIG_DIR/colors.sh"

# Left-click launches Spotify; right-click / shift-click opens a transport
# popup (plugins/spotify_click.sh). Mirrors the mic/volume right-click idiom.
spotify=(
  script="$PLUGIN_DIR/spotify.sh"
  icon="󰓇"
  label=""
  background.color="$PURE_BLACK"
  padding_right=5
  padding_left=5
  update_freq=5
  updates=on
  click_script="$PLUGIN_DIR/spotify_click.sh"
  popup.background.color="$POPUP_BACKGROUND_COLOR"
  popup.background.border_color="$POPUP_BORDER_COLOR"
  popup.background.border_width=2
  popup.background.corner_radius=6
  popup.horizontal=off
  popup.align=left
  popup.y_offset=5
)

sketchybar --add item spotify right \
           --set spotify "${spotify[@]}"

##### Popup transport rows (label-only, font-safe; state shown via color) #####
# Track header — refreshed on open. Click closes the popup.
sketchybar --add item spotify.track popup.spotify \
           --set spotify.track label="…" label.color="$WHITE" \
                 icon.drawing=off background.drawing=off \
                 click_script="sketchybar --set spotify popup.drawing=off"

sketchybar --add item spotify.prev popup.spotify \
           --set spotify.prev label="Previous" label.color="$WHITE" \
                 icon.drawing=off background.color="$PURE_BLACK" background.drawing=on \
                 click_script="$PLUGIN_DIR/spotify_action.sh prev"

sketchybar --add item spotify.playpause popup.spotify \
           --set spotify.playpause label="Play / Pause" label.color="$GREEN" \
                 icon.drawing=off background.color="$PURE_BLACK" background.drawing=on \
                 click_script="$PLUGIN_DIR/spotify_action.sh playpause"

sketchybar --add item spotify.next popup.spotify \
           --set spotify.next label="Next" label.color="$WHITE" \
                 icon.drawing=off background.color="$PURE_BLACK" background.drawing=on \
                 click_script="$PLUGIN_DIR/spotify_action.sh next"

sketchybar --add item spotify.open popup.spotify \
           --set spotify.open label="Open Spotify" label.color="$WHITE" \
                 icon.drawing=off background.color="$PURE_BLACK" background.drawing=on \
                 click_script="$PLUGIN_DIR/spotify_action.sh open"
