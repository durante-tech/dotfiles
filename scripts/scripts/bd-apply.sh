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
# (bd-build-slots.sh).
#
# Version note (re-verified 2026-07-28): the running app is 5.0.1 (build 52622,
# via Sparkle) on the STABLE channel — preReleaseChannel=0, internalReleaseChannel=0.
# The Homebrew cask is still at 4.3.5, because Sparkle updated the bundle in place
# and brew never learned: `brew reinstall --cask betterdisplay` would DOWNGRADE
# 5.0.1 -> 4.3.5. Keep that in mind before using brew as a repair (`bd-apply.sh
# doctor` prints both versions). The CLI is not a separate build — the Caskroom
# "betterdisplaycli" is a one-line wrapper that execs the app binary — so CLI
# behavior always tracks whatever version is in /Applications.
#
# `betterdisplaycli version` still hangs, and it does NOT just hang: it strands a
# second full app instance, extra menu-bar icon and all, which looks exactly like
# a duplicate installation. Two accumulated on 2026-07-28. Never call it — read
# the version from /Applications/BetterDisplay.app/Contents/Info.plist instead
# (`bd-apply.sh doctor` does this, and flags any strays it finds).
# On 5.x several `get` flags regressed to "Failed." — nativeResolution,
# displayColorSpace, bitDepth, active. Nothing here reads them; use
# system_profiler SPDisplaysDataType / displayplacer for those facts.
# The 4.3.0-era slot-load breakage was never re-verified on 5.x.
#
# Usage:
#   bd-apply.sh <mode>
#   bd-apply.sh status | verify | doctor
#
# Modes:
#   Time-based:  dawn | day | afternoon | evening | night
#   Task-based:  meeting | read | stream | cinema
#   Utility:     status (print current state, no change)
#                verify (diff live readback against the intent table)
#                doctor (confirm both tagIDs still resolve — run after any redock)
#
# State persisted to ~/.cache/bd-state. Sketchybar notified via trigger.

set -u

# Personal values override the defaults below. See docs/PERSONALIZE.md.
[ -f "$HOME/.config/dotfiles/personal.env" ] && source "$HOME/.config/dotfiles/personal.env"

DEV_TAG="${DOTFILES_BD_DEV_TAG:-2}"          # DEV-MAIN (default: MacBook Pro 16" XDR)
PORT_TAG="${DOTFILES_BD_PORT_TAG:-60}"       # PORTRAIT-MONITOR (default: Dell U2718Q, DDC)
STATE_FILE="$HOME/.cache/bd-state"
LOCK_DIR="$HOME/.cache/bd-apply.lock"
LOG_FILE="/tmp/bd-apply.log"
CLI="/opt/homebrew/bin/betterdisplaycli"

