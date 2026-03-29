#!/usr/bin/env bash

sketchybar --add event aerospace_mode_change

sketchybar --add item aerospace_mode left \
    --set aerospace_mode \
        drawing=off \
        label="NORMAL" \
        label.font="$FONT:Bold:12.0" \
        icon="" \
        icon.padding_right=6 \
        background.corner_radius=5 \
        background.height=22 \
        background.drawing=on \
        script="$PLUGIN_DIR/aerospace_mode.sh" \
    --subscribe aerospace_mode aerospace_mode_change
