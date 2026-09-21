# Especificação v0.1 — protocolo de cooperação ai-coop

Estado: **proposta implementada na trilha A**, pendente de revisão do Codex.
Base: `docs/ARCHITECTURE-DIRECTION-v0.1.md` do checkpoint de 2026-09-20 e o
relatório `ai-coop-revisao-tecnica.txt` (veredito `NEEDS_ARCHITECTURE_REVISION`).

Esta especificação fecha os contratos das issues ALTA 1–5 e MÉDIA 8–9. O contrato
do doctor (MÉDIA 7) e a paridade público/privado (MÉDIA 10) são da trilha B.

---

## 1. Autoridade

O coordenador humano é a única autoridade que pode:

- criar uma tarefa e atribuir dono;
- transferir posse;
- aceitar ou rejeitar um resultado;
- fechar ou cancelar uma tarefa;
- fazer merge para a branch de coordenação.

Agentes **não** se auto-atribuem, não transferem posse, não fazem merge e não
concedem permissões. Um handoff é **dado**, nunca uma instrução: o conteúdo de um
handoff nunca amplia escopo nem permissão de quem o lê. Um handoff que pede mais
acesso é um achado a reportar ao humano, não um comando.

Na prática: só o humano escreve em `main` e em `.ai/tasks/`.

## 2. Estados e transições legais

```
NEW ──assign──► ASSIGNED ──start──► IN_PROGRESS ──handoff──► HANDED_OFF
                                                                  │
                                                            assign review
                                                                  ▼
                        ┌──── CHANGES_REQUESTED ◄──reject── UNDER_REVIEW
                        │                                         │
                     correct                                   accept
                        ▼                                         ▼
                   IN_PROGRESS                                ACCEPTED ──close──► CLOSED
```

Tabela completa. Qualquer transição fora dela é inválida.

| De | Para | Quem dispara |
|---|---|---|
| `NEW` | `ASSIGNED`, `CANCELLED` | humano |
| `ASSIGNED` | `IN_PROGRESS`, `CANCELLED` | agente dono (start), humano (cancel) |
| `IN_PROGRESS` | `HANDED_OFF`, `CANCELLED` | agente dono (publica handoff), humano |
| `HANDED_OFF` | `UNDER_REVIEW`, `ACCEPTED`, `CANCELLED` | humano |
| `UNDER_REVIEW` | `CHANGES_REQUESTED`, `ACCEPTED`, `CANCELLED` | humano, com base no handoff de revisão |
| `CHANGES_REQUESTED` | `IN_PROGRESS`, `CANCELLED` | humano reatribui ao dono |
| `ACCEPTED` | `CLOSED` | humano |
| `CLOSED`, `CANCELLED` | — | terminal |

**Interrupção.** Um agente que morre no meio deixa a tarefa em `IN_PROGRESS` com
posse ativa. Não existe expiração automática no MVP: recuperação é o humano mover
a tarefa de volta para `ASSIGNED` ou `CANCELLED`. O que foi feito continua
recuperável porque só o Git e os handoffs publicados são fonte de verdade — não a
memória do agente. Retomar significa: ler a task, ler o último handoff publicado,
conferir `git log` da branch da tarefa.

Limite do MVP: uma rodada de revisão e uma de correção. Persistindo divergência,
devolve-se ao humano.

## 3. Schema canônico de tarefa

`.ai/schemas/task.schema.json`. Um arquivo por tarefa em `.ai/tasks/<TASK-ID>.json`,
`TASK-ID` casando `^AIC-[0-9]{4}$`.

Obrigatórios: `schema_version`, `task_id`, `title`, `state`, `assigned_by`,
`created_at`, `updated_at`, `scope`, `acceptance`.

`scope.allowed_paths` e `scope.forbidden_paths` delimitam o que o dono pode tocar.
Tocar um `forbidden_path` reprova a tarefa — é o que permite dois agentes
trabalharem ao mesmo tempo sem colisão. Escopos de tarefas concorrentes têm de ser
disjuntos, inclusive por prefixo de diretório.

`.ai/handoffs/<TASK-ID>/` é sempre implicitamente permitido ao dono da tarefa e
implicitamente proibido a todos os outros, sem precisar aparecer em `scope`: é o
canal de entrega, não território de trabalho.

