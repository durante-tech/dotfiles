#!/usr/bin/env bash
# bd-apply.sh — BetterDisplay mode-switching entrypoint.
#
# Sets display parameters DIRECTLY rather than via --favoriteMode slot loads,
# because the slot-load mechanism is broken on BetterDisplay 4.3.0 pre-release
# (see bd-build-slots.sh + memory notes). This is the bulletproof path until
# the channel is reverted (Tier 1.2).
#
# Usage:
#   bd-apply.sh <mode>
#   bd-apply.sh status
#
# Modes:
#   Time-based:  dawn | day | afternoon | evening | night
#   Task-based:  meeting | read | stream | cinema
#   Utility:     status (print current state, no change)
#
# State persisted to ~/.cache/bd-state. Sketchybar notified via trigger.

set -u

DEV_TAG=2          # DEV-MAIN (MacBook Pro 14" XDR)
PORT_TAG=60        # PORTRAIT-MONITOR (Dell U2718Q, DDC)
STATE_FILE="$HOME/.cache/bd-state"
LOG_FILE="/tmp/bd-apply.log"
CLI="/opt/homebrew/bin/betterdisplaycli"

mkdir -p "$(dirname "$STATE_FILE")"

log() { printf '[%s] %s\n' "$(date '+%Y-%m-%d %H:%M:%S')" "$*" >> "$LOG_FILE"; }

bd() {
    [[ -x "$CLI" ]] || return 127
    "$CLI" "$@" 2>>"$LOG_FILE"
}

# set_dev <brightness%> <xdrPreset>
# Locks hardwareBrightness=100% to bypass macOS auto-brightness (the LMU still
# feeds the OS but the panel backlight stays pinned). All dimming happens via
# softwareBrightness, which BetterDisplay overlays at the compositor.
# Attempts unconditionally; failures log but don't abort.
set_dev() {
    local pct="$1" preset="$2"
    bd set --tagID="$DEV_TAG" --xdrPreset="$preset" >/dev/null && \
        log "DEV xdrPreset=$preset" || log "WARN DEV xdrPreset=$preset FAILED"
    sleep 0.3
    bd set --tagID="$DEV_TAG" --hardwareBrightness=100% >/dev/null && \
        log "DEV hwBrightness=100%" || log "WARN DEV hwBrightness=100% FAILED"
    bd set --tagID="$DEV_TAG" --softwareBrightness="${pct}%" >/dev/null && \
        log "DEV swBrightness=${pct}%" || log "WARN DEV swBrightness=${pct}% FAILED"
}

# set_port <brightness%> <contrast%> <temperature%>
set_port() {
    local b="$1" c="$2" t="$3"
    bd set --tagID="$PORT_TAG" --hardwareBrightness="${b}%" >/dev/null && \
        log "PORT hwBrightness=${b}%" || log "WARN PORT brightness FAILED"
    bd set --tagID="$PORT_TAG" --hardwareContrast="${c}%" >/dev/null && \
        log "PORT hwContrast=${c}%" || log "WARN PORT contrast FAILED"
    bd set --tagID="$PORT_TAG" --temperature="${t}%" >/dev/null && \
        log "PORT temperature=${t}%" || log "WARN PORT temperature FAILED"
}

apply_mode() {
    local mode="$1"
    local glyph label

    case "$mode" in
        # DEV-MAIN uses XDR P3-1600 by default for EDR headroom (brightness > 100%
        # via software upscale on top of 100% hardware). sRGB preset reserved for
        # color-accurate work (meeting / read / stream) where gamut accuracy beats nits.
        dawn)
            glyph='󰖚'; label='Dawn'
            set_dev 100 'Apple XDR Display (P3-1600 nits)'
            set_port 55 70 -2
            ;;
        day)
            glyph='󰖙'; label='Day'
            set_dev 130 'Apple XDR Display (P3-1600 nits)'
            set_port 85 75 0
            ;;
        afternoon)
            glyph='󰖕'; label='Afternoon'
            set_dev 110 'Apple XDR Display (P3-1600 nits)'
            set_port 70 75 -1
            ;;
        evening)
            glyph='󰖔'; label='Evening'
            set_dev 80 'Apple XDR Display (P3-1600 nits)'
            set_port 55 70 -5
            ;;
        night)
            glyph='󰖔'; label='Night'
            set_dev 60 'Apple XDR Display (P3-1600 nits)'
            set_port 45 60 -10
            ;;
        meeting)
            glyph='󰍫'; label='Meeting'
            set_dev 130 'Apple XDR Display (P3-1600 nits)'
            set_port 100 80 0
            ;;
        read)
            glyph='󰂺'; label='Read'
            set_dev 100 'Apple XDR Display (P3-1600 nits)'
            set_port 70 70 -3
            ;;
        stream)
            glyph='󰕧'; label='Stream'
            set_dev 120 'Apple XDR Display (P3-1600 nits)'
            set_port 90 75 0
            ;;
        cinema)
            glyph='󰎁'; label='Cinema'
            set_dev 150 'Apple XDR Display (P3-1600 nits)'
            set_port 80 80 0
            ;;
        *) echo "unknown mode: $mode" >&2; return 2 ;;
    esac

    log "applied mode=$mode"
    printf '%s|%s|%s|%s|%s\n' "$mode" "n/a" "0" "$glyph" "$label" > "$STATE_FILE"

    if command -v sketchybar >/dev/null 2>&1; then
        sketchybar --trigger bd_mode_changed MODE="$mode" GLYPH="$glyph" LABEL="$label" 2>/dev/null || true
    fi
}

print_status() {
    if [[ -r "$STATE_FILE" ]]; then
        cat "$STATE_FILE"
    else
        echo "unknown||0||"
    fi
}

main() {
    local arg="${1:-}"
    if [[ -z "$arg" ]]; then
        echo "usage: $(basename "$0") <mode>"
        echo "modes: dawn day afternoon evening night meeting read stream cinema status"
        exit 1
    fi

    case "$arg" in
        status) print_status; return 0 ;;
        *) apply_mode "$arg" ;;
    esac
}

main "$@"
