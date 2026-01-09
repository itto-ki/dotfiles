############################################################################################
### Environmental variables
############################################################################################
export PATH=/usr/texbin:$HOME/.cargo/bin:$PATH
export EDITOR=nvim
export LANG=ja_JP.UTF-8
export RUST_SRC_PATH=$HOME/.rustup/toolchains/stable-x86_64-apple-darwin/lib/rustlib/src/rust/src
export PATH=$PATH:${GOPATH//://bin:}/bin:$HOME/.local/bin
export PATH=/usr/local/opt/ruby/bin:$PATH
export PATH="/opt/homebrew/opt/mysql-client/bin:$PATH"
export PATH=$HOME/.fig/bin:$PATH
export PATH="/opt/homebrew/opt/libpq/bin:$PATH"
export PATH=/Applications/Visual\ Studio\ Code.app/Contents/Resources/app/bin:$PATH


#############################################################################################
### Deno
#############################################################################################
export PATH=$HOME/.deno/bin:$PATH
. "$HOME/.deno/env"


#############################################################################################
### gcloud
#############################################################################################
if [ -f '/Users/itto-ki/Downloads/google-cloud-sdk/path.zsh.inc' ]; then . '/Users/itto-ki/Downloads/google-cloud-sdk/path.zsh.inc'; fi
export PATH=$HOME/google-cloud-sdk/bin:$PATH

#############################################################################################
### Amazon Q
#############################################################################################
[[ -f "${HOME}/Library/Application Support/amazon-q/shell/zshrc.post.zsh" ]] && builtin source "${HOME}/Library/Application Support/amazon-q/shell/zshrc.post.zsh"

#############################################################################################
### LM Studio
#############################################################################################
export PATH="$PATH:/Users/itto-ki/.lmstudio/bin"
