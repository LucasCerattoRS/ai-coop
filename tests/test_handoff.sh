#!/usr/bin/env bash
# Teste do criador e do validador de handoff. Sem framework: bash + python3.
# uso: tests/test_handoff.sh   ->  0 tudo passou, 1 alguma falha
set -uo pipefail

SRC=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
PASS=0; FAIL=0

ok()   { printf 'ok   %s\n' "$1"; PASS=$((PASS+1)); }
bad()  { printf 'FALHA %s\n' "$1"; FAIL=$((FAIL+1)); }
check(){ if [[ $1 == "$2" ]]; then ok "$3"; else bad "$3 (esperado '$2', obtido '$1')"; fi; }

SANDBOX=$(mktemp -d)
trap 'rm -rf "$SANDBOX"' EXIT

# repositorio de teste com branch de coordenacao main e uma branch de tarefa
cd "$SANDBOX"
git init -q -b main .
git config user.email t@t; git config user.name t
mkdir -p scripts .ai/schemas
cp "$SRC/scripts/handoff.sh" "$SRC/scripts/validate-handoff.py" scripts/
echo base > base.txt
git add -A >/dev/null; git commit -qm base
git checkout -qb claude/AIC-0001-x
echo work > work.txt; git add -A >/dev/null; git commit -qm work

H=scripts/handoff.sh
V=scripts/validate-handoff.py

# --- uso incorreto e IDs inseguros -------------------------------------------
bash $H AIC-0001 claude >/dev/null 2>&1; check $? 2 "poucos argumentos -> 2"
bash $H "" claude codex delivery >/dev/null 2>&1; check $? 2 "TASK_ID vazio -> 2"
bash $H "../../../tmp/evil" claude codex delivery >/dev/null 2>&1; check $? 2 "TASK_ID com ../ -> 2"
bash $H "AIC-0001/../../etc" claude codex delivery >/dev/null 2>&1; check $? 2 "TASK_ID com barra -> 2"
bash $H "AIC-1" claude codex delivery >/dev/null 2>&1; check $? 2 "TASK_ID curto demais -> 2"
bash $H AIC-0001 claude claude delivery >/dev/null 2>&1; check $? 2 "from == to -> 2"
bash $H AIC-0001 claude gemini delivery >/dev/null 2>&1; check $? 2 "agente desconhecido -> 2"
bash $H AIC-0001 claude codex merge >/dev/null 2>&1; check $? 2 "kind desconhecido -> 2"

ESCAPED=$(find "$SANDBOX" -name '*evil*' -o -name 'etc' -type d 2>/dev/null | wc -l)
check "$ESCAPED" 0 "nenhum arquivo criado fora de .ai/handoffs"

# --- caminho feliz ------------------------------------------------------------
OUT1=$(bash $H AIC-0001 claude codex delivery 2>/dev/null)
check "$OUT1" ".ai/handoffs/AIC-0001/0001-claude.json" "primeiro handoff nomeado por sequencia"
python3 -c "import json;json.load(open('$OUT1'))" 2>/dev/null; check $? 0 "handoff gerado e JSON valido"
python3 -c "
import json;d=json.load(open('$OUT1'))
assert d['previous_handoff'] is None and d['sequence']==1, d
assert len(d['base_commit'])==40 and len(d['delivery_commit'])==40, d
assert d['base_commit']!=d['delivery_commit'], 'base deve ser o merge-base, nao HEAD'
" 2>/dev/null; check $? 0 "git state capturado: seq 1, previous null, base != delivery"

# esqueleto com placeholders tem de ser recusado pelo validador
python3 $V "$OUT1" >/dev/null 2>&1; check $? 1 "esqueleto com <TODO> e recusado"

# --- imutabilidade e atomicidade ---------------------------------------------
# reexecutar avanca a sequencia, nunca sobrescreve
OUT2=$(bash $H AIC-0001 codex claude review 2>/dev/null)
check "$OUT2" ".ai/handoffs/AIC-0001/0002-codex.json" "segundo handoff avanca a sequencia"
python3 -c "
import json;d=json.load(open('$OUT2'))
assert d['previous_handoff']=='0001-claude.json', d
assert d['sequence']==2 and d['kind']=='review' and 'findings' in d, d
" 2>/dev/null; check $? 0 "segundo handoff encadeia o anterior e review traz findings"

# terceiro fecha o ciclo Claude -> Codex -> Claude
OUT3=$(bash $H AIC-0001 claude codex correction 2>/dev/null)
check "$OUT3" ".ai/handoffs/AIC-0001/0003-claude.json" "ciclo claude->codex->claude preservado"

# escrita concorrente na MESMA sequencia: exatamente um vencedor
mkdir -p .ai/handoffs/AIC-0009
CREATED=0; FAILED=0
for i in 1 2 3 4 5 6 7 8; do
  ( bash $H AIC-0009 claude codex delivery >"$SANDBOX/r.$i" 2>/dev/null; echo $? > "$SANDBOX/c.$i" ) &
done
wait
for i in 1 2 3 4 5 6 7 8; do
  [[ $(cat "$SANDBOX/c.$i") == 0 ]] && CREATED=$((CREATED+1)) || FAILED=$((FAILED+1))
