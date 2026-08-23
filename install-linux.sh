#!/usr/bin/env bash
# install-linux.sh — terminal-core dotfiles install for Debian/Ubuntu.
#
# Scope is deliberately NOT parity with install.sh. This deploys the portable
# terminal stack (zsh, tmux, neovim, starship, yazi, w3m, atuin, mise, fzf and
# friends) and nothing else. The macOS window manager, status bar, key remapper,
# desktop widgets and display tooling have no Linux build; stow-packages.linux.txt
# lists what is excluded and why.
#
# Separate script rather than platform branches inside install.sh, because a
# branch nobody executes is exactly the shape that rots — this repo has spent a
# day proving how much drift a SINGLE unexercised path accumulates.
#
# Usage:
#   ./install-linux.sh              full install
#   ./install-linux.sh --dry-run    print what would happen, change nothing
#   ./install-linux.sh --skip-apt   skip the apt phase (already provisioned)
#   ./install-linux.sh --help

set -e

# -----------------------------------------------------------------------------
# CONFIG
# -----------------------------------------------------------------------------
DOTFILES_DIR="${DOTFILES_DIR:-$HOME/dotfiles}"
PACKAGE_MANIFEST="$DOTFILES_DIR/stow-packages.linux.txt"
LOCAL_BIN="$HOME/.local/bin"
TPM_DIR="$HOME/.config/tmux/.tmux/plugins/tpm"

DRY_RUN=false
SKIP_APT=false

# Accumulated failures. Nothing in the package phases is fatal: stow is the whole
# point of this script, and an unavailable package must never cost the user their
# dotfiles. Same rule install.sh learned the hard way (commit 0683da3).
APT_FAILED=""
TOOL_FAILED=""

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; BLUE='\033[0;34m'; NC='\033[0m'

print_header()  { echo -e "\n${BLUE}=== $1 ===${NC}"; }
print_step()    { echo -e "${BLUE}▶${NC} $1"; }
print_success() { echo -e "${GREEN}✓${NC} $1"; }
print_warn()    { echo -e "${YELLOW}⚠${NC} $1"; }
print_error()   { echo -e "${RED}✗${NC} $1"; }
print_info()    { echo -e "${BLUE}ℹ${NC} $1"; }
print_dry()     { echo -e "${YELLOW}[dry-run]${NC} $1"; }

cmd_exists() { command -v "$1" >/dev/null 2>&1; }

# mise tool name -> the command it actually installs. Only neovim differs today,
# but the indirection is what stops a rename becoming a phantom failure.
tool_binary() {
    case "$1" in
        neovim) echo "nvim" ;;
        *)      echo "$1" ;;
    esac
}

# tmux uses -V and rejects --version ("unknown option -- -"), which made the
# verification below report a perfectly working tmux as broken.
version_flag() {
    case "$1" in
        tmux) echo "-V" ;;
        *)    echo "--version" ;;
    esac
}

# NOT named `usage`: mise ships a tool called `usage`, and bash resolves FUNCTIONS
# before external commands. The probe below ran this function instead of the
# binary, hit its `exit 0`, and killed the whole install silently at phase 4 with
# a success status — phases 5-10 never ran and nothing said so.
show_usage() {
    sed -n '2,20p' "$0" | sed 's/^# \{0,1\}//'
    exit 0
}

while [ $# -gt 0 ]; do
    case "$1" in
        --dry-run)  DRY_RUN=true ;;
        --skip-apt) SKIP_APT=true ;;
        -h|--help)  show_usage ;;
        *) print_error "Unknown option: $1"; exit 1 ;;
    esac
    shift
done

# -----------------------------------------------------------------------------
# 1. PREFLIGHT
# -----------------------------------------------------------------------------
print_header "1. Preflight"

if [ "$(uname -s)" != "Linux" ]; then
    print_error "This is the Linux installer and this is $(uname -s). Use ./install.sh on macOS."
    exit 1
fi

