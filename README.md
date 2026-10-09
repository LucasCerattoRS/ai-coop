# ai-coop

![CI](https://github.com/LucasCerattoRS/ai-coop/actions/workflows/ci.yml/badge.svg)

A repository-native cooperation protocol for running multiple coding agents safely on the same projects.

The project separates three concerns:

1. **Private agent memory** — each agent keeps its own internal state.
2. **Shared operational state** — Git-versioned task, handoff, decision, and status files.
3. **Shared durable knowledge** — explicit promotion into `.ai/knowledge/`, never implicit database merging.

The goal is not to make agents recursively talk to each other. The goal is to make collaboration observable, reversible, auditable, and reproducible.

## Core principles

- Git is the shared source of truth.
- One active worktree per agent.
- Private memory stores are never merged by default.
- Handoffs are explicit and versioned.
- Cross-agent review is encouraged; recursive uncontrolled invocation is not.
- Shared skills should be thin adapters over common protocols and scripts.
- Every automated mutation should have a verification and rollback path.

## Use it in another repository

```bash
scripts/adopt.sh ~/path/to/your-repo          # install or update the protocol files
scripts/adopt.sh --check ~/path/to/your-repo  # exit 1 if that repo is behind this one
```

Pick a task prefix of your own there (e.g. `DW-0001`). Coordinator tools: `scripts/task-state.py`
and `scripts/new-review-task.py` (see `docs/SPEC-v0.1.md` §1–2).

## Status

Early architecture / reference implementation seed.

## License

Source-available under the **PolyForm Noncommercial License 1.0.0** (see `LICENSE`). You may use, copy, modify and
redistribute it for any noncommercial purpose (personal, hobby, research, education, charities).
**Commercial (paid) use requires a separate paid license from the author**: open an issue titled "Commercial license"
in this repository. This is *not* an OSI-approved open-source license, and this is not legal advice.

*Pt-BR:* uso livre para fins não comerciais; uso comercial (remunerado) exige licença paga, à parte, com o autor.

## Em português

### O que é

Protocolo para Claude Code e Codex trabalharem no mesmo repositório sem pisar um no outro: cada agente na sua
branch/worktree, estado compartilhado só em arquivos versionados (`.ai/tasks/*.json` manda, Markdown é vista),
handoffs imutáveis e sequenciados (`.ai/handoffs/<TAREFA>/NNNN-agente.json`) e merge só pelo humano.
`ESTADO.md` é o ponto de retorno; `docs/SPEC-v0.1.md` é a especificação.

### Estado real (revisão de 08/10/2026)

- Rodado localmente (Linux, Python 3 com `jsonschema`): `test_handoff.sh` 74 ok, `test_skills.sh` 44 ok,
  `test_doctor.sh` ok, `test_task.sh` 23 ok, `test_adopt.sh` 31 ok (30 antes + 1 novo), `test_merge_guard.sh`
  11 ok, `test_schema_conformance.py` ok. O CI do GitHub não foi observado rodando nesta revisão.
- Corrigido: `scripts/adopt.sh` colava `.ai/private/` na última linha de um `.gitignore` sem quebra de linha
  final (ex.: `node_modules.ai/private/`), anulando as duas regras.
- `test_merge_guard.sh` não rodava no CI; agora roda. Um `.pyc` tinha sido commitado em `scripts/__pycache__/`.
- `ESTADO.md` ainda lista a AIC-0010 como ASSIGNED, mas o JSON (`.ai/tasks/AIC-0010.json`) diz CLOSED: pelo
  próprio protocolo, vale o JSON.
- A guarda de merge/push (`.githooks/`) está **desativada por padrão** desde 27/09 (`docs/MERGE-GUARD.md`).

### Como rodar

```bash
pip install jsonschema                       # só o test_schema_conformance.py precisa
for t in tests/test_*.sh; do bash "$t" || echo "FALHOU $t"; done
python3 tests/test_schema_conformance.py
bash scripts/ai-coop-doctor.sh               # 0 = layout .ai ok
bash scripts/install-hooks.sh                # opcional: liga a guarda local de merge/push
scripts/adopt.sh ~/caminho/do/repo           # instala/atualiza o protocolo em outro repo
```

### Estrutura

```
.ai/tasks/        estado autoritativo de cada tarefa (JSON, validado por scripts/validate-task.py)
.ai/handoffs/     entregas e revisões, uma pasta por tarefa (validado por scripts/validate-handoff.py)
.ai/schemas/      JSON Schema de tarefa e handoff
.githooks/        guarda local: só AI_COOP_HUMAN=1 faz merge/push/atualiza main
scripts/          handoff.sh, task-state.py, new-review-task.py, adopt.sh, doctor, rodar-codex.sh
.claude/ .agents/ skills finas que apontam para os scripts acima
tests/            testes em bash puro + conformidade com o schema
```

### Pendências / para o Lukas decidir

- Atualizar `ESTADO.md` (AIC-0010 e "Próximo passo exato" estão atrás do JSON).
- Revisão jurídica de `LICENSE` (PolyForm Noncommercial) e `CONTRIBUTING.md`, já listada no `ESTADO.md`.
- `scripts/rodar-codex.sh` grava o log em `/tmp/codex-<TAREFA>-<hora>.log`, nome previsível em diretório
  compartilhado; aceitável em máquina pessoal, trocar por `mktemp` se rodar em máquina com outros usuários.

### Para estudar

- **Operações atômicas no sistema de arquivos**: `mkdir` como trava e `ln` (hard link) que falha se o destino
  existe, em `scripts/handoff.sh`; é como dois agentes não geram o mesmo número de handoff.
- **Symlink e path traversal**: por que `handoff.sh` e `adopt.sh` recusam qualquer componente do caminho que seja
  symlink, e o limite TOCTOU anotado no próprio código.
- **Máquina de estados com caminho mínimo**: `task-state.py` faz busca em largura (BFS) no grafo de transições
  legais de `validate-task.py`, um commit por passo.
- **Git hooks**: `pre-merge-commit` não roda em fast-forward; `reference-transaction` cobre esse buraco.
- **Validador escrito à mão x JSON Schema**: `validate-handoff.py` e o teste de conformidade que confere os dois.
- **Testes sem framework**: funções `ok`/`bad` em bash e repositórios temporários com `mktemp -d`.
