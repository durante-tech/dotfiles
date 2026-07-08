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
# Usage: render-aerospace.sh [--dry-run]

set -eu

DRY_RUN=false
[ "${1:-}" = "--dry-run" ] && DRY_RUN=true

DOTFILES_DIR="${DOTFILES_DIR:-$HOME/dotfiles}"
TEMPLATE="$DOTFILES_DIR/aerospace/templates/aerospace.toml.template"
OUTPUT="$DOTFILES_DIR/aerospace/.config/aerospace/aerospace.toml"

[ -f "$TEMPLATE" ] || { echo "render-aerospace: template not found: $TEMPLATE" >&2; exit 1; }

[ -f "$HOME/.config/dotfiles/personal.env" ] && source "$HOME/.config/dotfiles/personal.env"

BUILTIN="${DOTFILES_MONITOR_BUILTIN:-Built-in Retina Display}"
EXTERNAL="${DOTFILES_MONITOR_EXTERNAL:-PORTRAIT-MONITOR}"

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