if [ -r /etc/os-release ]; then
    # shellcheck disable=SC1091
    . /etc/os-release
    print_info "Distro: ${PRETTY_NAME:-unknown}"
    case " ${ID:-} ${ID_LIKE:-} " in
        *debian*|*ubuntu*) : ;;
        *) print_warn "Not Debian/Ubuntu — the apt phase will likely fail. --skip-apt to bypass it." ;;
    esac
else
    print_warn "No /etc/os-release; cannot identify the distro"
fi

# Root is wrong here: everything lands in $HOME, and running as root would create
# root-owned files in a user's home that they then cannot rewrite.
if [ "$(id -u)" -eq 0 ]; then
    print_error "Do not run as root. This installs into \$HOME; it calls sudo only for apt."
    exit 1
fi

SUDO=""
if [ "$SKIP_APT" = false ]; then
    if cmd_exists sudo; then
        SUDO="sudo"
    else
        print_error "sudo not found and the apt phase needs it. Install sudo, or use --skip-apt."
        exit 1
    fi
fi

mkdir -p "$LOCAL_BIN"

# -----------------------------------------------------------------------------
# 2. APT BASE PACKAGES
# -----------------------------------------------------------------------------
print_header "2. Base packages (apt)"

# Only what Debian ships at a USABLE version. Everything apt lags on badly, or
# does not carry at all, goes through mise in phase 4 — see that phase's note.
APT_PACKAGES="
build-essential
ca-certificates
curl
file
git
jq
luarocks
python3
python3-venv
ripgrep
stow
tmux
unzip
w3m
wget
xclip
zsh
bat
fd-find
"

if [ "$SKIP_APT" = true ]; then
    print_info "Skipping apt phase (--skip-apt)"
else
    if [ "$DRY_RUN" = true ]; then
        print_dry "$SUDO apt-get update"
        print_dry "$SUDO apt-get install -y $(echo "$APT_PACKAGES" | tr '\n' ' ')"
    else
        print_step "Updating apt index..."
        $SUDO apt-get update -qq || print_warn "apt-get update reported problems"

        for pkg in $APT_PACKAGES; do
            if dpkg -s "$pkg" >/dev/null 2>&1; then
                print_success "$pkg already installed"
                continue
            fi
            print_step "Installing $pkg..."
            if DEBIAN_FRONTEND=noninteractive $SUDO apt-get install -y -qq "$pkg" >/dev/null 2>&1; then
                print_success "$pkg"
            else
                print_warn "$pkg failed to install"
                APT_FAILED="$APT_FAILED $pkg"
            fi
        done
    fi
fi

# Debian renames two binaries to avoid clashes: fd-find ships `fdfind` and bat
# ships `batcat`. Every alias and script in this repo calls `fd` and `bat`, so
# without these shims .zshrc's `cat`/`fd` aliases and fzf's preview are broken.
if [ "$DRY_RUN" = true ]; then
    print_dry "ln -s fdfind $LOCAL_BIN/fd ; ln -s batcat $LOCAL_BIN/bat"
else
    for pair in "fdfind:fd" "batcat:bat"; do
        src="${pair%%:*}"; dst="${pair##*:}"
        if cmd_exists "$src" && ! cmd_exists "$dst"; then
            ln -sf "$(command -v "$src")" "$LOCAL_BIN/$dst"
            print_success "Shimmed $dst -> $src"
        fi
    done
fi

# -----------------------------------------------------------------------------
# 3. MISE
# -----------------------------------------------------------------------------
print_header "3. mise"

if cmd_exists mise || [ -x "$LOCAL_BIN/mise" ]; then
    print_success "mise already installed"
elif [ "$DRY_RUN" = true ]; then
    print_dry "curl https://mise.run | sh"
else
    print_step "Installing mise..."
    # pipefail is load-bearing: without it a failed curl feeds empty stdin to sh,
    # which exits 0, and the failure is silent. Measured on install.sh's Homebrew
    # and SDKMAN paths earlier today.
    if bash -c 'set -o pipefail; curl -fsSL https://mise.run | sh' >/dev/null 2>&1; then
        print_success "mise installed"
    else
        print_warn "mise install failed - phase 4 will be skipped"
        TOOL_FAILED="$TOOL_FAILED mise"
    fi
