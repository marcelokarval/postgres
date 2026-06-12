# PG18 Realtime v2 + LLM Docs — Final Report

Date: 2026-06-12
Status: DELIVERED_PASS
Owner/governor: Thor/default
Mode: parent orchestrator/reviewer with bounded subagents

## 1. Executive summary

This slice promoted the PG18 realtime explanation into living documentation and evolved the local database-centric realtime proof from MVP to v2.

Delivered:

- Explicit realtime WebSocket architecture documentation with user and developer views.
- Root `llms.txt` and `llms-full.txt` for LLM/Hermes agent context discovery.
- Realtime v2 runtime contract:
  - replay/cursor;
  - scopes/topics;
  - database-owned subscription authorization check;
  - durable ACK storage;
  - future fanout shape without mandatory Redis/NATS.
- Web proof UI for profile, subscribe/replay, publish, ACK, denied subscription and invalid token.
- Parent-owned runtime smoke over the actual compose stack and PG18 RC1 image digest.
- Browser-proof + vision QA.
- Side-by-side task review.

Final verdict: `DELIVERED_PASS` for repo-local documentation + realtime v2 proof.

This is not a production/VPS deployment claim.

## 2. Baseline and image identity

Current PG18 RC1 image:

```text
registry tag: registry.arthuragrelli.com/supabase-postgres:18-karval-rc1
registry digest: sha256:c477d5146ea51f235b811c093363c3ed5d8a342dbed8efac7635a1b9779e2f9f
digest-pinned reference: registry.arthuragrelli.com/supabase-postgres@sha256:c477d5146ea51f235b811c093363c3ed5d8a342dbed8efac7635a1b9779e2f9f
```

Runtime proof used the durable local stack:

```text
docker/pg18-postgrest-rls/
```

## 3. Files delivered

Planning/review/report stack:

```text
docs/pg18-realtime-v2-llms-prd.md
docs/pg18-realtime-v2-llms-tasks.md
docs/pg18-realtime-v2-llms-task-reviews.md
docs/pg18-realtime-v2-llms-browser-proof.html
docs/pg18-realtime-v2-llms-final-report.md
```

Living documentation / LLM context:

```text
docs/pg18-realtime-websocket-architecture.md
llms.txt
llms-full.txt
README.md
```

Runtime implementation:

```text
docker/pg18-postgrest-rls/init/001-api-rls.sql
docker/pg18-postgrest-rls/realtime/server.js
docker/pg18-postgrest-rls/realtime/test-client.js
docker/pg18-postgrest-rls/web/serve.py
```

Subagent monitor artifacts:

```text
.tmp/pg18-realtime-v2-llms/subagents/SA-01-status.md
.tmp/pg18-realtime-v2-llms/subagents/SA-01-final.md
.tmp/pg18-realtime-v2-llms/subagents/SA-02-status.md
.tmp/pg18-realtime-v2-llms/subagents/SA-02-final.md
```

These `.tmp` files are intentionally local evidence and not committed unless policy changes.

## 4. Documentation delivered

### 4.1 Realtime architecture doc

Created:

```text
docs/pg18-realtime-websocket-architecture.md
```

It documents:

- user view;
- developer view;
- step-by-step event flow;
- Postgres as durable source of truth;
- PostgREST as command/RPC gateway;
- WebSocket as transport adapter;
- `event_outbox` durability vs `LISTEN/NOTIFY` transient signal;
- JWT/RLS identity model;
- v2/future direction for replay, scopes, ACK, and fanout.

### 4.2 `llms.txt`

Created:

```text
llms.txt
```

Purpose:

- concise LLM/agent entrypoint;
- current RC digest;
- canonical docs links;
- runtime commands;
- safety guidance;
- non-claims.

This follows the public `llms.txt` convention: Markdown optimized for LLM discovery and navigation.

### 4.3 `llms-full.txt`

Created:

```text
llms-full.txt
```

Purpose:

- fuller repo/agent context packet;
- architecture and runtime map;
- docs and file paths;
- validation commands;
- PG18 RC identity;
- realtime contract;
- production gates and safety boundaries.

## 5. Realtime v2 delivered

### 5.1 Replay/cursor

Client can subscribe with:

```json
{"type":"subscribe","scope_type":"user","scope_id":"user_karval_demo","topic":"proof.realtime","last_event_id":0}
```

