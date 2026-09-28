#!/usr/bin/env bash
# Adocao em repo novo (adopt.sh), transicao por caminho legal (task-state.py) e tarefa de
# revisao gerada do handoff (new-review-task.py). Sem framework. Usa o HEAD deste repo.
set -uo pipefail
SRC=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
PASS=0; FAIL=0
ok() { printf 'ok   %s\n' "$1"; PASS=$((PASS + 1)); }
bad() { printf 'FAIL %s\n' "$1" >&2; FAIL=$((FAIL + 1)); }
check() { if [[ $1 == "$2" ]]; then ok "$3"; else bad "$3 (esperado '$2', obtido '$1')"; fi; }

SB=$(mktemp -d); trap 'rm -rf "$SB"' EXIT
new_repo() { git init -q -b main "$1"; git -C "$1" config user.name t; git -C "$1" config user.email t@t; }
D="$SB/destino"; new_repo "$D"; echo app > "$D/app.txt"; git -C "$D" add -A; git -C "$D" commit -qm base

bash "$SRC/scripts/adopt.sh" "$D" >/dev/null; check $? 0 "adota em repo novo"
bash "$SRC/scripts/adopt.sh" --check "$D" >/dev/null; check $? 0 "--check logo depois: em dia"
check "$(cat "$D/PROTOCOL-VERSION")" "ai-coop $(git -C "$SRC" rev-parse HEAD)" "PROTOCOL-VERSION grava o commit de origem"
[[ -x $D/scripts/handoff.sh && ! -x $D/AGENTS.md ]]; check $? 0 "modo de execucao preservado"
(cd "$D" && bash scripts/ai-coop-doctor.sh >/dev/null); check $? 0 "doctor OK no destino"

echo '# minhas decisoes' > "$D/.ai/DECISIONS.md"; echo mexido >> "$D/scripts/handoff.sh"
bash "$SRC/scripts/adopt.sh" --check "$D" 2>/dev/null | grep -q 'DESATUALIZADO scripts/handoff.sh'; check $? 0 "--check aponta o arquivo divergente"
bash "$SRC/scripts/adopt.sh" --check "$D" >/dev/null; check $? 1 "--check sai 1 quando desatualizado"
bash "$SRC/scripts/adopt.sh" "$D" >/dev/null
bash "$SRC/scripts/adopt.sh" --check "$D" >/dev/null; check $? 0 "readocao corrige o divergente"
check "$(cat "$D/.ai/DECISIONS.md")" "# minhas decisoes" "readocao nao toca DECISIONS.md"

F="$SB/alheio"; new_repo "$F"; echo '# Regras do meu projeto' > "$F/AGENTS.md"
bash "$SRC/scripts/adopt.sh" "$F" >/dev/null 2>&1; check $? 1 "recusa sobrescrever AGENTS.md alheio"
[[ ! -e $F/scripts/handoff.sh ]]; check $? 0 "recusa nao deixa arquivo pela metade"
bash "$SRC/scripts/adopt.sh" "$SRC" >/dev/null 2>&1; check $? 2 "recusa adotar no proprio ai-coop"

git -C "$D" add -A; git -C "$D" commit -qm "coord: adota ai-coop"
python3 - "$D/.ai/tasks/DW-0001.json" <<'EOF'
import json, sys
json.dump({"schema_version": 1, "task_id": "DW-0001", "title": "t", "state": "ASSIGNED", "owner": "claude",
           "role": "implement", "assigned_by": "human", "created_at": "2026-09-28T00:00:00Z",
           "updated_at": "2026-09-28T00:00:00Z", "scope": {"allowed_paths": ["docs/"]}, "acceptance": ["a"]},
          open(sys.argv[1], "w"))
EOF
(cd "$D" && python3 scripts/validate-task.py >/dev/null); check $? 0 "tarefa com prefixo DW valida no destino"
TS="python3 $D/scripts/task-state.py"
$TS DW-0001 HANDED_OFF >/dev/null 2>&1; check $? 1 "dois passos sem --commit: recusa"
$TS DW-0001 HANDED_OFF 2>&1 | grep -q 'ASSIGNED -> IN_PROGRESS -> HANDED_OFF'; check $? 0 "recusa mostra o caminho legal"
N0=$(git -C "$D" rev-list --count HEAD)
$TS DW-0001 HANDED_OFF --commit >/dev/null; check $? 0 "caminho legal com --commit"
check $(( $(git -C "$D" rev-list --count HEAD) - N0 )) 2 "um commit por passo"
check "$(python3 -c 'import json,sys;print(json.load(open(sys.argv[1]))["state"])' "$D/.ai/tasks/DW-0001.json")" HANDED_OFF "estado final gravado"
git -C "$D" show HEAD~1:.ai/tasks/DW-0001.json > "$SB/a.json"; git -C "$D" show HEAD:.ai/tasks/DW-0001.json > "$SB/b.json"
python3 "$D/scripts/validate-task.py" --transition "$SB/a.json" "$SB/b.json"; check $? 0 "cada commit e transicao legal"
$TS DW-0001 NEW >/dev/null 2>&1; check $? 1 "sem caminho legal: recusa"
$TS DW-0001 HANDED_OFF >/dev/null; check $? 0 "ja no estado: no-op"

H="$SB/h.json"
python3 - "$H" "$(git -C "$D" rev-parse HEAD)" <<'EOF'
import json, sys
json.dump({"handoff_id": "DW-0001-0001", "task_id": "DW-0001", "kind": "delivery", "from_agent": "claude",
           "to_agent": "codex", "branch": "claude/DW-0001-x", "delivery_commit": sys.argv[2]}, open(sys.argv[1], "w"))
EOF
NR="python3 $D/scripts/new-review-task.py"
$NR "$H" DW-0002 >/dev/null; check $? 0 "gera tarefa de revisao"
(cd "$D" && python3 scripts/validate-task.py .ai/tasks/DW-0002.json >/dev/null); check $? 0 "tarefa de revisao valida"
check "$(python3 -c 'import json,sys;t=json.load(open(sys.argv[1]));print(t["owner"],t["role"],t["scope"]["allowed_paths"][0])' "$D/.ai/tasks/DW-0002.json")" "codex review .ai/handoffs/DW-0002/" "dono = to_agent, papel review, escopo so o canal"
$NR "$H" DW-0002 >/dev/null 2>&1; check $? 1 "nao sobrescreve tarefa existente"

printf '\n%d ok, %d falha(s)\n' "$PASS" "$FAIL"
[[ $FAIL -eq 0 ]]
