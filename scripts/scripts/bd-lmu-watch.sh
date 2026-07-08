#!/usr/bin/env bash
# bd-lmu-watch.sh — ambient-light bridge.
#
# Primary ambient source is BetterDisplay's own `get --ambientLight` (the ONLY
# working ambient surface on this Apple Silicon Mac — verified 2026-06-20: every
# ioreg ALS class is empty here, including the legacy Intel-era AppleLMUController
# and the AppleSPUALS* family). The earlier "Screen Recording permission gap"
# theory was wrong: ioreg is not TCC-gated; the sensor simply isn't exposed via
# IORegistry on this hardware. The ioreg ladder is retained only as a best-effort
# fallback for other rigs. See [[display-color-refresh-already-optimal]].
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

[ -f "$HOME/.config/dotfiles/personal.env" ] && source "$HOME/.config/dotfiles/personal.env"

DOTFILES_DIR="${DOTFILES_DIR:-$HOME/dotfiles}"
APPLY="$DOTFILES_DIR/scripts/scripts/bd-apply.sh"
WAKE="$DOTFILES_DIR/scripts/scripts/bd-wake.sh"
BUCKET_FILE="/tmp/bd-lmu-bucket"
LOG_FILE="/tmp/bd-lmu-watch.log"
CLI="/opt/homebrew/bin/betterdisplaycli"
PORT_TAG="${DOTFILES_BD_PORT_TAG:-60}"
POLL_S=60

# Ambient bucket boundaries in raw AppleLMUController units (NOT lux — see
# read_lmu; thresholds are nominal, calibrate by eye). THRESHOLDS[i] is the
# boundary between bucket i and i+1. Hysteresis: a bucket change requires
# crossing a boundary by HYST_FRAC in the direction of travel, so a reading
# sitting on a boundary can't flap modes. Bands (±15%) are non-overlapping
# given the 50/200/600 spacing.
THRESHOLDS=(50 200 600)
HYST_FRAC=0.15

# In-place truncate at 1MB (never mv/gzip — that swaps the inode and breaks any
# running `>>` redirect). The launchd-captured StandardOut stream is a separate
# fd this guard can't reach; this only bounds the script's own LOG_FILE.
log() {
  [ -f "$LOG_FILE" ] && [ "$(wc -c <"$LOG_FILE" 2>/dev/null || echo 0)" -gt 1048576 ] && : > "$LOG_FILE"
  printf '[%s] %s\n' "$(date '+%Y-%m-%d %H:%M:%S')" "$*" >> "$LOG_FILE"
}

# read_lmu — PRIMARY: BetterDisplay `get --ambientLight` (global flag, returns a
# lux-like float; the only live source on this Apple Silicon rig). FALLBACK: the
# ioreg ladder (AppleLMUController = legacy/Intel; AppleSMC) for other hardware —
# both empty here, harmless to try. Returns -1 if no source yields a number.
read_lmu() {
    local raw
    raw="$("$CLI" get --ambientLight 2>/dev/null)"
    [[ "$raw" =~ ^-?[0-9]*\.?[0-9]+$ ]] && { echo "$raw"; return; }
    raw="$(ioreg -r -c AppleLMUController 2>/dev/null | awk '/"brightness"/ {gsub(/[^0-9.]/,"",$NF); print $NF; exit}')"
    if [[ -z "$raw" ]]; then
        raw="$(ioreg -r -c AppleSMC 2>/dev/null | awk '/"ambient[Bb]rightness"/ {gsub(/[^0-9.]/,"",$NF); print $NF; exit}')"
    fi
    [[ "$raw" =~ ^-?[0-9]*\.?[0-9]+$ ]] || { echo -1; return; }
    echo "$raw"
}

