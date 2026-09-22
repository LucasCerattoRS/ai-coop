# Guarda local de merge e push

Em 21/09, o Codex fez merge em `main` após receber uma instrução ambígua. A
regra “só o humano faz merge” existia apenas como texto. Estes hooks adicionam
uma barreira mecânica contra essa classe de erro.

## Instalação

Em cada clone ou worktree, execute:

```bash
bash scripts/install-hooks.sh
```

O instalador grava `core.hooksPath` localmente, apontando para o `.githooks`
versionado daquele worktree. Rode-o de novo se o diretório for movido.

## Cobertura

`pre-merge-commit` bloqueia merges que criam commit. Como Git não o chama em
fast-forward, `reference-transaction` recusa, no estado `prepared`, qualquer
atualização de `refs/heads/main` sem `AI_COOP_HUMAN=1`; portanto também cobre
fast-forward em `main`. `pre-push` recusa qualquer push sem a mesma variável.

O coordenador humano libera a ação explicitamente:

```bash
AI_COOP_HUMAN=1 git merge --ff-only <branch>
AI_COOP_HUMAN=1 git push
```

## Limites

Esta é uma barreira local contra erro, não defesa contra agente hostil. Hooks
podem ser burlados com `--no-verify` quando o Git o aceita, alterando
`core.hooksPath`, ou executando comandos fora do clone configurado. O
`reference-transaction` preserva a trava de `main` contra fast-forward, mas
um fast-forward em uma branch de trabalho que não seja `main` não é
identificável como merge pela transação de refs e não é bloqueado.

Execute `bash tests/test_merge_guard.sh` para verificar merge com commit,
fast-forward em `main`, push e as liberações explícitas.
