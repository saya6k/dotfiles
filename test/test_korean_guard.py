"""python3 test/test_korean_guard.py 로 실행한다.

minorun365/claude-code-japanese-guard 의 테스트를 한국어용으로 옮긴 것 (Apache License 2.0)."""

import json
import os
import subprocess
import sys
import tempfile
import threading
from pathlib import Path

HOOK = Path(__file__).resolve().parent.parent / "config" / "claude" / "hooks" / "korean-guard.py"


def user(text):
    return {"type": "user", "message": {"role": "user", "content": text}}


def tool_result():
    return {"type": "user", "message": {"role": "user", "content": [{"type": "tool_result", "content": "ok"}]}}


def assistant(text):
    return {"type": "assistant", "message": {"role": "assistant", "content": [{"type": "text", "text": text}]}}


def tool_use():
    return {"type": "assistant", "message": {"role": "assistant", "content": [{"type": "tool_use", "name": "Bash", "input": {}}]}}


def thinking(text, display="updates"):
    return {"type": "assistant", "thinkingDisplay": display,
            "message": {"role": "assistant", "content": [{"type": "thinking", "thinking": text}]}}


def wrap_up(recap, ask=None, actions=None):
    inp = {"recap": recap}
    if ask:
        inp["ask"] = ask
    if actions is not None:
        inp["actions"] = actions
    return {"type": "assistant", "message": {"role": "assistant", "content": [
        {"type": "tool_use", "name": "mcp__ccd_turn__wrap_up", "input": inp}]}}


def pre_tool_use(tool_name, tool_input):
    payload = json.dumps({"hook_event_name": "PreToolUse", "tool_name": tool_name, "tool_input": tool_input})
    out = subprocess.run([sys.executable, str(HOOK)], input=payload, capture_output=True, text=True, check=True)
    return json.loads(out.stdout) if out.stdout.strip() else None


def run(entries, stop_hook_active=False, last_message=None):
    with tempfile.NamedTemporaryFile("w", suffix=".jsonl", delete=False, encoding="utf-8") as f:
        for e in entries:
            f.write(json.dumps(e, ensure_ascii=False) + "\n")
    data = {"transcript_path": f.name, "stop_hook_active": stop_hook_active}
    if last_message is not None:
        data["last_assistant_message"] = last_message
    payload = json.dumps(data)
    out = subprocess.run([sys.executable, str(HOOK)], input=payload, capture_output=True, text=True, check=True)
    return json.loads(out.stdout) if out.stdout.strip() else None


EN = "The build finished successfully and all tests passed, so I will publish the page now."
KO = "빌드가 통과했고 테스트도 모두 성공해서 페이지를 공개하겠습니다."
EN_MID = ("I have finished reading the configuration files.\n"
          "Next I will update the build script, run the tests again, and report the results once everything passes.")
EN_ONE_LINE = "Register the page in the index after the existing entry, then publish it and check the build log."
KO_MID = "설정 파일을 다 읽었습니다. 다음으로 빌드 스크립트를 고치고 테스트를 다시 돌리겠습니다."

cases = [
    ("영어 본문은 되돌린다", [user("공개해 줘"), assistant(EN)], False, True),
    ("한국어 본문은 통과", [user("공개해 줘"), assistant(KO)], False, False),
    ("도구 전 한마디가 영어여도 최종 답변이 한국어면 통과", [user("공개해 줘"), assistant("Checking the build first."
        " Then I will run the whole test suite."), tool_use(), tool_result(), assistant(KO)], False, False),
    ("도구 전 한 줄 머리말이 영문자 60자를 넘어도 최종 답변이 한국어면 통과", [user("공개해 줘"), assistant(EN_ONE_LINE),
        tool_use(), tool_result(), assistant(KO)], False, False),
    ("마지막 도구 뒤의 최종 답변이 영어면 되돌린다", [user("공개해 줘"), assistant(KO), tool_use(), tool_result(),
        assistant(EN)], False, True),
    ("도구 없는 턴에 영어 문단이 섞이면 되돌린다", [user("공개해 줘"), assistant(KO), assistant(EN)], False, True),
    ("코드 블록의 영어는 세지 않는다", [user("절차는?"), assistant("다음 명령을 실행합니다.\n```bash\n"
        "npm install && npm run build && npm test -- --coverage --watchAll=false\n```")], False, False),
    ("Markdown 링크는 표시 글자도 세지 않는다", [user("자료는?"),
        assistant("참고: [Apple Developer Documentation](https://developer.apple.com/documentation/)")], False, False),
    ("이전 턴의 영어는 대상 외", [user("a"), assistant(EN), user("b"), assistant(KO)], False, False),
    ("두 번째는 통과(무한 루프 방지)", [user("공개해 줘"), assistant(EN)], True, False),
    ("짧은 영어는 넘어간다", [user("괜찮아?"), assistant("OK, done.")], False, False),
    ("도구 사이의 긴 중간 보고가 영어면 되돌린다", [user("공개해 줘"), assistant(EN_MID), tool_use(), tool_result(),
        assistant(KO)], False, True),
    ("updates 표시 thinking의 중간 보고가 영어면 되돌린다", [user("공개해 줘"), thinking(EN_MID), tool_use(),
        tool_result(), assistant(KO)], False, True),
    ("updates 표시 thinking이라도 한국어면 통과", [user("공개해 줘"), thinking(KO_MID), tool_use(), tool_result(),
        assistant(KO)], False, False),
    ("updates 외의 thinking은 세지 않는다", [user("공개해 줘"), thinking(EN_MID, display="summarized"), tool_use(),
        tool_result(), assistant(KO)], False, False),
    ("다음 단계 상자가 영어면 되돌린다", [user("공개해 줘"), wrap_up(EN, "Should I publish it now?"), tool_result(),
        assistant("No response requested.")], False, True),
    ("다음 단계 상자가 한국어면 통과", [user("공개해 줘"), wrap_up(KO, "공개할까요?",
        [{"label": "공개하기"}]), tool_result(), assistant("(응답 없음)")], False, False),
]

