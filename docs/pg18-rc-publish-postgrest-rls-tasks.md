# PG18 RC1 Publish + Durable PostgREST/RLS/Realtime Stack — Task Ledger

Status geral: DELIVERED_PASS

| ID | Task | Acceptance | Status | Evidence |
|---|---|---|---|---|
| PGR-01 | PRD/tasks | PRD e ledger persistidos | DONE | `docs/pg18-rc-publish-postgrest-rls-prd.md` |
| PGR-02 | Preflight | git/Docker/Nix/registry/ports auditados | DONE | compose config parse, Docker process checks |
| PGR-03 | Nix full validate | `validate-pg18.sh` completo em runner | DONE | `tmp/pg18-publish/full-validate-persistent-nix/summary.txt`; 15/15 PASS |
| PGR-04 | Registry push/digest | Push ArthurAgrelli e digest registrado | DONE | `registry.arthuragrelli.com/supabase-postgres:18-karval-rc1` -> `sha256:c477d5146ea51f235b811c093363c3ed5d8a342dbed8efac7635a1b9779e2f9f` |
| PGR-05 | Durable stack | Compose/scripts/docs para PostgREST/web versionados | DONE | `docker/pg18-postgrest-rls/compose.pg18-postgrest-rls.yml` |
| PGR-06 | JWT/RLS contract | RPC JSONB com claims/RLS-safe smoke PASS | DONE | `/api/current-profile` returned `user_karval_demo`, role `authenticated`, PG `18.0` |
| PGR-07 | Realtime MVP | WebSocket JWT/RLS-aware event delivery PASS | DONE | client received `proof.realtime` from `event_outbox`/`LISTEN/NOTIFY` |
| PGR-08 | Browser proof | Web client + console/DOM PASS | DONE | Browser DOM: `publish 200 OK`, `event received: proof.realtime`; console 0 errors |
| PGR-09 | Reviews | Task/final review PASS após correções | DONE | `docs/pg18-rc-publish-postgrest-rls-task-reviews.md` |
| PGR-10 | Commit/closeout | Commit local, árvore limpa, relatório final | DONE | `docs/pg18-rc-publish-postgrest-rls-final-report.md` |