# The Dell was designated a COLOR-REFERENCE display on 2026-06-13, which pinned
# its contrast to the 75 OSD default on every mode. RETIRED 2026-07-29 (operator):
# the panel runs Slack, WhatsApp, Discord and kitty — colour fidelity is not
# load-bearing there, and the pin was actively costing contrast on a 350-nit panel
# sitting beside a 500-nit XDR one.
#
# What still holds: the WHITE POINT stays pinned neutral. Temperature is the
# setting that actually warps colour identity across modes.
#
# CONTRAST STAYS AT 75, and that is not the old colour-reference pin — it is the
# panel's NATIVE contrast point. Raising it above the factory default clips
# whites, which costs exactly the near-white steps text antialiasing lives in.
# Florian Hoech (author of DisplayCAL): "the 'contrast' control is usually
# implemented in a way that alters the incoming signal, which can cause clipping
# ... I'd suggest leaving 'contrast' at (factory) default." Dell's own manual
# agrees: "Adjust the Brightness first, and then adjust the Contrast only if
# further adjustment is necessary." This was briefly set to 100 on 2026-07-29 on
# the mistaken reasoning that panel-max contrast costs nothing; it does.
#
# The same source settles which lever DOES address perceived flatness: "Gamma
# (tone curve) and contrast are not related." Gamma is the one below.
#
# The brightness gap is physics, not configuration — DELL 350 nits vs BUILT-IN
# 500 nits x EDR. With luminance already at 100 the only remaining levers are
# perceptual: contrast at the native point, and a gamma lift that raises MIDTONES
# (where text and UI chrome live) without touching the white point. Gamma
# manipulates the colour table, so it is an accuracy-for-legibility trade.
#
# GAMMA IS OFF (2026-07-29, operator preference after living with it). The lift
# was set to 80 earlier the same day, then the operator tuned gamma to 0 at the
# panel and preferred it — with the macOS colour profile also adjusted, the
# midtone lift was no longer buying legibility, only costing accuracy.
#
# 0 does not write gamma 0 — set_port() skips the write entirely, leaving the
# colour table untouched. This matters: the ambient watcher re-applies the full
# mode on every light-level change, so a non-zero value here silently overwrites
# any gamma the operator sets by hand, usually within minutes. That is exactly
# what this line is preventing. Set DOTFILES_BD_PORT_GAMMA=80 to restore the lift.
PORT_REF_CONTRAST="${DOTFILES_BD_PORT_REF_CONTRAST:-75}"   # NATIVE point — raising this clips whites, see below
PORT_REF_TEMP="${DOTFILES_BD_PORT_REF_TEMP:-0}"            # neutral white point — STILL PINNED
PORT_GAMMA="${DOTFILES_BD_PORT_GAMMA:-0}"                  # midtone lift %, 0 = do not touch gamma (operator-chosen 2026-07-29)

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
day|105|100|70|-1|󰖙|Day
afternoon|100|85|75|-1|󰖕|Afternoon
evening|80|55|70|-5|󰖔|Evening
night|60|35|60|-10|󰖔|Night
meeting|130|100|75|0|󰍫|Meeting
read|100|85|70|-3|󰂺|Read
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

# resolve_port_tag — self-heal a stale DOTFILES_BD_PORT_TAG.
#
# The external panel's tagID is a property of the CONNECTION, not the display.
# Measured on this rig by swapping one cable back and forth:
#
#     DisplayPort  tagID 60   UUID E3434867…  name PORTRAIT-MONITOR  350 nits
#     HDMI         tagID 166  UUID E9024EE3…  name DELL U2718Q       500 nits
#     serial       808734284  — IDENTICAL on both, the only stable identifier
#
# Every one of those pinned values moves when the cable moves, and a stale tag is
# silent: writes land in BetterDisplay's cache and the panel never changes. That
# has now cost four separate debugging sessions (60 -> 166 -> 60 -> 166 -> 60).
# Pinning a value that is a function of the cable was the design error; the fix is
# to treat the configured tag as a HINT and re-derive when it does not resolve.
#
# Order: use the configured tag if it is live (fast path, zero behaviour change);
# else match on serial, which survives the swap; else take the sole non-built-in
# display. Every correction is logged loudly — self-healing must never be silent,
# or personal.env rots while everything appears fine.
resolve_port_tag() {
    local ids live
    ids="$(bd get --identifiers 2>/dev/null)" || return 0
    [[ -z "$ids" ]] && return 0

    # awk over the identifier blocks: emit "tagID<TAB>serial<TAB>registryLocation"
    # for each Display (fields are alphabetical, so tagID comes last of the three).
    live="$(awk '
        /"deviceType"/       { isdisp = ($0 ~ /"Display"/); ser=""; reg="" }
        /"serial"/           { s=$0; gsub(/.*: *"|",?$/, "", s); ser=s }
        /"registryLocation"/ { r=$0; reg = ($0 ~ /disp0@/) ? "builtin" : "external" }
        /"tagID"/ { t=$0; gsub(/[^0-9-]/, "", t)
                    if (isdisp) print t "\t" ser "\t" reg
                    isdisp=0 }' <<< "$ids")"
    [[ -z "$live" ]] && return 0

    # 1. Configured tag still live? Nothing to do.
    if grep -q "^${PORT_TAG}	" <<< "$live"; then return 0; fi

    local found=""
    # 2. Match the serial we last saw, if one was recorded.
    if [[ -n "${DOTFILES_BD_PORT_SERIAL:-}" ]]; then
        found="$(awk -F'\t' -v s="$DOTFILES_BD_PORT_SERIAL" '$2==s {print $1; exit}' <<< "$live")"
    fi
    # 3. Otherwise the sole non-built-in display.
    [[ -z "$found" ]] && found="$(awk -F'\t' '$3=="external" {print $1; exit}' <<< "$live")"

    if [[ -n "$found" && "$found" != "$PORT_TAG" ]]; then
        log "PORT tag $PORT_TAG is stale (cable change?) — re-derived as $found for this run."
        log "     Persist it: DOTFILES_BD_PORT_TAG=\"$found\" in ~/.config/dotfiles/personal.env"
        PORT_TAG="$found"
    fi
}
# NOT called at source time. bd-cycle.sh sources this file purely to reuse ORDER,
# and an unguarded call here fired a live `get --identifiers` on every source —
# two round-trips per sketchybar click, with no timeout, in a file that already
# documents this CLI hanging and stranding app instances. main() invokes it.

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

