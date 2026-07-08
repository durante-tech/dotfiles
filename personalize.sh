#!/usr/bin/env bash
# personalize.sh — interactive prompt that writes ~/.config/dotfiles/personal.env.
#
# Walks the user through discovering machine-specific values (BetterDisplay
# tagIDs, monitor names, keyboard layout), then writes the env file the
# bd-* scripts source at runtime.
#
# Usage:
#   ./personalize.sh                 # interactive
#   ./personalize.sh --recheck       # re-discover after hardware change
#   ./personalize.sh --dry-run       # preview what would be written
#
# See docs/PERSONALIZE.md for the full catalog of machine-specific values.

set -e

DRY_RUN=false
RECHECK=false
for arg in "$@"; do
    case "$arg" in
        --dry-run|-n) DRY_RUN=true ;;
        --recheck|-r) RECHECK=true ;;
        --help|-h)
            sed -n '2,12p' "$0" | sed 's|^# \?||'
            exit 0
            ;;
    esac
done

# Repo root = this script's directory; DOTFILES_DIR env var overrides.
DOTFILES_DIR="${DOTFILES_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)}"

PERSONAL_DIR="$HOME/.config/dotfiles"
PERSONAL_ENV="$PERSONAL_DIR/personal.env"
EXAMPLE="$DOTFILES_DIR/templates/personal.env.example"

# Colors
B='\033[0;34m'; G='\033[0;32m'; Y='\033[1;33m'; R='\033[0;31m'; N='\033[0m'
say()  { printf "${B}▶${N} %s\n" "$*"; }
ok()   { printf "${G}✓${N} %s\n" "$*"; }
warn() { printf "${Y}!${N} %s\n" "$*"; }
err()  { printf "${R}✗${N} %s\n" "$*" >&2; }
hdr()  { printf "\n${B}━━━ %s ━━━${N}\n" "$*"; }
ask()  { local prompt="$1" def="$2" var; read -r -p "$(printf "%s [${G}%s${N}]: " "$prompt" "$def")" var; echo "${var:-$def}"; }

hdr "Dotfiles Personalization"
echo "This writes machine-specific values to: $PERSONAL_ENV"
echo "Re-run anytime with --recheck. See docs/PERSONALIZE.md for the full catalog."
echo

# Existing file handling
if [ -f "$PERSONAL_ENV" ] && [ "$RECHECK" = false ]; then
    warn "$PERSONAL_ENV already exists."
    echo "Current values:"
    sed 's/^/  /' "$PERSONAL_ENV" | grep -v '^[[:space:]]*$\|^[[:space:]]*#' | head -20
    echo
    overwrite=$(ask "Overwrite? (y/N)" "n")
    [ "$overwrite" != "y" ] && [ "$overwrite" != "Y" ] && { ok "Keeping existing file. Use --recheck to re-run."; exit 0; }
fi

# -----------------------------------------------------------------------------
# 1. BetterDisplay tagIDs
# -----------------------------------------------------------------------------
hdr "1. BetterDisplay tagIDs"

DEV_TAG_DEFAULT=2
PORT_TAG_DEFAULT=60
if command -v betterdisplaycli >/dev/null 2>&1; then
    say "Detected BetterDisplay. Available displays:"
    betterdisplaycli get --identifiers 2>/dev/null | grep -E "name|tagID" | head -20 | sed 's/^/  /' || warn "(could not read identifiers — BetterDisplay running?)"
    echo
    say "DEV = your primary built-in display (where you edit code)."
    say "PORT = your external display (the one bd-apply.sh writes DDC to)."
else
    warn "BetterDisplay not installed. Using defaults."
fi

DEV_TAG=$(ask "BetterDisplay tagID for your built-in display (DEV_TAG)" "$DEV_TAG_DEFAULT")
PORT_TAG=$(ask "BetterDisplay tagID for your external display (PORT_TAG, or same as DEV if single-display)" "$PORT_TAG_DEFAULT")

# -----------------------------------------------------------------------------
# 2. Monitor names (substituted into aerospace.toml by render-aerospace.sh)
# -----------------------------------------------------------------------------
hdr "2. Monitor names"

