dotfiles
========
## Install
```
./instal.sh
```

## Claude Code
```
./claude/install.sh
```
`~/.claude`（CLAUDE.md・rules・hooks）と `~/.local/bin`（claude-run・claude-chrome・agy-proof・claude-usage-report）にリンクし、`settings.json` には `claude/settings.fragment.json` の項目だけをマージする。何度実行してもよい。最後の doctor で、リンク・フックの登録・必要な道具・フックのテストを確かめる。

## To use auto complete function in some language
### C
[Servers Clangd](https://github.com/prabirshrestha/vim-lsp/wiki/Servers-Clangd)

### Python
```
pip install python-language-server
```

### Golang
```
go get -u github.com/sourcegraph/go-langserver
```

### TypeScript
```
npm i -g javascript-typescript-server
```
