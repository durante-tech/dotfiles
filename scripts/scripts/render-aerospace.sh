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
#   --doctor   check-only, four checks (exit 1 if any warns):
#              monitor patterns vs connected displays, AeroSpace version
#              >= 0.20.0 (config-version=2 keys), persistent-workspaces drift,
#              and window-detection health (rules are dead if AeroSpace has
#              stopped seeing newly-launched apps — see doctor_detection)

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

# --- version doctor -----------------------------------------------------------
# The template uses config-version = 2 keys (persistent-workspaces), which need
# AeroSpace >= 0.20.0. On an older install, AeroSpace rejects the unknown keys
# and falls back to its bundled default config — all custom bindings vanish.
doctor_version() {
    command -v aerospace >/dev/null 2>&1 || return 0
    local ver
    ver=$(aerospace --version 2>/dev/null | head -1 | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | head -1) || true
    [ -n "$ver" ] || return 0
    if [ "$(printf '%s\n0.20.0\n' "$ver" | sort -V | head -1)" != "0.20.0" ]; then
        echo "doctor: WARN AeroSpace $ver < 0.20.0 — template's config-version=2 keys"
        echo "             (persistent-workspaces) are unsupported; the app will fall"
        echo "             back to its default config. Upgrade: brew upgrade --cask aerospace"
        return 1
    fi
    echo "doctor: OK   AeroSpace $ver supports config-version = 2"
}

# --- persistent-workspaces drift doctor ----------------------------------------
# Every workspace referenced by an active binding, monitor assignment, or
# on-window-detected rule must be in persistent-workspaces (and vice versa) —
# a workspace missing from the list silently vanishes whenever it empties.
doctor_workspaces() {
    local persistent referenced missing extra
    persistent=$(grep '^persistent-workspaces' "$TEMPLATE" \
        | grep -oE "'[A-Za-z0-9]+'" | tr -d "'" | sort -u)
    referenced=$( { grep -vE '^\s*#' "$TEMPLATE" \
        | grep -oE "move-node-to-workspace [A-Za-z0-9]+|'workspace [A-Za-z0-9]+'" \
        | awk '{print $NF}' | tr -d "'" ;
        sed -n '/^\[workspace-to-monitor-force-assignment\]/,/^\[/p' "$TEMPLATE" \
        | grep -oE '^[A-Za-z0-9]+ =' | awk '{print $1}' ; } | sort -u)
    missing=$(comm -13 <(printf '%s\n' "$persistent") <(printf '%s\n' "$referenced"))
    extra=$(comm -23 <(printf '%s\n' "$persistent") <(printf '%s\n' "$referenced"))
    if [ -n "$missing" ]; then
        echo "doctor: WARN workspaces referenced but NOT in persistent-workspaces:" \
             $missing "— they vanish from listings when empty"
        return 1
    fi
    [ -n "$extra" ] && echo "doctor: NOTE persistent-workspaces entries never referenced:" $extra
    echo "doctor: OK   persistent-workspaces covers every referenced workspace"
}

# --- window-detection doctor ---------------------------------------------------
# AeroSpace runs on-window-detected the moment it FIRST sees a window. If the
# running instance stops observing newly-launched apps, every routing rule
# silently stops firing: no error, no log entry, and the config still validates
# clean. The only symptom is "new windows don't move any more" — which reads as
# a config bug and is not one.
#
# Observed 2026-07-30 on a 40h-old instance that had lived through a display
# reconfiguration: every app launched within an hour of AeroSpace start was
# managed, and every app launched afterwards (Chrome, ChatGPT, Safari) was
# invisible to it while plainly on screen. Fix is to restart AeroSpace.
#
# Ground truth is lsappinfo, a macOS built-in, so this adds no dependency. An
# app that is running with a real UI but missing from `aerospace list-apps` is
# invisible to the window manager. UIElement apps (menubar agents — BetterDisplay,
# Stream Deck, Logi Options+) are skipped: they carry no managed window by design
# and would otherwise report as permanent false positives.
doctor_detection() {
    command -v aerospace >/dev/null 2>&1 || return 0
    if ! command -v lsappinfo >/dev/null 2>&1; then
        echo "doctor: lsappinfo not found — skipping window-detection check"
        return 0
    fi

    local seen ids id asn drift=0 checked=0
    seen=$(aerospace list-apps --format '%{app-bundle-id}' 2>/dev/null | sort -u) || true
    if [ -z "$seen" ]; then
        echo "doctor: could not list apps (AeroSpace not running?) — skipping detection check"
        return 0
    fi

    # app-ids carry no @SENTINEL@ placeholders, so the template is as good as the
    # render and is always present.
    ids=$(grep -oE "^if\.app-id = '[^']+'" "$TEMPLATE" | sed "s/.*'\(.*\)'/\1/" | sort -u) || true

    while IFS= read -r id; do
        [ -n "$id" ] || continue
        asn=$(lsappinfo find bundleID="$id" 2>/dev/null | head -1) || true
        [ -n "$asn" ] || continue   # not running — nothing to detect
        if lsappinfo info "$asn" 2>/dev/null | grep -q 'type="UIElement"'; then
            continue                # menubar agent, legitimately window-less
        fi
        checked=$((checked + 1))
        if ! printf '%s\n' "$seen" | grep -qxF -- "$id"; then
            [ "$drift" -eq 0 ] && \
                echo "doctor: WARN AeroSpace cannot see these running, windowed apps:"
            echo "             $id"
            drift=$((drift + 1))
        fi
    done <<< "$ids"

    if [ "$drift" -gt 0 ]; then
        echo "             on-window-detected never fires for them, so their routing"
        echo "             rules are dead while the config looks correct."
        echo "             Restart AeroSpace, then re-run this check."
        return 1
    fi
    echo "doctor: OK   AeroSpace sees all $checked running rule-covered app(s)"
}

run_doctors() {
    local bad=0
    doctor_monitors   || bad=1
    doctor_version    || bad=1
    doctor_workspaces || bad=1
    doctor_detection  || bad=1
    return $bad
}

if [ "$DOCTOR_ONLY" = true ]; then
    if run_doctors; then exit 0; else exit 1; fi
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

run_doctors || true
