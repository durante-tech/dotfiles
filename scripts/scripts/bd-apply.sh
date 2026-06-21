#!/usr/bin/env bash
# bd-apply.sh — BetterDisplay mode-switching entrypoint.
#
# Sets display parameters DIRECTLY rather than via --favoriteMode slot loads.
# This is NOT a temporary workaround pending a favoriteMode migration — the
# direct-set path is the deliberately-preferred mechanism: it adds per-feature
# readback verification (set_port_feature's DDC reinit + 3x retry against a
# sleeping external; set_dev_sw's guard on BD's async EDR-headroom clobber).
# favoriteMode is a single set that exits 0 even on a silent DDC no-op, with no
# closed-loop verify — re-adopting it would re-introduce "mode lost while monitor
# asleep". favoriteMode slots are kept only as a manual recovery fallback
# (bd-build-slots.sh). Version note: the running app is 4.4.0 (build 51969, via
# Sparkle), though the Homebrew cask metadata is pinned at 4.1.1 — `betterdisplaycli
# version` currently hangs (launches a 2nd app instance), so the skew is cosmetic
# but worth tracking. The 4.3.0-era slot-load breakage was never re-verified on 4.4.0.
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

# Personal values override the defaults below. See docs/PERSONALIZE.md.
[ -f "$HOME/.config/dotfiles/personal.env" ] && source "$HOME/.config/dotfiles/personal.env"

DEV_TAG="${DOTFILES_BD_DEV_TAG:-2}"          # DEV-MAIN (default: MacBook Pro 14" XDR)
PORT_TAG="${DOTFILES_BD_PORT_TAG:-60}"       # PORTRAIT-MONITOR (default: Dell U2718Q, DDC)
STATE_FILE="$HOME/.cache/bd-state"
LOCK_DIR="$HOME/.cache/bd-apply.lock"
LOG_FILE="/tmp/bd-apply.log"
CLI="/opt/homebrew/bin/betterdisplaycli"

# Samsung (PORT) is a COLOR-REFERENCE display (operator decision 2026-06-13):
# pin its white point + contrast to neutral/native on EVERY mode so time-of-day
# never warps color fidelity. Only brightness follows the mode ("color locked,
# brightness adapts"). These override the port_contrast/port_temp MODES columns
# for the Samsung; override per-rig via the env vars below.
PORT_REF_CONTRAST="${DOTFILES_BD_PORT_REF_CONTRAST:-75}"  # Samsung native contrast (OSD default)
PORT_REF_TEMP="${DOTFILES_BD_PORT_REF_TEMP:-0}"           # neutral white point (no DDC warm shift)

# Single source of truth for every mode. apply_mode() AND verify_mode() both
# read this table, so verify can no longer silently agree with a stale copy.
# bd-cycle.sh sources this file for ORDER. Add a mode = add one row here.
# Row format: dev_sw% | port_brightness% | port_contrast% | port_temp% | glyph | label
# dev_sw% is softwareBrightness (may exceed 100 — EDR software upscale).
DEV_PRESET='Apple XDR Display (P3-1600 nits)'
# Pipe-delimited string table (NOT an associative array): launchd runs these via
# macOS stock /bin/bash 3.2, which has no `declare -A`. Add a mode = add a row.
# Row: mode|dev_sw%|port_brightness%|port_contrast%|port_temp%|glyph|label
MODES_TABLE='dawn|100|55|70|-2|󰖚|Dawn
day|130|85|70|-1|󰖙|Day
afternoon|110|70|75|-1|󰖕|Afternoon
evening|80|55|70|-5|󰖔|Evening
night|60|35|60|-10|󰖔|Night
meeting|130|100|75|0|󰍫|Meeting
read|100|70|70|-3|󰂺|Read
stream|120|90|75|0|󰕧|Stream
cinema|150|80|80|-2|󰎁|Cinema'

