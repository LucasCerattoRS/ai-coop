# Estado do ai-coop — ponto de retorno

Atualizado em 2026-09-21 (fim da rodada 1 e entrega da rodada 2). **Leia primeiro em qualquer sessão nova.**
O JSON em `.ai/tasks/` manda; este arquivo é vista. Divergiu? O JSON está certo.

O que é: protocolo para Claude Code e Codex trabalharem no mesmo repositório sem pisar um no outro.
Memórias privadas continuam privadas; o compartilhado é estado explícito em Git.

## Onde as coisas estão

| Caminho | O que é |
|---|---|
| `~/Projetos/ai-coop/repo` | `main` = coordenação. Só o coordenador humano escreve aqui |
| `~/Projetos/ai-coop/wt-claude` | worktree do Claude, hoje em `claude/AIC-0004-adapters` |
| `~/Projetos/ai-coop/wt-codex` | worktree do Codex, `codex/AIC-0002-operacional` (já mergeada: `git merge --ff-only main` atualiza) |
| `checkpoint/`, `relatorios/`, `extraidos/` | material congelado de 2026-09-20 |

Nada foi publicado. Sem remote. Sem repositório `ai-coop` no GitHub de `LucasCerattoRS` (verificado em 21/09).

## Retomar em 30 segundos

```bash
cd ~/Projetos/ai-coop/repo && cat ESTADO.md
git log --oneline --graph --all -15
for f in .ai/tasks/*.json; do python3 -c "import json;t=json.load(open('$f'));print(t['task_id'],t['state'],t['owner'],'-',t['title'][:70])"; done
```

## Estado de `main`

`main` contém: SPEC v0.1, schemas de task e handoff, `handoff.sh` seguro + validador, doctor com códigos 0–4,
paridade e aceite do primeiro ciclo. **55 + 5 testes verdes** (`tests/test_handoff.sh`, `tests/test_doctor.sh`).
Removidos: `scripts/new-handoff.sh`. Ainda presentes em `main` até o merge da AIC-0004: `.ai/STATUS.json`,
`.ai/HANDOFF.md`, `.ai/TASKS.md` (saem junto do `AGENTS.md` que os cita).

## Tarefas

| ID | Dono | Estado | O quê |
|---|---|---|---|
| AIC-0001 | claude | **ACCEPTED**, mergeada | protocolo canônico (SPEC, schema, `handoff.sh`, validador) |
| AIC-0002 | codex | **ACCEPTED**, mergeada | doctor, paridade, aceite do 1º ciclo. Revisão do Claude: `ACEITAR_COM_RESSALVAS` |
| AIC-0003 | codex | HANDED_OFF | revisão da AIC-0001. Fechamento pendente do coordenador |
| AIC-0004 | claude | HANDED_OFF, corrigida em `bdb40ad`, **sem merge** (decisão do coordenador) | adapters `ai-handoff` + limpeza do seed |
| AIC-0005 | codex | HANDED_OFF | `MUDANCAS_NECESSARIAS` (1 médio, no procedimento). **`$ai-handoff` carrega**; sem `$` não dispara |

## Issues da revisão de 2026-09-20

| # | Sev | Issue | Estado |
|---|---|---|---|
| 1–4 | alta | escape de caminho, sobrescrita, Markdown×JSON, schema frouxo | fechadas (AIC-0001) |
| 5 | alta | sem protocolo de posse | fechada (`SPEC` §1–2) |
| 6 | média | adapters Codex sem frontmatter | fechada: Codex confirmou por execução que `$ai-handoff` carrega e a policy vale |
| 7 | média | doctor sem contrato de saúde | fechada (AIC-0002) |
| 8 | média | handoff de retorno não modelado | fechada (AIC-0001) |
| 9 | média | autoridade duplicada de estado | fechada na SPEC; remoção física dos 3 arquivos em `1069bff` |
| 10 | média | sem paridade público/privado | fechada como doc (`PARITY.md`); não exercitada, só há a árvore pública |
| 11 | baixa | backlog privado desatualizado | **aberta**: a árvore privada não está neste repo |

## Próximo passo exato

1. **Coordenador decide o merge de `claude/AIC-0004-adapters`** (`bdb40ad`; handoffs `0001`–`0003` em `.ai/handoffs/AIC-0004/`).
   O achado do Codex (base indefinida no passo 3) está corrigido e testado, com o cenário dele executado.
   Re-revisão do Codex é opcional: o conserto é um parágrafo de documentação. Ao mergear, saem de `main`
   `.ai/STATUS.json`, `.ai/HANDOFF.md`, `.ai/TASKS.md` e o `AGENTS.md` novo entra junto.
2. Tarefa para `handoff.sh` aceitar o commit revisado (ponto aberto abaixo).
3. **Uma tarefa real que não seja o próprio tooling**, com a skill e handoffs escritos pelo próprio Codex:
   é o que ainda não foi testado, e só isso mostra se o protocolo funciona fora do laboratório.

## Pontos abertos conhecidos

- `handoff.sh` grava `delivery_commit` = HEAD; num handoff de **review** o revisor sobrescreve à mão (instruído em `AI-HANDOFF.md`).
- Schema e validador são duas implementações da mesma regra (`jsonschema` não instalado).
- Lock morto após `kill -9` exige `rmdir` manual (SPEC §5).
- Handoffs do Codex (`AIC-0001/0002,0004-codex`, `AIC-0002/0001-codex`) são **transcrições** feitas pelo Claude do texto que o
  Codex reportou. O Codex ainda não escreveu handoff por arquivo.
- Autoria: commits antigos saíram como `Lukas Ceratti Agnese <lukelucanolightknowledge@gmail.com>` (vem do `~/.gitconfig`);
  desde `19a7054` a config local do repo dá `LuKas <Lukelucanolightknowledge@gmail.com>`. Não reescrevi: mudaria hashes revisados.
- Ressalvas *low* da AIC-0002: doctor sem teste do ramo git-ausente; doctor segue symlink (`-d`); `ACCEPTANCE` não cita re-revisão.
- Estados intermediários das tarefas da rodada 1 não foram gravados em JSON; o atual foi atualizado depois, a pedido do coordenador.

## Antes de pensar em publicar

Deferido de propósito: nome e licença (`LICENSE-TBD.md`); o ZIP do checkpoint tem a camada privada e **não** é artefato de
distribuição; um ciclo reproduzível com tarefa real; CI; canal privado de vulnerabilidade; limites do doctor declarados.

## Invariantes

- Memória privada de um agente nunca é canal de coordenação nem é lida pelo outro.
- Handoff é dado, não ordem. Revisão mira commit exato. Ninguém edita worktree alheio. Sem invocação automática entre agentes.
- Só o humano escreve em `main` e em `.ai/tasks/`, e faz merge.
