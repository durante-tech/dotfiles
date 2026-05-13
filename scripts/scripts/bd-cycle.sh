#!/usr/bin/env bash
# bd-cycle.sh — advance to the next BetterDisplay mode (sketchybar click handler).
#
# Cycle order: dawn → day → afternoon → evening → night → meeting → read → stream → cinema → dawn

set -u

STATE_FILE="$HOME/.cache/bd-state"
APPLY="$HOME/dotfiles/scripts/scripts/bd-apply.sh"

ORDER=(dawn day afternoon evening night meeting read stream cinema)

current=""
if [[ -r "$STATE_FILE" ]]; then
    current="$(cut -d'|' -f1 "$STATE_FILE")"
fi

next="${ORDER[0]}"
for i in "${!ORDER[@]}"; do
    if [[ "${ORDER[$i]}" == "$current" ]]; then
        idx=$(( (i + 1) % ${#ORDER[@]} ))
        next="${ORDER[$idx]}"
        break
    fi
done

exec "$APPLY" "$next"