# dev_present — is the built-in actually connected? False in clamshell.
#
# set_dev already reads before writing (Amendment F), but a readback against an
# ABSENT display returns the literal "Failed." rather than a value. That reads
# as "differs from target", so every write fires and the full retry budget is
# spent — ~6s of xdrPreset + hwBrightness + softwareBrightness attempts against
# hardware that is not there. Measured: 8244ms total for one apply in clamshell,
# of which the DEV phase was ~6s and the panel did not move until it gave up.
# That delay is precisely what makes a bd-* Stream Deck key feel dead.
#
# The retry budget is NOT the bug — it exists so a SLEEPING external recovers a
# mode change instead of dropping it. It simply cannot distinguish "asleep, keep
# trying" from "absent, skip". One cheap probe answers that before the budget is
# spent. Deliberately uncached: a stale yes/no across a dock or undock would
# reintroduce exactly the silent-no-op class this file exists to prevent.
dev_present() {
    local v
    v="$(bd get --tagID="$DEV_TAG" --hardwareBrightness 2>/dev/null | tr -d '[:space:]')"
    [[ "$v" =~ ^-?[0-9]*\.?[0-9]+$ ]]
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
# set_port_vcp <vcp-name> <value 0-100> — write one DDC control to the external
# panel as a RAW VCP command.
#
# Why raw VCP instead of BetterDisplay's `--hardwareBrightness` abstraction:
# this display's DDC capabilities report is unacquirable ("DDC channel:
# Available, DDC communication: Supported, DDC capabilities report: Unable to
# acquire" — BetterDisplay's own panel, 2026-07-29). Without that report BD does
# not know which VCP codes the panel implements, so it silently declines to route
# hardwareBrightness/hardwareContrast over DDC — while still ACCEPTING the value
# into its cache and echoing it back on `get`. The old readback loop below
# therefore verified BD's own cache and reported success for writes that never
# left the machine: every mode change was inert on this panel for as long as that
# was true. A raw VCP write bypasses the capability gate entirely and does reach
# the display (operator-confirmed: luminance 20 -> visibly dim, 100 -> restored).
#
# NO READBACK. Three attempts were made to verify these writes against the display
# and all three verified BetterDisplay's own write cache instead. Measured:
#
#   0.5s after a write   stdout="77"  stderr=""          <- cached echo, CLEAN stderr
#   6s after a write     stdout=""    stderr="Failed."   <- the truth on DisplayPort
#
# The cache returns the just-written value with no error for several seconds, so
# neither the value nor stderr discriminates at the moment a readback is taken.
# Waiting the cache out costs ~6s per write, ~12s per mode change, on five launchd
# timers plus the ambient watcher plus every wake — not worth it for a brightness
# preset (operator decision 2026-07-29).
#
# So this dispatches and says so. "dispatched" means the command was ACCEPTED by
# the CLI — validated by the fact that a bogus VCP name and a bogus tagID both
# print "Failed." — not that the panel obeyed. That is a weaker claim than the old
# code made, and it is the true one. doctor and verify report PORT hardware values
# as UNVERIFIABLE rather than inventing agreement.
#
# Prior context this replaces:
#
#   over DisplayPort : capabilities report unacquirable, `get --ddc --vcp=...`
#                      -> "Failed."  — no readback possible
#   over HDMI + HDR  : capabilities report acquired, `get --ddc --vcp=luminance`
#                      -> a real panel value — full readback available
#
# So: read back when the panel answers and compare (genuine verification); when it
# does not, fall back to the dispatch signal — the CLI prints "Failed." on a
# rejected write and stays silent on an accepted one, validated by sending a bogus
# VCP name and a bogus tagID, both of which print "Failed.". The log line says
# which of the two happened; `verified=` and `dispatched=` are not the same claim
# and must not be conflated when reading these logs.
set_port_vcp() {
    local vcp="$1" val="$2"
    local out attempt rc_set
    for (( attempt=1; attempt<=3; attempt++ )); do
        out="$(bd set --tagID="$PORT_TAG" --ddc --vcp="$vcp" --value="$val" 2>&1)"; rc_set=$?
        if (( rc_set == 127 )); then
            log "FATAL PORT vcp:$vcp=$val — betterdisplaycli missing or not executable at $CLI"
            return 1
        fi
        if grep -qi 'failed' <<< "$out"; then
            log "PORT vcp:$vcp=$val rejected (attempt=$attempt) — reinitialize + retry"
            bd perform --tagID="$PORT_TAG" --reinitialize >/dev/null 2>&1 || true
            sleep 1.0
            continue
        fi
        log "PORT vcp:$vcp=$val (dispatched attempt=$attempt)"
        return 0
    done
    log "WARN PORT vcp:$vcp=$val FAILED after 3 attempts (monitor asleep or DDC down)"
    return 1
}

# set_port_feature <feature> <pct> — BetterDisplay-abstraction writer with
# readback. RETAINED for software-path features only (temperature is a software
# colour-table control, not DDC), where the readback is a real signal because BD
# applies it itself rather than forwarding it to the panel.
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

# set_port <brightness%> [contrast% temp% — ignored] — Dell is a color-
# reference display: only brightness follows the mode; contrast + temperature
# are pinned to the neutral PORT_REF_* values on every mode to preserve color
# fidelity. The port_contrast/port_temp args are accepted (call-site stability)
# but intentionally NOT applied to the Dell.
# Brightness and contrast go over RAW DDC (the abstraction silently no-ops on
# this panel — see set_port_vcp). Temperature stays on the BD abstraction: it is
# a SOFTWARE colour-table control, not a DDC one, so BD applies it locally and
# the readback there is genuine.
set_port() {
    set_port_vcp     luminance "$1"
    set_port_vcp     contrast  "$PORT_REF_CONTRAST"
    set_port_feature temperature "$PORT_REF_TEMP"
    # Software midtone lift. Skipped entirely at 0 so the opt-out leaves no trace
    # in the colour table rather than writing a neutral value over it.
    [[ "$PORT_GAMMA" != "0" ]] && set_port_feature gamma "$PORT_GAMMA"
    return 0
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
    # Guarded on dev_present: in clamshell the built-in is absent and the DEV
    # phase would burn ~6s failing before the external is ever touched. The
    # docked path is unchanged — this only skips work that cannot succeed.
    if dev_present; then
        set_dev "$dev_pct" "$DEV_PRESET"
    else
        log "DEV absent (clamshell) — skipping DEV phase"
    fi
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

# bd_stray_instances — list BetterDisplay app processes that a CLI call started
# and never cleaned up. `betterdisplaycli version` is the known offender: it hangs
# and leaves a SECOND full app instance running, complete with its own menu-bar
# icon, so the rig LOOKS like it has several BetterDisplay installations when
# exactly one bundle exists on disk. Two accumulated on 2026-07-28 alone (20:31
# and 20:38, both from an agent asking the CLI for its version).
#
# Discriminator: the real app runs the binary with NO arguments; every CLI call
# execs the same binary WITH arguments (the Homebrew "CLI" is a one-line wrapper
# that does exactly that) and should exit in milliseconds. `ps -Ao pid,lstart,args`
# puts the binary path in field 7 — five lstart fields follow the pid — so field 7
# matching the binary exactly plus NF>7 means "invoked with args and still alive".
bd_stray_instances() {
    ps -Ao pid,lstart,args 2>/dev/null | awk '
        $7 ~ /\/BetterDisplay\.app\/Contents\/MacOS\/BetterDisplay$/ && NF > 7 {
            printf "  pid=%-7s started=%s %s %s  args=%s\n", $1, $3, $4, $5, $8
        }'
}

# bd_app_version — read the version from Info.plist, NEVER from `betterdisplaycli
# version`. That subcommand hangs and strands an app instance (see above); the
# plist is the safe source and needs no running app.
bd_app_version() {
    /usr/libexec/PlistBuddy -c 'Print :CFBundleShortVersionString' \
        /Applications/BetterDisplay.app/Contents/Info.plist 2>/dev/null
}

# bd_display_tags — emit the tagID of every REGISTERED display, one per line.
# Software-side enumeration off `get --identifiers`: unlike a hardwareBrightness
# read it does NOT travel over DDC, so it stays truthful while the external is
# asleep. That distinction is the whole point of doctor (see below).
# `--identifiers` emits one JSON-ish block per device with fields in alphabetical
# order, so deviceType is always seen before tagID. The "DisplayGroup" pseudo-
# device (tagID -1001) is excluded by the closing quote in the /"Display"/ match.
bd_display_tags() {
    bd get --identifiers 2>/dev/null | awk '
        /"deviceType"/ { isdisp = ($0 ~ /"Display"/) }
        /"tagID"/      { if (isdisp) { t = $0; gsub(/[^0-9-]/, "", t); print t } isdisp = 0 }'
}

# doctor: confirm both configured tagIDs actually resolve to a live display
# BEFORE trusting any apply. This exists because the tag is the one value here
# that can go stale silently: reattaching the external through a different port
# renumbers it, `betterdisplaycli get` then answers "Failed." for every feature
# while still exiting 0, and set_port_feature's retry loop misattributes the
# cause to "monitor asleep or DDC down". That mis-diagnosis cost two separate
# debugging sessions (60 -> 166 on 2026-07-25, 166 -> 60 on 2026-07-28), so the
# check is now one command instead of a memory.
#
# Liveness is decided by REGISTRATION, not by a DDC readback. A sleeping external
# answers "Failed." to `get --hardwareBrightness` with a perfectly valid tagID —
# the identical symptom a stale tag produces — so probing DDC here would recreate
# the exact ambiguity doctor exists to resolve, and would tell the operator to
# rewrite a correct personal.env. DDC reachability is still reported, but only as
# a second, non-fatal line.
#
# Exit 0 = healthy. Exit 1 = something needs attention: a tag is stale (the live
# identifier table is printed so the correct value can be copied into
# personal.env) and/or stray app instances are running. Exit 2 = could not
# enumerate at all (CLI missing / BD not running), which is not evidence either
# way — deliberately distinct from 1 so "I could not check" never reads as
# "your config is wrong".
doctor() {
    local rc=0 pair tag name probe tags
    printf 'BetterDisplay tag reachability\n'

    tags="$(bd_display_tags)"
    if [[ -z "$tags" ]]; then
        printf '  cannot enumerate displays — is BetterDisplay running? (CLI: %s)\n' "$CLI"
        printf '  no verdict on the tagIDs; nothing was checked.\n'
        return 2
    fi

    for pair in "DEV:$DEV_TAG" "PORT:$PORT_TAG"; do
        name="${pair%%:*}"; tag="${pair#*:}"
        if ! grep -qx -- "$tag" <<< "$tags"; then
            printf '  %-5s tagID=%-5s STALE — no registered display carries this tagID\n' "$name" "$tag"
            rc=1
            continue
        fi
        probe="$(bd get --tagID="$tag" --hardwareBrightness 2>/dev/null)"
        if [[ "$name" == "PORT" ]]; then
            # Registration alone is not enough for the external panel: the
            # control path can be dead while every cache read looks healthy.
            # `--hardwareBrightness` answers from BD's cache, so it reported a
            # confident OK for days while writes never reached the display.
            # Probe the panel itself; that is the only answer worth printing.
            local vcp
            vcp=""          # no trustworthy DDC readback on this panel — see set_port_vcp
            if [[ "$vcp" =~ ^[0-9]+$ ]]; then
                printf '  %-5s tagID=%-5s OK — panel answers DDC (luminance=%s)\n' "$name" "$tag" "$vcp"
            else
                # NOT a failure. Read support is connection-dependent: this panel
                # answers reads over HDMI and not over DisplayPort, while WRITES
                # work on both (operator-confirmed). DisplayPort is the preferred
                # daily path — it keeps HDR off, which is what leaves the monitor's
                # Brightness and Preset Modes usable at all (Dell U2718Q manual:
                # "While the monitor is processing HDR content, Preset Modes,
                # Brightness, and Dynamic Contrast will be disabled").
                #
                # Exiting 1 here would make doctor fail on the CORRECT setup, and a
                # check that cries wolf on the normal configuration is worse than no
                # check — it teaches you to ignore the one alarm that matters (a
                # genuinely stale tag, which is still rc=1 above).
                printf '  %-5s tagID=%-5s OK — registered; panel does not answer DDC reads\n' "$name" "$tag"
                printf '        (normal over DisplayPort). Writes land but cannot be read back,\n'
                printf '        so bd-apply logs those as "dispatched" rather than "verified".\n'
            fi
        elif [[ "$probe" =~ ^-?[0-9]*\.?[0-9]+$ ]]; then
            printf '  %-5s tagID=%-5s OK (hardwareBrightness=%s)\n' "$name" "$tag" "$probe"
        else
            printf '  %-5s tagID=%-5s OK — registered, but DDC did not answer (monitor asleep?)\n' \
                "$name" "$tag"
        fi
    done

    if (( rc != 0 )); then
        printf '\nLive displays:\n'
        bd get --identifiers 2>/dev/null | grep -E '"(name|tagID)"' | sed 's/^/  /'
        printf '\nFix: set DOTFILES_BD_{DEV,PORT}_TAG in ~/.config/dotfiles/personal.env\n'
    fi

    # Stray app instances left behind by a hung CLI call. Not fatal to DDC, but
    # they duplicate the menu-bar icon and read as "multiple installations".
    local strays
    strays="$(bd_stray_instances)"
    if [[ -n "$strays" ]]; then
        printf '\nStray BetterDisplay instances (a CLI call that never exited):\n%s' "$strays"
        printf 'These are extra copies of the ONE app in /Applications, not extra installs.\n'
        printf 'Clear with: pkill -f "BetterDisplay/Contents/MacOS/BetterDisplay version"\n'
        printf 'Avoid by never running `betterdisplaycli version` — it hangs. Use:\n'
        printf '  bd-apply.sh doctor   (reports the version from Info.plist)\n'
        rc=1
    fi

    # Homebrew vs. on-disk skew. Sparkle updates the bundle in place, so brew
    # keeps believing the version it installed — and `brew upgrade`/`reinstall
    # --cask betterdisplay` would then DOWNGRADE a Sparkle-updated app onto the
    # cask's older build. Worth knowing before reaching for a brew-based repair.
    local app_ver cask_ver
    app_ver="$(bd_app_version)"
    # Glob rather than `ls | grep`: the Caskroom holds one directory per
    # installed version, so iterating entries and keeping the last
    # version-looking basename gives the same answer without parsing ls output.
    cask_ver=""
    local _cask_dir
    for _cask_dir in /opt/homebrew/Caskroom/betterdisplay/*; do
        [[ -e "$_cask_dir" ]] || continue          # unmatched glob stays literal
        _cask_dir="${_cask_dir##*/}"
        [[ "$_cask_dir" == [0-9]* ]] && cask_ver="$_cask_dir"
    done
    printf '\nVersions: app=%s (Info.plist)  homebrew-cask=%s\n' "${app_ver:-?}" "${cask_ver:-none}"
    if [[ -n "$app_ver" && -n "$cask_ver" && "$app_ver" != "$cask_ver" ]]; then
        printf '  NOTE skew — the app self-updated via Sparkle. `brew reinstall --cask\n'
        printf '  betterdisplay` would DOWNGRADE %s -> %s. Not an error; just do not\n' "$app_ver" "$cask_ver"
        printf '  reach for brew as a repair unless you mean to roll back.\n'
    fi

    return $rc
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
    # Brightness/contrast are read from the PANEL over raw DDC, never from
    # `--hardwareBrightness`. That abstraction reports BD's own cache: setting it
    # to 30% makes `get` answer 0.3 while the panel's real VCP luminance sits
    # unchanged (measured 2026-07-29 — panel held 85 across a 30%/100% round
    # trip). Verifying against that cache is how this command reported a
    # confident "all values match intent" through a control path that had not
    # touched the display in days. Raw VCP is the display's own answer.
    #
    # Values arrive as 0..100 integers; normalise to the 0..1 float the rest of
    # this function compares against. A panel that does not answer reads (the
    # DisplayPort case) yields `?`, which surfaces as a mismatch rather than a
    # false pass — "cannot verify" must never render as "ok".
    cur_port_b=""   # no trustworthy DDC readback on this panel — see set_port_vcp
    cur_port_c=""   # no trustworthy DDC readback on this panel — see set_port_vcp
    [[ "$cur_port_b" =~ ^[0-9]+$ ]] && cur_port_b="$(awk -v v="$cur_port_b" 'BEGIN{printf "%.2f", v/100}')" || cur_port_b='?'
    [[ "$cur_port_c" =~ ^[0-9]+$ ]] && cur_port_c="$(awk -v v="$cur_port_c" 'BEGIN{printf "%.2f", v/100}')" || cur_port_c='?'
    # temperature is a SOFTWARE colour-table control applied by BD itself, so its
    # readback is genuine and stays on the abstraction.
    cur_port_t="$(bd get --tagID="$PORT_TAG" --temperature 2>/dev/null || echo ?)"

    # BD reports brightness/contrast as 0..1 float, temperature as ±0..1.
    # Convert intent percent → expected float for comparison.
    local exp_dev_sw exp_port_b exp_port_c exp_port_t
    exp_dev_sw="$(awk -v p="$dev_pct"  'BEGIN{printf "%.2f", p/100}')"
    # Dell contrast + temperature are pinned to the color-reference values on
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

    # UNVERIFIABLE is not DRIFT. Over DisplayPort this panel accepts DDC writes but
    # answers no reads, so there is nothing to compare — reporting that as drift
    # would make `verify` fail permanently on the CORRECT daily setup and train the
    # operator to ignore it, the same cry-wolf trap already fixed in doctor. Only a
    # value we actually read and that actually disagrees sets drift.
    if [[ -z "$cur_port_b" || "$cur_port_b" == '?' ]]; then
        printf '  %-22s expect=%-8s actual=%-8s %s\n' "PORT hardwareBrightness" \
            "$exp_port_b" "unread" "UNVERIFIABLE (no DDC readback)"
    else
        st=ok; diff_ok "$exp_port_b" "$cur_port_b" >/dev/null || { st=DRIFT; drift=1; }
        printf '  %-22s expect=%-8s actual=%-8s %s\n' "PORT hardwareBrightness" \
            "$exp_port_b" "$cur_port_b" "$st"
    fi

    if [[ -z "$cur_port_c" || "$cur_port_c" == '?' ]]; then
        printf '  %-22s expect=%-8s actual=%-8s %s\n' "PORT hardwareContrast" \
            "$exp_port_c" "unread" "UNVERIFIABLE (no DDC readback)"
    else
        st=ok; diff_ok "$exp_port_c" "$cur_port_c" >/dev/null || { st=DRIFT; drift=1; }
        printf '  %-22s expect=%-8s actual=%-8s %s\n' "PORT hardwareContrast" \
            "$exp_port_c" "$cur_port_c" "$st"
    fi

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

    (( drift == 0 )) && echo $'\nall READABLE values match intent.' && return 0
    echo $'\ndrift detected — re-apply or investigate.' >&2
    return 1
}

# diff_ok <expected> <actual> — tolerate 0.02 float jitter (BD rounds at 2dp).
diff_ok() {
    awk -v a="$1" -v b="$2" 'BEGIN{ d=a-b; if(d<0)d=-d; exit (d<=0.02)?0:1 }' && echo ok
}

main() {
    local arg="${1:-}"
    resolve_port_tag
    if [[ -z "$arg" ]]; then
        echo "usage: $(basename "$0") <mode>"
        echo "modes:    dawn day afternoon evening night meeting read stream cinema"
        echo "commands: status verify doctor"
        exit 1
    fi

    case "$arg" in
        status) print_status; return 0 ;;
        verify) verify_mode ;;
        doctor) doctor ;;
        *) apply_mode "$arg" ;;
    esac
}

# Run main only when executed directly. bd-cycle.sh sources this file for the
# MODES / ORDER tables and must not apply a mode as a side effect of sourcing.
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
