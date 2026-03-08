source $HOME/.zshenv
source $HOME/.config/nnn/quitoncd.sh

# Basic options
setopt rcquotes
[[ $- == *i* ]] && stty icrnl 2>/dev/null
zstyle ':omz:update' mode disabled

# Theme and oh-my-zsh
ZSH_THEME="gozilla"
ENABLE_CORRECTION="false"
VI_MODE_RESET_PROMPT_ON_MODE_CHANGE=true
VI_MODE_SET_CURSOR=true

# Minimal plugins for speed
plugins=(git vi-mode docker-compose)

source $ZSH/oh-my-zsh.sh

# Lazy load heavy tools
function pyenv() {
    unfunction pyenv
    eval "$(command pyenv init -)"
    pyenv "$@"
}

function nvm() {
		echo "loading nvm"
		unset -f nvm
    [ -s "$NVM_DIR/nvm.sh" ] && source "$NVM_DIR/nvm.sh"
    [ -s "$NVM_DIR/bash_completion" ] && source "$NVM_DIR/bash_completion"
    nvm "$@"
}

# Auto-use node 22 only when needed
function node() {
    if ! type -p node &> /dev/null; then
        nvm use 24 >/dev/null 2>&1
    fi
    command node "$@"
}

function npm() {
    if ! type -p npm &> /dev/null; then
        nvm use 24 >/dev/null 2>&1
    fi
    command npm "$@"
}

# Shortcuts
alias e="$EDITOR"
alias add="sudo apt install"
alias remove="sudo apt remove"
alias update="sudo apt update"
alias lg="lazygit"
alias 3n="nnn -aeA"
alias findf="find . -type f -name "
alias py="python3.8"

# Jira
alias jirah="cat ~/.oh-my-zsh/plugins/jira/README.md"

# Confs
alias zc="$EDITOR $DOTS/zsh/.zshrc"
alias zs="source ~/.zshrc"

alias tmuxc="$EDITOR $DOTS/tmux/.tmux.conf"
alias wmc="$EDITOR $DOTS/bspwm/.config/bspwm/bspwmrc"
alias keybinds="$EDITOR $DOTS/sxhkd/.config/sxhkd/sxhkdrc"
alias kc="$EDITOR $DOTS/kitty/.config/kitty/kitty.conf"
alias picomc="$EDITOR $DOTS/picom/.config/picom/picom.conf"

alias cl="clear"
alias cdls="cd $HOME/Downloads"
alias cdocs="cd $HOME/Documents"
alias dots="cd $DOTS"

function print_colors() {
  for i in {0..255}; do
      printf "\x1b[38;5;${i}mcolour${i}\x1b[0m\n"
  done
}

# ccode rust | deno | node etc.
function ccode() {
  p=$HOME/Documents/code
  if [[ -n $1 ]]; then
    p=$p/$1
  fi
  cd $p*
}

function monitor() {
  file=${@:1:1}
  cmd=${@:2}
  echo "Files: $file"
  echo "Cmd: '$cmd'"
	find -type f -name "$file" | entr eval $cmd
  # while inotifywait -e close_write $file; do eval $cmd; done
}

function sql() {
		sq sql "$@" --json
# 	# qr=`psql "$PG_C" --csv -c $1`
# 	# exec 3>$2
# 	# exec 2>/dev/null
#  	#	echo $qr | sq '.data' -j "$@" 2>/dev/null || echo $qr
# 	# exec 2>$3
}

function timestamp() {
	date +"%Y%m%d%H%M"
}

alias uuid="cat /proc/sys/kernel/random/uuid"


[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh

nvm use 24 &> /dev/null

# bun completions
# [ -s "/home/nasmx/.bun/_bun" ] && source "/home/nasmx/.bun/_bun"

# opam configuration
# [[ ! -r /home/nasmx/.opam/opam-init/init.zsh ]] || source /home/nasmx/.opam/opam-init/init.zsh  > /dev/null 2> /dev/null

# Load Angular CLI autocompletion.
# source <(ng completion script)
