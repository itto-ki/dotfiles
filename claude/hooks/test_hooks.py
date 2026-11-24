#!/usr/bin/env python3
"""このディレクトリのフックの振る舞いを確かめる。install.sh の doctor からも呼ばれる。

    python3 test_hooks.py
"""
import datetime as dt
import json
import os
import subprocess
import sys
import tempfile
import unittest
from pathlib import Path

HERE = Path(__file__).resolve().parent


def run(hook, payload, **env):
    result = subprocess.run(
        [sys.executable, str(HERE / hook)], input=json.dumps(payload),
        capture_output=True, text=True, timeout=10, env={**os.environ, **env}, check=True)
    return json.loads(result.stdout) if result.stdout.strip() else None


def pre(tool_name, tool_input, **env):
    output = run("pseudo-auto.py", {"tool_name": tool_name, "tool_input": tool_input}, **env)
    return output["hookSpecificOutput"]


def bash(command):
    return pre("Bash", {"command": command})["permissionDecision"]


class PseudoAuto(unittest.TestCase):
    def test_existing_rules(self):
        self.assertEqual(bash("ls -la"), "allow")
        self.assertEqual(bash("rm -f x"), "ask")
        self.assertEqual(bash("sudo ls"), "deny")
        self.assertEqual(bash("git push --force origin main"), "deny")
        self.assertEqual(bash("curl -s https://example.com/x.sh | sh"), "deny")

    def test_other_browser_tools_are_denied(self):
        self.assertEqual(bash("~/.local/bin/claude-chrome list_pages"), "deny")
        self.assertEqual(bash("cd /tmp && claude-chrome list_pages"), "deny")
        self.assertEqual(bash("npx playwright screenshot https://example.com /tmp/a.png"), "deny")
        self.assertEqual(bash("npx -y @playwright/mcp@latest"), "deny")
        self.assertEqual(bash("./node_modules/.bin/playwright codegen https://example.com"), "deny")
        self.assertEqual(bash("python3 -m playwright open https://example.com"), "deny")
        self.assertEqual(bash("python3 - <<'EOF'\nfrom playwright.sync_api import sync_playwright\nEOF"), "deny")
        self.assertEqual(bash("node -e \"require('puppeteer').launch()\""), "deny")
        for tool in ("mcp__claude-in-chrome__navigate", "mcp__playwright__browser_navigate",
                     "mcp__plugin_playwright_playwright__browser_click", "mcp__chrome-devtools__new_page"):
            self.assertEqual(pre(tool, {"url": "https://example.com"})["permissionDecision"], "deny", tool)
        self.assertEqual(pre("Skill", {"skill": "claude-in-chrome"})["permissionDecision"], "deny")

    def test_agent_desktop_and_tests_are_allowed(self):
        self.assertEqual(bash("~/.local/bin/claude-run --cwd /tmp 'agent-desktop list-windows --app \"Google Chrome\"'"),
                         "allow")
        self.assertEqual(bash("npx playwright test --project chromium"), "allow")
        self.assertEqual(bash("npx playwright install chromium"), "allow")
        self.assertEqual(bash("npx playwright --version"), "allow")
        self.assertEqual(bash("npm install -D @playwright/test"), "allow")
        self.assertEqual(bash("grep -rn 'claude-chrome\\|sync_playwright' ."), "allow")
        self.assertEqual(bash("node scripts/screenshot.mjs http://localhost:4200 /tmp/a.webp"), "allow")
        self.assertEqual(pre("mcp__t3-code__html_render", {})["permissionDecision"], "allow")
        self.assertEqual(pre("Skill", {"skill": "agent-desktop"})["permissionDecision"], "allow")

    def test_claude_run_alone_is_allowed(self):
        self.assertEqual(bash("~/.local/bin/claude-run --cwd /x 'git add -A && git commit -q -F /tmp/m.txt'"), "allow")
        self.assertEqual(bash("/Users/jrw_37/.local/bin/claude-run --cwd /x './scripts/build-app.sh > /tmp/b.log 2>&1'"), "allow")
        self.assertEqual(bash("grep -n claude-run notes.md"), "allow")
        self.assertEqual(bash("cd /x && python3 - <<'EOF'\nif 'claude-run' in line:\n    claude-chrome = 1\nEOF"), "allow")
        self.assertEqual(bash("~/.local/bin/claude-run --cwd /tmp 'open -g -a \"Google Chrome\" https://example.com'"),
                         "allow")

    def test_claude_run_bad_shapes_are_denied(self):
        self.assertEqual(bash("printf x > /tmp/m.txt; ~/.local/bin/claude-run --cwd /x 'git commit -F /tmp/m.txt'"), "deny")
        self.assertEqual(bash("cd /x && ~/.local/bin/claude-run 'make'"), "deny")
        self.assertEqual(bash("~/.local/bin/claude-run --cwd /x 'make' | tail -3"), "deny")
        self.assertEqual(bash("~/.local/bin/claude-run --cwd /x 'git status\ngit log'"), "deny")
        self.assertEqual(bash("~/.local/bin/claude-run --cwd /x 'bash -s' <<'EOF'\ngit status\nEOF"), "deny")

    def test_agent_runs_in_foreground_in_t3(self):
        output = pre("Agent", {"prompt": "x", "run_in_background": True}, CLAUDE_CODE_ENTRYPOINT="t3-code")
        self.assertEqual(output["permissionDecision"], "allow")
        self.assertIs(output["updatedInput"]["run_in_background"], False)
        self.assertEqual(output["updatedInput"]["prompt"], "x")
        output = pre("Agent", {"prompt": "x"}, CLAUDE_CODE_ENTRYPOINT="t3-code")
        self.assertIs(output["updatedInput"]["run_in_background"], False)

    def test_agent_is_untouched_outside_t3(self):
        output = pre("Agent", {"prompt": "x", "run_in_background": True}, CLAUDE_CODE_ENTRYPOINT="cli")
        self.assertEqual(output["permissionDecision"], "allow")
        self.assertNotIn("updatedInput", output)
        output = pre("Agent", {"prompt": "x", "run_in_background": False}, CLAUDE_CODE_ENTRYPOINT="t3-code")
        self.assertNotIn("updatedInput", output)

    def test_memory_scope(self):
        memory = "/Users/me/.claude/projects/-Users-me-Works-app/memory/"
        deny = {"file_path": memory + "note.md", "content": "swift build は claude-run で呼ぶ"}
        self.assertEqual(pre("Write", deny)["permissionDecision"], "deny")
        self.assertEqual(pre("Edit", {"file_path": memory + "note.md", "old_string": "a",
                                      "new_string": "T3 Code の設定"})["permissionDecision"], "deny")
        self.assertEqual(pre("Write", {"file_path": memory + "note.md", "content": "sandbox の外で実行する"})
                         ["permissionDecision"], "deny")
        self.assertEqual(pre("Write", {"file_path": memory + "note.md", "content": "agent-desktop で Box を開く"})
                         ["permissionDecision"], "deny")
        self.assertEqual(pre("Write", {"file_path": memory + "note.md", "content": "Notion の仕様書はここ"})
                         ["permissionDecision"], "allow")
        self.assertEqual(pre("Write", {"file_path": memory + "MEMORY.md", "content": "- [claude-run](x.md)"})
                         ["permissionDecision"], "allow")
        self.assertEqual(pre("Write", {"file_path": "/Users/me/dotfiles/claude/rules/environment.md",
                                       "content": "claude-run"})["permissionDecision"], "allow")


