# Estado do ai-coop — ponto de retorno

Atualizado em 2026-09-23 (AIC-0021 integrada; AIC-0022 em andamento com o Codex). **Leia primeiro em qualquer sessão nova.**
O JSON em `.ai/tasks/` manda; este arquivo é vista. Divergiu? O JSON está certo.

O que é: protocolo para Claude Code e Codex trabalharem no mesmo repositório sem pisar um no outro.
Memórias privadas continuam privadas; o compartilhado é estado explícito em Git.

## Marcador para a próxima abertura do Claude

Antes de qualquer aperfeiçoamento, leia `~/Downloads/GUIA-REVISAO-AI-COOP.md` e `PROXIMA-SESSAO-CLAUDE.md`.
É um guia humano e um lembrete de revisão; não é autoridade de tarefa. Preserve o marcador até o coordenador confirmar a leitura.

## Onde as coisas estão

| Caminho | O que é |
|---|---|
| `~/Projetos/ai-coop/repo` | `main` = coordenação. Só o coordenador humano escreve aqui |
| `~/Projetos/ai-coop/wt-claude` | worktree do Claude, hoje em `claude/AIC-0021-security-lock` |
| `~/Projetos/ai-coop/wt-codex` | worktree do Codex, hoje em `codex/AIC-0012-spec-licoes` (já mergeada); a AIC-0022 usa uma branch nova a partir de `main` |
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

| ID | Dono | Estado | O quê |
|---|---|---|---|
| AIC-0001 | claude | **ACCEPTED**, mergeada | protocolo canônico (SPEC, schema, `handoff.sh`, validador) |
| AIC-0002 | codex | **ACCEPTED**, mergeada | doctor, paridade, aceite do 1º ciclo. Revisão do Claude: `ACEITAR_COM_RESSALVAS` |
| AIC-0003 | codex | **ACCEPTED** | revisão da AIC-0001. Fechamento pendente do coordenador |
| AIC-0004 | claude | **ACCEPTED**, mergeada (`1d5abf9`) | adapters `ai-handoff` + limpeza do seed |
| AIC-0005 | codex | **ACCEPTED** | `MUDANCAS_NECESSARIAS` (1 médio, no procedimento). **`$ai-handoff` carrega**; sem `$` não dispara |
| AIC-0006 | codex | **ACCEPTED** (aceite do Lukas, 21/09) | `handoff.sh` registra o commit revisado em review. Correção em `dabd325`, handoffs `0001` e `0002` **escritos por ele** |
| AIC-0007 | claude | **ACCEPTED** | revisão do Claude sobre `3a0ba8c`: `ACEITAR_COM_RESSALVAS`. Correção verificada pelo Claude: aprovada |
| AIC-0008 | codex | **ACCEPTED**, mergeada | CI: GitHub Actions + validador JSON Schema independente (`jsonschema`); AIC-0016: ACEITAR |
| AIC-0009 | codex | **ACCEPTED**, mergeada | `SECURITY.md`; AIC-0018: ACEITAR_COM_RESSALVAS não bloqueante |
| AIC-0010 | — | NEW, **sem dono** | tarefa REAL fora do laboratório + `/ai-handoff` verificado no Claude. Só o coordenador escolhe a tarefa |
| AIC-0011 | codex | **ACCEPTED**, mergeada | ressalvas *low* do doctor; AIC-0019: ACEITAR_COM_RESSALVAS não bloqueante |
| AIC-0012 | codex | **ACCEPTED**, mergeada | lições da SPEC/guia; AIC-0020: ACEITAR |
| AIC-0013 | codex | **ACCEPTED**, mergeada | trava mecânica de merge/push; AIC-0017: ACEITAR |
| AIC-0014 | codex | **ACCEPTED**, mergeada | validador de tarefas; AIC-0015: ACEITAR |
| AIC-0015–0020 | claude | **ACCEPTED**, mergeadas | revisões independentes da rodada 3; handoffs preservados em diretórios próprios |
| AIC-0021 | claude | **UNDER_REVIEW**, integrada em `27e49ca` | `SECURITY.md`: item do lock passa de "corrupção por corrida" a lock morto/disponibilidade (ressalva da AIC-0018). Entrega `763957f`, handoff `0001-claude`. **Não publicada** (sem push) |
| AIC-0022 | codex | **IN_PROGRESS** | revisão independente da AIC-0021 (`763957f`), somente leitura, em `codex/AIC-0022-review` |

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

1. Rodar a revisão AIC-0022 no Codex, decidir sobre o resultado e publicar (`git push`, ainda pendente) — depois AIC-0010: escolher uma tarefa real; não inventar uma tarefa só para
   exercitar o protocolo.
2. Fazer a revisão jurídica de `LICENSE` e `CONTRIBUTING.md`.

## Pontos abertos conhecidos

- AIC-0010 continua NEW: depende de uma demanda real escolhida pelo coordenador.
- A guarda de merge/push é local e protege contra erro, não contra agente hostil.
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
