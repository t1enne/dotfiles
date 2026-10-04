source $HOME/.zshenv
source $HOME/.config/nnn/quitoncd.sh

# Basic options
setopt rcquotes
[[ $- == *i* ]] && stty icrnl 2>/dev/null
zstyle ':omz:update' mode disabled

# Theme and oh-my-zsh
# habamax: custom theme recolored to match the nvim colorscheme (~/.oh-my-zsh/custom/themes/habamax.zsh-theme)
ZSH_THEME="habamax"
ENABLE_CORRECTION="false"
VI_MODE_RESET_PROMPT_ON_MODE_CHANGE=true
VI_MODE_SET_CURSOR=true

# Minimal plugins for speed
plugins=(git vi-mode docker-compose)

source $ZSH/oh-my-zsh.sh


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

alias uuid="cat /proc/sys/kernel/random/uuid"

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


# sl [src] [dest]  - symlink src (default: $PWD) at dest (default: ./basename(src))
# src/dest may be relative or absolute; dest parent must exist.
function sl() {
	local src="${1:-$PWD}"
	local dest="${2:-$(basename "$src")}"

	[[ -e "$src" ]] || { echo "sl: no such file or directory: $src" >&2; return 1; }

	local abs_src; abs_src="$(realpath "$src")" || return 1
	local destdir; destdir="$(dirname "$dest")"
	[[ -d "$destdir" ]] || { echo "sl: dest dir does not exist: $destdir" >&2; return 1; }

	ln -s "$abs_src" "$dest" || return 1
	echo "linked: $dest -> $abs_src"
}

# ai: query pi. -c resumes last session (shared context). Plain -p "$@" for one-offs.
#   ai @file.ts "review"     @-files auto-attach
#   cmd | ai "summarize"     stdin merges into prompt
function ai() {
	pi -p "$*"
}

# pir: fuzzy-pick a pi session by folder/date (any working dir),
# cd into that session's original cwd, then resume it.
function pir() {
	local -a rows
	local f first cwd ts
	for f in "$HOME"/.pi/agent/sessions/*/*.jsonl(Nom); do
		read -r first < "$f" || continue
		[[ $first == *'"type":"session"'* ]] || continue
		[[ $first =~ '"cwd":"([^"]*)"' ]] && cwd=$match[1] || cwd='?'
		[[ $first =~ '"timestamp":"([^"]*)"' ]] && ts=$match[1] || ts='?'
		rows+=("$f"$'\t'"${ts[1,16]}"$'\t'"$cwd")
	done
	[[ ${#rows} -gt 0 ]] || { print -u2 'pir: no sessions found'; return 1 }

	local sel
	sel=$(print -rl -- "${rows[@]}" | fzf --delimiter=$'\t' --with-nth=2,3 --nth=2,1 \
		--prompt='pi session> ' --no-sort \
		--preview="grep -m1 '\"role\":\"user\"' {1} | jq -r '[.message.content[]? | select(.type==\"text\") | .text] | join(\" \")' 2>/dev/null" \
		--preview-window='down,30%,border-top,wrap') || return 0
	[[ -n $sel ]] || return 0

	local file=${sel%%$'\t'*}
	cwd=$(print -r -- "$sel" | cut -f3)
	if [[ -d $cwd ]]; then
		cd "$cwd" || return 1
	else
		print -u2 "pir: original dir gone ($cwd), staying in $PWD"
	fi
	pi --session "$file"
}

function yttext() {
	local id="$1" 
	local lang="${2:-en}" 
	[[ -z "$id" ]] && { print -u2 "usage: yttext <id> [lang-chain]"; return 1 }
	local out=$(youtube_transcript_api "$id" --format text --languages ${=lang}) || return 1
	print -r -- "$out" | tr '\n' ' ' | tr -s ' ' | sed 's/^ //; s/ $//'
	print
}

[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh

autoload -Uz add-zsh-hook

# Clean up the loading process
function _cleanup_nvm_loading() {
  rm -f /tmp/nvm_loaded.$$ 2>/dev/null
}

add-zsh-hook zshexit _cleanup_nvm_loading

# Lazy load nvm on startup via preexec hook (runs before each command)
# function _lazy_load_nvm() {
  # Load once; nvm/node/npm/npx all become available after nvm.sh sources
  # if [[ -z "$NVM_LOADED" ]] && [[ "$1" =~ '(^|[[:space:]/])(nvm|node|npm|npx)([[:space:]]|$)' ]]; then
    # export NVM_LOADED=1
[ -s "$NVM_DIR/nvm.sh" ] && source "$NVM_DIR/nvm.sh"
[ -s "$NVM_DIR/bash_completion" ] && source "$NVM_DIR/bash_completion"
nvm use 24.16 >/dev/null 2>&1
  # fi
# }
# add-zsh-hook preexec _lazy_load_nvm


# bun completions
# [ -s "/home/nasmx/.bun/_bun" ] && source "/home/nasmx/.bun/_bun"

# opam configuration
# [[ ! -r /home/nasmx/.opam/opam-init/init.zsh ]] || source /home/nasmx/.opam/opam-init/init.zsh  > /dev/null 2> /dev/null

# Load Angular CLI autocompletion.
# source <(ng completion script)
