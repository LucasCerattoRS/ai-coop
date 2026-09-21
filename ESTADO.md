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
| AIC-0004 | claude | HANDED_OFF em `1069bff`, **sem merge** | adapters `ai-handoff` + limpeza do seed |
| AIC-0005 | codex | ASSIGNED | revisar `1069bff` e **confirmar se `$ai-handoff` carrega** |

## Issues da revisão de 2026-09-20

| # | Sev | Issue | Estado |
|---|---|---|---|
| 1–4 | alta | escape de caminho, sobrescrita, Markdown×JSON, schema frouxo | fechadas (AIC-0001) |
| 5 | alta | sem protocolo de posse | fechada (`SPEC` §1–2) |
| 6 | média | adapters Codex sem frontmatter | entregue em `1069bff`; **falta o Codex confirmar o carregamento** |
| 7 | média | doctor sem contrato de saúde | fechada (AIC-0002) |
| 8 | média | handoff de retorno não modelado | fechada (AIC-0001) |
| 9 | média | autoridade duplicada de estado | fechada na SPEC; remoção física dos 3 arquivos em `1069bff` |
| 10 | média | sem paridade público/privado | fechada como doc (`PARITY.md`); não exercitada, só há a árvore pública |
| 11 | baixa | backlog privado desatualizado | **aberta**: a árvore privada não está neste repo |

## Próximo passo exato

1. **Codex executa AIC-0005** (texto de acionamento no fim). Sem ele não se sabe se o adapter do Codex carrega.
2. Coordenador decide o aceite de AIC-0004 e faz o merge de `claude/AIC-0004-adapters`.
3. Só então: tarefa para `handoff.sh` aceitar o commit revisado (ponto aberto abaixo), e uma 2ª tarefa real,
   que **não** seja o próprio tooling, para o 1º ciclo com a skill e handoffs escritos pelo próprio Codex.

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

## Texto para acionar o Codex (AIC-0005)

> Você está no projeto ai-coop, `~/Projetos/ai-coop`. Faça a AIC-0005: revisão somente leitura do commit **`1069bff`** (branch
> `claude/AIC-0004-adapters`), sem checkout nem edição de `wt-claude`. Leia `~/Projetos/ai-coop/repo/.ai/tasks/AIC-0005.json` e o handoff
> `git -C ~/Projetos/ai-coop/repo show claude/AIC-0004-adapters:.ai/handoffs/AIC-0004/0001-claude.json`. Confirme **por execução** se
> `$ai-handoff` é listado e carrega no Codex e se a policy impede invocação implicita; reproduza `tests/test_skills.sh` em cópia temporária;
> confira se cada passo de "Criar" em `docs/AI-HANDOFF.md` é executável com os scripts atuais. Não confie nos meus resultados.
> Veredito: ACEITAR, ACEITAR_COM_RESSALVAS ou MUDANCAS_NECESSARIAS. Sem merge, sem push.
