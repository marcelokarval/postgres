# PG18 RC1 Publish + Durable PostgREST/RLS/Realtime Stack — Final Report

Date: 2026-06-12
Status: DELIVERED_PASS
Owner/governor: Thor/default

## Executive summary

The PostgreSQL 18 fork now has a formal local release-candidate closeout:

- Full no-skip Nix/Docker validation passed in the persistent KVM-capable runner.
- The validated image was retagged and pushed to the ArthurAgrelli registry as RC1.
- The registry digest was captured and the durable local PostgREST/RLS stack was updated to pin it.
- A database-centric proof now covers PostgREST RPC, JWT claims, Postgres RLS, a web client, and a sibling realtime WebSocket bridge over `event_outbox + LISTEN/NOTIFY`.

## Image and registry evidence

```text
local validation tag: local/supabase-postgres:18-karval-full-validate
local image id: sha256:cb3e0e2e88054cc1ea6fc6ac34b9558b210a8e0e281269214248ad0cd829470a
registry tag: registry.arthuragrelli.com/supabase-postgres:18-karval-rc1
registry digest: sha256:c477d5146ea51f235b811c093363c3ed5d8a342dbed8efac7635a1b9779e2f9f
digest-pinned reference: registry.arthuragrelli.com/supabase-postgres@sha256:c477d5146ea51f235b811c093363c3ed5d8a342dbed8efac7635a1b9779e2f9f
```

Push evidence:

```text
18-karval-rc1: digest: sha256:c477d5146ea51f235b811c093363c3ed5d8a342dbed8efac7635a1b9779e2f9f size: 6563
```

## Full validation evidence

Source log:

```text
tmp/pg18-publish/full-validate-persistent-nix/summary.txt
```

Completed steps:

```text
01-psql_18_bin                  DONE
02-psql_18_slim_bin             DONE
03-ext-pg_jsonschema            DONE
04-ext-pgaudit                  DONE
05-ext-pgmq                     DONE
06-ext-postgis                  DONE
07-ext-vector                   DONE
08-ext-pg_cron                  DONE
09-ext-pg_net                   DONE
10-check-psql_18                DONE
11-check-psql_18_slim           DONE
12-check-postgresql_18_debug    DONE
13-check-postgresql_18_src      DONE
14-docker-build                 DONE
15-docker-image-test            DONE
PG18 validation sequence finished successfully
```

Docker runtime regression evidence:

```text
All 50 tests passed.
```

## Durable local stack

Path:

```text
docker/pg18-postgrest-rls/
```

Run:

```bash
cd docker/pg18-postgrest-rls
docker compose -f compose.pg18-postgrest-rls.yml up -d --build
```

Services:

- `pg18`: PG18 RC1 image pinned by digest.
- `postgrest`: RPC gateway over schema `api`.
- `web`: same-origin proof page/proxy.
- `realtime`: sibling WebSocket bridge; not baked into the PG image.

## Database-centric contract

Schemas/tables/functions:

- `private.account_profiles`: RLS-owned profile rows.
- `api.current_profile()`: JSONB RPC using JWT claim `app_user_id`.
- `private.event_outbox`: durable event source.
- `private.notify_event_outbox()`: trigger emits `pg_notify('app_events', ...)`.
- `api.publish_realtime_proof(text)`: JWT/RLS-aware RPC that inserts into outbox.

The client never connects to Postgres directly. Web/API clients go through PostgREST or the web proof proxy. Realtime uses a separate bridge process with JWT verification and event filtering by `app_user_id`.

## Runtime proof executed

RPC smoke:

```json
{
  "app_user_id": "user_karval_demo",
  "display_name": "Karval Demo",
  "plan": "rc1",
  "role": "authenticated",
  "jwt_app_user_id": "user_karval_demo",
  "postgres_version": "18.0"
}
```

Realtime smoke:

```json
{"type":"ready","app_user_id":"user_karval_demo","transport":"pg-listen-notify"}
{"type":"event","event":{"topic":"proof.realtime","app_user_id":"user_karval_demo"}}
```

Browser proof:

```text
URL: http://127.0.0.1:18083/
Title: PG18 RLS + Realtime Web Proof
DOM status: publish 200 OK
DOM realtime status: event received: proof.realtime
Console messages: 0
JS errors: 0
```

Negative proof:

```text
Anon direct PostgREST /rpc/current_profile: HTTP 401, permission denied for schema private
Invalid WebSocket token: close=1008, reason=invalid jwt format
```

## Requested vs delivered

| Requested | Delivered | Status |
|---|---|---|
| 1. Registrar evidência do RC/gate | Full no-skip summary + docker-image-test PASS documented | PASS |
| 2. Retag/push registry and capture digest | RC1 pushed to ArthurAgrelli registry with digest `sha256:c477d5146ea51f235b811c093363c3ed5d8a342dbed8efac7635a1b9779e2f9f` | PASS |
| 3. Implement MVP realtime WebSocket JWT/RLS | Node bridge + Postgres outbox + LISTEN/NOTIFY + web/browser proof | PASS |
| Add documentation layer | README, PRD, tasks, reviews and final report updated | PASS |

## Follow-up gates before production

1. Production/VPS deployment proof: remote service spec, newest task/container digest, health endpoints, clean logs.
2. Realtime hardening: replay cursor, reconnect semantics, ack/retry, multi-instance fanout, backpressure.
3. Optional Supabase Realtime spike: compare JWT/RLS compatibility, replication/publication overhead, operational complexity, and fit with the custom PG18 image.
4. Security hardening if exposed beyond local dev: TLS termination, token TTL, origin policy, rate limits, and no dev default credentials.
5. Separate semantic gates for `supautils` and `plan_filter` if enabling enforcement claims.

## Final verdict

`DELIVERED_PASS` for repo-local PG18 RC1 + database-centric PostgREST/RLS/realtime proof.

Not a production deployment claim.
