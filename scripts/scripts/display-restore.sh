#!/usr/bin/env bash
# display-restore.sh — re-assert the canonical monitor layout (resolution,
# rotation, origin) via displayplacer.
#
# Display reconfigurations silently wreck this layout: sleep/wake drops the
# built-in to a wide scaled mode (so the OBS capture goes small + soft) and a
# monitor or BetterDisplay virtual-screen connect/disconnect knocks the external
# out of its rotation. This restores the known-good layout so daily work stays
# true-2x sharp (built-in "looks like 1728x1117", backing == native 3456x2234;
# external "looks like 1920x1080" landscape, backing == native 3840x2160 — zero
# scaling). The --stream profile swaps the built-in
# to "looks like 1728x1080" so the OBS capture is a clean 2:1 downscale to a
# 1080 canvas (height == OBS canvas) for the duration of a stream.
#
# Idempotent by default: only calls displayplacer when the live layout has
# drifted from target, because a redundant apply can itself flicker / disturb the
# window manager. --force applies unconditionally.
#
# Usage: display-restore.sh [--daily | --stream | --hires | --native | --portrait | --solo] [--force | --dry-run]
#   --daily   : explicit alias for the default (built-in 1728x1117 + Samsung 1920x1080).
#   --stream  : built-in at 1728x1080 (OBS-clean 2:1). Default is 1728x1117 (sharp).
#   --hires   : Samsung external at 2560x1440 HiDPI (~78% more desktop area, stays
#               retina-scaled). Default is 1920x1080 true integer-2x (sharpest).
#   --native  : BOTH panels at 1x native (built-in 3456x2234, Samsung 3840x2160),
#               scaling:off — pixel-perfect 1:1, zero scaling, but UI renders tiny.
#   --portrait: Samsung rotated 90 to true-2x 1080x1920 portrait (backing 2160x3840
#               == native — pixel-perfect, 1920px of crisp vertical space).
#   --solo    : single-display / clamshell — drive the ONLY connected display at
#               2560x1440 HiDPI landscape (override: DOTFILES_DISPLAY_SOLO_RES).
#               UUID is detected live, so this works for any external 4K panel.
#
# Every profile detects its screen ids live (built-in by displayplacer's
# "MacBook built in screen" type, external by elimination) — no UUID is pinned,
# so a redock that renumbers a persistent id cannot silently disable a profile.
# A two-screen profile run in clamshell drops the absent built-in and applies
# its external half at the origin.
#               Bare laptop (single display == built-in): applies the canonical
#               built-in true-2x 1728x1117@120 instead. With >1 display
#               connected it FALLS BACK to the daily layout (so a bd-profile
#               cached as 'solo' can never disable wake restore after
#               re-docking). Note: --solo ignores DOTFILES_DISPLAY_LAYOUT —
#               that override describes a fixed multi-screen topology.
#
# Personal override (~/.config/dotfiles/personal.env): display UUIDs are
# machine-specific, so override the WHOLE layout there as a newline-separated
# string of displayplacer per-screen specs:
#   DOTFILES_DISPLAY_LAYOUT='id:AAAA res:... origin:(0,0) degree:0
#   id:BBBB res:... origin:(...) degree:90'

set -u
[ -f "$HOME/.config/dotfiles/personal.env" ] && source "$HOME/.config/dotfiles/personal.env"

DP="$(command -v displayplacer || echo /opt/homebrew/bin/displayplacer)"
LOG="/tmp/display-restore.log"
# In-place truncate at 1MB (never mv/gzip — that swaps the inode and breaks any
# running `>>` redirect or launchd StandardOutPath fd pointed at this file).
log() {
  [ -f "$LOG" ] && [ "$(wc -c <"$LOG" 2>/dev/null || echo 0)" -gt 1048576 ] && : > "$LOG"
  printf '[%s] %s\n' "$(date '+%F %T')" "$*" >> "$LOG"
}

# Profile: daily (default) drives the built-in at true integer-2x (1728x1117 →
# backing == native 3456x2234, zero scaling, sharpest). --stream drops it to
# 1728x1080 so the OBS screen capture is a clean 2:1 downscale to a 1080 canvas.
# The external stays true-2x landscape 1920x1080 (backing == native 3840x2160)
# centered ABOVE the built-in in both profiles. Action flags (--force/--dry-run)
# compose with --stream.
PROFILE=daily
ACTION=""
for a in "$@"; do
  case "$a" in
    --daily)           PROFILE=daily ;;
    --stream)          PROFILE=stream ;;
    --hires)           PROFILE=hires ;;
    --native)          PROFILE=native ;;
    --portrait)        PROFILE=portrait ;;
    --solo)            PROFILE=solo ;;
    --force|--dry-run) ACTION="$a" ;;
  esac
