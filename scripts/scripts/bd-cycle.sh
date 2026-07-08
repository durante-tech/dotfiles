#!/usr/bin/env bash
# bd-cycle.sh [next|prev] — advance / reverse BetterDisplay mode (sketchybar handler).
#
# Cycle order: dawn → day → afternoon → evening → night → meeting → read → stream → cinema → dawn
# Default direction = next (sketchybar left-click). Pass `prev` for reverse (right-click).

set -u

STATE_FILE="$HOME/.cache/bd-state"
# sketchybar click context (launchd) — source personal.env so a DOTFILES_DIR
# override set there is honored outside interactive shells.
[ -f "$HOME/.config/dotfiles/personal.env" ] && source "$HOME/.config/dotfiles/personal.env"

DOTFILES_DIR="${DOTFILES_DIR:-$HOME/dotfiles}"
APPLY="$DOTFILES_DIR/scripts/scripts/bd-apply.sh"
DIR="${1:-next}"

# Source bd-apply.sh for the canonical ORDER table (its source-guard prevents it
# from applying a mode on source). Single source of truth for the cycle order.
# shellcheck source=/dev/null
source "$APPLY"
N="${#ORDER[@]}"

current=""
if [[ -r "$STATE_FILE" ]]; then
    current="$(cut -d'|' -f1 "$STATE_FILE")"
fi

target="${ORDER[0]}"
for i in "${!ORDER[@]}"; do
    if [[ "${ORDER[$i]}" == "$current" ]]; then
        case "$DIR" in
            next) idx=$(( (i + 1)     % N )) ;;
            prev) idx=$(( (i - 1 + N) % N )) ;;
            *)    echo "usage: $(basename "$0") [next|prev]" >&2; exit 2 ;;
        esac
        target="${ORDER[$idx]}"
        break
    fi
done

BD_SOURCE=click exec "$APPLY" "$target"
