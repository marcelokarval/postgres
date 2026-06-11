# PG18 28 Extensions KVM Gate — Tasks

Status geral: DELIVERED_WITH_KVM_INFRA_BLOCKER
Fonte: `docs/pg18-28ext-kvm-gate-prd.md`

| ID | Task | Escopo detalhado | Critério de aceite | Status | Evidência |
|---|---|---|---|---|---|
| T00 | Planejamento/PRD | Persistir plano executivo, escopo, não-objetivos, riscos, perguntas e matriz inicial. | PRD existe e cobre solicitação 1..5. | DONE | `docs/pg18-28ext-kvm-gate-prd.md` |
| T01 | Auditar KVM/runner | Confirmar logs do validate, `/dev/kvm`, sudo, script runner e classificar blocker. | Status/final subagent + parent verification. | DONE_BLOCKED_INFRA | `.tmp/pg18-28ext-kvm/subagents/SA-01-final.md` |
| T02 | Auditar 28 extensões | Extrair PG18 `versions.json`, cruzar com smoke/runtime docs e classificar pendência KVM. | Matriz 28/28 persistida. | DONE | `.tmp/pg18-28ext-kvm/subagents/SA-02-final.md` |
| T03 | Harden/review runner | Garantir preflight KVM, pass-through `/dev/kvm`, Nix features e knobs de paralelismo. | `bash -n` passa; preflight falha cedo sem KVM. | DONE | commit `77d36ad9`; `scripts/run-pg18-persistent-nix-validate.sh` |
| T04 | Persistir reviews | Comparar solicitado vs entregue por task e revisão final. | Reviews lado a lado persistidos. | DONE | `docs/pg18-28ext-kvm-task-reviews.md` |
| T05 | Browser-proof + vision | Gerar página QA estática, servir localmente, capturar browser/vision e validar liveness. | Browser abre página correta; vision confirma conteúdo. | DONE | `docs/pg18-28ext-kvm-browser-proof.html`; HTTP 200; 28 rows; vision PASS |
| T06 | Commit e relatório final | Commitar artefatos escopados, deixar `tmp/` fora, emitir relatório final no chat. | Commit com docs/artefatos; relatório final persistido. | PENDING_COMMIT | `docs/pg18-28ext-kvm-final-report.md` |

## Subagent monitoring ledger

| Slot | Subagent | Escopo | Status file | Final file | Resultado | Slot |
|---|---|---|---|---|---|---|
| 1 | SA-01 | KVM/runner audit | `.tmp/pg18-28ext-kvm/subagents/SA-01-status.md` | `.tmp/pg18-28ext-kvm/subagents/SA-01-final.md` | COMPLETED / BLOCKED_INFRA | CLOSED |
| 2 | SA-02 | 28 extensions matrix | `.tmp/pg18-28ext-kvm/subagents/SA-02-status.md` | `.tmp/pg18-28ext-kvm/subagents/SA-02-final.md` | COMPLETED / PASS_LOCAL_MATRIX_WARN_KVM | CLOSED |

## Parent-owned gates

```bash
bash -n scripts/run-pg18-persistent-nix-validate.sh
PG18_VALIDATE_OUTER_LOG=tmp/pg18-publish/kvm-preflight.log scripts/run-pg18-persistent-nix-validate.sh
```

Expected on current host: exit `86`, because `/dev/kvm` is unavailable.