fi

export PATH="$LOCAL_BIN:$PATH"
MISE=""
cmd_exists mise && MISE="$(command -v mise)"
[ -z "$MISE" ] && [ -x "$LOCAL_BIN/mise" ] && MISE="$LOCAL_BIN/mise"

# The repo's mise config carries the node/python pins and settings. It is COPIED,
# never stowed, on Linux: `mise use -g` below rewrites this file, and with a
# symlink here that write lands in the git repo (measured — the tracked file's
# md5 changed and stow's folded directory link became a real file). Never
# overwritten, so a user's own config is left alone.
MISE_CFG="$HOME/.config/mise/config.toml"
if [ "$DRY_RUN" = true ]; then
    print_dry "cp mise/.config/mise/config.toml $MISE_CFG (if absent)"
elif [ -e "$MISE_CFG" ]; then
    print_info "mise config already present - left untouched"
elif [ -f "$DOTFILES_DIR/mise/.config/mise/config.toml" ]; then
    mkdir -p "$(dirname "$MISE_CFG")"
    cp "$DOTFILES_DIR/mise/.config/mise/config.toml" "$MISE_CFG"
    print_success "Seeded mise config (node/python pins) -> $MISE_CFG"
fi

# -----------------------------------------------------------------------------
# 4. TOOLCHAIN VIA MISE
# -----------------------------------------------------------------------------
print_header "4. Toolchain (mise)"

# These go through mise, not apt, for a concrete reason each:
#
#   neovim    Debian 12 ships 0.7.2. This config uses the vim.lsp.config API,
#             which landed in 0.11 — apt's build cannot load it at all.
#   zoxide    apt has 0.4.3; current is 0.9+.
#   fzf       Debian ships 0.38. `fzf --zsh`, which .zshrc uses to install the
#             Ctrl+T / Alt+C / Ctrl+R bindings, only exists from 0.48 — measured:
#             the old binary prints "unknown option: --zsh" on every shell start.
#   the rest  not packaged by Debian at all (verified against bookworm):
#             eza, starship, atuin, yazi, lazygit, delta, fastfetch, uv.
#
# One installer instead of eight bespoke curl|tar pipelines, and it matches the
# repo's existing convention — CLAUDE.md already makes mise the polyglot manager.
MISE_TOOLS="
neovim
fzf
starship
atuin
eza
zoxide
yazi
lazygit
delta
fastfetch
usage
"

if [ -z "$MISE" ]; then
    print_warn "No mise - skipping toolchain phase entirely"
elif [ "$DRY_RUN" = true ]; then
    for t in $MISE_TOOLS; do print_dry "mise use -g $t@latest"; done
    print_dry "mise use -g node@lts ; mise use -g python@latest"
else
    for t in $MISE_TOOLS; do
        if "$MISE" which "$t" >/dev/null 2>&1; then
            print_success "$t already managed by mise"
            continue
        fi
        print_step "Installing $t..."
        if ! "$MISE" use -g "$t@latest" >/dev/null 2>&1; then
            print_warn "$t failed to install via mise"
            TOOL_FAILED="$TOOL_FAILED $t"
            continue
        fi
        # A successful fetch is NOT a working binary. mise ships glibc-linked
        # builds: on Debian 12 (glibc 2.36) atuin and yazi install cleanly and
        # then die with "GLIBC_2.39 not found" — and .zshrc evals `atuin init
        # zsh` on EVERY shell start, so a silent pass here becomes an error on
        # every prompt. Verified in a container.
        #
        # Probe by BINARY name, not tool name: mise's `neovim` provides `nvim`,
        # so checking `$t` reported neovim broken on a machine where it worked
        # perfectly — the plugin sync in phase 8 succeeded on that same run.
        bin="$(tool_binary "$t")"
        # `command` skips shell functions and aliases — a tool whose name collides with
        # one must never be able to execute repo code instead of the binary.
        if PATH="$HOME/.local/share/mise/shims:$PATH" command "$bin" "$(version_flag "$bin")" >/dev/null 2>&1; then
            print_success "$t"
        else
            print_warn "$t installed but $bin will not run here (glibc too old?)"
            TOOL_FAILED="$TOOL_FAILED $t"
        fi
    done

    for lang in node@lts python@latest; do
        print_step "Installing $lang..."
        "$MISE" use -g "$lang" >/dev/null 2>&1 \
            && print_success "$lang" \
            || { print_warn "$lang failed"; TOOL_FAILED="$TOOL_FAILED ${lang%@*}"; }
    done
