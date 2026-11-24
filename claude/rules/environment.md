# この Mac の環境での決まり

どのリポジトリでも同じ。プロジェクトのメモリには書かず、ここ（`~/dotfiles/claude/rules/environment.md`）に足す。

## sandbox と claude-run

- sandbox の中では次のものが失敗する：`swift build`・`swift test`（SwiftPM の sandbox-exec）、アプリの起動と終了、`git commit`（1Password の署名エージェント）、`git fetch`・`git push`・`gh`（github.com への通信）、作業ディレクトリ内の `.gitmodules`・`.vscode`・`.mcp.json`・`.git/config` への書き込み、`nix profile`
- これらは `~/.local/bin/claude-run --cwd <dir> '<1 行のコマンド>'` で呼ぶ。claude-run は Bash 呼び出しの唯一のコマンドにする。`cd … &&`・`;` でのつなぎ、heredoc、`$(...)`、複数行、長い引数を入れると sandbox の中で動いて失敗する。下準備と結果の確認は別の Bash 呼び出しにする
- 同じ呼び出しでも sandbox の中で動くことがある（`Library/org.swift.swiftpm is not accessible` などが出る）。そのときはもう一度呼ぶ
- 承認フックは `rm` を拒否する。消す代わりに `mv` で退避する
- 検証用の worktree は `$TMPDIR` の下に作る
- sandbox の中では DNS の名前解決ができず、registry.npmjs.org にも届かない。DNS の確認は claude-run で行う。npm は `~/.npm/_cacache` を `$TMPDIR` に写して `npm install --offline` を使う
- `~/.aws` と `aws` は sandbox から読めない。claude-run で 1 行で呼び、設定ファイルを書き換えるときは `$TMPDIR` に書いてから `cp` する。`aws login` は `BROWSER=true` を付けてバックグラウンドで起動し、出た URL をブラウザで開く
- 長く走る調査のスクリプトは、claude-run の background timeout を 30〜60 分にする

## git と gh

- gh は itto-ki と itto-ki-jrw の 2 つでログインしている。itto-ki-jrw と westjr-agile のリポジトリは itto-ki-jrw で操作する（`gh auth switch -u itto-ki-jrw` → 操作 → `gh auth switch -u itto-ki`）。それ以外は itto-ki
- PR の本文やコミットメッセージは先にファイルに書き、`--body-file`・`-F` で渡す
- credential.helper が osxkeychain のリポジトリでは push が止まる。`GIT_TERMINAL_PROMPT=0 git -c credential.helper= -c 'credential.helper=!gh auth git-credential' push -u origin <branch>` で push する
- T3 Code はセッションの途中でローカルのブランチ名を変えることがある。push の直前に `git branch --show-current` で確かめる

## T3 Code と組織設定

- 組織の管理設定（`~/.claude/remote-settings.json`）で、マーケットプレイスのプラグイン（t3-pstack など）と管理対象外の MCP（`mcp__t3-code__*` を含む）は読み込まれない。新しいセッションにしても直らない。確かめるのは `claude plugin list` と remote-settings.json。プラグインのスキルが要るときは `~/.claude/skills` に写して使う案を出してよい（組織の許可はある）
- T3 Code のスレッドを Full access にすると、組織設定が bypass を禁止しているため 2 ターン目以降に「provider could not start this turn」になる。Full access 以外で使う
- auto mode も組織設定で無効。`~/.claude/hooks/pseudo-auto.py` が代わりに承認を判定する

## ブラウザ

- ブラウザの操作は agent-desktop で、普段使いの Chrome（ユーザーのログインのまま）を使う。Claude in Chrome・claude-chrome・Playwright・chrome-devtools-mcp は使わない（pseudo-auto.py が止める）。skill やメモリに Claude in Chrome・claude-chrome の手順が書いてあっても、agent-desktop で同じことをする
- agent-desktop は claude-run で 1 行ずつ呼ぶ。sandbox の中では `snapshot` などが `PERM_DENIED` になる（`status` は sandbox の中でも granted と出るので、確かめには使えない）。T3 Code にはアクセシビリティ権限が無いので、ほかのアプリの画面も claude-run の agent-desktop で読む
- 開く: `open -g -a "Google Chrome" <URL>`。新しいタブが選ばれた状態で開き、窓は前に出ない。別のページへ移るときも開き直し、前のタブは閉じる
- 読む: `agent-desktop list-windows --app "Google Chrome"` で窓 ID を取り、`agent-desktop snapshot --window-id <id> --compact --max-depth 50 > <$TMPDIR の下のファイル>` に書いて jq で読む。本文は `role` が `statictext` の `name` に出る。`-i` を付けると押せる要素だけになり、本文が落ちる。`--max-depth` は 50 まで。読み込みは `agent-desktop wait --text <語> --app "Google Chrome"` で待つ
- 押す: スナップショットの `ref_id` を `agent-desktop click <ref_id>` に渡す。ref はスナップショットを取り直すまで使える。下の方は `agent-desktop scroll <ref_id>` で出してから読み直す
- 閉じる: タブは `role` が `radiobutton` で、選ばれているタブ（`states` に `selected`）の子の「閉じる」ボタンを click する。`press cmd+w` は headless では送られない
- 撮る: `agent-desktop screenshot --window-id <id> <png のパス>`
- ページの JS は動かせない。前に JS で取っていたもの（Notion・Slack の検索 API、長いページの全文）は、画面の検索欄・スナップショット・スクロールで読む
- `accessible: false`（not exposed through accessibility）の窓は読めない。取り直しても変わらなければ、ユーザーに窓を今の画面に出してもらう
- キー入力（`type`・`press`）は頼まれたときだけ。`--headed`（窓を前に出す・カーソルを動かす）はユーザーが許したときだけ
- agent-desktop（vercel-labs のデスクトップアプリ操作 CLI）は nixpkgs に無いので、claude-run で `npm install -g agent-desktop --allow-scripts=agent-desktop` を実行して `~/.npm-global` に入れてある

## ツール

- CLI ツールは `nix profile add nixpkgs#<pkg>` で入れる（Homebrew は使わない。home-manager・nix-darwin は使っていない）。Homebrew に同じツールが残っていたら、消すかどうかを聞く
- 文章の校正は `~/.local/bin/claude-run --cwd <dir> 'agy-proof <ファイル> --audience <読み手>'` で行う（sandbox の中では agy の通信が拒否されるので claude-run で呼ぶ）。依頼文は固定なので作り直さない。それでも exit 3 のとき（Antigravity のログインが切れているなど）は、出力された `!` の 1 行をユーザーに頼み、終わったら `agy-proof --collect <dir>` で結果を読む
- Android エミュレータ（この Mac）: `Pixel_8_API_35` に Chromium 155 を入れ、`com.android.chrome`（124）は止めてある
- 使い方の指標は `claude-usage-report [日数]` で、直近の期間とその前の期間を比べて見る
