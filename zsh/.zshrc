source $HOME/.zshenv
ZSH_THEME="gozilla"

# for `echo 'Dont''t'`
set rcquotes

stty icrnl # fixes Enter appearing as ^M
zstyle ':omz:update' mode reminder # avb: auto, reminder, disabled


plugins=(
  git
  # jira
  vi-mode
  # docker
  zsh-autosuggestions
  # zsh-autocomplete
	zsh-syntax-highlighting
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
alias cdls="cd $HOME/Downloads"
alias cdocs="cd $HOME/Documents"
alias dots="cd $DOTS"

function print_colors() {
  for i in {0..255}; do
      printf "\x1b[38;5;${i}mcolour${i}\x1b[0m\n"
  done
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
  file=${@:1:1}
  cmd=${@:2}
  echo "Files: $file"
  echo "Cmd: '$cmd'"
	find -type f -name "$file" | entr eval $cmd
  # while inotifywait -e close_write $file; do eval $cmd; done
}

function f() {
    fff "$@"
    cd "$(cat "${XDG_CACHE_HOME:=${HOME}/.cache}/fff/.fff_d")"
}

[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh

# bun completions
# [ -s "/home/nasmx/.bun/_bun" ] && source "/home/nasmx/.bun/_bun"

# opam configuration
# [[ ! -r /home/nasmx/.opam/opam-init/init.zsh ]] || source /home/nasmx/.opam/opam-init/init.zsh  > /dev/null 2> /dev/null

#THIS MUST BE AT THE END OF THE FILE FOR SDKMAN TO WORK!!!
export SDKMAN_DIR="$HOME/.sdkman"
[[ -s "$HOME/.sdkman/bin/sdkman-init.sh" ]] && source "$HOME/.sdkman/bin/sdkman-init.sh"
