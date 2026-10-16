#!/usr/bin/env python3
"""Regera a tabela de tarefas do ESTADO.md a partir de .ai/tasks/*.json.

uso: estado.py [--check]

So o trecho entre os marcadores e gerado; o resto do ESTADO.md segue manual.
ID, Dono, Estado e O quê vêm do JSON. A coluna Notas é humana: é lida do ESTADO.md
atual (por ID) e reescrita como está. Nota de ID sem JSON aborta em vez de sumir.
Com --check nao escreve nada e sai 1 se o ESTADO.md divergir dos JSONs (CI).
"""
import json
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
ESTADO = ROOT / "ESTADO.md"
BEGIN = "<!-- tarefas:inicio (gerado por scripts/estado.py; nao edite a mao) -->"
END = "<!-- tarefas:fim -->"


def notes_by_id(block):
    """Notas humanas (5a coluna) da tabela atual, por ID. Tabela antiga de 4 colunas: sem notas."""
    notes = {}
    for line in block.split("\n"):
        cells = [c.strip() for c in re.split(r"(?<!\\)\|", line.strip())[1:-1]]
        # "|" cru digitado na nota gera colunas extras: junta de volta, escapado.
        note = " \\| ".join(cells[4:]).strip()
        if len(cells) >= 5 and re.fullmatch(r"AIC-\d+", cells[0]) and note:
            notes[cells[0]] = note
    return notes


def load_task(file):
    """Le um JSON de tarefa; erro claro (sem traceback) se ilegivel, malformado ou sem campos."""
    try:
        t = json.loads(file.read_text(encoding="utf-8"))
    except (OSError, UnicodeDecodeError, json.JSONDecodeError) as exc:
        raise SystemExit(f"{file.name}: JSON invalido ou ilegivel: {exc}")
    if not isinstance(t, dict):
        raise SystemExit(f"{file.name}: esperado objeto JSON, veio {type(t).__name__}")
    for key in ("task_id", "title", "state"):
        if not isinstance(t.get(key), str) or not t[key]:
            raise SystemExit(f"{file.name}: campo '{key}' ausente ou nao e texto")
    return t


def table(notes):
    rows = ["| ID | Dono | Estado | O quê | Notas |", "|---|---|---|---|---|"]
    ids = {}
    tasks_dir = ROOT / ".ai/tasks"
    if not tasks_dir.is_dir():
        raise SystemExit(f"{tasks_dir}: diretorio de tarefas ausente")
    for file in sorted(tasks_dir.glob("*.json")):
        t = load_task(file)
        if t["task_id"] in ids:
            raise SystemExit(f"{file.name}: task_id {t['task_id']} repetido (ja em {ids[t['task_id']]})")
        ids[t["task_id"]] = file.name
        title = " ".join(t["title"].split()).replace("|", "\\|")
        note = notes.get(t["task_id"], "")
        rows.append(f"| {t['task_id']} | {t.get('owner') or '-'} | **{t['state']}** | {title} | {note} |")
    orphans = sorted(set(notes) - set(ids))
    if orphans:
        raise SystemExit(f"{ESTADO.name}: notas de tarefa sem JSON ({', '.join(orphans)}); mova-as antes de regerar")
    return "\n".join(rows)


def render(text):
    if text.count(BEGIN) != 1 or text.count(END) != 1 or text.index(BEGIN) > text.index(END):
        raise SystemExit(f"{ESTADO.name}: marcadores da tabela ausentes ou duplicados")
    head, rest = text.split(BEGIN)
    block, tail = rest.split(END)
    return f"{head}{BEGIN}\n{table(notes_by_id(block))}\n{END}{tail}"


def main(argv):
    try:
        current = ESTADO.read_text(encoding="utf-8").replace("\r\n", "\n")
    except (OSError, UnicodeDecodeError) as exc:
        raise SystemExit(f"{ESTADO}: nao consegui ler: {exc}")
    wanted = render(current)
    if "--check" in argv:
        if current != wanted:
            print("ESTADO.md diverge de .ai/tasks/*.json; rode scripts/estado.py", file=sys.stderr)
            return 1
        print("ESTADO.md coerente com .ai/tasks/*.json")
        return 0
    ESTADO.write_text(wanted, encoding="utf-8", newline="\n")
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))
