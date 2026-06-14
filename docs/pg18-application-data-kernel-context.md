# PG18 Application Data Kernel Context

Status: ACTIVE_CONTEXT
Source: user-provided database-centric PG18 discussion, normalized into project guidance.

## 1. Core framing

For this repository, PostgreSQL 18+ with a Supabase-style extension surface is treated as an **Application Data Kernel**.

That means:

```text
Postgres 18+
  = transactional core
  + domain engine
  + event engine
  + JSONB contract engine
  + async operational engine
  + jobs/queue engine
  + integration/FDW hub
  + search/geo/AI extension surface
```

This is database-only/database-centric. It does not assume the full hosted Supabase stack.

Not automatically included by the DB image alone:

```text
Auth
PostgREST
Realtime
Storage
Edge Functions
Studio
API Gateway
```

But the database-centric kernel can use:

```text
PL/pgSQL
RLS
triggers/procedures/constraints
JSONB / SQL-JSON / JSON_TABLE
FDW
logical replication / wal2json
pgmq
pg_cron
pg_net
vector
PostGIS
pgaudit
pg_jsonschema
observability extensions
```

## 2. Important project correction

The upstream `supabase/postgres` project is PostgreSQL plus curated extensions; it is not a modified PostgreSQL engine fork.

Karval's PG18 line exists because the upstream public image line did not provide a stable PG18 release at the time this work was created. This repository is the Karval-controlled PG18 original/fork line for image/build/runtime proof.

Always verify actual extension availability in the final container with:

```sql
select * from pg_available_extensions;
```

## 3. PG18 AIO vs operational async

PG18 Async I/O is a storage/read/maintenance improvement.

It helps scenarios such as:

```text
large append-only tables
event scans
snapshot scans
materialized view refreshes
VACUUM / maintenance
bitmap heap scans
large JSONB/GIN maintenance windows
```

It is not:

```text
async/await in PL/pgSQL
non-blocking triggers
HTTP inside transaction safety
magic FDW network acceleration
```

Operational async remains:

```text
pgmq          durable queues
pg_cron       scheduling
pg_net        async HTTP after commit
LISTEN/NOTIFY lightweight signaling
outbox        durable event source
workers       external execution
```

## 4. JSONB rule

JSONB is central for payloads, integration and event contracts, but it must not replace strong relational modeling.

Use:

```text
relational columns
  identity, joins, constraints, filters, indexes

JSONB
  raw payloads, external metadata, rare/flexible attributes

generated columns STORED
  JSONB fields that become indexed/filterable/joinable

JSON_TABLE
  converting complex payloads into staging/read-model rows

GIN/expression indexes
  containment/path queries

materialized views
  heavy recurring reads
```

Do not build a Mongo-style schema inside Postgres.

## 5. PG18 features to use deliberately

### uuidv7

Prefer:

```sql
id uuid primary key default uuidv7()
```

for append-heavy, public/technical IDs:

```text
events
queues
logs
snapshots
activity records
integration records
```

### JSON_TABLE

Use `JSON_TABLE` for staging/intelligence transformations from JSON payloads into relational rows.

Good targets:

```text
webhooks
checkout events
WhatsApp/messages
Chatwoot snapshots
Evolution snapshots
external enrichment payloads
integration logs
```

### Generated columns

Rule:

```text
virtual generated column
  projection/debug/low-frequency read

stored generated column
  indexing/filtering/joining/sorting/performance
```

### OLD/NEW RETURNING

Use PG18 `OLD`/`NEW` in `RETURNING` to generate domain events with before/after state without excessive triggers or duplicate queries.

### Skip scan / parallel GIN

Useful for hybrid relational+JSONB models, but index design must still be based on real queries and `EXPLAIN ANALYZE`.

## 6. Multi-database + FDW rule

Use:

```text
multi-schema
  for our own application/database-centric system

multi-database
  for external/third-party systems

FDW
  for controlled reads/correlation

staging/materialized views
  for dashboards/intelligence/recurring heavy reads

outbox + pgmq/workers
  for consistency and side effects
```

FDW is not a magic distributed transaction layer.

Use FDW for:

```text
small lookups
controlled correlation
snapshot building
materialized view refresh inputs
```

Avoid FDW for:

```text
critical distributed writes
heavy live joins
dashboards directly over foreign tables
strong cross-database transaction assumptions
```

## 7. Recommended data flow

Integration input:

```text
raw payload
  -> event.inbox
  -> pg_jsonschema validation
  -> domain command function
  -> relational domain tables
  -> event.domain_event
  -> outbox/pgmq
  -> workers/staging/intelligence/read models
```

Core principle:

```text
raw lineage, operational snapshots and canonical truth are distinct.
```

## 8. Security without full Supabase stack

Do not depend on deprecated or non-core extensions for central auth.

Avoid making these central:

```text
pgjwt
pgsodium
plv8
timescaledb
```

Preferred model:

```text
gateway/app authenticates
Postgres authorizes with RLS
request context enters via transaction-scoped settings or verified RPC input
PL/pgSQL executes domain use cases
pgaudit/audit tables record critical actions
```

Example context pattern:

```sql
set local app.tenant_id = '...';
set local app.actor_id = '...';
set local app.actor_role = '...';
```

Then RLS checks current settings or validated claims.

## 9. Extension categories

Think of extensions by purpose:

```text
domain/contract
  pg_jsonschema, plpgsql_check, pgtap

async
  pgmq, pg_cron, pg_net

integration/CDC
  postgres_fdw, wrappers, wal2json

search/AI
  vector, pgroonga, rum

geo
  postgis, pgrouting

security/ops
  vault, pgaudit, pg-safeupdate, pg_plan_filter, supautils

performance/observability
  pg_stat_statements, pg_stat_monitor, hypopg, index_advisor, pg_repack
```

## 10. Application Data Kernel verdict

The strongest architecture is not "everything in JSONB" and not "schemas only".

It is:

```text
strong relational core
+ validated JSONB payloads
+ append-only events
+ FDW for external databases
+ local snapshots/read models
+ intelligence layer
+ pgmq/pg_cron/pg_net operational async
+ PG18 AIO sustaining scans and maintenance
```

Final framing:

```text
In PG18, the database becomes the operational kernel of business intelligence: events enter as JSONB, become relational domain truth, correlate via FDW and snapshots, process asynchronously through queues/jobs, and surface as consistent read models.
```
