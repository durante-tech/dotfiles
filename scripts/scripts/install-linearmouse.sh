#!/usr/bin/env bash
# install-linearmouse.sh — install LinearMouse PINNED to v0.11.2.
#
# WHY PINNED (do not "upgrade" this):
#   Upstream PR #1209 ("Fix config hot reload after directory recreation",
#   merged 2026-05-25) replaced LinearMouse's config DispatchSource watchers
#   with a generic FSEvents FileWatcher and, in its own words, "watch stable
#   parent roots". Those roots are /, /Users, $HOME, $HOME/.config and
#   $HOME/Library — so FSEvents now fires on activity ANYWHERE in $HOME, and
#   the callback costs a readlink plus a full _SwiftURL/RFC3986 reparse per
#   event. On a machine with a busy home directory this pegs a core.
#
#   Measured 2026-08-11, identical 3000-file create+delete load in $HOME:
#     v0.11.2 (pre-#1209)   peak   1%   watches / and ~/.config/linearmouse
#     v0.11.4 (has #1209)   peak  92%   watches $HOME and parents
#     v0.12.0-beta.4        peak  99%   watches $HOME and parents
#
#   v0.11.2 is the last release before #1209 AND still carries the earlier
#   CPU fixes (upstream #1168 / #1185, landed in 0.11.2). v0.11.3 is the
#   first release carrying the regression. Tracked upstream as issue #1368
#   ("High CPU usage in LinearMouse 0.11.4 due to broad FSEvents
#   configuration watches", opened 2026-08-19 by a third party, still open,
#   no linked PR; v0.11.4 of 2026-08-02 is still the newest stable). Do NOT
#   open a second issue for this — add this repo's measurements to #1368 —
#   and re-check #1368 plus the release list before lifting the pin.
#
#   Casks cannot be `brew pin`ned, which is why linearmouse is commented out
#   in the Brewfile and installed here instead. `brew install --cask
#   linearmouse` or `brew bundle` WILL reinstall 0.11.4 and bring the
#   regression back.
#
# Usage: install-linearmouse.sh [--force]

set -eu

PINNED_VERSION="0.11.2"
DMG_URL="https://github.com/linearmouse/linearmouse/releases/download/v${PINNED_VERSION}/LinearMouse.dmg"
APP="/Applications/LinearMouse.app"

FORCE=false
[ "${1:-}" = "--force" ] && FORCE=true

installed_version() {
    [ -d "$APP" ] || return 1
    defaults read "$APP/Contents/Info.plist" CFBundleShortVersionString 2>/dev/null
}

current="$(installed_version || echo none)"

# Pinning the bundle is not enough on its own: LinearMouse embeds Sparkle
# (Contents/Frameworks/Sparkle.framework, SUFeedURL =
# https://linearmouse.app/appcast.xml, SUScheduledCheckInterval = 604800) and
# this machine was found with SUAutomaticallyUpdate = 1 and
# SUEnableAutomaticChecks = 1 — i.e. Sparkle would download and install 0.11.4
# unattended on its next weekly check, silently reinstating #1209 and undoing
# the whole point of this script. Disarm it on EVERY run, above the
# "already pinned" early exit, so a machine already sitting on 0.11.2 still
# gets the auto-updater turned off.
defaults write com.lujjjh.LinearMouse SUEnableAutomaticChecks -bool false
defaults write com.lujjjh.LinearMouse SUAutomaticallyUpdate -bool false

if [ "$current" = "$PINNED_VERSION" ] && [ "$FORCE" = false ]; then
    echo "LinearMouse $PINNED_VERSION already installed (pinned) — nothing to do."
    # ...except start it if it is not running. The stowed config is inert
    # while the app is down, and nothing in this repo launches it (there is no
    # com.lucas.linearmouse LaunchAgent), so the package can look fully
    # deployed — live stow link, correct pinned bundle, VERIFY.md check green —
    # while delivering no pointer or scrolling settings at all.
    pgrep -f "MacOS/LinearMouse" >/dev/null 2>&1 || open -a "$APP"
    exit 0
fi

if [ "$current" != "none" ]; then
    echo "Found LinearMouse $current — replacing with pinned $PINNED_VERSION"
fi

tmpdir="$(mktemp -d)"
# shellcheck disable=SC2064  # expand tmpdir now, not at trap time
trap "rm -rf '$tmpdir'" EXIT

echo "Downloading LinearMouse $PINNED_VERSION..."
curl -fsSL -o "$tmpdir/LinearMouse.dmg" "$DMG_URL"

echo "Mounting..."
mnt="$(hdiutil attach "$tmpdir/LinearMouse.dmg" -nobrowse -readonly | awk '/\/Volumes/{print $NF; exit}')"
if [ -z "$mnt" ]; then
    echo "Failed to mount DMG" >&2
    exit 1
fi

# Quit a running instance so the bundle can be replaced cleanly.
osascript -e 'quit app "LinearMouse"' 2>/dev/null || true
sleep 2
pkill -f "MacOS/LinearMouse" 2>/dev/null || true
sleep 1

rm -rf "$APP"
cp -R "$mnt/LinearMouse.app" "$APP"
hdiutil detach "$mnt" -quiet
xattr -dr com.apple.quarantine "$APP" 2>/dev/null || true

got="$(installed_version || echo none)"
if [ "$got" != "$PINNED_VERSION" ]; then
    echo "Version check FAILED: expected $PINNED_VERSION, got $got" >&2
    exit 1
fi

# Start it. Without this a fresh install ends with the app on disk but not
# running, which means the stowed linearmouse.json has no effect at all.
open -a "$APP"

echo "Installed LinearMouse $got (pinned, Sparkle auto-update disabled)."
echo "Grant Accessibility permission on first launch if prompted."
