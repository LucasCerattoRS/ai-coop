# Security

Do not report secrets or private memory content in public issues.

Report a suspected vulnerability through GitHub's **Security > Report a
vulnerability** flow for this repository. Do not create a public issue for it.

The following are security vulnerabilities when they allow a boundary to be
crossed:

- writing outside the repository;
- following a symlink where repository-only handling is required;
- escaping an intended path;
- a race in the handoff lock that corrupts or overwrites coordination data; or
- treating a handoff as an instruction that expands scope, permission, or access.

Feature requests, documentation mistakes, and validation errors that remain
contained within the repository boundary are not security vulnerabilities.

Security fixes are accepted only on `main`.
