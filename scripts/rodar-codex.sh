#!/usr/bin/env bash
# Roda o Codex numa tarefa em PRIMEIRO PLANO e, ao sair, diz o que ficou: codigo de saida,
# commits novos, arvore suja e o ultimo handoff da tarefa (validado). Rode como comando em
# segundo plano do Claude Code (run_in_background): o aviso de termino passa a ser o do
# Codex de verdade, nao o de um shell lancador (nohup ... & avisa cedo demais).
#
# uso: scripts/rodar-codex.sh TASK_ID PROMPT_FILE [WORKTREE]
#   CODEX_SANDBOX=workspace-write (padrao) | danger-full-access (Chrome/Git em worktree)
#   saida: 0 handoff valido e arvore limpa; 3 terminou sem handoff valido; 4 arvore suja;
#          outro = codigo do codex
set -uo pipefail
[[ $# -ge 2 ]] || { echo "uso: $0 TASK_ID PROMPT_FILE [WORKTREE]" >&2; exit 2; }
TASK=$1; PROMPT=$2; WT=${3:-$PWD}; SANDBOX=${CODEX_SANDBOX:-workspace-write}
[[ $TASK =~ ^[A-Z][A-Z0-9]{1,7}-[0-9]{4}$ ]] || { echo "TASK_ID invalido: $TASK" >&2; exit 2; }
WT=$(cd "$WT" && pwd) || exit 2; LOG=/tmp/codex-$TASK-$(date +%s).log
BASE=$(git -C "$WT" rev-parse HEAD)

codex exec --sandbox "$SANDBOX" -C "$WT" - < "$PROMPT" > "$LOG" 2>&1; rc=$?

echo "== codex $TASK terminou: rc=$rc sandbox=$SANDBOX log=$LOG"
echo "-- commits novos:"; git -C "$WT" log --oneline "$BASE"..HEAD
sujo=$(git -C "$WT" status --porcelain | grep -v '^?? scripts/__pycache__' || true)
[[ -z $sujo ]] || { echo "-- ARVORE SUJA (commit nao feito?):"; echo "$sujo" | head; }
ultimo=$(ls "$WT/.ai/handoffs/$TASK/"*.json 2>/dev/null | tail -1)
if [[ -n $ultimo ]]; then
  echo "-- ultimo handoff: ${ultimo#$WT/}"; python3 "$WT/scripts/validate-handoff.py" "$ultimo" | tail -1
else echo "-- NENHUM handoff em .ai/handoffs/$TASK/"; fi
echo "-- fim do relato do codex:"; tail -n 12 "$LOG"
[[ $rc -eq 0 ]] || exit "$rc"
[[ -z $sujo ]] || exit 4
[[ -n $ultimo ]] && python3 "$WT/scripts/validate-handoff.py" "$ultimo" >/dev/null || exit 3
