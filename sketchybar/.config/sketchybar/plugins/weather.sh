#!/bin/bash

source "$CONFIG_DIR/colors.sh"

# Get weather from wttr.in (free, no API key needed)
# Format: %c = condition icon, %t = temperature
# Added --max-time 5 to prevent hanging on slow networks
# --fail (-f) makes curl return empty output on HTTP 4xx/5xx errors
# Location: DOTFILES_WEATHER_LOCATION from personal.env (e.g. "Sao+Paulo");
# empty default lets wttr.in geolocate by IP — agnostic out of the box.
[ -f "$HOME/.config/dotfiles/personal.env" ] && source "$HOME/.config/dotfiles/personal.env"
LOCATION="${DOTFILES_WEATHER_LOCATION:-}"
WEATHER=$(curl -sf --max-time 5 "wttr.in/${LOCATION}?format=%c+%t&m" 2>/dev/null | head -1)

if [ -z "$WEATHER" ] \
    || [[ "$WEATHER" == *"Unknown"* ]] \
    || [[ "$WEATHER" == *"Sorry"* ]] \
    || [[ "$WEATHER" == *"error"* ]] \
    || [[ "$WEATHER" == *"refused"* ]] \
    || [[ "$WEATHER" == *"DOCTYPE"* ]] \
    || [[ ${#WEATHER} -gt 30 ]]; then
    sketchybar --set "$NAME" icon="󰖐" label="--" icon.color="$GREY"
else
    # Extract icon (first field) and temp (second field) - space separated
    ICON=$(echo "$WEATHER" | awk '{print $1}')
    TEMP=$(echo "$WEATHER" | awk '{print $2}')
    sketchybar --set "$NAME" icon="$ICON" label="$TEMP" icon.color="$BLUE"
fi
