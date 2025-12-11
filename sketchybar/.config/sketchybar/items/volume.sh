#!/bin/sh

volume_icon=(
  script="$PLUGIN_DIR/volume.sh"
  click_script="$PLUGIN_DIR/volume_click.sh"
  updates=on
  padding_left=5
  padding_right=5
  icon.align=center
  icon.padding_left=8
  icon.padding_right=4
  background.color="$PURE_BLACK"
  icon.color=$WHITE
  label.color=$WHITE
  label.padding_right=8
)

sketchybar --add item volume left \
           --set volume "${volume_icon[@]}" \
           --subscribe volume volume_change
