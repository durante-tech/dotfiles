#!/usr/bin/env bash
# Build BetterDisplay favorite-mode slots from the live bd-apply.sh modes.
#
# IMPORTANT: slot-load is broken on BetterDisplay 4.3.0 pre-release, so bd-apply.sh
# sets display values DIRECTLY and does NOT use favoriteMode. This builder exists
# only to keep the slots in sync for if/when BD fixes slot-load. Day to day,
# switch modes with `bd-apply.sh <mode>` or `bd-cycle.sh` — NOT favoriteMode.
#
# Each slot is built by APPLYING the live mode through bd-apply.sh (the single
# source of truth — the MODES_TABLE) and then saving the result as a favorite,
# so a slot can never drift from its mode again. Slot -> mode:
#   1 = day   2 = night   3 = meeting   4 = read   5 = stream
#
# Reconciled 2026-06: previously this set its own divergent values (different
# brightness, bGain, sRGB presets, per-mode resolution + STREAM-CAPTURE for OBS).
# Those were not part of the live modes, so they are gone — if you want any of
# them back, add them to bd-apply.sh's mode table, not here.
#
# Run interactively. Restores the day mode at the end.

set -u

[ -f "$HOME/.config/dotfiles/personal.env" ] && source "$HOME/.config/dotfiles/personal.env"

APPLY="$HOME/dotfiles/scripts/scripts/bd-apply.sh"
DEV="${DOTFILES_BD_DEV_TAG:-2}"          # DEV-MAIN tagID (default: MBP 14")
PORT="${DOTFILES_BD_PORT_TAG:-60}"       # PORTRAIT-MONITOR tagID (default: Dell U2718Q)

# Slot order — index i maps to favoriteMode slot (i+1).
SLOTS=(day night meeting read stream)

save_slot() {   # <slot-number> — persist current display state to both monitors
    betterdisplaycli set --tagID="$DEV"  --saveFavoriteMode="$1" >/dev/null 2>&1 || true
    betterdisplaycli set --tagID="$PORT" --saveFavoriteMode="$1" >/dev/null 2>&1 || true
}

echo "BetterDisplay slot builder — replaying live bd-apply modes into slots 1-5."
echo "NOTE: slot-load is broken on BD 4.3.0; this only keeps the slots in sync."
echo
read -r -p "Proceed? [y/N] " yn
[[ "$yn" =~ ^[Yy]$ ]] || { echo "Aborted."; exit 0; }

for i in "${!SLOTS[@]}"; do
    slot=$((i + 1))
    mode="${SLOTS[$i]}"
    echo "[slot $slot] applying '$mode' then saving favorite..."
    "$APPLY" "$mode"
    sleep 1
    save_slot "$slot"
    echo "    saved."
done

echo
echo "Restoring day mode..."
"$APPLY" day
echo "Done. Switch modes with bd-apply.sh <mode> or bd-cycle.sh (favoriteMode unused)."
