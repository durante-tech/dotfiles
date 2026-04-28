# Kitty-in-tmux: propagate KITTY env vars so kitty graphics protocol works
if [[ -n "$TMUX" && -z "$KITTY_PID" ]]; then
    local _kitty_pid
    _kitty_pid=$(pgrep -a kitty 2>/dev/null | grep -v 'kitten\|ssh' | head -1 | awk '{print $1}')
    if [[ -n "$_kitty_pid" ]]; then
        export KITTY_PID="$_kitty_pid"
        # Resolve KITTY_WINDOW_ID from kitty's environment
        local _kitty_wid
        _kitty_wid=$(command ps -p "$_kitty_pid" -o command= 2>/dev/null | grep -q kitty && echo "1")
        export KITTY_WINDOW_ID="${_kitty_wid:-1}"
        # Inject into tmux server so new panes/windows inherit
        tmux setenv KITTY_PID "$KITTY_PID" 2>/dev/null
        tmux setenv KITTY_WINDOW_ID "$KITTY_WINDOW_ID" 2>/dev/null
    fi
fi

# Add deno completions to search path
if [[ ":$FPATH:" != *":$HOME/.zsh/completions:"* ]]; then export FPATH="$HOME/.zsh/completions:$FPATH"; fi
# export PATH=$HOME/bin:/usr/local/bin:$PATH
# echo source ~/.bash_profile

# Note: .zprofile is automatically sourced by login shells
# Removed explicit source to avoid duplicate initialization (fnm, brew, etc.)

command -v gdircolors &>/dev/null && eval "$(gdircolors)"

# Note: Oh-My-Zsh removed for faster startup (~200ms savings)
# Git aliases and web-search functions are now defined manually below

# unbind ctrl g in terminal
bindkey -r "^G"

# Vi mode + Starship (vi mode must be set BEFORE starship init so Starship
# can register its zle-keymap-select handler for vi-mode indicators)
set -o vi
eval "$(starship init zsh)"

# Zoxide
command -v zoxide &>/dev/null && eval "$(zoxide init zsh)"

# FNM auto-switch on cd (hook only - base env in .zprofile)
autoload -U add-zsh-hook
_fnm_autoload_hook() {
    [[ -f .node-version || -f .nvmrc ]] && fnm use --silent-if-unchanged
}
add-zsh-hook chpwd _fnm_autoload_hook

# FZF
command -v fzf &>/dev/null && eval "$(fzf --zsh)"

# FZF with Git right in the shell by Junegunn : check out his github below
# Keymaps for this is available at https://github.com/junegunn/fzf-git.sh
[ -f "$HOME/scripts/fzf-git.sh" ] && source "$HOME/scripts/fzf-git.sh"

# Atuin Configs
export ATUIN_NOBIND="true"
command -v atuin &>/dev/null && eval "$(atuin init zsh)"
# bindkey '^r' _atuin_search_widget
bindkey '^r' atuin-up-search-viins

# Pyenv
command -v pyenv &>/dev/null && eval "$(pyenv init -)"

#User configuration
# export MANPATH="/usr/local/man:$MANPATH"

#----- Vim Editing modes & keymaps ------
# Note: set -o vi is done before starship init (above) so Starship's
# vi-mode handler isn't clobbered

export EDITOR=nvim
export VISUAL=nvim

bindkey -M viins '^E' autosuggest-accept
bindkey -M viins '^P' up-line-or-history
bindkey -M viins '^N' down-line-or-history

# Shift+Enter for Ghostty — disabled, conflicts with Claude Code multi-line input
# bindkey -M viins '^[^M' accept-line  # ESC+Enter
# bindkey -M viins '^[[27;2;13~' accept-line  # Ghostty fixterms sequence

#----------------------------------------

# Web search functions (replaces oh-my-zsh web-search plugin)
# Use 'open' on macOS, 'xdg-open' on Linux
if [[ "$(uname)" == "Darwin" ]]; then
    _open_cmd="open"
else
    _open_cmd="xdg-open"
fi
google() { $_open_cmd "https://www.google.com/search?q=${(j:+:)@}" }
ddg() { $_open_cmd "https://duckduckgo.com/?q=${(j:+:)@}" }
github() { $_open_cmd "https://github.com/search?q=${(j:+:)@}" }

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
alias a="tmux attach"
# calls the tmux new session script
alias tns="$HOME/scripts/tmux-sessionizer"

# fzf
# called from ~/scripts/
alias nlof="$HOME/scripts/fzf_listoldfiles.sh"
# opens documentation through fzf (eg: git,zsh etc.)
alias fman='print -rl -- ${(k)commands} | fzf | xargs man'

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

# Git-specific: show only modified/new files (use lsg to avoid conflict with lazygit)
alias lsg="eza --long --all --color=always --icons=always --no-user --git --git-ignore --only-files"

# Classic tree command (fallback)
alias tree="tree -L 3 -a -I '.git' --charset X "
alias dtree="tree -L 3 -a -d -I '.git' --charset X "

# lstr (requires lstr to be installed: cargo install lstr)
# alias lstr="lstr --icons"

# Modern CLI tools (Rust/Go replacements)
alias ps="procs"                          # Better ps with colors and search
alias top="btm"                           # Better top/htop with graphs
alias htop="btm"                          # bottom is the new htop
alias curl="curlie"                       # curl with syntax highlighting
alias cat="bat"                           # Already have bat, ensure alias
alias du="dust"                           # Visual disk usage

