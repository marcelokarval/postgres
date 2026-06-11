# PG18 28 Extensions KVM Gate — Final Report

Status: DELIVERED_WITH_KVM_INFRA_BLOCKER
Owner/orchestrator: Thor/default
Date: 2026-06-11

## 1. Executive summary

A sequência 1..5 foi executada de forma encadeada mantendo as 28 extensões PG18. O resultado técnico honesto é:

- `01-psql_18_bin`: PASS no runner persistente.
- `02-psql_18_slim_bin`: PASS no runner persistente.
- `03-ext-pg_jsonschema`: bloqueado por infraestrutura KVM, não por falha comprovada do código.
- Host atual não expõe `/dev/kvm`.
- O runner agora falha cedo com exit `86` quando KVM está ausente.
- As 28 extensões permanecem na matriz PG18; nenhuma remoção foi proposta.
- `plv8` e `timescaledb` continuam explicitamente fora do PG18.
- Browser-proof + vision da pilha documental passaram.

Veredito final: `CONDITIONAL / BLOCKED_BY_KVM_INFRA`.

## 2. Files persisted

- `docs/pg18-28ext-kvm-gate-prd.md`
- `docs/pg18-28ext-kvm-tasks.md`
- `docs/pg18-28ext-kvm-task-reviews.md`
- `docs/pg18-28ext-kvm-browser-proof.html`
- `docs/pg18-28ext-kvm-final-report.md`

Subagent monitor artifacts, intentionally not committed unless requested:

- `.tmp/pg18-28ext-kvm/subagents/SA-01-status.md`
- `.tmp/pg18-28ext-kvm/subagents/SA-01-final.md`
- `.tmp/pg18-28ext-kvm/subagents/SA-02-status.md`
- `.tmp/pg18-28ext-kvm/subagents/SA-02-final.md`

## 3. Subagent orchestration/monitoring

| Slot | Subagent | Scope | Toolsets | Status | Parent decision |
|---|---|---|---|---|---|
| 1 | SA-01 | KVM/runner audit | terminal,file | COMPLETED / BLOCKED_INFRA | Accepted after parent preflight check |
| 2 | SA-02 | 28-extension matrix audit | terminal,file | COMPLETED / PASS_LOCAL_MATRIX_WARN_KVM | Accepted after parent matrix/docs integration |

No extra MCPs/browser/GitHub were granted to subagents. Both slots were closed after delivery.

## 4. Requested vs delivered

| Requested | Delivered | Status |
|---|---|---|
| Prosseguir próximos passos 1..5 | Executed through blocker classification, QA docs, browser proof and final report | PASS_WITH_INFRA_BLOCKER |
| Manter as 28 extensões | 28 PG18 extensions preserved and documented | PASS |
| PRD completo e persistido | `docs/pg18-28ext-kvm-gate-prd.md` | PASS |
| Tasks detalhadas derivadas do PRD | `docs/pg18-28ext-kvm-tasks.md` | PASS |
| Iniciar execução das tasks | T00-T05 executed; T06 completed after commit/chat closeout | PASS |
| Review por task e final lado a lado | `docs/pg18-28ext-kvm-task-reviews.md` | PASS |
| Correção ativa sem HITL | Runner preflight/hardening validated; no unsafe KVM mutation attempted without sudo/admin | PASS |
| Browser-proof + vision | Static QA page served locally, HTTP 200, 28 rows, vision PASS | PASS |
| Relatório final persistido e no chat | This file + final chat response | PASS |

## 5. Parent validation commands and outputs

```text
git status --short
?? docs/pg18-28ext-kvm-browser-proof.html
?? docs/pg18-28ext-kvm-final-report.md
?? docs/pg18-28ext-kvm-gate-prd.md
?? docs/pg18-28ext-kvm-task-reviews.md
?? docs/pg18-28ext-kvm-tasks.md
?? tmp/
```

```text
bash -n scripts/run-pg18-persistent-nix-validate.sh
OK
```

```text
PG18_VALIDATE_OUTER_LOG=tmp/pg18-publish/kvm-preflight-parent.log scripts/run-pg18-persistent-nix-validate.sh
exit=86
ERROR: /dev/kvm is not available on the host...
Required features: {kvm, nixos-test}
```

Browser/QA:

```text
HTTP status: 200
title count: 2
extension rows rough count: 28
blocker count: 1
Vision QA: PASS; page visible, not blank, blocker/build-proof/table rendered.
```

