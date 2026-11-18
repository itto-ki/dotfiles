#!/usr/bin/env python3
"""UserPromptSubmit: スレッドが長くなったら、新しいスレッドへの切り替えを勧めさせる。

コンテキストが 30 万トークンを超えたとき（以後 10 万トークン増えるごと）と、開始から 24 時間を過ぎたとき（1 回）に、
返答の最後で切り替えを勧め、引き継ぎの要点を書くよう Claude に伝える。
compact などでコンテキストが減ったら数え直す。状態は ~/.cache/claude-hooks/long-thread/ に置く。
"""
import datetime as dt
import json
import re
import sys
from pathlib import Path

CONTEXT_STEP = 100_000
CONTEXT_START = 300_000
MAX_AGE_HOURS = 24
TAIL_BYTES = 2 * 1024 * 1024
HEAD_BYTES = 256 * 1024
STATE_DIR = Path.home() / ".cache/claude-hooks/long-thread"


def last_context(path):
    """最後のアシスタントの呼び出しが読んだトークン数（≒ 今のコンテキストの大きさ）。"""
    with open(path, "rb") as handle:
        handle.seek(0, 2)
        size = handle.tell()
        handle.seek(max(0, size - TAIL_BYTES))
        lines = handle.read().decode("utf-8", "replace").splitlines()
    for line in reversed(lines):
        if '"usage"' not in line:
            continue
        try:
            entry = json.loads(line)
        except ValueError:
            continue
        if entry.get("type") != "assistant" or entry.get("isSidechain"):
            continue
        usage = (entry.get("message") or {}).get("usage") or {}
        return sum(usage.get(key) or 0 for key in (
            "input_tokens", "cache_read_input_tokens", "cache_creation_input_tokens"))
    return 0


def started_at(path):
    with open(path, "rb") as handle:
        head = handle.read(HEAD_BYTES).decode("utf-8", "replace")
    match = re.search(r'"timestamp":\s*"([^"]+)"', head)
    if not match:
        return None
    try:
        return dt.datetime.fromisoformat(match.group(1).replace("Z", "+00:00"))
    except ValueError:
        return None


def main():
    try:
        data = json.load(sys.stdin)
    except ValueError:
        return
    path, session = data.get("transcript_path"), data.get("session_id")
    if not isinstance(path, str) or not isinstance(session, str) or not re.fullmatch(r"[\w-]+", session):
        return
    try:
        context = last_context(path)
        start = started_at(path)
    except OSError:
        return
    hours = (dt.datetime.now(dt.timezone.utc) - start).total_seconds() / 3600 if start else 0
    state_file = STATE_DIR / f"{session}.json"
    try:
        state = json.loads(state_file.read_text())
    except (OSError, ValueError):
        state = {"level": 0, "aged": False}
    level = context // CONTEXT_STEP if context >= CONTEXT_START else 0
    warn_context = level > state.get("level", 0)
    warn_age = hours >= MAX_AGE_HOURS and not state.get("aged")
    state = {"level": level, "aged": state.get("aged") or warn_age}
    try:
        STATE_DIR.mkdir(parents=True, exist_ok=True)
        state_file.write_text(json.dumps(state))
    except OSError:
        return
    if not (warn_context or warn_age):
        return
    print(json.dumps({"hookSpecificOutput": {
        "hookEventName": "UserPromptSubmit",
        "additionalContext": (
            f"このスレッドは長くなっている（コンテキスト約 {context // 10_000} 万トークン、開始から {hours:.0f} 時間）。"
            "今回の依頼に答えたあと、返答の最後に、新しいスレッドに移ることを 1 行で勧め、"
            "引き継ぎに要る要点（目的・決まったこと・残っていること）を 3 行以内で書く"),
    }}, ensure_ascii=False))


if __name__ == "__main__":
    main()
