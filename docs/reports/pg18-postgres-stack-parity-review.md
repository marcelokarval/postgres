# PG18 postgres stack parity review

Date: 2026-06-14
Scope: local Portainer-saved YAML exports and read-only live Docker Swarm inspection for `postgres`, `postgres18`, and `pgadmin`.
Runtime mutation: none.
Secrets: omitted/redacted.

## Inputs reviewed

- `.tmp/portainer-pg18/postgres.portainer.yml`
- `.tmp/portainer-pg18/postgres18.portainer.yml`
- `.tmp/portainer-pg18/pgadmin.portainer.yml`
- live Swarm specs for:
  - `postgres_postgres`
  - `postgres18_postgres`
  - `pgadmin_pgadmin`
- pgAdmin SQLite registry, read-only query of server metadata only.
- DNS checks from the running pgAdmin container.

## Executive summary

`postgres18` is running, but its Portainer-saved stack file is materially less complete than the existing `postgres` stack. The highest-risk issue is volume identity: the saved `postgres18` YAML declares a non-external `postgres18_data` volume, so Swarm materializes it as `postgres18_postgres18_data`. That is the actual current data volume and must be preserved explicitly before any Portainer update.

`postgres18` should gain the operational parity items from `postgres` that do not conflict with PG18: explicit hostname, healthcheck, resource limits, manager placement, and command-level tuning. Its PG18-specific command/config must be preserved: keep `postgres -D /etc/postgresql`, keep data at `/var/lib/postgresql/data`, keep config at `/etc/postgresql/postgresql.conf`, and keep the PG18 preload set `pg_stat_statements,pgaudit,pg_cron,pg_net,pg_tle,safeupdate` rather than copying the PG17 preload list verbatim.

pgAdmin currently has only one registered server named `postgres`, with host `postgres`. From inside pgAdmin, `postgres18` does not resolve, while `postgres18_postgres` does. The likely fix is to register/fix the PG18 server in pgAdmin with host `postgres18_postgres`, port `5432`, maintenance DB `postgres`, and user `supabase_admin`.

## Saved YAML comparison

### Image and service identity

- `postgres` saved YAML:
  - service: `postgres`
  - image: `supabase/postgres:17.6.1.064`
  - hostname: `{{.Service.Name}}.{{.Task.Slot}}`
- `postgres18` saved YAML:
  - service: `postgres`
  - image: `local/supabase-postgres:18-karval`
  - no explicit hostname

Adjustment: add the same hostname template to `postgres18` for parity and easier task identity in logs/diagnostics.

### Command/config

- `postgres` saved YAML runs `postgres` with explicit `-c` tuning:
  - `max_connections=500`
  - `shared_buffers=3GB`
  - `work_mem=128MB`
  - `maintenance_work_mem=128MB`
  - `log_min_messages=fatal`
  - `listen_addresses=*`
  - `shared_preload_libraries=pg_net,pg_cron,pg_stat_statements,pgaudit,pg_stat_monitor`
- `postgres18` saved YAML runs:
  - `postgres -D /etc/postgresql`

Adjustment: keep `-D /etc/postgresql` for the PG18 image, then add the comparable `-c` tuning. Do not copy `pg_stat_monitor` from PG17 unless separately verified for this PG18 image. Preserve the current PG18 preload set:

```yaml
command:
  - postgres
  - -D
  - /etc/postgresql
  - -c
  - max_connections=500
  - -c
  - shared_buffers=3GB
  - -c
  - work_mem=128MB
  - -c
  - maintenance_work_mem=128MB
  - -c
  - log_min_messages=fatal
  - -c
  - listen_addresses=*
  - -c
  - shared_preload_libraries=pg_stat_statements,pgaudit,pg_cron,pg_net,pg_tle,safeupdate
```

### Environment

- `postgres` saved YAML:
  - `POSTGRES_USER=postgres`
  - `POSTGRES_DB=postgres`
  - `POSTGRES_HOST_AUTH_METHOD=md5`
  - password present in source but not repeated here
- `postgres18` saved YAML:
  - `POSTGRES_USER=supabase_admin`
  - `POSTGRES_DB=postgres`
  - no `POSTGRES_HOST_AUTH_METHOD`
  - password present in source but not repeated here