# Productivity tools
alias y="yazi"                            # Fast file manager
alias br="broot"                          # Interactive tree navigation
alias json="fx"                           # Interactive JSON viewer
alias cheat="navi"                        # Interactive cheatsheets

# Git info
alias ginfo="onefetch"                    # Git repo summary (like neofetch for repos)

# Yazi with cd on exit (changes to last visited directory)
function ya() {
    local tmp
    tmp=$(mktemp -t "yazi-cwd.XXXXXX") || return 1
    trap "rm -f -- '$tmp'" RETURN
    yazi "$@" --cwd-file="$tmp" || return
    local cwd
    if cwd=$(cat -- "$tmp" 2>/dev/null) && [[ -n "$cwd" ]] && [[ "$cwd" != "$PWD" ]]; then
        cd -- "$cwd"
    fi
}

# -------------------GIT ALIASES----------------------
# Consolidated git shortcuts (was scattered across file)
alias gt="git"
alias ga="git add ."
alias gs="git status -s"
alias gc='git commit -m'
alias gco='git checkout'
alias gcb='git checkout -b'
alias gp='git push'
alias gl='git pull'
alias gd='git diff'
alias gds='git diff --staged'
alias gb='git branch'
alias gba='git branch -a'
alias glog='git log --oneline --graph --all'
alias gh-create='gh repo create --private --source=. --remote=origin && git push -u --all && gh browse'
# ----------------------------------------------------

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

# Cached Fabric pattern aliases (regenerates only when patterns directory changes)
# This saves ~150-250ms on every shell startup
FABRIC_ALIAS_CACHE="$HOME/.cache/fabric-aliases.zsh"
FABRIC_PATTERNS_DIR="$HOME/.config/fabric/patterns"

if [[ -d "$FABRIC_PATTERNS_DIR" ]]; then
    # Regenerate cache if it doesn't exist or patterns directory is newer
    if [[ ! -f "$FABRIC_ALIAS_CACHE" ]] || [[ "$FABRIC_PATTERNS_DIR" -nt "$FABRIC_ALIAS_CACHE" ]]; then
        mkdir -p "$(dirname "$FABRIC_ALIAS_CACHE")"
        {
            echo "# Auto-generated Fabric pattern aliases - $(date)"
            for pattern_file in "$FABRIC_PATTERNS_DIR"/*; do
                pattern_name="$(basename "$pattern_file")"
                echo "alias ${pattern_name}='fabric --pattern ${pattern_name}'"
            done
        } > "$FABRIC_ALIAS_CACHE"
    fi
    # Source the cached aliases
    [[ -f "$FABRIC_ALIAS_CACHE" ]] && source "$FABRIC_ALIAS_CACHE"
fi

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
alias cldy="claude --dangerously-skip-permissions --model sonnet"
alias cldyo="claude --dangerously-skip-permissions --model opus"
alias lfg="claude --dangerously-skip-permissions --model opus"
alias cldpy="claude -p --dangerously-skip-permissions"
alias cldpyo="claude -p --dangerously-skip-permissions --model opus"
alias cldr="claude --resume"
alias dosa="dos -l -m full --dangerously-skip-permissions"
# ---------------------------------------

# brew installations activation
BREW_PREFIX="${HOMEBREW_PREFIX:-/opt/homebrew}"
[ -f "$BREW_PREFIX/share/zsh-autosuggestions/zsh-autosuggestions.zsh" ] && source "$BREW_PREFIX/share/zsh-autosuggestions/zsh-autosuggestions.zsh"
[ -f "$BREW_PREFIX/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh" ] && source "$BREW_PREFIX/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh"

[ -s "$HOME/.deno/env" ] && . "$HOME/.deno/env"

if [[ -x "$HOME/.claude/local/claude" ]]; then
    alias claude="$HOME/.claude/local/claude"
elif command -v claude >/dev/null 2>&1; then
    alias claude="$(command -v claude)"
fi
# Zsh completions (needed after oh-my-zsh removal)
autoload -Uz compinit && compinit -C

# Source project-specific aliases if they exist
[[ -f ~/Developer/tac/scripts/aliases.sh ]] && source ~/Developer/tac/scripts/aliases.sh

# Source machine-specific local overrides (not tracked in git)
[[ -f ~/.zshrc.local ]] && source ~/.zshrc.local

# bun completions (sourced in .zprofile, not duplicated here)

# The following lines have been added by Docker Desktop to enable Docker CLI completions.
fpath=(/Users/lgertel/.docker/completions $fpath)
autoload -Uz compinit
compinit
# End of Docker CLI completions

# Added by LM Studio CLI (lms)
export PATH="$PATH:/Users/lgertel/.lmstudio/bin"
# End of LM Studio CLI section


# pnpm
export PNPM_HOME="/Users/lgertel/Library/pnpm"
case ":$PATH:" in
  *":$PNPM_HOME:"*) ;;
  *) export PATH="$PNPM_HOME:$PATH" ;;
esac
# pnpm end



# Added by Antigravity
export PATH="/Users/lgertel/.antigravity/antigravity/bin:$PATH"

# PAI alias
alias pai='bun /Users/lgertel/.claude/PAI/Tools/pai.ts'

# Added by Antigravity
export PATH="/Users/lgertel/.antigravity/antigravity/bin:$PATH"

# Durante CLI: distribution tool (install/upgrade/status/doctor)
alias durante="node /Users/lgertel/Durante/npm-package/bin/dos.js"

# DOS alias
alias dos='bun /Users/lgertel/.claude/DOS/Tools/dos.ts'
