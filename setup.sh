#!/bin/bash

# setup.sh - Configure dotfiles for current environment
# Run after cloning or pulling updates
# Usage: ./setup.sh [--check | --stow | --configure | --all]

set -e

# Machine-specific overrides live OUTSIDE the repo, in
# ~/.config/dotfiles/personal.env (written by personalize.sh). This script reads
# DOTFILES_RAYCAST_DIR and DOTFILES_CLAUDE_SETTINGS but never sourced the file
# that is supposed to define them, so the documented override home was inert for
# every non-interactive run — and launchd, sketchybar and Raycast contexts never
# see interactive-shell exports, which is the whole reason personal.env exists.
#
# Sourced BEFORE DOTFILES_DIR is defaulted so personal.env can override that too.
# An `if` rather than `[ -r ... ] && . ...`: under `set -e` the && form exits
# non-zero when the file is absent, which would abort the script on a machine
# that has simply never run personalize.sh.
if [ -r "$HOME/.config/dotfiles/personal.env" ]; then
    # shellcheck disable=SC1091  # user-generated, not in the repo
    . "$HOME/.config/dotfiles/personal.env"
fi

# Repo root = this script's directory; DOTFILES_DIR env var overrides.
DOTFILES_DIR="${DOTFILES_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)}"
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# ============================================================================
# Helper Functions
# ============================================================================

print_header() {
    echo -e "\n${BLUE}══════════════════════════════════════════════════════════════${NC}"
    echo -e "${BLUE}  $1${NC}"
    echo -e "${BLUE}══════════════════════════════════════════════════════════════${NC}\n"
}

print_success() { echo -e "${GREEN}✓${NC} $1"; }
print_warning() { echo -e "${YELLOW}⚠${NC} $1"; }
print_error() { echo -e "${RED}✗${NC} $1"; }
print_info() { echo -e "${BLUE}ℹ${NC} $1"; }

check_command() {
    if command -v "$1" &>/dev/null; then
        print_success "$1 installed"
        return 0
    else
        print_error "$1 not found"
        return 1
    fi
}

# ============================================================================
# Dependency Check
# ============================================================================

check_dependencies() {
    print_header "Checking Dependencies"

    local missing=0

    # Essential tools
    echo "Essential tools:"
    check_command "brew" || missing=$((missing + 1))
    check_command "git" || missing=$((missing + 1))
    check_command "stow" || missing=$((missing + 1))

    echo -e "\nShell tools:"
    check_command "zsh" || missing=$((missing + 1))
    check_command "starship" || missing=$((missing + 1))
    check_command "fzf" || missing=$((missing + 1))
    check_command "zoxide" || missing=$((missing + 1))
    check_command "atuin" || missing=$((missing + 1))

    echo -e "\nDevelopment tools:"
    check_command "nvim" || missing=$((missing + 1))
    check_command "tmux" || missing=$((missing + 1))
    check_command "lazygit" || missing=$((missing + 1))
    check_command "fd" || missing=$((missing + 1))
    check_command "bat" || missing=$((missing + 1))
    check_command "eza" || missing=$((missing + 1))

    echo -e "\nmacOS tools:"
    check_command "aerospace" || print_warning "aerospace not found (optional)"
    check_command "sketchybar" || print_warning "sketchybar not found (optional)"

    # mise is the single polyglot manager for Node + Python; it replaced
    # fnm + pyenv + nvm + asdf (install.sh brew-installs it). This check still
    # asked for fnm and pyenv, so a correctly-provisioned machine was told twice
    # that it was missing tools the repo deliberately no longer uses.
    echo -e "\nLanguage managers:"
    check_command "mise" || print_warning "mise not found (Node + Python versions)"

    if [[ $missing -gt 0 ]]; then
        echo -e "\n${YELLOW}$missing essential tools missing. Run ./install.sh first.${NC}"
        return 1
    fi

    print_success "All essential dependencies installed"
    return 0
}

# ============================================================================
# Stow Packages
# ============================================================================

