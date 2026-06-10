# PG18 Release-Readiness — Local Test Evidence

## Scope

Local-only, non-production release-readiness gates for the PG18 fork.

## Gates executed

### 1. Script syntax

- `bash -n scripts/pg18-runtime-status.sh`: PASS
- `bash -n scripts/smoke-pg18-full-parity.sh`: PASS
- `bash -n scripts/promote-pg18-stack.sh`: PASS
- `bash -n scripts/validate-pg18.sh`: PASS

### 2. Live runtime status

- `scripts/pg18-runtime-status.sh`: PASS
- Live stack remained `postgres18_postgres` on the accepted baseline image.
- Runtime proved PostgreSQL 18.0, preload, SQL extensions, and library-only parity surfaces.

### 3. Baseline smoke

- `scripts/smoke-pg18-full-parity.sh --image local/supabase-postgres:18-karval-full`: PASS

### 4. Promotion validation without restart

- `scripts/promote-pg18-stack.sh --skip-update`: PASS

### 5. Docker image build path

Command:

```bash
scripts/validate-pg18.sh --skip-nix-builds --skip-docker-test --image-tag local/supabase-postgres:18-karval-validation
```

Result: PASS.

Host note: the host does not expose `nix` on PATH, so the host-Nix part of `validate-pg18.sh` is documented as a runner requirement. The Dockerfile path builds through Nix inside the Docker builder and was validated successfully.

Summary:

```text
[2026-06-10 14:26:07] ROOT_DIR=/home/marcelo-karval/Backup/Projetos/supabase-postgres-18-fork/postgres
[2026-06-10 14:26:07] LOG_DIR=/home/marcelo-karval/Backup/Projetos/supabase-postgres-18-fork/postgres/tmp/pg18-validation
[2026-06-10 14:26:07] IMAGE_TAG=local/supabase-postgres:18-karval-validation
[2026-06-10 14:26:07] RUN_NIX_BUILDS=false
[2026-06-10 14:26:07] RUN_DOCKER_BUILD=true
[2026-06-10 14:26:07] RUN_DOCKER_TEST=false
[2026-06-10 14:26:07] START 14-docker-build
[2026-06-10 15:23:59] DONE  14-docker-build
[2026-06-10 15:23:59] PG18 validation sequence finished successfully
[2026-06-10 15:23:59] Summary file: /home/marcelo-karval/Backup/Projetos/supabase-postgres-18-fork/postgres/tmp/pg18-validation/summary.txt
```

Validation image:

```text
actual_id=sha256:ddd0cc5e4ecef17d4661c62ccf25ca5c3e78107550109d2141e458e4209a1c32
```

### 6. Smoke of freshly built validation image

Command:

```bash
actual_id=$(docker image inspect local/supabase-postgres:18-karval-validation --format '{{.Id}}')
scripts/smoke-pg18-full-parity.sh \
  --image local/supabase-postgres:18-karval-validation \
  --expected-image-id "$actual_id"
```

Result: PASS.

Smoke tail/marker:

```text
== starting disposable PG18 smoke ==
image=local/supabase-postgres:18-karval-validation
expected_image_id=sha256:ddd0cc5e4ecef17d4661c62ccf25ca5c3e78107550109d2141e458e4209a1c32
container=pg18-full-parity-smoke-1781119468
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
## Validate-only promotion output after safety correction

`promote-pg18-stack.sh` is now validate-only by default; no `docker tag` or Swarm restart occurs unless `--apply` is passed.

Command:

```bash
scripts/promote-pg18-stack.sh
```

Output:

```text
== PG18 stack validation/promotion ==
mode=validate-only
full_image=local/supabase-postgres:18-karval-full
image=local/supabase-postgres:18-karval
expected_image_id=sha256:576f2d7cb01fdd0dacd37679eb37100e3da37102c536ecb3ed39173cdd39e9e3
service=postgres18_postgres
validate_only_no_retag_or_service_update=true
replicas=1/1
live_container_image_id=sha256:576f2d7cb01fdd0dacd37679eb37100e3da37102c536ecb3ed39173cdd39e9e3
/run/postgresql:5432 - accepting connections
http
hypopg
index_advisor
pg_cron
pg_graphql
pg_hashids
pg_jsonschema
pg_net
pg_repack
pg_stat_monitor
pg_tle
pgaudit
pgjwt
pgmq
pgroonga
pgroonga_database
pgrouting
pgsodium
pgtap
plpgsql_check
postgis
rum
supabase_vault
vector
wal2json
wrappers
pg_partman
/nix/store/hx5lcxq6clqcx32ng2k956bqh10vv39l-safeupdate-1.4/lib/safeupdate-1.4.so
/nix/store/rc9xlw6qw8hckbxl48j9nr8hd2daqw2s-supautils/lib/supautils.so
/nix/store/7dn4dxxzi2wfb1cm9lsvyzz0b0jqdzyf-plan_filter-0.1/lib/plan_filter-0.1.so
PG18_STACK_PROMOTION_OK
```

Backward-compatible command:

```bash
scripts/promote-pg18-stack.sh --skip-update
```

Output:

```text
== PG18 stack validation/promotion ==
mode=validate-only
full_image=local/supabase-postgres:18-karval-full
image=local/supabase-postgres:18-karval
expected_image_id=sha256:576f2d7cb01fdd0dacd37679eb37100e3da37102c536ecb3ed39173cdd39e9e3
service=postgres18_postgres
validate_only_no_retag_or_service_update=true
replicas=1/1
live_container_image_id=sha256:576f2d7cb01fdd0dacd37679eb37100e3da37102c536ecb3ed39173cdd39e9e3
/run/postgresql:5432 - accepting connections
http
hypopg
index_advisor
pg_cron
pg_graphql
pg_hashids
pg_jsonschema
pg_net
pg_repack
pg_stat_monitor
pg_tle
pgaudit
pgjwt
pgmq
pgroonga
pgroonga_database
pgrouting
pgsodium
pgtap
plpgsql_check
postgis
rum
supabase_vault
vector
wal2json
wrappers
pg_partman
/nix/store/hx5lcxq6clqcx32ng2k956bqh10vv39l-safeupdate-1.4/lib/safeupdate-1.4.so
/nix/store/rc9xlw6qw8hckbxl48j9nr8hd2daqw2s-supautils/lib/supautils.so
/nix/store/7dn4dxxzi2wfb1cm9lsvyzz0b0jqdzyf-plan_filter-0.1/lib/plan_filter-0.1.so
PG18_STACK_PROMOTION_OK
```

## Host-Nix runner caveat

Host-Nix validation is classified as WARN/BLOCKED on this workstation because `nix` is not available on PATH. The Dockerfile release path still validated because it builds with Nix inside Docker BuildKit.

```text
nix not found on PATH
```
