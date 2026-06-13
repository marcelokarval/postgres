# PG18 Database-Centric DDL Strategy

Status: ACTIVE_GUIDANCE
Date: 2026-06-12

## 1. Executive decision

The architecture must keep two concerns separate:

1. **Compiled database/stack base**
   - PostgreSQL 18 image based on the `supabase/postgres` build recipe.
   - Curated compiled extensions and preload configuration.
   - Optional sibling service layers such as PostgREST, web proof and realtime bridge.
   - Release identity by image tag/digest.

2. **Installed project/database DDL packages**
   - Versioned `.sql` files applied into a target database after the base DB/stack is running.
   - Shared base DDLs that can be installed for any project when appropriate.
   - Project-specific DDLs such as Prop4You schemas, policies, functions and data contracts.
   - Applied in explicit numeric order and tracked as source artifacts.

The compiled PG18 image must not become polluted with one product's project schema. The base image should be ready to host project DDLs; the project DDLs are installed later as controlled artifacts.


## 1.1 Database-centric soft-DDD rule

This DDL strategy follows the project rule documented in `docs/database-centric-soft-ddd-rule.md`.

Operational summary:

```text
schemas = domains / bounded contexts
tables = entities, ledgers, snapshots, queues or operational records inside a domain
functions/RPCs = use cases / application actions
views/materialized views = read projections
policies = domain authorization rules
triggers/jobs = domain automations
api schema = public facade for PostgREST/client access
```

The base PG18 image remains project-neutral. Soft-DDD modeling applies when DDL packages are installed into a running database.

## 2. Why this separation matters

The PG18 image answers:

```text
Can this database runtime start, expose extensions, preload hooks, and support the database-centric stack reliably?
```

The DDL packages answer:

```text
What schemas, tables, functions, RLS policies, jobs, views and contracts does this project install into a running database?
```

Conflating both would make the base image less reusable and harder to validate. Keeping them separate lets us:

- reuse the same PG18 image for multiple projects;
- pin and validate image digests independently from application schema migrations;
- install shared base DDLs only when the project needs them;
- version project DDLs in a deterministic order;
- run clean database install/reinstall proofs without rebuilding the image;
- model Prop4You as a consumer/project case rather than as part of the core PG18 image.

## 3. Layer model

```text
Layer 0 — PG18 image/build recipe
  Dockerfile-18, Nix packages, compiled extensions, preload libraries.

Layer 1 — Optional local stack services
  PostgREST, realtime WebSocket bridge, web proof, future workers.
  These connect to PG18 but are not baked into the database image.

Layer 2 — Shared base DDL package
  Common SQL primitives reusable across projects: app identity helpers,
  audit primitives, event/outbox primitives, standard schemas, utility functions.

Layer 3 — Project DDL package
  Prop4You or another project installs its own schemas, policies, functions,
  domain contracts and project-specific realtime scopes.

Layer 4 — Seed/reference data package
  Optional deterministic seed data, lookup tables and test fixtures.
```

## 4. Directory convention

Current starting convention:

```text
database/ddl/
  README.md
  base/
    README.md
    0001_*.sql
    0002_*.sql
  projects/
    prop4you/
      README.md
      0001_*.sql
      0002_*.sql
```

Rules:

- SQL files are numeric and ordered: `0001_name.sql`, `0002_name.sql`, etc.
- No hidden execution order.
- No `latest.sql` that changes meaning silently.
- Every file should be idempotent where reasonable, or explicitly marked as one-shot.
- Each project gets its own subtree.
- Project DDLs may depend on base DDLs, but base DDLs must not depend on project DDLs.
- Destructive changes require explicit review and should not be mixed with additive DDL.

## 5. Prop4You as first real project case

Prop4You is the right first case for real scopes because it already has domain boundaries that matter:

- Lead Finder defines canonical graph truth.
- Matrix governs semantic meaning and mappings.
- SourceHub owns ingress, lineage and canonical DTO publication.
- Skip Trace enriches; it does not define owner/property truth.

Therefore, Prop4You-specific DDLs should live under:

```text
database/ddl/projects/prop4you/
```

They should define project scopes such as, for example:

```text
org/<org_id>
property/<property_id>
lead/<lead_id>
owner/<owner_id>
room/<room_id>
```

But those are project/application DDL concerns, not PG18 image concerns.

## 6. Realtime scope strategy

The base realtime v2 proof currently supports:

```text
scope_type
scope_id
topic
```

The base stack proves the mechanics using:

```text
scope_type = user
scope_id = <app_user_id>
topic = proof.realtime
```

A project DDL package can extend the authorization function and scope tables to support project semantics.

For Prop4You, the project DDL should eventually define membership/access checks using project-owned tables, then extend or replace the relevant DB-owned authorization function.

The base rule remains:

```text
Postgres owns authorization truth.
WebSocket transports authorized events only.
```

## 7. Installation lifecycle

Recommended lifecycle:

1. Start PG18 base image/stack pinned by digest.
2. Verify base runtime and extension surface.
3. Install shared base DDL package if required.
4. Install project DDL package.
5. Run project DDL smoke tests.
6. Run browser proof or API proof for project-specific flows.
7. Record installed DDL version state.

The install state should eventually be tracked in a table such as:

```sql
create table if not exists private.ddl_migrations (
  package_name text not null,
  version text not null,
  filename text not null,
  checksum text not null,
  applied_at timestamptz not null default now(),
  primary key (package_name, filename)
);
```

That table belongs to the DDL installer/base DDL layer, not the image build layer.

## 8. What is correct now

The correct immediate path is:

1. Keep PG18 image/extension/realtime stack generic.
2. Keep proofs HTML-accessible for human review.
3. Add deterministic smoke scripts for the stack.
4. Create versioned DDL directory conventions now.
5. Treat Prop4You as the first project DDL package, but do not bake Prop4You schemas into the image.
6. Before implementing Prop4You DDL, inventory the existing inherited scripts and convert them into ordered `.sql` files under the project package.

## 9. Non-goals

- Do not create the `strapi` database just to silence a misconfigured service unless Strapi is intentionally part of this proof.
- Do not use `supabase_admin` as a project application user.
- Do not make project schemas part of the base image.
- Do not introduce Redis/NATS unless the realtime load/fanout proof demands it.
