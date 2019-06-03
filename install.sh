#!/bin/bash

SCRIPT_DIR=$(cd $(dirname $0); pwd)
NVIMDIR=$HOME/.config/nvim
NVIM_PLUGIN_DIR=$NVIMDIR/plugin
NVIM_CONF_FILE=init.vim
GTAGS_VIM_SCRIPT=https://gist.githubusercontent.com/itto-ki/ef1606ea4120ed44383e1eb1518d12c7/raw/2d04567041532db9f18f767175b31911ae4faac0/gtags.vim
DEIN_INSTALLSCRIPT=dein_installer.sh
CONFIGFIELS=(zshrc tmux.conf gitconfig)
TPMDIR=$HOME/.tmux/plugins/tpm

# neovimの設定ファイル用ディレクトリをバックアップ用のディレクトリごと生成
if [ ! -e $NVIMDIR/backup ]; then
    mkdir -p $NVIMDIR/backup
fi
# neovimのプラグイン用ディレクトリを作成
if [ ! -e $NVIM_PLUGIN_DIR ]; then
    mkdir -p $NVIM_PLUGIN_DIR
fi

# vim-plugのインストール
curl -fLo ~/.local/share/nvim/site/autoload/plug.vim --create-dirs \
    https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim

# neovimの設定ファイルを作成
if [ ! -e $NVIMDIR/$NVIM_CONF_FILE ]; then
    ln -s $SCRIPT_DIR/$NVIM_CONF_FILE $NVIMDIR/$NVIM_CONF_FILE
fi

# GNU GlobalのためのVim Pluginを追加
curl $GTAGS_VIM_SCRIPT > $NVIM_PLUGIN_DIR/gtags.vim

# dein.vimのインストール
if [ ! -e $NVIMDIR/repos ]; then    # dein.vimがインストールされていない場合
    curl https://raw.githubusercontent.com/Shougo/dein.vim/master/bin/installer.sh > $DEIN_INSTALLSCRIPT
    sh $DEIN_INSTALLSCRIPT $NVIMDIR
    rm $DEIN_INSTALLSCRIPT
fi

# tpmのインストール
if [ ! -e $TPMDIR ]; then
    git clone https://github.com/tmux-plugins/tpm $TPMDIR
fi

# neovim以外の設定ファイルを作成
for file in ${CONFIGFIELS[@]}; do
    ln -s $SCRIPT_DIR/$file $HOME/.$file
done
