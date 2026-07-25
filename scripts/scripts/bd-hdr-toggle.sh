#!/usr/bin/env bash
# bd-hdr-toggle.sh — flip HDR on the external panel, with verified readback.
#
# Deliberately NOT a bd-apply.sh mode. The MODES_TABLE is a time-of-day/task
# axis (dawn..cinema); HDR is orthogonal to it — you want HDR for graded video
# at any hour, and off for SDR desktop work at that same hour. Folding it into
# the table would force every one of the nine modes to take an HDR position.
#
# Why a toggle rather than "leave it on": the external is an HDR10-input panel
# without local dimming. Held on, SDR content renders against an HDR transfer
# curve and greys lift — the desktop looks flat. One key flips it per content.
#
# `betterdisplaycli set` exits 0 even when the write silently no-ops (same trap
# bd-apply.sh:184 documents for DDC), so the exit code is worthless here too.
# Every write in this script is confirmed by reading the value back.
#
# Usage:
#   bd-hdr-toggle.sh            # flip current state
#   bd-hdr-toggle.sh on|off     # force a state (idempotent)
#   bd-hdr-toggle.sh status     # print current state, change nothing

set -u

# Personal values override the defaults below. See docs/PERSONALIZE.md.
[ -f "$HOME/.config/dotfiles/personal.env" ] && source "$HOME/.config/dotfiles/personal.env"

# Same override var as bd-apply.sh — one tag definition per rig, not two.
# Reattaching the panel through a different port renumbers its tagID, so this
# MUST stay overridable rather than hardcoded. Re-derive after a redock with:
#   betterdisplaycli get --identifiers
PORT_TAG="${DOTFILES_BD_PORT_TAG:-60}"
# Brightness to hold while HDR is ON. Graded content wants the full backlight,
# and an HDR transfer curve at a dimmed backlight just crushes the highlights
# you turned HDR on to see.
PORT_BRIGHT="${DOTFILES_BD_HDR_BRIGHTNESS:-100}"
STATE_FILE="$HOME/.cache/bd-state"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG_FILE="/tmp/bd-apply.log"
CLI="/opt/homebrew/bin/betterdisplaycli"

# In-place truncate at 1MB (never mv/gzip — that swaps the inode and breaks any
# running `>>` redirect or launchd StandardOutPath fd pointed at this file).
log() {
    [ -f "$LOG_FILE" ] && [ "$(wc -c <"$LOG_FILE" 2>/dev/null || echo 0)" -gt 1048576 ] && : > "$LOG_FILE"
    printf '[%s] %s\n' "$(date '+%Y-%m-%d %H:%M:%S')" "$*" >> "$LOG_FILE"
}

bd() {
    [[ -x "$CLI" ]] || return 127
    "$CLI" "$@" 2>>"$LOG_FILE"
}

# read_hdr — echo "on" | "off", or empty when the tag does not resolve. The CLI
# prints the literal string "Failed." (exit 0) for an unknown tagID, so treat
# anything that is not on/off as unresolved rather than trusting $?.
read_hdr() {
    local v
    v="$(bd get --tagID="$PORT_TAG" --hdr 2>/dev/null | tr -d '[:space:]')"
    case "$v" in
        on|off) printf '%s' "$v" ;;
        *)      printf '' ;;
    esac
}

# require_tag — fail loudly and actionably when the tag is stale. This is the
# single most likely failure on this rig: reattaching the panel through another
# port renumbers its tagID and every pinned caller silently no-ops.
require_tag() {
    [[ -n "$(read_hdr)" ]] && return 0
    echo "HDR: tagID $PORT_TAG does not resolve." >&2
    echo "Live devices (tagID + name):" >&2
    bd get --identifiers 2>/dev/null | grep -E '"(tagID|name)"' >&2 || true
    echo "Fix: set DOTFILES_BD_PORT_TAG in ~/.config/dotfiles/personal.env" >&2
    log "ERROR tagID=$PORT_TAG unresolved"
    return 3
}

# set_hdr <on|off> — write, then confirm by readback with one retry. HDR is a
# display mode change, not a DDC register poke, so the panel needs a beat to
# renegotiate before the new value reads back.
set_hdr() {
    local want="$1" cur attempt
    for (( attempt=1; attempt<=3; attempt++ )); do
        bd set --tagID="$PORT_TAG" --hdr="$want" >/dev/null
        sleep 1.0
        cur="$(read_hdr)"
        if [[ "$cur" == "$want" ]]; then
            log "HDR=$want (verified attempt=$attempt)"
            return 0
        fi
        log "HDR=$want drift (got=${cur:-?} attempt=$attempt) — retry"
    done
    log "WARN HDR=$want FAILED after 3 attempts"
    return 1
}