# mode_row <mode> — echo the row with the key stripped ("dev|b|c|t|glyph|label"),
# or empty if the mode is unknown. The trailing `|` anchor stops day/dawn-style
# prefix collisions. Single source of truth for apply_mode + verify_mode.
mode_row() {
    local line
    line="$(grep -m1 "^$1|" <<< "$MODES_TABLE")"
    [[ -n "$line" ]] && printf '%s' "${line#*|}"
}

# Canonical cycle sequence for bd-cycle next/prev. Indexed array (3.2-safe);
# explicit because the order is time/task-meaningful, not alphabetical.
# shellcheck disable=SC2034  # consumed by bd-cycle.sh, which sources this file
ORDER=(dawn day afternoon evening night meeting read stream cinema)

mkdir -p "$(dirname "$STATE_FILE")"

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

# acquire_lock — serialize concurrent apply_mode runs. The five launchd timers,
# bd-lmu-watch, bd-wake (sleepwatcher), and a manual bd-cycle can fire near
# simultaneously and would otherwise interleave DDC writes + STATE_FILE writes.
# macOS ships no flock(1), so use an atomic mkdir mutex with PID-based stale-lock
# reclaim. Blocks up to 30s, then proceeds rather than dropping the apply.
acquire_lock() {
    local waited=0 pid
    while ! mkdir "$LOCK_DIR" 2>/dev/null; do
        pid="$(cat "$LOCK_DIR/pid" 2>/dev/null || true)"
        if [[ -n "$pid" ]] && ! kill -0 "$pid" 2>/dev/null; then
            log "lock stale (pid=$pid gone) — reclaiming"
            rm -rf "$LOCK_DIR"; continue
        fi
        if (( waited >= 30 )); then
            log "WARN lock held ${waited}s by pid=${pid:-?} — proceeding without it"
            return 0
        fi
        sleep 1; waited=$((waited + 1))
    done
    echo "$$" > "$LOCK_DIR/pid"
    trap 'rm -rf "$LOCK_DIR"' EXIT
}

# set_dev_sw <brightness%> — write DEV softwareBrightness and confirm it landed
# via readback, re-asserting on drift. softwareBrightness rides above hardware
# (values > 1.0 are valid EDR upscale: 130% → 1.30), so compare against the
# float, not a 0..1 clamp. The failure mode this guards: BD's async EDR-headroom
# recalc overwriting sw with the headroom ceiling (~1.658) — only a readback
# catches it. `betterdisplaycli set` exits 0 regardless, so the exit code lies.
# Mirror of set_port_feature's discipline; the built-in lacked it.
set_dev_sw() {
    local pct="$1"
    local exp cur attempt
    exp="$(awk -v p="$pct" 'BEGIN{printf "%.2f", p/100}')"
    for (( attempt=1; attempt<=3; attempt++ )); do
        bd set --tagID="$DEV_TAG" --softwareBrightness="${pct}%" >/dev/null
        sleep 0.5
        cur="$(bd get --tagID="$DEV_TAG" --softwareBrightness 2>/dev/null)"
        if [[ "$cur" =~ ^-?[0-9]*\.?[0-9]+$ ]] && \
           awk -v a="$exp" -v b="$cur" 'BEGIN{d=a-b;if(d<0)d=-d;exit(d<=0.02)?0:1}'; then
            log "DEV swBrightness=${pct}% (verified=$cur attempt=$attempt)"
            return 0
        fi
        log "DEV swBrightness=${pct}% drift (want=$exp got=${cur:-?} attempt=$attempt) — re-assert"
        sleep 0.5
    done
    log "WARN DEV swBrightness=${pct}% FAILED after 3 attempts (EDR recalc clobber?)"
    return 1
}

