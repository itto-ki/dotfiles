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

## ツール

- CLI ツールは `nix profile add nixpkgs#<pkg>` で入れる（Homebrew は使わない。home-manager・nix-darwin は使っていない）。Homebrew に同じツールが残っていたら、消すかどうかを聞く
- 文章の校正は `~/.local/bin/claude-run --cwd <dir> 'agy-proof <ファイル> --audience <読み手>'` で行う（sandbox の中では agy の通信が拒否されるので claude-run で呼ぶ）。依頼文は固定なので作り直さない。それでも exit 3 のとき（Antigravity のログインが切れているなど）は、出力された `!` の 1 行をユーザーに頼み、終わったら `agy-proof --collect <dir>` で結果を読む
- claude-chrome は、単独の 1 行で、`$(...)` を入れず短い引数で呼ぶ（フックが強制する）。長い JS は `evaluate_script --pageId <id> --sourcePath <js>`、結果は `--filePath <json>` で受け取る。デーモンが 2 つ立って「The browser is already running」になったら、`pkill -TERM -f chrome-devtools-mcp/out` で両方止め、`pgrep -fl claude-chrome` で専用 Chrome も止まったのを確かめてから `new_page` で起動し直す。ログインはプロファイルに残る
- Claude in Chrome（`mcp__claude-in-chrome__*`）の javascript_tool の戻り値は 1,100〜4,000 字ほどで切れるので、900 字ずつの配列で返す。`?` `&` `=` や Cookie らしい文字列を含むと BLOCKED になるので置き換えて返す。app.slack.com ではスクリーンショットが Permission denied になる。`file_upload` に渡せるのは作業ディレクトリの中のファイルだけ。組織設定で止められている時期もある
- T3 Code にはアクセシビリティ権限が無いので、ほかのアプリの画面の情報は読めない
- Android エミュレータ（この Mac）: `Pixel_8_API_35` に Chromium 155 を入れ、`com.android.chrome`（124）は止めてある
- 使い方の指標は `claude-usage-report [日数]` で、直近の期間とその前の期間を比べて見る
