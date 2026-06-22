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
DP="$(command -v displayplacer || echo /opt/homebrew/bin/displayplacer)"

# --- wake trace (persistent; /tmp is cleared at boot, ~/.cache survives) -------
# Records what fired on each wake so a missed re-apply can be pinned to a DarkWake
# (panels still off the DDC bus -> betterdisplaycli/displayplacer no-op yet exit 0)
# vs. a too-short settle wait. Diagnostic only; every call is best-effort and must
# never block the load-bearing brightness re-apply. In-place truncate at 512K to
# preserve the inode (same idiom as display-restore.sh).
WLOG="$HOME/.cache/bd-wake.log"
wlog() {
  [ -f "$WLOG" ] && [ "$(wc -c <"$WLOG" 2>/dev/null || echo 0)" -gt 524288 ] && : > "$WLOG"
  printf '[%s] %s\n' "$(date '+%F %T')" "$*" >> "$WLOG" 2>/dev/null || true
}
# How many displays are enumerated + the most recent power event — together these
# reveal whether the panels were actually awake when sleepwatcher fired the hook.
dcount()  { "$DP" list 2>/dev/null | grep -c 'Persistent screen id:'; }
last_pm() { pmset -g log 2>/dev/null | grep -E 'DarkWake (from|to)|Wake from|Entering Sleep state' | tail -1 | sed -E 's/  +/ /g'; }

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
wlog "WAKE fired | displays=$(dcount) | last-pm:$(last_pm)"
sleep 5
profile=daily
[[ -r "$PROFILE_FILE" ]] && profile="$(cat "$PROFILE_FILE" 2>/dev/null)"
[[ "$profile" =~ ^(daily|stream|hires|native|portrait)$ ]] || profile=daily
restore_rc=na
if [[ -x "$RESTORE" ]]; then "$RESTORE" --"$profile" >/dev/null 2>&1; restore_rc=$?; fi
wlog "  post-restore profile=$profile restore_rc=$restore_rc displays=$(dcount)"

if [[ ! -r "$STATE_FILE" ]]; then
    echo "no state — defaulting to day"
    wlog "  no bd-state — applying day"
    exec env BD_SOURCE=wake "$APPLY" day
fi

mode="$(cut -d'|' -f1 "$STATE_FILE")"
[[ -z "$mode" ]] && mode=day

for attempt in 1 2 3; do
    if BD_SOURCE=wake "$APPLY" "$mode"; then
        wlog "  bd-apply mode=$mode result=ok attempt=$attempt displays=$(dcount)"
        exit 0
    fi
    wlog "  bd-apply mode=$mode result=FAIL attempt=$attempt"
    sleep $(( attempt * 5 ))
done
wlog "  bd-apply mode=$mode result=gave-up after 3 attempts"
exit 1
