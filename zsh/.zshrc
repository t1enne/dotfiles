source $HOME/.zshenv
ZSH_THEME="fwalch"

zstyle ':omz:update' mode auto      # update automatically without asking

plugins=(
  git
  jira
  vi-mode
  # zsh-autocomplete
  # zsh-autosuggestions
  # web-search
)

# Uncomment the following line to enable command auto-correction.
ENABLE_CORRECTION="false"
VI_MODE_RESET_PROMPT_ON_MODE_CHANGE=true
VI_MODE_SET_CURSOR=true

source $ZSH/oh-my-zsh.sh

# Shortcuts
alias e="$EDITOR"
alias add="sudo apt install"
alias remove="sudo apt remove"
alias update="sudo apt update"
alias lg="lazygit"
alias 3n="nnn -aeA"
alias python="python3"
alias findf="find . -type f -name "

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
alias cdl="cd $HOME/Downloads"
alias cdocs="cd $HOME/Documents"
alias dots="cd $DOTS"

function gtar() {
  # tracks all remotes, including deleted ones
  for remote in `git branch -r | grep -v /HEAD`; do git checkout --track $remote ; done
}

function gtr() {
  gco --track `git branch -r | fzf`
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
  file=$@:0:-1
  cmd=$@:-1
  echo "Files: $file"
  echo "Cmd: $cmd"
  # while inotifywait -e close_write $file; do eval $cmd; done
}

[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh
