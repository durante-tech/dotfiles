#!/usr/bin/env bash

# OBS popup control actions. Invoked as:
#   obs_action.sh <refresh|rec|stream|marker|open>
# Uses the same obs WebSocket CLI as plugins/obs.sh.
source "$CONFIG_DIR/colors.sh"

OBS_BIN="$(command -v obs || echo "$HOME/scripts/obs")"
RESTORE="$HOME/dotfiles/scripts/scripts/display-restore.sh"
ACTION="$1"

have_obs() { command -v obs >/dev/null 2>&1 || [ -x "$OBS_BIN" ]; }
rec_active()    { "$OBS_BIN" rec status    2>/dev/null | tr -d ' ' | grep -q '"outputActive":true'; }
stream_active() { "$OBS_BIN" stream status 2>/dev/null | tr -d ' ' | grep -q '"outputActive":true'; }

refresh_header() {
    if ! have_obs; then
        sketchybar --set obs.status label="obs CLI not available" label.color="$GREY"
        return
    fi
    local rstate sstate
    if rec_active;    then rstate="REC";  else rstate="idle";    fi
    if stream_active; then sstate="LIVE"; else sstate="offline"; fi
    sketchybar --set obs.status label="Recording: ${rstate} · Stream: ${sstate}" label.color="$WHITE"
}

case "$ACTION" in
    refresh)
        refresh_header
        ;;
    rec)
        have_obs && "$OBS_BIN" rec toggle >/dev/null 2>&1
        sleep 0.3; refresh_header
        ;;
    stream)
        if have_obs; then
            # Capture pre-toggle state, then invert — more reliable than racing
            # OBS's post-toggle handshake before re-reading status.
            was_live=offline; stream_active && was_live=live
            "$OBS_BIN" stream toggle >/dev/null 2>&1
            # Match display geometry to the new stream state (backgrounded so the
            # sketchybar action returns fast; displayplacer takes a beat):
            #   going LIVE    -> 1728x1080 (clean OBS 2:1 capture to 1080 canvas)
            #   going offline -> 1728x1117 (true-2x sharp daily)
            if [ "$was_live" = offline ]; then
                "$RESTORE" --stream --force >/dev/null 2>&1 &
            else
                "$RESTORE" --force >/dev/null 2>&1 &
            fi
        fi
        sleep 0.3; refresh_header
        ;;
    marker)
        have_obs && "$OBS_BIN" marker >/dev/null 2>&1
        sketchybar --set obs popup.drawing=off
        ;;
    open)
        open -a OBS
        sketchybar --set obs popup.drawing=off
        ;;
esac