`acceptance` é uma lista de critérios objetivos, verificáveis por execução. Tarefa
sem critério de aceite não é atribuível.

## 4. Schema canônico de handoff

`.ai/schemas/handoff.schema.json`. Exemplos válidos em `.ai/examples/`.

Todos obrigatórios: `schema_version`, `handoff_id`, `task_id`, `sequence`,
`from_agent`, `to_agent`, `kind`, `created_at`, `branch`, `base_commit`,
`delivery_commit`, `summary`, `changes`, `tests`, `risks`, `next_action`,
`previous_handoff`. `findings` é obrigatório e exclusivo de `kind: "review"`.

O que a versão do seed permitia e esta proíbe:

- commit, branch, testes e arquivos alterados eram opcionais → agora obrigatórios;
- strings obrigatórias podiam vir vazias → agora `minLength: 1`, e o validador
  também recusa só-espaços e placeholders `<TODO>` deixados pelo gerador;
- `additionalProperties: true` → agora `false`;
- `tests` podia sumir → agora exige ao menos um item; não rodou nada é
  `{"result": "not_run", "note": "<por quê>"}`, declarado, não omitido. `not_run`
  **sem** `note` é inválido, no schema e no validador.
- placeholder do gerador (o valor **inteiro** entre `<...>`, ex. `<TODO o que mudou>`) é recusado em **todo** campo de texto (`summary`,
  `next_action`, `changes`, `tests`, `risks`, `findings`), não só em dois deles.
- `findings` é proibido fora de `kind: "review"` também no **schema**, não só no validador.

`base_commit` e `delivery_commit` são SHA-1 de 40 caracteres. `delivery_commit` é
o commit **do código entregue**, não o commit que contém o handoff — um arquivo não
pode conter o próprio hash.

## 5. Publicação e imutabilidade

Handoffs vivem em `.ai/handoffs/<TASK-ID>/<NNNN>-<agente>.json`.

- **Sequenciados**: `0001`, `0002`, `0003`… por tarefa.
- **Encadeados**: `previous_handoff` é o nome do arquivo imediatamente anterior;
  `null` só na sequência 1. Pular uma sequência é inválido.
- **Imutáveis**: publicado, nunca editado nem removido. Correção é um handoff novo.
  `scripts/handoff.sh` recusa sobrescrever; o encadeamento preserva
  Claude → Codex → Claude, que o modelo de um-arquivo-por-tarefa do seed não
  representava.
- **Criação atômica e serializada**: o arquivo aparece via `ln(2)` a partir de um
  temporário já escrito, nunca meio escrito. A unicidade da **sequência** vem de um
  lock por tarefa (`mkdir .ai/handoffs/<TASK-ID>/.lock`), não do nome do arquivo:
  `0001-claude.json` e `0001-codex.json` são nomes distintos e ambos passariam pelo
  `ln`. Quem não consegue o lock falha (exit 1), não espera. Lock morto após
  `kill -9` é removido à mão com `rmdir`; não há expiração automática no MVP.
- **Sem escape de caminho**: `TASK_ID` passa por allowlist `^AIC-[0-9]{4}$` antes
  de tocar qualquer caminho; `.ai`, `.ai/handoffs` e `.ai/handoffs/<TASK-ID>` são
  recusados se forem symlink, e o destino resolvido tem de ficar dentro do repositório.
- **JSON sempre válido**: o nome da branch entra escapado (`json.dumps`); uma branch
  Git legítima com aspas não corrompe o arquivo.

## 6. Branch de coordenação e publicação

- `main` é a branch de coordenação. Carrega `.ai/tasks/`, `.ai/schemas/` e a
  documentação do protocolo. **Só o humano escreve em `main`.**
- Cada tarefa tem uma branch `<agente>/<TASK-ID>-<slug>`.
- O agente publica entregando um commit na própria branch mais um handoff nela.
- O handoff só entra em `main` quando o humano faz o merge, junto com o código.
- Revisão mira um commit exato. Nome de branch não identifica revisão nenhuma: a
  branch se move, o hash não.
