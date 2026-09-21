#!/usr/bin/env bash
# Cria um handoff novo, imutavel e sequenciado, em .ai/handoffs/<TASK_ID>/.
#
# uso: scripts/handoff.sh TASK_ID FROM_AGENT TO_AGENT KIND [REVIEWED_COMMIT]
#   TASK_ID     AIC-NNNN
#   FROM_AGENT  claude | codex
#   TO_AGENT    claude | codex | human
#   KIND        delivery | review | correction
#   REVIEWED_COMMIT  obrigatorio apenas para review
#
# saida: 0 criado, 1 falha operacional, 2 uso incorreto.
set -euo pipefail

die() { printf '%s\n' "$*" >&2; exit "${2:-1}"; }
usage() { die "uso: $0 TASK_ID FROM_AGENT TO_AGENT KIND [REVIEWED_COMMIT]" 2; }

[[ $# -ge 4 && $# -le 5 ]] || usage
TASK_ID=$1; FROM=$2; TO=$3; KIND=$4

# Allowlist. E o que impede TASK_ID de influenciar o caminho.
[[ $TASK_ID =~ ^AIC-[0-9]{4}$ ]] || die "TASK_ID invalido: $TASK_ID (esperado AIC-NNNN)" 2
[[ $FROM == claude || $FROM == codex ]] || die "FROM_AGENT invalido: $FROM" 2
[[ $TO == claude || $TO == codex || $TO == human ]] || die "TO_AGENT invalido: $TO" 2
[[ $FROM != "$TO" ]] || die "FROM_AGENT e TO_AGENT nao podem ser iguais" 2
[[ $KIND == delivery || $KIND == review || $KIND == correction ]] || die "KIND invalido: $KIND" 2
if [[ $KIND == review ]]; then [[ $# -eq 5 ]] || usage
else [[ $# -eq 4 ]] || usage; fi

ROOT=$(git rev-parse --show-toplevel) || die "fora de um repositorio git" 1
cd "$ROOT"

BRANCH=$(git rev-parse --abbrev-ref HEAD)
[[ $BRANCH != HEAD ]] || die "HEAD destacado: faca checkout da branch da tarefa antes do handoff" 1
if [[ $KIND == review ]]; then
  DELIVERY_COMMIT=$(git rev-parse --verify "$5^{commit}" 2>/dev/null) || die "REVIEWED_COMMIT nao resolve para um commit: $5" 1
else
  DELIVERY_COMMIT=$(git rev-parse HEAD)
fi
if ! BASE_COMMIT=$(git merge-base main "$DELIVERY_COMMIT" 2>/dev/null); then
  die "nao foi possivel derivar base_commit: branch de coordenacao 'main' ausente" 1
fi

# .ai, .ai/handoffs e .ai/handoffs/<TASK_ID> tem de ser diretorios reais, nunca symlinks:
# um symlink em qualquer nivel reintroduziria a escrita fora da arvore que a allowlist fechou.
ROOT=$(pwd -P)
for d in .ai .ai/handoffs ".ai/handoffs/$TASK_ID"; do
  [[ ! -L $d ]] || die "$d e um symlink; recusando" 1
  mkdir -p "$d"
  [[ -d $d && ! -L $d ]] || die "$d nao e um diretorio real" 1
done
DIR=".ai/handoffs/$TASK_ID"
# ponytail: checagem-e-uso (TOCTOU) contra quem troca um diretorio por symlink entre a
# checagem e a escrita. Fora do modelo de ameaca do MVP (exige escrita local no repo).
[[ $(cd "$DIR" && pwd -P) == "$ROOT/$DIR" ]] || die "$DIR resolve para fora do repositorio; recusando" 1

# Exclusao mutua por tarefa. A unicidade da sequencia NAO pode depender do nome do arquivo:
# claude e codex geram 0001-claude.json e 0001-codex.json, nomes distintos que o ln(2) aceita.
# mkdir e atomico; quem nao consegue o lock falha em vez de esperar.
LOCK="$DIR/.lock"
mkdir "$LOCK" 2>/dev/null || die "outro processo esta criando handoff em $DIR (ou um lock morto em $LOCK; se nenhum processo estiver rodando, remova-o com rmdir)" 1
TMP=
cleanup() { [[ -n $TMP ]] && rm -f "$TMP"; rmdir "$LOCK" 2>/dev/null || true; }
trap cleanup EXIT

# Sequencia = maior existente + 1, calculada COM o lock: e ele que garante unicidade.
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
BRANCH_J=$(python3 -c 'import json,sys;print(json.dumps(sys.argv[1]))' "$BRANCH")

FINDINGS=""
[[ $KIND == review ]] && FINDINGS='
  "findings": [
    {"severity": "medium", "path": "<caminho>", "line": null, "finding": "<TODO achado>"}
  ],'

TMP=$(mktemp "$DIR/.tmp.XXXXXXXX")
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
  "branch": $BRANCH_J,
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

# ln(2) e atomico e falha com EEXIST: defesa em profundidade contra sobrescrita,
# inclusive contra symlink no destino. O lock acima ja serializa a criacao.
if ! ln "$TMP" "$OUT" 2>/dev/null; then
  die "ja existe um handoff em $OUT; handoffs sao imutaveis, gere a proxima sequencia" 1
fi

printf '%s\n' "$OUT"
printf 'preencha os campos <TODO> e valide com: scripts/validate-handoff.py %s\n' "$OUT" >&2
