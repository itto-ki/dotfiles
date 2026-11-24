#!/usr/bin/env python3
"""PreToolUse: rm は許可を求め、その他の危険なシェル操作は拒否する。

静的なコマンド検査であり、任意のスクリプトの副作用を検証するものではない。
Claude Code の管理設定・deny/ask ルールは、このフックの allow より優先される。

ほかに次の決まりを強制する。
- ブラウザは agent-desktop で操作する。Claude in Chrome・claude-chrome・Playwright・chrome-devtools-mcp は止める
- claude-run は単独の 1 行で呼ぶ（ほかのコマンドとつなぐと sandbox の中で動いて失敗するため）
- プロジェクトの自動メモリに環境の話を書かない（~/dotfiles/claude/rules/environment.md に書く）
- T3 Code では Agent をフォアグラウンドで動かす（バックグラウンドだとターン終了後のツール呼び出しが失敗する）
"""
import json
import os
import re
import shlex
import sys


ASK_COMMANDS = frozenset({"rm"})
BLOCKED_COMMANDS = frozenset({
    "rmdir", "unlink", "shred", "sudo", "doas", "dd",
    "mkfs", "newfs", "fdisk", "sfdisk", "parted", "wipefs",
    "shutdown", "reboot", "halt", "poweroff",
})
SHELLS = {"sh", "bash", "zsh", "dash", "ksh", "fish"}
WRAPPERS = {"command", "builtin", "exec", "env", "nohup", "nice", "time", "timeout", "xargs"}
CONTROL_WORDS = {"if", "then", "elif", "else", "while", "until", "do", "!", "{"}
FIND_EXEC_ACTIONS = {"-exec", "-execdir", "-ok", "-okdir"}
ASSIGNMENT = re.compile(r"^[A-Za-z_][A-Za-z0-9_]*=")
HEREDOC = re.compile(r"(?<!<)<<(-?)[ \t]*(?:(['\"])([A-Za-z_][A-Za-z0-9_]*)\2|([A-Za-z_][A-Za-z0-9_]*))")
PUNCTUATION = ";&|()\n"

CHROME = "claude-chrome"
CLAUDE_RUN = "claude-run"
MEMORY_FILE = re.compile(r"/\.claude/projects/[^/]+/memory/(?!MEMORY\.md$)[^/]+\.md$")
ENVIRONMENT_WORDS = re.compile(
    r"claude-run|claude-chrome|Claude in Chrome|agent-desktop|\bagy\b|\bT3\b|remote-settings|managed-settings"
    r"|nix profile|pseudo-auto|Operation not permitted|sandbox ?(の外|の中|内|で|が|は|を|では|から)",
    re.IGNORECASE,
)
RULES_FILE = "~/dotfiles/claude/rules/environment.md"

# agent-desktop 以外のブラウザの道具。MCP のサーバ名・skill 名に含まれる語で見分ける。
OTHER_BROWSER_SERVERS = ("claude-in-chrome", "playwright", "chrome-devtools", "puppeteer")
OTHER_BROWSER_SKILLS = frozenset({"claude-in-chrome"})
# playwright の CLI の前に来てよい語（npx・pnpm dlx・python -m など）。これ以外が前にあれば引数とみなす。
RUNNER_WORDS = frozenset({"npx", "bunx", "pnpx", "pnpm", "yarn", "npm", "exec", "dlx", "x",
                          "uv", "uvx", "run", "-m", "-y", "--yes"})
PLAYWRIGHT_CLI = re.compile(r"(@playwright/[a-z-]+|playwright(-cli)?)(@[\w.^~-]+)?")
# プロジェクトのテストの実行と準備は止めない。
PLAYWRIGHT_ALLOWED = frozenset({"test", "show-report", "merge-reports", "install", "install-deps", "uninstall"})
BROWSER_LIBRARY = re.compile(
    r"\b(sync|async)_playwright\b|\b(chromium|firefox|webkit|puppeteer)\.(launch|connect)"
    r"|(require\(\s*|from\s+|import\s+)['\"](playwright|puppeteer)")
INTERPRETER = re.compile(r"python[0-9.]*|node|deno|bun|tsx|ts-node")
BROWSER_RULE = ("ブラウザの操作は agent-desktop で普段使いの Chrome を使う。"
                "Claude in Chrome・claude-chrome・Playwright・chrome-devtools-mcp は使わない。"
                f"呼び方は {RULES_FILE} の「ブラウザ」の項（claude-run で 1 行ずつ呼ぶ）")


