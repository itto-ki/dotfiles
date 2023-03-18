" ################################################################################
" ### vim-plug
" ################################################################################
call plug#begin()
Plug 'Shougo/deoplete.nvim', { 'do': ':UpdateRemotePlugins' }
Plug 'lighttiger2505/deoplete-vim-lsp'
Plug 'Shougo/neosnippet-snippets'
Plug 'Shougo/vimproc.vim'
Plug 'Shougo/neomru.vim'
Plug 'Shougo/neoyank.vim'
Plug 'Shougo/denite.nvim'
Plug 'prabirshrestha/async.vim'
Plug 'prabirshrestha/vim-lsp'
Plug 'mattn/vim-lsp-settings'
Plug 'ryanoasis/vim-devicons'
Plug 'tomasr/molokai'
Plug 'dracula/vim', { 'as': 'dracula' }
Plug 'cocopon/iceberg.vim'
Plug 'scrooloose/nerdcommenter'
Plug 'scrooloose/nerdtree'
Plug 'itchyny/lightline.vim'
Plug 'nathanaelkane/vim-indent-guides'
Plug 'scrooloose/syntastic'
Plug 'Shougo/neosnippet'
Plug 'Shougo/neosnippet-snippets'
Plug 'fatih/vim-go', {
    \ 'do': ':GoUpdateBinaries',
    \ 'for': 'go'
    \ }
Plug 'rust-lang/rust.vim', { 'for': 'rust' }
Plug 'nvie/vim-flake8'
Plug 'pangloss/vim-javascript', { 'for': 'javascript' }
Plug 'maxmellon/vim-jsx-pretty', { 'for': 'javascript' }
Plug 'leafgarland/typescript-vim', { 'for': 'typescript' }
Plug 'cespare/vim-toml', { 'for': 'toml' }
Plug 'prettier/vim-prettier', {
    \ 'do': 'yarn install',
    \' branch': 'release/1.x',
    \ 'for': [
        \ 'javascript',
        \ 'typescript',
        \ 'css',
        \ 'scss',
        \ 'json',
        \ 'markdown',
        \ 'graphql',
        \ 'html',
        \ 'yaml',
        \ 'toml'
    \ ]}
Plug 'tpope/vim-fugitive'
call plug#end()

" ################################################################################
" ### 画面表示の設定
" ################################################################################
"
" スクロール時に下が見えるようにする
set scrolloff=7
" 行番号を表示
set number
" 行番号・列番号を右下に表示
set ruler
" 対応する括弧をハイライト
set showmatch
" 対応する括弧をハイライトする時間 (n * 0.1[s])
set matchtime=3
" ウィンドウの幅より長い行は折り返され、次の行に続けて表示する
set wrap
" コマンドを画面の最下行に表示
set showcmd
" ステータス行を常に表示
set laststatus=2
" 補完メニューの高さ
set pumheight=10
" 不可視文字を表示
set list
" 不可視文字の表示設定
set listchars=tab:>-,trail:･,extends:>,precedes:<,nbsp:%,eol:↲
" Shift + Cursor でウィンドウサイズを変更
nnoremap <S-Left>  <C-w><<CR>
nnoremap <S-Right> <C-w>><CR>
nnoremap <S-Up>    <C-w>-<CR>
nnoremap <S-Down>  <C-w>+<CR>


" ###################################################################################
" ### カラーリング設定
" ###################################################################################
" コメント色を37(ターコイズブルー)にする
autocmd ColorScheme * highlight Comment ctermfg=37
" カラースキーム
colorscheme dracula
syntax on
" 背景を透明化
highlight Normal ctermbg=none

" カーソル下の構文情報を取得するコマンドSyntaxInfoを定義
function! s:get_syn_id(transparent)
  let synid = synID(line("."), col("."), 1)
  if a:transparent
    return synIDtrans(synid)
  else
    return synid
  endif
endfunction
function! s:get_syn_attr(synid)
  let name = synIDattr(a:synid, "name")
  let ctermfg = synIDattr(a:synid, "fg", "cterm")
  let ctermbg = synIDattr(a:synid, "bg", "cterm")
  let guifg = synIDattr(a:synid, "fg", "gui")
  let guibg = synIDattr(a:synid, "bg", "gui")
  return {
        \ "name": name,
        \ "ctermfg": ctermfg,
        \ "ctermbg": ctermbg,
        \ "guifg": guifg,
        \ "guibg": guibg}
