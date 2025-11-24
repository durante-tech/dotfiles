# Add deno completions to search path
if [[ ":$FPATH:" != *":/Users/lgertel/.zsh/completions:"* ]]; then export FPATH="/Users/lgertel/.zsh/completions:$FPATH"; fi
# export PATH=$HOME/bin:/usr/local/bin:$PATH
# echo source ~/.bash_profile

eval "$(brew shellenv)"
# source .zprofile in all zsh shells (just in case)
# [[ -f "$HOME/.zprofile" ]] && source "$HOME/.zprofile"

eval "$(gdircolors)"

source $ZSH/oh-my-zsh.sh

# unbind ctrl g in terminal
bindkey -r "^G"

# Starship
bindkey -v
if [[ "${widgets[zle-keymap-select]#user:}" == "starship_zle-keymap-select" || \
      "${widgets[zle-keymap-select]#user:}" == "starship_zle-keymap-select-wrapped" ]]; then
    zle -N zle-keymap-select "";
fi
eval "$(starship init zsh)"

# Force yellow cursor in all vim modes (must be after Starship init)
# Uses OSC 12 escape sequence to set cursor color
_set_yellow_cursor() {
  echo -ne "\e]12;#ffff00\a"
}

function zle-keymap-select {
  _set_yellow_cursor
}

function zle-line-init {
  _set_yellow_cursor
}

function zle-line-finish {
  _set_yellow_cursor
}

zle -N zle-keymap-select
zle -N zle-line-init
zle -N zle-line-finish

# Set yellow cursor on shell startup
_set_yellow_cursor

# Zoxide
eval "$(zoxide init zsh)"

# FZF
eval "$(fzf --zsh)"

# FZF with Git right in the shell by Junegunn : check out his github below
# Keymaps for this is available at https://github.com/junegunn/fzf-git.sh
[ -f "$HOME/scripts/fzf-git.sh" ] && source "$HOME/scripts/fzf-git.sh"

# Atuin Configs
export ATUIN_NOBIND="true"
eval "$(atuin init zsh)"
# bindkey '^r' _atuin_search_widget
bindkey '^r' atuin-up-search-viins

# Pyenv
eval "$(pyenv init -)"

#User configuration
# export MANPATH="/usr/local/man:$MANPATH"

#----- Vim Editing modes & keymaps ------
set -o vi

export EDITOR=nvim
export VISUAL=nvim

bindkey -M viins '^E' autosuggest-accept
bindkey -M viins '^P' up-line-or-history
bindkey -M viins '^N' down-line-or-history

# Shift+Enter for Ghostty (handles both escape sequence and fixterms)
bindkey -M viins '^[^M' accept-line  # ESC+Enter
bindkey -M viins '^[[27;2;13~' accept-line  # Ghostty fixterms sequence

#----------------------------------------

# zsh plugins
plugins=(
    git
    ## with oh-my-zsh and not homebrew
    # zsh-autosuggestions ( git clone <find link in the repo> and uncomment  )
    # zsh-syntax-highlighting ( git clone <find link in the repo> and uncomment )
    web-search
)

# -------------------ALIAS----------------------
# These alias need to have the same exact space as written here
# HACK: For Running Go Server using Air
alias air='$(go env GOPATH)/bin/air'

# other Aliases shortcuts
alias c="clear"
alias e="exit"
alias vim="nvim"

# Tmux
alias tmux="tmux -f $TMUX_CONF"
alias a="attach"
# calls the tmux new session script
alias tns="$HOME/scripts/tmux-sessionizer"

# fzf
# called from ~/scripts/
alias nlof="$HOME/scripts/fzf_listoldfiles.sh"
# opens documentation through fzf (eg: git,zsh etc.)
alias fman="compgen -c | fzf | xargs man"

# zoxide (called from ~/scripts/)
alias nzo="$HOME/scripts/zoxide_openfiles_nvim.sh"

# Eza - Next level ls with git integration
# Basic ls with git status indicators (M=modified, N=new, I=ignored, etc.)
alias ls="eza --long --color=always --icons=always --no-user --no-filesize --git"

# All files including hidden, with git status
alias la="eza --long --all --color=always --icons=always --no-user --git"

# Long format with file sizes and timestamps
alias ll="eza --long --all --color=always --icons=always --no-user --git --header --group"

