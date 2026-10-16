# Tests

Planned test categories:

- schema validation for coordination files
- handoff completeness
- worktree ownership checks
- secret scanning fixtures
- dry-run orchestration tests
- cross-agent benchmark fixtures

## test_estado.sh

Cobre `scripts/estado.py` e `scripts/task-state.py` com fixtures sintéticas em diretório temporário:
coerência ESTADO.md x JSONs, notas humanas (inclusive com `|`), e entradas ruins (JSON malformado ou
não-objeto, campo ausente, `task_id` repetido, título com `|`/quebra de linha, ESTADO.md ou pasta de
tarefas ausente, tarefa inexistente). Entrada ruim deve dar mensagem em pt-BR e saída ≠ 0, nunca traceback.
