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
LOG_FILE="/tmp/bd-lmu-watch.log"
STATE_FILE="$HOME/.cache/bd-state"
CLI="/opt/homebrew/bin/betterdisplaycli"
PORT_TAG=60
POLL_S=60

log() { printf '[%s] %s\n' "$(date '+%Y-%m-%d %H:%M:%S')" "$*" >> "$LOG_FILE"; }

# Try multiple IOReg classes — Apple silicon and Intel macs expose ambient via
# different keys. AppleLMUController is the legacy/Intel path; on M-series the
# sensor surface moved to AppleSMC or AOPSensorHub on some channels.
read_lmu() {
    local raw
    raw="$(ioreg -r -c AppleLMUController 2>/dev/null | awk '/"brightness"/ {gsub(/[^0-9.]/,"",$NF); print $NF; exit}')"
    if [[ -z "$raw" ]]; then
        raw="$(ioreg -r -c AppleSMC 2>/dev/null | awk '/"ambient[Bb]rightness"/ {gsub(/[^0-9.]/,"",$NF); print $NF; exit}')"
    fi
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

# port_awake — probe whether the portrait monitor is reachable via DDC.
# Returns 0 (awake) if hardwareBrightness reads back as a numeric value, 1
# (asleep / DDC down) otherwise. Drives the wake-triggered re-apply below.
port_awake() {
    local v
    v="$("$CLI" get --tagID="$PORT_TAG" --hardwareBrightness 2>/dev/null)"
    [[ "$v" =~ ^-?[0-9]*\.?[0-9]+$ ]]
}

last_bucket=-1
# Bucket file format: <bucket>|<lux>|<iso-ts> — first field is bucket for
# back-compat with prior cut -f1 readers; pipe-delimited tail adds observability.
[[ -r "$BUCKET_FILE" ]] && last_bucket="$(cut -d'|' -f1 "$BUCKET_FILE")"

# Assume the monitor is awake at startup. We only fire a re-apply on a real
# asleep→awake transition, so an initial 1→1 (or 1→1 via no-op) is silent;
# missing a stale state from before the script started is the deliberate cost.
last_port_awake=1

log "bd-lmu-watch started, poll=${POLL_S}s, last_bucket=$last_bucket"
sensor_missing_warned=0

while true; do
    # Wake handler — when the portrait monitor recovers from display sleep,
    # re-apply the current mode. DDC writes scheduled while the monitor was
    # asleep silently no-op (betterdisplaycli's `set` still exits 0), so the
    # only way to correct stale brightness is to re-fire after wake. Runs
    # before the ambient-sensor read so it works even when the sensor is
    # unavailable (the loop would otherwise `continue` past the rest).
    if port_awake; then
        if (( last_port_awake == 0 )); then
            if [[ -r "$STATE_FILE" ]]; then
                cur_mode="$(cut -d'|' -f1 "$STATE_FILE")"
                log "PORT wake detected — re-applying mode=$cur_mode"
                BD_SOURCE=wake "$APPLY" "$cur_mode" >>"$LOG_FILE" 2>&1 \
                    || log "WARN wake re-apply $cur_mode failed"
            else
                log "PORT wake detected — no state file, nothing to re-apply"
            fi
        fi
        last_port_awake=1
    else
        last_port_awake=0
    fi

    lux="$(read_lmu)"
    if [[ "$lux" == "-1" ]]; then
        if (( sensor_missing_warned == 0 )); then
            log "WARN ambient sensor unavailable (AppleLMUController + AppleSMC both empty). Check Screen Recording permission for launchd, or sensor key may have moved on this hardware."
            sensor_missing_warned=1
        fi
        printf 'unavailable|-1|%s\n' "$(date -u +%FT%TZ)" > "$BUCKET_FILE"
        sleep "$POLL_S"
        continue
    fi
    if (( sensor_missing_warned == 1 )); then
        log "ambient sensor came back: lux=$lux"
        sensor_missing_warned=0
    fi
    bucket="$(raw_to_bucket "$lux")"
    printf '%s|%s|%s\n' "$bucket" "$lux" "$(date -u +%FT%TZ)" > "$BUCKET_FILE"
    if [[ "$bucket" != "$last_bucket" ]]; then
        mode="$(bucket_to_mode "$bucket")"
        log "transition lux=$lux bucket=$last_bucket→$bucket mode=$mode"
        BD_SOURCE=lmu "$APPLY" "$mode" >>"$LOG_FILE" 2>&1 || log "WARN apply $mode failed"
        last_bucket="$bucket"
    fi
    sleep "$POLL_S"
done
