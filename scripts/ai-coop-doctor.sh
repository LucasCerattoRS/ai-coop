#!/usr/bin/env bash
set -euo pipefail

printf 'ai-coop doctor\n'
printf '%-28s %s\n' 'git' "$(command -v git || echo MISSING)"
printf '%-28s %s\n' 'claude' "$(command -v claude || echo not-found)"
printf '%-28s %s\n' 'codex' "$(command -v codex || echo not-found)"

for f in AGENTS.md .ai/STATUS.json .ai/TASKS.md .ai/DECISIONS.md .ai/HANDOFF.md; do
  if [[ -e "$f" ]]; then
    printf 'OK   %s\n' "$f"
  else
    printf 'MISS %s\n' "$f"
  fi
done

if git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  printf 'OK   git repository detected\n'
  git worktree list || true
else
  printf 'INFO not currently inside a git worktree\n'
fi
