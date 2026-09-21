# Architecture

```text
                  Human / Orchestrator
                         |
              +----------+----------+
              |                     |
           Agent A                Agent B
              |                     |
         worktree A             worktree B
              \                     /
               +-------- Git -------+
                         |
                        .ai/
                         |
          tasks / handoffs / decisions / knowledge
```

## Separation model

Private memory remains agent-specific. Shared state is repository-native and reviewable.

## Why not merge agent memories?

Agent memory formats, semantics, retention rules, and product behavior differ. A repository protocol is more portable and auditable than cross-writing opaque memory databases.

## Coordination model

The default is user/orchestrator-mediated coordination. Direct agent-to-agent invocation may be added later, but only with explicit loop prevention, task ownership, and budget controls.