stow_packages() {
    local failed=0
    print_header "Stowing Packages"

    cd "$DOTFILES_DIR" || exit 1

    # aerospace.toml is the GITIGNORED render output of render-aerospace.sh, so a
    # fresh clone does not have it. install.sh renders it before its own stow
    # loop, but stow_packages() never did — meaning `setup.sh --stow` and
    # `--all`, the documented repair paths, stowed the aerospace package around a
    # file that does not exist and left the window manager unconfigured.
    if [[ -x "$DOTFILES_DIR/scripts/scripts/render-aerospace.sh" ]]; then
        # shellcheck disable=SC2097,SC2098  # false positive, same as install.sh:
        # the prefix assignment exports DOTFILES_DIR into the child's environment
        # and the path expansion reads the OUTER variable — the same string. This
        # is not the `FOO=bar echo $FOO` bug those checks look for.
        if DOTFILES_DIR="$DOTFILES_DIR" "$DOTFILES_DIR/scripts/scripts/render-aerospace.sh" >/dev/null 2>&1; then
            print_success "Rendered aerospace.toml from template"
        else
            print_warning "render-aerospace.sh failed - aerospace.toml may be missing or stale"
            failed=1
        fi
    fi

    # Package list comes from stow-packages.txt, the single source of truth
    # shared with install.sh, check_stow_drift and the CI stow dry run.
    #
    # This used to be a fourth hand-maintained copy, and it had already drifted:
    # da836f2 ("bring mouse config under stow management") added `linearmouse` to
    # the manifest but not to this list, so `--stow` and `--all` silently skipped
    # the very package that commit existed to deploy.
    local manifest="$DOTFILES_DIR/stow-packages.txt"
    if [[ ! -r "$manifest" ]]; then
        print_error "Missing $manifest — cannot stow"
        return 1
    fi
    # `|| true` guards `set -e`: an empty manifest filters to zero lines and grep
    # exits 1, which would abort the run with no diagnostic.
    local packages
    packages="$(sed -e 's/#.*//' -e 's/[[:space:]]//g' "$manifest" | grep -v '^$' || true)"
    if [[ -z "$packages" ]]; then
        print_error "$manifest lists no packages — cannot stow"
        return 1
    fi

    # Ensure .config exists
    mkdir -p "$HOME/.config"
    # Ensure deep parent dirs exist for non-XDG stow packages
    mkdir -p "$HOME/Library/Application Support/Übersicht"

    # here-string, not a pipe: a `while read` on the right of a pipe runs in a
    # subshell, so any counter set inside would not survive into this scope.
    local pkg stow_err
    while IFS= read -r pkg; do
        [[ -n "$pkg" ]] || continue
        if [[ "$pkg" == aerospace && ! -f "$DOTFILES_DIR/aerospace/.config/aerospace/aerospace.toml" ]]; then
            print_error "AeroSpace render is missing; skipping its deployment"
            failed=1
            continue
        fi
        if [[ -d "$DOTFILES_DIR/$pkg" ]]; then
            # Keep stderr so a genuine error is distinguishable from a conflict.
            if stow_err="$(stow -t ~ -R "$pkg" 2>&1)"; then
                print_success "Stowed $pkg"
            else
                print_warning "Failed to stow $pkg:"
                failed=1
                sed 's/^/    /' <<< "$stow_err"
            fi
        else
            print_error "Package $pkg is missing"
            failed=1
        fi
    done <<< "$packages"

    # Übersicht caveat: its internal server.js doesn't follow relative
    # symlinks. Stow produces ../../../dotfiles/... which crashes the app.
    # Replace with an absolute symlink so server.js can resolve it.
    local uber_link="$HOME/Library/Application Support/Übersicht/widgets"
    local uber_target="$DOTFILES_DIR/ubersicht/Library/Application Support/Übersicht/widgets"
    if [[ -L "$uber_link" && -d "$uber_target" ]]; then
        ln -sfn "$uber_target" "$uber_link"
        print_success "Übersicht widgets symlink rewritten to absolute"
    fi
    return "$failed"
}

# ============================================================================
# Environment Configuration
# ============================================================================

