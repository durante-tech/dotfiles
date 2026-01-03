#!/bin/bash

# Install xCode cli tools
if [[ "$(uname)" == "Darwin" ]]; then
    echo "macOS detected..."

    if xcode-select -p &>/dev/null; then
        echo "Xcode already installed"
    else
        echo "Installing commandline tools..."
        xcode-select --install
    fi
fi

# Install oh-my-zsh
sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
## install zsh-autosuggestions
# git clone https://github.com/zsh-users/zsh-autosuggestions.git $ZSH_CUSTOM/plugins/zsh-autosuggestions
## install zsh-syntax-highlighting
# git clone https://github.com/zsh-users/zsh-syntax-highlighting.git $ZSH_CUSTOM/plugins/zsh-syntax-highlighting

# Homebrew
## Install
echo "Installing Brew..."
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
brew analytics off

## Taps
echo "Tapping Brew..."
# Note: homebrew/cask-fonts is deprecated, fonts are now in homebrew/cask
brew tap FelixKratz/formulae
brew tap nikitabobko/tap

## Formulae
echo "Installing Brew Formulae..."

## Core Utils
echo "Install gnu coreutils"
brew install coreutils

### Must Have things
brew install zsh-autosuggestions
brew install zsh-syntax-highlighting
brew install stow
brew install fzf
brew install bat
brew install fd
brew install zoxide
brew install lua
brew install luajit
brew install luarocks
brew install prettier
brew install make
brew install qmk
brew install ripgrep

### Terminal
brew install git
brew install lazygit
brew install tmux
brew install neovim
brew install starship
brew install tree-sitter
brew install tree
brew install borders
brew install eza
brew install atuin
brew install yazi
brew install w3m
brew install sketchybar

### Modern CLI replacements (Rust/Go)
brew install procs       # Better ps
brew install bottom      # Better htop
brew install curlie      # Better curl
brew install onefetch    # Git repo info
brew install fx          # JSON viewer
brew install navi        # Interactive cheatsheets
brew install broot       # Interactive tree
brew install dust        # Better du
brew install mpd
brew install rmpc

### dev things
brew install node
brew install nvm
brew install sqlite
brew install pyenv

## Casks
brew install --cask raycast
brew install --cask karabiner-elements
brew install --cask wezterm
brew install --cask ghostty
brew install --cask aerospace
brew install --cask keycastr
brew install --cask betterdisplay
brew install --cask linearmouse
brew install --cask font-hack-nerd-font
brew install --cask font-jetbrains-mono-nerd-font
brew install --cask font-sf-pro

## MacOS settings
echo "Changing macOS defaults..."
defaults write com.apple.Dock autohide -bool TRUE
defaults write NSGlobalDomain KeyRepeat -int 2
defaults write NSGlobalDomain InitialKeyRepeat -int 15

csrutil status
echo "Installation complete..."

# Clone dotfiles repository
if [ ! -d "$HOME/dotfiles" ]; then
  echo "Cloning dotfiles repository..."
  git clone https://github.com/Sin-cy/dotfiles.git $HOME/dotfiles
fi

# Note: coreutils PATH is already set in .zprofile (stowed from zsh package)

# Navigate to dotfiles directory
cd $HOME/dotfiles || exit

# Stow dotfiles packages
echo "Stowing dotfiles..."
# Core packages (nvim not neovim - matches directory name)
stow -t ~ aerospace alacritty atuin ghostty karabiner mpd nvim rmpc scripts sketchybar starship tmux w3m wezterm yazi zed zsh

echo "Dotfiles setup complete!"

