# PG18 RC1 Publish + Durable PostgREST/RLS/Realtime Stack — Task Reviews

Date: 2026-06-12
Verdict: PASS for repo-local release-candidate closeout.

| Task | Requested | Delivered | Evidence | Verdict |
|---|---|---|---|---|
| Nix full gate | Full no-skip validation | 15/15 steps PASS in persistent Nix/KVM runner | `summary.txt`: `PG18 validation sequence finished successfully`; docker-image-test: `All 50 tests passed` | PASS |
| Registry promotion | Retag/push RC and capture digest | Pushed `18-karval-rc1`; digest `sha256:c477d5146ea51f235b811c093363c3ed5d8a342dbed8efac7635a1b9779e2f9f` | `docker buildx imagetools inspect` | PASS |
| Documentation layer | README + reports updated | README, PRD, task ledger, task review, final report updated | files under `docs/` plus README | PASS |
| Durable PostgREST/RLS stack | Versioned local stack | Compose stack under `docker/pg18-postgrest-rls/` pinned to RC1 digest by default | `docker compose config --format json` parsed URI host/port/db correctly | PASS |
| JWT/RLS RPC | Database-centric RPC with JWT claims | `api.current_profile()` returns only claim-owned profile via RLS | `/api/current-profile` returned `app_user_id=user_karval_demo`, `role=authenticated`, `postgres_version=18.0`; anon direct call returned HTTP 401 | PASS |
| Realtime MVP | WebSocket JWT/RLS-aware transport | Sibling Node bridge listens to Postgres `app_events`, filters by JWT `app_user_id`, pushes WS event | test client received `ready` and `event proof.realtime`; invalid token closed with 1008 | PASS |
| Browser proof | UI path proof with console | Browser loaded web proof, clicked publish, DOM showed `publish 200 OK` and `event received: proof.realtime`; console empty | browser snapshot + console | PASS |

## Residual risks

- This is local/dev proof, not production/VPS deployment proof.
- Realtime bridge is intentionally MVP-grade: no replay cursor, no ack/retry protocol, no multi-instance fanout, no Redis/NATS. Postgres remains source of truth through `private.event_outbox`.
- `supautils` and `plan_filter` enforcement semantics remain separate hardening gates.
