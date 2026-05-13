#!/bin/sh

# bd_mode plugin — renders glyph + label from event or state file fallback.

STATE_FILE="$HOME/.cache/bd-state"

GLYPH="${GLYPH:-}"
LABEL="${LABEL:-}"

if [ -z "$GLYPH" ] && [ -r "$STATE_FILE" ]; then
    GLYPH="$(cut -d'|' -f4 "$STATE_FILE")"
    LABEL="$(cut -d'|' -f5 "$STATE_FILE")"
fi

[ -z "$GLYPH" ] && GLYPH=󰖙
[ -z "$LABEL" ] && LABEL=""

sketchybar --set "$NAME" icon="$GLYPH" label="$LABEL"
