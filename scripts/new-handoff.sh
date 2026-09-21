#!/usr/bin/env bash
set -euo pipefail

TASK_ID=${1:-}
SOURCE_AGENT=${2:-}
TARGET_AGENT=${3:-}

if [[ -z "$TASK_ID" || -z "$SOURCE_AGENT" || -z "$TARGET_AGENT" ]]; then
  echo "usage: $0 TASK_ID SOURCE_AGENT TARGET_AGENT" >&2
  exit 2
fi

mkdir -p .ai/handoffs
OUT=".ai/handoffs/${TASK_ID}.md"
if [[ -e "$OUT" ]]; then
  echo "refusing to overwrite existing handoff: $OUT" >&2
  exit 1
fi

cat > "$OUT" <<DOC
# Handoff — ${TASK_ID}

- Source agent: ${SOURCE_AGENT}
- Target agent: ${TARGET_AGENT}
- Branch:
- Worktree:
- Last commit:
- Status: ready

## Completed

## Files changed

## Tests

## Risks

## Decisions

## Exact next action
DOC

printf '%s\n' "$OUT"
