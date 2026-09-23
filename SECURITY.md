# Security

Do not report secrets or private memory content in public issues.

Report a suspected vulnerability through GitHub's **Security > Report a
vulnerability** flow for this repository. Do not create a public issue for it.

The following are security vulnerabilities when they allow a boundary to be
crossed:

- writing outside the repository;
- following a symlink where repository-only handling is required;
- escaping an intended path; or
- treating a handoff as an instruction that expands scope, permission, or access.

Feature requests, documentation mistakes, and validation errors that remain
contained within the repository boundary are not security vulnerabilities.
The same goes for a stale handoff lock left behind by a crash such as `kill -9`:
`scripts/handoff.sh` takes the lock with an atomic `mkdir`, so a lost race fails
immediately and corrupts nothing. A dead lock only blocks new handoffs for that
task until someone removes it by hand with `rmdir` (see `docs/SPEC-v0.1.md`),
which is an availability issue, not a boundary crossing.

Security fixes are accepted only on `main`.
