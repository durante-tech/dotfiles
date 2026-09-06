#!/usr/bin/env bash
# No side effects when sourced. The installer owns the option contract.
dotfiles_preview() {
    local manifest="$DOTFILES_DIR/stow-packages.txt" pkg listed=0
    [[ -r "$manifest" ]] || { echo "Missing package manifest: $manifest" >&2; return 1; }
    echo "Preview only — no commands below are executed. Repository: $DOTFILES_DIR"
    if "$PROVISION_TOOLS"; then
        echo "Provision requested toolchains, global CLIs and the Neovim provider environment."
        if ! "$SKIP_BREW" || ! "$SKIP_CASKS"; then
            dotfiles_bundle_args
            printf 'brew'; printf ' %q' "${BUNDLE_ARGS[@]}"; printf '\n'
        fi
        if ! "$SKIP_CASKS"; then echo "Install the pinned LinearMouse release if needed."; fi
    fi
    echo "Render AeroSpace configuration and apply these Stow packages:"
    while IFS= read -r pkg; do
        if [[ -n "$pkg" ]]; then printf '  %s\n' "$pkg"; listed=$((listed + 1)); fi
    done < <(sed -e 's/#.*//' -e 's/[[:space:]]//g' "$manifest")
    (( listed > 0 )) || { echo "Package manifest is empty" >&2; return 1; }
    echo "Synchronize Neovim and tmux plugins (including plugin-local build dependencies)."
    if ! "$UPDATE_ONLY"; then
        echo "Fresh setup: configure native helpers, owned services and explicit setup integrations."
        if ! "$SKIP_MACOS_DEFAULTS"; then echo "Apply macOS defaults on macOS."; fi
    fi
    dotfiles_reload_steps
}

dotfiles_reload_steps() {
    cat <<'STEPS'
Reload when convenient (no extra restart is triggered by an update):
  Open a new terminal for Zsh changes.
  tmux source-file ~/.config/tmux/tmux.conf
  aerospace reload-config
  sketchybar --reload
  Restart Neovim for plugin/configuration changes.
  Reload Kitty with Cmd+B, then r (the configured prefix binding).
  Review changed LaunchAgent templates before explicit setup.sh --configure.
STEPS
}

dotfiles_sync_plugins() {
    local failed=0 tpm="$HOME/.config/tmux/.tmux/plugins/tpm" plugins
    if command -v nvim >/dev/null 2>&1; then
        DOTFILES_CONFIG_ONLY=1 nvim --headless '+Lazy! sync' +qa || failed=1
    else
        echo "Neovim is missing; plugin sync was not run. Provision tools explicitly." >&2
        failed=1
    fi
    if [[ -d "$tpm/.git" ]]; then
        git -C "$tpm" pull --ff-only || failed=1
        # TPM's interactive updater reloads the server. Read the declarative
        # plugin lines instead, preserving unlisted plugin repositories.
        plugins="$(dirname "$tpm")"
        local plugin destination config="$DOTFILES_DIR/tmux/.config/tmux/tmux.conf"
        if [[ ! -r "$config" ]]; then
            echo "tmux plugin configuration is missing" >&2
            failed=1
        else
            while IFS= read -r plugin; do
                [[ "$plugin" =~ ^[a-zA-Z0-9_.-]+/[a-zA-Z0-9_.-]+$ ]] || {
                    echo "Unsupported plugin reference: $plugin" >&2; failed=1; continue;
                }
                destination="$plugins/${plugin##*/}"
                [[ "$destination" == "$tpm" ]] && continue
                if [[ -d "$destination/.git" ]]; then
                    git -C "$destination" pull --ff-only || failed=1
                elif [[ -e "$destination" ]]; then
                    echo "Plugin target is not a Git checkout: $destination" >&2
                    failed=1
                else
                    git clone "https://github.com/$plugin" "$destination" || failed=1
                fi
            done < <(sed -nE "s|^[[:space:]]*set(-option)?[[:space:]]+-g[[:space:]]+@plugin[[:space:]]+['\"]([^'\"]+)['\"].*|\\2|p" "$config")
        fi
    else
        echo "TPM is missing; tmux plugin sync was not run. Use explicit setup." >&2
        failed=1
    fi
    return "$failed"
}

dotfiles_update() {
    local failed=0
    [[ -x "$DOTFILES_DIR/setup.sh" ]] || { echo 'setup.sh is missing or not executable' >&2; return 1; }
    "$DOTFILES_DIR/setup.sh" --stow || failed=1
    dotfiles_sync_plugins || failed=1
    "$DOTFILES_DIR/setup.sh" --check || failed=1
    dotfiles_reload_steps
    if (( failed )); then
        echo 'Update incomplete: required phases failed; see diagnostics above.' >&2
    else
        echo 'Configuration and plugin update completed.'
    fi
    return "$failed"
}
