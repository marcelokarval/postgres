# PostgreSQL 18 goal: path to 100%

This document defines what "PG18 functioning 100%" means for this fork, what is already in place, and what remains open.

## Goal definition

For this repo, PG18 can be called 100% functioning only when all of the following are true:

1. core PG18 package outputs build successfully
2. the current PG18 bootstrap extension set builds successfully
3. focused PG18 checks pass
4. Dockerfile-18 builds successfully
5. docker-image-test passes for Dockerfile-18, or any legitimate divergences are captured as explicit PG18 fixtures/expected outputs
6. no remaining PG18-critical path is relying on unverified assumptions only

## Current verified state on this host

Verified here by direct tool output:

- PG18 package/test/image scaffolding has been wired into the repo
- `Dockerfile-18` exists
- `docker-image-test.nix` recognizes `Dockerfile-18`
- the first-pass PG18 runtime regression path intentionally reuses `z_17_*`
- checked-in helper scripts now exist and are syntax-validated:
  - `scripts/validate-pg18.sh`
  - `scripts/triage-pg18-failure.sh`
  - `scripts/promote-pg18-safe-outs.sh`
- Docker exists on this host at `/usr/bin/docker`

## Current unverified state on this host

Still unverified here because `nix` is not available in PATH:

- actual `nix build` of `psql_18/bin`
- actual `nix build` of `psql_18_slim/bin`
- actual `nix build` of PG18 bootstrap extensions
- actual `nix build` of focused PG18 checks
- actual `nix run .#docker-image-test -- --no-build Dockerfile-18`

## PG18 bootstrap extension set currently declared

Current PG18-enabled extension entries in `nix/ext/versions.json`:

- `pg_jsonschema` `0.3.4`
- `pg_cron` `1.6.7`
- `pg_net` `0.20.3`
- `pgaudit` `18.0`
- `pgmq` `1.11.1`
- `postgis` `3.6.3`
- `vector` `0.8.2`

Count: 7 PG18 extension entries.

## Biggest remaining technical gaps

### 1. Runtime acceptance gap
The repo now has a reproducible validation path, but no executed acceptance evidence on this host.

### 2. Extension VM test matrix still leans 15 -> 17 -> orioledb-17
Several extension tests are still structurally centered on:
- `psql_15`
- `psql_17`
- `orioledb-17`
- explicit upgrade-path calls like `check_upgrade_path("15")` and `check_upgrade_path("17")`

That means PG18 is not yet broadly represented in the extension VM test matrix.

### 3. First-pass regression fixture reuse may need explicit PG18 siblings
There are currently:
- 5 `z_17_*` SQL fixtures
- 0 `z_18_*` SQL fixtures

This is acceptable for the first pass, but only until real PG18 runtime evidence says otherwise.

## Exact path to 100%

### Phase A — decisive build proof
Run:

```bash
scripts/validate-pg18.sh --skip-docker-test
```

Acceptance for Phase A:
- all core builds pass
- all targeted PG18 extension builds pass
- focused PG18 checks pass
- Dockerfile-18 builds

### Phase B — decisive runtime regression proof
Run:

```bash
scripts/validate-pg18.sh
```

Acceptance for Phase B:
- `nix run .#docker-image-test -- --no-build Dockerfile-18` passes
- or fails with preserved artifacts that can be triaged deterministically

### Phase C — divergence resolution if needed
If runtime regression fails:

```bash
scripts/triage-pg18-failure.sh --validation-log-dir tmp/pg18-validation
```

Then either:

```bash
scripts/promote-pg18-safe-outs.sh --bundle /tmp/pg18-triage-out/<stamp>
```

or:

```bash
scripts/promote-pg18-safe-outs.sh --bundle /tmp/pg18-triage-out/<stamp> --as-z18
```

Acceptance for Phase C:
- only reviewed-safe `.out` files are promoted
- shared patched outputs are not copied back blindly
- any real PG18-only divergence is captured intentionally as `z_18_*`

### Phase D — extension test matrix hardening
After first pass is green, expand PG18 coverage where still structurally 15/17-only.

Acceptance for Phase D:
- PG18 appears not only in bootstrap/image path, but also where extension upgrade/runtime tests should explicitly cover it

## Honest verdict

Current verdict: incomplete

Reason:
- the repo has a credible PG18 path and reusable verification tooling
- but "100% functioning" still requires real build/runtime execution on a host with Nix available

## Next operator move

On the first host with working Nix:

```bash
scripts/validate-pg18.sh
```

That is the shortest truthful path toward proving or disproving the 100% claim.
