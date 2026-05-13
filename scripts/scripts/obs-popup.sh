#!/usr/bin/env bash
# obs-popup — tmux popup for OBS scene/recording control via fzf.
# Bound to: prefix + Ctrl+s (see tmux.conf)
# Requires: bun (for obs.ts), fzf, scripts/scripts/obs.ts in PATH

set -euo pipefail

# Get current scene state up front so the prompt is informative
current=$(obs current 2>/dev/null || echo "?")
rec_state=$(obs rec status 2>/dev/null | grep -o '"outputActive":\s*true' >/dev/null && echo "REC" || echo "idle")

# Pull scene list dynamically — falls back to the 5 build-in-public defaults if OBS is offline
scenes=$(obs scenes 2>/dev/null | grep -oE '"[^"]+"' | tr -d '"' || printf "01_Intro\n02_Coding\n03_Terminal_Only\n04_Break\n05_Outro")

action=$(printf "%s\n---\nToggle Recording\nDrop Marker\nMute Mic/Aux\nStop Stream\nStream Stats\n" "$scenes" \
  | fzf --prompt="OBS [${rec_state}] @ ${current} > " --height=40% --reverse --border=rounded)

case "$action" in
  "" | "---" ) exit 0 ;;
  "Toggle Recording") obs rec toggle ;;
  "Drop Marker")
    label=$(echo "" | fzf --print-query --prompt="marker label (empty=ok)> " --height=10% || true)
    [[ -n "$label" ]] && obs marker "$label" || obs marker
    ;;
  "Mute Mic/Aux") obs mute "Mic/Aux" ;;
  "Stop Stream") obs stream stop ;;
  "Stream Stats") obs stats | less ;;
  *) obs scene "$action" ;;
esac
