#!/bin/bash

clock=(
    background.color="$PURE_BLACK"
    # The label shows minutes.
    update_freq=30
    icon=
    script="$PLUGIN_DIR/clock.sh"
    click_script="open -a Calendar"
)

sketchybar --add item clock right \
           --set clock "${clock[@]}" \
