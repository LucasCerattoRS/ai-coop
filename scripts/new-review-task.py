#!/usr/bin/env python3
"""Gera a tarefa de revisao a partir do handoff de entrega (ou correcao).

uso: new-review-task.py HANDOFF.json NOVO_TASK_ID

Dono da revisao = to_agent do handoff. A tarefa nasce ASSIGNED, revisando o
delivery_commit exato (SPEC: revisao mira commit, nunca nome de branch).
"""
import importlib.util
import json
import sys
from datetime import datetime, timezone
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
spec = importlib.util.spec_from_file_location("vt", ROOT / "scripts/validate-task.py")
vt = importlib.util.module_from_spec(spec)
spec.loader.exec_module(vt)


def main(argv):
    if len(argv) != 3 or not vt.TASK_ID.match(argv[2]):
        print(__doc__.strip().splitlines()[2], file=sys.stderr)
        return 2
    handoff, error = vt.load(argv[1])
    if error:
        print(f"{argv[1]}: {error}", file=sys.stderr)
        return 1
    if handoff.get("kind") not in {"delivery", "correction"} or handoff.get("to_agent") not in {"claude", "codex"}:
        print("so handoff de delivery/correction destinado a claude ou codex vira tarefa de revisao", file=sys.stderr)
        return 1
    new_id, owner, author = argv[2], handoff["to_agent"], handoff["from_agent"]
    commit, source = handoff["delivery_commit"], handoff["task_id"]
    file = ROOT / ".ai/tasks" / f"{new_id}.json"
    if file.exists():
        print(f"{file} ja existe; recusando sobrescrever", file=sys.stderr)
        return 1
    now = datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")
    task = {
        "schema_version": 1,
        "task_id": new_id,
        "title": f"Revisao independente da {source} sobre {commit[:7]}",
        "state": "ASSIGNED",
        "owner": owner,
        "role": "review",
        "assigned_by": "human",
        "created_at": now,
        "updated_at": now,
        "branch": f"{owner}/{new_id}-review",
        "worktree": None,
        "base_commit": None,
        "scope": {
            "allowed_paths": [f".ai/handoffs/{new_id}/"],
            "forbidden_paths": [".ai/tasks/", f"o worktree de {author} (ler so por git show {commit[:7]}:<caminho>)"],
        },
        "acceptance": [
            f"Le o handoff {handoff['handoff_id']} (branch {handoff['branch']}) e revisa o commit {commit}, nunca o nome da branch",
            f"Confere os criterios de aceite da {source} e os riscos declarados no handoff",
            f"Parecer em handoff kind=review: scripts/handoff.sh {new_id} {owner} {author} review {commit}, validado e commitado na propria branch",
            "Sem editar o trabalho revisado; achados viram correcao do autor",
        ],
        "handoffs": [],
        "notes": f"Gerada por scripts/new-review-task.py a partir de {handoff['handoff_id']}.",
    }
    errors = vt.check(task)
    if errors:
        print("\n".join(errors), file=sys.stderr)
        return 1
    file.write_text(json.dumps(task, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    print(file.relative_to(ROOT))
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))
