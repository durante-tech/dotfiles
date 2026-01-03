#!/bin/bash

calendar=(
  script="$PLUGIN_DIR/calendar.sh"
  icon="󰃭"
  label="..."
  background.color="$PURE_BLACK"
  padding_right=5
  padding_left=5
  update_freq=300
  updates=on
  click_script="open -a Calendar"
)

sketchybar --add item calendar left \
           --set calendar "${calendar[@]}"
