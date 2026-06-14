# Tasks — postgres18 Portainer/pgAdmin Parity Slice

Status: ACTIVE_TASK_LEDGER
Date: 2026-06-14

## T01 — Runtime/source discovery

Status: DONE

Acceptance:

```text
Portainer endpoint/stacks identified.
postgres/postgres18/pgadmin saved files exported to .tmp.
Live Swarm specs inspected with secrets redacted.
```

## T02 — YAML comparison

Status: DONE

Acceptance:

```text
Compare postgres vs postgres18 saved YAML: service options, command, healthcheck, env, volumes, networks, ports, deploy resources.
```

## T03 — Readequate postgres18 via Portainer API

Status: DONE

Acceptance:

```text
Portainer PUT updates stack postgres18.
Saved StackFileContent re-fetched.
Service converges 1/1.
No volume loss; actual data volume preserved.
```

## T04 — pgAdmin diagnosis/correction

Status: DONE

Acceptance:

```text
Existing pgAdmin server registry inspected.
postgres18 server registration added/fixed.
Connectivity proof succeeds.
```

## T05 — Verification and report

Status: DONE

Acceptance:

```text
Runtime psql proof, pgAdmin registry proof, Portainer saved-file proof, final report persisted.
```
