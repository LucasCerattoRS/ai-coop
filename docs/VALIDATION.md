# Validation Strategy

A multi-agent setup is not considered safe because configuration looks correct. Validate behavior.

Recommended sequence:

1. Agent A alone.
2. Agent B alone.
3. Both agents simultaneously.
4. Verify there are no unexpected shared workers, servers, locks, caches, or writes.
5. Verify each agent can stop without corrupting shared state.
6. Verify rollback from a saved configuration backup.

For future releases, add automated smoke tests wherever possible.