fi

# mise installs are reachable from an interactive zsh via `mise activate` in
# .zshrc — but NOT from this script's own bash. Without the shim dir on PATH the
# later phases could not see anything installed above: phase 8 skipped the nvim
# plugin sync entirely and phase 9 reported six tools missing that were in fact
# installed, then the summary announced gaps that did not exist. Measured in a
# Debian 12 container before this line existed.
export PATH="$HOME/.local/share/mise/shims:$PATH"

# uv — the repo's Python package manager (CLAUDE.md). Its own installer targets
# ~/.local/bin, which is already on PATH above.
if cmd_exists uv; then
    print_success "uv already installed"
elif [ "$DRY_RUN" = true ]; then
    print_dry "curl -LsSf https://astral.sh/uv/install.sh | sh"
else
    print_step "Installing uv..."
    bash -c 'set -o pipefail; curl -LsSf https://astral.sh/uv/install.sh | sh' >/dev/null 2>&1 \
        && print_success "uv installed" \
        || { print_warn "uv install failed"; TOOL_FAILED="$TOOL_FAILED uv"; }
fi

# -----------------------------------------------------------------------------
# 5. STOW
# -----------------------------------------------------------------------------
print_header "5. Dotfiles"

if [ ! -d "$DOTFILES_DIR" ]; then
    print_error "No dotfiles at $DOTFILES_DIR. Clone it there first, or set DOTFILES_DIR."
    exit 1
fi
cd "$DOTFILES_DIR"

if [ ! -r "$PACKAGE_MANIFEST" ]; then
    print_error "Missing $PACKAGE_MANIFEST — cannot determine which packages to stow"
    exit 1
fi

# `|| true` is load-bearing under set -e: an all-comment manifest filters to zero
# lines, grep exits 1, and a bare assignment propagates that status.
PACKAGES="$(sed -e 's/#.*//' -e 's/[[:space:]]//g' "$PACKAGE_MANIFEST" | grep -v '^$' | tr '\n' ' ' || true)"
if [ -z "${PACKAGES// /}" ]; then
    print_error "$PACKAGE_MANIFEST lists no packages — nothing to stow"
    exit 1
fi
print_info "Packages: $PACKAGES"

mkdir -p "$HOME/.config"

STOW_BACKUP_DIR="$HOME/dotfiles-backup-$(date +%Y%m%d-%H%M%S)"
STOW_BACKED_UP=0
STOW_FAILED=0

# One conflicting plain file makes stow refuse the ENTIRE package, so a stray
# ~/.zshrc takes ~/.zprofile with it. Move it aside instead of losing the package.
# Plain FILES only — stow folds into directories rather than conflicting on them.
backup_stow_conflicts() {
    local pkg="$1" out target full
    out="$(stow -n -v -R -t "$HOME" "$pkg" 2>&1)" || true
    while IFS= read -r target; do
        [ -n "$target" ] || continue
        full="$HOME/$target"
        if [ -f "$full" ] && [ ! -L "$full" ]; then
            mkdir -p "$STOW_BACKUP_DIR/$(dirname "$target")"
            mv "$full" "$STOW_BACKUP_DIR/$target"
            print_warn "Moved pre-existing $target -> $STOW_BACKUP_DIR/$target"
            STOW_BACKED_UP=$((STOW_BACKED_UP + 1))
        fi
    # Two message shapes, both seen in practice:
    #   "cannot stow X over existing target Y since ..."
    #   "existing target is neither a link nor a directory: Y"
    # Only the first was parsed, so the mise config collision slipped straight
    # through the backup and failed the whole package.
    done <<< "$(printf '%s\n' "$out" \
        | sed -n -e 's/.*over existing target \(.*\) since.*/\1/p' \
                 -e 's/.*existing target is neither a link nor a directory: \(.*\)$/\1/p')"
}

