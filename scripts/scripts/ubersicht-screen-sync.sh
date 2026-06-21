#!/usr/bin/env bash
# ubersicht-screen-sync.sh — keep the Übersicht dashboard pinned to the external
# (Samsung) monitor even when its NSScreenNumber drifts.
#
# Übersicht's "show on selected screens" keys on the live NSScreenNumber, which is
# NOT stable on this rig: it drifted 5 -> 3 during display-profile switches, which
# silently hid the whole dashboard (the selected id no longer matched any screen).
# This re-resolves the current external screen number and rewrites WidgetSettings.json,
# then relaunches Übersicht ONLY when the number actually changed (cheap no-op
# otherwise). The 4 built-in widgets use showOnMainScreen, which is stable (index 0),
# so they're left alone.
#
# Wired into the display-change flow (display-restore.sh runs it best-effort after an
# apply; bd-wake.sh covers it via display-restore on wake). Safe to run manually.

set -u

SETTINGS="$HOME/Library/Application Support/tracesOf.Uebersicht/WidgetSettings.json"
APP="/Applications/Übersicht.app"
LOG="/tmp/ubersicht-screen-sync.log"
log() {
  [ -f "$LOG" ] && [ "$(wc -c <"$LOG" 2>/dev/null || echo 0)" -gt 1048576 ] && : > "$LOG"
  printf '[%s] %s\n' "$(date '+%F %T')" "$*" >> "$LOG"
}

[ -r "$SETTINGS" ] || { log "no WidgetSettings.json — skip"; exit 0; }

# Widgets that stay on the built-in (main) display. Everything else is dashboard.
BUILTIN_WIDGETS="focus-widget-index-jsx drift-warden-widget-index-jsx today-focus-widget-index-jsx clock-widget-index-jsx"

# Current external (non-builtin) NSScreenNumber — the value Übersicht keys on.
EXT="$(swift - <<'SW' 2>/dev/null
import AppKit
for s in NSScreen.screens {
  let n = (s.deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")] as? NSNumber)?.uint32Value ?? 0
  if CGDisplayIsBuiltin(n) == 0 { print(n); break }
}
SW
)"
if [[ -z "${EXT// }" ]]; then log "no external display connected — leaving settings as-is"; exit 0; fi

# Compute the desired settings; write a tmp copy + report whether anything changed.
# Read-only on the live file so a running Übersicht can't be clobbered mid-write.
result="$(BUILTIN="$BUILTIN_WIDGETS" EXT="$EXT" TMP="$SETTINGS.sync.tmp" python3 - "$SETTINGS" <<'PY'
import json, os, sys
p = sys.argv[1]
builtin = set(os.environ["BUILTIN"].split())
ext = int(os.environ["EXT"])
d = json.load(open(p))
changed = False
for k, v in d.items():
    if k.startswith("-"):
        continue
    if k in builtin:
        if not v.get("showOnMainScreen") or v.get("showOnAllScreens") or v.get("showOnSelectedScreens"):
            v.update(showOnAllScreens=False, showOnMainScreen=True, showOnSelectedScreens=False, screens=[]); changed = True
    else:
        if v.get("screens") != [ext] or not v.get("showOnSelectedScreens"):
            v.update(showOnAllScreens=False, showOnMainScreen=False, showOnSelectedScreens=True, screens=[ext]); changed = True
if changed:
    json.dump(d, open(os.environ["TMP"], "w"))
print("changed" if changed else "nochange")
PY
)"

if [[ "$result" == changed ]]; then
  # Übersicht reads WidgetSettings.json only at launch and rewrites it on quit, so
  # SIGKILL it (no save-on-quit clobber), swap in the new file, relaunch.
  pkill -9 -f 'Uebersicht' 2>/dev/null
  sleep 1
  mv -f "$SETTINGS.sync.tmp" "$SETTINGS"
  open -gj "$APP" 2>/dev/null
  log "external=$EXT — dashboard re-pinned to screens:[$EXT], Übersicht relaunched"
else
  rm -f "$SETTINGS.sync.tmp" 2>/dev/null
  log "external=$EXT — already correct, no-op"
fi
