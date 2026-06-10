# PG18 RC1 Release Checklist

Status: LOCAL_RC_READY_WITH_RUNNER_WARN

## Image tags

```text
rc_tag=local/supabase-postgres:18-karval-rc1
rc_image_id=sha256:ddd0cc5e4ecef17d4661c62ccf25ca5c3e78107550109d2141e458e4209a1c32
```

Registry candidate tag, not pushed:

```text
local_rc=local/supabase-postgres:18-karval-rc1
registry_candidate=registry.arthuragrelli.com/supabase-postgres:18-karval-rc1
image_id=sha256:ddd0cc5e4ecef17d4661c62ccf25ca5c3e78107550109d2141e458e4209a1c32
push_status=NOT_PUSHED_NO_EXPLICIT_SCOPE
```

## Required gates

| Gate | Evidence | Status |
|---|---|---|
| Git clean before slice | `git status --short` was 0 before work | PASS |
| Local RC tag | `local/supabase-postgres:18-karval-rc1` | PASS |
| RC image ID | `sha256:ddd0cc5e4ecef17d4661c62ccf25ca5c3e78107550109d2141e458e4209a1c32` | PASS |
| RC smoke | `PG18_FULL_PARITY_SMOKE_OK` | PASS |
| Runtime baseline | `postgres18_postgres` remains on accepted baseline | PASS |
| Registry push | No explicit PG18 registry/push scope | NOT_PUSHED |
| Nix runner full validate | Nix container available; docker-client acquisition blocked by GitHub/nixpkgs timeout | BLOCKED/WARN |
| PostgREST API proof | `/rpc/hello` returned JSON from PG18 | PASS |
| Web browser proof | Browser rendered `/api/hello` result via local proxy | PASS |

## RC smoke marker

```text
== starting disposable PG18 smoke ==
image=local/supabase-postgres:18-karval-rc1
expected_image_id=sha256:ddd0cc5e4ecef17d4661c62ccf25ca5c3e78107550109d2141e458e4209a1c32
container=pg18-full-parity-smoke-1781126136
/run/postgresql:5432 - accepting connections
-- version/preload --
PostgreSQL 18.0 on x86_64-pc-linux-gnu, compiled by gcc (GCC) 15.2.0, 64-bit
pg_stat_statements, pgaudit, pg_cron, pg_net, pg_tle, safeupdate
-- create extension smoke --
OK:pg_cron
OK:pg_net
OK:pgaudit
OK:pgmq
OK:postgis
OK:pg_jsonschema
OK:vector
OK:rum
OK:pgroonga
OK:pgroonga_database
NOTICE:  installing required extension "hypopg"
OK:index_advisor
OK:wal2json
OK:pg_repack
OK:plpgsql_check
OK:pgjwt
OK:pgrouting
OK:pgtap
OK:http
OK:pg_hashids
OK:pgsodium
OK:pg_graphql
OK:pg_stat_monitor
OK:pg_partman
NOTICE:  extension "supabase_vault" already exists, skipping
OK:supabase_vault
NOTICE:  extension "hypopg" already exists, skipping
OK:hypopg
OK:pg_tle
OK:wrappers
-- functional probes --
NOTICE:  table "safeupdate_probe" does not exist, skipping
ERROR:  UPDATE requires a WHERE clause
-- library-only surfaces --
PG18_FULL_PARITY_SMOKE_OK
```
