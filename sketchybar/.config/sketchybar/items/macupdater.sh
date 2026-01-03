#!/bin/bash

macupdater=(
  script="$PLUGIN_DIR/macupdater.sh"
  icon="󰚰"
  label="..."
  background.color="$PURE_BLACK"
  padding_right=5
  padding_left=5
  update_freq=300
  updates=on
  click_script="open -a 'MacUpdater 3'"
)

sketchybar --add item macupdater left \
           --set macupdater "${macupdater[@]}"
