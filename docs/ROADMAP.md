# Roadmap

## Phase 0 — Safe coexistence

- isolate private agent state
- validate concurrent operation
- document rollback

## Phase 1 — Shared coordination

- `.ai/STATUS.json`
- task registry
- deterministic handoff format
- decision log
- knowledge promotion

## Phase 2 — Worktree orchestration

- one worktree per active agent
- branch ownership
- claim/release semantics
- conflict detection

## Phase 3 — Shared skills

- Claude adapter skill
- Codex adapter skill
- common validation scripts
- portable installation

## Phase 4 — Reliability benchmark

- same-task A/B runs
- instruction adherence metrics
- regression counts
- review quality
- rollback quality
- human intervention rate

## Phase 5 — Orchestrator

- tmux launcher
- status pane
- bounded agent assignment
- review routing
- loop prevention
- budget controls

## Phase 6 — Optional MCP coordination bus

Possible tools:
- claim_task
- read_handoff
- submit_result
- release_task
- record_decision
- promote_knowledge

The MCP layer should remain optional; Git must stay sufficient for recovery.
