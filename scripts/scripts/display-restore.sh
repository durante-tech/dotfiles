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
# Usage: display-restore.sh [--daily | --stream | --hires | --native | --portrait] [--force | --dry-run]
#   --daily   : explicit alias for the default (built-in 1728x1117 + Samsung 1920x1080).
#   --stream  : built-in at 1728x1080 (OBS-clean 2:1). Default is 1728x1117 (sharp).
#   --hires   : Samsung external at 2560x1440 HiDPI (~78% more desktop area, stays
#               retina-scaled). Default is 1920x1080 true integer-2x (sharpest).
#   --native  : BOTH panels at 1x native (built-in 3456x2234, Samsung 3840x2160),
#               scaling:off — pixel-perfect 1:1, zero scaling, but UI renders tiny.
#   --portrait: Samsung rotated 90 to true-2x 1080x1920 portrait (backing 2160x3840
#               == native — pixel-perfect, 1920px of crisp vertical space).
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

# Maintainer default (this rig). Override via DOTFILES_DISPLAY_LAYOUT.
DEFAULT_LAYOUT=(
  "id:37D8832A-2D66-02CA-B9F7-8F30A301B230 res:$BUILTIN_RES hz:120 color_depth:8 enabled:true scaling:$SCALING origin:(0,0) degree:0"
  "id:E3434867-5A33-48E9-8FAE-B8DC6CC682B6 res:$EXT_RES hz:60 color_depth:8 enabled:true scaling:$SCALING origin:$EXT_ORIGIN degree:$EXT_DEGREE"
)

if [[ -n "${DOTFILES_DISPLAY_LAYOUT:-}" ]]; then
  args=(); while IFS= read -r l; do [[ -n "$l" ]] && args+=("$l"); done <<< "$DOTFILES_DISPLAY_LAYOUT"
else
  args=("${DEFAULT_LAYOUT[@]}")
fi

[[ -x "$DP" ]] || { log "displayplacer not found at $DP"; exit 127; }

[[ "$ACTION" == "--dry-run" ]] && { printf 'would apply:\n'; printf '  %s\n' "${args[@]}"; exit 0; }

# Persist the active profile so bd-wake.sh re-applies it on wake. Without this,
# sleep/wake silently reverts to daily, losing --portrait/--stream/--hires/--native.
# Real applies only (dry-run exits above). Best-effort — never block the apply.
mkdir -p "$HOME/.cache" 2>/dev/null || true
printf '%s\n' "$PROFILE" > "$HOME/.cache/bd-profile" 2>/dev/null || true

# drifted — true if any target screen's live res|rotation differs from the target.
drifted() {
  [[ "${1:-}" == "--force" ]] && return 0
  local line id want cur
  for line in "${args[@]}"; do
    id="$(sed -E 's/.*id:([A-Za-z0-9-]+).*/\1/' <<< "$line")"
    want="$(sed -E 's/.*res:([0-9]+x[0-9]+).*degree:([0-9]+).*/\1|\2/' <<< "$line")"
    cur="$("$DP" list 2>/dev/null | awk -v u="$id" 'index($0,u){f=1} f&&/Resolution:/{r=$2} f&&/Rotation:/{print r"|"$2; exit}')"
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
SYNC="$HOME/dotfiles/scripts/scripts/ubersicht-screen-sync.sh"
[[ -x "$SYNC" ]] && "$SYNC" >/dev/null 2>&1 &
