# PRD — postgres18 Portainer/pgAdmin Parity Slice

Status: ACTIVE_PRD
Date: 2026-06-14
Owner: Thor/default as orchestrator and final reviewer

## Objective

Bring the local Swarm `postgres18` stack closer to the existing `postgres` stack shape while preserving PG18-specific runtime requirements, keeping the stack administrable through Portainer Dashboard/API, and correcting pgAdmin access/registration for PostgreSQL 18.

## User requirements

```text
1. Compare the YAML of postgres18 with postgres.
2. Re-adjust postgres18 following the logic of postgres.
3. Use the Portainer API so postgres18 remains administrable from the Portainer dashboard.
4. Diagnose/correct why postgres18 cannot be registered/accessed from pgAdmin.
5. Do not regress the PG18 extension/runtime work already achieved.
```

## Scope

In scope:

```text
- Local Portainer API only.
- Stacks: postgres, postgres18, pgadmin.
- Portainer saved StackFileContent comparison and update.
- Live Swarm service validation.
- pgAdmin server registry/connectivity validation.
- PII/secret-safe reports.
```

Out of scope:

```text
- Production/remote Portainer mutation.
- Registry push/image rebuild.
- Dropping/removing database volumes.
- Replacing existing postgres 17 stack.
- Creating project databases unless explicitly justified.
```

## Guardrails

```text
- Never print POSTGRES_PASSWORD or pgAdmin password in reports/chat.
- Preserve current postgres18 data volume; do not switch to an empty volume silently.
- Use Portainer API for stack update, not raw docker stack deploy, when changing postgres18 saved stack file.
- Verify Portainer saved file after update.
- Verify live Swarm convergence after update.
```

## Acceptance

```text
- Comparison report exists.
- postgres18 Portainer saved YAML has healthcheck/hostname/resources/config parity where appropriate.
- postgres18 uses external volume mapping to the current real data volume, avoiding data loss.
- postgres18 remains reachable as postgres18_postgres:5432 on portainer_agent_network.
- pgAdmin has a postgres18 server registration with host postgres18_postgres and port 5432.
- psql proof from pgAdmin or same overlay network succeeds.
- Final report records requested-vs-delivered and residuals.
```
