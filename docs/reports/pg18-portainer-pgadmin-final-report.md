# Final Report — postgres18 Portainer/pgAdmin Parity Slice

Date: 2026-06-14
Verdict: DELIVERED_LOCAL_PORTAINER_PGADMIN_PARITY
Runtime: local Docker Swarm + local Portainer API
Secrets: redacted/omitted

## Executive summary

The local Swarm `postgres18` stack has been compared against the existing `postgres` stack, re-shaped through the Portainer API, and validated as healthy with PG18 runtime settings preserved.

The pgAdmin issue was diagnosed as a registration/DNS mismatch: pgAdmin had only a `postgres` server entry, and the attempted/obvious hostname `postgres18` does not resolve from the overlay network. The correct Swarm service DNS name is `postgres18_postgres` on internal port `5432`.

A `postgres18` server entry was added to pgAdmin with host `postgres18_postgres`, port `5432`, maintenance DB `postgres`, username `supabase_admin`, and the existing saved encrypted password blob already present in pgAdmin for the same database password. No password was printed or persisted in repo artifacts.

## Requested vs delivered

| Requested | Delivered | Evidence | Verdict |
|---|---|---|---|
| Compare postgres18 YAML with postgres YAML | Compared Portainer-saved files and live Swarm specs | `docs/reports/pg18-postgres-stack-parity-review.md` | PASS |
| Readequate postgres18 following postgres stack logic | Added hostname, healthcheck, tuning args, resource limits, preserved manager placement/network/port | Portainer saved file and service inspect | PASS |
| Use Portainer API so dashboard remains administrable | `PUT /api/stacks/29?endpointId=1` returned 200, saved StackFileContent updated | runtime evidence below | PASS |
| Preserve current postgres18 data | Volume explicitly maps logical `postgres18_data` to external `postgres18_postgres18_data` | service inspect mount source | PASS |
| Do not regress PG18 extensions/preload | Preserved PG18 preload: `pg_stat_statements,pgaudit,pg_cron,pg_net,pg_tle,safeupdate` | SQL runtime settings | PASS |
| Diagnose pgAdmin access issue | Found only server `postgres`; `postgres18` DNS does not resolve; `postgres18_postgres` resolves | pgAdmin DB and network probes | PASS |
| Correct pgAdmin registration | Inserted/updated pgAdmin server `postgres18` with host `postgres18_postgres` | SQLite registry safe readback | PASS |

## Portainer API update

Endpoint:

```text
local Portainer API
stack: postgres18
stack id: 29
endpoint id: 1
method: PUT /api/stacks/29?endpointId=1
status: 200
```

The updated saved stack file is represented in repo, secret-free, at:

```text
docker/postgres18.portainer.stack.yml
```

Portainer saved file was re-fetched after update and matched the intended shape, with `POSTGRES_PASSWORD` redacted in evidence.

## Stack comparison summary

`postgres` already had:

```text
hostname template
healthcheck
command tuning
resource limits
external named volume
portainer_agent_network
published port 5432 -> 5432
```

`postgres18` previously had:

```text
image local/supabase-postgres:18-karval
POSTGRES_USER=supabase_admin
postgres -D /etc/postgresql
published port 54318 -> 5432
portainer_agent_network
non-external volume declaration materialized as postgres18_postgres18_data
no explicit hostname
no explicit healthcheck
no explicit resources
no command tuning
```

`postgres18` now has:

```text
hostname: {{.Service.Name}}.{{.Task.Slot}}
healthcheck: pg_isready -U supabase_admin -d postgres -h localhost
command: postgres -D /etc/postgresql plus tuning flags
resources: 2.5 CPUs / 2560M memory
volume: external postgres18_postgres18_data
network: external portainer_agent_network
port: 54318 -> 5432
```

## Runtime evidence after Portainer update

Service convergence:

```text
postgres18_postgres replicas=1/1
latest task: Running
```

Container status:

```text
status=running
health=healthy
```

Runtime SQL settings:

```text
server_version=18.0
data_directory=/var/lib/postgresql/data
config_file=/etc/postgresql/postgresql.conf
max_connections=500
shared_buffers=3GB
work_mem=128MB
maintenance_work_mem=128MB
shared_preload_libraries=pg_stat_statements,pgaudit,pg_cron,pg_net,pg_tle,safeupdate
pgaudit_available=18.0
```

Service inspect after update:

```text
image=local/supabase-postgres:18-karval
hostname={{.Service.Name}}.{{.Task.Slot}}
args include postgres -D /etc/postgresql and tuning flags
healthcheck present
mount source=postgres18_postgres18_data target=/var/lib/postgresql/data
resources limits present
published port=54318 target=5432
```

## pgAdmin diagnosis

Before correction, pgAdmin server registry contained only:

```text
name=postgres
host=postgres
port=5432
maintenance_db=postgres
username=postgres
```

DNS/access findings:

```text
postgres18_postgres resolves/reachable from overlay
postgres18 does not resolve from pgAdmin overlay
internal clients must use port 5432, not host-published 54318
```

Therefore the correct pgAdmin registration is:

```text
name=postgres18
host=postgres18_postgres
port=5432
maintenance_db=postgres
username=supabase_admin
```

This entry was added to pgAdmin DB:

```text
server_id=12
name=postgres18
host=postgres18_postgres
port=5432
maintenance_db=postgres
username=supabase_admin
save_password=1
```

Password handling:

```text
No password printed.
No password persisted in repo.
Reused existing encrypted pgAdmin password blob because postgres and postgres18 currently share the same database password.
```

## SQL connectivity proof

From a container on the same overlay network using service DNS:

```text
auth_sql_ok=supabase_admin@postgres:v18.0
```

From pgAdmin container:

```text
TCP postgres18_postgres:5432 ok
```

The pgAdmin container did not expose `psycopg`/`psycopg2` in its global Python environment, so direct SQL from that global interpreter could not be used. SQL auth was proven from an overlay container with `psql`; pgAdmin network reachability to the same service host/port was proven by socket.

## Files persisted

```text
docs/pg18-portainer-pgadmin-prd.md
docs/pg18-portainer-pgadmin-tasks.md
docs/reports/pg18-postgres-stack-parity-review.md
docs/reports/pg18-portainer-pgadmin-final-report.md
docker/postgres18.portainer.stack.yml
```

## Residual notes

1. The current PG18 image remains local-tag based: `local/supabase-postgres:18-karval`. If this stack should be portable across nodes, next step is using the immutable registry digest in the Portainer stack file.
2. `POSTGRES_HOST_AUTH_METHOD` was intentionally not copied from PG17. PG18 is working with current auth, and changing this could be a behavioral regression.
3. `pg_stat_monitor` was intentionally not copied from PG17 preload. The PG18 accepted preload includes `pg_stat_statements,pgaudit,pg_cron,pg_net,pg_tle,safeupdate`.
4. If pgAdmin UI does not show the new server immediately due to application caching, refresh the browser session first. If still not visible, restart only the pgAdmin service through Portainer; the registry row is already present.

## Recommended next steps

1. Replace local image tag with registry digest in `postgres18` stack once you want multi-node/portable Portainer management.
2. Add a small pgAdmin server bootstrap artifact/runbook, so future PG stacks can be registered without direct SQLite manipulation.
3. Continue the deeper Prop4You core scan before project DDL implementation.
4. Build a pgaudit comparison slice using official docs/community examples and then decide whether to add optional `CREATE EXTENSION pgaudit` policy to base/runtime DDL.
