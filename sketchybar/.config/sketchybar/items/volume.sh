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
  slider.highlight_color=$WHITE
  slider.background.height=5
  slider.background.corner_radius=3
  slider.background.color=$GREY
  slider.knob=󰀁
  slider.knob.drawing=on
  slider.width=0
)

sketchybar --add slider volume left 100 \
           --set volume "${volume_icon[@]}" \
           --subscribe volume volume_change mouse.clicked
