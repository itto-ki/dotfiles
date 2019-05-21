"dein Scripts
if &compatible
    set nocomptible
endif

set runtimepath^=~/.config/nvim/repos/github.com/Shougo/dein.vim
" dein.vimのディレクトリ
let s:dein_dir = expand('~/.config/nvim/dein')
let s:dein_repo_dir = s:dein_dir . '/repos/github.com/Shougo/dein.vim'

if dein#load_state(s:dein_dir)
    call dein#begin(s:dein_dir)
    " 導入プラグインを記述したtomlファイルへのパス
    let s:toml      = '~/.config/nvim/dein.toml'
    let s:lazy_toml = '~/.config/nvim/dein_lazy.toml'
    call dein#load_toml(s:toml, {'lazy':0})
    call dein#load_toml(s:lazy_toml, {'lazy':1})
    call dein#end()
    call dein#save_state()
endif

" 依存関係の問題でvimprocだけは先にチェックする
if dein#check_install(['vimproc.vim'])
    call dein#install(['vimproc.vim'])
endif
" その他のプラグインチェックする
if dein#check_install()
    call dein#install()
endif

filetype plugin indent on

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
colorscheme molokai
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
" set encoding=utf-8
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
let g:python_host_prog = $PYENV_ROOT . '/shims/python'
let g:python3_host_prog = $PYENV_ROOT . '/shims/python3'


" ++++++++++++++++++++++++++++++ 各種プラグインの設定 ++++++++++++++++++++++++++++++
"
" ##########################################################################################
" ### deopleteの設定
" ##########################################################################################
"
let g:deoplete#enable_at_startup = 1


" ##########################################################################################
" ### uniteの設定
" ##########################################################################################
" バッファ一覧
nmap <silent> <C-u><C-b> :<C-u>Denite buffer<CR>
" レジスタ一覧
nmap <silent> <C-u><C-y> :<C-u>Denite neoyank<CR>
" 最近使用したファイル一覧
nmap <silent> <C-u><C-m> :<C-u>Denite file_mru<CR>
" ファイル一覧
nmap <silent> <C-u><C-f> :<C-u>Denite file_rec<CR>
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
" Tell Neosnippet about the other snippets
let g:neosnippet#snippets_directory='~/.cache/dein/repos/github.com/Shougo/neosnippet-snippets/neosnippets'



" ##########################################################################################
" ### jediの設定
" ##########################################################################################

" docstringを非表示に
autocmd FileType python setlocal completeopt-=preview

autocmd FileType python setlocal omnifunc=jedi#completions
let g:jedi#auto_vim_configuration = 0
let g:jedi#completions_enabled = 0
if !exists('g:neocomplete#force_omni_input_patterns')
    let g:deoplete#omni_patterns = {}
endif
let g:deoplete#omni_patterns.python = '\h\w*\|[^. \t]\.\w*'



" ##########################################################################################
" ### syntasticの設定
" ##########################################################################################
let g:syntastic_python_checkers = ['pyflakes', 'pep8']



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
let g:lightline = {
            \ 'colorscheme': 'wombat',
            \ 'separator': { 'left': "\ue0b0", 'right': "\ue0b2" },
            \ 'subseparator': { 'left': "\ue0b1", 'right': "\ue0b3" }
            \ }



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

" racer
set hidden
let g:racer_cmd = $HOME . '/.cargo/bin/racer'
let g:racer_experimental_completer = 1

au FileType rust nmap gd <Plug>(rust-def)
au FileType rust nmap sp <Plug>(rust-def-split)
au FileType rust nmap vs <Plug>(rust-def-vertical)
au FileType rust nmap <leader>gd <Plug>(rust-doc)


" ##########################################################################################
" ### YAMLの設定
" ##########################################################################################
autocmd FileType yaml setlocal ts=2 sts=2 sw=2 expandtab
