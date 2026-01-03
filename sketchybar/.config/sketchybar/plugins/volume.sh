#!/bin/bash

source "$CONFIG_DIR/icons.sh"
source "$CONFIG_DIR/colors.sh"

update_icon() {
  local vol="$1"
  case $vol in
    [6-9][0-9]|100) ICON=$VOLUME_100 ;;
    [3-5][0-9]) ICON=$VOLUME_66 ;;
    [1-2][0-9]) ICON=$VOLUME_33 ;;
    [1-9]) ICON=$VOLUME_10 ;;
    0) ICON=$VOLUME_0 ;;
    *) ICON=$VOLUME_100 ;;
  esac
  echo "$ICON"
}

volume_change() {
  ICON=$(update_icon "$INFO")
  sketchybar --set "$NAME" icon="$ICON" label="${INFO}%" slider.percentage="$INFO"
}

mouse_clicked() {
  # PERCENTAGE is set by sketchybar when slider is clicked (0-100)
  if [ -n "$PERCENTAGE" ]; then
    osascript -e "set volume output volume $PERCENTAGE"
    ICON=$(update_icon "$PERCENTAGE")
    sketchybar --set "$NAME" icon="$ICON" label="${PERCENTAGE}%"
  fi
}

case "$SENDER" in
  "volume_change") volume_change ;;
  "mouse.clicked") mouse_clicked ;;
esac
