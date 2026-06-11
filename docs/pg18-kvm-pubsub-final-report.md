# PG18 KVM Enable + Pub/Sub WebSocket — Final Report

Status: DELIVERED_WITH_SUDO_INTERACTIVE_BLOCKER
Owner/orchestrator: Thor/default
Date: 2026-06-11

## 1. Executive summary

A rodada foi executada com as respostas de Karval:

- KVM deve ser habilitado.
- Caminho mais simples/adequado foi escolhido: sudo interativo local no próprio host.
- Como não houve novo build/digest/no-skip PASS, a evidência deve ser anexada à RC1; não é RC2 ainda.
- `plv8` e `timescaledb` continuam fora do PG18.
- Redis/pub-sub foi analisado: recomendação é Postgres-first com `event_outbox + LISTEN/NOTIFY + WebSocket bridge`, deixando Redis/NATS como downstream futuro opcional.

O bloqueio atual é operacional: o host tem VT-x e módulos KVM disponíveis, mas `/dev/kvm` está ausente e `sudo -n modprobe` exige senha. Eu não forcei prompt interativo para não travar a sessão.

Veredito: `DELIVERED_WITH_SUDO_INTERACTIVE_BLOCKER`.

## 2. Files persisted

- `docs/pg18-kvm-pubsub-prd.md`
- `docs/pg18-kvm-pubsub-tasks.md`
- `docs/pg18-kvm-pubsub-task-reviews.md`
- `docs/pg18-kvm-pubsub-browser-proof.html`
- `docs/pg18-kvm-pubsub-final-report.md`

Subagent artifacts, intentionally kept out of commit unless requested:

- `.tmp/pg18-kvm-pubsub/subagents/SA-01-status.md`
- `.tmp/pg18-kvm-pubsub/subagents/SA-01-final.md`
- `.tmp/pg18-kvm-pubsub/subagents/SA-02-status.md`
- `.tmp/pg18-kvm-pubsub/subagents/SA-02-final.md`

## 3. Subagent orchestration

| Slot | Subagent | Scope | Toolsets | Status | Parent decision |
|---|---|---|---|---|---|
| 1 | SA-01 | KVM strategy audit | terminal,file | COMPLETED / BLOCKED_SUDO_INTERACTIVE | Accepted after parent preflight/modprobe attempt |
| 2 | SA-02 | Redis/pubsub architecture | terminal,file,web allowed | COMPLETED / POSTGRES_FIRST_RECOMMENDED | Accepted and integrated |

Both slots were closed after delivery. No unnecessary browser/GitHub/MCP access was granted.

## 4. Requested vs delivered

| Requested | Delivered | Status |
|---|---|---|
| Habilitar KVM | Attempted safe non-interactive enable; blocked by sudo password; runbook persisted | BLOCKED_SUDO_INTERACTIVE |
| Usar caminho mais adequado/simples | Local sudo `modprobe kvm/kvm_intel` is simplest; runner bare-metal only Plan C | PASS |
| RC1 vs RC2 | No new digest/build/no-skip PASS => append evidence to RC1, no RC2 | PASS |
| Keep 28 extensions | Preserved; no removal | PASS |
| Keep plv8/timescaledb out | Explicit non-claim | PASS |
| Analyze Redis/pubsub | Postgres-first architecture recommended; Redis/NATS optional downstream future | PASS |
| PRD/tasks/reviews/final report | Persisted in docs stack | PASS |
| Browser-proof + vision | Local page served, HTTP 200, markers verified, vision PASS, server killed | PASS |

## 5. Parent evidence

Host/KVM preflight:

```text
/dev/kvm=absent
cpu flags vmx/svm count=1
Model name: Intel(R) Xeon(R) CPU E5-2683 v4 @ 2.10GHz
Virtualization: VT-x
user groups include sudo,docker
sudo noninteractive=unavailable
```

Safe authorized attempt:

