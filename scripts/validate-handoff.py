#!/usr/bin/env python3
"""Valida um handoff contra o contrato de .ai/schemas/handoff.schema.json.

ponytail: validacao escrita a mao contra ESTE schema, nao um validador
JSON Schema generico. jsonschema nao esta instalado e o contrato e pequeno.
Teto: mudou o schema, mude aqui tambem. Se o contrato crescer, trocar por
`pip install jsonschema` e 5 linhas.

Saida: 0 valido, 1 invalido, 2 uso incorreto.
"""
import json
import re
import sys
from pathlib import Path

HANDOFF_ID = re.compile(r"^AIC-\d{4}-\d{4}$")
TASK_ID = re.compile(r"^AIC-\d{4}$")
SHA1 = re.compile(r"^[0-9a-f]{40}$")
PREV = re.compile(r"^\d{4}-(claude|codex)\.json$")
ISO = re.compile(r"^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}Z$")

AGENTS = {"claude", "codex"}
TARGETS = AGENTS | {"human"}
KINDS = {"delivery", "review", "correction"}
RESULTS = {"pass", "fail", "not_run"}
SEVERITIES = {"high", "medium", "low"}

REQUIRED = [
    "schema_version", "handoff_id", "task_id", "sequence", "from_agent",
    "to_agent", "kind", "created_at", "branch", "base_commit",
    "delivery_commit", "summary", "changes", "tests", "risks",
    "next_action", "previous_handoff",
]
OPTIONAL = ["findings"]

# Placeholders que o gerador escreve e o agente tem de substituir.
PLACEHOLDER = re.compile(r"(?i)\bTODO\b|^<.*>$|^$")


def nonempty_str(value):
    return isinstance(value, str) and value.strip() != ""


def check(handoff):
    errors = []

    def err(msg):
        errors.append(msg)

    for key in REQUIRED:
        if key not in handoff:
            err(f"campo obrigatorio ausente: {key}")
    extra = set(handoff) - set(REQUIRED) - set(OPTIONAL)
    if extra:
        err(f"campos nao permitidos: {sorted(extra)}")
    if errors:
        return errors

    if handoff["schema_version"] != 1:
        err("schema_version deve ser 1")
    if not HANDOFF_ID.match(str(handoff["handoff_id"])):
        err("handoff_id fora do formato AIC-NNNN-NNNN")
    if not TASK_ID.match(str(handoff["task_id"])):
        err("task_id fora do formato AIC-NNNN")
    if not str(handoff["handoff_id"]).startswith(str(handoff["task_id"]) + "-"):
        err("handoff_id nao pertence a task_id")

    seq = handoff["sequence"]
    if not isinstance(seq, int) or isinstance(seq, bool) or seq < 1:
        err("sequence deve ser inteiro >= 1")
    elif not str(handoff["handoff_id"]).endswith(f"-{seq:04d}"):
        err("handoff_id nao corresponde a sequence")

    if handoff["from_agent"] not in AGENTS:
        err(f"from_agent deve ser um de {sorted(AGENTS)}")
    if handoff["to_agent"] not in TARGETS:
        err(f"to_agent deve ser um de {sorted(TARGETS)}")
    if handoff["from_agent"] == handoff["to_agent"]:
        err("from_agent e to_agent nao podem ser o mesmo agente")
    if handoff["kind"] not in KINDS:
        err(f"kind deve ser um de {sorted(KINDS)}")
    if not ISO.match(str(handoff["created_at"])):
        err("created_at deve ser ISO-8601 UTC (YYYY-MM-DDTHH:MM:SSZ)")
    if not nonempty_str(handoff["branch"]):
        err("branch vazio")
    for field in ("base_commit", "delivery_commit"):
        if not SHA1.match(str(handoff[field])):
            err(f"{field} deve ser um SHA-1 completo de 40 caracteres")

    for field in ("summary", "next_action"):
        value = handoff[field]
        if not nonempty_str(value):
            err(f"{field} vazio")
        elif PLACEHOLDER.search(value.strip()):
            err(f"{field} ainda contem placeholder do gerador")

    changes = handoff["changes"]
    if not isinstance(changes, list) or not changes:
        err("changes deve ter ao menos um item")
    else:
        for i, item in enumerate(changes):
            if not isinstance(item, dict) or set(item) != {"path", "what"}:
                err(f"changes[{i}] deve ter exatamente path e what")
            elif not (nonempty_str(item["path"]) and nonempty_str(item["what"])):
                err(f"changes[{i}] tem campo vazio")

    tests = handoff["tests"]
    if not isinstance(tests, list) or not tests:
        err("tests deve ter ao menos um item (use result=not_run e justifique)")
    else:
        for i, item in enumerate(tests):
            if not isinstance(item, dict) or not {"command", "result"} <= set(item):
                err(f"tests[{i}] precisa de command e result")
            elif set(item) - {"command", "result", "note"}:
                err(f"tests[{i}] tem campo nao permitido")
            elif item["result"] not in RESULTS:
                err(f"tests[{i}].result deve ser um de {sorted(RESULTS)}")
            elif not nonempty_str(item["command"]):
                err(f"tests[{i}].command vazio")

    risks = handoff["risks"]
    if not isinstance(risks, list) or any(not nonempty_str(r) for r in risks):
        err("risks deve ser lista de strings nao vazias (lista vazia e permitida)")

    prev = handoff["previous_handoff"]
    if seq == 1:
        if prev is not None:
            err("o primeiro handoff da tarefa precisa de previous_handoff null")
    elif isinstance(seq, int) and seq >= 2:
        if not isinstance(prev, str) or not PREV.match(prev):
            err("handoff de sequence >= 2 precisa apontar o anterior (NNNN-agente.json)")
        elif not prev.startswith(f"{seq - 1:04d}-"):
            err("previous_handoff nao aponta para a sequencia imediatamente anterior")

    if handoff["kind"] == "review":
        findings = handoff.get("findings")
        if not isinstance(findings, list):
            err("kind=review exige findings (lista, possivelmente vazia)")
        else:
            for i, f in enumerate(findings):
                if not isinstance(f, dict) or not {"severity", "path", "finding"} <= set(f):
                    err(f"findings[{i}] precisa de severity, path e finding")
                elif set(f) - {"severity", "path", "line", "finding"}:
                    err(f"findings[{i}] tem campo nao permitido")
                elif f["severity"] not in SEVERITIES:
                    err(f"findings[{i}].severity invalido")
    elif "findings" in handoff:
        err("findings so e permitido em kind=review")

    return errors


def main(argv):
    if len(argv) != 2:
        print("uso: validate-handoff.py CAMINHO_DO_HANDOFF.json", file=sys.stderr)
        return 2
    path = Path(argv[1])
    try:
        handoff = json.loads(path.read_text(encoding="utf-8"))
    except FileNotFoundError:
        print(f"arquivo nao encontrado: {path}", file=sys.stderr)
        return 2
    except json.JSONDecodeError as exc:
        print(f"JSON invalido: {exc}", file=sys.stderr)
        return 1
    if not isinstance(handoff, dict):
        print("o handoff precisa ser um objeto JSON", file=sys.stderr)
        return 1

    errors = check(handoff)
    if errors:
        for e in errors:
            print(f"INVALIDO: {e}", file=sys.stderr)
        return 1
    print(f"VALIDO: {handoff['handoff_id']}")
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))
