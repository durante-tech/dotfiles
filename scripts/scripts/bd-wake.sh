#!/usr/bin/env bash
# bd-wake.sh — re-apply the current BetterDisplay mode after wake (sleepwatcher ~/.wakeup).
#
# Sleep can drop the Dell off the DDC bus; mode must be re-asserted on wake.
# Retries up to 3 times with backoff if displays are slow to enumerate.

set -u

STATE_FILE="$HOME/.cache/bd-state"
PROFILE_FILE="$HOME/.cache/bd-profile"
APPLY="$HOME/dotfiles/scripts/scripts/bd-apply.sh"
RESTORE="$HOME/dotfiles/scripts/scripts/display-restore.sh"

# APPLY is load-bearing (brightness re-apply is the whole point of this hook) —
# fail loud if it's missing. RESTORE stays soft below: a missing layout restore
# must not block the brightness re-apply.
[[ -x "$APPLY" ]] || { echo "FATAL: bd-apply.sh not found/executable at $APPLY" >&2; exit 127; }

# Displays may be slow to re-enumerate after wake; give them a moment, then
# restore the canonical layout (res/rotation/origin) BEFORE re-applying
# brightness. Sleep/wake otherwise drops the built-in to a wide scaled mode and
# un-rotates PORTRAIT. Best-effort + idempotent (no-op when layout is intact).
# Re-apply the PROFILE that was active before sleep (persisted by display-restore.sh)
# so portrait/stream/hires/native survive wake instead of reverting to daily.
sleep 5
profile=daily
[[ -r "$PROFILE_FILE" ]] && profile="$(cat "$PROFILE_FILE" 2>/dev/null)"
[[ "$profile" =~ ^(daily|stream|hires|native|portrait)$ ]] || profile=daily
[[ -x "$RESTORE" ]] && "$RESTORE" --"$profile" >/dev/null 2>&1 || true

if [[ ! -r "$STATE_FILE" ]]; then
    echo "no state — defaulting to day"
    exec env BD_SOURCE=wake "$APPLY" day
fi

mode="$(cut -d'|' -f1 "$STATE_FILE")"
[[ -z "$mode" ]] && mode=day

for attempt in 1 2 3; do
    if BD_SOURCE=wake "$APPLY" "$mode"; then
        exit 0
    fi
    sleep $(( attempt * 5 ))
done
exit 1