# set_brightness <pct> — mirrors bd-apply.sh set_port_feature: DDC writes lie,
# so compare the readback against the expected 0..1 float within BD's 2dp
# rounding jitter. Non-fatal — a brightness miss should not fail the HDR flip.
set_brightness() {
    local pct="$1" exp cur attempt
    exp="$(awk -v p="$pct" 'BEGIN{printf "%.2f", p/100}')"
    for (( attempt=1; attempt<=3; attempt++ )); do
        bd set --tagID="$PORT_TAG" --hardwareBrightness="${pct}%" >/dev/null
        sleep 0.7
        cur="$(bd get --tagID="$PORT_TAG" --hardwareBrightness 2>/dev/null)"
        if [[ "$cur" =~ ^-?[0-9]*\.?[0-9]+$ ]] && \
           awk -v a="$exp" -v b="$cur" 'BEGIN{d=a-b;if(d<0)d=-d;exit(d<=0.02)?0:1}'; then
            log "PORT hardwareBrightness=${pct}% (verified=$cur attempt=$attempt)"
            return 0
        fi
        bd perform --tagID="$PORT_TAG" --reinitialize >/dev/null 2>&1 || true
        sleep 1.0
    done
    log "WARN hardwareBrightness=${pct}% not confirmed"
    return 1
}

# target_brightness <on|off> — HDR on takes the full backlight; HDR off hands
# brightness back to whatever time-of-day mode bd-apply.sh currently holds.
#
# Hardcoding 100% on the way out would be wrong: bd-apply's five launchd timers
# dim the panel through the evening (evening=55%, night=35%), so an HDR flip at
# 23:00 would silently undo the night preset and leave the desk glaring. Reads
# the mode from bd-state and the percentage from bd-apply's MODES_TABLE, so the
# table stays the single source of truth rather than being duplicated here.
target_brightness() {
    [[ "$1" == "on" ]] && { printf '%s' "$PORT_BRIGHT"; return; }

    local mode pct
    mode="$(cut -d'|' -f1 "$STATE_FILE" 2>/dev/null)"
    if [[ -n "$mode" && -r "$SCRIPT_DIR/bd-apply.sh" ]]; then
        # Subshell: bd-apply.sh is source-safe (it guards main() on BASH_SOURCE)
        # but defines its own log()/bd()/tags — isolate so none of it leaks back.
        pct="$(source "$SCRIPT_DIR/bd-apply.sh" >/dev/null 2>&1; mode_row "$mode" | cut -d'|' -f2)"
        [[ "$pct" =~ ^[0-9]+$ ]] && { printf '%s' "$pct"; return; }
    fi
    printf '%s' "$PORT_BRIGHT"
}

apply_hdr() {
    local want="$1" from pct
    from="$(read_hdr)"
    pct="$(target_brightness "$want")"

    if [[ "$from" == "$want" ]]; then
        # Idempotent: still re-assert brightness, because the usual reason to
        # press the key twice is that the panel drifted, not that you forgot.
        set_brightness "$pct" || true
        echo "HDR already $want (brightness ${pct}%)"
        return 0
    fi

    if ! set_hdr "$want"; then
        echo "HDR $from -> $want FAILED (see $LOG_FILE)" >&2
        return 1
    fi

    # Brightness after the flip, never before: switching transfer curves resets
    # the panel's backlight handling, so a pre-flip write gets clobbered.
    set_brightness "$pct" || true

    echo "HDR $from -> $want (brightness ${pct}%)"
    log "toggled HDR $from -> $want (brightness ${pct}%)"
}

main() {
    local arg="${1:-toggle}"

    case "$arg" in
        status)
            require_tag || return $?
            echo "HDR: $(read_hdr) | brightness: $(bd get --tagID="$PORT_TAG" --hardwareBrightness 2>/dev/null)"
            ;;
        on|off)
            require_tag || return $?
            apply_hdr "$arg"
            ;;
        toggle)
            require_tag || return $?
            if [[ "$(read_hdr)" == "on" ]]; then apply_hdr off; else apply_hdr on; fi
            ;;
        *)
            echo "usage: $(basename "$0") [toggle|on|off|status]" >&2
            return 1
            ;;
    esac
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