endfunction
function! s:get_syn_info()
  let baseSyn = s:get_syn_attr(s:get_syn_id(0))
  echo "name: " . baseSyn.name .
        \ " ctermfg: " . baseSyn.ctermfg .
        \ " ctermbg: " . baseSyn.ctermbg .
        \ " guifg: " . baseSyn.guifg .
        \ " guibg: " . baseSyn.guibg
  let linkedSyn = s:get_syn_attr(s:get_syn_id(1))
  echo "link to"
  echo "name: " . linkedSyn.name .
        \ " ctermfg: " . linkedSyn.ctermfg .
        \ " ctermbg: " . linkedSyn.ctermbg .
        \ " guifg: " . linkedSyn.guifg .
        \ " guibg: " . linkedSyn.guibg
endfunction
command! SyntaxInfo call s:get_syn_info()

" ####################################################################################
" ### タブ/インデントの設定
" ####################################################################################
"
" タブを複数の空白に置き換える
set expandtab
" インデント幅
set shiftwidth=4
" 連続した空白に対してタブキーやバックスペースキーでカーソルの動く幅
set softtabstop=4
" 改行時に前の行のインデントを継続する
set autoindent
" 改行時に入力された行の末尾に合わせて次の行のインデントを増減する
set smartindent


" #######################################################################################
" ### ファイル処理関連の設定
" #######################################################################################
"
" 保存されていないファイルがある時は、終了前に保存確認
set confirm
" スワップファイルを作成する
set swapfile
set directory=~/.config/nvim/swap
" バックアップファイルのディレクトリ
set backupdir=$HOME/.config/nvim/backup



" ###################################################################################
" ### カーソル動作設定
" ###################################################################################
"
" カーソル行の背景色を変える
set cursorline

" カーソルを行頭、行末で止まらないようにする
set whichwrap=b,s,h,l,,[,]
" インデントの削除を可能に、行の先頭で前の行の改行を削除を可能に、Ctrl+Wで入力した単語以外も削除可能に
set backspace=indent,eol,start
" ウィンドウ間を移動
nnoremap <c-j> <c-w>j
nnoremap <c-h> <c-w>h
nnoremap <c-l> <c-w>l
nnoremap <c-k> <c-w>k

" gcで最後に変更したテキストを選択
nnoremap gc `[v`]
vnoremap gc :<C-u>normal gc<Enter>
onoremap gc :<C-u>normal gc<Enter>

" カーソル位置の記憶. 次回開いた時にカーソルが前回の終了場所に
augroup vimrcEx
  autocmd!
  autocmd BufReadPost *
    \ if line("'\"") > 1 && line("'\"") <= line('$') |
    \   exe "normal! g`\"" |
    \ endif
augroup END



" #########################################################################################
" ### 文字コードの設定
" #########################################################################################
"
" エンコード
set encoding=UTF-8
" ファイルエンコード
set fileencoding=utf-8



" ##########################################################################################
" ### 検索設定
" ##########################################################################################
"
" 補完の際、大文字小文字の区別をしない
" set infercase
" 検索の際、小文字と大文字の区別をしない
set ignorecase
" ただし、大文字も含めた場合は区別をする
set smartcase
" インクリメンタルサーチを行う
set incsearch
" 検索結果をハイライト表示
set hlsearch
" 検索ハイライトを消す
nnoremap <ESC><ESC> :nohlsearch<CR>
" 最後尾まで検索を終えたら次の検索で先頭に移る
set wrapscan



" ########################################################################################
" ### 動作環境との統合関連の設定
" ########################################################################################
"
" マウスの入力を受け付ける
if has('mouse')
    set mouse=a
