#!/usr/bin/env bash
# ESTADO.md coerente com os JSONs, e o --check pega divergencia. Sem framework.
set -uo pipefail
ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd); cd "$ROOT"
PASS=0; FAIL=0
check() { if eval "$2" >/dev/null 2>&1; then printf 'ok   %s\n' "$1"; PASS=$((PASS + 1)); else printf 'FAIL %s\n' "$1" >&2; FAIL=$((FAIL + 1)); fi; }

check "ESTADO.md do repo coerente" "python3 scripts/estado.py --check"
SB=$(mktemp -d); trap 'rm -rf "$SB"' EXIT
mkdir -p "$SB/scripts" "$SB/.ai"; cp scripts/estado.py "$SB/scripts/"; cp -r .ai/tasks "$SB/.ai/"; cp ESTADO.md "$SB/"
python3 -c 'import json,sys;p=sys.argv[1];d=json.load(open(p));d["state"]="CANCELLED";json.dump(d,open(p,"w"))' "$SB/.ai/tasks/AIC-0001.json"
check "estado mudado no JSON -> --check falha" "! python3 $SB/scripts/estado.py --check"
check "gerador reescreve" "python3 $SB/scripts/estado.py && grep -q '| AIC-0001 | claude | \*\*CANCELLED\*\*' $SB/ESTADO.md"
check "depois de regerar -> --check passa" "python3 $SB/scripts/estado.py --check"
grep -v 'tarefas:inicio' "$SB/ESTADO.md" > "$SB/x" && mv "$SB/x" "$SB/ESTADO.md"
check "sem marcador -> falha" "! python3 $SB/scripts/estado.py --check"

printf '%d passou, %d falhou\n' "$PASS" "$FAIL"
[[ $FAIL -eq 0 ]]
