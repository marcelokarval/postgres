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