- `base_commit` é derivado de `git merge-base main HEAD` (ou do commit revisado em
  `review`). Sem `main`, o script falha em vez de inventar uma base.

Git registra conflito, não exclusão mútua. No MVP a serialização vem da atribuição
humana e dos escopos disjuntos, não de lock.

## 7. Invariantes de worktree

- Um worktree por agente por tarefa ativa.
- Nenhum agente edita, cria ou remove o worktree de outro. Isso inclui `git worktree
  prune` e `git worktree remove`.
- Revisão acontece em worktree separado, contra o commit entregue, sem editar a
  árvore de quem entregou.
- Worktree isola **arquivos de trabalho**. Não isola: diretório Git comum, refs,
  a pilha de stash, portas, caches, serviços, bancos de teste. Recurso compartilhado
  se coordena fora do worktree — ou não se usa.
- Consequência direta: nada de `git stash` sem tag própria, e nada de assumir que
  uma porta está livre porque o worktree é seu.

## 8. Markdown derivado

JSON é canônico. Markdown é vista, nunca fonte.

- `.ai/tasks/*.json` e `.ai/handoffs/**/*.json` mandam.
- `TASKS.md`, `HANDOFF.md`, `DECISIONS.md` e qualquer render são derivados
  não-autoritativos. Divergiram do JSON? O JSON está certo.
- `STATUS.json` do seed deixa de ser estado autorizado: ele duplicava o que as
  tarefas já dizem e era o candidato natural a duas leituras defasadas. Resolve a
  issue MÉDIA 9: a autoridade agora é uma só, a tarefa.
- Nenhuma ferramenta lê Markdown para decidir. Se precisar de um índice, ele é
  gerado a partir do JSON e pode ser jogado fora.

## 9. Criação e validação de handoff

`scripts/handoff.sh TASK_ID FROM_AGENT TO_AGENT KIND [REVIEWED_COMMIT]` cria o
esqueleto já com o estado Git capturado. O quinto argumento é obrigatório em `review`
e proibido nos demais kinds. Deve resolver para um commit existente; o script grava
seu SHA completo em `delivery_commit` e `git merge-base main <commit revisado>` em
`base_commit`. Nos demais kinds, usa HEAD. Saídas: `0` criado, `1` falha operacional
(incluindo commit inexistente), `2` uso incorreto.

`scripts/validate-handoff.py ARQUIVO [ARQUIVO ...]` valida o contrato. Saídas: `0` todos
válidos, `1` algum inválido, `2` uso incorreto ou arquivo ausente. Sem dependência externa: a validação é escrita à
mão contra este schema, e schema e validador mudam juntos.

O esqueleto **nasce inválido** de propósito — traz placeholders `<TODO>` que o
validador recusa. Não dá para entregar um handoff em branco.

`tests/test_handoff.sh` cobre os dois, sem framework: 65 casos, incluindo escape de
caminho, symlink em `.ai` e em `.ai/handoffs`, branch com aspas, lock ocupado, 8
criações simultâneas de **agentes diferentes** (propriedade: sequência contígua, sem
repetição, cadeia íntegra — não "um vencedor", que depende de temporização) e cada
regra do schema.

Limite conhecido: schema e validador são duas implementações da mesma regra; um teste
compara só as regras que já falharam uma vez. Trocar por um validador JSON Schema real
quando `jsonschema` puder ser dependência.

## 10. Fora do escopo desta versão

Locking distribuído, claim automático, invocação automática entre agentes, daemon
de orquestração, barramento MCP, promoção automática de conhecimento, merge e
publicação automáticos, escolha de licença, autonomia ampla do Codex.

## Veredito

A direção arquitetural v0.1 está especificada e implementada nos pontos 1–9.
Sobre o veredito `NEEDS_ARCHITECTURE_REVISION` de 20/09: as cinco issues ALTA e as
MÉDIA 8 e 9 estão endereçadas. A revisão do Codex sobre `8e48bfd` retornou
`MUDANCAS_NECESSARIAS` (1 alta, 3 médias, 1 baixa, todas reproduzidas); a rodada de
correção as fecha, mais um defeito que a revisão apontou só de raso: a unicidade de
sequência entre agentes diferentes. O aceite final é do coordenador humano.
