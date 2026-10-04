# habamax.zsh-theme — 'gozilla' recolored to the habamax nvim colorscheme.
# Uses explicit 24-bit hex so colors survive whatever the terminal ANSI palette.
# Prompt shape kept identical to gozilla (glyphs: ➜ ❯ %c git% %).

# habamax.vim (dark) palette reference
#  base   #1C1C1C   bright #BCBCBC   top #DADADA
#  grey1  #767676   grey2  #585858   mid #9E9E9E
#  red    #D75F5F   peach  #FFAF5F   orange #D7875F
#  green  #87AF87   green+ #AFD7AF   olive #AFAF87   ylw #D7D787
#  blue   #5F87AF   blue+  #87AFD7
#  mauve  #AF87AF   mauve+ #D7AFD7   teal #5F8787    teal+ #87AFAF

PROMPT='%F{#D75F5F}%B➜%b%f %F{#87AF87}%B❯%b%f %F{#87AFAF}%c%f %F{#87AFD7}%B$(git_prompt_info)%b%f %F{#5F87AF}%B% %b%f%{$reset_color%}'

ZSH_THEME_GIT_PROMPT_PREFIX="%F{#767676}(%f"
ZSH_THEME_GIT_PROMPT_SUFFIX="%F{#767676})%f"
ZSH_THEME_GIT_PROMPT_DIRTY=""
ZSH_THEME_GIT_PROMPT_CLEAN=""

RPROMPT='$(git_prompt_status)%{$reset_color%}'

ZSH_THEME_GIT_PROMPT_ADDED="%F{#87AF87} ✈"
ZSH_THEME_GIT_PROMPT_MODIFIED="%F{#AFAF87} ✭"
ZSH_THEME_GIT_PROMPT_DELETED="%F{#D75F5F} ✗"
ZSH_THEME_GIT_PROMPT_RENAMED="%F{#87AFD7} ➦"
ZSH_THEME_GIT_PROMPT_UNMERGED="%F{#D7AFD7} ✂"
ZSH_THEME_GIT_PROMPT_UNTRACKED="%F{#767676} ✱"
