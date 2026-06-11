# PG18 KVM Helper + Realtime JWT/RLS — Tasks

Status geral: DELIVERED_VALIDATE_AWAITS_MANUAL_KVM
Fonte: `docs/pg18-kvm-helper-realtime-prd.md`

| ID | Task | Escopo | Critério de aceite | Status | Evidência |
|---|---|---|---|---|---|
| R00 | PRD/tasks | Persistir plano e ledger. | Docs existem. | DONE | PRD + este arquivo |
| R01 | KVM helper | Criar script seguro executável com modo preflight/--apply. | bash -n; preflight 86; --apply extra args 64. | DONE | `scripts/enable-kvm-preflight.sh` |
| R02 | Realtime strategy | Decidir tecnologia MVP e alvo Supabase-like. | Node/TS MVP + Supabase Realtime spike futuro. | DONE | SA-02 final + PRD |
| R03 | Parent validations | Rodar checks do helper e revisar request changes. | Correções SA-01 aplicadas. | DONE | terminal validation |
| R04 | Reviews | Persistir requested-vs-delivered por task. | Review doc existe. | DONE | `docs/pg18-kvm-helper-realtime-task-reviews.md` |
| R05 | Browser-proof + vision | Servir HTML, DOM/HTTP/vision, encerrar server. | HTTP 200 + markers + vision PASS. | DONE | `docs/pg18-kvm-helper-realtime-browser-proof.html`; HTTP 200; vision PASS |
| R06 | Commit/report | Commitar artefatos escopados e reportar. | Commit + final chat. | PENDING_COMMIT | `docs/pg18-kvm-helper-realtime-final-report.md` |

## Subagent monitoring ledger

| Slot | Subagent | Escopo | Resultado | Slot |
|---|---|---|---|---|
| 1 | SA-01 | Review helper KVM | REQUEST_CHANGES, corrigido pelo parent | CLOSED |
| 2 | SA-02 | Decisão realtime JWT/RLS | COMPLETED / Node/TS MVP recomendado | CLOSED |

## Karval answers incorporated — realtime placement

Karval confirmed:

1. KVM helper was executed successfully.
2. The realtime MVP placement must be checked against architecture/flexibility before implementation.
3. Supabase Realtime spike/comparison should be documented in the same report as the Node/TypeScript MVP, not a separate report.

Decision:

- The MVP realtime should extend `docker/pg18-postgrest-rls/` because that stack already contains the durable proof boundary for PG18 image + PostgREST + JWT + RLS + browser proof.
- This is correct for the current architecture if implemented as a separate, optional service/profile rather than entangling realtime logic into PostgREST or into the database image.
- The database remains the source of truth; realtime is a transport adapter over `app.event_outbox` + `LISTEN/NOTIFY`.
- Supabase Realtime remains a same-report comparison/spike target against the MVP, with explicit criteria: JWT/RLS compatibility, replication/publication requirements, operational complexity, and fit with the custom `supabase/postgres:18` image fork.

Implementation constraint for the next slice:

- Add `realtime` as a sibling service under `docker/pg18-postgrest-rls/`, preferably behind a compose profile or override file.
- Do not bake realtime into the PG18 image.
- Do not make Redis/NATS mandatory.
- Do not bypass Postgres RLS/JWT authorization.
- Browser proof must include authorized and unauthorized client behavior.

