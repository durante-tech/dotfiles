#!/bin/bash

# volume item — icon + percentage label, click to open Sound prefs.
# Originally a slider with width=0 (icon-only effectively); converted to a
# regular item so update_freq actually fires the script on first load.
#
# update_freq is a stale-guard, not the refresh path: the volume_change
# subscription below fires the instant CoreAudio volume changes, system_woke
# covers wake, and sketchybarrc's --update populates it at load. At 5s the
# routine tick spawned bash + osascript ~17k times a day
# (plugins/volume.sh populate_from_system) to re-read a value nothing changed.
#
# Deliberately NOT subscribed to mouse.clicked. sketchybar only exports
# $PERCENTAGE from bar_item_cancel_drag(), which is guarded by has_slider
# (v2.24.0 src/bar_item.c); this item is a plain `item`, so the handler that
# read $PERCENTAGE could never fire and the subscription only cost one extra
# forked bash per click on top of click_script.
volume=(
  script="$PLUGIN_DIR/volume.sh"
  click_script="$PLUGIN_DIR/volume_click.sh"
  updates=on
  update_freq=60
  padding_left=5
  padding_right=5
  icon.padding_left=8
  icon.padding_right=4
  background.color="$PURE_BLACK"
  icon.color="$WHITE"
  label.color="$WHITE"
  label.padding_right=8
)

sketchybar --add item volume right \
           --set volume "${volume[@]}" \
           --subscribe volume volume_change system_woke
