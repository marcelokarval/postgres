# Database-Centric App Model

Status: ACTIVE
Date: 2026-06-14

## Purpose

This document defines how this PG18 project models "apps" in a database-centric architecture.

In the old Django-centric model, an app was a Python package containing models, services, managers, serializers, signals, Celery tasks, admin actions, and permissions. In the database-centric model, an app becomes a governed database module: schemas, tables, functions, triggers, policies, views, jobs, events, and documentation.

Prop4You is used here as the first concrete example, but this document is not Prop4You-specific. The same pattern applies to other product databases or app modules such as lead capture, UTM tracking, notifications, billing, realtime, or future vertical products.

## Core translation

```text
Django app
  -> database-centric app / domain module
  -> schema + tables + functions + triggers + policies + views + jobs + events
```

For a small app, the module can be only one table plus helper functions:

```text
Django model or simple app
  -> one durable table
  -> lifecycle triggers
  -> public ID prefix registration
  -> optional audit/realtime/API facade
```

The important distinction: database-centric apps do not inherit Python classes. They adopt database contracts.

```text
Python inheritance
  becomes
DDL-level composition by columns, constraints, triggers, registry entries, functions, policies, audit, and events.
```

## App definition

A database-centric app is an ordered DDL package or a bounded section of one ordered DDL package.

Canonical locations:

```text
database/ddl/base/                 shared platform substrate
database/ddl/projects/prop4you/    first product package
database/ddl/projects/<product>/   future product packages
```

Potential future app/capability packages:

```text
database/ddl/apps/lead_capture/
database/ddl/apps/utm_tracker/
database/ddl/apps/notifications/
```

Default recommendation for now: keep Prop4You as one project package until boundaries stabilize, then split into subpackages only when volume and ownership justify it.

## Base substrate

The `base` package is not a business app. It is the platform contract every app can use.

Current base capabilities include:

```text
base.ddl_migrations
base.extension_install_results
base.public_id_prefix_registry
base.register_public_id_prefix(...)
base.make_public_ref(...)
base.parse_public_ref(...)
base.resolve_public_ref(...)
base.set_local_context(...)
base.current_context()
base lifecycle helpers
base JSONB helpers
base search normalization helpers
audit.log
realtime.event_outbox
realtime.event_acks
api.health()
api.current_context()
api.ddl_status()
```

An app does not inherit `base` as an object-oriented parent class. It uses `base` through explicit DDL composition:

```text
standard columns
lifecycle triggers
public ID registry
audit hooks
realtime/outbox hooks
context helpers
JSON/search helpers
API facade functions
jobs functions
policies
```

## Why not PostgreSQL table inheritance by default

PostgreSQL supports table inheritance with `INHERITS`, but it is not the default pattern for this project.

Avoid this as the normal app model:

```sql
create table property.property (...) inherits (base.entity);
```

Reasons:

```text
1. constraints and foreign keys are harder to govern;
2. RLS/policies become less obvious;
3. PostgREST/API introspection can become confusing;
4. migration and schema review become more fragile;
5. PostgreSQL inheritance is not equivalent to Python/Django inheritance;
6. multi-product maintainability suffers.
```

Preferred pattern:

```text
explicit columns + explicit triggers + explicit registry + explicit functions + explicit policies.
```

This is more verbose, but it is auditable and safer for a database-as-product-kernel architecture.

## Django to database-centric mapping

```text
Django app
  -> schema or ordered DDL package

Django model
  -> table

Django abstract BaseModel
  -> standard columns + lifecycle triggers + public ID registry + audit/realtime conventions

Django mixin
  -> reusable column/constraint/trigger/function pattern

Django manager / queryset
  -> view, materialized view, or read function

Model.clean() / validators
  -> CHECK constraints, domains, JSON schema validation, trigger validation, or command function validation

Model.save()
  -> command function or trigger, depending on semantics

Service class
  -> SQL/PLpgSQL function in domain schema, or public function in api schema

Serializer
  -> api view/function returning stable JSONB

DRF ViewSet
  -> api.* RPC function or controlled view exposed by PostgREST/gateway

Django signal
  -> trigger + audit.log + realtime.event_outbox

Celery task
  -> pg_cron + pgmq + jobs schema/function

Django admin action
  -> operational SQL function with audit

Permission class
  -> RLS policy + authorization helper function

Soft delete manager
  -> deleted_at + views/policies/functions filtering active rows
```

## Standard durable entity contract

A durable entity table should normally include:

```sql
id uuid primary key default uuidv7(),
created_at timestamptz not null default now(),
updated_at timestamptz not null default now(),
deleted_at timestamptz,
version bigint not null default 1,
metadata jsonb not null default '{}'::jsonb
```

Then attach lifecycle behavior:

