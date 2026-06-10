# Supabase Postgres Fork — PostgreSQL 18 Local Release-Readiness

This repository is a fork of `supabase/postgres` focused on carrying the Supabase/Postgres image recipe forward to PostgreSQL 18 while preserving the curated extension surface used by the PostgreSQL 17 image, with newer compatible extension versions where available.

## Current status

The PostgreSQL 18 lane in this fork is no longer only a bootstrap note. It has a locally accepted database-image slice.

Accepted local PG18 image:

```text
local/supabase-postgres:18-karval
local/supabase-postgres:18-karval-full
sha256:576f2d7cb01fdd0dacd37679eb37100e3da37102c536ecb3ed39173cdd39e9e3
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

- `docs/pg18-full-parity-final-report.md`
- `docs/pg18-full-parity-acceptance.md`
- `docs/pg18-full-parity-prd.md`
- `docs/pg18-release-readiness-prd.md`
- `docs/pg18-release-readiness-final-report.md`

Historical/bootstrap docs may still exist under `docs/pg18-*`; if they conflict with the full-parity/final reports, treat the final reports as the current source of truth.

## What this fork currently claims

This fork currently claims local database-image readiness for PostgreSQL 18 under the documented acceptance lane.

It does not yet claim:

- remote registry publication;
- production/VPS deployment;
- full Supabase platform stack parity;
- active `supautils` or `plan_filter` enforcement semantics;
- a completed clean-runner release gate unless separately run and recorded.

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

## Database-centric next direction

The next architecture slice is database-centric with PostgREST as the first gateway and a simple web client as the first consumer. Django is intentionally out of scope for that slice.

See:

```text
docs/pg18-database-centric-postgrest-web-prd.md
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

Before a broader release, run and record:

1. clean Nix-capable runner validation;
2. docker-image-test harness and fixture triage;
3. registry/digest publication strategy;
4. remote deployment proof if production is in scope;
5. explicit hardening tests if activating `supautils` or `plan_filter` enforcement.

## Upstream context

This fork is based on Supabase Postgres: PostgreSQL with a curated extension set and supporting build/release infrastructure. Upstream community links and detailed generic extension tables should be treated as upstream reference material; this README prioritizes the current PG18 fork state and local release-readiness path.