def separate_heredocs(command):
    """ヒアドキュメントの本文をシェルのコマンド列と区別する。"""
    lines = iter(command.splitlines(keepends=True))
    outer, bodies = [], []
    for line in lines:
        outer.append(line)
        for match in HEREDOC.finditer(line):
            delimiter = match.group(3) or match.group(4)
            body = []
            for content in lines:
                compared = content.lstrip("\t") if match.group(1) else content
                if compared.rstrip("\r\n") == delimiter:
                    break
                body.append(content)
            bodies.append(("".join(outer), "".join(body), bool(match.group(2))))
    return "".join(outer), bodies


def substitutions(command):
    """単一引用符で囲まれたリテラルを除き、コマンド置換を取り出す。"""
    quote = None
    index = 0
    while index < len(command):
        char = command[index]
        if char == "\\" and quote != "'":
            index += 2
            continue
        if char == quote:
            quote = None
        elif quote is None and char in "\"'":
            quote = char
        elif quote != "'" and char == "`":
            end = index + 1
            while end < len(command):
                if command[end] == "\\":
                    end += 2
                elif command[end] == "`":
                    break
                else:
                    end += 1
            yield command[index + 1:end]
            index = end
        elif quote != "'" and command.startswith("$(", index):
            end, nesting, inner_quote = index + 2, 1, None
            while end < len(command) and nesting:
                current = command[end]
                if current == "\\" and inner_quote != "'":
                    end += 2
                    continue
                if current == inner_quote:
                    inner_quote = None
                elif inner_quote is None and current in "\"'":
                    inner_quote = current
                elif inner_quote is None:
                    if current == "(":
                        nesting += 1
                    elif current == ")":
                        nesting -= 1
                end += 1
            yield command[index + 2:end - 1 if nesting == 0 else end]
            index = end - 1
        index += 1


def decide(decision, reason, updated_input=None):
    output = {
        "hookEventName": "PreToolUse",
        "permissionDecision": decision,
        "permissionDecisionReason": "pseudo-auto: " + reason,
    }
    if updated_input is not None:
        output["updatedInput"] = updated_input
    print(json.dumps({"hookSpecificOutput": output}, ensure_ascii=False))


def split_segments(command):
    """コマンド列を ; & | ( ) 改行で区切った単語の並びに分ける。構文を読めなければ None。"""
    lexer = shlex.shlex(command, posix=True, punctuation_chars=PUNCTUATION)
    lexer.whitespace = " \t\r"
    lexer.whitespace_split = True
    try:
        tokens = list(lexer)
    except ValueError:
        return None, None
    segments = []
    words = []
    for token in tokens:
        if token and all(char in PUNCTUATION for char in token):
            if words:
                segments.append(words)
                words = []
        else:
            words.append(token)
    if words:
        segments.append(words)
    return tokens, segments


def strip_prefix(words):
    # shlex は find のエスケープされた ; でも分割するため、後続の実行アクションも扱う。
    while words and (
        words[0] in CONTROL_WORDS or words[0] in FIND_EXEC_ACTIONS
        or ASSIGNMENT.match(words[0])
    ):
        words = words[1:]
    return words


