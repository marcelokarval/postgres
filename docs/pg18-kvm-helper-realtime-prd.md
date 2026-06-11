# PG18 KVM Helper + Realtime JWT/RLS — PRD / Plano Executivo

Status: EXECUTION_STARTED_HELPER_READY_VALIDATE_BLOCKED_UNTIL_MANUAL_SUDO
Owner/orchestrator: Thor/default
Repo: `/home/marcelo-karval/Backup/Projetos/supabase-postgres-18-fork/postgres`
Branch: `karval/pg18-bootstrap`
Date: 2026-06-11

## 1. Decisões de Karval

1. Criar helper `.sh` para habilitar/validar KVM e exibir caminho completo.
2. Depois que Karval rodar o helper, Thor deve monitorar o validate.
3. Para realtime/pubsub, escolher o caminho mais adaptável, fácil, flexível e, se possível, já testado/pronto como Supabase.
4. JWT compatível com PostgREST/RLS desde o início.

## 2. Objetivo da rodada

Entregar um slice operacional fechado que:

- cria um helper seguro para KVM;
- deixa claro o comando absoluto a executar;
- não tenta capturar senha sudo nem travar a sessão;
- prepara a sequência de monitoramento do no-skip validate;
- define a decisão tecnológica do realtime JWT/RLS;
- persiste PRD/tasks/reviews/final report;
- executa browser-proof + vision da pilha documental.

## 3. Caminho absoluto do helper

```bash
/home/marcelo-karval/Backup/Projetos/supabase-postgres-18-fork/postgres/scripts/enable-kvm-preflight.sh
```

Modo somente leitura:

```bash
/home/marcelo-karval/Backup/Projetos/supabase-postgres-18-fork/postgres/scripts/enable-kvm-preflight.sh
```

Modo apply, que pode pedir senha sudo:

```bash
/home/marcelo-karval/Backup/Projetos/supabase-postgres-18-fork/postgres/scripts/enable-kvm-preflight.sh --apply
```

Depois que `/dev/kvm` existir:

```bash
cd /home/marcelo-karval/Backup/Projetos/supabase-postgres-18-fork/postgres
PG18_REQUIRE_KVM=true scripts/run-pg18-persistent-nix-validate.sh
```

Monitoramento:

```bash
tail -f /home/marcelo-karval/Backup/Projetos/supabase-postgres-18-fork/postgres/tmp/pg18-publish/nix-full-validate-persistent.log
tail -f /home/marcelo-karval/Backup/Projetos/supabase-postgres-18-fork/postgres/tmp/pg18-publish/full-validate-persistent-nix/summary.txt
```

## 4. Decisão realtime

MVP recomendado: bridge própria Node/TypeScript com `ws` + `pg`, usando:

```text
PostgREST/RPC mutation
  -> Postgres RLS/JWT claims
  -> app.event_outbox durable event
  -> LISTEN/NOTIFY wake-up
  -> Node/TS WebSocket bridge
  -> authorize via JWT + Postgres/RLS/RPC
  -> clients
```

Por que não começar direto com Supabase Realtime:

- É a opção mais pronta/testada no ecossistema Supabase.
- Mas exige spike próprio contra nosso PG18 fork, roles, logical replication, JWT, publications e autorização por canal.
- Não herda automaticamente a semântica PostgREST `request.jwt.claims` em leitura WAL.
- Portanto, é arquitetura alvo/spike, não dependência bloqueante do MVP.

Por que Node/TypeScript:

- Mais adaptável e simples para MVP.
- Ecossistema amplo e testado (`ws`, `pg`, JWT libs).
- Fácil compartilhar tipos com frontend.
- Menor acoplamento operacional que Elixir/Phoenix no primeiro slice.
- Contrato pode ser mantido compatível para trocar/combinar com Supabase Realtime depois.

Redis/NATS:

- Não entram como core inicial.
- Podem entrar depois como downstream/fanout, nunca como fonte de verdade.

## 5. Contrato JWT/RLS mínimo desde o início

Claims mínimas:

```json
{
  "role": "authenticated",
  "app_user_id": "user_karval_demo",
  "exp": 9999999999
}
```

A bridge deve:

1. Validar assinatura e expiração.
2. Rejeitar role desconhecida.
3. Normalizar claims no mesmo shape do PostgREST.
4. Consultar Postgres com claims setadas para autorização.
5. Enviar somente payload público/autorizado.
6. Nunca logar token completo.

## 6. Acceptance criteria

| Critério | Status esperado |
|---|---|
| Helper criado e executável | PASS |
| Helper sem argumento não pede sudo | PASS |
| Helper `--apply` explícito rejeita args extras | PASS |
| Helper mostra próximo validate e monitoramento | PASS |
| PRD/tasks/reviews/final report persistidos | PASS |
| Browser-proof + vision | PASS |
| No-skip validate | BLOCKED até Karval rodar sudo/apply e `/dev/kvm` existir |

## 7. Não-objetivos

- Não rodar sudo interativo nesta sessão.
- Não implementar bridge realtime ainda.
- Não publicar nova tag/digest.
- Não declarar RC2.
- Não adicionar Redis/NATS ao core.

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