done

# Caller attribution (diagnostic) — record WHO invoked us and with which profile,
# so an unexpected layout flip can be traced to its trigger in this same log.
# Best-effort; the parent's command is truncated to keep the line bounded.
log "invoked profile=$PROFILE action=${ACTION:-none} ppid=$PPID caller=[$(ps -o command= -p "$PPID" 2>/dev/null | head -c 140)]"

# Built-in resolution per profile. --native runs 1x native 3456x2234 (scaling:off,
# pixel-perfect 1:1, UI renders tiny); --stream drops to 1728x1080 for a clean OBS
# 2:1 downscale; daily + hires keep the sharp true integer-2x 1728x1117. SCALING is
# shared by both panels: off only for --native, on otherwise.
SCALING=on
if [[ "$PROFILE" == native ]]; then
  BUILTIN_RES=3456x2234; SCALING=off
elif [[ "$PROFILE" == stream ]]; then
  BUILTIN_RES=1728x1080
else
  BUILTIN_RES=1728x1117
fi

# External Samsung 4K resolution + origin per profile. daily/stream run true
# integer-2x (1920x1080 logical, backing == native 3840x2160 — sharpest). --hires
# drives it at 2560x1440 HiDPI: ~78% more desktop area, still retina-scaled, with a
# slight non-integer softness (5120x2880 supersampled down to the 3840x2160 panel).
# --native runs 1x native 3840x2160 (scaling:off, pixel-perfect 1:1, UI tiny).
# --portrait rotates the Samsung 90 to true-2x 1080x1920 (res:1920x1080 degree:90,
# backing 2160x3840 == native — pixel-perfect, 1920px crisp vertical). EXT_DEGREE
# carries the rotation (0 for every landscape profile, 90 for portrait).
# Origin places the Samsung to the RIGHT of the built-in for the landscape profiles
# (operator arrangement 2026-06-30): left = builtinWidth (edges touch), top = +37.
# daily/stream/hires keep builtinWidth=1728; native is 1x so builtinWidth=3456.
# --portrait is the exception — it still stacks the rotated panel ABOVE at (324,-1920).
EXT_DEGREE=0
if [[ "$PROFILE" == native ]]; then
  EXT_RES=3840x2160; EXT_ORIGIN='(3456,37)'
elif [[ "$PROFILE" == hires ]]; then
  EXT_RES=2560x1440; EXT_ORIGIN='(1728,37)'
elif [[ "$PROFILE" == portrait ]]; then
  EXT_RES=1920x1080; EXT_ORIGIN='(324,-1920)'; EXT_DEGREE=90
else
  EXT_RES=1920x1080; EXT_ORIGIN='(1728,37)'
fi

# displayplacer is needed to DETECT screen ids below as well as to apply, so the
# availability guard has to run before the layout is assembled.
[[ -x "$DP" ]] || { log "displayplacer not found at $DP"; exit 127; }

# Resolve screen ids LIVE. Pinned UUIDs do not survive a redock: reattaching the
# external through a different port renumbers its persistent id, after which
# every two-screen profile silently no-ops — displayplacer prints "Unable to
# find screen <uuid>" per screen and the deck key looks inert (observed
# 2026-07-27: --hires from Raycast, both ids stale). Only the live-detecting
# --solo path survived. The built-in is identified by displayplacer's "MacBook
# built in screen" type; the first screen that is not the built-in is external.
DP_LIST="$("$DP" list 2>/dev/null)"
BUILTIN_ID="$(awk '/Persistent screen id:/{id=$4} /^Type:/{if(id!=""){if($0~/MacBook built in/){print id;exit} id=""}}' <<< "$DP_LIST")"
EXT_ID="$(awk '/Persistent screen id:/{id=$4} /^Type:/{if(id!=""){if($0!~/MacBook built in/){print id;exit} id=""}}' <<< "$DP_LIST")"

# Maintainer default (this rig), assembled from the live ids. Override via
# DOTFILES_DISPLAY_LAYOUT. Each panel is emitted only when actually connected,
# so a clamshell dock (built-in absent) still applies the profile's external
# resolution instead of addressing a panel that is not there. With the built-in
# absent the external is the ONLY screen, so it takes the origin rather than an
# offset past a panel that is not present.
DEFAULT_LAYOUT=()
if [[ -n "$BUILTIN_ID" ]]; then
  DEFAULT_LAYOUT+=("id:$BUILTIN_ID res:$BUILTIN_RES hz:120 color_depth:8 enabled:true scaling:$SCALING origin:(0,0) degree:0")
else
  EXT_ORIGIN='(0,0)'
