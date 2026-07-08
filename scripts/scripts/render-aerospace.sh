#!/usr/bin/env bash
# render-aerospace.sh — produce aerospace.toml from aerospace.toml.template.
#
# AeroSpace's TOML doesn't support env-var substitution, and monitor names
# differ per machine (built-in display model varies by laptop, external
# monitor names depend on BetterDisplay tag rewrites). So we keep
# aerospace.toml.template as the source of truth in git, and generate
# aerospace.toml at install/update time by sed-substituting the
# @DOTFILES_MONITOR_*@ sentinels from ~/.config/dotfiles/personal.env.
#
# Falls back to the maintainer's defaults when personal.env is absent so a
# fresh clone still produces a working config.
#
# Usage: render-aerospace.sh [--dry-run | --doctor]
#   --dry-run  show what would be rendered, write nothing
#   --doctor   check-only: compare configured monitor patterns against the
#              monitors AeroSpace actually sees (exit 1 on dead patterns)

set -eu

DRY_RUN=false
DOCTOR_ONLY=false
case "${1:-}" in
    --dry-run) DRY_RUN=true ;;
    --doctor)  DOCTOR_ONLY=true ;;
esac

DOTFILES_DIR="${DOTFILES_DIR:-$HOME/dotfiles}"
TEMPLATE="$DOTFILES_DIR/aerospace/templates/aerospace.toml.template"
OUTPUT="$DOTFILES_DIR/aerospace/.config/aerospace/aerospace.toml"

[ -f "$TEMPLATE" ] || { echo "render-aerospace: template not found: $TEMPLATE" >&2; exit 1; }

[ -f "$HOME/.config/dotfiles/personal.env" ] && source "$HOME/.config/dotfiles/personal.env"

BUILTIN="${DOTFILES_MONITOR_BUILTIN:-Built-in Retina Display}"
EXTERNAL="${DOTFILES_MONITOR_EXTERNAL:-PORTRAIT-MONITOR}"

# --- monitor-pattern doctor ---------------------------------------------------
# Warns when a configured pattern matches no connected monitor. Never blocks a
# render — the template's fallback chains ('secondary'/'main') keep the config
# functional — but a dead pattern usually means ./personalize.sh hasn't run.
MONITOR_NAMES=""
check_monitor_pattern() {  # $1 = label, $2 = pattern (AeroSpace substring regex)
    if [ "$2" = '^NONE$' ]; then
        echo "doctor: OK   $1 '^NONE$' — single-display config, external pinning intentionally disabled"
        return 0
    fi
    if printf '%s\n' "$MONITOR_NAMES" | grep -qiE -- "$2"; then
        echo "doctor: OK   $1 pattern '$2' matches a connected monitor"
    else
        echo "doctor: WARN $1 pattern '$2' matches NO connected monitor;"
        echo "             workspaces pinned to it fall back to secondary/main."
        echo "             Run ./personalize.sh to set your monitor names."
        return 1
    fi
}
doctor_monitors() {
    if ! command -v aerospace >/dev/null 2>&1; then
        echo "doctor: aerospace CLI not found — skipping monitor-pattern check"
        return 0
    fi
    MONITOR_NAMES=$(aerospace list-monitors 2>/dev/null | sed 's/^[^|]*| *//') || true
    if [ -z "$MONITOR_NAMES" ]; then
        echo "doctor: could not list monitors (AeroSpace not running?) — skipping"
        return 0
    fi
    local bad=0
    check_monitor_pattern BUILTIN "$BUILTIN" || bad=1
    check_monitor_pattern EXTERNAL "$EXTERNAL" || bad=1
    return $bad
}

if [ "$DOCTOR_ONLY" = true ]; then
    if doctor_monitors; then exit 0; else exit 1; fi
fi

if [ "$DRY_RUN" = true ]; then
    echo "Template:  $TEMPLATE"
    echo "Output:    $OUTPUT"
    echo "BUILTIN:   $BUILTIN"
    echo "EXTERNAL:  $EXTERNAL"
    exit 0
fi

# Escape sed replacement metacharacters (&, \, delimiter) so a repo path
# containing them can't corrupt the rendered bindings.
DOTFILES_DIR_ESC=$(printf '%s' "$DOTFILES_DIR" | sed -e 's/[&\\|]/\\&/g')

sed \
    -e "s|@DOTFILES_MONITOR_BUILTIN@|${BUILTIN}|g" \
    -e "s|@DOTFILES_MONITOR_EXTERNAL@|${EXTERNAL}|g" \
    -e "s|@DOTFILES_DIR@|${DOTFILES_DIR_ESC}|g" \
    "$TEMPLATE" > "$OUTPUT"

echo "rendered: $OUTPUT (builtin='$BUILTIN' external='$EXTERNAL')"

doctor_monitors || true