failed = 0
for name, entries, active, expect_block in cases:
    result = run(entries, active)
    blocked = bool(result and result.get("decision") == "block")
    ok = blocked == expect_block
    failed += not ok
    print(("✓ " if ok else "✗ ") + name)
# 최종 답변이 hook 실행보다 늦게 기록되어도 기다렸다가 판정한다
with tempfile.NamedTemporaryFile("w", suffix=".jsonl", delete=False, encoding="utf-8") as f:
    for e in [user("공개해 줘"), tool_use(), tool_result()]:
        f.write(json.dumps(e, ensure_ascii=False) + "\n")
late = json.dumps(assistant(EN), ensure_ascii=False) + "\n"
threading.Timer(0.5, lambda: open(f.name, "a", encoding="utf-8").write(late)).start()
out = subprocess.run([sys.executable, str(HOOK)], input=json.dumps({"transcript_path": f.name}),
                     capture_output=True, text=True, check=True)
ok = bool(out.stdout.strip()) and json.loads(out.stdout).get("decision") == "block"
failed += not ok
print(("✓ " if ok else "✗ ") + "최종 답변 기록이 늦어도 영어면 되돌린다")
# 최종 답변이 last_assistant_message에만 있을 때(transcript에 아직 기록되지 않음)
import time
t0 = time.time()
r = run([user("공개해 줘"), tool_use(), tool_result()], last_message=EN)
ok = bool(r and r.get("decision") == "block") and time.time() - t0 < 2
failed += not ok
print(("✓ " if ok else "✗ ") + "last_assistant_message가 영어면 transcript를 기다리지 않고 되돌린다")
r = run([user("공개해 줘"), assistant(KO)], last_message=KO)
ok = r is None
failed += not ok
print(("✓ " if ok else "✗ ") + "last_assistant_message가 한국어면 통과")
r = run([user("공개해 줘"), assistant(EN), assistant(KO)], last_message=KO)
ok = bool(r and r.get("decision") == "block")
failed += not ok
print(("✓ " if ok else "✗ ") + "last_assistant_message가 한국어여도 나뉜 앞부분이 영어면 transcript 쪽에서 되돌린다")
# 최종 답변이 JSON뿐이면 기계가 읽는 출력으로 보고 통과
JSON_OUT = json.dumps({"status": "ok", "items": [{"title": "Weekly build report", "summary": EN}]})
for name, msg, expect_block in [
    ("최종 답변이 JSON뿐이면 통과", JSON_OUT, False),
    ("코드 펜스로 감싼 JSON도 통과", "```json\n" + JSON_OUT + "\n```", False),
    ("JSON 앞에 영어 설명이 붙으면 되돌린다", EN + "\n" + JSON_OUT, True),
    ("{로 시작해도 JSON으로 못 읽으면 되돌린다", "{" + EN, True),
]:
    r = run([user("목록을 JSON으로"), tool_use(), tool_result()], last_message=msg)
    ok = bool(r and r.get("decision") == "block") == expect_block
    failed += not ok
    print(("✓ " if ok else "✗ ") + name)
# KOREAN_GUARD_DISABLE=1이면 아무것도 하지 않는다
with tempfile.NamedTemporaryFile("w", suffix=".jsonl", delete=False, encoding="utf-8") as f:
    for e in [user("공개해 줘"), assistant(EN)]:
        f.write(json.dumps(e, ensure_ascii=False) + "\n")
env = {**os.environ, "KOREAN_GUARD_DISABLE": "1"}
out = subprocess.run([sys.executable, str(HOOK)], input=json.dumps({"transcript_path": f.name,
                     "last_assistant_message": EN}), capture_output=True, text=True, check=True, env=env)
ok = not out.stdout.strip()
failed += not ok
print(("✓ " if ok else "✗ ") + "KOREAN_GUARD_DISABLE=1이면 영어여도 통과")
# PreToolUse: 다음 단계 상자는 화면에 나오기 전에 막는다
checks = [
    ("PreToolUse: 영어 상자는 deny", "mcp__ccd_turn__wrap_up",
     {"recap": EN, "ask": "Publish now?", "actions": [{"label": "Publish", "message": "Yes, go ahead."}]}, True),
    ("PreToolUse: 버튼이 JSON 문자열로 와도 읽는다", "mcp__ccd_turn__wrap_up",
     {"recap": "공개 준비가 끝났습니다.", "actions": json.dumps([{"label": "Go", "message": EN}])}, True),
    ("PreToolUse: 한국어 상자는 통과", "mcp__ccd_turn__wrap_up",
     {"recap": KO, "ask": "공개할까요?", "actions": [{"label": "공개하기"}]}, False),
    ("PreToolUse: 다른 도구는 보지 않는다", "Bash", {"command": EN}, False),
]
for name, tool, inp, expect_deny in checks:
    r = pre_tool_use(tool, inp)
    denied = bool(r and r.get("hookSpecificOutput", {}).get("permissionDecision") == "deny")
    ok = denied == expect_deny
    failed += not ok
    print(("✓ " if ok else "✗ ") + name)
sys.exit(1 if failed else 0)
