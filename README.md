# Supabase Postgres Fork — PostgreSQL 18 Local Release-Readiness

This repository is a fork of `supabase/postgres` focused on carrying the Supabase/Postgres image recipe forward to PostgreSQL 18 while preserving the curated extension surface used by the PostgreSQL 17 image, with newer compatible extension versions where available.

## Current status

The PostgreSQL 18 lane in this fork is no longer only a bootstrap note. It has a full local no-skip Nix/Docker gate, a registry-published RC1 digest, and a durable PostgREST/JWT/RLS/realtime dev proof.

Accepted PG18 RC1 image:

```text
local validation tag: local/supabase-postgres:18-karval-full-validate
local image id: sha256:cb3e0e2e88054cc1ea6fc6ac34b9558b210a8e0e281269214248ad0cd829470a
registry tag: registry.arthuragrelli.com/supabase-postgres:18-karval-rc1
registry digest: sha256:c477d5146ea51f235b811c093363c3ed5d8a342dbed8efac7635a1b9779e2f9f
digest-pinned reference: registry.arthuragrelli.com/supabase-postgres@sha256:c477d5146ea51f235b811c093363c3ed5d8a342dbed8efac7635a1b9779e2f9f
```

Accepted local Swarm service used for validation:

```text
postgres18_postgres
```

Accepted preload:

```text
pg_stat_statements, pgaudit, pg_cron, pg_net, pg_tle, safeupdate
```

Primary acceptance docs:

- `docs/canonical-docs-index.md`
- `docs/pg18-full-parity-final-report.md`
- `docs/pg18-full-parity-acceptance.md`
- `docs/pg18-full-parity-prd.md`
- `docs/pg18-release-readiness-prd.md`
- `docs/pg18-release-readiness-final-report.md`
- `docs/pg18-rc-publish-postgrest-rls-final-report.md`
- `docs/pg18-rc-publish-postgrest-rls-task-reviews.md`

Historical/bootstrap docs may still exist under `docs/pg18-*`; if they conflict with the full-parity/final reports, treat the final reports as the current source of truth.

## What this fork currently claims

This fork currently claims local database-image readiness for PostgreSQL 18 under the documented acceptance lane.

It does not yet claim:

- production/VPS deployment;
- full Supabase platform stack parity;
- active `supautils` or `plan_filter` enforcement semantics.

It now does claim:

- full local no-skip Nix/Docker validation in the persistent KVM-capable runner;
- registry RC1 publication with immutable digest;
- durable local dev stack for PG18 RC1 + PostgREST + JWT/RLS + web proof + optional realtime bridge.


## Database-centric DDL packages and runtime log notes

This repository now separates the compiled PG18 database/stack base from project-installed DDL packages. The base image/stack provides PostgreSQL 18, curated extensions, preload hooks and optional sibling services such as PostgREST/realtime. Project schemas are installed later as ordered `.sql` packages.

Project DDL modeling follows the database-centric soft-DDD rule: schemas are domains/bounded contexts; tables are durable domain records; functions/RPCs are use cases; views are projections; policies are authorization; `api` is the public PostgREST/client facade.

Current DDL convention:

```text
database/ddl/base/                  shared base SQL package
database/ddl/projects/prop4you/     Prop4You project SQL package
```

Read:

- `docs/pg18-database-centric-ddl-strategy.md`
- `docs/database-centric-soft-ddd-rule.md`
- `database/ddl/README.md`
- `docs/pg18-runtime-log-analysis.md`

Deterministic realtime v2 smoke with human-accessible HTML proof:

```bash
scripts/smoke-pg18-realtime-v2.sh --keep-stack
# then open http://127.0.0.1:18083/
```

## Existing version lanes

- PostgreSQL 15: upstream-supported lane remains present.
- PostgreSQL 17: upstream-supported lane remains present.
- OrioleDB/PostgreSQL 17: upstream/experimental lane remains present.
- PostgreSQL 18: local fork lane with `Dockerfile-18`, PG18 Nix packages, full-parity smoke/promotion/status scripts and local acceptance docs.

## Build PostgreSQL 18 locally

```bash
nix build .#psql_18/bin -L
nix build .#psql_18_slim/bin -L
```

Build selected PG18 extensions:

```bash
nix build .#psql_18/exts/pg_jsonschema -L
nix build .#psql_18/exts/postgis -L
nix build .#psql_18/exts/vector -L
```

## Build the PG18 Docker image

```bash
docker build -f Dockerfile-18 -t local/supabase-postgres:18-karval-full .
```

The accepted PG18 local release lane uses:

```bash
scripts/smoke-pg18-full-parity.sh --image local/supabase-postgres:18-karval-full
scripts/promote-pg18-stack.sh   # validate-only by default; no retag/restart
scripts/pg18-runtime-status.sh
```

`scripts/promote-pg18-stack.sh` is validate-only by default. It does not retag images and does not restart the Swarm service unless `--apply` is passed explicitly.