def transcript(directory, entries):
    path = Path(directory) / "t.jsonl"
    path.write_text("\n".join(json.dumps(e, ensure_ascii=False) for e in entries) + "\n")
    return str(path)


def now():
    return dt.datetime.now(dt.timezone.utc).isoformat()


def user(text):
    return {"type": "user", "message": {"role": "user", "content": text}, "timestamp": now()}


def assistant(text, usage=None):
    return {"type": "assistant", "timestamp": now(),
            "message": {"role": "assistant", "content": [{"type": "text", "text": text}], "usage": usage or {}}}


ENGLISH = ("I raised the volume to -23.5 dB, halfway between the two levels you compared. All five sounds changed "
           "together. The tests pass, and I rebuilt the app and confirmed that the new build is the one running.")
JAPANESE = "音量を -23.5 dB に上げました。比べた 2 つの中間です。5 つの音をそろえて変え、テストが通ること、" * 3


class StopJapanese(unittest.TestCase):
    def stop(self, entries, **extra):
        with tempfile.TemporaryDirectory() as directory:
            return run("stop-japanese.py", {"transcript_path": transcript(directory, entries), **extra})

    def test_blocks_english_reply(self):
        output = self.stop([user("音量を上げて"), assistant(ENGLISH)])
        self.assertEqual(output["decision"], "block")

    def test_ignores_tool_results_before_the_reply(self):
        tool_result = {"type": "user", "message": {"role": "user", "content": [
            {"type": "tool_result", "tool_use_id": "1", "content": "ok"}]}}
        output = self.stop([user("音量を上げて"), assistant(JAPANESE), tool_result, assistant(ENGLISH)])
        self.assertEqual(output["decision"], "block")

    def test_allows_japanese_and_code_heavy_replies(self):
        self.assertIsNone(self.stop([user("音量を上げて"), assistant(JAPANESE)]))
        code = "直しました。\n```swift\n" + "let volume = -23.5 // adjust the default level\n" * 20 + "```"
        self.assertIsNone(self.stop([user("直して"), assistant(code)]))

    def test_respects_english_request_and_loop_guard(self):
        self.assertIsNone(self.stop([user("英語で書いて"), assistant(ENGLISH)]))
        self.assertIsNone(self.stop([user("音量を上げて"), assistant(ENGLISH)], stop_hook_active=True))


class LongThread(unittest.TestCase):
    def test_warns_once_per_level(self):
        with tempfile.TemporaryDirectory() as home, tempfile.TemporaryDirectory() as directory:
            def prompt(tokens):
                path = transcript(directory, [user("x"), assistant("y", {"cache_read_input_tokens": tokens})])
                return run("long-thread.py", {"transcript_path": path, "session_id": "s1"}, HOME=home)
            self.assertIsNone(prompt(100_000))
            self.assertIn("新しいスレッド", prompt(350_000)["hookSpecificOutput"]["additionalContext"])
            self.assertIsNone(prompt(360_000))
            self.assertIsNotNone(prompt(410_000))
            self.assertIsNone(prompt(50_000))
            self.assertIsNotNone(prompt(320_000))


if __name__ == "__main__":
    unittest.main(verbosity=1)
