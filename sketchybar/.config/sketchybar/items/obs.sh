#!/usr/bin/env bash
# OBS recording widget — shows REC + size when recording, hidden otherwise.
# Polls every 5s (cheap call to obs.ts via local WebSocket).
# Click to open OBS.

sketchybar --add item obs right \
           --set obs \
              update_freq=5 \
              icon="" \
              icon.font="$FONT:Bold:14.0" \
              icon.color=$WHITE \
              label="" \
              script="$PLUGIN_DIR/obs.sh" \
              click_script="open -a OBS"
