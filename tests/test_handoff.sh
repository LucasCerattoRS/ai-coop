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
git config user.email Lukelucanolightknowledge@gmail.com; git config user.name LuKas
mkdir -p scripts .ai/schemas
cp "$SRC/scripts/handoff.sh" "$SRC/scripts/validate-handoff.py" scripts/
echo base > base.txt
git add -A >/dev/null; git commit -qm base
git checkout -qb claude/AIC-0001-x
echo work > work.txt; git add -A >/dev/null; git commit -qm work
TASK_HEAD=$(git rev-parse HEAD)
TASK_BASE=$(git merge-base main HEAD)
git checkout -q main
echo newer > main.txt; git add -A >/dev/null; git commit -qm main-advance
MAIN_HEAD=$(git rev-parse HEAD)
MAIN_SHORT=$(git rev-parse --short=12 main)
git checkout -q claude/AIC-0001-x

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
bash $H AIC-0011 codex human review >/dev/null 2>&1; check $? 2 "review sem commit -> 2"
[[ ! -e .ai/handoffs/AIC-0011 ]]; check $? 0 "review sem commit nao escreve"
bash $H AIC-0012 claude codex delivery main >/dev/null 2>&1; check $? 2 "delivery com quinto argumento -> 2"
[[ ! -e .ai/handoffs/AIC-0012 ]]; check $? 0 "delivery com quinto argumento nao escreve"
bash $H AIC-0013 claude codex correction main >/dev/null 2>&1; check $? 2 "correction com quinto argumento -> 2"
[[ ! -e .ai/handoffs/AIC-0013 ]]; check $? 0 "correction com quinto argumento nao escreve"
bash $H AIC-0014 codex human review inexistente-aic-0006 >/dev/null 2>&1; check $? 1 "review de commit inexistente -> 1"
[[ ! -e .ai/handoffs/AIC-0014 ]]; check $? 0 "review de commit inexistente nao escreve"

OUTR=$(bash $H AIC-0015 codex human review main 2>/dev/null)
python3 - "$OUTR" "$MAIN_HEAD" <<'PYX' 2>/dev/null; check $? 0 "review de branch grava commit revisado e sua base"
import json, sys
d = json.load(open(sys.argv[1]))
assert d['delivery_commit'] == d['base_commit'] == sys.argv[2]
PYX
OUTS=$(bash $H AIC-0016 codex human review "$MAIN_SHORT" 2>/dev/null)
python3 - "$OUTS" "$MAIN_HEAD" <<'PYX' 2>/dev/null; check $? 0 "review de SHA abreviado grava SHA completo"
import json, sys
d = json.load(open(sys.argv[1]))
assert d['delivery_commit'] == d['base_commit'] == sys.argv[2]
PYX

ESCAPED=$(find "$SANDBOX" -name '*evil*' -o -name 'etc' -type d 2>/dev/null | wc -l)
check "$ESCAPED" 0 "nenhum arquivo criado fora de .ai/handoffs"

# --- caminho feliz ------------------------------------------------------------
OUT1=$(bash $H AIC-0001 claude codex delivery 2>/dev/null)
check "$OUT1" ".ai/handoffs/AIC-0001/0001-claude.json" "primeiro handoff nomeado por sequencia"
python3 -c "import json;json.load(open('$OUT1'))" 2>/dev/null; check $? 0 "handoff gerado e JSON valido"
python3 -c "
import json;d=json.load(open('$OUT1'))
assert d['previous_handoff'] is None and d['sequence']==1, d
assert d['delivery_commit']=='$TASK_HEAD', d
assert d['base_commit']=='$TASK_BASE', d
" 2>/dev/null; check $? 0 "git state capturado: seq 1, previous null, base != delivery"

# esqueleto com placeholders tem de ser recusado pelo validador
python3 $V "$OUT1" >/dev/null 2>&1; check $? 1 "esqueleto com <TODO> e recusado"

# --- imutabilidade e atomicidade ---------------------------------------------
# reexecutar avanca a sequencia, nunca sobrescreve
OUT2=$(bash $H AIC-0001 codex claude review HEAD 2>/dev/null)
check "$OUT2" ".ai/handoffs/AIC-0001/0002-codex.json" "segundo handoff avanca a sequencia"
python3 -c "
import json;d=json.load(open('$OUT2'))
assert d['previous_handoff']=='0001-claude.json', d
assert d['sequence']==2 and d['kind']=='review' and 'findings' in d, d
" 2>/dev/null; check $? 0 "segundo handoff encadeia o anterior e review traz findings"

# terceiro fecha o ciclo Claude -> Codex -> Claude
OUT3=$(bash $H AIC-0001 claude codex correction 2>/dev/null)
check "$OUT3" ".ai/handoffs/AIC-0001/0003-claude.json" "ciclo claude->codex->claude preservado"

# escrita concorrente, agentes DIFERENTES, mesma tarefa.
# Propriedade: nenhuma sequencia se repete e a cadeia fica contigua e encadeada,
# qualquer que seja o entrelacamento. (Contar "1 vencedor" depende de temporizacao.)
mkdir -p .ai/handoffs/AIC-0009
for i in 1 2 3 4 5 6 7 8; do
  ag=claude; to=codex; (( i % 2 )) && { ag=codex; to=claude; }
  ( bash $H AIC-0009 $ag $to delivery >/dev/null 2>&1; echo $? > "$SANDBOX/c.$i" ) &
