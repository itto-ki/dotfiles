#!/usr/bin/env python3
"""Stop: 最後の返答が英語になっていたら、日本語で書き直させる。

コードブロック・インラインコード・URL・パスを除いた文字のうち、かなと漢字が 20% 未満で、
文字が 150 以上あるときだけ止める。ユーザーが英語を頼んだターンと、
このフックで一度止めたあと（stop_hook_active）は止めない。
"""
import json
import re
import sys

MIN_LETTERS = 150
MIN_JAPANESE_RATIO = 0.2
TAIL_BYTES = 4 * 1024 * 1024
JAPANESE = re.compile(r"[぀-ヿ㐀-鿿ｦ-ﾟ]")
LATIN = re.compile(r"[A-Za-z]")
ASKED_ENGLISH = re.compile(r"英語|English", re.IGNORECASE)


def strip_noise(text):
    text = re.sub(r"```.*?```", " ", text, flags=re.DOTALL)
    text = re.sub(r"`[^`\n]*`", " ", text)
    text = re.sub(r"\]\([^)]*\)", "]", text)
    text = re.sub(r"https?://\S+", " ", text)
    text = re.sub(r"(?<![\w])[~/][\w./@%+=:-]+", " ", text)
    return text


def measure(text):
    """(かな・漢字とラテン文字の数, かな・漢字の割合) を返す。"""
    text = strip_noise(text)
    japanese = len(JAPANESE.findall(text))
    total = japanese + len(LATIN.findall(text))
    return total, (japanese / total if total else 1.0)


def text_blocks(content):
    if isinstance(content, str):
        return [content]
    if isinstance(content, list):
        return [block.get("text", "") for block in content if isinstance(block, dict) and block.get("type") == "text"]
    return []


def is_tool_result(content):
    return isinstance(content, list) and any(
        isinstance(block, dict) and block.get("type") == "tool_result" for block in content)


def read_tail(path):
    with open(path, "rb") as handle:
        handle.seek(0, 2)
        size = handle.tell()
        handle.seek(max(0, size - TAIL_BYTES))
        lines = handle.read().decode("utf-8", "replace").splitlines()
    return lines[1:] if size > TAIL_BYTES else lines


def last_turn(lines):
    """(最後のユーザーの依頼, その依頼への最後の返答) を返す。"""
    reply, prompt, in_reply = [], "", True
    for line in reversed(lines):
        try:
            entry = json.loads(line)
        except ValueError:
            continue
        if not isinstance(entry, dict) or entry.get("isSidechain"):
            continue
        kind = entry.get("type")
        content = (entry.get("message") or {}).get("content")
        if kind == "assistant":
            if in_reply:
                reply[:0] = text_blocks(content)
        elif kind == "user" and not entry.get("isMeta"):
            in_reply = False
            if is_tool_result(content):
                continue
            text = "\n".join(text_blocks(content)).strip()
            if text and not text.startswith("<"):
                prompt = text
                break
    return prompt, "\n".join(reply)


def main():
    try:
        data = json.load(sys.stdin)
    except ValueError:
        return
    if not isinstance(data, dict) or data.get("stop_hook_active"):
        return
    prompt, reply = "", data.get("last_assistant_message") if isinstance(data.get("last_assistant_message"), str) else ""
    path = data.get("transcript_path")
    if isinstance(path, str) and path:
        try:
            prompt, transcript_reply = last_turn(read_tail(path))
        except OSError:
            transcript_reply = ""
        reply = reply or transcript_reply
    if not reply or ASKED_ENGLISH.search(prompt):
        return
    letters, ratio = measure(reply)
    if letters < MIN_LETTERS or ratio >= MIN_JAPANESE_RATIO:
        return
    print(json.dumps({
        "decision": "block",
        "reason": (f"最後の返答が英語になっている（かな・漢字の割合 {ratio:.0%}）。同じ内容を日本語で書き直して、"
                   "もう一度返答する。コード・コマンド・識別子・固有名詞は原文のまま"),
    }, ensure_ascii=False))


if __name__ == "__main__":
    main()
