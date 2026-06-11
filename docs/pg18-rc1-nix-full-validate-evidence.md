# PG18 RC1 Nix Full Validate Evidence

Status: BLOCKED_BY_KVM_UNAVAILABLE_ON_CURRENT_HOST_AFTER_REAL_NIX_PROOF

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

## Persistent runner attempt

A persistent `/nix` Docker volume runner was added and executed through:

```bash
scripts/run-pg18-persistent-nix-validate.sh
```

Persistent-runner evidence files:
- `tmp/pg18-publish/nix-full-validate-persistent.log`
- `tmp/pg18-publish/full-validate-persistent-nix/summary.txt`
- `tmp/pg18-publish/full-validate-persistent-nix/01-psql_18_bin.log`
- `tmp/pg18-publish/full-validate-persistent-nix/02-psql_18_slim_bin.log`
- `tmp/pg18-publish/full-validate-persistent-nix/03-ext-pg_jsonschema.log`

Summary result:

```text
[2026-06-11 01:23:40] START 01-psql_18_bin
[2026-06-11 02:15:59] DONE  01-psql_18_bin
[2026-06-11 02:15:59] START 02-psql_18_slim_bin
[2026-06-11 02:58:15] DONE  02-psql_18_slim_bin
[2026-06-11 02:58:15] START 03-ext-pg_jsonschema
[2026-06-11 03:03:57] FAIL  03-ext-pg_jsonschema exit_code=1 logfile=/work/tmp/pg18-publish/full-validate-persistent-nix/03-ext-pg_jsonschema.log
```

The persistent volume fix worked: both package build steps completed and the gate advanced to the first VM-backed extension check.

## Current blocker: KVM unavailable on this host

`03-ext-pg_jsonschema` failed before executing the VM test because Nix required the `kvm` system feature:

```text
error: Cannot build '/nix/store/mln5mk7n71q7ixw8si4lmkwbbv0m71zm-vm-test-run-pg_jsonschema.drv'.
       Reason: missing system features
       Required features: {kvm, nixos-test}
       Available features: {benchmark, big-parallel, nixos-test, uid-range}
```

Host verification:

```text
ls: cannot access '/dev/kvm': No such file or directory
Virtualization: VT-x
sudo_noninteractive_unavailable
```

This is not a PG18 source/build failure. It is a current-host runner capability blocker: the NixOS VM tests require a KVM-capable runner with `/dev/kvm` exposed to the validation container and Nix configured with the `kvm` system feature.

## Script hardening applied

`scripts/run-pg18-persistent-nix-validate.sh` now:
- uses a persistent `/nix` volume;
- maps host checkout paths to `/work/...` before invoking the inner validator;
- controls Nix parallelism with `PG18_NIX_MAX_JOBS` and `PG18_NIX_CORES`;
- accepts flake config by default through `PG18_ACCEPT_FLAKE_CONFIG=true`;
- fails fast with exit `86` when `/dev/kvm` is missing and `PG18_REQUIRE_KVM=true`;
- passes `/dev/kvm` to Docker and adds `extra-system-features = kvm` when KVM is available.

Preflight proof on the current host:

```text
preflight_status=86
ERROR: /dev/kvm is not available on the host, but this full no-skip PG18 gate
requires NixOS VM tests with the Nix system feature `kvm`.
```

## Final gate status

BLOCKED for a single continuous no-skip `scripts/validate-pg18.sh` PASS on the current host because `/dev/kvm` is unavailable.

Not blocked:
- PG18 full package build proof: `psql_18/bin` completed in the persistent real Nix runner.
- PG18 slim package build proof: `psql_18_slim/bin` completed in the persistent real Nix runner.
- Script output bug: fixed.
- Disposable `/nix` store recompilation issue: fixed by persistent Docker volume.
- Runner path-mapping issue: fixed.

Required next infrastructure fix:
- enable/load KVM on this workstation, then rerun `scripts/run-pg18-persistent-nix-validate.sh`; or
- move the gate to a KVM-capable runner where `/dev/kvm` is available and passed to Docker.

Recommended host verification before rerun:

```bash
ls -l /dev/kvm
```

Recommended rerun command after KVM is available:

```bash
PG18_NIX_MAX_JOBS=1 PG18_NIX_CORES=16 scripts/run-pg18-persistent-nix-validate.sh
```
