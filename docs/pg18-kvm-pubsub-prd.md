# PG18 KVM Enable + Pub/Sub WebSocket — PRD / Plano Executivo

Status: EXECUTION_STARTED_KVM_SUDO_BLOCKED
Owner/orchestrator: Thor/default
Repo: `/home/marcelo-karval/Backup/Projetos/supabase-postgres-18-fork/postgres`
Branch: `karval/pg18-bootstrap`
Baseline commit before this slice: `9b8e74fd docs: record PG18 28-extension KVM gate closeout`
Date: 2026-06-11

## 1. Decisões recebidas de Karval

1. KVM: sim, quer habilitar o KVM.
2. Runner: usar o caminho mais adequado e simples para nossa realidade.
3. RC: se já virou RC2, usar RC2; se ainda é evidência da RC1, anexar evidências à RC1.
4. Extensões fora: `plv8` e `timescaledb` continuam fora.
5. Nova análise: Redis e alternativa mais natural para pub/sub externo consumido por WebSockets.

## 2. Objetivos

- Tentar habilitar KVM de forma segura e registrar evidência real.
- Se KVM ficar disponível, rerodar o PG18 no-skip gate mantendo 28 extensões.
- Se KVM exigir sudo interativo, persistir runbook operacional exato e classificar blocker corretamente.
- Não promover RC2 artificialmente: como ainda estamos anexando evidência da RC1 e não produzimos nova imagem/digest, o estado permanece RC1 + evidência complementar.
- Persistir análise inicial Redis vs Postgres-centric pub/sub/WebSocket.
- Executar browser-proof + vision da pilha documental.

## 3. Não-objetivos

- Não remover nenhuma das 28 extensões.
- Não adicionar `plv8` ou `timescaledb` nesta rodada.
- Não usar `PG18_REQUIRE_KVM=false` como aceite de release.
- Não forçar prompt sudo interativo via processo que possa travar a sessão.
- Não publicar nova tag/digest sem gate real novo.
- Não implementar ainda o WebSocket bridge; esta rodada é análise/decisão e PRD de próximo experimento.

## 4. Evidência KVM atual

Preflight parent:

```text
/dev/kvm=absent
CPU: Intel Xeon E5-2683 v4
Virtualization: VT-x
user groups: sudo,docker
sudo noninteractive=unavailable
```

Tentativa segura autorizada:

```text
sudo -n modprobe kvm          -> exit 1 / sudo: a password is required
sudo -n modprobe kvm_intel    -> exit 1 / sudo: a password is required
/dev/kvm_after=absent
```

Conclusão: hardware parece apto; bloqueio atual é operacional/sudo interativo para carregar `kvm` e `kvm_intel`.

## 5. Caminho mais adequado e simples

O caminho recomendado é local e simples:

```bash
cd /home/marcelo-karval/Backup/Projetos/supabase-postgres-18-fork/postgres
sudo modprobe kvm
sudo modprobe kvm_intel
ls -l /dev/kvm
lsmod | grep -E '^kvm|^kvm_intel'
```

Depois:

```bash
PG18_REQUIRE_KVM=true scripts/run-pg18-persistent-nix-validate.sh
```

Se `modprobe` falhar, coletar:

```bash
sudo modprobe -v kvm
sudo modprobe -v kvm_intel
sudo dmesg | grep -iE 'kvm|vmx|virtualization' | tail -80
```

## 6. RC1 vs RC2

Decisão desta rodada:

- Não há nova imagem PG18/digest.
- Não houve novo no-skip PASS.
- Portanto, isto é evidência complementar da RC1, não RC2.
- RC2 só deve existir quando houver mudança material nova: novo build/tag/digest ou correção real após o gate KVM avançar.

## 7. Pub/Sub WebSocket database-centric

Resposta curta: Redis não deve ser o core inicial.

Arquitetura recomendada:

```text
Postgres transaction
  -> app.event_outbox durable event
  -> LISTEN/NOTIFY wake-up signal
  -> thin WebSocket bridge
  -> authorized clients
```

Complementos:

- `pgmq`: jobs/retries/DLQ/side effects.
- `wal2json` / logical decoding: CDC/realtime-like posterior.
- `pg_net`: outbound webhooks, não backbone WS.
- Redis/NATS: downstream opcional quando fanout/escala justificar; nunca fonte de verdade inicial.

## 8. Acceptance criteria desta rodada

| Critério | Resultado esperado |
|---|---|
| PRD persistido | `docs/pg18-kvm-pubsub-prd.md` |
| Tasks persistidas | `docs/pg18-kvm-pubsub-tasks.md` |
| KVM auditado | evidência sudo/KVM registrada |
| Pub/sub analisado | recomendação Postgres-first persistida |
| Reviews lado a lado | `docs/pg18-kvm-pubsub-task-reviews.md` |
| Browser-proof + vision | HTML QA local com HTTP 200, markers e vision PASS |
| Relatório final | `docs/pg18-kvm-pubsub-final-report.md` |

## 9. Perguntas para próximos passos

1. Você quer executar agora manualmente o runbook sudo local e me mandar o output, ou prefere que eu deixe um script helper para você rodar?
2. Se `modprobe` falhar por BIOS/firmware, autorizamos mover o gate para um runner bare-metal/CI self-hosted com `/dev/kvm`?
3. Para o pub/sub, quer que o próximo slice implemente o MVP `event_outbox + LISTEN/NOTIFY + WebSocket bridge` sem Redis?
4. Se formos testar bridge, prefere Node/TypeScript, Python ou Go?
