# PG18 runner bootstrap

This guide is the shortest path to get a temporary Linux VM/runner ready for PG18 acceptance work.

## Target use case

Use this when the current workstation cannot run the real PG18 acceptance path because `nix` is missing, misconfigured, or too risky to install directly.

The target is a disposable Linux runner/VM where we can prove or falsify the claim:

> PostgreSQL 18 is functioning end-to-end in this fork.

## Recommended target profile

- Linux x86_64
- Ubuntu 24.04 LTS preferred
- Docker available or installable
- outbound access to:
  - `cache.nixos.org`
  - `nix-postgres-artifacts.s3.amazonaws.com`
  - `postgrest.cachix.org`
  - GitHub / upstream source hosts
- enough disk for Nix store + Docker image builds

## Single-entry bootstrap

From repo root:

```bash
scripts/bootstrap-pg18-runner.sh
```

Default behavior:
- installs base packages if needed
- installs/configures Nix for this repo
- installs Docker only if missing
- runs `scripts/validate-pg18.sh`

## Supported Nix modes

### 1. Official repo-aligned mode (default)

```bash
scripts/bootstrap-pg18-runner.sh --nix-mode official
```

This uses the official Nix `2.34.6` installer path documented in `nix/docs/start-here.md`, which is the closest match to the repo's documented CI/dev baseline.

### 2. Determinate mode

```bash
scripts/bootstrap-pg18-runner.sh --nix-mode determinate
```

Use this only when you explicitly prefer the Determinate installer operationally. The script still writes the repo-specific cache/trusted-key config into `/etc/nix/nix.conf` afterward.

## Safe dry preview

To print the exact plan without mutating the runner:

```bash
scripts/bootstrap-pg18-runner.sh --print-only
```

## Validation control

Skip validation and only bootstrap prerequisites:

```bash
scripts/bootstrap-pg18-runner.sh --skip-validation
```

Pass flags through to the PG18 validator:

```bash
scripts/bootstrap-pg18-runner.sh -- --skip-docker-test
scripts/bootstrap-pg18-runner.sh -- --skip-docker-build
```

## Output locations

Bootstrap summary:
- `tmp/pg18-runner-bootstrap/summary.txt`

Validation logs:
- `tmp/pg18-runner-bootstrap/validate-pg18.log`
- plus the underlying logs from `scripts/validate-pg18.sh`

## If validation fails

Use the checked-in failure path:

```bash
scripts/triage-pg18-failure.sh --validation-log-dir tmp/pg18-validation
```

Then decide promotion safely:

```bash
scripts/promote-pg18-safe-outs.sh --bundle /tmp/pg18-triage-out/<stamp> --dry-run
scripts/promote-pg18-safe-outs.sh --bundle /tmp/pg18-triage-out/<stamp>
# or
scripts/promote-pg18-safe-outs.sh --bundle /tmp/pg18-triage-out/<stamp> --as-z18
```

## Acceptance meaning

This bootstrap script does not by itself prove PG18 works.

It only creates the fastest reproducible path to execute the real proof:

```bash
scripts/validate-pg18.sh
```

PG18 reaches a truthful "100% functioning" claim only after the build/runtime path actually passes, or its remaining divergences are intentionally captured and resolved.
