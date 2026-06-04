#!/bin/bash

source "$CONFIG_DIR/colors.sh"

# Main bar item — icon/label/color driven by plugins/voice_server.sh (5s poll).
# Click opens a popup menu (plugins/voice_server_click.sh) mirroring the old
# SwiftBar menu: Start/Stop/Restart, Test Voice, View Logs, Open Folder.
voice_server=(
  script="$PLUGIN_DIR/voice_server.sh"
  click_script="$PLUGIN_DIR/voice_server_click.sh"
  icon="󰗊"
  label=""
  background.color="$PURE_BLACK"
  padding_right=5
  padding_left=5
  update_freq=5
  updates=on
  popup.background.color="$POPUP_BACKGROUND_COLOR"
  popup.background.border_color="$POPUP_BORDER_COLOR"
  popup.background.border_width=2
  popup.background.corner_radius=6
  popup.horizontal=off
  popup.align=left
  popup.y_offset=5
)

sketchybar --add item voice_server left \
           --set voice_server "${voice_server[@]}"

##### Popup menu rows (label-only to stay font-safe; mirrors mic/volume idiom) #####
# Status header — refreshed on open by voice_server_click.sh. Click just closes.
sketchybar --add item voice_server.status popup.voice_server \
           --set voice_server.status label="…" label.color="$WHITE" \
                 icon.drawing=off background.drawing=off \
                 click_script="sketchybar --set voice_server popup.drawing=off"

# Start / Stop — only the contextually-relevant one is drawn (toggled on open).
sketchybar --add item voice_server.start popup.voice_server \
           --set voice_server.start label="Start Server" label.color="$GREEN" \
                 icon.drawing=off background.color="$PURE_BLACK" background.drawing=on \
                 click_script="$PLUGIN_DIR/voice_server_action.sh start"

sketchybar --add item voice_server.stop popup.voice_server \
           --set voice_server.stop label="Stop Server" label.color="$RED" \
                 icon.drawing=off background.color="$PURE_BLACK" background.drawing=on \
                 click_script="$PLUGIN_DIR/voice_server_action.sh stop"

sketchybar --add item voice_server.restart popup.voice_server \
           --set voice_server.restart label="Restart Server" label.color="$YELLOW" \
                 icon.drawing=off background.color="$PURE_BLACK" background.drawing=on \
                 click_script="$PLUGIN_DIR/voice_server_action.sh restart"

sketchybar --add item voice_server.test popup.voice_server \
           --set voice_server.test label="Test Voice" label.color="$WHITE" \
                 icon.drawing=off background.color="$PURE_BLACK" background.drawing=on \
                 click_script="$PLUGIN_DIR/voice_server_action.sh test"

sketchybar --add item voice_server.logs popup.voice_server \
           --set voice_server.logs label="View Logs" label.color="$WHITE" \
                 icon.drawing=off background.color="$PURE_BLACK" background.drawing=on \
                 click_script="$PLUGIN_DIR/voice_server_action.sh logs"

sketchybar --add item voice_server.folder popup.voice_server \
           --set voice_server.folder label="Open Folder" label.color="$WHITE" \
                 icon.drawing=off background.color="$PURE_BLACK" background.drawing=on \
                 click_script="$PLUGIN_DIR/voice_server_action.sh folder"
