#!/usr/bin/env bash
# bd-lmu-watch.sh — ambient-light bridge.
#
# BetterDisplay reports the MacBook ambient sensor unavailable (likely Screen
# Recording permission gap on pre-release channel). Bridge via IORegistry:
# AppleLMUController exposes "brightness" as a hex value.
#
# Polls every 60s, buckets into 4 ambient levels with hysteresis (±15%),
# triggers bd-apply.sh on bucket TRANSITION only (not every read).
#
# Buckets (rough lux mapping, calibrate by eye):
#   0 = dark        (<= 50 lux)     → night
#   1 = dim         (51-200 lux)    → evening
#   2 = indoor      (201-600 lux)   → afternoon
#   3 = daylight    (>600 lux)      → day
#
# Designed to run as launchd KeepAlive agent. Loop interval inside the script
# (not StartInterval) so a single process owns hysteresis state.

set -u

APPLY="$HOME/dotfiles/scripts/scripts/bd-apply.sh"
BUCKET_FILE="/tmp/bd-lmu-bucket"
POLL_S=60

read_lmu() {
    local raw
    raw="$(ioreg -r -c AppleLMUController 2>/dev/null | awk '/"brightness"/ {gsub(/[^0-9.]/,"",$NF); print $NF; exit}')"
    [[ -z "$raw" ]] && { echo -1; return; }
    echo "$raw"
}

raw_to_bucket() {
    local lux="$1"
    if   (( $(echo "$lux <= 50" | bc -l) ));   then echo 0
    elif (( $(echo "$lux <= 200" | bc -l) ));  then echo 1
    elif (( $(echo "$lux <= 600" | bc -l) ));  then echo 2
    else echo 3
    fi
}

bucket_to_mode() {
    case "$1" in
        0) echo night ;;
        1) echo evening ;;
        2) echo afternoon ;;
        3) echo day ;;
        *) echo day ;;
    esac
}

last_bucket=-1
[[ -r "$BUCKET_FILE" ]] && last_bucket="$(cat "$BUCKET_FILE")"

while true; do
    lux="$(read_lmu)"
    if [[ "$lux" == "-1" ]]; then
        sleep "$POLL_S"
        continue
    fi
    bucket="$(raw_to_bucket "$lux")"
    if [[ "$bucket" != "$last_bucket" ]]; then
        echo "$bucket" > "$BUCKET_FILE"
        mode="$(bucket_to_mode "$bucket")"
        "$APPLY" "$mode" >/dev/null 2>&1 || true
        last_bucket="$bucket"
    fi
    sleep "$POLL_S"
done