configure_environment() {
    local failed=0
    print_header "Configuring Environment"

    # Detect monitors for AeroSpace
    echo "Detecting monitors..."
    if command -v aerospace &>/dev/null; then
        local monitors
        monitors=$(aerospace list-monitors 2>/dev/null || echo "")

        if [[ -n "$monitors" ]]; then
            echo -e "\nConnected monitors:"
            echo "$monitors"

            # Do NOT tell people to edit ~/.config/aerospace/aerospace.toml. It is
            # the gitignored OUTPUT of render-aerospace.sh, which truncates it with
            # `> "$OUTPUT"` on every render (install.sh, personalize.sh, or a manual
            # run). A hand-edit there survives until the next render and then
            # vanishes with no message and no diff, because the file is gitignored.
            echo -e "\n${YELLOW}Action needed:${NC}"
            echo "Record your monitor names, then re-render:"
            echo "  ./personalize.sh                              # writes ~/.config/dotfiles/personal.env"
            echo "  scripts/scripts/render-aerospace.sh && aerospace reload-config"
            echo ""
            echo "The rendered ~/.config/aerospace/aerospace.toml is GENERATED — edit"
            echo "aerospace/templates/aerospace.toml.template instead; a hand-edit"
            echo "to the rendered file is discarded by the next render."
        else
            print_warning "No monitors detected or aerospace not running"
        fi
    else
        print_info "AeroSpace not installed, skipping monitor config"
    fi

    # tmux-sessionizer paths
    echo -e "\n${YELLOW}Optional:${NC} Set custom project paths for tmux-sessionizer"
    echo "Add to ~/.zshrc or ~/.zprofile:"
    echo "  export TMUX_SESSIONIZER_PATHS=\"\$HOME/Projects \$HOME/Developer \$HOME/dotfiles\""

    # Create necessary directories
    echo -e "\nCreating directories..."
    mkdir -p "$HOME/.config"
    mkdir -p "$HOME/.local/bin"
    mkdir -p "$HOME/.local/share/nvim/mason/bin"
    mkdir -p "$HOME/scripts"
    mkdir -p "$HOME/.cache"
    mkdir -p "$HOME/.zsh/completions"
    mkdir -p "$HOME/.local/state/mpd"   # mpd.conf runtime paths; mpd won't create parents
    print_success "Directories created"

    # Make scripts executable.
    #
    # find -type f, not a glob: ~/scripts is almost entirely stow symlinks into
    # the repo, and chmod FOLLOWS a symlink operand (only -h touches the link
    # itself). The glob therefore rewrote the mode of the repo files behind
    # those links, flipping git-tracked 100644 entries (fzf-git.sh,
    # unlock-watch.swift) to 100755 and leaving
    # ~/dotfiles dirty after every setup run. find without -L reports a symlink
    # as -type l, so this now touches only the real files that live in
    # ~/scripts; stow already reproduces the tracked mode through the links.
    if [[ -d "$HOME/scripts" ]]; then
        find "$HOME/scripts" -maxdepth 1 -type f -exec chmod +x {} + 2>/dev/null || true
        print_success "Scripts made executable"
    fi

    # Install tmux plugins
    if [[ -d "$HOME/.config/tmux/.tmux/plugins/tpm" ]]; then
        print_info "TPM already installed"
    else
        echo "Installing TPM (Tmux Plugin Manager)..."
        git clone https://github.com/tmux-plugins/tpm "$HOME/.config/tmux/.tmux/plugins/tpm" 2>/dev/null || true
        print_success "TPM installed - press prefix + I in tmux to install plugins"
    fi

    # Python venv for nvim's python3 provider (Molten/Jupyter — pynvim).
    # options.lua points python3_host_prog here with an existence guard.
    setup_nvim_python || failed=1

    # Compile native helper binaries (unlock-watch) before the agents that run
    # them are bootstrapped.
    build_native_helpers || failed=1

    # Render LaunchAgent plists from templates and bootstrap them.
    # ~/.wakeup — the hook BOTH wake-recovery agents execute.
    #
    # com.lucas.sleepwatcher passes it to sleepwatcher's -w/-W, and
    # unlock-watch.swift runs it on com.apple.screenIsUnlocked. Nothing in this
    # repo ever created it, so on a fresh machine both agents fired against a
    # missing path and display recovery after sleep/unlock silently never
    # happened — invisible precisely because a missing hook is a no-op.
    #
    # Deliberately NOT `ln -sfn`: sleepwatcher's own brew caveat tells users to
    # WRITE ~/.sleep and ~/.wakeup as scripts, so an unconditional force-link
    # would silently destroy a hand-written hook. Only create it when the path
    # is free, and only re-point it when it is already a symlink into this repo.
    local wake_hook="$HOME/.wakeup"
    local wake_src="$DOTFILES_DIR/scripts/scripts/bd-wake.sh"
    if [[ -x "$wake_src" ]]; then
        if [[ ! -e "$wake_hook" && ! -L "$wake_hook" ]]; then
            ln -s "$wake_src" "$wake_hook"
            print_success "Created ~/.wakeup -> bd-wake.sh (display recovery on wake/unlock)"
        elif [[ -L "$wake_hook" && "$(readlink "$wake_hook")" == "$DOTFILES_DIR"/* ]]; then
            ln -sfn "$wake_src" "$wake_hook"
            print_info "Hook ~/.wakeup re-pointed at bd-wake.sh"
        else
            print_info "Hook ~/.wakeup exists and is not ours — left untouched"
        fi
    fi

    render_launchagents || failed=1

    # Symlink dotfiles-tracked Raycast script-commands into the indexed dir.
    link_raycast_commands || failed=1


    # Wire the rtk token-saver hook into Claude Code's PreToolUse:Bash chain.
    configure_rtk_hook || failed=1
    return "$failed"
}

# ============================================================================
# Native Helper Binaries
# ============================================================================
#
# A repo feature needs a tiny compiled listener that launchd cannot express as
# a plain plist: launchd has no trigger for distributed notifications.
# unlock-watch.swift observes com.apple.screenIsUnlocked and runs ~/.wakeup so
# the external monitor recovers on unlock (sleepwatcher's -W display-wake hook
# is unreliable on Apple Silicon). Compiled to ~/.local/bin so the LaunchAgent
# runs an absolute path. Guarded on swiftc: a machine without the Swift
# toolchain skips the helper and com.lucas.unlock-watch simply no-ops.

setup_nvim_python() {
    print_header "Nvim Python Provider"

    if ! command -v python3 >/dev/null 2>&1; then
        print_error "python3 not found — provider provisioning unavailable"
        return 1
    fi

    local VENV="$HOME/.venvs/nvim"
    # Check ALL three imports, not just pynvim. The old guard tested pynvim only,
    # so a venv that had pynvim but nothing else returned early forever and could
    # never repair itself — which is exactly the state this machine was in.
    if [[ -x "$VENV/bin/python" ]] \
        && "$VENV/bin/python" -c 'import pynvim, jupyter_client, ipykernel' 2>/dev/null \
        && "$VENV/bin/python" -m jupyter kernelspec list 2>/dev/null | grep -q '^  python3 '; then
        print_info "nvim python venv already provisioned ($VENV)"
        return 0
    fi

    # pynvim alone is not enough for Molten. jupyter_client lets nvim TALK to a
    # kernel but ships none, and ipykernel must additionally be REGISTERED as a
    # kernelspec — without that, `:MoltenInit python3` fails and every documented
    # <leader>m* binding is dead. Installing pynvim only is why Jupyter support
    # has never worked from a clean provision.
    #
    # uv is this repo's Python package manager, so use it here rather than pip.
    # Measured on this machine for venv + these three packages: uv 1.4s, pip 28.3s.
    # The stdlib path stays as a fallback because setup.sh must still work before
    # brew has run.
    #
    # Create ONLY when absent: `uv venv` errors out on an existing directory, and
    # recreating would discard a working provision. An existing-but-incomplete
    # venv is repaired by the install step below instead.
    if [[ ! -x "$VENV/bin/python" ]]; then
        if command -v uv >/dev/null 2>&1; then
            # --python pins the interpreter to the python3 already on PATH (mise's,
            # per CLAUDE.md). Without it uv downloads and uses its OWN CPython,
            # quietly giving nvim a different Python than the rest of the machine.
            uv venv --python "$(command -v python3)" "$VENV" >/dev/null 2>&1 || true
        else
            python3 -m venv "$VENV" 2>/dev/null || true
        fi
    fi

    local pkg_ok=0
    if [[ -x "$VENV/bin/python" ]]; then
        if command -v uv >/dev/null 2>&1; then
            # Works against a stdlib-created venv too, so a machine provisioned
            # before uv existed self-heals on the next run.
            uv pip install -q --python "$VENV/bin/python" \
                pynvim jupyter_client ipykernel 2>/dev/null && pkg_ok=1
        elif [[ -x "$VENV/bin/pip" ]]; then
            "$VENV/bin/pip" install -q pynvim jupyter_client ipykernel 2>/dev/null && pkg_ok=1
        fi
    fi

    if [[ $pkg_ok -eq 1 ]]; then
        # Name it python3 because that is the kernel `:MoltenInit python3` asks for.
        if "$VENV/bin/python" -m ipykernel install --user --name python3 \
               --display-name "Python 3 (nvim)" >/dev/null 2>&1; then
            print_success "nvim python provider venv ready -> $VENV (python3 kernel registered)"
        else
            print_warning "Provisioned $VENV but could not register the python3 Jupyter kernel"
            return 1
        fi
    else
        print_warning "Failed to provision $VENV (Molten/Jupyter provider disabled)"
        return 1
    fi
}

build_native_helpers() {
    print_header "Building Native Helpers"

    if ! command -v swiftc >/dev/null 2>&1; then
        print_info "swiftc not found — skipping native helpers (unlock-watch)"
        return 0
    fi

    local SRC="$DOTFILES_DIR/scripts/scripts/unlock-watch.swift"
    local OUT="$HOME/.local/bin/unlock-watch"

    if [[ ! -f "$SRC" ]]; then
        print_info "No unlock-watch.swift — skipping"
        return 0
    fi

    mkdir -p "$HOME/.local/bin"
    if swiftc -O "$SRC" -o "$OUT" 2>/dev/null; then
        print_success "Built unlock-watch -> $OUT"
    else
        print_warning "Failed to build unlock-watch (unlock-recovery for external monitor disabled)"
    fi
}

# ============================================================================
# LaunchAgent Templates
# ============================================================================
#
# macOS launchd reads plists literally — no env var expansion. Repo holds
# *.plist.template files with __USER__ and __DOTFILES_DIR__ placeholders; this
# function substitutes the running user + absolute repo path and copies real
# plists to ~/Library/LaunchAgents/, then bootstraps each agent into the
# user's gui session.

render_launchagents() {
    print_header "Rendering LaunchAgent Plists"

    local TPL_DIR="$DOTFILES_DIR/launchagents/Library/LaunchAgents"
    local DEST_DIR="$HOME/Library/LaunchAgents"

    if [[ ! -d "$TPL_DIR" ]]; then
        print_info "No launchagents/ directory — skipping"
        return 0
    fi

    mkdir -p "$DEST_DIR"
    mkdir -p "$HOME/Library/Logs"

    local rendered=0
    local loaded=0
    for tpl in "$TPL_DIR"/*.plist.template; do
        [[ -f "$tpl" ]] || continue
        local base
        base="$(basename "$tpl" .template)"
        local dest="$DEST_DIR/$base"

        # Escape sed replacement metacharacters in the repo path (&, \, |).
        local dotdir_esc
        dotdir_esc=$(printf '%s' "$DOTFILES_DIR" | sed -e 's/[&\\|]/\\&/g')
        sed -e "s|__USER__|$USER|g" -e "s|__DOTFILES_DIR__|$dotdir_esc|g" "$tpl" > "$dest"

        # Do NOT bootstrap an agent whose program does not exist. launchd
        # re-executes a failing agent, so a missing binary becomes a respawn
        # loop that burns CPU and fills the log with nothing useful — this repo
        # has already had two such loops at ~20k spawns each. The clearest case
        # is com.lucas.unlock-watch: build_native_helpers() is swiftc-guarded, so
        # on a Mac without the Swift toolchain the binary is never built, yet the
        # agent was still loaded and reported as a green "Loaded".
        local prog
        prog="$(sed -n 's|.*<string>\(/[^<]*\)</string>.*|\1|p' "$dest" | head -1)"
        if [ -n "$prog" ] && [ ! -x "$prog" ] && [ "${prog#/bin/}" = "$prog" ] && [ "${prog#/usr/bin/}" = "$prog" ]; then
            print_warning "Skipped $base - its program is missing: $prog"
            rendered=$((rendered + 1))
            continue
        fi

        # Bootstrap (or re-bootstrap) the agent so changes take effect now.
        launchctl bootout "gui/$(id -u)" "$dest" 2>/dev/null || true
        if launchctl bootstrap "gui/$(id -u)" "$dest" 2>/dev/null; then
            print_success "Loaded $base"
            loaded=$((loaded + 1))
        else
            # NOT "may already be loaded" — the bootout on the line above just
            # unloaded it, so a double-load is the one cause this cannot be.
            # The real ones are: no gui/<uid> domain (any SSH or non-console
            # run has none), a malformed plist, or a Program path that does not
            # exist. The old text sent people hunting a phantom.
            print_warning "Could not bootstrap $base (no gui domain, bad plist, or missing program path)"
        fi
        rendered=$((rendered + 1))
    done

    if [[ $rendered -eq 0 ]]; then
        print_info "No .plist.template files found"
    else
        # Report loads, not just renders. Writing a plist is not running it:
        # over SSH every bootstrap fails, yet the run still ended on a green
        # "Rendered 11 LaunchAgent plist(s)" that reads as "all agents are up".
        print_success "Rendered $rendered LaunchAgent plist(s), loaded $loaded"
        if [[ $loaded -lt $rendered ]]; then
            print_warning "$((rendered - loaded)) agent(s) did NOT load — re-run from a console login session (launchctl needs the gui/$(id -u) domain)"
        fi
    fi
}

# ============================================================================
# Raycast Script-Command Symlinks
# ============================================================================
#
# The Stream Deck SCREENS folder fires Raycast script-commands (display-* layout
# profiles + bd-* brightness modes). Raycast only indexes scripts in directories
# registered in its Script Commands settings. The display-* wrappers are tracked
# in dotfiles (raycast/script-commands/); this symlinks them into the Raycast
# indexed dir so they resolve without copying. Override the target with
# DOTFILES_RAYCAST_DIR (default: ~/Durante/scripts/raycast).

link_raycast_commands() {
    print_header "Linking Raycast Script Commands"

    local SRC_DIR="$DOTFILES_DIR/raycast/script-commands"
    local RAYCAST_DIR="${DOTFILES_RAYCAST_DIR:-$HOME/Durante/scripts/raycast}"

    if [[ ! -d "$SRC_DIR" ]]; then
        print_info "No raycast/script-commands/ directory — skipping"
        return 0
    fi

    # ~/Durante is the maintainer's DOS-private tree and is NOT part of this
    # public repo. mkdir -p on the default target therefore MATERIALIZED a
    # phantom ~/Durante/scripts/raycast on any clone that doesn't have it, on
    # every install.sh run (install.sh calls setup.sh --configure) — a directory
    # the user cannot account for, holding links Raycast is not indexing. The
    # repo rule is that ~/Durante references existence-guard and no-op; honour
    # it here and create the target only when the operator opted in, either by
    # having ~/Durante or by setting DOTFILES_RAYCAST_DIR.
    if [[ -z "${DOTFILES_RAYCAST_DIR:-}" && ! -d "$HOME/Durante" ]]; then
        print_info "No ~/Durante and no DOTFILES_RAYCAST_DIR — skipping Raycast links"
        return 0
    fi

    mkdir -p "$RAYCAST_DIR"

    local linked=0
    for src in "$SRC_DIR"/*.sh; do
        [[ -f "$src" ]] || continue
        ln -sf "$src" "$RAYCAST_DIR/$(basename "$src")"
        linked=$((linked + 1))
    done

    if [[ $linked -eq 0 ]]; then
        print_info "No raycast script-commands found"
    else
        print_success "Linked $linked Raycast script-command(s) into $RAYCAST_DIR"
        print_info "Enable in Raycast → Extensions → Script Commands (add $RAYCAST_DIR if needed)"
    fi
}

# ============================================================================
# RTK Agent Hook (Claude Code token-saver)
# ============================================================================
#
# rtk (Rust Token Killer, installed via Brewfile) proxies verbose dev-command
# output into compact form before it reaches the agent context. Its Claude Code
# integration is a PreToolUse:Bash hook (`rtk hook claude`) that transparently
# rewrites known commands (git/cargo/npm/ls/...) to their `rtk <cmd>` proxy;
# unknown/unsafe commands (e.g. rm) pass through untouched. We append it as the
# LAST hook in the existing Bash chain so every DOS guard validates the ORIGINAL
# command first — rtk only compacts the final proxy form. Hook-only: it does NOT
# create RTK.md or mutate ~/.claude/CLAUDE.md. Idempotent; gated on rtk + jq +
# an existing settings.json; skips gracefully otherwise. Override the settings
# path with DOTFILES_CLAUDE_SETTINGS.

configure_rtk_hook() {
    print_header "Wiring RTK Agent Hook (Claude Code)"

    if ! command -v rtk >/dev/null 2>&1; then
        print_info "rtk not installed — skipping (comes from Brewfile)"
        return 0
    fi
    if ! command -v jq >/dev/null 2>&1; then
        print_warning "jq not found — cannot patch settings.json safely; skipping rtk hook"
        return 0
    fi

    local SETTINGS="${DOTFILES_CLAUDE_SETTINGS:-$HOME/.claude/settings.json}"
    if [[ ! -f "$SETTINGS" ]]; then
        print_info "No $SETTINGS — skipping rtk hook (Claude Code not configured here)"
        return 0
    fi

    # Already wired? (idempotent)
    if jq -e '[.hooks.PreToolUse[]? | select(.matcher=="Bash") | .hooks[]? | select(.command=="rtk hook claude")] | length > 0' "$SETTINGS" >/dev/null 2>&1; then
        print_success "rtk hook already present in $SETTINGS"
        return 0
    fi

    # Need an existing PreToolUse:Bash block to append to.
    if ! jq -e '[.hooks.PreToolUse[]? | select(.matcher=="Bash")] | length > 0' "$SETTINGS" >/dev/null 2>&1; then
        print_warning "No PreToolUse:Bash block in $SETTINGS — skipping (unexpected layout)"
        return 0
    fi

    local TMP
    TMP="$(mktemp)"
    if jq '.hooks.PreToolUse = ([.hooks.PreToolUse[] |
            if .matcher=="Bash" and ((.hooks // []) | any(.command=="rtk hook claude") | not)
            then .hooks += [{"type":"command","command":"rtk hook claude"}]
            else . end])' "$SETTINGS" > "$TMP" 2>/dev/null && jq -e . "$TMP" >/dev/null 2>&1; then
        cp "$SETTINGS" "$SETTINGS.bak"
        mv "$TMP" "$SETTINGS"
        print_success "Appended 'rtk hook claude' as last Bash hook (backup: $SETTINGS.bak)"
    else
        rm -f "$TMP"
        print_warning "Failed to patch $SETTINGS with rtk hook — left unchanged"
    fi
}

# ============================================================================
# Verify Configuration
# ============================================================================

# check_stow_drift — report any package file the repo has but $HOME does not.
#
# The hardcoded symlink spot-check below only covers a handful of well-known
# paths, so a package could gain files that were never stowed and nothing would
# say so. That is exactly what happened: 17 scripts (display-restore.sh,
# bd-apply.sh, render-aerospace.sh, ...) plus all of fastfetch and wezterm sat
# unlinked in ~/ for weeks, because adding a file to a package does not re-run
# stow. `stow -n -R` in simulation mode is the authoritative answer — anything it
# would still LINK is a file that is missing from $HOME right now.
#
# Entries that are deliberately NOT stowed (aerospace/templates, wallpapers/
# shaders, zsh docs + completion cache) are excluded by each package's
# .stow-local-ignore, so they never show up here.
check_stow_drift() {
    STOW_LEGACY_PRESENT=0
    print_header "Checking Stow Drift"
    command -v stow >/dev/null 2>&1 || { print_error "stow not installed"; return 1; }
    cd "$DOTFILES_DIR" || return 1
    local manifest="$DOTFILES_DIR/stow-packages.txt" packages pkg raw out rc drifted=0
    [[ -r "$manifest" ]] || { print_error "Missing package manifest"; return 1; }
    packages="$(sed -e 's/#.*//' -e 's/[[:space:]]//g' "$manifest" | grep -v '^$' || true)"
    [[ -n "$packages" ]] || { print_error "Empty package manifest"; return 1; }
    while IFS= read -r pkg; do
        [[ -n "$pkg" ]] || continue
        if [[ ! -d "$DOTFILES_DIR/$pkg" ]]; then
            print_error "Package $pkg is missing"
            drifted=$((drifted + 1))
            continue
        fi
        rc=0
        raw="$(stow -n -v -R -t ~ "$pkg" 2>&1)" || rc=$?
        if (( rc != 0 )); then
            print_warning "$pkg — stow refused to run (conflict or error):"
            sed 's/^/    /' <<< "$raw"
            drifted=$((drifted + 1))
            continue
        fi
        # A re-stow lists existing links as UNLINK + LINK(reverts previous action).
        out="$(printf '%s\n' "$raw" | grep '^LINK:' | grep -v 'reverts previous action' || true)"
        if [[ -n "$out" ]]; then
            print_warning "$pkg has unstowed file(s):"
            sed 's/^/    /' <<< "$out"
            drifted=$((drifted + 1))
        fi
    done <<< "$packages"
    if (( drifted )); then
        print_warning "$drifted package(s) drifted — inspect before applying stow"
    else
        print_success "All manifest packages fully stowed"
    fi
    if [[ -L "$HOME/.dos/isc-state.json" ]]; then
        STOW_LEGACY_PRESENT=1
        print_warning "Legacy ~/.dos/isc-state.json link preserved; producer/successor ownership remains unresolved"
    fi
    (( drifted == 0 ))
}

verify_config() {
    print_header "Verifying Configuration"

    local issues=0 cfg_warn=0

    check_stow_drift || issues=$((issues + 1))
    cfg_warn=${STOW_LEGACY_PRESENT:-0}

    # Check symlinks
    echo "Checking symlinks..."

    local symlinks=(
        "$HOME/.zshrc:zsh/.zshrc"
        "$HOME/.zprofile:zsh/.zprofile"
        "$HOME/.config/nvim:nvim/.config/nvim"
        "$HOME/.config/tmux:tmux/.config/tmux"
        "$HOME/.config/starship:starship/.config/starship"
    )

    for link in "${symlinks[@]}"; do
        local target="${link%%:*}"
        local source="${link##*:}"

        if [[ -L "$target" ]]; then
            print_success "$target linked"
        elif [[ -e "$target" ]]; then
            print_info "$target exists; ownership checked by Stow (unfolded directories are valid)"
        else
            print_error "$target missing"
            issues=$((issues + 1))
        fi
    done

    # Check shell
    echo -e "\nChecking shell..."
    if [[ "$SHELL" == *"zsh"* ]]; then
        print_success "Default shell is zsh"
    else
        print_warning "Default shell is not zsh (current: $SHELL)"
        echo "  Run: chsh -s \$(which zsh)"
    fi

    # Check Neovim health
    echo -e "\nNeovim quick check..."
    if nvim --version &>/dev/null; then
        local nvim_version
        nvim_version=$(nvim --version | head -1)
        print_success "$nvim_version"
    else
        print_error "Neovim not working"
        issues=$((issues + 1))
    fi

    # AeroSpace doctor — three checks: monitor patterns (dead pins degrade to
    # the template's fallback chains), AeroSpace >= 0.20.0 (config-version=2
    # keys), persistent-workspaces drift. Warns without counting as an issue.
    if [[ -x "$DOTFILES_DIR/scripts/scripts/render-aerospace.sh" ]]; then
        echo -e "\nAeroSpace doctor..."
        # shellcheck disable=SC2097,SC2098  # false positive: the prefix assignment
        # exports DOTFILES_DIR into the child's environment, and the path expansion
        # reads the OUTER variable — same string. Not the `FOO=bar echo $FOO` bug.
        if DOTFILES_DIR="$DOTFILES_DIR" "$DOTFILES_DIR/scripts/scripts/render-aerospace.sh" --doctor; then
            print_success "AeroSpace doctor checks passed"
        else
            cfg_warn=$((cfg_warn + 1))
            print_warning "See doctor WARN lines above for the specific fix (personalize.sh, brew upgrade --cask aerospace, or persistent-workspaces edit)"
        fi
    fi

    # Verify what --configure actually PROVISIONED. Until now this function
    # checked stow drift, symlinks, the login shell, nvim and AeroSpace — none of
    # which --configure creates. So every failure it is meant to catch (an agent
    # that would not bootstrap, a venv that could not be built, a wake hook that
    # was never linked) passed verification silently.
    echo -e "\nConfigured state..."
    local agent_count
    agent_count=$(find "$HOME/Library/LaunchAgents" -name 'com.lucas.*.plist' 2>/dev/null | wc -l | tr -d ' ')
    local tpl_count
    tpl_count=$(find "$DOTFILES_DIR/launchagents/Library/LaunchAgents" -name '*.plist.template' 2>/dev/null | wc -l | tr -d ' ')
    if [[ "$agent_count" -eq 0 ]]; then
        print_warning "No com.lucas.* LaunchAgents rendered - run ./setup.sh --configure"
        cfg_warn=$((cfg_warn + 1))
    elif [[ "$agent_count" -lt "$tpl_count" ]]; then
        print_warning "$agent_count of $tpl_count LaunchAgents rendered (some templates did not land)"
        cfg_warn=$((cfg_warn + 1))
    else
        print_success "$agent_count/$tpl_count LaunchAgents rendered"
    fi

    # Molten needs all three, plus a registered kernelspec. pynvim alone is the
    # state this repo shipped for a long time and it is not enough.
    if [[ -x "$HOME/.venvs/nvim/bin/python" ]]; then
        if "$HOME/.venvs/nvim/bin/python" -c 'import pynvim, jupyter_client, ipykernel' 2>/dev/null; then
            print_success "nvim python provider venv complete (pynvim + jupyter_client + ipykernel)"
        else
            print_warning "nvim venv is missing packages - re-run ./setup.sh --configure"
        cfg_warn=$((cfg_warn + 1))
        fi
    else
        print_warning "No nvim python venv (~/.venvs/nvim) - Molten/Jupyter disabled"
        cfg_warn=$((cfg_warn + 1))
    fi

    # Both wake-recovery agents exec this path; nothing used to create it.
    if [[ -e "$HOME/.wakeup" ]]; then
        print_success "Wake hook ~/.wakeup present"
    else
        print_warning "Wake hook missing at ~/.wakeup - display recovery after sleep/unlock will not run"
        cfg_warn=$((cfg_warn + 1))
    fi

    if [[ -r "$HOME/.config/dotfiles/personal.env" ]]; then
        print_success "personal.env present"
    else
        print_info "No ~/.config/dotfiles/personal.env - run ./personalize.sh for machine-specific values"
    fi

    # "All checks passed!" used to print even with warnings on screen, because
    # only hard errors increment $issues. Saying it passed while a warning is
    # visible is the same false-success pattern this triage has been removing.
    if [[ $issues -eq 0 && $cfg_warn -eq 0 ]]; then
        print_success "All checks passed!"
    elif [[ $issues -eq 0 ]]; then
        print_warning "No errors, but $cfg_warn configuration warning(s) above"
    else
        print_warning "$issues issues found"
    fi

    return $issues
}

# ============================================================================
# Post-Update Tasks
# ============================================================================

post_update() {
    print_header "Post-Update Tasks"

    # Reload shell config hint
    echo "To apply shell changes:"
    echo "  source ~/.zprofile && source ~/.zshrc"
    echo "  OR restart your terminal"

    # Reload services
    echo -e "\nTo reload services:"
    echo "  aerospace reload-config  # Window manager"
    echo "  sketchybar --reload      # Status bar"
    echo "  tmux source ~/.config/tmux/tmux.conf  # Tmux (if running)"

    # Neovim plugins
    echo -e "\nTo update Neovim plugins:"
    echo "  nvim +Lazy sync +qa"

    # Tmux plugins
    echo -e "\nTo install Tmux plugins:"
    echo "  Inside tmux: prefix + I"
}

# ============================================================================
# Main
# ============================================================================

main() {
    echo -e "${BLUE}"
    echo "  ╔═══════════════════════════════════════╗"
    echo "  ║       Dotfiles Setup Script           ║"
    echo "  ╚═══════════════════════════════════════╝"
    echo -e "${NC}"

    case "${1:-}" in
        --check)
            # `|| true` is load-bearing under this file's `set -e`: a bare
            # function call that returns non-zero aborts the script. One missing
            # tool (eza, atuin, lazygit, ...) made check_dependencies return 1
            # and killed --check right there, so verify_config — stow drift,
            # symlink audit, aerospace doctor, the entire point of --check —
            # never ran on exactly the machines that needed diagnosing.
            # check_dependencies prints its own "Run ./install.sh first"
            # remediation, so continuing costs nothing.
            local check_failed=0
            check_dependencies || check_failed=1
            verify_config || check_failed=1
            return "$check_failed"
            ;;
        --stow)
            stow_packages
            ;;
        --provision)
            local provision_failed=0
            setup_nvim_python || provision_failed=1
            build_native_helpers || provision_failed=1
            return "$provision_failed"
            ;;
        --configure)
            local configure_failed=0
            configure_environment || configure_failed=1
            verify_config || configure_failed=1
            post_update
            return "$configure_failed"
            ;;
        --all|"")
            local all_failed=0
            check_dependencies || all_failed=1
            stow_packages || all_failed=1
            configure_environment || all_failed=1
            verify_config || all_failed=1
            post_update
            return "$all_failed"
            ;;
        --help|-h)
            echo "Usage: ./setup.sh [OPTION]"
            echo ""
            echo "Options:"
            echo "  --check      Check dependencies and verify config"
            echo "  --stow       Stow all packages"
            echo "  --configure  Explicit service/helper/integration setup"
            echo "  --provision  Provision provider environment and native helpers only"
            echo "  --all        Run all steps (default)"
            echo "  --help       Show this help"
            ;;
        *)
            echo "Unknown option: $1"
            echo "Run ./setup.sh --help for usage"
            exit 1
            ;;
    esac
}

main "$@"
