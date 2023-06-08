source $HOME/.zshenv
# Set name of the theme to load --- if set to "random", it will
# load a random theme each time oh-my-zsh is loaded, in which case,
# to know which specific one was loaded, run: echo $RANDOM_THEME
# See https://github.com/ohmyzsh/ohmyzsh/wiki/Themes
ZSH_THEME="fwalch"

# Uncomment the following line to use hyphen-insensitive completion.
# Case-sensitive completion must be off. _ and - will be interchangeable.
# HYPHEN_INSENSITIVE="true"

zstyle ':omz:update' mode auto      # update automatically without asking

# Uncomment the following line if pasting URLs and other text is messed up.
# DISABLE_MAGIC_FUNCTIONS="true"

# Uncomment the following line to disable colors in ls.
# DISABLE_LS_COLORS="true"

# Uncomment the following line to disable auto-setting terminal title.
# DISABLE_AUTO_TITLE="true"

# Uncomment the following line to enable command auto-correction.
ENABLE_CORRECTION="false"

# Uncomment the following line to display red dots whilst waiting for completion.
# You can also set it to another string to have that shown instead of the default red dots.
# e.g. COMPLETION_WAITING_DOTS="%F{yellow}waiting...%f"
# Caution: this setting can cause issues with multiline prompts in zsh < 5.7.1 (see #5765)
# COMPLETION_WAITING_DOTS="true"

# Uncomment the following line if you want to disable marking untracked files
# under VCS as dirty. This makes repository status check for large repositories
# much, much faster.
# DISABLE_UNTRACKED_FILES_DIRTY="true"

# Uncomment the following line if you want to change the command execution time
# stamp shown in the history command output.
# You can set one of the optional three formats:
# "mm/dd/yyyy"|"dd.mm.yyyy"|"yyyy-mm-dd"
# or set a custom format using the strftime function format specifications,
# see 'man strftime' for details.
# HIST_STAMPS="mm/dd/yyyy"

# Which plugins would you like to load?
# Standard plugins can be found in $ZSH/plugins/
# Custom plugins may be added to $ZSH_CUSTOM/plugins/
# Example format: plugins=(rails git textmate ruby lighthouse)
# Add wisely, as too many plugins slow down shell startup.


plugins=(
  git
  jira
  # vi-mode
  # zsh-autocomplete
  # zsh-autosuggestions
  # web-search
)

source $ZSH/oh-my-zsh.sh

# Compilation flags
# export ARCHFLAGS="-arch x86_64"
# Set personal aliases, overriding those provided by oh-my-zsh libs,
# plugins, and themes. Aliases can be placed here, though oh-my-zsh
# users are encouraged to define aliases within the ZSH_CUSTOM folder.
# For a full list of active aliases, run `alias`.

# Shortcuts
alias e="$EDITOR"
alias add="sudo apt install"
alias remove="sudo apt remove"
alias update="sudo apt update"
alias lg="lazygit"
alias 3n="nnn -ae"
alias python="python3"

# Jira
alias jirah="cat ~/.oh-my-zsh/plugins/jira/README.md"

# Confs
alias zc="$EDITOR $DOTFILES/zsh/.zshrc"
alias zs="source ~/.zshrc"

alias tmuxc="$EDITOR $DOTFILES/tmux/.tmux.conf"
alias wmc="$EDITOR $DOTFILES/bspwm/.config/bspwm/bspwmrc"
alias keybinds="$EDITOR $DOTFILES/sxhkd/.config/sxhkd/sxhkdrc"
alias kc="$EDITOR $DOTFILES/kitty/.config/kitty/kitty.conf"
alias picomc="$EDITOR $DOTFILES/picom/.config/picom/picom.conf"

alias cc="clear"
alias cdl="cd $HOME/Downloads"
alias cdocs="cd $HOME/Documents"

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

function query_xrdb() {
  xrdb -query | grep -w $1 | awk '{ print $2}'
}

function ntf() {
  $@ && notify-send "Task done:\n$@"
}

[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh
# tabtab source for electron-forge package
# uninstall by removing these lines or running `tabtab uninstall electron-forge`
[[ -f $HOME/Documents/code/node/mith-ts/node_modules/tabtab/.completions/electron-forge.zsh ]] && . /home/nasmx/Documents/code/node/mith-ts/node_modules/tabtab/.completions/electron-forge.zsh

# if [ -z "$TMUX" ] && [ ${UID} != 0 ]
# then
#     tmux new -As0
# fi