for pkg in $PACKAGES; do
    if [ ! -d "$DOTFILES_DIR/$pkg" ]; then
        print_warn "No such package directory: $pkg"
        continue
    fi
    if [ "$DRY_RUN" = true ]; then
        print_dry "stow -R -t $HOME $pkg"
        continue
    fi
    backup_stow_conflicts "$pkg"
    if ! stow_err="$(stow -R -t "$HOME" "$pkg" 2>&1)"; then
        print_warn "Failed to stow $pkg:"
        sed 's/^/    /' <<< "$stow_err"
        STOW_FAILED=$((STOW_FAILED + 1))
    fi
done

if [ "$DRY_RUN" = false ]; then
    if [ "$STOW_FAILED" -eq 0 ]; then
        print_success "Dotfiles stowed"
    else
        print_warn "$STOW_FAILED package(s) failed to stow — those configs are NOT deployed"
    fi
    if [ "$STOW_BACKED_UP" -gt 0 ]; then
        print_info "$STOW_BACKED_UP pre-existing file(s) moved to $STOW_BACKUP_DIR (nothing deleted)"
    fi
fi

# The scripts package is stowed whole, then the macOS-only entry points are
# unlinked. They drive BetterDisplay, displayplacer, AeroSpace and sketchybar —
# none of which exist here — so leaving them on PATH would offer the user commands
# that can only fail.
MACOS_ONLY_SCRIPTS="
aerospace-resweep.sh
bd-apply.sh
bd-build-slots.sh
bd-cycle.sh
bd-hdr-toggle.sh
bd-lmu-watch.sh
bd-wake.sh
display-restore.sh
install-linearmouse.sh
kitty-font-per-workspace.sh
render-aerospace.sh
ubersicht-screen-sync.sh
unlock-watch.swift
wallpaper-cycle.sh
wallpaper-rotate.sh
wallpaper-workspace.sh
"
if [ "$DRY_RUN" = true ]; then
    print_dry "unlink $(echo "$MACOS_ONLY_SCRIPTS" | tr '\n' ' ') from ~/scripts"
else
    pruned=0
    for s in $MACOS_ONLY_SCRIPTS; do
        if [ -L "$HOME/scripts/$s" ]; then rm -f "$HOME/scripts/$s"; pruned=$((pruned + 1)); fi
    done
    [ "$pruned" -gt 0 ] && print_info "Unlinked $pruned macOS-only script(s) from ~/scripts"
fi

# -----------------------------------------------------------------------------
# 6. SHELL
# -----------------------------------------------------------------------------
print_header "6. Shell"

ZSH_PATH="$(command -v zsh || true)"
if [ -z "$ZSH_PATH" ]; then
    print_warn "zsh not installed - cannot set it as the default shell"
elif [ "$SHELL" = "$ZSH_PATH" ]; then
    print_success "Default shell is already zsh"
elif [ "$DRY_RUN" = true ]; then
    print_dry "chsh -s $ZSH_PATH"
else
    # chsh prompts for a password and cannot in a non-TTY run (a container, CI, an
    # agent session), so this is advisory rather than attempted-and-failed.
    print_info "Default shell is $SHELL. To switch:  chsh -s $ZSH_PATH"
fi

# -----------------------------------------------------------------------------
# 7. TMUX PLUGIN MANAGER
# -----------------------------------------------------------------------------
print_header "7. Tmux plugins"

# NON-DEFAULT path: tmux.conf sets TMUX_PLUGIN_MANAGER_PATH to
# ~/.config/tmux/.tmux/plugins and runs tpm from there, so a clone into the usual
# ~/.tmux/plugins/tpm is never read and tmux comes up with zero plugins.
if [ -d "$TPM_DIR" ]; then
    print_success "TPM already installed"
