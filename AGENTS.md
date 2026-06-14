# AGENTS.md — PG18 Database-Centric Platform

Status: ACTIVE_ENTRYPOINT
Audience: Hermes/Thor, Codex, Claude, Copilot and any other agent working in this repository.

## 1. Read this first

This repository is Karval's PostgreSQL 18 database-centric fork/original line derived from the open-source `supabase/postgres` image recipe.

Before changing anything, read in this order:

1. `README.md`
2. `llms.txt`
3. `llms-full.txt`
4. `docs/canonical-docs-index.md`
5. The task-specific docs listed by the canonical index.

Do not rely on chat memory alone. The repository docs are the operational source of truth.

## 2. Branch policy

The primary branch for this fork is `develop`.

Current PG18 work may happen on topic branches, but final accepted work should be merged/fast-forwarded into `develop` when verified.

Do not assume `main` exists or is canonical.

## 3. Current release identity

Current pure PG18 release:

```text
18.0.0.001-karval-pure-rc1
```

Meaning of pure:

- PostgreSQL 18 image/stack base.
- Supabase-style curated compiled extension surface.
- Local PostgREST/JWT/RLS proof.
- Local realtime v2 proof.
- HTML proof.
- No Prop4You/project DDL installed.
- No Strapi database.
- No production/VPS claim.

Release notes:

```text
docs/releases/18.0.0.001-karval-pure-rc1.md
```

## 4. Architecture rule

This project uses database-centric soft-DDD.

Canonical rule:

```text
docs/database-centric-soft-ddd-rule.md
```

Operational summary:

```text
schemas = domains / bounded contexts
tables = durable domain records
functions/RPCs = use cases / application actions
views/materialized views = read projections
policies = domain authorization rules
triggers/jobs = domain automations
api = public facade for PostgREST/client access
```

Do not model everything under `public`.
Do not expose raw domain tables to clients by default.
Do not bake project DDL into the reusable PG18 image.

## 5. Database image/stack vs DDL packages

Keep these layers separate:

```text
PG18 image/build recipe
  -> compiled database and extensions

Optional sibling stack services
  -> PostgREST, realtime bridge, HTML proof, future workers/gateways

Base DDL package
  -> reusable database-centric primitives

Project DDL packages
  -> Prop4You and later project schemas/RLS/RPCs/seeds
```

DDL root:

```text
database/ddl/
```

Base package:

```text
database/ddl/base/
```

Prop4You package:

```text
database/ddl/projects/prop4you/
```

The extraction of rules from Django apps must become framework-agnostic database-centric DDL. Do not create a `platform/django` package as the canonical target. Django, FastAPI, Kong, PostgREST or other gateways are consumers/transports, not owners of business truth.

## 6. Application Data Kernel context

Read:

```text
docs/pg18-application-data-kernel-context.md
```

The PG18 database is treated as an Application Data Kernel:

```text
transactional core
+ domain engine
+ event engine
+ JSONB contract engine
+ async operational engine
+ jobs/queue engine
+ integration/FDW hub
+ search/geo/AI extension surface
```

Important distinction:

```text
PG18 AIO = storage/read/maintenance I/O improvement.
Operational async = pgmq, pg_cron, pg_net, outbox, LISTEN/NOTIFY and external workers.
```

## 7. Prop4You context

Read:

```text
docs/prop4you-database-centric-base-extraction.md
docs/prop4you-core-db-to-ddl-analysis.md
```

Prop4You sources to analyze together:

- `app.prop4you.com` — older/base Django app surface.
- `prop4you-inertia` — evolved domain-oriented implementation.

Extract the best working rules from both, but convert them into framework-agnostic database-centric packages.

Canonical Prop4You truths:

```text
Lead Finder defines the canonical graph.
Matrix governs semantic meaning and mapping artifacts.
SourceHub owns ingress, lineage and canonical DTO publication.
Skip Trace enriches; it does not define owner/property truth.
Situations are structured facts, not tags.
Raw lineage, snapshots and operational truth remain distinct.
```

## 8. Realtime proof

Realtime v2 is local proof, not production claim.

Smoke command:

```bash
scripts/smoke-pg18-realtime-v2.sh --keep-stack
```

HTML proof when running:

```text
http://127.0.0.1:18083/
```

## 9. Safety and operational rules

- Do not print secrets.
- Do not assume prod/VPS without explicit scope.
- Do not create databases just to silence logs.
- Do not mutate Strapi or other services unless asked.
- Prefer scoped commits; never use broad `git add .` in dirty repos.
- Verify runtime claims with tools before reporting completion.
- If changing GitHub releases/tags/default branches, verify remotes and tag peeled commits.

## 10. Next recommended work

Current next slice:

```text
DDL installer + base install tracking
```

Expected direction:

```text
scripts/apply-ddl-package.sh
database/ddl/base/0001_install_tracking.sql
framework-agnostic base capabilities extracted from Prop4You/Django history
Prop4You project DDL inventory
```

## Active DDL installer slice

Before working on the DDL installer/base substrate, read:

```text
docs/ddl-installer-prd.md
docs/ddl-installer-tasks.md
```

Key current rules:

- Public references use prefix registry + uuid7 pointer semantics, not the old random 24-character suffix.
- Preserve the PG18 extension inventory; do not regress image extensions from DDL work.
- Base DDL now includes `database/ddl/base/0002_extensions.sql`; extension enablement is target-database DDL-owned and recorded in `base.extension_install_results`.
- `pg18_ddl_lab` is the canonical local clean database for DDL/script proof runs via `scripts/proof-ddl-base-lab.sh`.
- Multi-product cron policy: keep `cron.database_name=postgres`; product DBs such as `p4y` or lead-capture DBs use `cron.schedule_in_database(...)` from `postgres` and record `pg_cron` as `skipped_by_cron_database_name` locally.
- Database-centric methodology: every DDL/runtime/script/policy change must evolve the relevant documentation in the same work cycle. Update the nearest entrypoint (`AGENTS.md`, `README.md`, `llms.txt`, `llms-full.txt`), the canonical index, and task/proof docs when the change affects future operators.