Adjustment: keep `POSTGRES_USER=supabase_admin` unless there is a deliberate migration plan to change roles. Add `POSTGRES_HOST_AUTH_METHOD: md5` only if this matches the intended auth policy for the PG18 image and clients. This is a parity candidate, but it should be validated against the existing `pg_hba.conf` and password encryption expectations before deployment.

### Healthcheck

- `postgres` saved YAML has:
  - `pg_isready -U postgres -h localhost`
  - interval 5s, timeout 5s, retries 10
- `postgres18` saved YAML has no explicit stack healthcheck.
- Live container status for `postgres18_postgres` currently reports healthy, but the Swarm service spec has no explicit healthcheck override. This may be inherited from the image and is less visible/controlled from the saved stack file.

Adjustment:

```yaml
healthcheck:
  test: ["CMD-SHELL", "pg_isready -U supabase_admin -d postgres -h localhost"]
  interval: 5s
  timeout: 5s
  retries: 10
```

### Volumes

- `postgres` saved YAML:
  - service mount: `postgres_data:/var/lib/postgresql/data`
  - top-level volume is external with name `postgres_data`
- `postgres18` saved YAML:
  - service mount: `postgres18_data:/var/lib/postgresql/data`
  - top-level volume is not external
- live Swarm spec for `postgres18_postgres`:
  - actual source volume: `postgres18_postgres18_data`
  - target: `/var/lib/postgresql/data`
  - stack namespace label: `postgres18`

Risk: if the stack file is changed incorrectly, Portainer/Swarm may attach a different empty volume and start PG18 without the current data.

Required adjustment to preserve data:

```yaml
volumes:
  - postgres18_data:/var/lib/postgresql/data

volumes:
  postgres18_data:
    external: true
    name: postgres18_postgres18_data
```

This keeps the service-level logical name stable while explicitly binding it to the current real Docker volume.

### Networks and ports

- both stacks use `portainer_agent_network` as an external network.
- `postgres` publishes host port `5432` to target `5432`.
- `postgres18` publishes host port `54318` to target `5432`.

Adjustment: keep `54318:5432` or the equivalent long syntax. Inside the overlay network, clients such as pgAdmin should use service DNS and target port `5432`, not the published host port.

### Deploy/resources

- `postgres` saved YAML:
  - replicated, 1 replica
  - manager placement
  - resource limits: `2.5` CPUs, `2560M` memory
- `postgres18` saved YAML:
  - 1 replica
  - manager placement
  - restart policy `on-failure`
  - no resource limits

Adjustment: add resource limits comparable to `postgres` unless PG18-specific sizing is intended:

```yaml
deploy:
  mode: replicated
  replicas: 1
  restart_policy:
    condition: on-failure
  placement:
    constraints:
      - node.role == manager
  resources:
    limits:
      cpus: "2.5"
      memory: 2560M
```

## Live Swarm observations

### `postgres_postgres`

- image: `supabase/postgres:17.6.1.064`
- published port: `5432 -> 5432/tcp`
- hostname template present
- explicit service healthcheck present
- volume: `postgres_data -> /var/lib/postgresql/data`
- resources: CPU and memory limits present
- command args include PG17 tuning and preload list

### `postgres18_postgres`

- image: `local/supabase-postgres:18-karval`
- published port: `54318 -> 5432/tcp`
- no hostname in service spec
- no explicit healthcheck in service spec
- volume: `postgres18_postgres18_data -> /var/lib/postgresql/data`
- no resource limits in service spec
- command args: `postgres -D /etc/postgresql`
- environment keeps `POSTGRES_USER=supabase_admin` and `POSTGRES_DB=postgres`

Important runtime facts from parent discovery to preserve:

- `data_directory` is `/var/lib/postgresql/data`.
- `config_file` is `/etc/postgresql/postgresql.conf`.
- current preload is `pg_stat_statements, pgaudit, pg_cron, pg_net, pg_tle, safeupdate`.
- overlay DNS: `postgres18_postgres` resolves; `postgres18` does not.

### `pgadmin_pgadmin`