# set_dev <brightness%> <xdrPreset>
# Foundation rule (Amendment F): only fire BetterDisplay set commands when the
# target value differs from the current readback. Reasserting xdrPreset or
# hardwareBrightness when already at target triggers BD's async EDR-headroom
# recalc, which clobbers softwareBrightness with the EDR ceiling (~1.658).
# By short-circuiting unchanged values, the recalc never fires.
set_dev() {
    local pct="$1" preset="$2"
    local cur_preset cur_hw

    cur_preset="$(bd get --tagID="$DEV_TAG" --xdrPreset 2>/dev/null || true)"
    if [[ "$cur_preset" != "$preset" ]]; then
        bd set --tagID="$DEV_TAG" --xdrPreset="$preset" >/dev/null && \
            log "DEV xdrPreset=$preset" || log "WARN DEV xdrPreset=$preset FAILED"
        # Recalc only happens on real preset change. Wait for it to settle
        # (1s observed sufficient; 0.3s was not) before overwriting sw.
        sleep 1.0
    else
        log "DEV xdrPreset=$preset (unchanged, skip)"
    fi

    cur_hw="$(bd get --tagID="$DEV_TAG" --hardwareBrightness 2>/dev/null || true)"
    if [[ "$cur_hw" != "1.0" ]]; then
        bd set --tagID="$DEV_TAG" --hardwareBrightness=100% >/dev/null && \
            log "DEV hwBrightness=100%" || log "WARN DEV hwBrightness=100% FAILED"
        sleep 0.3
    else
        log "DEV hwBrightness=100% (unchanged, skip)"
    fi

    # softwareBrightness is the EDR-sensitive value — close the loop (read back,
    # re-assert on drift) instead of the prior fire-and-one-reassert open loop.
    # The 1s settle above lets the recalc land before we write, so our value
    # wins; set_dev_sw then guards against any late residual.
    set_dev_sw "$pct"
}

# set_port_feature <feature> <pct> — write one DDC feature and confirm it
# landed via readback, retrying (with a connection reinitialize) on drift.
# `betterdisplaycli set` exits 0 even when a DDC write silently no-ops against
# a sleeping external monitor, so the exit code is worthless — the readback is
# the only honest success signal. This is why a mode change scheduled while
# the portrait monitor sleeps used to be lost permanently.
set_port_feature() {
    local feat="$1" pct="$2"
    local exp cur attempt
    exp="$(awk -v p="$pct" 'BEGIN{printf "%.2f", p/100}')"
    for (( attempt=1; attempt<=3; attempt++ )); do
        bd set --tagID="$PORT_TAG" --"$feat"="${pct}%" >/dev/null
        sleep 0.7
        cur="$(bd get --tagID="$PORT_TAG" --"$feat" 2>/dev/null)"
        if [[ "$cur" =~ ^-?[0-9]*\.?[0-9]+$ ]] && \
           awk -v a="$exp" -v b="$cur" 'BEGIN{d=a-b;if(d<0)d=-d;exit(d<=0.02)?0:1}'; then
            log "PORT $feat=${pct}% (verified=$cur attempt=$attempt)"
            return 0
        fi
        log "PORT $feat=${pct}% drift (want=$exp got=${cur:-?} attempt=$attempt) — reinitialize + retry"
        bd perform --tagID="$PORT_TAG" --reinitialize >/dev/null 2>&1 || true
        sleep 1.0
    done
    log "WARN PORT $feat=${pct}% FAILED after 3 attempts (monitor asleep or DDC down)"
    return 1
}

# set_port <brightness%> [contrast% temp% — ignored] — Samsung is a color-
# reference display: only brightness follows the mode; contrast + temperature
# are pinned to the neutral PORT_REF_* values on every mode to preserve color
# fidelity. The port_contrast/port_temp args are accepted (call-site stability)
# but intentionally NOT applied to the Samsung.
set_port() {
    set_port_feature hardwareBrightness "$1"
    set_port_feature hardwareContrast  "$PORT_REF_CONTRAST"
    set_port_feature temperature       "$PORT_REF_TEMP"
}

