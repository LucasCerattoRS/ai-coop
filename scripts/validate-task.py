#!/usr/bin/env python3
"""Validate task JSON, state transitions, and active-task scope separation."""
import json
import re
import sys
from datetime import datetime
from pathlib import Path


STATES = {"NEW", "ASSIGNED", "IN_PROGRESS", "HANDED_OFF", "UNDER_REVIEW", "CHANGES_REQUESTED", "ACCEPTED", "CLOSED", "CANCELLED"}
ACTIVE = {"ASSIGNED", "IN_PROGRESS", "HANDED_OFF", "UNDER_REVIEW", "CHANGES_REQUESTED"}
TRANSITIONS = {
    "NEW": {"ASSIGNED", "CANCELLED"},
    "ASSIGNED": {"IN_PROGRESS", "CANCELLED"},
    "IN_PROGRESS": {"HANDED_OFF", "CANCELLED"},
    "HANDED_OFF": {"UNDER_REVIEW", "ACCEPTED", "CANCELLED"},
    "UNDER_REVIEW": {"CHANGES_REQUESTED", "ACCEPTED", "CANCELLED"},
    "CHANGES_REQUESTED": {"IN_PROGRESS", "CANCELLED"},
    "ACCEPTED": {"CLOSED"},
    "CLOSED": set(),
    "CANCELLED": set(),
}
REQUIRED = {"schema_version", "task_id", "title", "state", "assigned_by", "created_at", "updated_at", "scope", "acceptance"}
OPTIONAL = {"owner", "role", "branch", "worktree", "base_commit", "handoffs", "notes"}
TASK_ID = re.compile(r"^AIC-\d{4}$")
SHA1 = re.compile(r"^[0-9a-f]{40}$")


def text(value):
    return isinstance(value, str) and bool(value.strip())


def timestamp(value):
    if not text(value) or "T" not in value:
        return False
    try:
        datetime.fromisoformat(value.replace("Z", "+00:00"))
    except ValueError:
        return False
    return True


def strings(value, nonempty=False):
    return isinstance(value, list) and all(isinstance(item, str) and (not nonempty or bool(item)) for item in value)


def check(task):
    errors = []
    if not isinstance(task, dict):
        return ["a tarefa precisa ser um objeto JSON"]
    missing = REQUIRED - set(task)
    if missing:
        errors.append(f"campos obrigatorios ausentes: {sorted(missing)}")
    extra = set(task) - REQUIRED - OPTIONAL
    if extra:
        errors.append(f"campos nao permitidos: {sorted(extra)}")
    if missing:
        return errors
    if task["schema_version"] != 1:
        errors.append("schema_version deve ser 1")
    if not TASK_ID.match(str(task["task_id"])):
        errors.append("task_id fora do formato AIC-NNNN")
    if not text(task["title"]):
        errors.append("title vazio")
    if task["state"] not in STATES:
        errors.append("state invalido")
    if task["assigned_by"] != "human":
        errors.append("assigned_by deve ser human")
    for field in ("created_at", "updated_at"):
        if not timestamp(task[field]):
            errors.append(f"{field} deve ser date-time ISO-8601")
    if "owner" in task and task["owner"] not in {"claude", "codex", None}:
        errors.append("owner deve ser claude, codex ou null")
    if "role" in task and task["role"] not in {"implement", "review"}:
        errors.append("role deve ser implement ou review")
    for field in ("branch", "worktree"):
        if field in task and task[field] is not None and not text(task[field]):
            errors.append(f"{field} deve ser string nao vazia ou null")
    if "base_commit" in task and task["base_commit"] is not None and not SHA1.match(str(task["base_commit"])):
        errors.append("base_commit deve ser SHA-1 completo ou null")
    if "handoffs" in task and not strings(task["handoffs"], True):
        errors.append("handoffs deve ser lista de strings nao vazias")
    if "notes" in task and not isinstance(task["notes"], str):
        errors.append("notes deve ser string")
    scope = task["scope"]
    if not isinstance(scope, dict) or set(scope) - {"allowed_paths", "forbidden_paths"}:
        errors.append("scope invalido")
    elif not strings(scope.get("allowed_paths"), True) or not scope["allowed_paths"]:
        errors.append("scope.allowed_paths deve ser lista nao vazia de strings")
    elif "forbidden_paths" in scope and not strings(scope["forbidden_paths"], True):
        errors.append("scope.forbidden_paths deve ser lista de strings nao vazias")
    if not strings(task["acceptance"], True) or not task["acceptance"]:
        errors.append("acceptance deve ser lista nao vazia de strings")
    return errors


def load(path):
    try:
        return json.loads(Path(path).read_text(encoding="utf-8")), None
    except FileNotFoundError:
        return None, "arquivo nao encontrado"
    except json.JSONDecodeError as exc:
        return None, f"JSON invalido: {exc}"


def validate_files(paths):
    tasks = []
    errors = []
    for path in paths:
        task, error = load(path)
        if error:
            errors.append(f"{path}: {error}")
            continue
        tasks.append((path, task))
        errors.extend(f"{path}: {error}" for error in check(task))
    return tasks, errors


def overlap(left, right):
    left, right = left.rstrip("/"), right.rstrip("/")
    return left == right or left.startswith(right + "/") or right.startswith(left + "/")


def scopes(tasks):
    errors = []
    active = [(path, task) for path, task in tasks if task.get("state") in ACTIVE and task.get("owner") in {"claude", "codex"}]
    for index, (left_path, left) in enumerate(active):
        for right_path, right in active[index + 1:]:
            if left["owner"] == right["owner"]:
                continue
            for a in left["scope"]["allowed_paths"]:
                for b in right["scope"]["allowed_paths"]:
                    if overlap(a, b):
                        errors.append(f"{left_path} e {right_path}: escopos sobrepostos ({a}, {b})")
    return errors


def main(argv):
    root = Path(__file__).resolve().parents[1]
    if len(argv) == 1:
        paths = sorted((root / ".ai/tasks").glob("*.json"))
        tasks, errors = validate_files(paths)
        errors.extend(scopes(tasks))
    elif argv[1] == "--transition" and len(argv) == 4:
        tasks, errors = validate_files(argv[2:])
        if len(tasks) == 2 and not errors:
            before, after = (task for _, task in tasks)
            if before["task_id"] != after["task_id"]:
                errors.append("transicao exige o mesmo task_id")
            elif before["state"] != after["state"] and after["state"] not in TRANSITIONS[before["state"]]:
                errors.append(f"transicao ilegal: {before['state']} -> {after['state']}")
    elif argv[1] == "--scopes" and len(argv) >= 3:
        tasks, errors = validate_files(argv[2:])
        errors.extend(scopes(tasks))
    elif len(argv) >= 2:
        tasks, errors = validate_files(argv[1:])
    else:
        print("uso: validate-task.py [ARQUIVO.json ... | --transition ANTES.json DEPOIS.json | --scopes ARQUIVO.json ...]", file=sys.stderr)
        return 2
    for error in errors:
        print(error, file=sys.stderr)
    return 1 if errors else 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))