done
wait
CREATED=0
for i in 1 2 3 4 5 6 7 8; do [[ $(cat "$SANDBOX/c.$i") == 0 ]] && CREATED=$((CREATED+1)); done
FILES=$(ls .ai/handoffs/AIC-0009/[0-9]*.json 2>/dev/null | wc -l)
if [[ $CREATED -ge 1 && $CREATED -eq $FILES ]]; then ok "corrida 4 claude + 4 codex: $CREATED criados == $FILES arquivos"
else bad "corrida: $CREATED sucessos, $FILES arquivos"; fi
python3 - <<'PYX' 2>/dev/null; check $? 0 "sequencia contigua, sem repeticao entre agentes, cadeia integra"
import glob, json, os
fs = sorted(glob.glob('.ai/handoffs/AIC-0009/[0-9]*.json'))
for i, f in enumerate(fs, 1):
    d = json.load(open(f))
    assert d['sequence'] == i, (f, d['sequence'])
    assert d['previous_handoff'] == (None if i == 1 else os.path.basename(fs[i-2])), f
PYX
check "$(ls -A .ai/handoffs/AIC-0009 | grep -c '^\.')" 0 "sem .tmp nem .lock residuais apos a corrida"

# lock ocupado: recusa sem escrever; liberado: cria
mkdir -p .ai/handoffs/AIC-0010/.lock
bash $H AIC-0010 claude codex delivery >/dev/null 2>&1; check $? 1 "lock ocupado -> recusa"
check "$(ls .ai/handoffs/AIC-0010/*.json 2>/dev/null | wc -l)" 0 "lock ocupado nao escreveu nada"
rmdir .ai/handoffs/AIC-0010/.lock
bash $H AIC-0010 claude codex delivery >/dev/null 2>&1; check $? 0 "lock liberado -> cria"

# nome de branch com aspas nao pode quebrar o JSON
git checkout -qb 'claude/AIC-0005-"q"'
OUTQ=$(bash $H AIC-0005 claude codex delivery 2>/dev/null)
python3 -c 'import json,sys;assert json.load(open(sys.argv[1]))["branch"]==sys.argv[2]' "$OUTQ" 'claude/AIC-0005-"q"' 2>/dev/null
check $? 0 "branch com aspas gera JSON valido e fiel"
git checkout -q claude/AIC-0001-x

# .ai como symlink (nao so .ai/handoffs) nao pode levar a escrita para fora
mkdir -p "$SANDBOX/outside2" "$SANDBOX/s2"
( cd "$SANDBOX/s2" && git init -q -b main . && git config user.email Lukelucanolightknowledge@gmail.com && git config user.name LuKas \
  && echo x > x && git add -A >/dev/null && git commit -qm x && git checkout -qb claude/AIC-0001-y \
  && ln -s "$SANDBOX/outside2" .ai && bash "$SANDBOX/scripts/handoff.sh" AIC-0001 claude codex delivery >/dev/null 2>&1 )
check $? 1 ".ai como symlink -> recusa"
check "$(find "$SANDBOX/outside2" -type f | wc -l)" 0 ".ai symlink nao permitiu escrita fora do repositorio"

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
python3 -c "import json;d=json.load(open('$OUT1'));d['summary']='x real';d['next_action']='y real';json.dump(d,open('p1.json','w'))"
python3 $V p1.json >/dev/null 2>&1; check $? 1 "so summary/next_action preenchidos, resto <TODO> -> invalido"
mk '{"changes":[{"path":"<caminho>","what":"real"}]}' p2.json
python3 $V p2.json >/dev/null 2>&1; check $? 1 "placeholder em changes.path -> invalido"
mk '{"tests":[{"command":"<TODO comando>","result":"pass"}]}' p3.json
python3 $V p3.json >/dev/null 2>&1; check $? 1 "placeholder em tests.command -> invalido"
mk '{"tests":[{"command":"x","result":"not_run"}]}' p4.json
python3 $V p4.json >/dev/null 2>&1; check $? 1 "not_run sem note -> invalido"
mk '{"tests":[{"command":"x","result":"not_run","note":"sem ambiente"}]}' p5.json
python3 $V p5.json >/dev/null 2>&1; check $? 0 "not_run com note -> valido"
mk '{"summary":"o esqueleto traz <TODO> e <caminho> como marcadores","tests":[{"command":"grep TODO x","result":"pass"}]}' p6.json
python3 $V p6.json >/dev/null 2>&1; check $? 0 "texto que apenas cita <TODO> numa frase -> valido (sem falso positivo)"
python3 $V good.json p5.json >/dev/null 2>&1; check $? 0 "validador aceita varios arquivos validos"
python3 $V good.json m1.json >/dev/null 2>&1; check $? 1 "varios arquivos, um invalido -> 1"
python3 - "$SRC" <<'PYX' 2>/dev/null; check $? 0 "schema exige note em not_run e proibe findings fora de review"
import json, sys
s = json.load(open(sys.argv[1] + '/.ai/schemas/handoff.schema.json'))
t = s['properties']['tests']['items']
assert t['then']['required'] == ['note'] and t['if']['properties']['result']['const'] == 'not_run'
assert any(r.get('then', {}).get('not', {}).get('required') == ['findings']
           and r['if']['properties']['kind']['enum'] == ['delivery', 'correction'] for r in s['allOf'])
PYX
echo 'nao sou json' > m16.json
python3 $V m16.json >/dev/null 2>&1; check $? 1 "arquivo nao-JSON -> invalido"
python3 $V nao-existe.json >/dev/null 2>&1; check $? 2 "arquivo ausente -> uso incorreto"
python3 $V >/dev/null 2>&1; check $? 2 "validador sem argumento -> uso incorreto"

printf '\n%d passaram, %d falharam\n' "$PASS" "$FAIL"
[[ $FAIL -eq 0 ]]
