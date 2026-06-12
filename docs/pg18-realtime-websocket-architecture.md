# PG18 realtime WebSocket architecture

Status: living architecture note for the PG18 database-centric fork
Branch context: `karval/pg18-bootstrap`
Current RC digest: `sha256:c477d5146ea51f235b811c093363c3ed5d8a342dbed8efac7635a1b9779e2f9f`
Primary stack path: `docker/pg18-postgrest-rls/`

## Purpose

This document explains the current local realtime proof and the intended v2 direction for the PostgreSQL 18 database-centric fork.

The design goal is simple: Postgres remains the source of truth for state, authorization, durable event history and subscription decisions. PostgREST exposes database commands/RPCs. WebSocket is only a transport adapter for browser/client delivery.

## Explicit non-claims

This repository currently demonstrates a local database-image/dev-stack proof. It does not claim:

- full Supabase hosted platform stack parity;
- production or VPS deployment readiness;
- managed multi-tenant realtime infrastructure;
- Redis, NATS or Kafka as mandatory runtime dependencies;
- that the realtime bridge is baked into the PG18 database image.

Redis/NATS/Kafka may become useful future fanout transports, but they are not required for the current proof or the documented v2 database contract.

## User view

From a user or application-client perspective:

1. The browser opens the local proof page served by `docker/pg18-postgrest-rls/web/serve.py`.
2. The web proof creates a local JWT containing an `app_user_id` claim.
3. Profile and command actions call same-origin web endpoints, which proxy to PostgREST RPCs in schema `api`.
4. The client opens `ws://127.0.0.1:18084/ws?token=<jwt>` against the realtime bridge.
5. The bridge validates the JWT, accepts only authenticated users with an `app_user_id`, and returns a `ready` message.
6. When the user triggers a realtime publish action, PostgREST calls `api.publish_realtime_proof(...)` inside Postgres.
7. Postgres inserts a row into `private.event_outbox` and emits a `LISTEN/NOTIFY` signal on `app_events`.
8. The bridge receives the notification and forwards the event only to WebSocket clients whose authenticated `app_user_id` matches the event.
9. The browser displays the delivered event.

The important user-facing property is that commands go through PostgREST/Postgres and realtime delivery follows the same JWT user identity. WebSocket does not become the command authority.

## Developer view

Current implementation surfaces:

| Layer | Path | Responsibility |
|---|---|---|
| PG18 image | `Dockerfile-18`, compose image pin | Database runtime built from this fork; current accepted RC digest is listed above. |
| SQL/RLS/RPC | `docker/pg18-postgrest-rls/init/001-api-rls.sql` | Schemas, roles, JWT/RLS policies, `private.event_outbox`, trigger notification and `api.publish_realtime_proof`. |
| PostgREST | `docker/pg18-postgrest-rls/compose.pg18-postgrest-rls.yml` | HTTP gateway exposing `api` RPCs to authenticated JWT callers. |
| Web proof | `docker/pg18-postgrest-rls/web/serve.py` | Local browser proof, same-origin proxy and token creation for local-only validation. |
| Realtime bridge | `docker/pg18-postgrest-rls/realtime/server.js` | WebSocket adapter that validates JWT, listens to Postgres notifications and filters outgoing events. |
| Test client | `docker/pg18-postgrest-rls/realtime/test-client.js` | Local WebSocket smoke surface. |

The current bridge is intentionally small. It should stay transport-oriented:

- validate the JWT transport credential;
- map the connection to `app_user_id` and role;
- listen for Postgres notification signals;
- fetch/replay/ack through database APIs as v2 evolves;
- never become the durable policy engine.

## Step-by-step realtime flow

### Current v1 proof flow

1. Client obtains a local JWT with `role=authenticated` and `app_user_id=<user>`.
2. Client calls a PostgREST RPC command, currently `api.publish_realtime_proof(p_topic text default 'proof.realtime')`.
3. The RPC runs in Postgres and reads `request.jwt.claims` to identify the caller.
4. RLS and function logic ensure the inserted event belongs to the same `app_user_id`.
5. The RPC inserts into `private.event_outbox`:
   - `id bigserial primary key`;
   - `app_user_id text`;
   - `topic text`;
   - `payload jsonb`;
   - `created_at timestamptz`.
6. The `private.notify_event_outbox()` trigger runs after insert.
7. The trigger calls `pg_notify('app_events', <event json>)`.
8. The Node bridge has issued `LISTEN app_events` through the `realtime_bridge` database role.
9. On notification, the bridge parses the payload and checks each connected client's authenticated `app_user_id`.
10. Matching clients receive `{ "type": "event", "event": ... }` over WebSocket.
11. Non-matching clients do not receive the event.

### Why outbox plus NOTIFY

`private.event_outbox` is the durable event record. It survives bridge restarts and can support replay, cursor reads, auditing, ACK state and future fanout workers.

`LISTEN/NOTIFY` is only the low-latency signal that wakes the bridge for newly inserted rows. Notifications are not the source of truth and should not be treated as durable delivery storage.

This separation is central to the design:

- durable data: Postgres table(s);
- transient signal: `pg_notify`;
- client transport: WebSocket;
- command/API authority: PostgREST + Postgres RPC/RLS.

## JWT and RLS model

The local proof uses a shared local development JWT secret configured through compose. Treat this as local-only.

Expected JWT claims:

- `role`: must be `authenticated` for the current bridge;
- `app_user_id`: required user/application identity used by RLS and bridge filtering;
- standard expiry fields may be present and are checked by the bridge when `exp` exists.

PostgREST passes JWT claims to Postgres through `request.jwt.claims`. SQL policies compare table rows to the current `app_user_id`. For example, `private.event_outbox` SELECT/INSERT policies only allow rows whose `app_user_id` equals the JWT claim.

The bridge also validates the JWT before accepting a WebSocket connection, but this is a transport gate. The database remains responsible for durable authorization and must be consulted for v2 subscription decisions.

## PostgREST commands and RPCs

The command path is intentionally HTTP/RPC through PostgREST rather than arbitrary WebSocket commands.

Current command example:

```text
POST /rpc/publish_realtime_proof
Authorization: Bearer <local-dev-jwt>
```

The exposed SQL function inserts into the outbox and returns the inserted event. This keeps command validation, writes, RLS and event production inside Postgres.

For v2, new command/query surfaces should keep the same pattern: PostgREST/RPC should call SQL functions that enforce JWT-aware rules. The bridge may call database functions as an internal adapter, but it should not invent subscription authority outside Postgres.

## Realtime v2 direction

The next recommended level adds a durable protocol shape without introducing external fanout infrastructure as mandatory.

### Replay and cursor

Goal: reconnecting clients can request missed events after a known cursor.

Expected client message:

```json
{"type":"subscribe","last_event_id":123}
```

Expected bridge/database behavior:

1. Validate JWT and requested scope/topic.
2. Ask Postgres whether the user can subscribe.
3. Query durable events newer than `last_event_id` under RLS/subscription rules.
4. Send a replay envelope, for example:

```json
{"type":"replay","events":[...]}
```

The cursor should be based on the durable outbox identifier or another monotonic database-owned position.

### Scopes and topics

Current default is user-scoped delivery. v2 should make scope metadata explicit on events:

```text
scope_type text
scope_id text
topic text
```

Initial default:

```text
scope_type = 'user'
scope_id = <app_user_id>
```

Topics describe event categories such as `proof.realtime`; scopes describe who or what may subscribe. Keeping both fields allows future organization/project/team scopes without losing the current per-user proof.

### RLS-aware subscription check

The bridge must ask Postgres whether the authenticated user can subscribe to a requested scope/topic. Target shape:

```text
api.can_subscribe(p_scope_type text, p_scope_id text, p_topic text default null)
```

This keeps subscription policy in the database where it can share the same JWT/RLS model as PostgREST commands.

### ACK and retry tracking

Clients should be able to ACK delivered events:

```json
{"type":"ack","event_id":123}
```

Postgres should store ACK state durably, scoped to the JWT user. A future retry worker or replay query can then distinguish unseen, delivered and acknowledged events.

Recommended properties:

- ACK writes go through a database function or table protected by JWT-aware policy;
- ACK is idempotent for the same user/event;
- replay can optionally exclude acknowledged events or report ACK status;
- retry state remains database-owned, not memory-only inside the WebSocket bridge.

### Fanout future

The outbox schema should be shaped so future workers can fan out to Redis, NATS, Kafka or another delivery system. That worker would consume durable outbox rows and publish to external infrastructure.

Fanout is future-gated. Introducing it should not change the source of truth: Postgres still owns events, authorization, cursors and ACK state.

## Local run and validation commands

From repository root:

```bash
cd docker/pg18-postgrest-rls
docker compose -f compose.pg18-postgrest-rls.yml up -d --build
curl -fsS -X POST http://127.0.0.1:18083/api/current-profile
curl -fsS -X POST http://127.0.0.1:18083/api/publish-realtime
```

Static checks used by the current PRD:

```bash
python3 -m py_compile docker/pg18-postgrest-rls/web/serve.py
node --check docker/pg18-postgrest-rls/realtime/server.js
node --check docker/pg18-postgrest-rls/realtime/test-client.js
docker compose -f docker/pg18-postgrest-rls/compose.pg18-postgrest-rls.yml config
```

Browser proof target:

```text
http://127.0.0.1:18083/
```

Expected proof signals include profile display, publish success, WebSocket ready state and an event such as `proof.realtime` received by the page.

## Agent maintenance notes

- Documentation changes belong under `docs/`, root `llms.txt`, root `llms-full.txt` and small README links unless the task explicitly authorizes runtime edits.
- Do not print or commit secrets. The visible local defaults in compose are development-only placeholders.
- Do not claim production readiness unless a separate production/VPS gate has been run and documented.
- If docs conflict, prefer final reports and current PRD/task files over older bootstrap notes.
- Keep this document living: update it whenever the SQL contract, bridge protocol or proof commands change.