- image: `dpage/pgadmin4`
- on `portainer_agent_network`
- Traefik labels present
- pgAdmin registry currently contains only:
  - name: `postgres`
  - host: `postgres`
  - port: `5432`
  - maintenance DB: `postgres`
  - username: `postgres`
- DNS from pgAdmin container:
  - `postgres` resolves
  - `postgres_postgres` resolves
  - `postgres18` does not resolve
  - `postgres18_postgres` resolves

## Recommended `postgres18` stack adjustment sketch

Use Portainer API for the eventual update, but the desired saved YAML shape should be equivalent to the following. Replace the password placeholder with the existing value through the normal secret-safe Portainer workflow; do not print it in logs or reports.

```yaml
version: "3.8"

services:
  postgres:
    image: local/supabase-postgres:18-karval
    hostname: "{{.Service.Name}}.{{.Task.Slot}}"

    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U supabase_admin -d postgres -h localhost"]
      interval: 5s
      timeout: 5s
      retries: 10

    environment:
      POSTGRES_PASSWORD: "<keep-existing-value>"
      POSTGRES_USER: supabase_admin
      POSTGRES_DB: postgres
      # Optional parity candidate; validate against PG18 auth policy before enabling:
      # POSTGRES_HOST_AUTH_METHOD: md5

    command:
      - postgres
      - -D
      - /etc/postgresql
      - -c
      - max_connections=500
      - -c
      - shared_buffers=3GB
      - -c
      - work_mem=128MB
      - -c
      - maintenance_work_mem=128MB
      - -c
      - log_min_messages=fatal
      - -c
      - listen_addresses=*
      - -c
      - shared_preload_libraries=pg_stat_statements,pgaudit,pg_cron,pg_net,pg_tle,safeupdate

    ports:
      - target: 5432
        published: 54318
        protocol: tcp
        mode: ingress

    volumes:
      - postgres18_data:/var/lib/postgresql/data

    networks:
      - portainer_agent_network

    deploy:
      mode: replicated
      replicas: 1
      restart_policy:
        condition: on-failure
      placement:
        constraints:
          - node.role == manager
      resources:
        limits:
          cpus: "2.5"
          memory: 2560M

volumes:
  postgres18_data:
    external: true
    name: postgres18_postgres18_data

networks:
  portainer_agent_network:
    external: true
    name: portainer_agent_network
```

## pgAdmin likely fix

Register or correct a pgAdmin server entry for PG18 with:

- Name: `postgres18` or `postgres18_postgres`
- Host: `postgres18_postgres`
- Port: `5432`
- Maintenance database: `postgres`
- Username: `supabase_admin`
- Password: use the existing PG18 password, not recorded here

Do not use host `postgres18`; it does not resolve from the pgAdmin overlay network. Do not use port `54318` from pgAdmin unless connecting via the host/published-port path; pgAdmin is already on the overlay and should use service DNS plus target port `5432`.

## Risks and controls

1. Data volume switch/loss risk: high if `postgres18_data` remains non-external in a rewritten stack or is mapped to the wrong name. Control: explicitly set `external: true` and `name: postgres18_postgres18_data`.
2. PG18 extension regression risk: medium if the PG17 preload string is copied verbatim. Control: preserve `pg_stat_statements,pgaudit,pg_cron,pg_net,pg_tle,safeupdate`.
3. Config path regression risk: medium if `-D /etc/postgresql` is removed. Control: keep `postgres -D /etc/postgresql` and append `-c` settings after it.
4. pgAdmin connectivity risk: medium if the registration uses `postgres18` or published port assumptions. Control: use `postgres18_postgres:5432` from overlay.
5. Auth compatibility risk: low/medium around `POSTGRES_HOST_AUTH_METHOD=md5`. Control: treat it as a parity candidate and validate before enabling if clients rely on SCRAM or an existing `pg_hba.conf` policy.

## Conclusion

The safe next mutation step is a Portainer API stack update for `postgres18` using the adjusted stack shape above, followed by re-fetching the saved StackFileContent and validating service convergence. The single non-negotiable adjustment is preserving the current real volume `postgres18_postgres18_data` as an external volume mapping. pgAdmin should then receive a PG18 server registration targeting `postgres18_postgres:5432`.