endif
" インサートモードから抜けると自動的にIMEをオフにする
set imdisable
" OSとクリップボードを共有する
set clipboard+=unnamed
" <Space>. で.vimrcを開く
nnoremap <Space>, :<C-u>edit $MYVIMRC<Enter>
" <Space>s. で.vimrcのリロード
nnoremap <Space>. :<C-u>source $MYVIMRC<Enter>
" InsertModeでjj -> <ESC>
inoremap jj <ESC>
" 補完時にScratchウィンドウを表示しない
set completeopt=menuone
" Linuxの場合、ESCもしくはC-[でIMEをオフにする
let OSTYPE = system('uname')
if OSTYPE == "Linux\n"
    function! ImInActivate()
        call system('ibus engine "xkb:us::eng"')
    endfunction
    inoremap <silent> <C-[> <ESC>:call ImInActivate()<CR>
elseif OSTYPE == "Darwin\n"
  set ttimeoutlen=1
  let g:imeoff = 'osascript -e "tell application \"System Events\" to key code 102"'
  augroup MyIMEGroup
    autocmd!
    autocmd InsertLeave * :call system(g:imeoff)
  augroup END
  noremap <silent> <ESC> <ESC>:call system(g:imeoff)<CR>
endif

" ##########################################################################################
" ### その他の設定
" ##########################################################################################
"
" Yで行末まで削除
nnoremap Y y$
" +でカーソル下の数値をインクリメント
nnoremap + <C-a>
" -でカーソル下の数値をデクリメント
nnoremap - <C-x>

" システム標準pythonへのパスを追記
let g:python_host_prog = $HOME . '/.asdf/shims/python'
let g:python3_host_prog = $HOME . '/.asdf/shims/python3'

" ファイルを閉じる時にQuickFixウインドウしか残らないのであればQuickFixウインドウを自動クローズ
augroup QfAutoCommands
  autocmd!
  autocmd WinEnter * if (winnr('$') == 1) && (getbufvar(winbufnr(0), '&buftype')) == 'quickfix' | quit | endif
augroup END


" ++++++++++++++++++++++++++++++ 各種プラグインの設定 ++++++++++++++++++++++++++++++
"
" ##########################################################################################
" ### deopleteの設定
" ##########################################################################################
"
let g:deoplete#enable_at_startup = 1

" ##########################################################################################
" ### deniteの設定
" ##########################################################################################
" Floating Windowのための設定
let s:denite_win_width_percent = 0.85
let s:denite_win_height_percent = 0.7
" Change denite default options
call denite#custom#option('default', {
    \ 'split': 'floating',
    \ 'winwidth': float2nr(&columns * s:denite_win_width_percent),
    \ 'wincol': float2nr((&columns - (&columns * s:denite_win_width_percent)) / 2),
    \ 'winheight': float2nr(&lines * s:denite_win_height_percent),
    \ 'winrow': float2nr((&lines - (&lines * s:denite_win_height_percent)) / 2),
    \ })

" Change fire/rec command
call denite#custom#var('file/rec', 'command', ['ag', '--follow', '--nocolor', '--nogroup', '-g', ''])
"ESCキーでdeniteを終了
autocmd FileType denite call s:denite_my_settings()
function! s:denite_my_settings() abort
    nnoremap <silent><buffer><expr> <CR>
                \ denite#do_map('do_action')
    nnoremap <silent><buffer><expr> d
                \ denite#do_map('do_action', 'delete')
    nnoremap <silent><buffer><expr> p
                \ denite#do_map('do_action', 'preview')
    nnoremap <silent><buffer><expr> q
                \ denite#do_map('quit')
    nnoremap <silent><buffer><expr> i
                \ denite#do_map('open_filter_buffer')
    nnoremap <silent><buffer><expr> <Space>
                \ denite#do_map('toggle_select').'j'
endfunction
call denite#custom#map('insert', '<esc>', '<denite:enter_mode:normal>', 'noremap')
call denite#custom#map('normal', '<esc>', '<denite:quit>', 'noremap')
" <C-n>, <C-p>で上下移動
" call denite#custom#map('insert', '<C-n>', '<denite:move_to_next_line>', 'noremap')
" call denite#custom#map('insert', '<C-p>', '<denite:move_to_previous_line>', 'noremap')
" バッファ一覧
nmap <silent> <C-u><C-b> :<C-u>Denite buffer<CR>
" レジスタ一覧
nmap <silent> <C-u><C-y> :<C-u>Denite neoyank<CR>
" 最近使用したファイル一覧
nmap <silent> <C-u><C-m> :<C-u>Denite file_mru<CR>
" ファイル一覧
nmap <silent> <C-u><C-f> :<C-u>Denite file/rec<CR>
" grep
nmap <silent> <C-u><C-g> : <C-u>Denite grep<CR>
" colorschem
nmap <silent> <C-u><C-c> : <C-u>Denite colorscheme<CR>


