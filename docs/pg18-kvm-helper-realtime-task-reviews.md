# PG18 KVM Helper + Realtime JWT/RLS — Task Reviews

## Método

Parent/orchestrator criou o helper, delegou revisão, aplicou correções do SA-01, integrou decisão do SA-02 e rerodou validações decisivas. Subagent self-report foi input, não verdade final.

## Requested vs delivered por task

| Task | Solicitado | Entregue | Evidência | Review | Correção ativa |
|---|---|---|---|---|---|
| R00 | PRD/tasks persistidos | Criados | PRD/tasks docs | PASS | N/A |
| R01 | Helper `.sh` com caminho completo | `scripts/enable-kvm-preflight.sh`, executável, caminho absoluto no PRD/final | bash -n; preflight exit 86 | PASS_AFTER_FIX | Rejeição de args extras e validate no output adicionados |
| R02 | Mais adaptável/fácil/flexível/pronto possível | Node/TS bridge MVP; Supabase Realtime como spike/target | SA-02 final | PASS | N/A |
| R03 | JWT PostgREST/RLS desde início | Contrato mínimo definido | PRD seção JWT/RLS | PASS | N/A |
| R04 | Review por task/final | Este arquivo | review doc | PASS | N/A |
| R05 | Browser-proof + vision | Página servida localmente; HTTP/DOM/vision confirmados; server encerrado | HTTP 200; markers; vision PASS | PASS | Parent validou liveness pós-captura |
| R06 | Commit/report | Relatório final atualizado; commit pendente neste instante | final report | PASS_PENDING_COMMIT | Parent commita e reporta |

## Correções aplicadas a partir do SA-01

1. `--apply` agora rejeita argumentos extras:

```text
scripts/enable-kvm-preflight.sh --apply --typo -> exit 64
```

2. Caminho `KVM_READY=no` agora mostra:

```text
After /dev/kvm exists, rerun:
  PG18_REQUIRE_KVM=true scripts/run-pg18-persistent-nix-validate.sh
```

## Final review preliminar

- Orquestração: PASS.
- Subagentes: 2 simultâneos, slots fechados.
- MCP/browser desnecessário em subagentes: PASS.
- Helper: PASS após correção.
- Validate no-skip: BLOCKED até Karval executar `--apply` com sudo e `/dev/kvm` existir.
- Realtime: decisão arquitetural PASS; implementação fica para próximo slice.


## Browser-proof evidence

- URL local: `http://127.0.0.1:18086/pg18-kvm-helper-realtime-browser-proof.html`
- HTTP pós-captura: `200`
- Markers: título, `enable-kvm-preflight.sh --apply`, `Node/TypeScript bridge`, `app.event_outbox`, `JWT compatível com PostgREST/RLS`, `Supabase Realtime`, `Redis/NATS`.
- Vision QA: PASS; página visível, não branca, sem erro, com helper, validate monitor, current gate, realtime decision e not claimed.
- Server: encerrado pelo parent após captura.
