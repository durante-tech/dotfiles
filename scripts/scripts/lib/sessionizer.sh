#!/usr/bin/env bash
# Shared discovery; variables return paths without losing embedded newlines.
sessionizer_canonical() {
    local value
    value="$(cd -P -- "$1" 2>/dev/null && printf '%s/' "$PWD")" || return 1
    SESSIONIZER_CANONICAL="${value%/}"
}

sessionizer_roots() {
    SESSIONIZER_ROOTS=()
    local entry
    if [[ -n "${DOTFILES_SESSIONIZER_PATHS:-}" ]]; then
        while IFS= read -r entry; do
            [[ -n "$entry" ]] || continue
            case "$entry" in \~) entry="$HOME" ;; \~/*) entry="$HOME/${entry#\~/}" ;; esac
            [[ -d "$entry" ]] && SESSIONIZER_ROOTS+=("$entry")
        done <<< "$DOTFILES_SESSIONIZER_PATHS"
    elif [[ -n "${TMUX_SESSIONIZER_PATHS:-}" ]]; then
        local legacy_roots=()
        read -r -a legacy_roots <<< "$TMUX_SESSIONIZER_PATHS"
        for entry in "${legacy_roots[@]}"; do
            [[ -d "$entry" ]] && SESSIONIZER_ROOTS+=("$entry")
        done
    else
        for entry in "${DOTFILES_DIR:-$HOME/dotfiles}" "$HOME/Projects" "$HOME/Developer" "$HOME"; do
            [[ -d "$entry" ]] && SESSIONIZER_ROOTS+=("$entry")
        done
    fi
    if [[ ${#SESSIONIZER_ROOTS[@]} -eq 0 ]]; then
        echo 'No existing project roots are configured.' >&2
        return 2
    fi
}

sessionizer_select() {
    command -v fd >/dev/null 2>&1 && command -v fzf >/dev/null 2>&1 || {
        echo 'Project selection requires fd and fzf.' >&2; return 2;
    }
    sessionizer_roots || return 2
    SESSIONIZER_SELECTED=''
    IFS= read -r -d '' SESSIONIZER_SELECTED < <(
        fd --hidden --type d --max-depth 1 --absolute-path --print0 . "${SESSIONIZER_ROOTS[@]}" |
            fzf --read0 --print0 --prompt='Project> '
    )
}

sessionizer_label() {
    local basename="${1##*/}"
    SESSIONIZER_LABEL="$(printf '%s' "$basename" | LC_ALL=C tr -c '[:alnum:]_-' '_' | cut -c1-32)"
    [[ -n "$SESSIONIZER_LABEL" ]] || SESSIONIZER_LABEL=project
    [[ "$SESSIONIZER_LABEL" != -* ]] || SESSIONIZER_LABEL="p$SESSIONIZER_LABEL"
}

sessionizer_digest() {
    local digest
    if command -v sha256sum >/dev/null 2>&1; then
        digest="$(printf '%s' "$1" | sha256sum)" || return 1
    else
        digest="$(printf '%s' "$1" | shasum -a 256)" || return 1
    fi
    digest="${digest%% *}"
    [[ "$digest" =~ ^[[:xdigit:]]{64}$ ]] || { echo 'Invalid project digest.' >&2; return 1; }
    SESSIONIZER_DIGEST="${digest:0:12}"
}
