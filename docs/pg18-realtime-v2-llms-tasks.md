# PG18 Realtime v2 + LLM Docs — Task Ledger

Status geral: DELIVERED_PASS
Source PRD: `docs/pg18-realtime-v2-llms-prd.md`

## Task matrix

| ID | Task | Scope | Acceptance | Status | Owner | Evidence |
|---|---|---|---|---|---|---|
| RV2-01 | Persist PRD | Executive plan with scope, gates, subagents, validation | PRD exists and is read by subagents | DONE | parent | `docs/pg18-realtime-v2-llms-prd.md` |
| RV2-02 | Persist task ledger | Detailed task breakdown from PRD | Ledger exists before execution | DONE | parent | this file |
| RV2-03 | Realtime architecture doc | Promote explanation into durable docs with user/dev views | Explicit doc exists and is linked from README/llms | DONE | SA-01 + parent review | `docs/pg18-realtime-websocket-architecture.md` |
| RV2-04 | LLM context docs | Create root `llms.txt` and `llms-full.txt` | Files exist, concise/full context, current digest, commands | DONE | SA-01 + parent review | `llms.txt`, `llms-full.txt` |
| RV2-05 | SQL realtime v2 contract | Add replay/cursor, scopes, subscription check, ACK storage | SQL init supports v2 semantics and initializes in clean compose | DONE | SA-02 + parent smoke | `docker/pg18-postgrest-rls/init/001-api-rls.sql` |
| RV2-06 | WebSocket bridge v2 | Add subscribe/replay/ack/deny handling | Node bridge supports v2 messages and rejects invalid/denied requests | DONE | SA-02 + parent smoke | `docker/pg18-postgrest-rls/realtime/server.js` |
| RV2-07 | Web proof v2 | UI demonstrates profile, publish, replay/subscribe, ack status | Browser DOM proves v2 behavior | DONE | SA-02 + parent browser | `docker/pg18-postgrest-rls/web/serve.py` |
| RV2-08 | Runtime smoke | Parent-run compose smoke with actual services | current-profile, publish, WS subscribe/replay/ack, negative checks PASS | DONE | parent | command output; final report |
| RV2-09 | Browser proof + vision | Parent-owned browser QA | DOM status/realtime/replay/ack PASS; console 0 errors; vision confirms | DONE | parent | `docs/pg18-realtime-v2-llms-browser-proof.html` |
| RV2-10 | Reviews | Task review + final requested-vs-delivered | Review docs exist; corrections made without HITL | DONE | parent | `docs/pg18-realtime-v2-llms-task-reviews.md` |
| RV2-11 | Final report + commit | Persist final report, run final gates, commit scoped changes | report exists; commit done; git clean | DONE | parent | `docs/pg18-realtime-v2-llms-final-report.md` |

## Subagent monitor ledger

| Agent | Scope | Status file | Final file | Final status | Parent verification |
|---|---|---|---|---|---|
| SA-01 | Realtime docs + LLM docs | `.tmp/pg18-realtime-v2-llms/subagents/SA-01-status.md` | `.tmp/pg18-realtime-v2-llms/subagents/SA-01-final.md` | COMPLETED_PASS_WARN | Parent read final file, inspected created docs, will include in commit |
| SA-02 | Realtime v2 implementation | `.tmp/pg18-realtime-v2-llms/subagents/SA-02-status.md` | `.tmp/pg18-realtime-v2-llms/subagents/SA-02-final.md` | COMPLETED_PASS_WARN | Parent ran static gates, clean compose runtime, WS smoke, browser/vision |

## Parent gates executed

- PASS: `python3 -m py_compile docker/pg18-postgrest-rls/web/serve.py`
- PASS: `node --check docker/pg18-postgrest-rls/realtime/server.js`
- PASS: `node --check docker/pg18-postgrest-rls/realtime/test-client.js`
- PASS: `docker compose -f docker/pg18-postgrest-rls/compose.pg18-postgrest-rls.yml config`
- PASS: clean compose startup with PG18 RC1 digest
- PASS: current-profile JWT/RLS
- PASS: `api.can_subscribe` allowed and denied cases
- PASS: anon direct RPC denied with HTTP 401
- PASS: WebSocket subscribe/replay/live event/ACK
- PASS: denied subscription closes 1008
- PASS: invalid token closes/errors
- PASS: browser DOM + console + vision

## Commit status

DONE after final report, cleanup, scoped commit and clean-tree verification.