```text
sudo_modprobe_kvm_exit=1
sudo: a password is required
sudo_modprobe_kvm_intel_exit=1
sudo: a password is required
/dev/kvm_after=absent
```

Browser-proof:

```text
http_status=200
title_count=2
blocked_count=1
event_outbox_count=1
redis_optional_count=1
Vision QA: PASS
Server: killed after proof
```

## 6. KVM runbook for Karval

Run interactively in a local terminal:

```bash
cd /home/marcelo-karval/Backup/Projetos/supabase-postgres-18-fork/postgres
sudo modprobe kvm
sudo modprobe kvm_intel
ls -l /dev/kvm
lsmod | grep -E '^kvm|^kvm_intel'
```

If `/dev/kvm` appears, run:

```bash
PG18_REQUIRE_KVM=true scripts/run-pg18-persistent-nix-validate.sh
```

Monitor:

```bash
tail -f tmp/pg18-publish/nix-full-validate-persistent.log
tail -f tmp/pg18-publish/full-validate-persistent-nix/summary.txt
```

If `modprobe` fails:

```bash
sudo modprobe -v kvm
sudo modprobe -v kvm_intel
sudo dmesg | grep -iE 'kvm|vmx|virtualization' | tail -80
```

Then decide BIOS/UEFI VT-x enablement or move to KVM-capable runner.

## 7. Pub/Sub/WebSocket recommendation

Recommended first implementation:

```text
Postgres transaction
  -> app.event_outbox durable event
  -> LISTEN/NOTIFY wake-up signal
  -> thin WebSocket bridge
  -> authorized clients
```

Rules:

- `NOTIFY` carries only lightweight `event_id/topic/type`.
- Bridge fetches event from Postgres and authorizes delivery.
- Client reconnects with cursor and bridge replays from `event_outbox`.
- Commands/mutations stay via PostgREST/RPC.
- `pgmq` handles jobs/retries/DLQ.
- `wal2json`/logical decoding is a later CDC/realtime-like experiment.
- Redis/NATS is optional future fanout, downstream from Postgres, never source of truth.

## 8. Not claimed

- Not claiming KVM was enabled; it is blocked by sudo interactive password.
- Not claiming no-skip PG18 gate PASS.
- Not claiming RC2.
- Not claiming WebSocket bridge implemented.
- Not claiming Redis is unnecessary forever; only not recommended as core initial broker.

## 9. Remaining work

1. Karval runs the sudo KVM runbook locally.
2. Rerun `PG18_REQUIRE_KVM=true scripts/run-pg18-persistent-nix-validate.sh`.
3. If no-skip PASS: persist RC1 evidence appendix or decide RC2 if a new build/digest is produced.
4. Start a new implementation slice for `event_outbox + LISTEN/NOTIFY + WebSocket bridge`.

## 10. Questions for next steps

1. Quer que eu crie um script helper `scripts/enable-kvm-preflight.sh` que só imprime/guia os comandos sudo para você rodar manualmente?
2. Depois do KVM local, você quer que eu monitore o validate se você iniciar o comando no terminal?
3. Para o WebSocket bridge MVP: prefere Node/TypeScript, Python ou Go?
4. Quer que o bridge siga contrato JWT compatível com PostgREST/RLS desde o primeiro slice?

## 11. Recommended next steps

1. Execute local KVM runbook.
2. Rerun no-skip PG18 gate.
3. If PASS, append evidence to RC1 unless a new image/digest is built.
4. Open next PRD slice: `pg18-event-outbox-websocket-bridge`.
5. Keep Redis/NATS out of core until fanout measurements justify it.

## 12. Final verdict

`DELIVERED_WITH_SUDO_INTERACTIVE_BLOCKER`.

The requested orchestration, PRD/tasks/reviews, KVM attempt, pub/sub analysis, browser-proof, and final report were completed. The only operational blocker is that enabling KVM requires Karval's interactive sudo password or an alternate KVM-capable runner.
