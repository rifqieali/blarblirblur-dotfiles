# If you come from bash you might have to change your $PATH.
# export PATH=$HOME/bin:/usr/local/bin:$PATH

export ZSH="$HOME/.oh-my-zsh"

export PATH="$HOME/.config/composer/vendor/bin:$PATH"
#export PATH="$HOME/.composer/vendor/bin:$PATH"


ZSH_THEME="funky"

plugins=(
    git
    archlinux
    zsh-autosuggestions
    zsh-syntax-highlighting
    z
    sudo
    history
    dirhistory
)

[ -f "$ZSH/oh-my-zsh.sh" ] && source "$ZSH/oh-my-zsh.sh"

# Check archlinux plugin commands here
# https://github.com/ohmyzsh/ohmyzsh/tree/master/plugins/archlinux

# Display Pokemon-colorscripts
# Project page: https://gitlab.com/phoneybadger/pokemon-colorscripts#on-other-distros-and-macos
#pokemon-colorscripts --no-title -s -r #without fastfetch
#pokemon-colorscripts --no-title -s -r | fastfetch -c $HOME/.config/fastfetch/config-pokemon.jsonc --logo-type file-raw --logo-height 10 --logo-width 5 --logo -

# fastfetch. Will be disabled if above colorscript was chosen to install
fastfetch -c $HOME/.config/fastfetch/config-compact.jsonc

# Set-up icons for files/directories in terminal using lsd
alias ls='lsd'
alias l='ls -l'
alias la='ls -a'
alias lla='ls -la'
alias lt='ls --tree'

# Set-up FZF key bindings (CTRL R for fuzzy history finder)
source <(fzf --zsh)

HISTFILE=~/.zsh_history
HISTSIZE=10000
SAVEHIST=10000
setopt appendhistory

# opencode
export PATH=$HOME/.opencode/bin:$PATH

# Added by cua-driver-rs installer — see https://github.com/trycua/cua
export PATH="/home/rifqieali/.local/bin:$PATH"
export PATH="$HOME/.bun/bin:$PATH"

# Composio CLI
export PATH="$HOME/.local/bin:$PATH"
export PHP_INI_SCAN_DIR="/tmp/opencode/phpini::"
