############################################################################################
### Environmental variables
############################################################################################
export PATH=$HOME/.local/bin:$PATH  # Add a path to pipenv
export EDITOR=vim
export LANG=en_US.UTF-8
export RUST_SRC_PATH=$HOME/.multirust/toolchains/stable-x86_64-unknown-linux-gnu/lib/rustlib/src/rust/src
export LESSOPEN='| /usr/share/source-highlight/src-hilite-lesspipe.sh %s'
export PIPENV_VENV_IN_PROJECT=true

############################################################################################
### Alias
############################################################################################
alias ls='ls --color=always'
alias ta='tmux attach -t'
alias pbcopy='xsel --clipboard --input'
alias screenoff='xset dpms force standby'