def command_reason(words, depth, blocked_commands=BLOCKED_COMMANDS):
    words = strip_prefix(words)
    if not words:
        return None
    executable = os.path.basename(words[0])
    args = words[1:]
    if executable in blocked_commands or executable.startswith(("mkfs.", "newfs_")):
        return "blocked command: " + executable
    if executable in WRAPPERS:
        # env/xargs 等でラップされていても、その後の実行コマンドを検査する。
        for index, arg in enumerate(args):
            if arg.startswith("-") or ASSIGNMENT.match(arg):
                continue
            reason = command_reason(args[index:], depth, blocked_commands)
            if reason:
                return reason
    if executable == "git":
        if "reset" in args and "--hard" in args:
            return "git reset --hard"
        if "push" in args and any(
            arg == "-f" or re.fullmatch(r"-[A-Za-z]*f[A-Za-z]*", arg)
            or arg.startswith(("--force", "+")) for arg in args
        ):
            return "git force push"
        if "clean" in args and any(
            arg == "--force" or re.fullmatch(r"-[A-Za-z]*f[A-Za-z]*", arg)
            for arg in args
        ):
            return "git clean with force"
    if executable == "find":
        if "-delete" in args:
            return "find -delete"
        for index, arg in enumerate(args[:-1]):
            if arg in FIND_EXEC_ACTIONS:
                reason = command_reason(args[index + 1:], depth, blocked_commands)
                if reason:
                    return reason
    if executable == "diskutil" and any(
        arg.lower().startswith(("erase", "partition", "zerodisk", "randomdisk", "secureerase"))
        for arg in args
    ):
        return "diskutil destructive operation"
    if executable in SHELLS:
        for index, arg in enumerate(args[:-1]):
            if re.fullmatch(r"-[A-Za-z]*c[A-Za-z]*", arg):
                return shell_reason(args[index + 1], depth + 1, blocked_commands)
    if executable == "eval":
        return shell_reason(" ".join(args), depth + 1, blocked_commands)
    return None


def shell_reason(command, depth=0, blocked_commands=BLOCKED_COMMANDS):
    if depth > 12:
        return "shell nesting is too deep to inspect"
    command, heredocs = separate_heredocs(command)
    for header, body, quoted in heredocs:
        try:
            shell_input = any(os.path.basename(word) in SHELLS for word in shlex.split(header))
        except ValueError:
            return "shell syntax could not be inspected"
        if shell_input:
            reason = shell_reason(body, depth + 1, blocked_commands)
            if reason:
                return reason
        elif not quoted:
            # 引用されていないヒアドキュメントでは本文のコマンド置換が実行される。
            for nested in substitutions(body.replace("'", "")):
                reason = shell_reason(nested, depth + 1, blocked_commands)
                if reason:
                    return reason
    for nested in substitutions(command):
        reason = shell_reason(nested, depth + 1, blocked_commands)
        if reason:
            return reason
    tokens, segments = split_segments(command)
    if tokens is None:
        return "shell syntax could not be inspected"
    for words in segments:
        reason = command_reason(words, depth, blocked_commands)
        if reason:
            return reason
    # ダウンロードした内容の直接実行を拒否する。
    names = {os.path.basename(token) for token in tokens}
    if "|" in tokens and names & {"curl", "wget"} and names & SHELLS:
        return "download piped into a shell"
    return None


def called_alone(command, name):
    """name のコマンドを呼んでいなければ None、単独の 1 行で呼んでいれば True、ほかとつないでいれば False。

    ヒアドキュメントの本文（python3 - <<EOF の中のコードなど）はコマンドとして数えない。
    """
    if name not in command:
        return None
    outer, heredocs = separate_heredocs(command)
    _, segments = split_segments(outer)
    if not segments:
        return None
    if not any((stripped := strip_prefix(words)) and os.path.basename(stripped[0]) == name for words in segments):
        return None
    return len(segments) == 1 and not heredocs and "\n" not in outer.strip()


def runs_playwright_cli(words):
    """playwright の CLI でブラウザを動かす呼び出しか。テストの実行と準備（test・install など）は除く。"""
    words = strip_prefix(words)
    for index, word in enumerate(words):
        name = word if word.startswith("@") else os.path.basename(word)
        match = PLAYWRIGHT_CLI.fullmatch(name)
        if match:
            rest = [arg for arg in words[index + 1:] if not arg.startswith("-")]
            if match.group(1) in ("playwright", "@playwright/test") and (not rest or rest[0] in PLAYWRIGHT_ALLOWED):
                return False
            return True
        if not (name in RUNNER_WORDS or word.startswith("-") or INTERPRETER.fullmatch(name)):
            return False
    return False


def browser_command_reason(command):
    """Bash から agent-desktop 以外のブラウザの道具を呼んでいないかを調べる。

    claude-run に渡したコマンドも、claude-run がこのフックで調べる。
    """
    outer, _ = separate_heredocs(command)
    _, segments = split_segments(outer)
    executables = [os.path.basename(words[0]) for words in map(strip_prefix, segments or []) if words]
    if CHROME in executables or any(runs_playwright_cli(words) for words in segments or []):
        return BROWSER_RULE
    # python3 - <<EOF や node -e の中で Playwright・Puppeteer を使うもの。grep などで語を探すだけなら止めない。
    if BROWSER_LIBRARY.search(command) and any(INTERPRETER.fullmatch(name) for name in executables):
        return BROWSER_RULE
    return None


