#!/bin/bash

source "$ITEM_DIR/battery.sh"
source "$ITEM_DIR/wifi.sh"

media_block=(
    background.color="$PURE_BLACK"
    background.corner_radius=6
    background.padding_left=0
    background.padding_right=0
    blur_radius=0
)

sketchybar --add bracket media_block battery wifi \
           --set media_block "${media_block[@]}" \
