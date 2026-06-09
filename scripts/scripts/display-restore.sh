#!/usr/bin/env bash
# display-restore.sh — re-assert the canonical monitor layout (resolution,
# rotation, origin) via displayplacer.
#
# Display reconfigurations silently wreck this layout: sleep/wake drops the
# built-in to a wide scaled mode (so the OBS capture goes small + soft) and a
# monitor or BetterDisplay virtual-screen connect/disconnect knocks PORTRAIT out
# of its 90 rotation. This restores the known-good layout so the OBS capture
# stays 1080p-sharp (built-in at "looks like 1728x1080", height == OBS canvas, a
# clean 2:1 downscale) and the portrait panel stays upright.
#
# Idempotent by default: only calls displayplacer when the live layout has
# drifted from target, because a redundant apply can itself flicker / disturb the
# window manager. --force applies unconditionally.
#
# Usage: display-restore.sh [--force | --dry-run]
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
log() { printf '[%s] %s\n' "$(date '+%F %T')" "$*" >> "$LOG"; }

# Maintainer default (this rig). Override via DOTFILES_DISPLAY_LAYOUT.
DEFAULT_LAYOUT=(
  'id:37D8832A-2D66-02CA-B9F7-8F30A301B230 res:1728x1080 hz:120 color_depth:8 enabled:true scaling:on origin:(0,0) degree:0'
  'id:E3434867-5A33-48E9-8FAE-B8DC6CC682B6 res:2160x3840 hz:60 color_depth:8 enabled:true scaling:on origin:(-2160,0) degree:90'
)

if [[ -n "${DOTFILES_DISPLAY_LAYOUT:-}" ]]; then
  args=(); while IFS= read -r l; do [[ -n "$l" ]] && args+=("$l"); done <<< "$DOTFILES_DISPLAY_LAYOUT"
else
  args=("${DEFAULT_LAYOUT[@]}")
fi

[[ -x "$DP" ]] || { log "displayplacer not found at $DP"; exit 127; }

[[ "${1:-}" == "--dry-run" ]] && { printf 'would apply:\n'; printf '  %s\n' "${args[@]}"; exit 0; }

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

if drifted "${1:-}"; then
  log "restoring canonical layout"
  if "$DP" "${args[@]}" >>"$LOG" 2>&1; then log "restored OK"; else log "WARN displayplacer failed"; fi
else
  log "layout already canonical — no-op"
fi
