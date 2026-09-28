#!/usr/bin/env python3
"""Move uma tarefa ate STATE pelo caminho legal mais curto (SPEC §2).

uso: task-state.py TASK_ID STATE [--commit]

Sem --commit so aplica transicao direta (um passo). Com --commit aplica o caminho
inteiro, um commit por passo, para o historico mostrar cada transicao legal.
So o coordenador (ou um agente por ordem explicita dele, SPEC §1) roda isto.
"""
import importlib.util
import json
import subprocess
import sys
from collections import deque
from datetime import datetime, timezone
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
spec = importlib.util.spec_from_file_location("vt", ROOT / "scripts/validate-task.py")
vt = importlib.util.module_from_spec(spec)
spec.loader.exec_module(vt)


def path_to(start, goal):
    prev, queue = {start: None}, deque([start])
    while queue:
        cur = queue.popleft()
        if cur == goal:
            steps = []
            while cur != start:
                steps.append(cur)
                cur = prev[cur]
            return steps[::-1]
        for nxt in sorted(vt.TRANSITIONS[cur]):
            if nxt not in prev:
                prev[nxt] = cur
                queue.append(nxt)
    return None


def main(argv):
    args = [a for a in argv[1:] if a != "--commit"]
    commit = "--commit" in argv
    if len(args) != 2 or not vt.TASK_ID.match(args[0]) or args[1] not in vt.STATES:
        print(__doc__.strip().splitlines()[2], file=sys.stderr)
        return 2
    task_id, goal = args
    file = ROOT / ".ai/tasks" / f"{task_id}.json"
    task, error = vt.load(file)
    if error:
        print(f"{file}: {error}", file=sys.stderr)
        return 1
    steps = path_to(task["state"], goal)
    if steps is None:
        print(f"sem caminho legal de {task['state']} para {goal}", file=sys.stderr)
        return 1
    if not steps:
        print(f"{task_id} ja esta em {goal}")
        return 0
    if len(steps) > 1 and not commit:
        print(f"caminho: {' -> '.join([task['state']] + steps)}; rode com --commit (um commit por passo)",
              file=sys.stderr)
        return 1
    for state in steps:
        before = task["state"]
        task["state"] = state
        task["updated_at"] = datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")
        errors = vt.check(task)
        if errors:
            print("\n".join(errors), file=sys.stderr)
            return 1
        file.write_text(json.dumps(task, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
        print(f"{task_id}: {before} -> {state}")
        if commit:
            subprocess.run(["git", "-C", str(ROOT), "add", str(file)], check=True)
            subprocess.run(["git", "-C", str(ROOT), "commit", "-q", "-m", f"coord: {task_id} {before} -> {state}"],
                           check=True)
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))
