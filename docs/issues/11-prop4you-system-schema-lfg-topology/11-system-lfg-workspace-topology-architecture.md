# Architecture — System/LFG topology and user workspace boundary

Status: accepted-for-current-model
Updated: 2026-06-18T11:01:56
Reviewer: Thor/default

## Executive verdict

The legacy Django `system` area must be interpreted as evidence of a separate internal system boundary, not as a reason to collapse LFG into the logged-in user's workspace tables.

Canonical split:

```text
LFG / system-like internal upstream
  = intelligence, raw-derived facts, provider/public-record/contact evidence, quality, source taxonomy, Matrix/LeadFinder semantics, DTO/materialization versions, global markers

P4Y logged-in user workspace
  = selected refs, snapshots, local analysis state, usage, billing/export evidence, user/team annotations, local tags/labels/markers, refresh decisions
```

LFG behaves like a third-party/internal upstream serving information to P4Y. The user workspace consumes it by stable IDs, public refs, version/hash, and snapshot contracts.

## Why this matters

The same human label can appear on both sides without being duplicated:

```text
dnc
wrong
bad phone
hot
qualified
probate
tax deed
property
owner
contact
lead
```

The name is not the owner. The owner is determined by:

```text
scope
owner_context
authority
lineage
version/hash
audit source
refresh policy
who can edit it
```

## Domain lanes

```text
Lane A — LFG/System ingest and intelligence
  providers/public records/lists
  -> SourceHub raw_records / lineage / translated DTOs
  -> Matrix mapping/quality artifacts
  -> LeadFinder dictionary/gaps/promotions
  -> LFG staging/materialization/operational minimum

Lane B — Hot user workspace
  logged-in user/account/workspace
  -> selected LFG refs
  -> compact snapshots
  -> local tags/labels/notes/campaign decisions
  -> refresh/update choices based on LFG version/hash

Lane C — Async/integration control plane
  domain event/outbox
  -> pgmq/jobs/pg_cron/workers/pg_net where appropriate
  -> realtime/read models/notifications
```

## Multi-Postgres posture

Start as multi-schema while boundaries stabilize. Move LFG/SourceHub/Matrix to dedicated database/instance when load proves it:

```text
trigger conditions:
- ingestion/backfill affects workspace p95/p99 latency;
- raw/staging/materialization tables need different retention/VACUUM/index maintenance;
- Matrix/DTO reprocessing creates WAL/IO spikes;
- LFG operators need distinct permissions/blast-radius;
- dashboard/read-model refreshes compete with hot user OLTP.
```

Target topology when separated:

```text
p4y_hot / workspace DB
  - account/user/workspace/session/product-facing OLTP
  - selected refs and snapshots
  - user annotations/campaign state
  - tenant RLS/API facade

lfg_system DB
  - SourceHub raw/DTO
  - Matrix artifacts
  - LeadFinder dictionary
  - LeadFinder Group staging/materialization/operational projections
  - high-ingestion and reprocessing workload

postgres scheduler/control DB
  - central pg_cron policy
  - schedules that call stable functions in product/system DBs
```

## FDW policy

FDW is allowed for surgical contracts, not broad distributed analytics.

Allowed:

```text
point lookup by UUID/public_ref/hash
snapshot transaction for explicitly selected records
version/hash freshness check
controlled refresh of local read model with limit/cursor/timeout
operator/admin inspection
```

Avoid/prohibit in hot paths:

```text
heavy cross-node joins
exact counts over huge foreign tables
dashboards directly over foreign tables
unbounded pagination over foreign tables
critical distributed writes that require pretending strong cross-node ACID is always safe
```

Preferred user flow:

```text
user requests snapshot/update
  -> workspace function checks LFG ref/version/hash via local snapshot or FDW point lookup
  -> creates/updates compact local snapshot
  -> records usage
  -> emits audit/realtime event
```

## Tags/labels/markers split

LFG/system markers:

```text
owner: LFG/system
meaning: evidence, quality, contactability, provenance, source taxonomy, global operational signal
examples: is_dnc from provider/compliance evidence, wrong/bad phone from systemic evidence, source list type, provider confidence
requires: lineage, source, observed_at/effective_at, confidence, version/hash, audit
```

Workspace markers:

```text
owner: tenant/user/workspace
meaning: decision, note, campaign workflow, local override, team-specific organization
examples: do-not-call-in-this-workspace, wrong-for-this-campaign, hot for my team, call later, my list
requires: workspace/account/user/campaign scope, audit, local visibility/RLS, optional feedback event
```

Never promote workspace feedback into global LFG truth without a review/promotion gate.

## Snapshot/versioned DTO contract

Future workspace snapshot rows should carry at minimum:

```text
workspace_id / account_id / user_id
lfg_group_id or lfg_public_ref
sourcehub_publication_id/public_ref when applicable
matrix_artifact_id/ref
dictionary_version_id
dto_contract_version
lfg_materialization_version
source_payload_sha256 / translated_dto_sha256 / snapshot_sha256
snapshot_taken_at
snapshot_status: current | stale_available | refresh_requested | refresh_failed | superseded | pinned
local_annotations_ref
usage/billing/export evidence
```

## Async/realtime posture

The database can coordinate async work, but OLTP transactions should not wait on slow external APIs.

Use:

```text
realtime.event_outbox
pgmq/job tables
pg_cron central scheduler
pg_net only for bounded async use cases
workers for rate limits/retries/providers when needed
```

Do not put provider-call latency inside user snapshot transaction.

## Implication for the next slice

Before creating full workspace tables, the next agreed technical slice can still be:

```text
LeadFinder dictionary promotion review/apply policy
```

But this policy must respect the new boundary:

```text
workspace feedback may create promotion candidates;
only reviewed system/LFG authority can apply global dictionary/marker changes.
```
