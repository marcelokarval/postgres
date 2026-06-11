# PG18 RC1 Nix Full Validate Evidence

Status: BLOCKED_BY_RUNNER_ARCHITECTURE_AFTER_REAL_NIX_PROOF

## What was actually run

A real containerized Nix runner was built from `docker/pg18-self-hosted-runner/Dockerfile` and executed with Docker socket access.

Successful runner form:
```bash
docker run --rm   -v "$PWD":/work   -v /var/run/docker.sock:/var/run/docker.sock   -w /work   --entrypoint bash   local/pg18-self-hosted-runner:validation   -lc 'set -e; if ! getent group nixbld >/dev/null; then groupadd -r nixbld; fi; for i in $(seq 1 16); do id nixbld$i >/dev/null 2>&1 || useradd -r -g nixbld -G nixbld -d /var/empty -s /usr/sbin/nologin nixbld$i; done; git config --global --add safe.directory /work; nix --version; docker version --format "client={{.Client.Version}} server={{.Server.Version}}"; bash scripts/validate-pg18.sh --log-dir /work/tmp/pg18-publish/full-validate-nixbld --image-tag local/supabase-postgres:18-karval-full-validate'
```

## Evidence from first real full runner attempt

Log files:
- `tmp/pg18-publish/nix-full-validate-nixbld.log`
- `tmp/pg18-publish/full-validate-nixbld/summary.txt`
- `tmp/pg18-publish/full-validate-nixbld/03-ext-pg_jsonschema.log`

Summary result:
```text
[2026-06-10 22:57:48] START 01-psql_18_bin
[2026-06-10 23:50:58] DONE  01-psql_18_bin
[2026-06-10 23:50:58] START 02-psql_18_slim_bin
[2026-06-11 00:35:49] DONE  02-psql_18_slim_bin
[2026-06-11 00:35:49] START 03-ext-pg_jsonschema
[2026-06-11 00:35:50] FAIL  03-ext-pg_jsonschema exit_code=1
```

Root cause of failure:
```text
error: flake 'git+file:///work' does not provide attribute
'packages.x86_64-linux.psql_18/exts/pg_jsonschema',
'legacyPackages.x86_64-linux.psql_18/exts/pg_jsonschema'
or 'psql_18/exts/pg_jsonschema'
```

This is a validation script/output-name bug, not a PostgreSQL 18 build failure.

## Output discovery

Linux output discovery with `nix eval` showed the actual outputs:

Packages:
```text
postgresql_18
postgresql_18_debug
postgresql_18_jit
postgresql_18_src
psql_18/bin
psql_18_slim/bin
```

Checks:
```text
ext-pg_cron
ext-pg_jsonschema
ext-pg_net
ext-pgaudit
ext-pgmq
ext-postgis
ext-vector
postgresql_18_debug
postgresql_18_src
psql_18
psql_18_slim
```

## Fix applied

`scripts/validate-pg18.sh` was corrected to use:
```bash
nix build .#checks.x86_64-linux.ext-pg_jsonschema -L
nix build .#checks.x86_64-linux.ext-pgaudit -L
nix build .#checks.x86_64-linux.ext-pgmq -L
nix build .#checks.x86_64-linux.ext-postgis -L
nix build .#checks.x86_64-linux.ext-vector -L
nix build .#checks.x86_64-linux.ext-pg_cron -L
nix build .#checks.x86_64-linux.ext-pg_net -L
```

## V2 attempt after patch

A second full attempt was started in the same disposable-runner pattern.
It proved the patch advanced past the previous output-name issue, but because the runner does not persist `/nix/store`, it restarted the expensive `01-psql_18_bin` build from scratch and began recompiling heavy surfaces again.

Observed v2 state before intentional stop:
- `01-psql_18_bin` running again.
- Heavy derivations recompiling, including PostgreSQL regression tests, GDAL, pg_graphql, and pg_jsonschema.
- No PG18 failure was observed.

The v2 process was intentionally stopped to avoid wasting hours of CPU on a non-persistent disposable runner.

## Final gate status

BLOCKED for a single continuous no-skip `scripts/validate-pg18.sh` PASS in the current runner architecture.

Not blocked:
- PG18 full package build proof: `psql_18/bin` completed in real Nix runner.
- PG18 slim package build proof: `psql_18_slim/bin` completed in real Nix runner.
- Script output bug: fixed.

Required next infrastructure fix:
- run the Nix runner with a persistent `/nix` Docker volume or a long-lived validation container, then rerun `scripts/validate-pg18.sh` once with no skips.

Recommended command shape:
```bash
docker volume create pg18-nix-store
docker run --rm   -v pg18-nix-store:/nix   -v "$PWD":/work   -v /var/run/docker.sock:/var/run/docker.sock   -w /work   --entrypoint bash   local/pg18-self-hosted-runner:validation   -lc 'set -e; if ! getent group nixbld >/dev/null; then groupadd -r nixbld; fi; for i in $(seq 1 16); do id nixbld$i >/dev/null 2>&1 || useradd -r -g nixbld -G nixbld -d /var/empty -s /usr/sbin/nologin nixbld$i; done; git config --global --add safe.directory /work; bash scripts/validate-pg18.sh --log-dir /work/tmp/pg18-publish/full-validate-persistent-nix --image-tag local/supabase-postgres:18-karval-full-validate'
```
