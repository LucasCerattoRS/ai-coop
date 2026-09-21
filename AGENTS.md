# Agent Cooperation Protocol

1. Read `.ai/STATUS.json`, `.ai/TASKS.md`, `.ai/DECISIONS.md`, and the relevant handoff before substantial work.
2. Never modify another agent's active worktree.
3. Use Git branches/worktrees for concurrent implementation.
4. Never access or merge another agent's private memory store unless the repository owner explicitly authorizes it.
5. Promote reusable knowledge only through `.ai/knowledge/`.
6. Before handoff, record scope, files changed, tests, unresolved risks, last commit, and next action.
7. Never recursively invoke another agent without an orchestrator/user-controlled boundary.
8. Repository state and recorded decisions outrank conversational recollection.
9. Never commit credentials, private transcripts, raw memory databases, or user secrets.
10. If state is ambiguous, stop and reconcile through Git and the coordination files.
