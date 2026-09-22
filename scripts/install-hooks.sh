#!/usr/bin/env bash
# Instala os hooks versionados somente neste clone/worktree.
set -euo pipefail

ROOT=$(git rev-parse --show-toplevel) || { printf '%s\n' 'fora de um repositorio Git' >&2; exit 1; }
HOOKS="$ROOT/.githooks"
for hook in pre-merge-commit pre-push reference-transaction; do
  [[ -x "$HOOKS/$hook" ]] || { printf 'hook ausente ou nao executavel: %s\n' "$HOOKS/$hook" >&2; exit 1; }
done
git config --local core.hooksPath "$HOOKS"
printf 'ai-coop hooks ativos em %s\n' "$HOOKS"
