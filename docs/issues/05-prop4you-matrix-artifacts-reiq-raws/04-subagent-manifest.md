# Subagent manifest

Max simultaneous subagents: 3
Allowed toolsets: file, terminal
Forbidden: provider calls, web/API calls, raw value/PII dumps, secrets, production mutation, payload commits.

Each worker must write status under `.tmp/prop4you-matrix-artifacts-reiq/subagents/<ID>-status.md`.
