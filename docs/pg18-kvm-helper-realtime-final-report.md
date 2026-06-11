# PG18 KVM Helper + Realtime JWT/RLS — Final Report

Status: DELIVERED_VALIDATE_AWAITS_MANUAL_KVM
Owner/orchestrator: Thor/default
Date: 2026-06-11

## 1. Executive summary

Entreguei os próximos passos recomendados 1..5 dentro do que era seguro fazer sem sua senha sudo interativa:

- Criei helper executável para KVM.
- Exibi e persisti o caminho absoluto do arquivo.
- Validei que o helper não pede sudo no modo default.
- Validei que o modo `--apply` é explícito e rejeita argumentos extras.
- Defini o comando e logs para você iniciar/monitorarmos o no-skip validate após `/dev/kvm` existir.
- Decidi a estratégia realtime mais adaptável/fácil/flexível: MVP Node/TypeScript com `ws + pg`, mantendo Supabase Realtime como spike/target pronto/testado futuro.
- Defini JWT compatível com PostgREST/RLS desde o início.
- Persisti PRD, tasks, reviews, browser-proof HTML e relatório final.
- Executei browser-proof + vision.

Veredito: `DELIVERED_VALIDATE_AWAITS_MANUAL_KVM`.

## 2. Caminho absoluto do helper

Execute este arquivo no seu terminal local:

```bash
/home/marcelo-karval/Backup/Projetos/supabase-postgres-18-fork/postgres/scripts/enable-kvm-preflight.sh --apply
```

Também pode rodar primeiro em modo somente leitura:

```bash
/home/marcelo-karval/Backup/Projetos/supabase-postgres-18-fork/postgres/scripts/enable-kvm-preflight.sh
```

O modo `--apply` pode pedir sua senha sudo e tentará carregar:

```text
kvm
kvm_intel
```

Depois que `/dev/kvm` existir, rode no repo:

```bash
cd /home/marcelo-karval/Backup/Projetos/supabase-postgres-18-fork/postgres
PG18_REQUIRE_KVM=true scripts/run-pg18-persistent-nix-validate.sh
```

Monitoramento:

```bash
tail -f /home/marcelo-karval/Backup/Projetos/supabase-postgres-18-fork/postgres/tmp/pg18-publish/nix-full-validate-persistent.log
tail -f /home/marcelo-karval/Backup/Projetos/supabase-postgres-18-fork/postgres/tmp/pg18-publish/full-validate-persistent-nix/summary.txt
```

## 3. Files persisted

- `scripts/enable-kvm-preflight.sh`
- `docs/pg18-kvm-helper-realtime-prd.md`
- `docs/pg18-kvm-helper-realtime-tasks.md`
- `docs/pg18-kvm-helper-realtime-task-reviews.md`
- `docs/pg18-kvm-helper-realtime-browser-proof.html`
- `docs/pg18-kvm-helper-realtime-final-report.md`

Subagent artifacts, intentionally not committed unless requested:

- `.tmp/pg18-kvm-helper-realtime/subagents/SA-01-status.md`
- `.tmp/pg18-kvm-helper-realtime/subagents/SA-01-final.md`
- `.tmp/pg18-kvm-helper-realtime/subagents/SA-02-status.md`
- `.tmp/pg18-kvm-helper-realtime/subagents/SA-02-final.md`

## 4. Subagent orchestration

| Slot | Subagent | Scope | Status | Parent decision |
|---|---|---|---|---|
| 1 | SA-01 | Review helper KVM | REQUEST_CHANGES | Correções aplicadas e revalidadas |
| 2 | SA-02 | Decisão realtime JWT/RLS | COMPLETED | Node/TS MVP aceito; Supabase Realtime spike futuro |

Slots encerrados. Nenhum subagente ficou travado/idle.

## 5. Parent validation evidence

Helper:

```text
chmod 755 scripts/enable-kvm-preflight.sh
bash -n scripts/enable-kvm-preflight.sh
scripts/enable-kvm-preflight.sh --apply --typo -> exit 64
scripts/enable-kvm-preflight.sh -> exit 86 enquanto /dev/kvm ausente
```

Output relevante do preflight:

```text
[kvm-preflight] KVM_READY=no
After /dev/kvm exists, rerun:
  PG18_REQUIRE_KVM=true scripts/run-pg18-persistent-nix-validate.sh
Monitor:
  tail -f tmp/pg18-publish/nix-full-validate-persistent.log
  tail -f tmp/pg18-publish/full-validate-persistent-nix/summary.txt
```

