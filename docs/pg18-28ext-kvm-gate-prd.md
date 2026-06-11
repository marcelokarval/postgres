# PG18 28 Extensions KVM Gate — PRD / Plano Executivo

Status: EXECUTION_STARTED_BLOCKED_BY_KVM_INFRA
Owner/orchestrator: Thor/default
Repo: `/home/marcelo-karval/Backup/Projetos/supabase-postgres-18-fork/postgres`
Branch baseline: `karval/pg18-bootstrap`
Current committed anchor: `77d36ad9 chore: harden PG18 persistent Nix validation runner`
Date: 2026-06-11

## 1. Pedido original consolidado

Karval pediu prosseguir com os próximos passos 1..5, mantendo as 28 extensões PG18, de forma encadeada:

1. resolver o gate KVM/runner ou documentar blocker definitivo;
2. rerodar o Nix no-skip gate quando possível;
3. manter a matriz completa das 28 extensões;
4. persistir PRD, tasks, reviews e relatório final;
5. executar QA browser-proof + vision, revisar lado a lado solicitado vs entregue, corrigir sem HITL quando seguro e antecipar próximos passos.

O papel do agente principal é orquestrador/revisor. Subagentes são usados apenas quando agregam valor e com escopo restrito.

## 2. Objetivo executivo

Transformar o estado PG18 RC1 em uma trilha de fechamento controlada para uma imagem `supabase/postgres`-style PG18 mantendo as 28 extensões já declaradas, compiladas/empacotadas no caminho de package build e documentadas em runtime smoke, sem mascarar o bloqueio atual de infraestrutura KVM exigido pelos checks NixOS VM.

## 3. Não-objetivos

- Não remover nenhuma das 28 extensões.
- Não adicionar `plv8` ou `timescaledb` ao PG18 nesta rodada.
- Não chamar release final enquanto o Nix no-skip gate não passar em runner com `/dev/kvm`.
- Não usar `PG18_REQUIRE_KVM=false` como prova de release; apenas diagnóstico.
- Não executar mutação de produção/Swarm/registry além do que já foi autorizado e registrado anteriormente.

## 4. Estado factual atual

Evidência persistente em `tmp/pg18-publish/full-validate-persistent-nix/summary.txt`:

```text
START 01-psql_18_bin
DONE  01-psql_18_bin
START 02-psql_18_slim_bin
DONE  02-psql_18_slim_bin
START 03-ext-pg_jsonschema
FAIL  03-ext-pg_jsonschema exit_code=1
```

Erro do step 03:

```text
Required features: {kvm, nixos-test}
Available features: {benchmark, big-parallel, nixos-test, uid-range}
```

Host atual:

```text
/dev/kvm ausente
Virtualization: VT-x
sudo não interativo indisponível
```

Conclusão: blocker de infraestrutura runner, não falha comprovada de PG18 ou `pg_jsonschema`.

## 5. Matriz das 28 extensões mantidas