Bridge returns replay:

```json
{"type":"replay","events":[...]}
```

Runtime evidence:

```text
replay from cursor 0 returned event id=1 with acked_at populated
```

### 5.2 Scopes/topics

`private.event_outbox` now carries:

```text
scope_type
scope_id
topic
```

Initial proof uses:

```text
scope_type = user
scope_id = user_karval_demo
topic = proof.realtime
```

This prepares future `org`, `project`, `room`, `account` scopes without changing producers.

### 5.3 DB-owned subscription check

Implemented:

```text
private.can_subscribe_for_user(...)
api.can_subscribe(...)
private.bridge_can_subscribe(...)
```

Runtime evidence:

```text
api.can_subscribe user/user_karval_demo proof.realtime -> true
api.can_subscribe user/user_other_demo proof.realtime -> false
```

The bridge asks Postgres before accepting a subscription. It no longer relies only on local JavaScript filtering.

### 5.4 Durable ACK/retry state

Implemented:

```text
private.realtime_event_acks
private.bridge_ack_event(...)
```

Runtime evidence:

```text
id | scope_type | scope_id          | topic          | ack_user         | acked
1  | user       | user_karval_demo | proof.realtime | user_karval_demo | t
2  | user       | user_karval_demo | proof.realtime | user_karval_demo | t
```

### 5.5 Fanout preparation

The schema and health metadata explicitly document optional future fanout:

```text
fanout_ready: ["redis", "nats"]
durable_source: private.event_outbox
```

No Redis/NATS/Kafka dependency was added.

## 6. Runtime proof executed by parent

### 6.1 Static gates

```text
PASS python3 -m py_compile docker/pg18-postgrest-rls/web/serve.py
PASS node --check docker/pg18-postgrest-rls/realtime/server.js
PASS node --check docker/pg18-postgrest-rls/realtime/test-client.js
PASS docker compose -f docker/pg18-postgrest-rls/compose.pg18-postgrest-rls.yml config
```

### 6.2 Clean compose startup

The stack was started from a clean compose state with volumes removed:

```text
pg18-rls-db          healthy, image pinned to PG18 RC1 digest
pg18-rls-postgrest   running
pg18-rls-realtime    running
pg18-rls-web         running
```

Health evidence:

```json
{
  "status": "ok",
  "clients": 1,
  "fanout": "postgres-listen-notify",
  "durable_source": "private.event_outbox"
}
```

### 6.3 HTTP/RLS evidence

`/api/current-profile` returned:

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

Anon direct PostgREST call was denied:

```text
POST /rpc/current_profile -> HTTP 401
permission denied for schema private
```

### 6.4 WebSocket v2 evidence

Live subscribe/event/ACK smoke returned:

```json
{"type":"ready","app_user_id":"user_karval_demo","transport":"pg-listen-notify","durable_source":"private.event_outbox"}
{"type":"subscribed","scope_type":"user","scope_id":"user_karval_demo","topic":"proof.realtime","last_event_id":0}
{"type":"replay","events":[]}
{"type":"event","event":{"id":1,"topic":"proof.realtime","scope_type":"user","scope_id":"user_karval_demo","app_user_id":"user_karval_demo"}}
{"type":"ack","event_id":1,"app_user_id":"user_karval_demo"}
```

Replay after event returned event history:

```text
replay from cursor 0 included event id=1 and acked_at
```

Negative paths:

```text
denied subscription -> error code subscription_denied, close 1008
invalid token -> error invalid jwt signature, close 1008
```

## 7. Browser-proof + vision

Target:

```text
http://127.0.0.1:18083/
```

Browser DOM evidence:

```text
Title: PG18 RLS + Realtime v2 Web Proof
HTTP Status: publish 200 OK
Last event id: 2
Last ACK: event 2 @ 2026-06-12T20:40:26.302476+00:00
User: user_karval_demo
Plan: rc1
Role: authenticated
Postgres: 18.0
Replay present: true
ACK present: true
Denied subscription present: true
Invalid token present: true
Console messages: 0
JS errors: 0
```

Vision QA:

```text
PASS visual. Page rendered correctly with controls for current_profile, Subscribe/replay, publish, ACK, subscription denied, invalid token; status publish 200 OK; event and ACK visible; replay and negative proofs present in the realtime payload.
```

Observation:

```text
After clicking the invalid-token proof button, the Realtime Status field shows `error invalid jwt signature`. This is expected and part of the negative proof; the payload also contains the successful replay/event/ACK path.
```

Persisted browser artifact:

```text
docs/pg18-realtime-v2-llms-browser-proof.html
```

## 8. Subagent orchestration and monitoring

Two subagents were used in one bounded wave.

| Agent | Scope | Status | Final file | Parent action |
|---|---|---|---|---|
| SA-01 | Documentation + LLM docs | COMPLETED_PASS_WARN | `.tmp/pg18-realtime-v2-llms/subagents/SA-01-final.md` | Parent read final, inspected docs, accepted after review |
| SA-02 | Realtime v2 implementation | COMPLETED_PASS_WARN | `.tmp/pg18-realtime-v2-llms/subagents/SA-02-final.md` | Parent ran decisive static/runtime/browser gates |

No subagent was classified as stuck. Both completed and their slots were closed. The parent did not trust self-report alone; all decisive gates were rerun in the parent session.

## 9. Requested vs delivered

| Requested | Delivered | Status |
|---|---|---|
| Turn explanation into explicit documentation | `docs/pg18-realtime-websocket-architecture.md` created and README-linked | PASS |
| Create and feed `llms.txt` and `llms-full.txt` | Root files created with current digest, docs map, commands, safety and non-claims | PASS |
| Use accelerate / orchestrator pattern | PRD/tasks first, bounded subagents, parent final review, active verification | PASS |
| Build complete PRD | `docs/pg18-realtime-v2-llms-prd.md` | PASS |
| Build detailed task ledger from PRD | `docs/pg18-realtime-v2-llms-tasks.md` | PASS |
| Start execution | Two subagents executed docs/runtime lanes; parent ran final runtime/browser gates | PASS |
| Review by task and final review | `docs/pg18-realtime-v2-llms-task-reviews.md` | PASS |
| Correct actively without HITL | Parent converted runtime WARN into actual clean compose/browser proof | PASS |
| Browser-proof + vision | Real browser DOM/console/vision QA over running local stack | PASS |
| Mark tasks delivered | Ledger updated to `DELIVERED_PASS`; final commit gate pending until commit | PASS |
| Final report persisted and shown in chat | This file; chat final will summarize and include next steps | PASS |

## 10. What is not claimed

- No production/VPS deployment proof.
- No public internet/TLS proof.
- No Redis/NATS/Kafka runtime implementation.
- No multi-instance bridge coordination.
- No non-user scope authorization model beyond the extension point.
- No load/stress test.
- No final Supabase hosted stack parity claim.

## 11. Next-step questions

1. Should v3 prioritize multi-scope authorization (`org`, `project`, `room`) or production hardening first?
2. Should ACK semantics become strict delivery tracking with retry/dead-letter, or remain client-side read receipt initially?
3. Should replay use a client-provided cursor only, or should the backend persist per-client cursor state?
4. Should Redis/NATS be introduced for fanout now, or only after local load tests show `LISTEN/NOTIFY` pressure?
5. Should the next proof include desktop Python/Nuitka and mobile-style WebSocket clients against the same contract?

## 12. Recommended next steps

1. Add deterministic integration test script for realtime v2 so browser/runtime proof is repeatable without manual clicks.
2. Add `org`/`room` scope tables and extend `private.can_subscribe_for_user` with real membership checks.
3. Add persisted subscription/cursor model:
   - `private.realtime_subscriptions`;
   - `last_delivered_event_id`;
   - `last_acked_event_id`.
4. Add reconnection proof:
   - client connects;
   - receives event;
   - disconnects;
   - events are published while offline;
   - reconnects with cursor;
   - replay receives missing events.
5. Add production hardening checklist:
   - TLS/WSS;
   - short JWT TTL;
   - origin policy;
   - rate limiting;
   - structured logs without secrets;
   - health/metrics endpoints.
6. Optional later: Redis/NATS fanout worker from `event_outbox`, preserving Postgres as source of truth.

## 13. Final verdict

`DELIVERED_PASS` for repo-local PG18 realtime v2 + LLM documentation slice.

The database-centric architecture remains intact:

```text
Postgres = truth, authorization and durable event log
PostgREST = command/RPC gateway
WebSocket bridge = realtime transport adapter
Web/web/desktop/mobile clients = consumers of the same HTTP + WS contract
```
