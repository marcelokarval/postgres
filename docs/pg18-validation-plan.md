# PostgreSQL 18 validation plan

This document defines the first real validation pass for the PG18 bootstrap path.

## Acceptance item
PG18 must have a reproducible build/test path for:
- core package outputs
- key PG18-only extensions added during bootstrap
- Dockerfile-18 image build
- docker-image-test runtime harness

## Path exercised
1. Build core PG18 package outputs with Nix.
2. Build targeted PG18 extensions with Nix.
3. Run focused PG18 check harnesses.
4. Build Dockerfile-18.
5. Run docker-image-test against Dockerfile-18.

## Evidence checked
- successful `nix build` exit status
- successful `docker build` exit status
- successful `nix run .#docker-image-test -- --no-build Dockerfile-18`
- preserved regression diffs if any test fails
- confirmation that PG18 now reuses `z_17_*` fixtures intentionally for the first pass

## Commands
Run from repo root:

```bash
# Single-entry validation script
scripts/validate-pg18.sh

# Optional examples
scripts/validate-pg18.sh --skip-docker-test
scripts/validate-pg18.sh --log-dir /tmp/pg18-validation
```

Underlying commands executed by the script:

```bash
# 1. Core outputs
nix build .#psql_18/bin -L
nix build .#psql_18_slim/bin -L

# 2. Targeted bootstrap extensions
nix build .#psql_18/exts/pg_jsonschema -L
nix build .#psql_18/exts/pgaudit -L
nix build .#psql_18/exts/pgmq -L
nix build .#psql_18/exts/postgis -L
nix build .#psql_18/exts/vector -L
nix build .#psql_18/exts/pg_cron -L
nix build .#psql_18/exts/pg_net -L

# 3. Focused checks
nix build .#checks.x86_64-linux.psql_18 -L
nix build .#checks.x86_64-linux.psql_18_slim -L
nix build .#checks.x86_64-linux.postgresql_18_debug -L
nix build .#checks.x86_64-linux.postgresql_18_src -L

# 4. Docker build
docker build -f Dockerfile-18 -t pg-docker-test:18 .

# 5. Docker runtime regression
nix run .#docker-image-test -- --no-build Dockerfile-18
```

## Regression fixture decision
For the first PG18 validation pass, the harness should reuse `z_17_*` fixtures.

Rationale:
- there are 5 existing `z_17_*` SQL fixtures and 0 `z_18_*`
- these fixtures mostly test 17+ semantic surfaces rather than literal `17` string checks
- examples:
  - `z_17_pgvector.sql` exercises vector operators, not version text
  - `z_17_rum.sql` exercises RUM index behavior, not version text
  - `z_17_pg_stat_monitor.sql` is a shape/projection probe
  - `z_17_roles.sql` checks roles/privileges introduced in newer majors
  - `z_17_ext_interface.sql` is an interface-diff monitor and already contains prior cross-version filters

## When to create `z_18_*`
Create dedicated `z_18_*` fixtures only if one of these happens during validation:
- `z_17_*` expected output diverges materially on PG18
- PG18 introduces new role/privilege/output semantics not cleanly expressible in the 17 fixture
- extension public interfaces change in ways that should be audited separately for 18

## Result status
Current status: incomplete

Why incomplete:
- this host does not have `nix` in PATH
- real build/runtime acceptance has not yet been executed here

## Failure triage helper

When `docker-image-test` fails and preserves an `OUTPUT_DIR`, collect and summarize artifacts with:

```bash
scripts/triage-pg18-failure.sh --output-dir /tmp/tmp.<id>

# or, if using the validation script log dir
scripts/triage-pg18-failure.sh --validation-log-dir tmp/pg18-validation
```

The helper copies raw regression artifacts into a timestamped triage bundle, skips known patched shared outputs from direct promotion, and highlights `z_17_* -> z_18_*` fixture candidates.

## Safe promotion helper

After manual review of the triage bundle, promote only safe `.out` files with:

```bash
# preview actions only
scripts/promote-pg18-safe-outs.sh --bundle /tmp/pg18-triage-out/<stamp> --dry-run

# promote reviewed-safe outputs in place
scripts/promote-pg18-safe-outs.sh --bundle /tmp/pg18-triage-out/<stamp>

# or create PG18-specific siblings from z_17_* candidates
scripts/promote-pg18-safe-outs.sh --bundle /tmp/pg18-triage-out/<stamp> --as-z18
```

The promotion helper refuses direct promotion of the known runtime-patched shared files: `roles.out`, `vault.out`, `pgmq.out`, and `http.out`.

## Notes / remaining gap
- Docker is available on this host at `/usr/bin/docker`
- `nix` is not currently available on this host
- once a host with working Nix is available, the command block above is the next acceptance path
