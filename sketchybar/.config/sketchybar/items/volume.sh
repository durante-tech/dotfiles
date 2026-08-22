#!/bin/bash

# volume item — icon + percentage label, click to open Sound prefs.
# Originally a slider with width=0 (icon-only effectively); converted to a
# regular item so update_freq actually fires the script on first load.
#
# update_freq is a stale-guard, not the refresh path: the volume_change
# subscription below fires the instant CoreAudio volume changes, mouse.clicked
# and system_woke cover the other two cases, and sketchybarrc triggers
# volume_change once at load. At 5s the routine tick spawned bash + osascript
# ~17k times a day (plugins/volume.sh populate_from_system) to re-read a value
# nothing had changed.
volume=(
  script="$PLUGIN_DIR/volume.sh"
  click_script="$PLUGIN_DIR/volume_click.sh"
  updates=on
  update_freq=60
  padding_left=5
  padding_right=5
  icon.align=center
  icon.padding_left=8
  icon.padding_right=4
  background.color="$PURE_BLACK"
  icon.color="$WHITE"
  label.color="$WHITE"
  label.padding_right=8
)

sketchybar --add item volume right \
           --set volume "${volume[@]}" \
           --subscribe volume volume_change mouse.clicked system_woke