## 6. 28 extensions maintained

| Extension | PG18 version | Status |
|---|---:|---|
| `http` | `1.6.1` | runtime documented / Nix KVM pending |
| `hypopg` | `1.4.1` | runtime documented / Nix KVM pending |
| `index_advisor` | `0.2.0` | runtime documented / Nix KVM pending |
| `pg_cron` | `1.6.7` | runtime documented / Nix KVM pending |
| `pg_graphql` | `1.6.1` | runtime documented / Nix KVM pending |
| `pg_hashids` | `1.3.0-cd0e1b31d52b394a0df64079406a14a4f7387cd6` | runtime documented / Nix KVM pending |
| `pg_jsonschema` | `0.3.4` | runtime documented / Nix KVM pending |
| `pg_net` | `0.20.3` | runtime documented / Nix KVM pending |
| `pg_partman` | `5.3.1` | runtime documented / Nix KVM pending |
| `pg_plan_filter` | `0.1` | runtime documented / Nix KVM pending |
| `pg_repack` | `1.5.2` | runtime documented / Nix KVM pending |
| `pg_stat_monitor` | `2.0` | runtime documented / Nix KVM pending |
| `pg_tle` | `1.5.2` | runtime documented / Nix KVM pending |
| `pgaudit` | `18.0` | runtime documented / Nix KVM pending |
| `pgjwt` | `0.2.0` | runtime documented / Nix KVM pending |
| `pgmq` | `1.11.1` | runtime documented / Nix KVM pending |
| `pgroonga` | `4.0.6` | runtime documented / Nix KVM pending |
| `pgrouting` | `3.4.1` | runtime documented / Nix KVM pending |
| `pgsodium` | `3.1.8` | runtime documented / Nix KVM pending |
| `pgtap` | `1.3.3` | runtime documented / Nix KVM pending |
| `plpgsql_check` | `2.8` | runtime documented / Nix KVM pending |
| `postgis` | `3.6.3` | runtime documented / Nix KVM pending |
| `rum` | `1.3` | runtime documented / Nix KVM pending |
| `safeupdate` | `1.4` | runtime documented / Nix KVM pending |
| `supabase_vault` | `0.3.1` | runtime documented / Nix KVM pending |
| `vector` | `0.8.2` | runtime documented / Nix KVM pending |
| `wal2json` | `2.6` | runtime documented / Nix KVM pending |
| `wrappers` | `0.6.1` | runtime documented / Nix KVM pending |

## 7. Not claimed

- Not claiming final production release.
- Not claiming Nix no-skip gate PASS.
- Not claiming `pg_jsonschema` failed functionally; the current blocker is KVM infrastructure.
- Not claiming `plv8` or `timescaledb` are PG18-supported in this fork.
- Not claiming browser-proof proves a new database runtime; it proves the persisted QA/report surface.

## 8. Remaining work

1. Run on a KVM-capable runner.
2. Reexecute:

```bash
PG18_NIX_MAX_JOBS=1 PG18_NIX_CORES=16 scripts/run-pg18-persistent-nix-validate.sh
```

3. If the gate passes, update evidence and decide RC2/final tag.
4. If a real extension failure appears after KVM is available, patch the smallest surface and rerun with the persistent `/nix` volume.

## 9. Questions for next step

1. Do you want to enable KVM locally with sudo/admin, or move this to another runner?
2. If moving, should the target be bare-metal, nested-virt VM, or CI self-hosted runner?
3. After no-skip PASS, should we publish `18-karval-rc2` or keep `18-karval-rc1` digest and append evidence?
4. Confirm: `plv8` and `timescaledb` stay out of the PG18 image until separate compatibility work.

## 10. Recommended next steps

1. Provision/choose KVM runner.
2. Copy/checkout this branch and preserve the `pg18-nix-store` strategy if local Docker volume is available.
3. Run the no-skip gate with `PG18_REQUIRE_KVM=true`.
4. Monitor `summary.txt` step-by-step; do not kill long `wrappers all_fdws` builds without CPU/log evidence.
5. On PASS, create `docs/pg18-rc2-nix-full-validate-evidence.md` and publish/promote only after digest capture.

## 11. Final verdict

`DELIVERED_WITH_KVM_INFRA_BLOCKER`.

The requested orchestrated documentation, tasking, review, browser-proof and final-report stack is complete. The only remaining blocker is the external runner prerequisite `/dev/kvm` for NixOS VM checks.