BUILTIN_DEFAULT="Built-in Retina Display"
EXTERNAL_DEFAULT="^PORTRAIT-MONITOR$"

# Escape a literal monitor name for use inside an anchored regex. Apostrophes
# become '.' (regex any-char): the value is later injected into single-quoted
# TOML literal strings where a literal apostrophe cannot be represented at all,
# and '.' still matches the real name at runtime.
regex_escape() { printf '%s' "$1" | sed -e 's/[][\.*^$(){}?+|/]/\\&/g' -e "s/'/./g"; }

# Auto-detect connected monitors — AeroSpace preferred (its names are the ones
# the config matches against), system_profiler as a coarse fallback.
DETECTED=""
if command -v aerospace >/dev/null 2>&1; then
    DETECTED=$(aerospace list-monitors 2>/dev/null | sed 's/^[^|]*| *//' || true)
fi
if [ -z "$DETECTED" ] && command -v system_profiler >/dev/null 2>&1; then
    DETECTED=$(system_profiler SPDisplaysDataType 2>/dev/null \
        | awk '/^ {8}[^ ].*:$/ {sub(/^ +/,""); sub(/:$/,""); print}' || true)
fi

MON_COUNT=0
[ -n "$DETECTED" ] && MON_COUNT=$(printf '%s\n' "$DETECTED" | grep -c .)

if [ "$MON_COUNT" -eq 0 ]; then
    warn "Could not auto-detect monitors (AeroSpace not running?). Manual entry:"
    MONITOR_BUILTIN=$(ask "Built-in monitor name (matched as regex; escape special chars)" "$BUILTIN_DEFAULT")
    MONITOR_EXTERNAL=$(ask "External monitor name (matched as regex, e.g. 'DELL \\(1\\)'; '^NONE$' if single-display)" "$EXTERNAL_DEFAULT")
elif [ "$MON_COUNT" -eq 1 ]; then
    ONLY_MON=$(printf '%s\n' "$DETECTED" | head -1)
    say "Single display detected: $ONLY_MON"
    say "External pinning disabled; the template's fallback chains keep every workspace here."
    MONITOR_BUILTIN=$(ask "Built-in monitor name" "$ONLY_MON")
    # Accepted detected name verbatim -> escape it (matched as regex downstream);
    # user-edited input is treated as an intentional regex.
    [ "$MONITOR_BUILTIN" = "$ONLY_MON" ] && MONITOR_BUILTIN=$(regex_escape "$ONLY_MON")
    MONITOR_EXTERNAL='^NONE$'
else
    say "Detected $MON_COUNT monitors:"
    printf '%s\n' "$DETECTED" | awk '{print "  " NR ") " $0}'
    DEF_B=$(printf '%s\n' "$DETECTED" | grep -in 'built-in' | head -1 | cut -d: -f1)
    [ -z "$DEF_B" ] && DEF_B=1
    DEF_E=$(printf '%s\n' "$DETECTED" | grep -vin 'built-in' | head -1 | cut -d: -f1)
    [ -z "$DEF_E" ] && DEF_E=2
    PICK_B=$(ask "Which number is your BUILT-IN / primary display?" "$DEF_B")
    PICK_E=$(ask "Which number is your EXTERNAL / secondary display?" "$DEF_E")
    # Guard sed against non-numeric picks (a bare letter would crash under set -e)
    MONITOR_BUILTIN=""; EXT_NAME=""
    if [[ "$PICK_B" =~ ^[0-9]+$ ]] && [[ "$PICK_E" =~ ^[0-9]+$ ]]; then
        MONITOR_BUILTIN=$(printf '%s\n' "$DETECTED" | sed -n "${PICK_B}p")
        EXT_NAME=$(printf '%s\n' "$DETECTED" | sed -n "${PICK_E}p")
    fi
    if [ -z "$MONITOR_BUILTIN" ] || [ -z "$EXT_NAME" ]; then
        warn "Pick out of range — falling back to manual entry."
        MONITOR_BUILTIN=$(ask "Built-in monitor name (matched as regex; escape special chars)" "$BUILTIN_DEFAULT")
        MONITOR_EXTERNAL=$(ask "External monitor name (matched as regex; escape special chars, e.g. '\\(1\\)')" "$EXTERNAL_DEFAULT")
    else
        MONITOR_BUILTIN=$(regex_escape "$MONITOR_BUILTIN")
        MONITOR_EXTERNAL="^$(regex_escape "$EXT_NAME")\$"
        ok "BUILTIN='$MONITOR_BUILTIN'  EXTERNAL='$MONITOR_EXTERNAL'"
    fi
