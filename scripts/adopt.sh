#!/usr/bin/env bash
# Instala ou atualiza o protocolo ai-coop em outro repositorio Git.
#
# uso: scripts/adopt.sh DESTINO           instala/atualiza a partir do HEAD deste repo
#      scripts/adopt.sh --check DESTINO   so compara; sai 1 se o destino esta desatualizado
#
# Copia a versao COMMITADA (HEAD), nunca a arvore suja, e grava PROTOCOL-VERSION.
# Nunca toca .ai/tasks/, .ai/handoffs/, .ai/knowledge/ nem .ai/DECISIONS.md existentes:
# isso e estado do repo de destino, nao protocolo.
set -euo pipefail

die() { printf '%s\n' "$1" >&2; exit "${2:-1}"; }

CHECK=0
if [[ ${1:-} == --check ]]; then CHECK=1; shift; fi
[[ $# -eq 1 ]] || die "uso: $0 [--check] DESTINO" 2

SRC=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
DEST=$(cd "$1" 2>/dev/null && git rev-parse --show-toplevel 2>/dev/null) || die "DESTINO nao e um repositorio Git: $1" 2
[[ $DEST != "$(git -C "$SRC" rev-parse --show-toplevel)" ]] || die "DESTINO e o proprio ai-coop" 2
REF=$(git -C "$SRC" rev-parse HEAD)

# Lista minima: o que handoff.sh, os validadores, o doctor e as skills exigem.
FILES=(
  AGENTS.md
  .agents/skills/ai-coop/SKILL.md
  .agents/skills/ai-handoff/SKILL.md
  .agents/skills/ai-handoff/agents/openai.yaml
  .claude/skills/ai-coop/SKILL.md
  .claude/skills/ai-handoff/SKILL.md
  .ai/schemas/task.schema.json
  .ai/schemas/handoff.schema.json
  docs/AI-HANDOFF.md
  docs/SPEC-v0.1.md
  docs/MERGE-GUARD.md
  .githooks/pre-merge-commit
  .githooks/pre-push
  .githooks/reference-transaction
  scripts/adopt.sh
  scripts/ai-coop-doctor.sh
  scripts/handoff.sh
  scripts/install-hooks.sh
  scripts/new-review-task.py
  scripts/rodar-codex.sh
  scripts/task-state.py
  scripts/validate-handoff.py
  scripts/validate-task.py
)

# AGENTS.md do destino so e sobrescrito se ja for o do protocolo (ou nao existir).
if [[ -f $DEST/AGENTS.md ]] && ! head -1 "$DEST/AGENTS.md" | grep -q '^# Agent Cooperation Protocol'; then
  die "DESTINO/AGENTS.md existe e nao e o do ai-coop; junte as regras a mao antes de adotar" 1
fi

# nenhum caminho que vamos escrever pode passar por symlink: o redirecionamento seguiria e sobrescreveria fora do destino
for f in "${FILES[@]}" PROTOCOL-VERSION .gitignore .ai .ai/DECISIONS.md .ai/tasks .ai/handoffs .ai/knowledge; do
  p=$DEST
  IFS=/ read -ra parts <<<"$f"
  for part in "${parts[@]}"; do
    p=$p/$part
    [[ -L $p ]] && die "$p e symlink; remova ou troque por arquivo real antes de adotar" 1
  done
done

stale=()
for f in "${FILES[@]}"; do
  if ! git -C "$SRC" show "$REF:$f" | cmp -s - "$DEST/$f" 2>/dev/null; then stale+=("$f"); fi
done
current=$(cat "$DEST/PROTOCOL-VERSION" 2>/dev/null || true)

if (( CHECK )); then
  printf 'destino: %s\nversao do destino: %s\nversao daqui:      ai-coop %s\n' "$DEST" "${current:-(nenhuma)}" "$REF"
  if (( ${#stale[@]} )); then printf 'DESATUALIZADO %s\n' "${stale[@]}"; exit 1; fi
  printf 'OK todos os %d arquivos do protocolo iguais\n' "${#FILES[@]}"
  exit 0
fi

for f in "${stale[@]}"; do
  mkdir -p "$DEST/$(dirname "$f")"
  git -C "$SRC" show "$REF:$f" > "$DEST/$f"
  [[ $(git -C "$SRC" ls-files -s "$f" | cut -c1-6) == 100755 ]] && chmod +x "$DEST/$f" || chmod -x "$DEST/$f"
done
mkdir -p "$DEST/.ai/tasks" "$DEST/.ai/handoffs" "$DEST/.ai/knowledge"
[[ -e $DEST/.ai/DECISIONS.md ]] || printf '# Decisoes\n' > "$DEST/.ai/DECISIONS.md"
printf 'ai-coop %s\n' "$REF" > "$DEST/PROTOCOL-VERSION"
# .gitignore sem quebra de linha no fim: sem isto a primeira regra nova gruda na ultima existente
[[ -s $DEST/.gitignore && -n $(tail -c1 "$DEST/.gitignore") ]] && printf '\n' >> "$DEST/.gitignore"
for line in '.ai/private/' '.env' '.env.*'; do
  grep -qxF "$line" "$DEST/.gitignore" 2>/dev/null || printf '%s\n' "$line" >> "$DEST/.gitignore"
done

printf 'ai-coop %s instalado em %s (%d arquivo(s) novo(s) ou atualizado(s))\n' "${REF:0:7}" "$DEST" "${#stale[@]}"
printf 'proximo: revisar com git -C %s status, commitar como coord:, e usar um prefixo proprio de tarefa (ex. DW-0001)\n' "$DEST"
