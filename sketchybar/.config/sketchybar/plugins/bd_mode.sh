#!/bin/sh
# Render ownership + target + outcome from the controller's atomic state.
. "$CONFIG_DIR/colors.sh"
[ -f "$HOME/.config/dotfiles/personal.env" ] && . "$HOME/.config/dotfiles/personal.env"
DOTFILES_DIR="${DOTFILES_DIR:-$HOME/dotfiles}"
APPLY="$DOTFILES_DIR/scripts/scripts/bd-apply.sh"
if ! DATA=$("$APPLY" status --json 2>/dev/null); then
    sketchybar --set "$NAME" icon=󰀦 label="display state unavailable" icon.color="$RED" label.color="$RED"
    exit 1
fi
LABEL=$(printf '%s' "$DATA" | jq -r '((if .hdr.enabled == true then "HDR / " else "" end) + (if .owner == "manual" then "Manual" else "Auto" end) + " · " + (if .base.hardware < 100 then "H" + (.base.hardware|tostring) else "S" + (.base.dev|tostring) end) + "/" + (if .hdr.enabled == true then .hdr.brightness else .base.port end|tostring) + "%")')
STATUS=$(printf '%s' "$DATA" | jq -r '.outcome.status')
OWNER=$(printf '%s' "$DATA" | jq -r '.owner')
GLYPH=$(printf '%s' "$DATA" | jq -r '.base.glyph')
COLOR="$LABEL_COLOR"
case "$STATUS" in
    failed) LABEL="$LABEL · failed"; COLOR="$RED" ;;
    pending|awaiting-sensor|unverified) LABEL="$LABEL · $STATUS"; COLOR="$YELLOW" ;;
esac
if [ "$OWNER" = auto ] && [ -f /tmp/bd-lmu-sensor-alert ]; then
    LABEL="$LABEL · sensor unavailable"; COLOR="$RED"
fi
sketchybar --set "$NAME" icon="$GLYPH" label="$LABEL" icon.color="$COLOR" label.color="$COLOR"