def browser_tool_reason(tool_name, tool_input):
    """MCP・skill の、agent-desktop 以外のブラウザの道具を止める。"""
    server = re.match(r"mcp__(.+?)__", tool_name)
    if server and any(word in server.group(1).lower() for word in OTHER_BROWSER_SERVERS):
        return BROWSER_RULE
    if tool_name == "Skill" and str(tool_input.get("skill", "")).split(":")[-1] in OTHER_BROWSER_SKILLS:
        return BROWSER_RULE
    return None


def claude_run_reason(command):
    """claude-run の呼び出しが、sandbox の外で動く形（単独の 1 行）かどうかを調べる。"""
    if called_alone(command, CLAUDE_RUN) is False:
        return ("claude-run は Bash 呼び出しの唯一のコマンドにし、1 行で渡す（ほかのコマンドとつなぐと sandbox の中で動いて失敗する）。"
                "下準備と結果の確認は別の Bash 呼び出しで行い、長い文やメッセージはファイルに書いてから渡す。"
                "claude-run に渡す引数の中では && でつないでよい")
    return None


def memory_scope_reason(tool_name, tool_input):
    """プロジェクトの自動メモリに、環境の話が書かれようとしていないかを調べる。"""
    path = tool_input.get("file_path")
    if not isinstance(path, str) or not MEMORY_FILE.search(os.path.expanduser(path)):
        return None
    if tool_name == "Write":
        text = tool_input.get("content") or ""
    elif tool_name == "MultiEdit":
        text = "\n".join(str(edit.get("new_string", "")) for edit in tool_input.get("edits") or [] if isinstance(edit, dict))
    else:
        text = tool_input.get("new_string") or ""
    found = ENVIRONMENT_WORDS.search(str(text))
    if not found:
        return None
    return (f"プロジェクトのメモリに環境の話（「{found.group(0)}」）を書かない。別の Mac や別の clone では失われる。"
            f"claude-run・agent-desktop・agy・T3 Code・sandbox・組織設定・nix のことは {RULES_FILE} に書く"
            "（~/.claude/rules/ から読み込まれ、dotfiles で他の Mac にも入る）。"
            "プロジェクトの事実だけを残すなら、環境の話を外して書き直す")


def main():
    try:
        data = json.load(sys.stdin)
        if not isinstance(data, dict) or not isinstance(data.get("tool_name"), str) or not data["tool_name"]:
            raise ValueError("missing tool_name")
        tool_name = data["tool_name"]
        tool_input = data.get("tool_input")
        if not isinstance(tool_input, dict):
            raise ValueError("invalid tool_input")
        if tool_name == "Bash":
            command = tool_input.get("command")
            if not isinstance(command, str) or not command.strip():
                raise ValueError("missing Bash command")
            reason = shell_reason(command)
            if reason:
                uncertain = reason in {"shell syntax could not be inspected", "shell nesting is too deep to inspect"}
                decide("ask" if uncertain else "deny", reason)
                return
            reason = shell_reason(command, blocked_commands=BLOCKED_COMMANDS | ASK_COMMANDS)
            if reason:
                decide("ask", "rm requires manual approval")
                return
            reason = browser_command_reason(command) or claude_run_reason(command)
            if reason:
                decide("deny", reason)
                return
        elif reason := browser_tool_reason(tool_name, tool_input):
            decide("deny", reason)
            return
        elif tool_name in ("Write", "Edit", "MultiEdit"):
            reason = memory_scope_reason(tool_name, tool_input)
            if reason:
                decide("deny", reason)
                return
        elif tool_name == "Agent" and os.environ.get("CLAUDE_CODE_ENTRYPOINT") == "t3-code" \
                and tool_input.get("run_in_background") is not False:
            decide("allow", "T3 Code では Agent をフォアグラウンドで動かす",
                   {**tool_input, "run_in_background": False})
            return
    except (ValueError, TypeError, AttributeError):
        decide("ask", "invalid hook input; manual approval required")
        return
    # Agent / WebFetch / MCP、cwd 外の編集を含め、残りはすべて承認する。
    decide("allow", "allowed by default")


if __name__ == "__main__":
    main()
