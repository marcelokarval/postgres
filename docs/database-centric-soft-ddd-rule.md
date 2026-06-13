# Database-Centric Soft-DDD Project Rule

Status: ACTIVE_PROJECT_RULE
Date: 2026-06-13
Scope: PG18 database-centric platform and project DDL packages

## 1. Executive rule

This project uses **database-centric soft-DDD** as its operational modeling rule.

The database is not organized as a generic technical dump under `public.*`. It is organized by domain boundaries and operational capabilities.

Core rule:

```text
schemas = domains / bounded contexts
tables = entities, ledgers, snapshots, queues or operational records inside a domain
functions/RPCs = use cases / application actions
views/materialized views = read projections
policies = domain authorization rules
triggers/jobs = domain automations
audit/realtime tables = durable operational infrastructure
api schema = public facade for PostgREST/client access
```

This is soft-DDD, not academic/pure object-oriented DDD inside Postgres. PostgreSQL should not simulate classes or aggregates mechanically. It should express durable domain boundaries, data ownership, invariants, access rules and use cases.

## 2. What this prevents

Avoid this pattern:

```text
public.users
public.properties
public.leads
public.skip_trace_results
public.matrix_mappings
public.source_records
```

That creates a public-schema monolith with weak ownership and unclear boundaries.

Prefer this pattern:

```text
identity.*
property.*
leadfinder.*
matrix.*
sourcehub.*
skiptrace.*
realtime.*
billing.*
audit.*
api.*
```

## 3. Meaning of each object type

### Schemas

Schemas represent domain boundaries / bounded contexts.

Examples:

```text
identity
property
leadfinder
matrix
sourcehub
skiptrace
realtime
billing
audit
api
```

### Tables

Tables represent durable records inside a domain. A table is not automatically an "app" by itself.

A table can be:

- entity table;
- relationship table;
- ledger;
- event/outbox table;
- operational queue;
- snapshot;
- provider run table;
- audit/change table;
- projection backing table.

Example:

```text
skiptrace.requests
skiptrace.provider_runs
skiptrace.results
skiptrace.candidate_contacts
```

Together, these support the skip trace capability.

### Functions and RPCs

Functions represent domain use cases and application actions.

Internal/domain functions should live in the domain schema when they implement domain behavior.

Client-facing RPCs should live in the `api` schema as a stable facade.

Example:

```text
skiptrace.create_request(...)
skiptrace.record_provider_result(...)
api.run_skiptrace(...)
api.get_skiptrace_status(...)
```

### Views and materialized views

Views represent read models/projections.

Example:

```text
leadfinder.lead_score_view
sourcehub.canonical_owner_projection
api.lead_list_summary
```

### Policies

RLS policies represent domain authorization boundaries. Authorization belongs close to the data it protects.

Example:

```text
property.properties_rls
leadfinder.lead_lists_rls
skiptrace.requests_rls
```

### Triggers/jobs

Triggers and scheduled jobs represent domain automation, but must stay auditable and deterministic.

Examples:

```text
sourcehub.publish_canonical_record()
realtime.notify_event_outbox()
audit.capture_change()
```

## 4. API facade rule

Clients should not call domain tables directly.

Preferred client boundary:

```text
api.*
```

PostgREST should expose controlled RPCs/views from `api`, while domain schemas remain internal or selectively granted.

Example client-facing functions:

```text
api.current_profile()
api.search_properties(...)
api.create_lead_list(...)
api.run_skiptrace(...)
api.subscribe_scope(...)
```

The `api` schema is a facade. It may call domain functions internally:

```text
identity.*
property.*
leadfinder.*
matrix.*
sourcehub.*
skiptrace.*
realtime.*
```

This keeps the client contract stable when internal domain modeling changes.

## 5. Prop4You domain map

Prop4You is the first intended project DDL consumer of the PG18 platform.

Initial bounded contexts:

```text
identity
  users, accounts, organizations, memberships, roles, sessions

property
  properties, owners, owner-property links, addresses, APN/parcel/county/state facts

leadfinder
  lead lists, searches, scoring, ICP, opportunities

matrix
  semantic maps, situations, mapping artifacts, normalization rules

sourcehub
  ingress, raw records, lineage, snapshots, canonical DTO publication

skiptrace
  enrichment requests, provider calls, candidate contacts, rankings, results

realtime
  outbox, subscriptions, cursors, ACKs, scope membership hooks

billing / usage
  plans, credits, usage, limits, ledgers

audit
  operational audit and change history
```

Canonical Prop4You truths:

```text
Lead Finder defines the canonical graph.
Matrix governs semantic meaning and mapping artifacts.
SourceHub owns ingress, lineage and canonical DTO publication.
Skip Trace enriches; it does not define owner/property truth.
Situations are structured facts, not tags.
Raw lineage, snapshots and operational truth remain distinct.
```

## 6. Realtime naming rule

Realtime topics should follow:

```text
<domain>.<entity_or_use_case>.<event>
```

Examples:

```text
leadfinder.lead_list.created
skiptrace.request.completed
sourcehub.record.published
matrix.mapping.updated
property.owner.linked
```

Scopes should represent domain access boundaries:

```text
org/<org_id>
property/<property_id>
lead_list/<lead_list_id>
skiptrace_request/<request_id>
room/<room_id>
```

The realtime transport remains generic. Project-specific scope authorization belongs in project DDL functions/tables.

## 7. DDL package rule

The reusable PG18 base image/stack must stay project-neutral.

Project modeling lives in ordered SQL packages:

```text
database/ddl/base/
database/ddl/projects/prop4you/
```

Recommended early Prop4You sequence:

```text
0001_identity_schema.sql
0002_identity_tables.sql
0003_property_schema.sql
0004_property_tables.sql
0005_matrix_schema.sql
0006_sourcehub_schema.sql
0007_leadfinder_schema.sql
0008_skiptrace_schema.sql
0009_realtime_scopes.sql
0010_api_facade.sql
0011_rls_policies.sql
0012_seed_reference_data.sql
```

The exact sequence may change after inherited scripts are inventoried, but the ordering must remain explicit and versioned.

## 8. Naming conventions

Schemas:

```text
singular or domain-name snake_case: identity, property, leadfinder, sourcehub
```

Tables:

```text
plural snake_case: lead_lists, provider_runs, candidate_contacts
```

Functions:

```text
verb_object: create_lead_list, record_provider_result, publish_canonical_record
```

Client-facing RPCs:

```text
api.<verb_object>
```

Events:

```text
<domain>.<entity_or_use_case>.<event>
```

## 9. Non-goals

- Do not model everything under `public`.
- Do not expose raw domain tables directly to clients by default.
- Do not bake Prop4You or any project schema into the reusable PG18 image.
- Do not treat every table as an independent application.
- Do not force object-oriented aggregate patterns where relational modeling is clearer.

## 10. Rule summary

```text
Use soft-DDD for database-centric modeling.
Schemas are domains.
Tables are durable domain records.
Functions/RPCs are use cases.
Views are projections.
Policies are domain authorization.
Triggers/jobs are domain automation.
api is the public facade.
DDL packages are ordered, versioned and installed after the base PG18 runtime is running.
```
