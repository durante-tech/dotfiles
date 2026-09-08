#!/usr/bin/env bash
# Build BetterDisplay favorite-mode slots from the live bd-apply.sh modes.
#
# IMPORTANT: bd-apply.sh sets display values DIRECTLY and does NOT use favoriteMode
# — by design, not as a stopgap. The direct path closes the loop with readback +
# retry (see bd-apply.sh header); favoriteMode is a single fire-and-forget set with
# no verification, so it silently loses a mode written while the external monitor
# sleeps. These slots are therefore a MANUAL RECOVERY FALLBACK only, kept in sync
# in case they're ever needed by hand — NOT a migration target. Day to day, switch
# modes with `bd-apply.sh <mode>` or `bd-cycle.sh`. Use bundle metadata for the installed version;
# do not invoke betterdisplaycli version.
#
# Each slot is built by APPLYING the live mode through bd-apply.sh (the single
# source of truth — the display_control.policy.PRESETS) and then saving the result as a favorite,
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

DOTFILES_DIR="${DOTFILES_DIR:-$HOME/dotfiles}"
APPLY="$DOTFILES_DIR/scripts/scripts/bd-apply.sh"

# Slot order — index i maps to favoriteMode slot (i+1).
SLOTS=(day night meeting read stream)


echo "BetterDisplay slot builder — replaying live bd-apply modes into slots 1-5."
echo "NOTE: favoriteMode is a manual recovery fallback only; bd-apply.sh's direct"
echo "      readback-verified path is the production switch. This keeps slots in sync."
echo
read -r -p "Proceed? [y/N] " yn
[[ "$yn" =~ ^[Yy]$ ]] || { echo "Aborted."; exit 0; }

for i in "${!SLOTS[@]}"; do
    slot=$((i + 1))
    mode="${SLOTS[$i]}"
    echo "[slot $slot] applying '$mode' then saving favorite..."
    if ! "$APPLY" favorite "$mode" "$slot"; then
        echo "Slot $slot failed; stopping without reporting success" >&2
        exit 1
    fi
    echo "    saved."
done

echo
echo "Restoring day mode..."
"$APPLY" day
echo "Done. Switch modes with bd-apply.sh <mode> or bd-cycle.sh (favoriteMode unused)."
