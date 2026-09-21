# Contributing

Contributions should preserve these invariants:

- private agent memories remain private by default;
- Git remains a sufficient recovery path;
- every mutating workflow has validation and rollback;
- no uncontrolled recursive agent loops;
- public fixtures contain no real credentials or private transcripts;
- provider-specific adapters remain replaceable.
