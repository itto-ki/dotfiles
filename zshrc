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

# Colored prompt
autoload colors
colors

PROMPT="%{${fg[white]}%}[%n@%m]$ %{${reset_color}%}"
PROMPT2="%{${fg[white]}%}[%n@%m]> %{${reset_color}%}"
RPROMPT="%{${fg[white]}%}%~ %{${reset_color}%}"
SPROMPT="%{${fg[white]}%}%r is correct? [n,y,a,e]:%{${reset_color}%} "

[[ -s "/home/itto-ki/.gvm/scripts/gvm" ]] && source "/home/itto-ki/.gvm/scripts/gvm"
