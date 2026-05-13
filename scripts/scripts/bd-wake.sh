#!/usr/bin/env bash
# bd-wake.sh — re-apply the current BetterDisplay mode after wake (sleepwatcher ~/.wakeup).
#
# Sleep can drop the Dell off the DDC bus; mode must be re-asserted on wake.
# Retries up to 3 times with backoff if displays are slow to enumerate.

set -u

STATE_FILE="$HOME/.cache/bd-state"
APPLY="$HOME/dotfiles/scripts/scripts/bd-apply.sh"

if [[ ! -r "$STATE_FILE" ]]; then
    echo "no state — defaulting to day"
    exec "$APPLY" day
fi

mode="$(cut -d'|' -f1 "$STATE_FILE")"
[[ -z "$mode" ]] && mode=day

sleep 5

for attempt in 1 2 3; do
    if "$APPLY" "$mode"; then
        exit 0
    fi
    sleep $(( attempt * 5 ))
done
exit 1
