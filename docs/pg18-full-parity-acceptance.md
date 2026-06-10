# PG18 Full-Parity Acceptance Report

## Accepted runtime anchor

- Image tag: `local/supabase-postgres:18-karval`
- Full image tag: `local/supabase-postgres:18-karval-full`
- Accepted image ID: `sha256:576f2d7cb01fdd0dacd37679eb37100e3da37102c536ecb3ed39173cdd39e9e3`
- Live service: `postgres18_postgres`
- Expected service state: `1/1`, healthy
- PostgreSQL version: `PostgreSQL 18.0`

## Required preload

`pg_stat_statements, pgaudit, pg_cron, pg_net, pg_tle, safeupdate`

## SQL extension matrix

| Extension | PG17 reference | PG18 accepted runtime | Contract | Result |
|---|---:|---:|---|---|
| `http` | 1.6 | 1.6 | `CREATE EXTENSION` | PASS |
| `hypopg` | 1.4.1 | 1.4.1 | `CREATE EXTENSION` | PASS |
| `index_advisor` | 0.2.0 | 0.2.0 | `CREATE EXTENSION` | PASS |
| `pg_cron` | 1.6.4 | 1.6.7 | preload + `CREATE EXTENSION` | PASS |
| `pg_graphql` | 1.5.11 | 1.6.1 | `CREATE EXTENSION` | PASS |
| `pg_hashids` | cd0e1b31d52b394a0df64079406a14a4f7387cd6 | 1.3.0-cd0e1b31d52b394a0df64079406a14a4f7387cd6 | `CREATE EXTENSION` | PASS |
| `pg_jsonschema` | 0.3.3 | 0.3.4 | `CREATE EXTENSION` | PASS |
| `pg_net` | 0.19.5 | 0.20.3 | preload + `CREATE EXTENSION` | PASS |
| `pg_repack` | 1.5.2 | 1.5.2 | `CREATE EXTENSION` | PASS |
| `pg_stat_monitor` | 2.1.0 | 2.0 SQL install script / newer source lane | `CREATE EXTENSION` | PASS/WARN documented |
| `pg_tle` | 1.4.0 | 1.5.2 | preload + `CREATE EXTENSION` | PASS |
| `pgaudit` | 17.0 | 18.0 | preload + `CREATE EXTENSION` | PASS |
| `pgjwt` | 9742dab1b2f297ad3811120db7b21451bca2d3c9 | 0.2.0 | `CREATE EXTENSION` | PASS |
| `pgmq` | 1.4.4 | 1.11.1 | `CREATE EXTENSION` | PASS |
| `pgroonga` | 3.2.5 | 4.0.6 | `CREATE EXTENSION` | PASS |
| `pgroonga_database` | n/a | 4.0.6 | `CREATE EXTENSION` | PASS |
| `pgrouting` | 3.4.1 | 3.4.1 | `CREATE EXTENSION` | PASS |
| `pgsodium` | 3.1.8 | 3.1.8 | `CREATE EXTENSION` | PASS |
| `pgtap` | 1.2.0 | 1.3.3 | `CREATE EXTENSION` | PASS |
| `plpgsql_check` | 2.7.11 | 2.8 | `CREATE EXTENSION` | PASS |
| `postgis` | 3.3.7 | 3.6.3 | `CREATE EXTENSION` | PASS |
| `rum` | 1.3 | 1.3 | `CREATE EXTENSION` | PASS |
| `supabase_vault` / `vault` | 0.3.1 | 0.3.1 | `CREATE EXTENSION` | PASS |
| `vector` | 0.8.0 | 0.8.2 | `CREATE EXTENSION` | PASS |
| `wal2json` | 2_6 | 2.6 | `CREATE EXTENSION` + output plugin surface | PASS |
| `pg_partman` | not in supplied PG17 list | 5.3.1 | `CREATE EXTENSION` | PASS, PG18 bundled extra |
| `wrappers` | 0.5.4 | 0.6.1 | `CREATE EXTENSION` | PASS |

## Preload/library-only surfaces

| Module | PG17 reference | PG18 accepted runtime | Contract | Result |
|---|---:|---:|---|---|
| `pg-safeupdate` / `safeupdate` | 1.4 | 1.4 | preload-only behavior | PASS |
| `supautils` | 2.9.4 | `supautils.so` present | library/config surface | PASS/WARN deeper behavior pending |
| `pg_plan_filter` / `plan_filter` | 5081a7b5cb890876e67d8e7486b6a64c38c9a492 | `plan_filter-0.1.so` present | library/config surface | PASS/WARN deeper behavior pending |

## Functional probes required

- `pg_jsonschema`: `jsonb_matches_schema(...)` returns true for valid payload.
- `postgis`: `ST_AsText(ST_GeomFromText('POINT(1 2)'))` returns `POINT(1 2)`.
- `vector`: vector distance probe returns expected numeric result.
- `safeupdate`: `UPDATE` without `WHERE` fails with `ERROR: UPDATE requires a WHERE clause`; `UPDATE ... WHERE` succeeds.

## Superseded background build alerts

Several older background builds completed after the accepted image had already been built, smoke-tested and promoted. They are superseded if the final runtime anchor remains:

- final image ID unchanged;
- Swarm service `1/1` and healthy;
- no active matching build process;
- named extension/preload contract passes in live runtime.

## Verdict

Supported for this slice: PG18 full-parity database image acceptance and live Swarm runtime validation.

Not claimed: remote registry publication, production VPS deployment, deeper behavioral semantics for `supautils`/`plan_filter`, or full Supabase platform stack parity.
