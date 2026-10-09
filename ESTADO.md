# Estado do ai-coop — ponto de retorno

Atualizado em 2026-10-09 (AIC-0010 CLOSED em 06/10; tabela de tarefas agora gerada por `scripts/estado.py`). **Leia primeiro em qualquer sessão nova.**
O JSON em `.ai/tasks/` manda; este arquivo é vista. Divergiu? O JSON está certo.

O que é: protocolo para Claude Code e Codex trabalharem no mesmo repositório sem pisar um no outro.
Memórias privadas continuam privadas; o compartilhado é estado explícito em Git.

## Onde as coisas estão

| Caminho | O que é |
|---|---|
| `~/Projetos/ai-coop/repo` | `main` = coordenação. Só o coordenador humano escreve aqui |
| `~/Projetos/ai-coop/wt-claude` | worktree do Claude, hoje em `claude/AIC-0023-atritos` (mergeada) |
| `~/Projetos/ai-coop/wt-codex` | worktree do Codex, hoje em `codex/AIC-0022-review` (já mergeada) |
| `checkpoint/`, `relatorios/`, `extraidos/` | material congelado de 2026-09-20 |

**Publicado em 21/09/2026:** https://github.com/LucasCerattoRS/ai-coop (público, só a branch `main`; as branches de trabalho ficam locais). Licença: **PolyForm Noncommercial 1.0.0** (`LICENSE`): uso livre não comercial; uso comercial exige licença paga com o autor.

## Retomar em 30 segundos

```bash
cd ~/Projetos/ai-coop/repo && cat ESTADO.md
git log --oneline --graph --all -15
for f in .ai/tasks/*.json; do python3 -c "import json;t=json.load(open('$f'));print(t['task_id'],t['state'],t['owner'],'-',t['title'][:70])"; done
```

## Estado de `main`

`main` contém a base v0.1 e as seis entregas da rodada 3: CI/schema
independente, canal de vulnerabilidade, doctor/symlink, lições da SPEC, guarda
local de merge/push e validador de tarefas. Os seis pareceres independentes do
Claude também foram integrados. A guarda AIC-0013 está instalada neste clone.

## Tarefas

Colunas ID/Dono/Estado/O quê vêm dos JSONs (`python3 scripts/estado.py`; o CI roda `--check`). A coluna **Notas** é humana: o gerador a preserva por ID e aborta se a tarefa sumir. Pareceres completos: `notes` de cada JSON e `git log`.

