# Final Report — system/LFG topology and workspace boundary

Status: delivered after browser proof; commit pending at report write time
Updated: 2026-06-18T11:01:56
Reviewer: Thor/default

## Verdict

The architecture now explicitly treats LFG/legacy `system` as an internal external-like system that supplies versioned intelligence to the P4Y user workspace. The user workspace consumes refs/snapshots/versions/hashes and owns local annotations/usage, not global LFG truth.

## Delivered

```text
docs/issues/11-prop4you-system-schema-lfg-topology/08-system-user-boundary-review.md
docs/issues/11-prop4you-system-schema-lfg-topology/09-postgres-topology-fdw-review.md
docs/issues/11-prop4you-system-schema-lfg-topology/10-tags-labels-markers-review.md
docs/issues/11-prop4you-system-schema-lfg-topology/11-system-lfg-workspace-topology-architecture.md
```

## Core decisions

- LFG/system is an upstream/internal service boundary.
- Workspace is a snapshot/ref/usage/annotation boundary.
- Tags/labels/markers with same visible names are not duplicates if owner/scope/version differ.
- FDW is allowed for point lookup, snapshot transaction, and version/hash checks; not for heavy cross-node joins/live dashboards.
- High-ingestion LFG can move to dedicated Postgres instance when load/retention/WAL/VACUUM/blast-radius justify it.
- Async provider/realtime/workers should be decoupled from hot user transactions.

## Non-claims

- No production deploy change.
- No FDW credential/user mapping DDL.
- No workspace DDL implementation.
- No provider calls.
- No runtime/browser product API proof beyond static architecture browser-proof.


## Browser proof

PASS. See `06-browser-proof.md`.