elif [ "$DRY_RUN" = true ]; then
    print_dry "git clone https://github.com/tmux-plugins/tpm $TPM_DIR"
else
    print_step "Installing TPM..."
    if git clone -q https://github.com/tmux-plugins/tpm "$TPM_DIR" 2>/dev/null; then
        print_success "TPM installed — run 'prefix + I' inside tmux to fetch plugins"
    else
        print_warn "TPM clone failed"
        TOOL_FAILED="$TOOL_FAILED tpm"
    fi
fi

# -----------------------------------------------------------------------------
# 8. NEOVIM PLUGINS
# -----------------------------------------------------------------------------
print_header "8. Neovim plugins"

if ! cmd_exists nvim; then
    print_warn "nvim not on PATH - skipping plugin sync"
elif [ "$DRY_RUN" = true ]; then
    print_dry "nvim --headless '+Lazy! sync' +qa"
else
    print_step "Syncing Neovim plugins..."
    if nvim --headless "+Lazy! sync" +qa 2>&1 | tail -5; then
        print_success "Neovim plugins synced"
    else
        print_warn "Could not sync Neovim plugins - run ':Lazy sync' inside nvim"
    fi
fi

# -----------------------------------------------------------------------------
# 9. VERIFICATION
# -----------------------------------------------------------------------------
print_header "9. Verification"

ALL_OK=true
# `command -v` is not enough: a mise shim exists for a binary that cannot execute,
# which is exactly how a glibc-broken atuin reported a green tick while erroring on
# every prompt. Run each one.
for tool in zsh tmux nvim stow git fzf rg starship atuin mise eza zoxide yazi bat fd; do
    if ! cmd_exists "$tool"; then
        print_warn "$tool missing"
        ALL_OK=false
    elif command "$tool" "$(version_flag "$tool")" >/dev/null 2>&1; then
        print_success "$tool"
    else
        print_warn "$tool present but will not run (glibc too old?)"
        ALL_OK=false
    fi
done

echo
for link in .zshrc .zprofile .config/nvim .config/tmux .config/starship; do
    if [ -L "$HOME/$link" ] || [ -d "$HOME/$link" ]; then
        print_success "$link deployed"
    else
        print_warn "$link missing"
        ALL_OK=false
    fi
done

# -----------------------------------------------------------------------------
# 10. SUMMARY
# -----------------------------------------------------------------------------
print_header "Done"

if [ -n "$APT_FAILED" ]; then
    print_warn "apt packages that failed:$APT_FAILED"
fi
if [ -n "$TOOL_FAILED" ]; then
    print_warn "tools that failed:$TOOL_FAILED"
    print_info "Retry a single one with:  mise use -g <tool>@latest"
    # Name the actual cause rather than leaving the user to guess. mise ships
    # glibc-linked builds; on Debian 12 (glibc 2.36) current atuin and yazi need
    # GLIBC_2.39 and cannot run at all. Measured in a bookworm container.
    glibc="$(ldd --version 2>/dev/null | head -1 | grep -oE '[0-9]+\.[0-9]+$' || true)"
    if [ -n "$glibc" ]; then
        print_info "This system has glibc $glibc. Tools needing 2.38+ (atuin, yazi)"
        print_info "cannot run below it — Debian 13 / Ubuntu 24.04+ carry a new enough one."
        print_info "The rest of the stack is unaffected and fully working."
    fi
fi

if [ "$ALL_OK" = true ] && [ -z "$APT_FAILED$TOOL_FAILED" ]; then
    print_success "Terminal core installed."
else
    print_warn "Installed with gaps — see the warnings above."
fi

cat <<EOF

Next:
  1. exec zsh                       (or open a new terminal)
  2. prefix + I inside tmux         (fetch tmux plugins; prefix is Ctrl+b)
  3. atuin register -u <user> -e <email>    (optional shell-history sync)

Not installed by design — no Linux build exists: AeroSpace, sketchybar,
Karabiner, Übersicht, LinearMouse, BetterDisplay. See stow-packages.linux.txt.
EOF
