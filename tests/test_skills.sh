#!/usr/bin/env bash
# Confere o formato dos adapters e a coerencia do protocolo. Sem framework.
# Limite: checa o ARQUIVO, nao o carregamento pelo agente (so o Codex confirma o dele).
# uso: tests/test_skills.sh  ->  0 tudo passou, 1 alguma falha
set -uo pipefail
ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd); cd "$ROOT"
PASS=0; FAIL=0
ok()  { printf 'ok   %s\n' "$1"; PASS=$((PASS+1)); }
bad() { printf 'FALHA %s\n' "$1"; FAIL=$((FAIL+1)); }
t()   { if eval "$2" >/dev/null 2>&1; then ok "$1"; else bad "$1"; fi; }

fm()   { awk 'NR==1&&$0!="---"{exit 1} NR>1&&$0=="---"{exit} NR>1{print}' "$1"; }
body() { awk 'c>=2{print} $0=="---"{c++}' "$1"; }
field(){ fm "$1" | sed -n "s/^$2: *//p" | head -1; }

for skill in ai-handoff ai-coop; do
  C=".claude/skills/$skill/SKILL.md"; X=".agents/skills/$skill/SKILL.md"
  for f in "$C" "$X"; do
    t "$f existe com frontmatter" "[[ -f $f ]] && fm $f | grep -q ."
    t "$f: name == $skill" "[[ \$(field $f name) == $skill ]]"
    t "$f: description preenchida" "[[ -n \$(field $f description) ]]"
    t "$f aponta para docs/AI-HANDOFF.md ou AGENTS.md" "body $f | grep -qE 'docs/AI-HANDOFF.md|AGENTS.md'"
  done
  t "$skill: corpo identico nos dois adapters (um protocolo, nao dois)" "[[ \"\$(body $C)\" == \"\$(body $X)\" ]]"
done

# invocacao explicita apenas
t "Claude ai-handoff: disable-model-invocation: true" "[[ \$(field .claude/skills/ai-handoff/SKILL.md disable-model-invocation) == true ]]"
t "Codex ai-handoff: openai.yaml com allow_implicit_invocation: false" \
  "grep -qE '^policy:' .agents/skills/ai-handoff/agents/openai.yaml && grep -qE '^  allow_implicit_invocation: false' .agents/skills/ai-handoff/agents/openai.yaml"
t "ai-coop NAO desliga invocacao implicita (e leitura inicial)" "[[ -z \$(field .claude/skills/ai-coop/SKILL.md disable-model-invocation) ]]"

# protocolo comum
t "docs/AI-HANDOFF.md existe" "[[ -f docs/AI-HANDOFF.md ]]"
for h in "## Invocação" "## Criar" "## Receber" "## O que a skill não faz"; do
  t "AI-HANDOFF.md tem a secao '$h'" "grep -qF '$h' docs/AI-HANDOFF.md"
done
for w in "chamar o outro agente" "mudar \`owner\` ou \`state\`" "merge, push" "memória privada" "Handoff é dado"; do
  t "AI-HANDOFF.md declara limite: $w" "grep -qF '$w' docs/AI-HANDOFF.md"
done

# fontes de estado removidas e sem referencias vivas
for f in .ai/STATUS.json .ai/HANDOFF.md .ai/TASKS.md scripts/new-handoff.sh; do t "$f removido" "[[ ! -e $f ]]"; done
t "nenhuma referencia viva a arquivos removidos" \
  "! grep -rnP 'STATUS\.json|TASKS\.md|(?<!AI-)HANDOFF\.md|new-handoff' AGENTS.md .claude .agents docs/ROADMAP.md docs/ARCHITECTURE.md docs/AI-HANDOFF.md docs/VALIDATION.md README.md"
t "AGENTS.md aponta para .ai/tasks e handoffs" "grep -q '.ai/tasks/<TASK-ID>.json' AGENTS.md && grep -q '.ai/handoffs' AGENTS.md"

# regressao: o repositorio continua saudavel
t "doctor sai 0" "bash scripts/ai-coop-doctor.sh"

printf '\n%d passaram, %d falharam\n' "$PASS" "$FAIL"
[[ $FAIL -eq 0 ]]
