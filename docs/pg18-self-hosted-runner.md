# Local self-hosted runner for PG18 validation

This lane uses a local GitHub Actions self-hosted runner so the PG18 acceptance workflow can execute against your own Docker host/Swarm-capable machine.

## Why this exists

The repo already has:
- `.github/workflows/pg18-validation.yml` for GitHub-hosted runners
- `scripts/bootstrap-pg18-runner.sh` for disposable Linux hosts/VMs

This adds a third path:
- a persistent local self-hosted runner with Docker socket access and persistent `/nix`

This is useful when:
- you want repeatable local image builds
- you want to exploit the current machine's Docker/Swarm surface
- you want to re-run the PG18 lane without re-provisioning a VM every time

## Files

- `.github/workflows/pg18-validation-self-hosted.yml`
- `docker/pg18-self-hosted-runner/Dockerfile`
- `docker/pg18-self-hosted-runner/compose.pg18-self-hosted-runner.yml`
- `docker/pg18-self-hosted-runner/.env.example`

## Workflow behavior

The self-hosted workflow mirrors the hosted lane, but runs on:
- `[self-hosted, blacksmith-4vcpu-ubuntu-2404]`

It has two jobs:
1. build + checks
2. docker runtime

The workflow uses the repo's existing self-hosted Nix action:
- `./.github/actions/nix-install-self-hosted`

That means the runner image must already have `nix` available in PATH.

## Runner image behavior

The runner image is based on:
- `myoung34/github-runner:latest`

It layers on top:
- Docker CLI
- curl/git/jq/sudo/xz-utils
- single-user Nix 2.34.6 for the runner account
- Nix config aligned to the repo cache/substituter settings

## Security/operational note

This runner mounts:
- `/var/run/docker.sock`
- persistent `/nix`
- persistent runner home/work volumes

So it is a privileged local CI surface. Treat it as equivalent to a trusted operator container.

## Prepare env file

```bash
cd docker/pg18-self-hosted-runner
cp .env.example .env
```

Fill:
- `REPO_URL`
- `RUNNER_TOKEN`
- optional `RUNNER_NAME`
- optional `LABELS`

## Bring the runner up

From the repo root:

```bash
docker compose \
  --env-file docker/pg18-self-hosted-runner/.env \
  -f docker/pg18-self-hosted-runner/compose.pg18-self-hosted-runner.yml \
  up -d --build
```

## Trigger the workflow

Run in GitHub Actions:
- `PG18 Validation (Self-Hosted)`

Or trigger manually with `workflow_dispatch`.

## Observe the runner locally

```bash
docker logs -f pg18-gha-runner
```

## Teardown

```bash
docker compose \
  --env-file docker/pg18-self-hosted-runner/.env \
  -f docker/pg18-self-hosted-runner/compose.pg18-self-hosted-runner.yml \
  down
```

If you want to wipe runner state too:

```bash
docker volume rm \
  postgres_pg18_runner_home \
  postgres_pg18_runner_tmp \
  postgres_pg18_runner_nix
```

Adjust the volume prefix if the compose project name differs.

## Honest limitation

This materializes the local runner lane, but it does not prove PG18 green by itself.

PG18 is only closer to production after one of these is actually green with real output:
- `scripts/validate-pg18.sh` on a Nix-capable host
- `.github/workflows/pg18-validation.yml`
- `.github/workflows/pg18-validation-self-hosted.yml`
