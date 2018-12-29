############################################################################################
### Environmental variables
############################################################################################
export PATH=$HOME/.local/bin:$PATH  # Add a path to pipenv
export EDITOR=vim
export LANG=en_US.UTF-8
# coloring for less
export LESSOPEN='| /usr/share/source-highlight/src-hilite-lesspipe.sh %s'

############################################################################################
### Alias
############################################################################################
alias ls='ls --color=always'
alias ta='tmux attach -t'
alias pbcopy='xsel --clipboard --input'
alias screenoff='xset dpms force standby'


############################################################################################
### Rust
############################################################################################
# completion
export RUST_SRC_PATH=$HOME/.multirust/toolchains/stable-x86_64-unknown-linux-gnu/lib/rustlib/src/rust/src

############################################################################################
### Pyenv & Pipenv
############################################################################################
# Pyenv
export PYENV_ROOT="$HOME/.pyenv"
export PATH="$PYENV_ROOT/bin:$PATH"
if command -v pyenv 1>/dev/null 2>&1; then
  eval "$(pyenv init -)"
fi
# pipenv
eval "$(pipenv --completion)"
export PIPENV_VENV_IN_PROJECT=true

############################################################################################
### kubectl
############################################################################################
# completion
source <(kubectl completion zsh)

############################################################################################
### NordVPN
############################################################################################
alias nr='nordvpn disconnect; nordvpn connect'