done
FILES=$(ls .ai/handoffs/AIC-0009/*.json 2>/dev/null | wc -l)
TMPS=$(ls .ai/handoffs/AIC-0009/.tmp.* 2>/dev/null | wc -l)
if [[ $FILES -eq $CREATED && $CREATED -ge 1 && $FAILED -ge 1 ]]; then
  ok "8 criacoes simultaneas: $CREATED criados == $FILES arquivos, $FAILED recusados"
else
  bad "corrida: $CREATED sucessos, $FILES arquivos, $FAILED falhas"
fi
check "$TMPS" 0 "nenhum arquivo temporario deixado para tras"
BAD=0
for f in .ai/handoffs/AIC-0009/*.json; do python3 -c "import json,sys;json.load(open(sys.argv[1]))" "$f" 2>/dev/null || BAD=1; done
check "$BAD" 0 "nenhum handoff parcialmente escrito apos a corrida"

# symlink no lugar do diretorio de handoffs e recusado
mkdir -p "$SANDBOX/outside"
rm -rf .ai/handoffs/AIC-0007
ln -s "$SANDBOX/outside" .ai/handoffs/AIC-0007
bash $H AIC-0007 claude codex delivery >/dev/null 2>&1; check $? 1 "diretorio de handoff via symlink -> recusa"
check "$(ls "$SANDBOX/outside" | wc -l)" 0 "symlink nao permitiu escrita fora da arvore"

# --- validador ----------------------------------------------------------------
mk() { python3 -c "
import json,sys
d=json.load(open('$OUT1'))
d.update({'summary':'entrega real','next_action':'revisar o commit',
 'changes':[{'path':'scripts/handoff.sh','what':'criacao segura'}],
 'tests':[{'command':'tests/test_handoff.sh','result':'pass'}]})
patch=json.loads(sys.argv[1])
for k,v in patch.items():
    if v is None and k.startswith('-'): d.pop(k[1:],None)
    else: d[k]=v
json.dump(d,open(sys.argv[2],'w'))
" "$1" "$2"; }

mk '{}' good.json
python3 $V good.json >/dev/null 2>&1; check $? 0 "handoff completo e valido"

mk '{"-base_commit":null}' m1.json
python3 $V m1.json >/dev/null 2>&1; check $? 1 "sem base_commit -> invalido"
mk '{"-delivery_commit":null}' m2.json
python3 $V m2.json >/dev/null 2>&1; check $? 1 "sem delivery_commit -> invalido"
mk '{"-sequence":null}' m3.json
python3 $V m3.json >/dev/null 2>&1; check $? 1 "sem sequence -> invalido"
mk '{"-previous_handoff":null}' m4.json
python3 $V m4.json >/dev/null 2>&1; check $? 1 "sem previous_handoff -> invalido"
mk '{"summary":"   "}' m5.json
python3 $V m5.json >/dev/null 2>&1; check $? 1 "summary em branco -> invalido"
mk '{"delivery_commit":"abc123"}' m6.json
python3 $V m6.json >/dev/null 2>&1; check $? 1 "commit que nao e SHA-1 completo -> invalido"
mk '{"changes":[]}' m7.json
python3 $V m7.json >/dev/null 2>&1; check $? 1 "changes vazio -> invalido"
mk '{"tests":[]}' m8.json
python3 $V m8.json >/dev/null 2>&1; check $? 1 "tests vazio -> invalido"
mk '{"sequence":2,"handoff_id":"AIC-0001-0002"}' m9.json
python3 $V m9.json >/dev/null 2>&1; check $? 1 "sequence 2 com previous null -> invalido"
mk '{"sequence":3,"handoff_id":"AIC-0001-0003","previous_handoff":"0001-claude.json"}' m10.json
python3 $V m10.json >/dev/null 2>&1; check $? 1 "previous pulando uma sequencia -> invalido"
mk '{"handoff_id":"AIC-0002-0001"}' m11.json
python3 $V m11.json >/dev/null 2>&1; check $? 1 "handoff_id de outra tarefa -> invalido"
mk '{"kind":"review"}' m12.json
python3 $V m12.json >/dev/null 2>&1; check $? 1 "review sem findings -> invalido"
mk '{"findings":[{"severity":"low","path":"x","finding":"y"}]}' m13.json
python3 $V m13.json >/dev/null 2>&1; check $? 1 "findings fora de kind=review -> invalido"
mk '{"to_agent":"claude"}' m14.json
python3 $V m14.json >/dev/null 2>&1; check $? 1 "from_agent igual a to_agent -> invalido"
mk '{"extra_field":1}' m15.json
python3 $V m15.json >/dev/null 2>&1; check $? 1 "campo nao previsto -> invalido"
echo 'nao sou json' > m16.json
python3 $V m16.json >/dev/null 2>&1; check $? 1 "arquivo nao-JSON -> invalido"
python3 $V nao-existe.json >/dev/null 2>&1; check $? 2 "arquivo ausente -> uso incorreto"
python3 $V >/dev/null 2>&1; check $? 2 "validador sem argumento -> uso incorreto"

printf '\n%d passaram, %d falharam\n' "$PASS" "$FAIL"
[[ $FAIL -eq 0 ]]
