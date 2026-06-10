# PRD — PostgreSQL 18 Full-Parity Supabase/Postgres Image Acceptance

## 1. Executive goal

Build and operationalize a PostgreSQL 18 image based on this Supabase/Postgres fork with parity against the PostgreSQL 17 extension surface used as reference, while keeping the PG18 track intentionally upgraded to the newest compatible extension versions.

The output is not only a Docker image. The completed slice must provide:

1. a documented PG18 full-parity baseline;
2. repeatable smoke and promotion scripts;
3. live-stack proof in Docker Swarm;
4. extension/runtime contract documentation;
5. per-task reviews and final requested-vs-delivered review;
6. browser-proof/vision evidence over the persisted report.

## 2. Scope

### In scope

- Keep the final image tags:
  - `local/supabase-postgres:18-karval-full`
  - `local/supabase-postgres:18-karval`
- Validate the live Swarm service:
  - `postgres18_postgres`
- Preserve the user constraint: no Oriole, no TimescaleDB, no plv8.
- Treat each runtime surface according to its actual PostgreSQL contract:
  - SQL extension: `CREATE EXTENSION` must pass.
  - preload plus SQL extension: library must be in `shared_preload_libraries` and `CREATE EXTENSION` must pass.
  - preload-only hook: library must be preloaded and behavior must be proved.
  - output plugin/library-only module: prove availability or presence by the correct runtime handle.
- Persist all acceptance, tasks, reviews and final report under `docs/`.
- Provide scripts under `scripts/` for future reruns.

### Out of scope for this slice

- Publishing to a remote registry.
- Production VPS mutation.
- Changing secrets, connection strings, or external credentials.
- Adding Oriole, TimescaleDB, or plv8.
- Claiming full upstream Supabase platform parity. This is image/database parity only.

## 3. Acceptance criteria

### AC-1 — Image and runtime anchor

The repo must record the accepted image ID and the live Swarm service must run the accepted image tag.

Expected accepted image at time of this slice:

`sha256:576f2d7cb01fdd0dacd37679eb37100e3da37102c536ecb3ed39173cdd39e9e3`

### AC-2 — PG18 server and preload

The live service must report PostgreSQL 18 and this preload list:

`pg_stat_statements, pgaudit, pg_cron, pg_net, pg_tle, safeupdate`

### AC-3 — SQL extension smoke

The following SQL extensions must install with `CREATE EXTENSION IF NOT EXISTS ... CASCADE`:

`http hypopg index_advisor pg_cron pg_graphql pg_hashids pg_jsonschema pg_net pg_repack pg_stat_monitor pg_tle pgaudit pgjwt pgmq pgroonga pgroonga_database pgrouting pgsodium pgtap plpgsql_check postgis rum supabase_vault vector wal2json wrappers pg_partman`

### AC-4 — Library/preload-only module proof

- `safeupdate` must be in `shared_preload_libraries` and must block unsafe `UPDATE` without `WHERE`.
- `supautils.so` must be present as a library surface.
- `plan_filter-0.1.so` must be present as a library surface.

### AC-5 — Functional probes

The stack must pass probes for:

- `pg_jsonschema`
- `postgis`
- `vector`
- `safeupdate`

### AC-6 — Reproducibility scripts

The repo must include executable scripts for:

- isolated full-parity smoke;
- Swarm promotion and live-stack validation;
- runtime status/triage summary.

### AC-7 — Persisted review artifacts

The repo must include:

- this PRD;
- task ledger;
- acceptance report;
- task-by-task review;
- final side-by-side requested-vs-delivered report;
- browser-proof report HTML.

### AC-8 — Browser-proof + vision

A local static report must be served, loaded through browser tooling, visually inspected, and recorded in the final report.

## 4. PG17 reference to PG18 target surface

The PG17 reference surface contains 28 entries. The PG18 target keeps that surface, with newer compatible versions where available.

Important contract corrections:

- `pg-safeupdate` is not a SQL extension in this image path; it is `safeupdate` preload-only.
- `vault` appears as `supabase_vault` in `pg_available_extensions`.
- `wal2json` is installable with `CREATE EXTENSION` in this image and also represents an output-plugin surface.
- `pg_partman` is an additional PG18-bundled SQL extension validated by smoke, not part of the supplied PG17 reference list.
- `pg_plan_filter` is represented by `plan_filter-0.1.so` library presence.
- `supautils` is represented by `supautils.so` library presence/config surface.
- `pg_stat_monitor` reports SQL install version `2.0` although the source build lane used newer upstream; this must be documented instead of hidden.

## 5. Risks and mitigations

| Risk | Mitigation |
|---|---|
| Stale background build alerts after a later successful build | Anchor on live image ID, service health, active process list and targeted extension proof. |
| Treating preload-only modules as missing extensions | Separate SQL extension smoke from preload/library contract proof. |
| Drift between `:18-karval-full` and `:18-karval` | `promote-pg18-stack.sh` retags and forces Swarm update, then validates live task. |
| Secret leakage in logs | Scripts use local smoke password only and do not print real stack credentials. |
| Browser-proof route without live server | Static proof script must start a local server, verify HTTP, use browser tooling, and cleanup server. |

## 6. Delivery plan

1. Persist PRD and task ledger.
2. Persist acceptance report from known runtime evidence.
3. Add smoke/promotion/status scripts.
4. Run script syntax checks.
5. Run live stack validation script.
6. Run isolated smoke script against the final image.
7. Persist per-task reviews.
8. Generate browser-proof HTML report.
9. Serve report locally and capture browser + vision evidence.
10. Persist final side-by-side requested-vs-delivered report.
11. Optionally commit the owned PG18 slice if the checkout scope is safe.

## 7. Open questions for future roadmap

These do not block this slice:

1. Should `supautils`/`plan_filter` receive deeper behavioral tests beyond library presence?
2. Should PG18-specific regression fixtures (`z_18_*`) be created after comparing docker-image-test output on a clean Nix runner?
3. Should this image be pushed to a private registry and used by Portainer from a digest-pinned reference?
4. Should the database-centric API contract be documented as a separate PRD using schemas/functions/RLS/jobs/queues/search as first-class backend primitives?
