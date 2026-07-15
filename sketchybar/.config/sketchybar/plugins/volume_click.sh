#!/bin/bash

# Left-click opens Sound settings. (The old slider-width animation was dead
# code — items/volume.sh converted volume from a slider to a plain item.)
open_sound_settings() {
  open "x-apple.systempreferences:com.apple.Sound-Settings.extension"
}

toggle_devices() {
  which SwitchAudioSource >/dev/null || exit 0
  source "$CONFIG_DIR/colors.sh"

  args=(--remove '/volume.device\.*/' --set "$NAME" popup.drawing=toggle)
  COUNTER=0
  CURRENT="$(SwitchAudioSource -t output -c)"
  while IFS= read -r device; do
    COLOR=$GREY
    if [ "${device}" = "$CURRENT" ]; then
      COLOR=$WHITE
    fi
    args+=(--add item volume.device.$COUNTER popup."$NAME" \
           --set volume.device.$COUNTER label="${device}" \
                                        label.color="$COLOR" \
                                        background.color=$PURE_BLACK \
                                        background.drawing=on \
                 click_script="SwitchAudioSource -s \"${device}\" && sketchybar --set /volume.device\.*/ label.color=$GREY --set \$NAME label.color=$WHITE --set $NAME popup.drawing=off")
    COUNTER=$((COUNTER+1))
  done <<< "$(SwitchAudioSource -a -t output)"

  sketchybar -m "${args[@]}" > /dev/null
}

# Right-click or shift-click: show device picker
# Left-click: open Sound settings
if [ "$BUTTON" = "right" ] || [ "$MODIFIER" = "shift" ]; then
  toggle_devices
else
  open_sound_settings
fi
