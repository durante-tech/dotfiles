export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"

eval "$(/opt/homebrew/bin/brew shellenv)"

export LANG=en_US.UTF-8

#------------All PATHS------------
# GNU coreutils
export PATH="/opt/homebrew/opt/coreutils/libexec/gnubin:$PATH"

# uv (Python package manager)
export PATH="$HOME/.local/bin:$PATH"

# Add local ~/scripts to the PATH
export PATH="$HOME/scripts:$PATH"

# Mason
export PATH="$HOME/.local/share/nvim/mason/bin:$PATH"

# Tmux
export TMUX_CONF="$HOME/.config/tmux/tmux.conf"

# 1Password SSH Agent
# Use 1Password for SSH key management
export SSH_AUTH_SOCK="$HOME/Library/Group Containers/2BUA8C4S2C.com.1password/t/agent.sock"

# Starship PATH
export STARSHIP_CONFIG="$HOME/.config/starship/starship.toml"

# Tealdeer
export TEALDEER_CONFIG_DIR="$HOME/.config/tealdeer/"

# Path to your oh-my-zsh installation.
# NOTE : Disabled Shell Prompt: Currently using Starship
# NOTE: using oh-my-zsh only for zsh plugins management
export ZSH="$HOME/.oh-my-zsh"

# Using Starship instead of p10k
# export ZSH_THEME="powerlevel10k/powerlevel10k"

# ------------FZF--------------
# Set up fzf key bindings and fuzzy completion
export FZF_DEFAULT_COMMAND="fd --hidden --strip-cwd-prefix --exclude .git "
export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
export FZF_ALT_C_COMMAND="fd --type=d --hidden --strip-cwd-prefix --exclude .git"

export FZF_DEFAULT_OPTS="--height 50% --layout=default --border --color=hl:#2dd4bf"

# Setup fzf previews
export FZF_CTRL_T_OPTS="--preview 'bat --color=always -n --line-range :500 {}'"
export FZF_ALT_C_OPTS="--preview 'eza --icons=always --tree --color=always {} | head -200'"

# fzf preview for tmux
export FZF_TMUX_OPTS=" -p90%,70% "  
# -----------------------------

# NVM 
export NVM_DIR="$HOME/.nvm"
[ -s "/opt/homebrew/opt/nvm/nvm.sh" ] && \. "/opt/homebrew/opt/nvm/nvm.sh"  # This loads nvm
[ -s "/opt/homebrew/opt/nvm/etc/bash_completion.d/nvm" ] && \. "/opt/homebrew/opt/nvm/etc/bash_completion.d/nvm"  # This loads nvm bash_completion

# Console Ninja
export PATH=~/.console-ninja/.bin:$PATH

# bun
# bun completions
[ -s "$HOME/.bun/_bun" ] && source "$HOME/.bun/_bun"
export BUN_INSTALL="$HOME/.bun"
export PATH="$BUN_INSTALL/bin:$PATH"

# 010 Hex Editor
export PATH="$PATH:/Applications/010 Editor.app/Contents/CmdLine" #ADDED BY 010 EDITOR

#------------Langs------------

# Pyenv
export PYENV_ROOT="$HOME/.pyenv"
export PATH="$PYENV_ROOT/bin:$PATH"
eval "$(pyenv init --path)"

# Golang
export GOPATH=$HOME/go
export PATH=$GOPATH/bin:$PATH
export PATH=$PATH:$(go env GOPATH)/bin

# Fabric AI
export FABRIC_ROOT="$HOME/.config/fabric"

# Setting PATH for Python 3.11
# The original version is saved in .zprofile.pysave
PATH="/Library/Frameworks/Python.framework/Versions/3.11/bin:${PATH}"
export PATH






# Generated for envman. Do not edit.
[ -s "$HOME/.config/envman/load.sh" ] && source "$HOME/.config/envman/load.sh"