apply_mode() {
    local mode="$1"
    local row; row="$(mode_row "$mode")"
    if [[ -z "$row" ]]; then
        echo "unknown mode: $mode" >&2; return 2
    fi

    local dev_pct port_b port_c port_t glyph label
    IFS='|' read -r dev_pct port_b port_c port_t glyph label <<< "$row"

    # Serialize against other apply_mode invokers before touching displays.
    acquire_lock

    # DEV-MAIN uses XDR P3-1600 for EDR headroom (sw upscale on 100% hw) across
    # all modes. DEV_PRESET is constant today — if meeting/read/stream should
    # switch to sRGB for color accuracy, add a per-row preset field to MODES.
    set_dev "$dev_pct" "$DEV_PRESET"
    set_port "$port_b" "$port_c" "$port_t"

    local source="${BD_SOURCE:-manual}"
    local ts
    ts="$(date -u +%FT%TZ)"
    log "applied mode=$mode source=$source"
    # State schema: mode|applied_ts|source|glyph|label
    printf '%s|%s|%s|%s|%s\n' "$mode" "$ts" "$source" "$glyph" "$label" > "$STATE_FILE"

    if command -v sketchybar >/dev/null 2>&1; then
        sketchybar --trigger bd_mode_changed MODE="$mode" GLYPH="$glyph" LABEL="$label" 2>/dev/null || true
    fi
}

print_status() {
    if [[ -r "$STATE_FILE" ]]; then
        local mode ts source glyph label
        IFS='|' read -r mode ts source glyph label < "$STATE_FILE"
        printf 'mode:    %s\n' "$mode"
        printf 'applied: %s (%s)\n' "$ts" "$source"
        printf 'icon:    %s %s\n' "$glyph" "$label"
    else
        echo "unknown (no state file)"
    fi
}

