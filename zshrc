############################################################################################
### OS Type setting
############################################################################################
case ${OSTYPE} in
    linux*)
        source $HOME/dotfiles/linux.zsh
        ;;
    openbsd*)
        source $HOME/dotfiles/openbsd.zsh
        ;;
    darwin*)
        source $HOME/dotfiles/darwin.zsh
        ;;
esac


############################################################################################
### specific settings for this machine
############################################################################################
if [ -e $HOME/.special.zsh ]; then
    source $HOME/.special.zsh
fi

############################################################################################
### Environmental variables
############################################################################################

export LESS='-R'

############################################################################################
### Alias
############################################################################################

alias la='ls -a'
alias ll='ls -l'
alias tmux='tmux -2'
alias grep='grep -n --color=always'
alias ag='ag --color'
alias vndl='virsh net-dhcp-leases'
alias gosh='rlwrap gosh'
alias ocaml='rlwrap ocaml'
alias zshr='source $HOME/.zshrc'
alias tree='tree -C'
# Git
alias gad='git add'
alias gcm='git commit'
alias gbr='git branch'
alias gch='git checkout'
alias glg='git log'
alias ggr='git log --graph --oneline'



############################################################################################
### Language
############################################################################################

# Set character code using `less` command
export LESSCHARSET=UTF-8


############################################################################################
### General Setting
############################################################################################
# Remove duplicate PATH
typeset -U PATH

# Set KCODE UTF-8
export KCODE=u

# Set a keybaind emacs-mode
bindkey -e
# Set an keybaind vi-mode
# bindkey -v

# Don't beep
setopt no_beep
# Auto `cd` command when type directory name
setopt auto_cd
# Save hisotry of `cd`
setopt auto_pushd
# Fix a miss of command spells
setopt correct

# Colored by file categories
export LSCOLORS=gxfxcxdxbxegedabagacad
zstyle ':completion:*:default' list-colors ${(s.:.)LS_COLORS}
# Colored results ls commands. 
export CLICOLOR=true


#############################################################################################
### Complement
#############################################################################################

autoload -U compinit; compinit -u         # Enabled auto completion
setopt auto_list                          # Show the list of completion choices
setopt auto_menu                          # Select choices with pushing TAB
setopt auto_param_keys                    # Parens auto completion
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Z}' # Ignore large case or small case
# Colored
export LS_COLORS='di=01;36:ln=01;35:so=01;32:ex=01;31:bd=46;34:cd=43;34:su=41;30:sg=46;30:tw=42;30:ow=43;30'
# Colored completions
export ZLS_COLORS=$LS_COLORS


#############################################################################################
### History
#############################################################################################

# File of saveing history
HISTFILE=~/.zsh_history
# Number of histories mapped a memory
HISTSIZE=100
# Number of historyies
SAVEHIST=10000
# Don't save a same command
setopt hist_ignore_dups 
# Dont't save a hisotry command
setopt hist_no_store
# Delete redundant white spaces from a command
setopt hist_reduce_blanks
# Save hisotry smoothly
setopt inc_append_history
# Save time of starting zsh and ending zsh
setopt extended_history


#############################################################################################
### Prompt
#############################################################################################
# CUIで使用できるカラーコードを表示する
function palette () {
    for c in {000..255};
    do
        echo -n "\e[38;5;${c}m $c" ; [ $(($c%16)) -eq 15 ] && echo;
    done;
}

# IconFont一覧を表示
function iconfont () {
    # for i in {61545..62178};
    for i in {61446..62235};
    do
        echo -n -e "$(printf '\\u%x' $i) ";
    done
}

case ${OSTYPE} in
    linux*)
        OSICON=""
        ;;
    darwin*)
        OSICON=""
        ;;
    openbsd*)
        ;;
esac



# Colored prompt
autoload colors
colors
# Colors List
# { black | red | green | yellow | blue | magenta | cyan | white }
#
### %K{num}: background color
### %F{num}: characters color
### %f{num}: resetcharacters color
### %k{num}: reset background color
DEL=$(echo -e "")    # 削除文字
WB="%F{015}%K{031}"    # WRITE_BLUE
BP="%F{031}%K{135}"    # BLUE_PURPLE
WR="%F{015}%K{124}"    # WHITE_RED
RB="%F{124}%K{031}"    # RED_BLUE
WP="%F{015}%K{135}"    # WHITE_PURPLE
PG="%F{135}%K{064}"    # PURPLE_GREEN
P_="%F{135}"           # PURPLE_
WG="%F{015}%K{064}"    # WHITE_GREEN
G_="%F{064}"           # GREEN_
W_="%F{015}"           # WHITE_
Y_="%F{226}"           # YELLOW
WY="%F{015}%K{130}"
PY="%F{135}%K{130}"
PR="%F{135}%K{088}"    # PURPLE_RED
RS="%f%k"

# Git
autoload -Uz vcs_info
zstyle ':vcs_info:git:*' check-for-changes true
zstyle ':vcs_info:git:*' stagedstr "  "
zstyle ':vcs_info:git:*' unstagedstr "  "
zstyle ':vcs_info:*' formats "${DEL}${DEL}${PG}⮀ ${WG}  %u%c%b%f ${RS}${G_}⮀"
zstyle ':vcs_info:*' actionformats '[%b|%a]'

PROMPT='${WR}${OSICON}  %m ${RB}⮀ ${WB}  %~ ${BP}⮀ ${WP}  %n ${RS}${P_}⮀ '
PROMPT2="%{${W_}%}> ${RS}"
SPROMPT="%{${W_}%}%r is correct? [n,y,a,e]:%{${reset_color}%} "

PROMPT=${PROMPT}'${vcs_info_msg_0_}
${Y_}    ${RS}'
setopt prompt_subst
precmd () { vcs_info }

#############################################################################################
### direnv
#############################################################################################
eval "$(direnv hook zsh)"
