# Prospectus

`ai-coop` is intended to become a portable cooperation layer for coding agents that avoids vendor-specific shared-memory coupling.

Potential future capabilities:

- agent capability registry
- declarative task routing
- reproducible handoffs
- review chains
- Git worktree lifecycle management
- benchmark harnesses
- policy-aware execution boundaries
- knowledge promotion workflows
- optional tmux UI
- optional MCP coordination bus
- CI validation of coordination state

A central design constraint is portability: replacing one agent should not require rewriting the project's shared memory model.
