#!/usr/bin/env bash
# aerospace-resweep.sh — re-apply the on-window-detected routing rules to windows
# that are ALREADY open.
#
# Why this is needed: AeroSpace's `on-window-detected` fires once, when a window
# is first detected. It correctly routes an app you launch now. It does NOT
# retroactively move windows that were already open when a rule was added or
# changed, and it cannot help windows that macOS restores at login before
# AeroSpace has finished starting. Both leave apps sitting in the wrong
# workspace with no error anywhere — the config looks right and the screen
# disagrees.
#
# This reads the SAME rules out of the rendered aerospace.toml (never a second
# hardcoded copy of the mapping) and moves any misplaced window to where the
# config says it belongs.
#
# Usage:
#   aerospace-resweep.sh              # apply
#   aerospace-resweep.sh --dry-run    # show what would move, change nothing
#
# Safe to run any time; it is a no-op when everything is already correct.

set -u

[ -f "$HOME/.config/dotfiles/personal.env" ] && source "$HOME/.config/dotfiles/personal.env"
DOTFILES_DIR="${DOTFILES_DIR:-$HOME/dotfiles}"
CONFIG="$DOTFILES_DIR/aerospace/.config/aerospace/aerospace.toml"

DRY=false
[[ "${1:-}" == "--dry-run" ]] && DRY=true

command -v aerospace >/dev/null 2>&1 || { echo "aerospace not found" >&2; exit 127; }
[[ -r "$CONFIG" ]] || { echo "rendered config not readable at $CONFIG" >&2; exit 1; }

# Extract app-id -> workspace from the rendered config's on-window-detected
# blocks. Only rules that actually name a workspace are collected; pure
# `layout floating` rules (1Password, Docker, OrbStack, ...) are deliberately
# skipped — those apps are meant to live wherever they are opened.
#
# A block looks like:
#   [[on-window-detected]]
#   if.app-id = 'com.foo.bar'
#   run = ['layout tiling', 'move-node-to-workspace X']
# so we remember the last app-id seen and emit when a move target appears.
MAP="$(awk '
  /^\[\[on-window-detected\]\]/ { app=""; next }
  /^if\.app-id/                 { gsub(/.*= *.|.$/, "", $0); app=$0; next }
  /move-node-to-workspace/ {
      if (app != "") {
          match($0, /move-node-to-workspace [A-Za-z0-9]+/)
          ws = substr($0, RSTART+23, RLENGTH-23)
          print app "\t" ws
          app=""
      }
  }
' "$CONFIG")"

[[ -z "$MAP" ]] && { echo "no workspace-routing rules found in $CONFIG" >&2; exit 1; }

# One listing of every window with its bundle id, rather than one aerospace call
# per rule. `--all` is an alias that CONFLICTS with the filtering flags, so the
# per-app form needs `--monitor all` — and its error goes to stderr, which an
# earlier draft of this script swallowed with 2>/dev/null and silently swept
# nothing while reporting success. stderr is deliberately NOT suppressed here.
WINDOWS="$(aerospace list-windows --monitor all \
             --format '%{window-id}	%{workspace}	%{app-bundle-id}')" || {
    echo "failed to list windows" >&2; exit 1; }

moved=0 checked=0
while IFS=$'\t' read -r wid cur_ws bundle; do
    [[ -z "$wid" || -z "$bundle" ]] && continue
    want_ws="$(awk -F'\t' -v b="$bundle" '$1==b {print $2; exit}' <<< "$MAP")"
    # No routing rule, or a float-only rule: leave the window where it is.
    [[ -z "$want_ws" ]] && continue
    checked=$((checked + 1))
    [[ "$cur_ws" == "$want_ws" ]] && continue
    if $DRY; then
        printf '  would move %-6s %-38s %s -> %s\n' "$wid" "$bundle" "$cur_ws" "$want_ws"
    else
        if aerospace move-node-to-workspace --window-id "$wid" "$want_ws"; then
            printf '  moved %-6s %-38s %s -> %s\n' "$wid" "$bundle" "$cur_ws" "$want_ws"
        else
            printf '  FAILED %-6s %-38s -> %s\n' "$wid" "$bundle" "$want_ws" >&2
        fi
    fi
    moved=$((moved + 1))
