#!/usr/bin/env bash
# render-aerospace.sh — produce aerospace.toml from aerospace.toml.template.
#
# AeroSpace's TOML doesn't support env-var substitution, and monitor names
# differ per machine (built-in display model varies by laptop, external
# monitor names depend on BetterDisplay tag rewrites). So we keep
# aerospace.toml.template as the source of truth in git, and generate
# aerospace.toml at install/update time through the typed preference renderer.
#
# Shared defaults, legacy literal personal.env values, and preferences.json
# overrides are validated before substitution. Rendering never executes the env
# file or rewrites saved preferences.
#
# Usage: render-aerospace.sh [--dry-run | --doctor]
#   --dry-run  show what would be rendered, write nothing
#   --doctor   check-only, five checks (exit 1 if any warns):
#              monitor patterns vs connected displays, AeroSpace version
#              >= 0.20.0 (config-version=2 keys), persistent-workspaces drift,
#              window-detection health (rules are dead if AeroSpace has
#              stopped seeing newly-launched apps — see doctor_detection), and
#              a stale render (template pulled or edited but never re-rendered)

set -eu

DRY_RUN=false
DOCTOR_ONLY=false
case "${1:-}" in
    --dry-run) DRY_RUN=true ;;
    --doctor)  DOCTOR_ONLY=true ;;
    "") ;;
    # Without a default arm an unrecognised flag fell through to a full render:
    # a mistyped `--doctr`, or bd-apply.sh's bare-subcommand habit (`doctor`),
    # silently OVERWROTE aerospace.toml when the operator asked only to check
    # it — and because the post-render doctors run under `|| true`, the script
    # still exited 0, so a scripted check reported pass having verified nothing.
    *) echo "render-aerospace: unknown argument '$1'" >&2
       echo "Usage: render-aerospace.sh [--dry-run | --doctor]" >&2
       exit 2 ;;
esac

DOTFILES_DIR="${DOTFILES_DIR:-$HOME/dotfiles}"
TEMPLATE="$DOTFILES_DIR/aerospace/templates/aerospace.toml.template"
OUTPUT="$DOTFILES_DIR/aerospace/.config/aerospace/aerospace.toml"

[ -f "$TEMPLATE" ] || { echo "render-aerospace: template not found: $TEMPLATE" >&2; exit 1; }

export DOTFILES_DIR
PREFS="$DOTFILES_DIR/scripts/scripts/lib/preferences-cli.py"
# Read validated preferences without executing personal.env during rendering.
BUILTIN="$(python3 -B "$PREFS" get monitors.builtin --raw)"
EXTERNAL="$(python3 -B "$PREFS" get monitors.external --raw)"

# --- monitor-pattern doctor ---------------------------------------------------
# Warns when a configured pattern matches no connected monitor. Never blocks a
# render — the template's fallback chains ('secondary'/'main') keep the config
# functional — but a dead pattern usually means ./personalize.sh hasn't run.
MONITOR_NAMES=""
# $1 = label, $2 = the raw personal.env value, $3 = the pattern the RENDERED
# config actually matches with. Those differ for EXTERNAL: the template wraps it
# as '^…$' in workspace-to-monitor-force-assignment while BUILTIN goes in bare.
# Grepping the raw value therefore blessed patterns the config cannot match —
# EXTERNAL='PORTRAIT-MONITOR' (the shipped personal.env.example default) reports
# OK against a panel AeroSpace names 'PORTRAIT-MONITOR (1)' once a duplicate name
# appears, while the rendered '^PORTRAIT-MONITOR$' matches nothing and 2/M/T
# silently fall back to 'secondary'. $2 is still what the '^NONE$' single-display
# sentinel is tested against.
check_monitor_pattern() {
    if [ "$2" = '^NONE$' ]; then
        echo "doctor: OK   $1 '^NONE$' — single-display config, external pinning intentionally disabled"
        return 0
    fi
    if printf '%s\n' "$MONITOR_NAMES" | grep -qiE -- "$3"; then
        echo "doctor: OK   $1 pattern '$3' matches a connected monitor"
    else
        echo "doctor: WARN $1 pattern '$3' matches NO connected monitor;"
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
    check_monitor_pattern BUILTIN "$BUILTIN" "$BUILTIN" || bad=1
    check_monitor_pattern EXTERNAL "$EXTERNAL" "^$EXTERNAL\$" || bad=1
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
    python3 -B "$PREFS" check-workspaces
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

    # Inspect effective preferred apps as well as the category defaults.
    ids=$(python3 -B "$PREFS" app-routes) || true

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

# --- stale-render doctor -------------------------------------------------------
# aerospace.toml is gitignored render OUTPUT, so a `git pull` — or an agent that
# edits the template and stops there — moves the source of truth and leaves the
# deployed config untouched. Every other doctor reads $TEMPLATE or live AeroSpace
# state, so all four report OK while `alt-r` reloads yesterday's bindings; the
# only symptom is "the change I just pulled did nothing".
#
# Compare content using the same renderer; timestamps alone do not establish drift.
doctor_stale() {
    if python3 -B "$PREFS" render-aerospace --check >/dev/null 2>&1; then
        echo "doctor: OK   rendered aerospace.toml matches template and preferences"
        return 0
    fi
    echo "doctor: WARN rendered AeroSpace config differs from template/preferences; run render-aerospace.sh"
    return 1
}

run_doctors() {
    local bad=0
    doctor_monitors   || bad=1
    doctor_version    || bad=1
    doctor_workspaces || bad=1
    doctor_detection  || bad=1
    doctor_stale      || bad=1
    return $bad
}

if [ "$DOCTOR_ONLY" = true ]; then
    if run_doctors; then exit 0; else exit 1; fi
fi

if [ "$DRY_RUN" = true ]; then
    python3 -B "$PREFS" render-aerospace --dry-run --diff
    exit 0
fi

python3 -B "$PREFS" render-aerospace --apply
run_doctors || true
