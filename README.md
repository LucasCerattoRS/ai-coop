# ai-coop

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

## Status

Early architecture / reference implementation seed.