done <<< "$WINDOWS"

if [[ "$moved" -eq 0 ]]; then
    echo "resweep: $checked window(s) checked, all already on the right workspace"
else
    $DRY && echo "resweep (dry-run): $moved of $checked window(s) would move" \
         || echo "resweep: moved $moved of $checked window(s)"
fi

# --- Orientation ------------------------------------------------------------
# A workspace's root container orientation is chosen ONCE, when the container is
# created, from `default-root-container-orientation = 'auto'`. It is NOT
# re-evaluated when the workspace later moves to a different monitor — so every
# workspace that migrated from the wide built-in to the rotated panel kept its
# horizontal layout and tiled side-by-side on a 1440px-wide screen. Measured on
# 2026-07-28: workspace M read `h_tiles` while sitting on PORTRAIT-MONITOR.
#
# Enforce the intent instead of trusting 'auto': tall monitor -> v_tiles
# (stacked), wide monitor -> h_tiles (side-by-side).
#
# Monitor shape comes from displayplacer, with the built-in identified by its
# "MacBook built in screen" type — the same detection display-restore.sh uses and
# that is already proven on this rig. Unambiguous for a two-monitor setup; on 3+
# monitors the external match is by elimination and may need revisiting.
DP="$(command -v displayplacer || echo /opt/homebrew/bin/displayplacer)"
[[ -x "$DP" ]] || { echo "orientation: displayplacer not found, skipping" >&2; exit 0; }

DP_LIST="$("$DP" list 2>/dev/null)"
# "<is-builtin> <width> <height>" per screen, in displayplacer's listing order.
SHAPES="$(awk '
  /^Type:/       { builtin = (/MacBook built in/) ? 1 : 0 }
  /^Resolution:/ { split($2, r, "x"); print builtin, r[1], r[2] }
' <<< "$DP_LIST")"

builtin_tall=""; external_tall=""
while read -r is_builtin w h; do
    [[ -z "$w" || -z "$h" ]] && continue
    tall=$(( h > w ? 1 : 0 ))
    if [[ "$is_builtin" == "1" ]]; then builtin_tall="$tall"
    elif [[ -z "$external_tall" ]]; then external_tall="$tall"; fi
done <<< "$SHAPES"

fixed=0
while IFS=$'\t' read -r ws mon cur_layout; do
    [[ -z "$ws" ]] && continue
    case "$mon" in
        *"Built-in"*|*"built in"*) tall="$builtin_tall" ;;
        *)                         tall="$external_tall" ;;
    esac
    [[ -z "$tall" ]] && continue
    want=$([[ "$tall" == "1" ]] && echo vertical || echo horizontal)
    have=$([[ "$cur_layout" == v_tiles ]] && echo vertical || echo horizontal)
    [[ "$want" == "$have" ]] && continue
    if $DRY; then
        printf '  would set %-3s (%s) %s -> %s\n' "$ws" "$mon" "$have" "$want"
    else
        aerospace layout --workspace "$ws" --root "$want" \
            && printf '  set %-3s (%s) %s -> %s\n' "$ws" "$mon" "$have" "$want"
    fi
    fixed=$((fixed + 1))
done < <(aerospace list-windows --monitor all \
           --format '%{workspace}	%{monitor-name}	%{workspace-root-container-layout}' \
         | sort -u)

if [[ "$fixed" -eq 0 ]]; then
    echo "orientation: every workspace already matches its monitor's shape"
else
    $DRY && echo "orientation (dry-run): $fixed workspace(s) would change" \
         || echo "orientation: corrected $fixed workspace(s)"
fi