" ##########################################################################################
" ### neosnippetの設定
" ##########################################################################################

" Plugin key-mappings.
imap <C-k> <Plug>(neosnippet_expand_or_jump)
smap <C-k> <Plug>(neosnippet_expand_or_jump)
xmap <C-k> <Plug>(neosnippet_expand_target)


" For snippet_complete marker.
if has('conceal')
  set conceallevel=2 concealcursor=i
endif

" Enable snipMate compatibility feature.
let g:neosnippet#enable_snipmate_compatibility = 1



" ##########################################################################################
" ### syntasticの設定
" ##########################################################################################
let g:syntastic_python_checkers = ['pyflakes', 'pep8']



" ##########################################################################################
" ### NERDTreeの設定
" ##########################################################################################
" Vim終了時にNERDTreeしか残らない場合にNERDTreeごと終了する
autocmd bufenter * if (winnr("$") == 1 && exists("b:NERDTree") && b:NERDTree.isTabTree()) | q | endif
" <C-w>でNERDTree画面を開閉
map <C-n> :NERDTreeToggle<CR>
" 隠しファイルも表示
let NERDTreeShowHidden=1



" ##########################################################################################
" ### NERDcommenterの設定
" ##########################################################################################
"
let NERDSpaceDelims = 1
nmap ,, <Plug>NERDCommenterToggle
vmap ,, <Plug>NERDCommenterToggle



" ##########################################################################################
" ### lightline.vimの設定
" ##########################################################################################
"
let os = substitute(system('uname'), '\n', '', '')
if os == 'Darwin' || os == 'Mac'
    let g:lightline = {
                \ 'colorscheme': 'wombat',
                \ 'separator': { 'left': "\ue0b0", 'right': "\ue0b2" },
                \ 'subseparator': { 'left': "\ue0b1", 'right': "\ue0b3" }
                \ }
elseif os == 'Linux'
    let g:lightline = {
                \ 'colorscheme': 'wombat',
                \ 'separator': { 'left': "\u2b80", 'right': "\u2b82" },
                \ 'subseparator': { 'left': "\u2b81", 'right': "\u2b83" }
                \ }
endif



" ##########################################################################################
" ### indent-guides.vimの設定
" ##########################################################################################

"# 0で無効、1で有効
let g:indent_guides_enable_on_vim_startup = 1
" ガイドをスタートするインデントの量
let g:indent_guides_indent_levels = 4
" ガイドの幅
let g:indent_guides_guide_size = 1
" ハイライト色の変化の幅
let g:indent_guides_color_change_percent = 30
" 自動カラーを無効にする
let g:indent_guides_auto_colors = 0
" 奇数インデントのガイドカラー
hi IndentGuidesOdd ctermbg=gray
" 偶数インデントのガイドカラー
hi IndentGuidesEven ctermbg=darkgray



" ##########################################################################################
" ### prettier-vimの設定
" ##########################################################################################
" let g:prettier#autoformat = 0
" autocmd BufWritePre *.js,*.jsx,*.mjs,*.ts,*.tsx,*.css,*.less,*.scss,*.json,*.graphql,*.md,*.vue,*.yaml,*.html Prettier

" ##########################################################################################
" ### globalの設定
" ##########################################################################################

map <C-g> :Gtags 
map <C-c> :GtagsCursor<CR>



" ##########################################################################################
" ### rustの設定
" ##########################################################################################
"
" rustfmt
let g:rustfmt_autosave = 1
let g:rustfmt_comand = $HOME . '/.cargo/bin/rustfmt'



" ##########################################################################################
" ### Golangの設定
" ##########################################################################################
" Highlight
autocmd FileType go :highlight goErr cterm=bold ctermfg=214
autocmd FileType go :match goErr /\<err\>/
let g:go_highlight_functions = 1
let g:go_highlight_methods = 1
let g:go_highlight_structs = 1
let g:go_fmt_command = "goimports"

autocmd FileType go setlocal sw=4 ts=4 sts=4 noet


" ##########################################################################################
" ### TypeScriptの設定
" ##########################################################################################
autocmd FileType typescript setlocal ts=2 sts=2 sw=2 expandtab

" ##########################################################################################
" ### YAMLの設定
" ##########################################################################################
autocmd FileType yaml setlocal ts=2 sts=2 sw=2 expandtab
