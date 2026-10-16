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
# anotacao humana na tabela sobrevive a regeracao (regressao: o gerador apagava a coluna manual)
python3 - "$SB/ESTADO.md" <<'PY'
import sys
p = sys.argv[1]
out = []
for line in open(p, encoding="utf-8").read().split("\n"):
    if line.startswith("| AIC-0001 |"):
        line = " | ".join(line.split(" | ", 4)[:4]) + " | merge 1d5abf9 \\| parecer ACEITAR |"
    out.append(line)
open(p, "w", encoding="utf-8").write("\n".join(out))
PY
python3 "$SB/scripts/estado.py"
check "anotacao humana preservada ao regerar" "grep -qF '| merge 1d5abf9 \\| parecer ACEITAR |' $SB/ESTADO.md"
check "anotacao nao altera JSON: --check segue passando" "python3 $SB/scripts/estado.py --check"
python3 -c 'import json,sys;p=sys.argv[1];d=json.load(open(p));d["state"]="CLOSED";json.dump(d,open(p,"w"))' "$SB/.ai/tasks/AIC-0001.json"
python3 "$SB/scripts/estado.py"
check "estado vem do JSON, nota continua" "grep -qF '| AIC-0001 | claude | **CLOSED**' $SB/ESTADO.md && grep -qF 'merge 1d5abf9' $SB/ESTADO.md"
sed -i 's/merge 1d5abf9 \\| parecer ACEITAR/merge 1d5abf9 | parecer cru/' "$SB/ESTADO.md"
python3 "$SB/scripts/estado.py"
check "nota com | cru nao some ao regerar" "grep -qF 'merge 1d5abf9 \\| parecer cru |' $SB/ESTADO.md"
rm -f "$SB/.ai/tasks/AIC-0001.json"
check "nota de tarefa sem JSON nao e apagada em silencio" "! python3 $SB/scripts/estado.py"
grep -v 'tarefas:inicio' "$SB/ESTADO.md" > "$SB/x" && mv "$SB/x" "$SB/ESTADO.md"
check "sem marcador -> falha" "! python3 $SB/scripts/estado.py --check"

# robustez: entrada ruim da erro claro (exit != 0, sem traceback) e nao toca o ESTADO.md
RB=$(mktemp -d); trap 'rm -rf "$SB" "$RB"' EXIT
mkdir -p "$RB/scripts" "$RB/.ai"; cp scripts/estado.py scripts/task-state.py scripts/validate-task.py "$RB/scripts/"
cp -r .ai/tasks "$RB/.ai/"; cp ESTADO.md "$RB/"
fresh() { rm -rf "$RB/.ai/tasks"; cp -r .ai/tasks "$RB/.ai/"; cp ESTADO.md "$RB/"; }
clean_err() { # $1=comando que deve falhar, $2=trecho esperado na mensagem, sem Traceback
  local out; out=$(eval "$1" 2>&1); local rc=$?
  [[ $rc -ne 0 && $out == *"$2"* && $out != *Traceback* ]]
}
E="python3 $RB/scripts/estado.py"
echo '{bad' > "$RB/.ai/tasks/AIC-0099.json"
check "JSON malformado -> erro claro" "clean_err '$E --check' 'AIC-0099.json: JSON invalido'"
echo '[1]' > "$RB/.ai/tasks/AIC-0099.json"
check "JSON que nao e objeto -> erro claro" "clean_err '$E --check' 'esperado objeto JSON'"
echo '{"task_id":"AIC-0099"}' > "$RB/.ai/tasks/AIC-0099.json"
check "campo obrigatorio ausente -> erro claro" "clean_err '$E --check' \"campo 'title' ausente\""
fresh; cp "$RB/.ai/tasks/AIC-0001.json" "$RB/.ai/tasks/AIC-0099.json"
check "task_id repetido -> erro claro" "clean_err '$E --check' 'task_id AIC-0001 repetido'"
fresh; python3 -c 'import json,sys;p=sys.argv[1];d=json.load(open(p));d["title"]="a | b\nc";json.dump(d,open(p,"w"))' "$RB/.ai/tasks/AIC-0001.json"
$E
check "titulo com | e quebra de linha nao quebra a tabela" "grep -qF '| a \\| b c |' $RB/ESTADO.md && $E --check"
fresh; mv "$RB/ESTADO.md" "$RB/x"
check "ESTADO.md ausente -> erro claro" "clean_err '$E --check' 'nao consegui ler'"
fresh; rm -rf "$RB/.ai/tasks"
check "diretorio de tarefas ausente -> erro claro" "clean_err '$E --check' 'diretorio de tarefas ausente'"
fresh; echo '[1]' > "$RB/.ai/tasks/AIC-0099.json"
check "task-state com JSON nao-objeto -> erro claro, arquivo intacto" "clean_err 'python3 $RB/scripts/task-state.py AIC-0099 CLOSED' 'tarefa invalida' && [[ \$(cat $RB/.ai/tasks/AIC-0099.json) == '[1]' ]]"
check "task-state com tarefa inexistente -> erro claro" "clean_err 'python3 $RB/scripts/task-state.py AIC-0098 CLOSED' 'arquivo nao encontrado'"

printf '%d passou, %d falhou\n' "$PASS" "$FAIL"
[[ $FAIL -eq 0 ]]
