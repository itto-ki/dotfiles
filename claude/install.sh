#!/bin/bash
# Claude Code のユーザー設定を、このリポジトリから ~/.claude と ~/.local/bin に入れる。
# 何度実行しても同じ結果になる。置き換える既存のファイルは <名前>.bak.<日時> に退避する。
#
# settings.json は Orca などほかのツールも書き込むので、丸ごとは置き換えない。
# settings.fragment.json の項目だけをマージし、自分のフックは毎回入れ直す（ほかのフックは残す）。
# 最後に doctor で、リンク・フックの登録・必要な道具・フックのテストを確かめる。
set -euo pipefail

here=$(cd "$(dirname "$0")" && pwd)
stamp=$(date +%Y%m%d-%H%M%S)
failed=0

link() { # link <このディレクトリからのパス> <置き先>
  local src="$here/$1" dst=$2
  mkdir -p "$(dirname "$dst")"
  if [ -L "$dst" ] && [ "$(readlink "$dst")" = "$src" ]; then return; fi
  if [ -e "$dst" ] || [ -L "$dst" ]; then
    mv "$dst" "$dst.bak.$stamp"
    echo "退避: $dst.bak.$stamp"
  fi
  ln -s "$src" "$dst"
  echo "リンク: $dst -> $src"
}

merge_settings() {
  local settings="$HOME/.claude/settings.json"
  [ -f "$settings" ] || echo '{}' > "$settings"
  local merged
  merged=$(jq -s '
    def ours: (.command // "") | test("\\.claude/hooks/(pseudo-auto|stop-japanese|long-thread)\\.py");
    .[0] as $current | .[1] as $fragment
    | $current
    # 組織の管理設定で無効になっていて効かない項目を消す（2026-11 時点）。
    # auto mode は disableAutoMode、bypass は disableBypassPermissionsMode、t3-pstack は strictKnownMarketplaces で止められている。
    | del(.skipDangerousModePermissionPrompt)
    | if .permissions.defaultMode == "auto" then del(.permissions.defaultMode) else . end
    | if (.permissions // {}) == {} then del(.permissions) else . end
    | del(.enabledPlugins["t3-pstack@t3-pstack"], .extraKnownMarketplaces["t3-pstack"])
    | if (.enabledPlugins // {}) == {} then del(.enabledPlugins) else . end
    | if (.extraKnownMarketplaces // {}) == {} then del(.extraKnownMarketplaces) else . end
    | . * ($fragment | del(.hooks, .sandbox))
    | .sandbox.excludedCommands = (((.sandbox.excludedCommands // []) + $fragment.sandbox.excludedCommands) | unique)
    | .sandbox.network.allowUnixSockets = (((.sandbox.network.allowUnixSockets // []) + $fragment.sandbox.network.allowUnixSockets) | unique)
    | .sandbox.filesystem.allowWrite = (((.sandbox.filesystem.allowWrite // []) + $fragment.sandbox.filesystem.allowWrite) | unique)
    | reduce ($fragment.hooks | to_entries[]) as $event (.;
        .hooks[$event.key] = ($event.value + [
          (.hooks[$event.key] // [])[]
          | .hooks |= map(select(ours | not))
          | select(.hooks | length > 0)
        ]))
  ' "$settings" "$here/settings.fragment.json")
  if [ "$merged" != "$(jq . "$settings")" ]; then
    cp "$settings" "$settings.bak.$stamp"
    printf '%s\n' "$merged" > "$settings"
    echo "マージ: ${settings}（前の版は ${settings}.bak.${stamp}）"
  fi
}

check() { # check <説明> <コマンド...>
  local label=$1
  shift
  if "$@" >/dev/null 2>&1; then echo "OK  $label"; else echo "NG  $label"; failed=1; fi
}

points_here() { [ "$(readlink "$1")" = "$here/$2" ]; }

registered() { # registered <イベント> <フックのファイル名>
  jq -e --arg event "$1" --arg file "$2" \
    '[.hooks[$event][]?.hooks[]?.command] | any(contains($file))' "$HOME/.claude/settings.json"
}

for tool in jq python3; do
  command -v "$tool" >/dev/null || { echo "$tool が無い。nix profile add nixpkgs#$tool で入れてから実行し直す" >&2; exit 1; }
done

chmod +x "$here/install.sh" "$here"/bin/* "$here"/hooks/*.py
link CLAUDE.md "$HOME/.claude/CLAUDE.md"
link rules "$HOME/.claude/rules"
for hook in pseudo-auto.py stop-japanese.py long-thread.py; do
  link "hooks/$hook" "$HOME/.claude/hooks/$hook"
done
for command in claude-run claude-chrome agy-proof claude-usage-report; do
  link "bin/$command" "$HOME/.local/bin/$command"
done
merge_settings

echo "--- doctor"
check "~/.claude/CLAUDE.md がこのリポジトリを指す" points_here "$HOME/.claude/CLAUDE.md" CLAUDE.md
check "~/.claude/rules がこのリポジトリを指す" points_here "$HOME/.claude/rules" rules
check "PreToolUse に pseudo-auto.py が入っている" registered PreToolUse pseudo-auto.py
check "UserPromptSubmit に long-thread.py が入っている" registered UserPromptSubmit long-thread.py
check "Stop に stop-japanese.py が入っている" registered Stop stop-japanese.py
check "フックのテストが通る" python3 "$here/hooks/test_hooks.py"
check "chrome-devtools-mcp が入っている（無ければ npm install --prefix ~/.local/share/claude-chrome chrome-devtools-mcp@1.13.0）" \
  test -f "$HOME/.local/share/claude-chrome/node_modules/chrome-devtools-mcp/package.json"
check "node が ~/.nix-profile/bin/node にある（claude-chrome が使う）" test -x "$HOME/.nix-profile/bin/node"
check "agy が ~/.local/bin/agy にある（agy-proof が使う）" test -x "$HOME/.local/bin/agy"
exit $failed