# verify: probe live BD readback and diff against the intent table for the
# currently-applied mode. Exit 0 if all values match, 1 if any drift.
verify_mode() {
    if [[ ! -r "$STATE_FILE" ]]; then
        echo "no state — apply a mode first" >&2
        return 2
    fi
    local mode
    mode="$(cut -d'|' -f1 "$STATE_FILE")"

    # Intent comes from the same MODES table apply_mode() writes from — one
    # source of truth, so verify can no longer agree with a stale duplicate.
    local row; row="$(mode_row "$mode")"
    if [[ -z "$row" ]]; then
        echo "unknown mode: $mode" >&2; return 2
    fi
    local dev_pct dev_preset port_b port_c port_t
    IFS='|' read -r dev_pct port_b port_c port_t _ _ <<< "$row"
    dev_preset="$DEV_PRESET"

    local cur_dev_sw cur_dev_preset cur_port_b cur_port_c cur_port_t
    cur_dev_sw="$(bd get --tagID="$DEV_TAG" --softwareBrightness 2>/dev/null || echo ?)"
    cur_dev_preset="$(bd get --tagID="$DEV_TAG" --xdrPreset 2>/dev/null || echo ?)"
    cur_port_b="$(bd get --tagID="$PORT_TAG" --hardwareBrightness 2>/dev/null || echo ?)"
    cur_port_c="$(bd get --tagID="$PORT_TAG" --hardwareContrast 2>/dev/null || echo ?)"
    cur_port_t="$(bd get --tagID="$PORT_TAG" --temperature 2>/dev/null || echo ?)"

    # BD reports brightness/contrast as 0..1 float, temperature as ±0..1.
    # Convert intent percent → expected float for comparison.
    local exp_dev_sw exp_port_b exp_port_c exp_port_t
    exp_dev_sw="$(awk -v p="$dev_pct"  'BEGIN{printf "%.2f", p/100}')"
    # Samsung contrast + temperature are pinned to the color-reference values on
    # every mode (not the per-mode columns), so verify against PORT_REF_*, not port_c/port_t.
    exp_port_b="$(awk -v p="$port_b"           'BEGIN{printf "%.2f", p/100}')"
    exp_port_c="$(awk -v p="$PORT_REF_CONTRAST" 'BEGIN{printf "%.2f", p/100}')"
    exp_port_t="$(awk -v p="$PORT_REF_TEMP"     'BEGIN{printf "%.2f", p/100}')"

    # drift is accumulated in the parent scope here. The prior version set
    # `drift=1` inside a $(...) command substitution — a subshell — so the
    # assignment never propagated and verify always reported "all match".
    local drift=0 st
    printf 'mode: %s\n\n' "$mode"

    st=ok; diff_ok "$exp_dev_sw" "$cur_dev_sw" >/dev/null || { st=DRIFT; drift=1; }
    printf '  %-22s expect=%-8s actual=%-8s %s\n' "DEV softwareBrightness" \
        "$exp_dev_sw" "$cur_dev_sw" "$st"

    st=ok; [[ "$dev_preset" == "$cur_dev_preset" ]] || { st=DRIFT; drift=1; }
    printf '  %-22s expect=%-40s actual=%-40s %s\n' "DEV xdrPreset" \
        "$dev_preset" "$cur_dev_preset" "$st"

    st=ok; diff_ok "$exp_port_b" "$cur_port_b" >/dev/null || { st=DRIFT; drift=1; }
    printf '  %-22s expect=%-8s actual=%-8s %s\n' "PORT hardwareBrightness" \
        "$exp_port_b" "$cur_port_b" "$st"

    st=ok; diff_ok "$exp_port_c" "$cur_port_c" >/dev/null || { st=DRIFT; drift=1; }
    printf '  %-22s expect=%-8s actual=%-8s %s\n' "PORT hardwareContrast" \
        "$exp_port_c" "$cur_port_c" "$st"

    st=ok; diff_ok "$exp_port_t" "$cur_port_t" >/dev/null || { st=DRIFT; drift=1; }
    printf '  %-22s expect=%-8s actual=%-8s %s\n' "PORT temperature" \
        "$exp_port_t" "$cur_port_t" "$st"

    # EDR headroom diagnostic (read-only, informational — NOT a pass/fail check).
    # When 'Headroom' == 'Max Headroom' the built-in sits at its EDR ceiling, which
    # is the state where BD's async recalc can clobber softwareBrightness (the
    # failure set_dev_sw guards). Surfaced here to correlate a DEV sw drift above
    # with headroom-at-ceiling; no heuristic is asserted.
    local edr
    edr="$(bd get --tagID="$DEV_TAG" --appleBrightnessReport 2>/dev/null \
        | grep -E 'EDR State / (Headroom|Max Headroom|Available Headroom|Requested Headroom):' \
        | sed -E 's#.*/ ([A-Za-z ]+): *#\1=#' | tr '\n' ' ')"
    [[ -n "$edr" ]] && printf '  %-22s %s\n' "DEV EDR (info)" "$edr"

    (( drift == 0 )) && echo $'\nall values match intent.' && return 0
    echo $'\ndrift detected — re-apply or investigate.' >&2
    return 1
}

# diff_ok <expected> <actual> — tolerate 0.02 float jitter (BD rounds at 2dp).
diff_ok() {
    awk -v a="$1" -v b="$2" 'BEGIN{ d=a-b; if(d<0)d=-d; exit (d<=0.02)?0:1 }' && echo ok
}

main() {
    local arg="${1:-}"
    if [[ -z "$arg" ]]; then
        echo "usage: $(basename "$0") <mode>"
        echo "modes:    dawn day afternoon evening night meeting read stream cinema"
        echo "commands: status verify"
        exit 1
    fi

    case "$arg" in
        status) print_status; return 0 ;;
        verify) verify_mode ;;
        *) apply_mode "$arg" ;;
    esac
}

# Run main only when executed directly. bd-cycle.sh sources this file for the
# MODES / ORDER tables and must not apply a mode as a side effect of sourcing.
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
