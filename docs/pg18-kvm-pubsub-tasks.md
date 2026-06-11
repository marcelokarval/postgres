# PG18 KVM Enable + Pub/Sub WebSocket — Tasks

Status geral: DELIVERED_WITH_SUDO_INTERACTIVE_BLOCKER
Fonte: `docs/pg18-kvm-pubsub-prd.md`

| ID | Task | Escopo | Critério de aceite | Status | Evidência |
|---|---|---|---|---|---|
| K00 | PRD/tasks | Persistir plano executivo e tarefas desta rodada. | PRD e tasks existem. | DONE | `docs/pg18-kvm-pubsub-prd.md`, este arquivo |
| K01 | KVM preflight/enable | Checar host, tentar habilitação segura autorizada, classificar blocker. | Evidência de `/dev/kvm`, VT-x, sudo e modprobe. | DONE_BLOCKED_SUDO_INTERACTIVE | parent preflight + SA-01 |
| K02 | RC decision | Decidir RC1 vs RC2 conforme evidência real. | Sem nova imagem/digest => anexar evidência à RC1. | DONE | PRD seção RC1 vs RC2 |
| K03 | Pub/sub analysis | Analisar Redis vs Postgres-centric para WebSockets. | Recomendação pragmática persistida. | DONE | SA-02 + final report |
| K04 | Reviews | Review por task e final lado a lado. | Reviews persistidos. | DONE | `docs/pg18-kvm-pubsub-task-reviews.md` |
| K05 | Browser-proof + vision | Servir HTML QA, validar DOM/HTTP/vision, encerrar server. | HTTP 200 + markers + vision PASS. | DONE | `docs/pg18-kvm-pubsub-browser-proof.html`; HTTP 200; vision PASS |
| K06 | Commit/report | Commitar artefatos escopados e emitir relatório no chat. | Commit e relatório final. | PENDING_COMMIT | `docs/pg18-kvm-pubsub-final-report.md` |

## Subagent monitoring ledger

| Slot | Subagent | Escopo | Status file | Final file | Resultado | Slot |
|---|---|---|---|---|---|---|
| 1 | SA-01 | KVM strategy audit | `.tmp/pg18-kvm-pubsub/subagents/SA-01-status.md` | `.tmp/pg18-kvm-pubsub/subagents/SA-01-final.md` | COMPLETED / BLOCKED_SUDO_INTERACTIVE | CLOSED |
| 2 | SA-02 | Redis/pubsub architecture | `.tmp/pg18-kvm-pubsub/subagents/SA-02-status.md` | `.tmp/pg18-kvm-pubsub/subagents/SA-02-final.md` | COMPLETED / POSTGRES_FIRST_RECOMMENDED | CLOSED |
