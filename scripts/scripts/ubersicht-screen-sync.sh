#!/usr/bin/env bash
# Synchronize only widgets in the currently deployed dotfiles widget directory.
set -u
[ -f "$HOME/.config/dotfiles/personal.env" ] && source "$HOME/.config/dotfiles/personal.env"
DOTFILES_DIR="${DOTFILES_DIR:-$HOME/dotfiles}"
SETTINGS="$HOME/Library/Application Support/tracesOf.Uebersicht/WidgetSettings.json"
DEPLOYED="$HOME/Library/Application Support/Übersicht/widgets"
SOURCE="$DOTFILES_DIR/ubersicht/Library/Application Support/Übersicht/widgets"
HELPER="${BASH_SOURCE[0]%/*}/lib/widget-settings.py"
APP="/Applications/Übersicht.app"
log() { printf 'Übersicht sync: %s\n' "$*" >&2; }

python3 "$HELPER" verify "$SOURCE" "$DEPLOYED" || exit 0
[[ -r "$SETTINGS" ]] || { log "no settings; skipping"; exit 0; }
# This helper never removes another invocation's lock.
LOCK="${SETTINGS}.dotfiles-lock"
mkdir "$LOCK" 2>/dev/null || { log "another sync holds the lock; skipping"; exit 0; }
trap 'rmdir "$LOCK" 2>/dev/null' EXIT
EXT=$(swift - <<'SW' 2>/dev/null
import AppKit
for s in NSScreen.screens {
  let n = (s.deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")] as? NSNumber)?.uint32Value ?? 0
  if CGDisplayIsBuiltin(n) == 0 { print(n); break }
}
SW
)
[[ "$EXT" =~ ^[0-9]+$ ]] || { log "external screen unavailable; skipping"; exit 0; }
result=$(python3 "$HELPER" check "$SOURCE" "$DEPLOYED" "$SETTINGS" "$EXT") || exit 1
[[ "$result" == changed ]] || exit 0
# Bundle metadata supplies the exact executable spelling (including Unicode).
PROCESS=$(python3 -c 'import plistlib,sys; print(plistlib.load(open(sys.argv[1], "rb"))["CFBundleExecutable"])' "$APP/Contents/Info.plist" 2>/dev/null) || {
    log "application identity unavailable; settings unchanged"; exit 0;
}
[[ -n "$PROCESS" ]] || { log "empty application identity; settings unchanged"; exit 0; }
was_running=false
if pgrep -x "$PROCESS" >/dev/null; then
    was_running=true
    # Apple events have a bounded timeout; never force termination.
    osascript <<'AS' >/dev/null 2>&1
with timeout of 5 seconds
    tell application id "tracesOf.Uebersicht" to quit
end timeout
AS
    for ((i=0; i<5; i++)); do
        pgrep -x "$PROCESS" >/dev/null || break
        sleep 1
    done
    if pgrep -x "$PROCESS" >/dev/null; then
        log "application did not quit cleanly; settings unchanged"
        exit 0
    fi
fi
# Read again AFTER quit: Übersicht may save preferences during shutdown.
python3 "$HELPER" apply "$SOURCE" "$DEPLOYED" "$SETTINGS" "$EXT"
result=$?
if $was_running; then open -gj "$APP" || result=1; fi
exit "$result"
