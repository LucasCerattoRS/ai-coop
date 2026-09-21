#!/usr/bin/env bash
# Cria um handoff novo, imutavel e sequenciado, em .ai/handoffs/<TASK_ID>/.
#
# uso: scripts/handoff.sh TASK_ID FROM_AGENT TO_AGENT KIND
#   TASK_ID     AIC-NNNN
#   FROM_AGENT  claude | codex
#   TO_AGENT    claude | codex | human
#   KIND        delivery | review | correction
#
# saida: 0 criado, 1 falha operacional, 2 uso incorreto.
set -euo pipefail

die() { printf '%s\n' "$*" >&2; exit "${2:-1}"; }
usage() { die "uso: $0 TASK_ID FROM_AGENT TO_AGENT KIND" 2; }

[[ $# -eq 4 ]] || usage
TASK_ID=$1; FROM=$2; TO=$3; KIND=$4

# Allowlist. E o que impede TASK_ID de influenciar o caminho.
[[ $TASK_ID =~ ^AIC-[0-9]{4}$ ]] || die "TASK_ID invalido: $TASK_ID (esperado AIC-NNNN)" 2
[[ $FROM == claude || $FROM == codex ]] || die "FROM_AGENT invalido: $FROM" 2
[[ $TO == claude || $TO == codex || $TO == human ]] || die "TO_AGENT invalido: $TO" 2
[[ $FROM != "$TO" ]] || die "FROM_AGENT e TO_AGENT nao podem ser iguais" 2
[[ $KIND == delivery || $KIND == review || $KIND == correction ]] || die "KIND invalido: $KIND" 2

ROOT=$(git rev-parse --show-toplevel) || die "fora de um repositorio git" 1
cd "$ROOT"

BRANCH=$(git rev-parse --abbrev-ref HEAD)
[[ $BRANCH != HEAD ]] || die "HEAD destacado: faca checkout da branch da tarefa antes do handoff" 1
DELIVERY_COMMIT=$(git rev-parse HEAD)
if ! BASE_COMMIT=$(git merge-base main HEAD 2>/dev/null); then
  die "nao foi possivel derivar base_commit: branch de coordenacao 'main' ausente" 1
fi

# .ai/handoffs e .ai/handoffs/<TASK_ID> tem de ser diretorios reais, nunca symlinks:
# um symlink aqui reintroduziria a escrita fora da arvore que a allowlist acabou de fechar.
for d in .ai/handoffs ".ai/handoffs/$TASK_ID"; do
  [[ ! -L $d ]] || die "$d e um symlink; recusando" 1
  mkdir -p "$d"
  [[ -d $d && ! -L $d ]] || die "$d nao e um diretorio real" 1
done
DIR=".ai/handoffs/$TASK_ID"

# Sequencia = maior existente + 1. Vale como sugestao; quem garante unicidade e o O_EXCL abaixo.
SEQ=1
for f in "$DIR"/[0-9][0-9][0-9][0-9]-*.json; do
  [[ -e $f ]] || continue
  n=$(basename "$f"); n=${n%%-*}; n=$((10#$n))
  (( n >= SEQ )) && SEQ=$((n + 1))
done
PREV=null
if (( SEQ > 1 )); then
  p=$(printf '%04d' $((SEQ - 1)))
  for f in "$DIR/$p"-*.json; do
    [[ -e $f ]] && PREV="\"$(basename "$f")\""
  done
  [[ $PREV != null ]] || die "sequencia $SEQ sem handoff anterior $p-*.json; historico quebrado" 1
fi

OUT="$DIR/$(printf '%04d' "$SEQ")-$FROM.json"
HANDOFF_ID="$TASK_ID-$(printf '%04d' "$SEQ")"
CREATED_AT=$(date -u +%Y-%m-%dT%H:%M:%SZ)

FINDINGS=""
[[ $KIND == review ]] && FINDINGS='
  "findings": [
    {"severity": "medium", "path": "<caminho>", "line": null, "finding": "<TODO achado>"}
  ],'

TMP=$(mktemp "$DIR/.tmp.XXXXXXXX")
trap 'rm -f "$TMP"' EXIT
cat > "$TMP" <<JSON
{
  "schema_version": 1,
  "handoff_id": "$HANDOFF_ID",
  "task_id": "$TASK_ID",
  "sequence": $SEQ,
  "from_agent": "$FROM",
  "to_agent": "$TO",
  "kind": "$KIND",
  "created_at": "$CREATED_AT",
  "branch": "$BRANCH",
  "base_commit": "$BASE_COMMIT",
  "delivery_commit": "$DELIVERY_COMMIT",
  "summary": "<TODO uma frase: o que foi entregue>",
  "changes": [
    {"path": "<caminho>", "what": "<TODO o que mudou>"}
  ],
  "tests": [
    {"command": "<TODO comando executado>", "result": "not_run", "note": "<TODO>"}
  ],
  "risks": [],$FINDINGS
  "next_action": "<TODO acao exata para quem recebe>",
  "previous_handoff": $PREV
}
JSON

# ln(2) e atomico e falha com EEXIST: duas execucoes simultaneas produzem
# exatamente um arquivo criado e uma falha. Vence tambem contra symlink no destino.
if ! ln "$TMP" "$OUT" 2>/dev/null; then
  die "ja existe um handoff em $OUT; handoffs sao imutaveis, gere a proxima sequencia" 1
fi
rm -f "$TMP"; trap - EXIT

printf '%s\n' "$OUT"
printf 'preencha os campos <TODO> e valide com: scripts/validate-handoff.py %s\n' "$OUT" >&2
