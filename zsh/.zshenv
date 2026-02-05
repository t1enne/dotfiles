source "$HOME/.zshscrt"
export ZSH="$HOME/.oh-my-zsh"

export NNN_PLUG='p:preview-tui;f:finder;v:imgview'
export NNN_FCOLORS=''
export NNN_FIFO='/tmp/nnn.fifo'

# User configuration
export DENO_INSTALL="$HOME/.deno"
export GOROOT="$HOME/Downloads/Apps/go"
export GOPATH="$GOROOT/bin"
export GO111MODULE=on
export PNPM_HOME="$HOME/.local/share/pnpm"
export DOTS="$HOME/.dotfiles"
export EDITOR='nvim'
export SUDOEDITOR="vim"

# Tool paths
export BUN_INSTALL="$HOME/.bun"
export NVM_DIR="$HOME/.nvm"
export WABT_PATH="$HOME/Downloads/Apps/wabt-1.0.37"
export PYENV_ROOT="$HOME/.pyenv"

# Jenkins
export JENKINS_USER_ID="nasrt"
export JENKINS_URL="http://srv.raintonic.com:8080"
export JENKINS_PASSWORD="rt"
export JENKINS_INSECURE="true"

# Julia 
export JULIA_NUM_THREADS=4

# OpenHands CLI aliases
alias openhands="uvx --python 3.12 --from openhands-ai openhands"
alias oh="uvx --python 3.12 --from openhands-ai openhands"

# Build PATH once without duplicates
typeset -U path
path=(
    "$HOME/.local/bin"
    "$HOME/.opencode/bin"
    "$BUN_INSTALL/bin"
    "$PYENV_ROOT/bin"
    "$HOME/.cargo/bin"
    "$HOME/.npm-packages/bin"
    "$HOME/.deno/bin"
    "$GOPATH"
    "$GOPATH/bin"
    "$HOME/.yarn/bin"
    "$HOME/.node/bin"
    "$HOME/.config/yarn/global/node_modules/.bin"
    "$PNPM_HOME"
    "$HOME/.nimble/bin"
    "$HOME/.fly/bin"
		"$HOME/.juliaup/bin"
    "/opt/bin"
    $path
)