# raw_to_bucket <lux> <last_bucket> — map a raw reading to bucket 0..3, applying
# a direction-aware dead-band around each boundary relative to the current
# bucket. With a valid last_bucket we only rise past boundary i when lux exceeds
# THRESHOLDS[i]*(1+H) and only drop below it when lux falls under *(1-H); inside
# the band we hold. With no prior bucket (startup / sensor gap) we fall back to
# plain thresholds.
raw_to_bucket() {
    local lux="$1" last="${2:--1}"
    local i t hi lo b=0

    if [[ "$last" =~ ^[0-3]$ ]]; then
        for i in "${!THRESHOLDS[@]}"; do
            t="${THRESHOLDS[$i]}"
            if (( last > i )); then
                # currently above boundary i — only drop if lux < t*(1-H)
                lo="$(awk -v t="$t" -v h="$HYST_FRAC" 'BEGIN{printf "%.4f", t*(1-h)}')"
                (( $(echo "$lux >= $lo" | bc -l) )) && b=$((i + 1))
            else
                # currently at/below boundary i — only rise if lux > t*(1+H)
                hi="$(awk -v t="$t" -v h="$HYST_FRAC" 'BEGIN{printf "%.4f", t*(1+h)}')"
                (( $(echo "$lux > $hi" | bc -l) )) && b=$((i + 1))
            fi
        done
        echo "$b"
        return
    fi

    # No valid prior bucket — plain thresholds (boundary value → lower bucket).
    for i in "${!THRESHOLDS[@]}"; do
        (( $(echo "$lux > ${THRESHOLDS[$i]}" | bc -l) )) && b=$((i + 1))
    done
    echo "$b"
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
sensor_missing_count=0
SENSOR_ALERT_AFTER=5   # consecutive misses (~5min at 60s poll) before user-visible alert

while true; do
    # Wake handler — when the portrait monitor recovers from display sleep,
    # delegate re-apply to bd-wake.sh. DDC writes scheduled while the monitor
    # was asleep silently no-op (betterdisplaycli's `set` still exits 0), so
    # the only way to correct stale brightness is to re-fire after wake. We
    # call bd-wake.sh (the canonical sleepwatcher-ready re-apply) rather than
    # re-implement its 5s settle + 3-retry backoff inline. Runs before the
    # ambient-sensor read so it works even when the sensor is unavailable
    # (the loop would otherwise `continue` past the rest).
    if port_awake; then
        if (( last_port_awake == 0 )); then
            log "PORT wake detected — invoking bd-wake.sh"
            BD_SOURCE=wake "$WAKE" >>"$LOG_FILE" 2>&1 \
                || log "WARN bd-wake.sh failed"
        fi
        last_port_awake=1
    else
        last_port_awake=0
    fi

    lux="$(read_lmu)"
    if [[ "$lux" == "-1" ]]; then
        sensor_missing_count=$((sensor_missing_count + 1))
        if (( sensor_missing_warned == 0 )); then
            log "WARN ambient sensor unavailable (betterdisplaycli --ambientLight + ioreg ladder all empty). Auto mode-switching is paused until it returns."
            sensor_missing_warned=1
        fi
        # The dead sensor went unnoticed from 2026-06-19 because the failure was
        # log-only. Surface it on the bd_mode sketchybar item after ~5min so it
        # can't silently rot again. Fires once at the threshold, not every poll.
        if (( sensor_missing_count == SENSOR_ALERT_AFTER )) && command -v sketchybar >/dev/null 2>&1; then
            sketchybar --set bd_mode label="ambient sensor down" label.color=0xfff38ba8 2>/dev/null || true
        fi
        printf 'unavailable|-1|%s\n' "$(date -u +%FT%TZ)" > "$BUCKET_FILE"
        sleep "$POLL_S"
        continue
    fi
    if (( sensor_missing_warned == 1 )); then
        log "ambient sensor came back: lux=$lux"
        sensor_missing_warned=0
        # Clear the alert — re-render bd_mode from the live state file.
        command -v sketchybar >/dev/null 2>&1 && sketchybar --trigger bd_mode_changed 2>/dev/null || true
    fi
    sensor_missing_count=0
    bucket="$(raw_to_bucket "$lux" "$last_bucket")"
    printf '%s|%s|%s\n' "$bucket" "$lux" "$(date -u +%FT%TZ)" > "$BUCKET_FILE"
    if [[ "$bucket" != "$last_bucket" ]]; then
        mode="$(bucket_to_mode "$bucket")"
        log "transition lux=$lux bucket=$last_bucket→$bucket mode=$mode"
        BD_SOURCE=lmu "$APPLY" "$mode" >>"$LOG_FILE" 2>&1 || log "WARN apply $mode failed"
        last_bucket="$bucket"
    fi
    sleep "$POLL_S"
done