```sql
create trigger <table>_set_lifecycle_defaults
before insert on <schema>.<table>
for each row execute function base.set_lifecycle_defaults();

create trigger <table>_touch_updated_at
before update on <schema>.<table>
for each row execute function base.touch_updated_at();

create trigger <table>_increment_version
before update on <schema>.<table>
for each row execute function base.increment_version();
```

Register the public reference prefix:

```sql
select base.register_public_id_prefix(
  p_prefix := '<prefix>',
  p_schema_name := '<schema>',
  p_table_name := '<table>',
  p_entity_name := '<entity>',
  p_id_column := 'id'
);
```

Public references use this canonical shape:

```text
<prefix>_<uuid7>
```

Example:

```text
prop_019ec6c7-40c0-7a5a-81e5-1224f2ed2c27
lead_019ec6c7-40c0-7a5a-81e5-1224f2ed2c27
```

## Example: property table

```sql
create schema if not exists property;

create table property.property (
  id uuid primary key default uuidv7(),

  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  deleted_at timestamptz,
  version bigint not null default 1,
  metadata jsonb not null default '{}'::jsonb,

  address_line1 text not null,
  city text,
  state text,
  postal_code text
);

create trigger property_set_lifecycle_defaults
before insert on property.property
for each row execute function base.set_lifecycle_defaults();

create trigger property_touch_updated_at
before update on property.property
for each row execute function base.touch_updated_at();

create trigger property_increment_version
before update on property.property
for each row execute function base.increment_version();

select base.register_public_id_prefix(
  p_prefix := 'prop',
  p_schema_name := 'property',
  p_table_name := 'property',
  p_entity_name := 'property',
  p_id_column := 'id'
);
```

## Example: single-table app

A small app does not need a large schema. Example: UTM/event tracking.

```sql
create schema if not exists tracking;

create table tracking.utm_event (
  id uuid primary key default uuidv7(),

  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  deleted_at timestamptz,
  version bigint not null default 1,
  metadata jsonb not null default '{}'::jsonb,

  source text,
  medium text,
  campaign text,
  content text,
  term text,
  payload jsonb not null default '{}'::jsonb
);

create trigger utm_event_set_lifecycle_defaults
before insert on tracking.utm_event
for each row execute function base.set_lifecycle_defaults();

create trigger utm_event_touch_updated_at
before update on tracking.utm_event
for each row execute function base.touch_updated_at();

create trigger utm_event_increment_version
before update on tracking.utm_event
for each row execute function base.increment_version();

select base.register_public_id_prefix(
  p_prefix := 'utm',
  p_schema_name := 'tracking',
  p_table_name := 'utm_event',
  p_entity_name := 'utm_event',
  p_id_column := 'id'
);
```

API facade example:

```sql
create or replace function api.track_utm_event(p_payload jsonb)
returns jsonb
language plpgsql
as $$
declare
  v_id uuid;
begin
  insert into tracking.utm_event(payload)
  values (p_payload)
  returning id into v_id;

  return jsonb_build_object(
    'ok', true,
    'id', v_id,
    'public_ref', base.make_public_ref('utm', v_id)
  );
end;
$$;
```

## Domain schema vs api schema

Keep domain truth separate from public/client contracts.

```text
property.*        internal domain truth
leadfinder.*      internal domain truth
sourcehub.*       internal domain truth
skiptrace.*       internal domain truth
api.*             public facade / RPC / client contract
```

Preferred flow:

```text
client/web/desktop/mobile
  -> PostgREST / Django pass-through / gateway
  -> api.create_property(...)
  -> property.create_property(...)
  -> property.property + audit.log + realtime.event_outbox
```

Rules:

```text
api = facade
schema/domain = durable truth
audit/realtime/base = transversal capabilities
gateway = transport, not owner of business truth
```

## Audit pattern

`audit` is transversal and durable. A domain function or trigger should record meaningful mutations.

```sql
select audit.record_log(
  p_action := 'update',
  p_schema_name := 'property',
  p_table_name := 'property',
  p_object_id := v_id::text,
  p_old_data := old_json,
  p_new_data := new_json
);
```

Prefer explicit command functions for critical actions:

```text
property.transfer_ownership(...)
  validates
  changes state
  writes audit.log
  emits realtime event
  returns stable JSONB payload
```

## Realtime/event pattern

`realtime` is the event/outbox substrate, not the source of truth.

The app changes durable domain tables first, then emits a durable event:

```text
property.property = truth
realtime.event_outbox = event for downstream transport
LISTEN/NOTIFY = signal
WebSocket/SSE/push = external delivery
```

Future helper shape:

```sql
select realtime.publish_event(...);
```

Until then, domain functions can insert into `realtime.event_outbox` directly or via a domain wrapper.

## Jobs pattern

For multi-product/multi-database PG18, keep `cron.database_name=postgres` as the central scheduler database.

