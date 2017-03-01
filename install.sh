#!/bin/bash

nvim_dir=~/.config/nvim
nvim_files=(init.vim dein.toml dein_lazy.toml)
dein_installer=installer.sh
config_files=(zshrc tmux.conf)

# neovimの設定ファイルを作成
if [ -e $nvim_dir ]; then
    mkdir -p $nvim_dir
fi
for file in ${nvim_files[@]}; do
    if [ ! -e $nvim_dir/$file ]; then    # ファイルがない場合
        ln -s $file $nvim_dir/$file      # ファイルのシンボリックリンクを作成
    fi
done
# dein.vimのインストール
if [ ! -e $nvim_dir/repos ]; then    # dein.vimがインストールされていない場合
    curl https://raw.githubusercontent.com/Shougo/dein.vim/master/bin/installer.sh > $dein_installer
    sh $dein_installer $nvim_dir
    rm $dein_installer
fi

# neovim以外の設定ファイルを作成
for file in ${config_files[@]}; do
    if [ ! -e ~/.$file ]; then        # ファイルがない場合
        ln -s $file ~/.$file    # ファイルのシンボリックリンクを作成
    fi
done
