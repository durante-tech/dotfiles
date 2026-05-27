#!/usr/bin/env bash
# smart-pull.sh — pull, then open Claude Code with an upgrade prompt that
# tells DOS to intelligently apply the changes (run update.sh, surface
# cleanup commands, ask about hardware-specific changes, etc.).
#
# Usage:
#   ./smart-pull.sh                   # pull + open DOS with prompt
#   ./smart-pull.sh --print-prompt    # just print the prompt, don't pull or open Claude
#   ./smart-pull.sh --no-pull         # don't pull, just open DOS with prompt for the last 5 commits
#   ./smart-pull.sh --help            # this help
#
# Pairs with docs/POSTPULL_PROMPT.md (the prompt template) and
# docs/UPGRADE.md (the playbook DOS will read).

set -e

PRINT_ONLY=false
NO_PULL=false
for arg in "$@"; do
    case "$arg" in
        --print-prompt|-p) PRINT_ONLY=true ;;
        --no-pull|-n) NO_PULL=true ;;
        --help|-h)
            sed -n '2,12p' "$0" | sed 's|^# \?||'
            exit 0
            ;;
    esac
done

DOTFILES_DIR="${DOTFILES_DIR:-$HOME/dotfiles}"
TEMPLATE="$DOTFILES_DIR/docs/POSTPULL_PROMPT.md"

# Colors
B='\033[0;34m'; G='\033[0;32m'; Y='\033[1;33m'; R='\033[0;31m'; N='\033[0m'
say()  { printf "${B}▶${N} %s\n" "$*"; }
ok()   { printf "${G}✓${N} %s\n" "$*"; }
warn() { printf "${Y}!${N} %s\n" "$*"; }
err()  { printf "${R}✗${N} %s\n" "$*" >&2; }

[ ! -f "$TEMPLATE" ] && { err "Prompt template missing: $TEMPLATE"; exit 1; }
[ ! -d "$DOTFILES_DIR/.git" ] && { err "Not a git repo: $DOTFILES_DIR"; exit 1; }

cd "$DOTFILES_DIR"

# Capture before-pull HEAD
BEFORE=$(git rev-parse HEAD)

if [ "$NO_PULL" = false ]; then
    # Warn on uncommitted local changes (rare in a dotfiles repo, but possible
    # if you've been hand-editing and forgot to commit). Pull will refuse or
    # auto-merge; either way the user should know.
    if ! git diff --quiet || ! git diff --cached --quiet; then
        warn "Uncommitted local changes detected. Pull may fail or auto-merge."
        git status --short
        echo
    fi

    say "Pulling latest from origin..."
    git pull --ff-only 2>&1 | tail -5 || {
        err "Pull failed (probably non-fast-forward). Resolve manually and re-run."
        exit 1
    }
fi

AFTER=$(git rev-parse HEAD)

# Empty pull → nothing to do, exit cleanly
if [ "$BEFORE" = "$AFTER" ] && [ "$NO_PULL" = false ]; then
    ok "Already up to date — nothing for DOS to do."
    exit 0
fi

# If --no-pull, default the range to "last 5 commits" so the user can re-run
# the upgrade prompt against a past pull they forgot to process.
if [ "$NO_PULL" = true ]; then
    BEFORE=$(git rev-parse HEAD~5)
fi

RANGE="${BEFORE}..${AFTER}"

# Build substitutions
CHANGED_FILES=$(git diff --name-only "$RANGE")
DIFFSTAT=$(git diff --stat "$RANGE" | tail -20)

# Substitute placeholders in the template, skipping the explanatory header
# above the "## PROMPT" marker.
PROMPT=$(awk '/^## PROMPT \(everything below this line\)/{flag=1; next} flag' "$TEMPLATE")
PROMPT="${PROMPT//__COMMIT_RANGE__/$RANGE}"
PROMPT="${PROMPT//__CHANGED_FILES__/$CHANGED_FILES}"
PROMPT="${PROMPT//__DIFFSTAT__/$DIFFSTAT}"

if [ "$PRINT_ONLY" = true ]; then
    echo "─── prompt for range $RANGE ───"
    printf "%s\n" "$PROMPT"
    echo "─── (--print-prompt — no Claude session opened) ───"
    exit 0
fi

if ! command -v claude >/dev/null 2>&1; then
    warn "Claude Code CLI not found. Falling back to: print the prompt + run ./update.sh"
    echo
    printf "%s\n" "$PROMPT"
    echo
    say "Running ./update.sh as deterministic fallback..."
    exec "$DOTFILES_DIR/update.sh"
fi

ok "Opening DOS with upgrade prompt for $RANGE"
say "DOS will read UPGRADE.md, run ./update.sh, and ask you about anything ambiguous."
echo
exec claude "$PROMPT"
