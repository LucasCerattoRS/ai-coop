#!/usr/bin/env python3
"""Regera a tabela de tarefas do ESTADO.md a partir de .ai/tasks/*.json.

uso: estado.py [--check]

So o trecho entre os marcadores e gerado; o resto do ESTADO.md segue manual.
Com --check nao escreve nada e sai 1 se o ESTADO.md divergir dos JSONs (CI).
"""
import json
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
ESTADO = ROOT / "ESTADO.md"
BEGIN = "<!-- tarefas:inicio (gerado por scripts/estado.py; nao edite a mao) -->"
END = "<!-- tarefas:fim -->"


def table():
    rows = ["| ID | Dono | Estado | O quê |", "|---|---|---|---|"]
    for file in sorted((ROOT / ".ai/tasks").glob("*.json")):
        t = json.loads(file.read_text(encoding="utf-8"))
        title = t["title"].replace("|", "\\|")
        rows.append(f"| {t['task_id']} | {t.get('owner') or '-'} | **{t['state']}** | {title} |")
    return "\n".join(rows)


def render(text):
    if text.count(BEGIN) != 1 or text.count(END) != 1 or text.index(BEGIN) > text.index(END):
        raise SystemExit(f"{ESTADO.name}: marcadores da tabela ausentes ou duplicados")
    head, rest = text.split(BEGIN)
    _, tail = rest.split(END)
    return f"{head}{BEGIN}\n{table()}\n{END}{tail}"


def main(argv):
    current = ESTADO.read_text(encoding="utf-8").replace("\r\n", "\n")
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