Browser-proof:

```text
http_status=200
PG18 KVM Helper + Realtime QA=2
enable-kvm-preflight.sh --apply=1
Node/TypeScript bridge=1
app.event_outbox=1
JWT compatível com PostgREST/RLS=1
Supabase Realtime=1
Redis/NATS=1
Vision QA: PASS
Server: killed after proof
```

## 6. Requested vs delivered

| Requested | Delivered | Status |
|---|---|---|
| Prosseguir próximos passos 1..5 | Helper, validate instructions, realtime decision, docs, browser proof | PASS |
| Criar `.sh` e exibir caminho completo | `/home/marcelo-karval/Backup/Projetos/supabase-postgres-18-fork/postgres/scripts/enable-kvm-preflight.sh` | PASS |
| Thor monitorar validate depois | Comandos de monitoramento definidos; aguarda você rodar KVM/apply | READY_WAITING_USER_ACTION |
| Escolher tecnologia adaptável/fácil/flexível/pronta | Node/TS MVP; Supabase Realtime spike/target futuro | PASS |
| JWT PostgREST/RLS desde o início | Claims/contract/RLS posture documentados | PASS |
| PRD/tasks/reviews/final report | Persistidos | PASS |
| Browser-proof + vision | HTTP 200 + vision PASS | PASS |

## 7. Realtime decision

MVP recomendado:

```text
PostgREST/RPC mutation
  -> Postgres RLS/JWT claims
  -> app.event_outbox durable event
  -> LISTEN/NOTIFY wake-up
  -> Node/TypeScript WebSocket bridge (ws + pg)
  -> authorize via JWT + Postgres/RLS/RPC
  -> clients
```

Supabase Realtime:

- É a opção mais pronta/testada no ecossistema Supabase.
- Deve ser um spike/target futuro contra nosso PG18 fork.
- Não é bloqueante para o MVP porque precisa validação dedicada de logical replication, roles, publications, JWT e autorização por canal.

Redis/NATS:

- Não entram como core inicial.
- Podem entrar como downstream/fanout se escala justificar.
- Nunca devem virar fonte de verdade paralela no começo.

## 8. Not claimed

- Não rodei sudo interativo.
- Não habilitei `/dev/kvm`; o helper está pronto para você executar.
- Não rodei no-skip validate depois do KVM porque `/dev/kvm` ainda não existe nesta sessão.
- Não declarei RC2.
- Não implementei a bridge realtime ainda.

## 9. Próximos passos imediatos

1. Você roda:

```bash
/home/marcelo-karval/Backup/Projetos/supabase-postgres-18-fork/postgres/scripts/enable-kvm-preflight.sh --apply
```

2. Se aparecer `/dev/kvm`, você me chama ou já roda:

```bash
cd /home/marcelo-karval/Backup/Projetos/supabase-postgres-18-fork/postgres
PG18_REQUIRE_KVM=true scripts/run-pg18-persistent-nix-validate.sh
```

3. Eu monitoro:

```bash
tail -f tmp/pg18-publish/nix-full-validate-persistent.log
tail -f tmp/pg18-publish/full-validate-persistent-nix/summary.txt
```

4. Se o validate PASS:
   - anexar evidência à RC1 se não houver novo build/digest;
   - só criar RC2 se houver nova imagem/digest ou correção material.

5. Próximo slice recomendado:
   - `pg18-realtime-bridge-mvp`
   - Node/TypeScript + `ws` + `pg`;
   - JWT/RLS desde o início;
   - browser-proof com cliente autorizado/não autorizado;
   - spike separado de Supabase Realtime.

## 10. Perguntas para o próximo passo

1. Depois de rodar o helper, você quer colar aqui o output ou quer que eu apenas cheque o host novamente?
2. Quer que o MVP realtime seja colocado dentro de `docker/pg18-postgrest-rls/` como extensão da stack durável existente?
3. Para o spike Supabase Realtime, quer comparar contra o MVP Node/TS no mesmo relatório ou em slice separado?

## 11. Final verdict

`DELIVERED_VALIDATE_AWAITS_MANUAL_KVM`.

Tudo que era seguro executar sem senha sudo foi entregue, validado, revisado, browser-proved e persistido. O próximo gate real depende de Karval executar o helper com sudo interativo para criar `/dev/kvm`.

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