fi

# -----------------------------------------------------------------------------
# 3. Keyboard layout
# -----------------------------------------------------------------------------
hdr "3. Keyboard layout"

echo "Affects which AeroSpace bindings are usable. PT-BR users have alt-e/alt-n"
echo "as dead keys (commented out in aerospace.toml). Other layouts free up those keys."
KEYBOARD=$(ask "Keyboard layout (us | pt-br | uk | de | fr | other)" "us")

# -----------------------------------------------------------------------------
# Write personal.env
# -----------------------------------------------------------------------------
hdr "Writing personal.env"

new_content=$(cat <<EOF
# Generated by personalize.sh on $(date '+%Y-%m-%d %H:%M:%S')
# Re-run \`./personalize.sh --recheck\` to regenerate after hardware changes.
# See docs/PERSONALIZE.md for the catalog of every value.

DOTFILES_BD_DEV_TAG=$DEV_TAG
DOTFILES_BD_PORT_TAG=$PORT_TAG

DOTFILES_MONITOR_BUILTIN="$MONITOR_BUILTIN"
DOTFILES_MONITOR_EXTERNAL="$MONITOR_EXTERNAL"

DOTFILES_KEYBOARD_LAYOUT=$KEYBOARD
EOF
)

if [ "$DRY_RUN" = true ]; then
    echo "─── would write to $PERSONAL_ENV ───"
    printf "%s\n" "$new_content"
    echo "─── (dry-run — no file written) ───"
    exit 0
fi

mkdir -p "$PERSONAL_DIR"
if [ -f "$PERSONAL_ENV" ]; then
    cp "$PERSONAL_ENV" "$PERSONAL_ENV.before-$(date +%Y%m%d-%H%M%S)"
    say "Backed up existing file"
fi
printf "%s\n" "$new_content" > "$PERSONAL_ENV"
ok "Wrote $PERSONAL_ENV"

# -----------------------------------------------------------------------------
# Follow-up suggestions
# -----------------------------------------------------------------------------
hdr "Follow-up"

# Auto-render aerospace.toml so the new monitor names take effect immediately.
if [ -x "$DOTFILES_DIR/scripts/scripts/render-aerospace.sh" ]; then
    say "Rendering aerospace.toml from new monitor values..."
    DOTFILES_DIR="$DOTFILES_DIR" "$DOTFILES_DIR/scripts/scripts/render-aerospace.sh" || \
        warn "render-aerospace.sh failed — re-run manually"
    command -v aerospace >/dev/null 2>&1 && aerospace reload-config 2>/dev/null && ok "AeroSpace reloaded"
fi
echo

if [ "$KEYBOARD" != "pt-br" ]; then
    cat <<EOF
${Y}Keyboard${N} (${KEYBOARD} layout — not PT-BR):
  In aerospace.toml, search for "BRAZILIAN ACCENTS" and uncomment those 5 lines
  to recover alt-e/alt-n bindings. Then: aerospace reload-config

EOF
fi

cat <<EOF
${Y}LaunchAgents${N} (already templated):
  Run ~/dotfiles/setup.sh --configure to regenerate ~/Library/LaunchAgents/
  com.\$USER.* plists from the .plist.template files. The new DEV_TAG and
  PORT_TAG will be picked up because the bd-* scripts source personal.env.

EOF

ok "Done. Reload your bd-* tooling: pkill -USR1 bd-lmu-watch.sh; bd-status"
