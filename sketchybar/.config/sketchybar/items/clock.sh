#!/bin/bash

clock=(
    background.color="$PURE_BLACK"
    update_freq=10
    icon=
    script="$PLUGIN_DIR/clock.sh"
    click_script="open -a Calendar"
)

sketchybar --add item clock right \
           --set clock "${clock[@]}" \
