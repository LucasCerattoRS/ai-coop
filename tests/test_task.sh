#!/usr/bin/env bash
# Valida contrato, transicoes e escopos de tarefas. Sem framework.
set -uo pipefail
ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd); cd "$ROOT"
V=scripts/validate-task.py; PASS=0; FAIL=0
ok() { printf 'ok   %s\n' "$1"; PASS=$((PASS + 1)); }
bad() { printf 'FAIL %s\n' "$1" >&2; FAIL=$((FAIL + 1)); }
check() { if eval "$2"; then ok "$1"; else bad "$1"; fi; }

check "tarefas reais validas e escopos disjuntos" "$V"
SB=$(mktemp -d); trap 'rm -rf "$SB"' EXIT
A="$SB/antes.json"; B="$SB/depois.json"; BAD="$SB/invalida.json"
cp .ai/tasks/AIC-0009.json "$A"
set_state() { python3 -c 'import json,sys;p=sys.argv[1];d=json.load(open(p));d["state"]=sys.argv[2];json.dump(d,open(p,"w"))' "$1" "$2"; }

while read -r before after; do
  cp "$A" "$B"; set_state "$A" "$before"; set_state "$B" "$after"
  check "transicao legal $before -> $after" "$V --transition $A $B"
done <<'EOF'
NEW ASSIGNED
NEW CANCELLED
ASSIGNED IN_PROGRESS
ASSIGNED CANCELLED
IN_PROGRESS HANDED_OFF
IN_PROGRESS CANCELLED
HANDED_OFF UNDER_REVIEW
HANDED_OFF ACCEPTED
HANDED_OFF CANCELLED
UNDER_REVIEW CHANGES_REQUESTED
UNDER_REVIEW ACCEPTED
UNDER_REVIEW CANCELLED
CHANGES_REQUESTED IN_PROGRESS
CHANGES_REQUESTED CANCELLED
ACCEPTED CLOSED
EOF

cp "$A" "$B"; set_state "$A" NEW; set_state "$B" CLOSED
check "transicao ilegal falha" "! $V --transition $A $B"
printf '{}' > "$BAD"
check "schema invalido falha" "! $V $BAD"

scope_task() {
  cp .ai/tasks/AIC-0009.json "$1"
  python3 -c 'import json,sys;p=sys.argv[1];d=json.load(open(p));d["task_id"]=sys.argv[2];d["owner"]=sys.argv[3];d["state"]=sys.argv[4];d["scope"]["allowed_paths"]=[sys.argv[5]];json.dump(d,open(p,"w"))' "$1" "$2" "$3" "$4" "$5"
}
X="$SB/x.json"; Y="$SB/y.json"
scope_task "$X" AIC-9001 claude ASSIGNED scripts
scope_task "$Y" AIC-9002 codex ASSIGNED scripts/tool.py
check "prefixo de escopo com donos distintos falha" "! $V --scopes $X $Y"
scope_task "$Y" AIC-9002 codex ASSIGNED docs
check "escopos distintos passam" "$V --scopes $X $Y"
scope_task "$Y" AIC-9002 claude ASSIGNED scripts
check "mesmo dono pode compartilhar escopo" "$V --scopes $X $Y"
scope_task "$Y" AIC-9002 codex CLOSED scripts
check "tarefa terminal nao bloqueia escopo" "$V --scopes $X $Y"
scope_task "$Y" AIC-9002 codex ACCEPTED scripts
check "tarefa aceita nao bloqueia escopo ativo" "$V --scopes $X $Y"

printf '%s passaram, %s falharam\n' "$PASS" "$FAIL"
(( FAIL == 0 ))
