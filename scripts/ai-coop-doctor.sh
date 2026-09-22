#!/usr/bin/env bash
set -euo pipefail

if [[ $# -ne 0 ]]; then
  printf 'usage: %s\n' "${0##*/}" >&2
  exit 2
fi

if ! command -v git >/dev/null 2>&1; then
  printf 'DEGRADED git unavailable\n' >&2
  exit 1
fi

if ! root="$(git rev-parse --show-toplevel)"; then
  printf 'NOT_GIT run inside a Git worktree\n' >&2
  exit 3
fi

missing=0
for path in .ai .ai/tasks .ai/schemas; do
  if [[ -L "$root/$path" || ! -d "$root/$path" ]]; then
    printf 'MISS %s\n' "$path"
    missing=1
  fi
done
if [[ ! -s "$root/.ai/schemas/task.schema.json" ]]; then
  printf 'MISS .ai/schemas/task.schema.json\n'
  missing=1
fi
if [[ "$missing" -ne 0 ]]; then
  exit 4
fi

if ! git worktree list --porcelain >/dev/null; then
  printf 'DEGRADED git worktree list failed\n' >&2
  exit 1
fi

printf 'OK Git worktree and required .ai layout\n'
