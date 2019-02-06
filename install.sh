#!/bin/bash

SCRIPT_DIR=$(cd $(dirname $0); pwd)
NVIMDIR=$HOME/.config/nvim
NVIMFILES=(init.vim dein.toml dein_lazy.toml)
DEIN_INSTALLSCRIPT=dein_installer.sh
CONFIGFIELS=(zshrc tmux.conf)
TPMDIR=$HOME/.tmux/plugins/tpm

# neovimの設定ファイルを作成
if [ ! -e $NVIMDIR ]; then
    mkdir -p $NVIMDIR
fi
for file in ${NVIMFILES[@]}; do
    if [ ! -e $NVIMDIR/$file ]; then    # ファイルがない場合
        ln -s $SCRIPT_DIR/$file $NVIMDIR/$file      # ファイルのシンボリックリンクを作成
    fi
done

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
    if [ ! -e $HOME/.$file ]; then        # ファイルがない場合
        ln -s $SCRIPT_DIR/$file $HOME/.$file    # ファイルのシンボリックリンクを作成
    fi
done
