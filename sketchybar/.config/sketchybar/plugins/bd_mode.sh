#!/bin/sh

# bd_mode plugin — the SINGLE renderer for this item.
#
# Every path that can change bd_mode re-enters here: bd-apply.sh's
# bd_mode_changed trigger, system_woke, and bd-lmu-watch.sh's ambient-sensor
# alert. So every property this item mutates must be re-asserted on EVERY run,
# colors included — a property written by one path and not the others is a
# one-way door.
#
# That is exactly how this broke: the sensor alert used to be a direct
# `--set bd_mode label=... label.color=<red>` from bd-lmu-watch.sh, while the
# clear path only re-rendered icon + label. After the overnight outage of
# 2026-08-25 22:02 → 2026-08-26 08:37 the item read "Afternoon" in alert red and
# stayed that way, because nothing ever wrote the color back.

. "$CONFIG_DIR/colors.sh"

STATE_FILE="$HOME/.cache/bd-state"
ALERT_FILE="/tmp/bd-lmu-sensor-alert"   # created/removed by bd-lmu-watch.sh

# Sensor alert wins over the mode: auto-switching is paused, so the mode on
# screen is frozen and saying so beats naming it.
if [ -f "$ALERT_FILE" ]; then
    sketchybar --set "$NAME" icon=󰀦 label="ambient sensor down" \
                             icon.color="$RED" label.color="$RED"
    exit 0
fi

GLYPH="${GLYPH:-}"
LABEL="${LABEL:-}"

if [ -z "$GLYPH" ] && [ -r "$STATE_FILE" ]; then
    GLYPH="$(cut -d'|' -f4 "$STATE_FILE")"
    LABEL="$(cut -d'|' -f5 "$STATE_FILE")"
fi

[ -z "$GLYPH" ] && GLYPH=󰖙
[ -z "$LABEL" ] && LABEL=""

sketchybar --set "$NAME" icon="$GLYPH" label="$LABEL" \
                         icon.color="$ICON_COLOR" label.color="$LABEL_COLOR"