fi
[[ -n "$EXT_ID" ]] && DEFAULT_LAYOUT+=("id:$EXT_ID res:$EXT_RES hz:60 color_depth:8 enabled:true scaling:$SCALING origin:$EXT_ORIGIN degree:$EXT_DEGREE")

if [[ -n "${DOTFILES_DISPLAY_LAYOUT:-}" ]]; then
  args=(); while IFS= read -r l; do [[ -n "$l" ]] && args+=("$l"); done <<< "$DOTFILES_DISPLAY_LAYOUT"
elif [[ "${#DEFAULT_LAYOUT[@]}" -gt 0 ]]; then
  args=("${DEFAULT_LAYOUT[@]}")
else
  log "no displays detected — nothing to restore"
  exit 0
fi

# --solo overrides the assembled layout entirely: detect the single live display
# at runtime (no hardcoded UUID — clamshell docks vary). One list snapshot for
# count + id + kind, so the guard and the apply can't race a mid-enumeration
# dock event. With >1 display we fall back to the daily layout already in args:
# refusing here would let a cached bd-profile of 'solo' permanently disable the
# wake-restore path after re-docking (bd-wake re-runs the cached profile).
if [[ "$PROFILE" == solo ]]; then
  SOLO_LIST="$("$DP" list 2>/dev/null)"
  SOLO_COUNT="$(grep -c 'Persistent screen id:' <<< "$SOLO_LIST")"
  if [[ "$SOLO_COUNT" -ne 1 ]]; then
    log "solo: $SOLO_COUNT displays connected — falling back to daily layout"
    PROFILE=daily   # heal the persisted bd-profile too (written below)
  else
    SOLO_ID="$(awk '/Persistent screen id:/{print $4; exit}' <<< "$SOLO_LIST")"
    if grep -q 'MacBook built in screen' <<< "$SOLO_LIST"; then
      # Bare laptop: canonical built-in true-2x, keep ProMotion.
      SOLO_RES="1728x1117"; SOLO_HZ=120
    else
      SOLO_RES="${DOTFILES_DISPLAY_SOLO_RES:-2560x1440}"; SOLO_HZ=60
    fi
    args=("id:$SOLO_ID res:$SOLO_RES hz:$SOLO_HZ color_depth:8 enabled:true scaling:on origin:(0,0) degree:0")
  fi
fi

[[ "$ACTION" == "--dry-run" ]] && { printf 'would apply:\n'; printf '  %s\n' "${args[@]}"; exit 0; }

# Persist the active profile so bd-wake.sh re-applies it on wake. Without this,
# sleep/wake silently reverts to daily, losing --portrait/--stream/--hires/--native.
# Real applies only (dry-run exits above). Best-effort — never block the apply.
mkdir -p "$HOME/.cache" 2>/dev/null || true
printf '%s\n' "$PROFILE" > "$HOME/.cache/bd-profile" 2>/dev/null || true

# drifted — true if any target screen's live res|scaling|rotation differs from
# the target. Scaling matters: 2560x1440 at scaling:off on a 4K panel is a soft
# non-retina 1x mode that res+rotation alone would wrongly read as canonical.
drifted() {
  [[ "${1:-}" == "--force" ]] && return 0
  local line id want cur
  for line in "${args[@]}"; do
    id="$(sed -E 's/.*id:([A-Za-z0-9-]+).*/\1/' <<< "$line")"
    want="$(sed -E 's/.*res:([0-9]+x[0-9]+).*scaling:(on|off).*degree:([0-9]+).*/\1|\2|\3/' <<< "$line")"
    cur="$("$DP" list 2>/dev/null | awk -v u="$id" 'index($0,u){f=1} f&&/Resolution:/{r=$2} f&&/Scaling:/{s=$2} f&&/Rotation:/{print r"|"s"|"$2; exit}')"
    [[ "$cur" != "$want" ]] && { log "drift on $id: live=$cur want=$want"; return 0; }
  done
  return 1
}

if drifted "$ACTION"; then
  log "restoring canonical layout"
  if "$DP" "${args[@]}" >>"$LOG" 2>&1; then log "restored OK"; else log "WARN displayplacer failed"; fi
else
  log "layout already canonical — no-op"
fi

# Re-pin the Übersicht dashboard to the external monitor in case this layout change
# drifted its NSScreenNumber (Übersicht keys selected-screens on it; it is not
# stable). Best-effort + backgrounded so it never blocks the layout apply; the sync
# is a cheap no-op unless the number actually changed.
SYNC="${DOTFILES_DIR:-$HOME/dotfiles}/scripts/scripts/ubersicht-screen-sync.sh"
[[ -x "$SYNC" ]] && "$SYNC" >/dev/null 2>&1 &
