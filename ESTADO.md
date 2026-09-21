# Estado do ai-coop — ponto de retorno

Atualizado em 2026-09-21. **Leia este arquivo primeiro em qualquer sessão nova.**

O que é: protocolo para Claude Code e Codex trabalharem no mesmo repositório sem
pisar um no outro. Memórias privadas continuam privadas; o que é compartilhado é
estado explícito, versionado em Git.

## Onde as coisas estão

| Caminho | O que é |
|---|---|
| `~/Projetos/ai-coop/repo` | repositório de trabalho, branch `main` = coordenação |
| `~/Projetos/ai-coop/wt-claude` | worktree do Claude, branch `claude/AIC-0001-protocolo` |
| `~/Projetos/ai-coop/wt-codex` | worktree do Codex, branch `codex/AIC-0002-operacional` |
| `~/Projetos/ai-coop/checkpoint/` | ZIP congelado do closeout de 2026-09-20 |
| `~/Projetos/ai-coop/relatorios/` | revisão técnica do Codex, 2026-09-20 |
| `~/Projetos/ai-coop/extraidos/` | seeds originais, preservados sem alteração |

Nada foi publicado. Não existe remote. Não existe repositório `ai-coop` no GitHub
da conta `LucasCerattoRS` (verificado em 21/09, 47 repos, nenhum casando).

## Retomar em 30 segundos

```bash
cd ~/Projetos/ai-coop/repo
cat ESTADO.md
git log --oneline --graph --all -15
ls .ai/tasks/            # tarefas = estado autorizado
cat .ai/tasks/AIC-*.json | python3 -c "import json,sys;[print(t['task_id'],t['state'],t['owner'],t['title']) for t in map(json.loads,sys.stdin.read().split('}\n{')) ] " 2>/dev/null || true
```

Regra de leitura: **o JSON em `.ai/tasks/` manda.** Markdown é vista, inclusive este
arquivo. Divergiu? O JSON está certo.

## Progressão por commit

| Commit | Branch | O que entrou |
|---|---|---|
| `c4c1351` | main | importa o seed público congelado como base |
| `bdef1a7` | main | divisão de trabalho da rodada 1, `task.schema.json`, AIC-0001 e AIC-0002 |
| `561a74a` | main | AIC-0003 (revisão cruzada) e briefing do Codex com o commit entregue |
| `8e48bfd` | claude/AIC-0001 | SPEC v0.1, schema de handoff endurecido, `handoff.sh` seguro, validador, 40 testes |
| `1604052` | claude/AIC-0001 | handoff de entrega `0001-claude.json` publicado |

Cada rodada acrescenta linhas aqui. Não reescreva as antigas.

## Tarefas

| ID | Dono | Estado | O quê |
|---|---|---|---|
| AIC-0001 | claude | entregue, aguardando revisão | protocolo canônico (trilha A) |
| AIC-0002 | codex | atribuída, não iniciada | superfície operacional (trilha B) |
| AIC-0003 | codex | atribuída, depois de AIC-0002 | revisar o commit `8e48bfd` |

## Issues da revisão de 2026-09-20

| # | Sev | Issue | Estado |
|---|---|---|---|
| 1 | alta | `new-handoff.sh` permite escape de caminho | fechada em `8e48bfd` (allowlist) |
| 2 | alta | proteção contra sobrescrita não é atômica | fechada em `8e48bfd` (`ln(2)`) |
| 3 | alta | gerador produz Markdown, schema descreve JSON | fechada em `8e48bfd` (JSON canônico) |
| 4 | alta | schema permissivo demais | fechada em `8e48bfd` |
| 5 | alta | sem protocolo de posse | fechada em `SPEC-v0.1.md` §1–2 |
| 6 | média | adapters Codex sem frontmatter | **aberta** — vira AIC-0004, depende da SPEC |
| 7 | média | doctor não determina saúde | **aberta** — AIC-0002 |
| 8 | média | handoff de retorno não modelado | fechada em `8e48bfd` (sequência encadeada) |
| 9 | média | autoridade duplicada entre STATUS.json/TASKS.md/HANDOFF.md | fechada em `SPEC-v0.1.md` §8 |
| 10 | média | árvores pública e privada sem paridade | **aberta** — AIC-0002 |
| 11 | baixa | backlog privado desatualizado | **aberta** — trivial, no próximo merge |

## Próximo passo exato

1. Lukas aciona o Codex com `CODEX-BRIEFING.md`. Codex entrega AIC-0002, depois AIC-0003.
2. Lukas traz o veredito do Codex para o Claude.
3. Claude faz **uma** rodada de correção sobre os achados (limite da SPEC §2).
4. Lukas faz o merge de `claude/AIC-0001-protocolo` e `codex/AIC-0002-operacional` em `main`,
   remove `scripts/new-handoff.sh` e `.ai/STATUS.json` no mesmo merge, e atualiza este arquivo.
5. Rodada 2: AIC-0004, adapters de skill `ai-handoff` sobre a SPEC aceita.

Só o humano faz merge. Os agentes entregam commits nas próprias branches.

## Antes de pensar em publicar

Deferido por decisão, não por esquecimento:

- nome definitivo e licença (hoje `LICENSE-TBD.md`);
- o ZIP completo do checkpoint contém a camada privada — **não** é artefato de distribuição;
- um fluxo Claude → Codex → Claude completo e reproduzível;
- CI verificando schemas, scripts e exemplos;
- canal privado de relato de vulnerabilidade;
- limitações do doctor declaradas (AIC-0002).

## Invariantes que não se negociam

- Memória privada de um agente nunca vira canal de coordenação, nem é lida pelo outro.
- Handoff é dado, não ordem: nada que ele contenha amplia escopo ou permissão.
- Revisão mira commit exato, nunca nome de branch.
- Nenhum agente edita, cria ou remove o worktree de outro.
- Nenhuma invocação automática entre agentes.