# Tree view with git integration (ignores .git directory)
alias lt="eza --tree --level=2 --color=always --icons=always --git --git-ignore"
alias lt3="eza --tree --level=3 --color=always --icons=always --git --git-ignore"

# Only directories
alias lsd="eza --long --only-dirs --color=always --icons=always --no-user --git"

# Sort by modified time (newest first)
alias lm="eza --long --all --color=always --icons=always --no-user --git --sort=modified --reverse"

# Sort by size (largest first)
alias lz="eza --long --all --color=always --icons=always --no-user --git --sort=size --reverse"

# Git-specific: show only modified/new files
alias lg="eza --long --all --color=always --icons=always --no-user --git --git-ignore --only-files"

# Classic tree command (fallback)
alias tree="tree -L 3 -a -I '.git' --charset X "
alias dtree="tree -L 3 -a -d -I '.git' --charset X "

# lstr
alias lstr="lstr --icons"

# git aliases
alias gt="git"
alias ga="git add ."
alias gs="git status -s"
alias gc='git commit -m'
alias glog='git log --oneline --graph --all'
alias gh-create='gh repo create --private --source=. --remote=origin && git push -u --all && gh browse'

alias nvim-scratch="NVIM_APPNAME=nvim-scratch nvim"

# lazygit
alias lg="lazygit"

# mpd start alias
alias mpds="mpd ~/.config/mpd/mpd.conf"

# obsidian icloud path (customize for your vault)
# alias vault="cd ~/Library/Mobile\ Documents/iCloud~md~obsidian/Documents/YourVaultName/"

# Fabric AI aliases
alias fb="fabric"
alias fbp="fabric --pattern"
alias fbl="fabric --listpatterns"
alias fbs="fabric --stream"
alias fbsp="fabric --stream --pattern"

# Dynamically create aliases for all Fabric patterns
# Loop through all files in the ~/.config/fabric/patterns directory
for pattern_file in $HOME/.config/fabric/patterns/*; do
    # Get the base name of the file (i.e., remove the directory path)
    pattern_name="$(basename "$pattern_file")"
    alias_name="${FABRIC_ALIAS_PREFIX:-}${pattern_name}"

    # Create an alias in the form: alias pattern_name="fabric --pattern pattern_name"
    alias_command="alias $alias_name='fabric --pattern $pattern_name'"

    # Evaluate the alias command to add it to the current shell
    eval "$alias_command"
done

# Fabric YouTube transcript function
yt() {
    if [ "$#" -eq 0 ] || [ "$#" -gt 2 ]; then
        echo "Usage: yt [-t | --timestamps] youtube-link"
        echo "Use the '-t' flag to get the transcript with timestamps."
        return 1
    fi

    transcript_flag="--transcript"
    if [ "$1" = "-t" ] || [ "$1" = "--timestamps" ]; then
        transcript_flag="--transcript-with-timestamps"
        shift
    fi
    local video_link="$1"
    fabric -y "$video_link" $transcript_flag
}

# Claude CLI aliases
alias cld="claude"
alias cldp="claude -p"
alias cldo="claude --model opus"
alias clds="claude --model sonnet"
alias cldys="claude --dangerously-skip-permissions --model sonnet"
alias cldy="claude --dangerously-skip-permissions --model sonnet"
alias cldyo="claude --dangerously-skip-permissions --model opus"
alias lfg="claude --dangerously-skip-permissions --model opus"
alias cldpy="claude -p --dangerously-skip-permissions"
alias cldpyo="claude -p --dangerously-skip-permissions --model opus"
alias cldr="claude --resume"
# ---------------------------------------

# brew installations activation (new mac systems brew path: opt/homebrew , not usr/local )
source $(brew --prefix)/share/zsh-autosuggestions/zsh-autosuggestions.zsh
source $(brew --prefix)/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh

[ -s "$HOME/.deno/env" ] && . "$HOME/.deno/env"

if [[ -x "$HOME/.claude/local/claude" ]]; then
    alias claude="$HOME/.claude/local/claude"
elif command -v claude >/dev/null 2>&1; then
    alias claude="$(command -v claude)"
fi
source ~/Developer/tac/scripts/aliases.sh
source ~/Developer/tac/scripts/aliases.sh