Product databases expose stable job functions:

```sql
create schema if not exists jobs;

create or replace function jobs.tick()
returns void
language plpgsql
as $$
begin
  -- process product-owned outbox/queue/maintenance here
end;
$$;
```

Register from database `postgres`:

```sql
select cron.schedule_in_database(
  'p4y-jobs-tick',
  '* * * * *',
  'select jobs.tick();',
  'p4y'
);
```

Product/lab databases record `pg_cron` as `skipped_by_cron_database_name` and do not install it directly unless runtime policy changes.

## Prop4You initial domain examples

Prop4You is the first concrete project example. Likely bounded contexts:

```text
identity
property
leadfinder
sourcehub
matrix
skiptrace
billing
```

Base/facade/transversal schemas already exist or are shared:

```text
base
audit
realtime
api
```

Potential Prop4You tables:

```text
identity.account
identity.user_profile

property.property
property.owner
property.address
property.property_owner

leadfinder.lead
leadfinder.lead_score
leadfinder.lead_event

sourcehub.source_record
sourcehub.ingest_batch
sourcehub.lineage

skiptrace.request
skiptrace.result
skiptrace.candidate_contact

matrix.semantic_rule
matrix.enrichment_signal

billing.account
billing.plan
billing.usage_ledger
```

Canonical business-truth boundaries:

```text
Lead Finder defines the canonical graph.
Matrix governs semantic meaning.
SourceHub owns ingress, lineage, and DTO publication.
Skip Trace enriches but must not define owner/property truth.
Billing owns account/plan/usage truth.
```

## Standard creation flow for a new database-centric app

```text
1. Define bounded context.
2. Create schema.
3. Create durable tables.
4. Apply base entity contract where appropriate.
5. Register public ID prefixes.
6. Add constraints and indexes.
7. Add domain command functions.
8. Add read views/projections.
9. Add api facade functions/views.
10. Add audit/realtime hooks.
11. Add jobs functions if needed.
12. Add RLS/policies if exposed or multi-tenant.
13. Test in pg18_ddl_lab.
14. Update docs in the same work cycle.
```

## Suggested package shape

Start simple:

```text
database/ddl/projects/prop4you/
  README.md
  0001_schemas.sql
  0002_identity_tables.sql
  0003_property_tables.sql
  0004_leadfinder_tables.sql
  0005_public_id_registry.sql
  0006_lifecycle_triggers.sql
  0007_audit_realtime_hooks.sql
  0008_api_functions.sql
  0009_jobs.sql
  0010_policies.sql
```

Split by module only when it improves ownership/review:

```text
database/ddl/projects/prop4you/property/
  0001_schema.sql
  0002_tables.sql
  0003_public_ids.sql
  0004_functions.sql
  0005_api.sql
  0006_tests.sql
```

## Avoid premature generator abstraction

Do not start with a generator. Write explicit DDL first.

After 3 or 4 apps repeat the same patterns, consider helpers/generators:

```sql
base.register_entity_table(...)
base.attach_lifecycle_triggers(...)
base.attach_audit_trigger(...)
base.attach_realtime_trigger(...)
```

Or a manifest-driven generator:

```yaml
entity: property
schema: property
table: property
prefix: prop
lifecycle: true
audit: true
realtime: true
metadata: true
soft_delete: true
```

But the current rule is explicit DDL for auditability.

## Completion checklist

A database-centric app is not considered complete until it has:

```text
schema/tables created
base contract applied
public IDs registered when entity is public/durable
indexes/constraints reviewed
command functions for mutations
api facade for external clients
audit for meaningful changes
realtime/outbox if downstream consumers need events
jobs if async/scheduled work exists
RLS/policies if exposed or tenant-bound
functional proof in pg18_ddl_lab or another clean lab DB
documentation updated in the same work cycle
```

## Prop4You provider-payload addendum

For Prop4You and provider-heavy apps, do not freeze tables directly from Django models. Treat Django/Inertia models as evidence and compare provider/internal JSON payloads first. Preserve raw payloads in JSONB with lineage, normalize through mapper-versioned projections, promote only Matrix/LeadFinder-approved semantics into canonical facts/tables, and add generated/projected JSONB-path fields only after path stability and query need are proven. See `docs/issues/00-prop4you-database-centric-extraction-plan/`.

## Prop4You provider corpus gate

For Prop4You, final project DDL must be gated by the provider payload corpus comparison stack in `docs/issues/01-prop4you-provider-payload-corpus/`. REIQ is the current/base data source, DirectSkip is the owner/contact enrichment source, Realtor.com is the broad property enrichment source, and internal/product-originated payloads provide supporting evidence. Use package + subpackages under `database/ddl/projects/prop4you/`; do not freeze final tables before Matrix dictionary review of representative JSON paths.