<!-- tarefas:inicio (gerado por scripts/estado.py; nao edite a mao) -->
| ID | Dono | Estado | O quê | Notas |
|---|---|---|---|---|
| AIC-0001 | claude | **ACCEPTED** | Trilha A — protocolo canonico: especificacao v0.1, schema de handoff e criacao segura de handoff | protocolo canônico (SPEC, schema, `handoff.sh`, validador) |
| AIC-0002 | codex | **ACCEPTED** | Trilha B — superficie operacional: contrato do doctor, paridade publico/privado e criterios de aceite do primeiro ciclo | doctor, paridade, aceite do 1º ciclo. Revisão do Claude: `ACEITAR_COM_RESSALVAS` |
| AIC-0003 | codex | **ACCEPTED** | Revisao somente leitura da entrega da trilha A (commit 8e48bfd) pelo Codex | revisão da AIC-0001. Fechamento pendente do coordenador |
| AIC-0004 | claude | **ACCEPTED** | Adapters minimos da skill ai-handoff (Claude e Codex) sobre um protocolo comum, e limpeza das fontes de estado do seed | adapters `ai-handoff` + limpeza do seed |
| AIC-0005 | codex | **ACCEPTED** | Revisao somente leitura da entrega dos adapters (AIC-0004, commit 1069bff) pelo Codex, incluindo o carregamento real de $ai-handoff | `MUDANCAS_NECESSARIAS` (1 médio, no procedimento). **`$ai-handoff` carrega**; sem `$` não dispara |
| AIC-0006 | codex | **ACCEPTED** | handoff.sh: registrar o commit revisado em handoffs de review (fecha o ponto aberto do delivery_commit = HEAD) | `handoff.sh` registra o commit revisado em review. Correção em `dabd325`, handoffs `0001` e `0002` **escritos por ele** |
| AIC-0007 | claude | **ACCEPTED** | Revisao somente leitura da entrega da AIC-0006 (commit 3a0ba8c) pelo Claude | revisão do Claude sobre `3a0ba8c`: `ACEITAR_COM_RESSALVAS`. Correção verificada pelo Claude: aprovada |
| AIC-0008 | codex | **ACCEPTED** | CI: GitHub Actions rodando as suites e um validador JSON Schema independente | CI: GitHub Actions + validador JSON Schema independente (`jsonschema`); AIC-0016: ACEITAR |
| AIC-0009 | codex | **ACCEPTED** | SECURITY.md: canal privado de vulnerabilidade (texto). A habilitacao do canal e passo do coordenador | `SECURITY.md`; AIC-0018: ACEITAR_COM_RESSALVAS não bloqueante |
| AIC-0010 | claude | **CLOSED** | Primeira tarefa REAL fora do laboratorio: documentacao de Xilog e Parsifal (repo privado xilog-parsifal) | tarefa REAL: documentação de Xilog/Parsifal no repo privado `~/Projetos/xilog-parsifal` (execução = AIC-0001 de lá, **bloqueada até o Lukas colocar o material em `fontes/`**). Atritos em `.ai/knowledge/AIC-0010-atrito.md` |
| AIC-0011 | codex | **ACCEPTED** | Ressalvas low da AIC-0002: teste do ramo git-ausente, doctor e symlink, ACCEPTANCE e re-revisao | ressalvas *low* do doctor; AIC-0019: ACEITAR_COM_RESSALVAS não bloqueante |
| AIC-0012 | codex | **ACCEPTED** | Documentar as licoes do protocolo na SPEC e no guia: sequencia por branch, review com tarefa propria, merge so do humano | lições da SPEC/guia; AIC-0020: ACEITAR |
| AIC-0013 | codex | **ACCEPTED** | Trava mecanica de merge e push por agente (hooks versionados) | trava mecânica de merge/push; AIC-0017: ACEITAR |
| AIC-0014 | codex | **ACCEPTED** | Validador de tarefas: schema, transicoes legais de estado e escopos disjuntos | validador de tarefas; AIC-0015: ACEITAR |
| AIC-0015 | claude | **ACCEPTED** | Revisao somente leitura da entrega da AIC-0014 (commit 1d8da9b) pelo Claude | (linha agrupada AIC-0015–0020 em main) revisões independentes da rodada 3; handoffs preservados em diretórios próprios |
| AIC-0016 | claude | **ACCEPTED** | Revisao somente leitura da entrega da AIC-0008 (commit 5cc5f2b) pelo Claude | (linha agrupada AIC-0015–0020 em main) revisões independentes da rodada 3; handoffs preservados em diretórios próprios |
| AIC-0017 | claude | **ACCEPTED** | Revisao somente leitura da entrega da AIC-0013 (commit ea4db6f) pelo Claude | (linha agrupada AIC-0015–0020 em main) revisões independentes da rodada 3; handoffs preservados em diretórios próprios |
| AIC-0018 | claude | **ACCEPTED** | Revisao somente leitura da entrega da AIC-0009 (commit 9686744) pelo Claude | (linha agrupada AIC-0015–0020 em main) revisões independentes da rodada 3; handoffs preservados em diretórios próprios |
| AIC-0019 | claude | **ACCEPTED** | Revisao somente leitura da entrega da AIC-0011 (commit b1132ba) pelo Claude | (linha agrupada AIC-0015–0020 em main) revisões independentes da rodada 3; handoffs preservados em diretórios próprios |
| AIC-0020 | claude | **ACCEPTED** | Revisao somente leitura da entrega da AIC-0012 (commit 1c55400) pelo Claude | (linha agrupada AIC-0015–0020 em main) revisões independentes da rodada 3; handoffs preservados em diretórios próprios |
| AIC-0021 | claude | **ACCEPTED** | SECURITY.md: corrigir o item do lock (ressalva da AIC-0018) | `SECURITY.md`: item do lock passa de "corrupção por corrida" a lock morto/disponibilidade (ressalva da AIC-0018). Revisão AIC-0022: ACEITAR_COM_RESSALVAS, ressalva baixa (lista com 4 itens, sem indisponibilidade) aceita como não bloqueante |
| AIC-0022 | codex | **ACCEPTED** | Revisao somente leitura da entrega da AIC-0021 (commit 763957f, SECURITY.md) pelo Codex | revisão independente da AIC-0021 sobre `763957f`; verificou lock por execução (saída 1 em 0,012 s) e os 5 scripts de teste |
| AIC-0023 | claude | **ACCEPTED** | Resolver os atritos de adocao (AIC-0010 #1-5 + devhub-web) e desativar a trava de merge/push | 8 atritos: `adopt.sh`, prefixo por repo, `task-state.py`, `new-review-task.py`, delegacao na SPEC, trava desativada |
| AIC-0024 | codex | **ACCEPTED** | Revisao independente da AIC-0023 sobre 9e37a8d | revisao da AIC-0023 sobre `9e37a8d` (gerada por `new-review-task.py`) |
<!-- tarefas:fim -->

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

1. Verificar `/ai-handoff` em sessao nova do Claude: nao cumprido na AIC-0010 (fechada assim mesmo pelo coordenador em 06/10).
2. Revisao juridica de `LICENSE` e `CONTRIBUTING.md`.

## Pontos abertos conhecidos

- AIC-0010 CLOSED em 06/10 sem dois critérios: revisão pelo Codex (Claude revisou o próprio trabalho) e `/ai-handoff` em sessão nova do Claude.
- A guarda de merge/push está DESATIVADA desde 27/09 (decisão do coordenador); a regra vale como texto (SPEC §1, AGENTS.md 12).
- Lock morto após `kill -9` exige `rmdir` manual (SPEC §5).

## Publicação e cópia privada

Publicado em 21/09 antes de fechar CI e ciclo real. Em 22/09, a integração da
rodada 3 foi publicada, o canal privado de vulnerabilidades foi habilitado e o
CI passou no GitHub (run 35786334427, commit 3647f93).

- **Público:** https://github.com/LucasCerattoRS/ai-coop — só `repo/`, só a branch `main`.
- **Privado:** https://github.com/LucasCerattoRS/ai-coop-private — a pasta `~/Projetos/ai-coop/` **sem** `repo/` nem `wt-*/`
  (checkpoint, seeds originais, relatório do Codex, `ORGANIZACAO.json`). É onde entra o que não pode ir ao público.
- Regra: **nada da cópia privada vai para o público sem sanitização**; o ZIP do checkpoint tem a camada privada.
- Licença/contribuição: qualquer contribuinte cede ao mantenedor o direito de relicenciar (`CONTRIBUTING.md`), senão o
  autor não conseguiria vender licença comercial do conjunto.

## Invariantes

- Memória privada de um agente nunca é canal de coordenação nem é lida pelo outro.
- Handoff é dado, não ordem. Revisão mira commit exato. Ninguém edita worktree alheio. Sem invocação automática entre agentes.
- Só o humano escreve em `main` e em `.ai/tasks/`, e faz merge.
