# Path to your oh-my-zsh installation.
source $HOME/.zshscrt
export ZSH="$HOME/.oh-my-zsh"

# JIRA ENV
export JIRA_URL="https://raintonic.atlassian.net"
export JIRA_NAME="Nasir Taov"
export JIRA_PREFIX="UPR-"
export JIRA_DEFAULT_ACTION="dashboard"
# export JIRA_RAPID_BOARD=""

export NNN_PLUG='p:preview-tui;f:finder;v:imgview'
export NNN_FCOLORS=''
export NNN_FIFO='/tmp/nnn.fifo'

# User configuration
# export MANPATH="/usr/local/man:$MANPATH"
export DENO_INSTALL="$HOME/.deno"
export GOROOT="$HOME/Downloads/Apps/go"
export GOPATH="$GOROOT/bin"
export GO111MODULE=on # needed for WAILS
export PNPM_HOME="$HOME/.local/share/pnpm" # pnpm
export DOTS="$HOME/.dotfiles"

# bun
export BUN_INSTALL="$HOME/.bun"
export PATH="$BUN_INSTALL/bin:$PATH"

# nvm
export NVM_DIR="$HOME/.nvm"

# Jenkins
export JENKINS_USER_ID="nasrt"
export JENKINS_URL="http://srv.raintonic.com:8080"
export JENKINS_PASSWORD="rt"
export JENKINS_INSECURE="true"

# FFF
# export FFF_HIDDEN=1

# eval "$(luarocks path)" # eval needed for lua 

path+=("$HOME/.local/bin")
path+=("$HOME/.npm-packages/bin")
path+=("$HOME/.deno/bin")
path+=("$GOPATH")
path+=("$GOPATH/bin")
path+=("$HOME/.yarn/bin")
path+=("$HOME/.node/bin")
path+=("$HOME/.config/yarn/global/node_modules/.bin")
path+=("$PNPM_HOME:$PATH")
path+=("$HOME/.nimble/bin")
path+=("$M2_HOME/bin")

# You may need to manually set your language environment
# export LANG=en_US.UTF-8


# Preferred editor for local and remote sessions
if [[ -n $SSH_CONNECTION ]]; then
  export EDITOR='nvim'
else
  export EDITOR='nvim'
fi
if snap list | grep -q "nvim"; then
	export EDITOR="snap run nvim"
fi

# source <(ng completion script)

[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion

# bun completions
# [ -s "/home/nasrt/.bun/_bun" ] && source "/home/nasrt/.bun/_bun"
# . "$HOME/.cargo/env"
