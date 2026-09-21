# Divisão de trabalho — rodada 1 (2026-09-21)

Dois agentes trabalham ao mesmo tempo, em worktrees separados, sobre conjuntos de
arquivos disjuntos. Nenhum dos dois espera pelo outro nesta rodada.

## Layout

| Local | Branch | Papel |
|---|---|---|
| `repo/` | `main` | coordenação. Só o humano escreve aqui. |
| `wt-claude/` | `claude/AIC-0001-protocolo` | Claude Code implementa a trilha A |
| `wt-codex/` | `codex/AIC-0002-operacional` | Codex implementa a trilha B |

`main` carrega o estado autorizado: `.ai/tasks/*.json`, `.ai/schemas/task.schema.json`
e este documento. Os agentes leem `main`, escrevem apenas na própria branch.

## Trilha A — Claude — AIC-0001 — protocolo canônico

Fecha o contrato que hoje não existe: autoridade, estados, schema de handoff e
criação segura de handoff.

Escreve apenas: `docs/SPEC-v0.1.md`, `.ai/schemas/handoff.schema.json`,
`.ai/examples/`, `scripts/handoff.sh`, `scripts/validate-handoff.py`,
`tests/test_handoff.sh`.

## Trilha B — Codex — AIC-0002 — superfície operacional

Fecha o que dá para fechar sem depender do contrato de handoff: o que "saudável"
significa, como as árvores pública e privada não divergem, e o que conta como
aceite do primeiro ciclo cooperativo.

Escreve apenas: `scripts/ai-coop-doctor.sh`, `docs/DOCTOR-CONTRACT.md`,
`docs/PARITY.md`, `docs/ACCEPTANCE-FIRST-CYCLE.md`, `tests/test_doctor.sh`.

## Por que assim

As duas trilhas não compartilham nenhum arquivo, então não existe merge conflict
possível e nenhuma das duas bloqueia a outra. A única dependência real do projeto
— o doctor querer validar o schema de handoff — foi cortada: nesta rodada o doctor
valida o layout `.ai/` e o estado Git, que já estão fixados em
`docs/ARCHITECTURE-DIRECTION-v0.1.md` do checkpoint.

## Fora desta rodada

- Adapters de skill `ai-handoff` (`.claude/skills/`, `.agents/skills/`): dependem da
  SPEC da trilha A. Viram AIC-0003 depois do merge.
- `scripts/new-handoff.sh` permanece intocado até a trilha A entregar o substituto;
  a remoção é feita em `main` pelo humano, no merge.
- Publicação em repositório remoto, escolha de licença, invocação automática entre
  agentes: continuam deferidos.

## Regras da rodada

1. Nenhum agente edita, cria ou remove o worktree do outro.
2. Nenhum agente escreve em `main` nem em `.ai/tasks/`.
3. Quem toca um caminho listado em `forbidden_paths` da própria tarefa falhou a tarefa.
4. A entrega é um commit na própria branch. O humano faz o merge.
5. Revisão cruzada acontece depois das duas entregas, contra commits exatos.
