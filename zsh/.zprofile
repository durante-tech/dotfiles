# Homebrew - works on both ARM (/opt/homebrew) and Intel (/usr/local)
if [[ -f /opt/homebrew/bin/brew ]]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
elif [[ -f /usr/local/bin/brew ]]; then
    eval "$(/usr/local/bin/brew shellenv)"
fi

export LANG=en_US.UTF-8

#------------All PATHS------------
# GNU coreutils (uses HOMEBREW_PREFIX set by brew shellenv)
[[ -d "$HOMEBREW_PREFIX/opt/coreutils/libexec/gnubin" ]] && export PATH="$HOMEBREW_PREFIX/opt/coreutils/libexec/gnubin:$PATH"

# uv (Python package manager)
export PATH="$HOME/.local/bin:$PATH"

# grok CLI — guarded; installer originally appended an unguarded block to .zshrc
[[ -d "$HOME/.grok/bin" ]] && export PATH="$HOME/.grok/bin:$PATH"

# Add local ~/scripts to the PATH
export PATH="$HOME/scripts:$PATH"

# Mason
export PATH="$HOME/.local/share/nvim/mason/bin:$PATH"

# Tmux
export TMUX_CONF="$HOME/.config/tmux/tmux.conf"

# 1Password SSH Agent
# Use 1Password for SSH key management (validate socket exists first)
if [[ "$(uname)" == "Darwin" ]]; then
    _1password_sock="$HOME/Library/Group Containers/2BUA8C4S2C.com.1password/t/agent.sock"
else
    # Linux 1Password socket location
    _1password_sock="$HOME/.1password/agent.sock"
fi
[[ -S "$_1password_sock" ]] && export SSH_AUTH_SOCK="$_1password_sock"
unset _1password_sock

# Starship PATH
export STARSHIP_CONFIG="$HOME/.config/starship/starship.toml"

# Using Starship for shell prompt

# ------------FZF--------------
# Set up fzf key bindings and fuzzy completion
export FZF_DEFAULT_COMMAND="fd --hidden --strip-cwd-prefix --exclude .git --exclude node_modules --exclude .venv --exclude __pycache__ --exclude dist --exclude build"
export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
export FZF_ALT_C_COMMAND="fd --type=d --hidden --strip-cwd-prefix --exclude .git --exclude node_modules --exclude .venv"

export FZF_DEFAULT_OPTS="--height 50% --layout=default --border --color=hl:#2dd4bf"

# Setup fzf previews
export FZF_CTRL_T_OPTS="--preview 'bat --color=always -n --line-range :500 {}'"
export FZF_ALT_C_OPTS="--preview 'eza --icons=always --tree --color=always {} | head -200'"

# fzf preview for tmux
export FZF_TMUX_OPTS=" -p90%,70% "  
# -----------------------------

# bun
# bun completions
[ -s "$HOME/.bun/_bun" ] && source "$HOME/.bun/_bun"
export BUN_INSTALL="$HOME/.bun"
export PATH="$BUN_INSTALL/bin:$PATH"

#------------Langs------------

# Node + Python managed by mise (activated in .zshrc); fnm + pyenv fully retired.

# Golang
export GOPATH=$HOME/go
export PATH=$GOPATH/bin:$PATH

# Flutter via fvm (global SDK) + Dart pub-cache executables (very_good_cli, etc.)
export PATH="$HOME/fvm/default/bin:$HOME/.pub-cache/bin:$PATH"

# Fabric AI
export FABRIC_ROOT="$HOME/.config/fabric"

# GitHub MCP server (Claude Code `github` plugin) — reads the token from the gh
# keyring at login so no secret is stored on disk. Needs an authenticated gh.
if command -v gh >/dev/null 2>&1; then
  export GITHUB_PERSONAL_ACCESS_TOKEN="$(gh auth token 2>/dev/null)"
fi

# Generated for envman. Do not edit.
[ -s "$HOME/.config/envman/load.sh" ] && source "$HOME/.config/envman/load.sh"

# SDKMAN — JVM toolchain manager (java, kotlin, gradle, maven, scala, sbt).
# Complements mise, which owns Node + Python only; there is no overlap today.
#
# This is the CANONICAL init and lives in .zprofile, not .zshrc, because
# sdkman-init.sh exports JAVA_HOME and prepends PATH — login-shell concerns,
# same as bun above — and it works in non-interactive shells, which .zshrc
# never reaches.
#
# The upstream installer appends its own copy of this snippet to
# ${ZDOTDIR:-$HOME}/.zshrc. Here that path is a SYMLINK into this repo, so the
# append writes straight through into zsh/.zshrc and dirties git — which is
# exactly how a previous install silently lost its init when the working tree
# was later restored. install.sh §5 redirects ZDOTDIR to a throwaway dir to
# stop that; if you ever run the installer by hand, do the same:
#     ZDOTDIR="$(mktemp -d)" bash -c 'curl -fsSL https://get.sdkman.io | bash'
#
# Placed BEFORE the ~/.zprofile.local hook below, deliberately against SDKMAN's
# own "must be at the end of the file" instruction. That instruction exists so
# SDKMAN's PATH wins over anything later; here the whole point of .zprofile.local
# is that a machine CAN pin a different JDK, and it cannot do that if this block
# re-exports JAVA_HOME afterwards.
export SDKMAN_DIR="$HOME/.sdkman"
[ -s "$SDKMAN_DIR/bin/sdkman-init.sh" ] && source "$SDKMAN_DIR/bin/sdkman-init.sh"




# Added by OrbStack: command-line tools and integration
# This won't be added again if you remove it.
source ~/.orbstack/shell/init.zsh 2>/dev/null || :

# >>> localcan >>>
export PATH="$HOME/.localcan/bin:$PATH"
# <<< localcan <<<

# Added by Obsidian
export PATH="$PATH:/Applications/Obsidian.app/Contents/MacOS"

# Final login-shell overrides (not tracked in Git).
[[ -f ~/.zprofile.local ]] && source ~/.zprofile.local
