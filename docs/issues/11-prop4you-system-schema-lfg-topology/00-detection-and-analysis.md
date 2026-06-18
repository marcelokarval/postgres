# Detection and Analysis — system schema, LFG topology, user workspace boundary

Status: active
Created: 2026-06-18T10:56:16
Reviewer: Thor/default

## Trigger

Karval clarified that the legacy Django `system` schema/context is not simply the logged-in user's product schema. A large part of what belongs to the LFG group behaves like a separate system/service supplying information to P4Y users, with high ingestion volume and variable load.

## Extracted themes

- LFG/system behaves like an external-like upstream product/domain even if it is controlled internally.
- User logged-in workspace stores the user's selected/snapshotted property refs and analysis state.
- LFG stores provider/public-record/contact intelligence, tags/labels/phone markers and source versioning.
- Similar names in LFG/system and user workspace are not duplicates; they are different semantic contexts.
- High ingestion requires separation of heavy data work from hot user workload.
- Multiple Postgres instances/schemas may be used; FDW is acceptable for point-lookups and snapshot transactions, not heavy cross-node joins.
- Snapshot semantics should prefer version/hash comparison and explicit refresh/update requests.
- External calls/realtime/queues should remain decoupled from OLTP transactions.

## Scope

Repo-only architecture/specification slice. No production mutation. No provider calls. No runtime deploy change.