Validation-only gate:

```bash
scripts/promote-pg18-stack.sh
```

Explicit retag + Swarm update gate:

```bash
scripts/promote-pg18-stack.sh --apply
```

## Run local PG18 validation

Full local validation path except the docker-image-test harness, when the host has `nix` installed:

```bash
scripts/validate-pg18.sh --skip-docker-test --image-tag local/supabase-postgres:18-karval-validation
```

Docker-image build validation path for hosts without local `nix` in `PATH`:

```bash
scripts/validate-pg18.sh --skip-nix-builds --skip-docker-test --image-tag local/supabase-postgres:18-karval-validation
```

Default validation path, for a Nix-capable host where the docker-image-test harness is also intended:

```bash
scripts/validate-pg18.sh
```

Useful options:

```bash
scripts/validate-pg18.sh --skip-nix-builds
scripts/validate-pg18.sh --skip-docker-build
scripts/validate-pg18.sh --skip-docker-test
scripts/validate-pg18.sh --log-dir /tmp/pg18-validation
```

If docker-image-test fails and preserves regression output:

```bash
scripts/triage-pg18-failure.sh --validation-log-dir tmp/pg18-validation
scripts/triage-pg18-failure.sh --output-dir /tmp/tmp.<id>
scripts/promote-pg18-safe-outs.sh --bundle /tmp/pg18-triage/<stamp> --dry-run
```

## Extension/runtime contract model

Do not treat every runtime surface as a normal SQL extension.

| Contract type | Example | Required proof |
|---|---|---|
| SQL extension | `postgis`, `vector`, `pg_jsonschema` | `CREATE EXTENSION` succeeds |
| Preload + SQL extension | `pg_tle`, `pg_cron`, `pg_net`, `pgaudit` | preload plus `CREATE EXTENSION` succeeds |
| Preload-only hook | `safeupdate` | preload plus behavior proof |
| Library/config parity surface | `supautils`, `plan_filter` | `.so` present; semantic enforcement is a separate future gate |
| Output plugin/extension surface | `wal2json` | install/listing and output-plugin availability as scoped |

Current PG18 parity details:

- SQL extension matrix: `docs/pg18-full-parity-acceptance.md`
- Parity-only contract for `supautils` and `plan_filter`: `docs/pg18-parity-contracts.md`
- `pg_partman` is documented as a PG18 bundled extra, not part of the supplied PG17 reference list.

## Database-centric gateway and realtime proof

The current database-centric proof uses PostgREST as the first gateway and a simple web client as the first consumer. Django remains intentionally out of scope for this slice.

Durable local stack:

```bash
cd docker/pg18-postgrest-rls
docker compose -f compose.pg18-postgrest-rls.yml up -d --build
```

Surfaces:

- PG18 image pinned by RC1 digest.
- PostgREST exposes RPCs from schema `api`.
- JWT claim `app_user_id` drives RLS on `private.account_profiles` and `private.event_outbox`.
- Web proof calls same-origin endpoints and displays profile/realtime state.
- Realtime bridge is a sibling service, not baked into the database image: `event_outbox` + `LISTEN/NOTIFY` + WebSocket.

See:

```text
docs/pg18-database-centric-postgrest-web-prd.md
docs/pg18-realtime-websocket-architecture.md
docs/pg18-rc-publish-postgrest-rls-final-report.md
```

LLM/agent context entrypoints:

```text
llms.txt
llms-full.txt
```

## Repository layout

| Path | Purpose |
|---|---|
| `nix/` | Nix packages, extensions, checks and image inputs |
| `nix/ext/` | Extension derivations and version wiring |
| `nix/packages/postgres.nix` | PostgreSQL package sets and extension lists |
| `Dockerfile-18` | PG18 Docker image path for this fork |
| `scripts/validate-pg18.sh` | Local PG18 validation sequence |
| `scripts/smoke-pg18-full-parity.sh` | Disposable image smoke and extension/probe validation |
| `scripts/promote-pg18-stack.sh` | Safe-by-default live validation; `--apply` performs local retag + Swarm update |
| `scripts/pg18-runtime-status.sh` | Live status and accepted image validation |
| `docs/pg18-*` | PG18 planning, acceptance, release-readiness and reports |
| `ansible/` | Existing upstream/Supabase infra configuration surfaces |
| `migrations/` | Database initialization and migration files |

## Release-readiness gates still separate from local acceptance

Before production or VPS promotion, still run and record:

1. remote deployment proof if production is in scope;
2. service/stack spec updated to the digest-pinned image;
3. newest running task/container using that digest;
4. health endpoints and clean recent logs;
5. explicit hardening tests if activating `supautils` or `plan_filter` enforcement.

## Upstream context

This fork is based on Supabase Postgres: PostgreSQL with a curated extension set and supporting build/release infrastructure. Upstream community links and detailed generic extension tables should be treated as upstream reference material; this README prioritizes the current PG18 fork state and local release-readiness path.