| Extensão | Versão PG18 | Declaração | Runtime | Gate formal |
|---|---:|---|---|---|
| `http` | `1.6.1` | PG18 declared | runtime smoke/status documented | Nix no-skip pending KVM |
| `hypopg` | `1.4.1` | PG18 declared | runtime smoke/status documented | Nix no-skip pending KVM |
| `index_advisor` | `0.2.0` | PG18 declared | runtime smoke/status documented | Nix no-skip pending KVM |
| `pg_cron` | `1.6.7` | PG18 declared | runtime smoke/status documented | Nix no-skip pending KVM |
| `pg_graphql` | `1.6.1` | PG18 declared | runtime smoke/status documented | Nix no-skip pending KVM |
| `pg_hashids` | `1.3.0-cd0e1b31d52b394a0df64079406a14a4f7387cd6` | PG18 declared | runtime smoke/status documented | Nix no-skip pending KVM |
| `pg_jsonschema` | `0.3.4` | PG18 declared | runtime smoke/status documented | Nix no-skip pending KVM |
| `pg_net` | `0.20.3` | PG18 declared | runtime smoke/status documented | Nix no-skip pending KVM |
| `pg_partman` | `5.3.1` | PG18 declared | runtime smoke/status documented | Nix no-skip pending KVM |
| `pg_plan_filter` | `0.1` | PG18 declared | runtime smoke/status documented | Nix no-skip pending KVM |
| `pg_repack` | `1.5.2` | PG18 declared | runtime smoke/status documented | Nix no-skip pending KVM |
| `pg_stat_monitor` | `2.0` | PG18 declared | runtime smoke/status documented | Nix no-skip pending KVM |
| `pg_tle` | `1.5.2` | PG18 declared | runtime smoke/status documented | Nix no-skip pending KVM |
| `pgaudit` | `18.0` | PG18 declared | runtime smoke/status documented | Nix no-skip pending KVM |
| `pgjwt` | `0.2.0` | PG18 declared | runtime smoke/status documented | Nix no-skip pending KVM |
| `pgmq` | `1.11.1` | PG18 declared | runtime smoke/status documented | Nix no-skip pending KVM |
| `pgroonga` | `4.0.6` | PG18 declared | runtime smoke/status documented | Nix no-skip pending KVM |
| `pgrouting` | `3.4.1` | PG18 declared | runtime smoke/status documented | Nix no-skip pending KVM |
| `pgsodium` | `3.1.8` | PG18 declared | runtime smoke/status documented | Nix no-skip pending KVM |
| `pgtap` | `1.3.3` | PG18 declared | runtime smoke/status documented | Nix no-skip pending KVM |
| `plpgsql_check` | `2.8` | PG18 declared | runtime smoke/status documented | Nix no-skip pending KVM |
| `postgis` | `3.6.3` | PG18 declared | runtime smoke/status documented | Nix no-skip pending KVM |
| `rum` | `1.3` | PG18 declared | runtime smoke/status documented | Nix no-skip pending KVM |
| `safeupdate` | `1.4` | PG18 declared | runtime smoke/status documented | Nix no-skip pending KVM |
| `supabase_vault` | `0.3.1` | PG18 declared | runtime smoke/status documented | Nix no-skip pending KVM |
| `vector` | `0.8.2` | PG18 declared | runtime smoke/status documented | Nix no-skip pending KVM |
| `wal2json` | `2.6` | PG18 declared | runtime smoke/status documented | Nix no-skip pending KVM |
| `wrappers` | `0.6.1` | PG18 declared | runtime smoke/status documented | Nix no-skip pending KVM |

Fora do PG18 por enquanto:

- `plv8`
- `timescaledb`

## 6. Estratégia de execução encadeada

### Fase A — Fechar o blocker de runner

1. Verificar `/dev/kvm` no host antes de qualquer rerun longo.
2. Se `/dev/kvm` existir, o script passa `--device /dev/kvm` ao container e injeta `extra-system-features = kvm`.
3. Se `/dev/kvm` não existir, o script falha cedo com exit `86`.
4. Se este host não puder habilitar KVM, mover o gate para runner KVM-capable.

### Fase B — Rerodar gate no-skip

Com KVM disponível:

```bash
PG18_NIX_MAX_JOBS=1 PG18_NIX_CORES=16 scripts/run-pg18-persistent-nix-validate.sh
```

Critério de aceite:

```text
PG18 validation sequence finished successfully
```

### Fase C — Corrigir blockers reais

Se o gate avançar e falhar em extensão real:

1. classificar se é source/build/test fixture/runtime;
2. corrigir menor diff possível;
3. rerodar usando o mesmo volume `pg18-nix-store`;
4. atualizar evidência.

### Fase D — QA/documentação/browser-proof

- Persistir PRD/tasks/reviews/final report.
- Persistir browser-proof estático de QA mostrando o estado e blocker.
- Capturar browser + vision.

### Fase E — Release decision

- `PASS`: somente após gate no-skip completo.
- `CONDITIONAL`: runtime/local OK, mas no-skip bloqueado por infra.
- Estado atual: `CONDITIONAL / BLOCKED_BY_KVM_INFRA`.

## 7. Riscos e mitigação

| Risco | Mitigação |
|---|---|
| Repetir horas de build sem KVM | preflight exit 86 antes do Docker runner longo |
| OOM em wrappers all_fdws | `PG18_NIX_MAX_JOBS=1`, `PG18_NIX_CORES=16`, volume persistente |
| Chamar release final cedo | relatório separa runtime proof de Nix no-skip gate |
| Extensões pesadas atrasarem gate | manter volume `pg18-nix-store`, monitorar summary/logs |
| Browser-proof virar só página estática sem valor | página deve expor matriz, blocker, evidências e não-claims |

## 8. Perguntas para próximos passos

1. Você prefere habilitar KVM localmente com sudo interativo neste workstation ou mover o gate para outro runner?
2. Se mover para runner, qual alvo preferido: máquina bare-metal, VM com nested virtualization, ou CI self-hosted?
3. Após PASS do no-skip, publicamos `rc2` ou promovemos o digest atual com evidência complementar?
4. `plv8` e `timescaledb` continuam explicitamente fora do PG18 por enquanto?
