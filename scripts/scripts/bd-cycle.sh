#!/usr/bin/env bash
# bd-cycle.sh [next|prev] — advance / reverse BetterDisplay mode (sketchybar handler).
#
# Cycle order: dawn → day → afternoon → evening → night → meeting → read → stream → cinema → dawn
# Default direction = next (sketchybar left-click). Pass `prev` for reverse (right-click).

set -u

STATE_FILE="$HOME/.cache/bd-state"
APPLY="$HOME/dotfiles/scripts/scripts/bd-apply.sh"
DIR="${1:-next}"

ORDER=(dawn day afternoon evening night meeting read stream cinema)
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
