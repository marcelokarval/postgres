# PG18 Realtime v2 + LLM Docs — PRD

Status: IN_PROGRESS
Date: 2026-06-12
Owner/governor: Thor/default
Mode: orchestrator/reviewer with bounded subagents

## 1. Executive goal

Evolve the PG18 database-centric realtime proof into a durable v2 slice and promote the realtime explanation into explicit living documentation, including LLM-friendly entrypoints for Hermes/agent consumption:

1. Create explicit architecture documentation for the current realtime model with user and developer views.
2. Create and maintain root `llms.txt` and `llms-full.txt` for AI/agent context discovery.
3. Implement the next recommended realtime level:
   - replay/cursor;
   - topics and scopes;
   - RLS-aware subscription checks;
   - ACK/retry tracking;
   - fanout preparation without making Redis/NATS mandatory.
4. Validate with real runtime smoke and browser-proof + vision.
5. Persist PRD/tasks/reviews/final report in the same docs stack.
6. Keep the parent agent as orchestrator/reviewer; use subagents only where they add value.

## 2. Current baseline

Current repo baseline:

- Branch: `karval/pg18-bootstrap`.
- Last accepted commit: `0d0a24e8 feat: publish pg18 rc1 realtime proof`.
- PG18 RC1 registry digest: `sha256:c477d5146ea51f235b811c093363c3ed5d8a342dbed8efac7635a1b9779e2f9f`.
- Durable local stack: `docker/pg18-postgrest-rls/`.
- Current realtime MVP:
  - `private.event_outbox` stores events;
  - trigger emits `pg_notify('app_events', ...)`;
  - Node WebSocket bridge validates JWT and filters by `app_user_id`;
  - web proof shows `publish 200 OK` and `event received: proof.realtime`.

## 3. Non-goals and guardrails

- No production/VPS deployment claim in this slice.
- No Redis/NATS requirement yet; fanout is a documented extension point only.
- Do not bake realtime into the PG18 database image.
- Do not bypass Postgres/RLS/JWT authorization.
- Do not print secrets or raw long-lived tokens.
- Keep dev credentials clearly marked as local-only.
- Do not use more than 3 subagents simultaneously; default target is 2.
- Subagents receive only needed toolsets.
- Parent reruns decisive gates and owns final review.

## 4. LLM documentation contract

Create root files:

```text
llms.txt
llms-full.txt
```

`llms.txt` should be concise Markdown with:

- project name and scope;
- current release-candidate state;
- canonical docs links;
- architecture entrypoints;
- runtime commands;
- safety/secret guidance;
- clear statement that this is the image/build recipe, not the full Supabase hosted stack.

`llms-full.txt` should be a fuller agent context bundle that includes:

- high-level architecture;
- PG18 RC1 digest;
- realtime v1/v2 contract;
- important file map;
- run/validation commands;
- browser-proof expectations;
- production non-claims and next gates.

This follows the public `llms.txt` convention: a Markdown file optimized for LLM discovery with brief background plus links/sections for deeper context. The `llms-full.txt` file is a repo-specific full context packet.

## 5. Realtime v2 functional requirements

### FR-1 replay/cursor

A client can reconnect with a `last_event_id` and receive missed events newer than that id.

Expected WebSocket input:

```json
{"type":"subscribe","last_event_id":123}
```

Expected response:

```json
{"type":"replay","events":[...]}
```

### FR-2 topics/scopes

Events carry scope metadata:

```text
scope_type text
scope_id text
```

Initial default scope can remain user-scoped:

```text
scope_type='user'
scope_id=<app_user_id>
```

### FR-3 RLS-aware subscription check

The bridge must ask Postgres whether the authenticated JWT user can subscribe to a requested scope/topic using an RPC/function, not only local bridge logic.

Example function target:

```text
api.can_subscribe(p_scope_type text, p_scope_id text, p_topic text default null)
```

### FR-4 ACK/retry tracking

A client can ACK an event:

```json
{"type":"ack","event_id":123}
```

Postgres stores ACK state in a durable table, scoped to the JWT user.

### FR-5 fanout preparation

Document and shape the outbox so a future worker can fan out to Redis/NATS/Kafka without changing the primary source of truth.

Do not implement Redis/NATS in this slice unless required by tests; it is explicitly future-gated.

## 6. Acceptance criteria

- PRD and task ledger are persisted before implementation.
- Realtime architecture doc exists and contains user + developer views.
- `llms.txt` and `llms-full.txt` exist at repo root and mention canonical docs and current RC digest.
- SQL schema supports replay/cursor, scopes, subscription check, and ACK storage.
- WebSocket bridge supports:
  - token validation;
  - subscribe message;
  - replay response;
  - realtime event delivery;
  - ACK message;
  - invalid token rejection;
  - denied subscription rejection.
- Web proof exposes UI/buttons/status for profile, publish, subscribe/replay, ACK or at least demonstrates ACK through JS/runtime path.
- Parent runs syntax/config gates.
- Parent runs runtime smoke against the actual compose stack.
- Parent runs browser-proof and vision/liveness checks.
- Parent persists task review and final report with requested-vs-delivered matrix.
- Parent commits scoped changes with clean working tree.

## 7. Subagent plan

Use at most two parallel subagents initially:

| Slot | ID | Scope | Toolsets | Deliverables |
|---|---|---|---|---|
| 1 | SA-01 | Documentation + `llms.txt`/`llms-full.txt` draft | file, terminal | architecture doc, llms docs, status/final files |
| 2 | SA-02 | Realtime v2 implementation | file, terminal | SQL/bridge/web changes, smoke notes, status/final files |

Parent responsibilities:

- create PRD/tasks;
- monitor status/final files and delegate results;
- correct gaps without HITL;
- rerun gates;
- run browser/vision proof;
- write task reviews and final report;
- commit.

## 8. Validation plan

Static:

```bash
python3 -m py_compile docker/pg18-postgrest-rls/web/serve.py
node --check docker/pg18-postgrest-rls/realtime/server.js
node --check docker/pg18-postgrest-rls/realtime/test-client.js
docker compose -f docker/pg18-postgrest-rls/compose.pg18-postgrest-rls.yml config
```

Runtime:

```bash
cd docker/pg18-postgrest-rls
docker compose -f compose.pg18-postgrest-rls.yml up -d --build
curl -fsS -X POST http://127.0.0.1:18083/api/current-profile
curl -fsS -X POST http://127.0.0.1:18083/api/publish-realtime
# WebSocket smoke for subscribe/replay/ack
```

Browser:

- open `http://127.0.0.1:18083/`;
- verify page title and realtime status;
- click publish/replay/ack controls;
- inspect DOM state;
- inspect console errors;
- capture vision/screenshot evidence.

## 9. Final report questions to answer

- Is the realtime bridge still a transport-only adapter?
- Which rules remain in Postgres?
- What exactly is proven locally?
- What is not claimed for production?
- What are the next gates for production hardening?
- When should Redis/NATS be introduced?
