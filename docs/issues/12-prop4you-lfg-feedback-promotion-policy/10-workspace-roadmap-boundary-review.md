# Review — boundary do schema workspace e roadmap Thor endpoint

Status: delivered
Worker: C — workspace schema + Thor endpoint roadmap boundary
Escopo: revisão/proposta repo-only; sem DDL, sem browser/web/MCP, sem provider calls, sem segredos.

## 1. Veredito curto

A decisão `prop4you_user_workspace` deve entrar nesta slice como nome canônico e boundary documentado do workspace do usuário logado, não como modelo completo de tabelas.

O endpoint HTTP do banco para chamar o agent Thor deve permanecer roadmap-only nesta slice. A recomendação é abrir uma ADR futura, bloqueada por critérios explícitos de segurança, autorização, idempotência, auditoria, rate limit, segredos e isolamento transacional. Não implementar `pg_net`, cron, trigger, função HTTP ou gateway para Thor agora.

## 2. Evidência revisada

Arquivos consultados:

- `docs/issues/12-prop4you-lfg-feedback-promotion-policy/00-detection-and-analysis.md`
- `docs/issues/12-prop4you-lfg-feedback-promotion-policy/01-prd.md`
- `docs/issues/12-prop4you-lfg-feedback-promotion-policy/02-tasks.md`
- `docs/issues/12-prop4you-lfg-feedback-promotion-policy/03-execution-ledger.md`
- `docs/issues/12-prop4you-lfg-feedback-promotion-policy/04-subagent-manifest.md`
- `docs/issues/11-prop4you-system-schema-lfg-topology/09-postgres-topology-fdw-review.md`

Pontos já definidos pela slice:

```text
workspace schema: prop4you_user_workspace
LFG/system schema: prop4you_leadfinder_group
feedback: fica no LFG usando relações fracas para user/workspace/item
Thor/agent HTTP endpoint: roadmap futuro, não implementado agora
```

## 3. Boundary proposto para `prop4you_user_workspace`

### 3.1 O que entra nesta slice

Nesta slice, `prop4you_user_workspace` deve ser apenas:

1. nome canônico do bounded context do workspace logado;
2. fronteira conceitual entre experiência do usuário e verdade operacional LFG;
3. alvo futuro para seleções, snapshots, anotações, listas, ações e preferências do usuário;
4. referência textual/weak ref consumida pelo LFG feedback, sem FK forte obrigatória;
5. documento de intenção para evitar que feedback/votos sejam modelados como tabelas de UI dentro do schema LFG ou, inversamente, que verdade LFG seja movida para workspace.

Aceitável nesta slice:

```text
- declarar o schema em documentação;
- mencionar o nome `prop4you_user_workspace` em comentários/PRD/tarefas;
- usar `workspace_ref`, `workspace_public_ref` ou equivalente textual em DDL LFG, se Thor implementar votos;
- manter relações fracas para laboratório, sem identidade real de usuário.
```

### 3.2 O que NÃO deve entrar nesta slice

Não recomendo implementar agora:

```text
- create schema/table completo para workspace;
- tabelas de contas, usuários, memberships ou permissões reais;
- RLS final de workspace;
- snapshots completos de property/owner/contact;
- listas/campanhas/notas/workflows do usuário;
- dependência forte/FK do LFG para workspace;
- leitura viva pesada do workspace sobre tabelas LFG;
- provider calls ou enriquecimento a partir do workspace.
```

Motivo: o PRD explicitamente diz `No full prop4you_user_workspace table model yet` e `No real user identities; use weak text refs in lab`. Implementar o workspace completo agora ampliaria o escopo e misturaria a política de feedback/promoção com produto/UI, autenticação e autorização.

### 3.3 Contrato mínimo recomendado para interação LFG ↔ workspace

Para a DDL de feedback desta slice, o LFG deve aceitar referências fracas, por exemplo:

```text
actor_ref             text -- usuário/operador/test actor weak ref
workspace_ref         text -- workspace weak ref
workspace_public_ref  text -- opcional, se houver public ref conhecido
item_kind             text -- phone/email/mailing_address/etc.
item_ref              text -- weak ref ou public ref do item votado
```

Regra de ownership:

```text
prop4you_leadfinder_group
  owns feedback vote, aggregation, review, global marker apply

prop4you_user_workspace
  future owner of user-visible selections, snapshots, notes and actions
```

O feedback pode vir de uma tela do workspace, mas a decisão de promover marcador global pertence ao LFG, via agregação/review/apply. Um voto individual do usuário não deve alterar verdade global diretamente.

## 4. Boundary recomendado para o endpoint Thor/agent HTTP

### 4.1 Decisão desta slice

O endpoint HTTP do banco para chamar Thor deve permanecer somente roadmap. A slice deve registrar a intenção, mas não deve criar:

```text
- função SQL/plpgsql que chame Thor;
- uso de pg_net apontando para Thor;
- pg_cron que dispare análise crítica via HTTP;
- tabela de secrets/tokens/URLs;
- trigger que chame agente;
- endpoint PostgREST/API para executar agente;
- worker/gateway mock que pareça produção.
```

### 4.2 Forma correta: ADR futura com security gate

Proposta: criar no futuro uma ADR específica, por exemplo:

```text
ADR: database-to-agent critical analysis endpoint for Thor
Status inicial: proposed/blocked-by-security-review
```

A ADR deve decidir, antes de qualquer implementação:

1. quais análises são críticas o suficiente para pedir Thor;
2. se a chamada parte de cron, worker, queue, gateway ou função controlada;
3. se o banco chama HTTP diretamente ou apenas grava intenção/outbox;
4. como segredos são armazenados fora do DDL e fora de docs;
5. qual identidade/role pode solicitar análise;
6. como a resposta é validada, versionada, auditada e aplicada;
7. como impedir prompt injection/dados sensíveis indevidos;
8. quais payloads são permitidos e quais devem ser redigidos;
9. qual timeout, retry, DLQ, idempotency key e rate limit;
10. como evitar side effect dentro de transação crítica.

### 4.3 Gate mínimo de segurança antes de implementação

Nenhuma implementação deve começar antes de existir resposta documentada para:

```text
AuthN/AuthZ
  - Quem pode pedir Thor?
  - Qual role SQL/gateway executa?
  - Como impedir uso por usuário final sem autorização?

Secrets
  - Onde ficam URL/token/chave?
  - Como rotaciona?
  - Como garantir que DDL, fixtures e logs não vazem segredo?

Data minimization
  - Qual contrato JSON mínimo?
  - PII/sensíveis são redigidos?
  - Raw provider payload é proibido por default?

Transaction boundary
  - A chamada é pós-commit/async?
  - O banco nunca bloqueia update crítico esperando LLM?
  - Existe outbox/queue para retry?

Idempotency and replay
  - Como deduplicar chamadas?
  - Como versionar prompt/policy/modelo?
  - Como auditar resposta e decisão humana?

Operational safety
  - rate limit, timeout, retry, DLQ;
  - circuit breaker/manual disable;
  - observability e alertas;
  - ambiente lab/staging/prod separado.
```

### 4.4 Padrão futuro preferido

Para análises críticas, o padrão mais seguro é assíncrono e revisável:

```text
domain event/review row committed
  -> outbox/queue records intent for Thor analysis
  -> worker/gateway outside critical transaction calls Thor
  -> response stored as advisory proposal with hash/version
  -> human/policy review applies or rejects
  -> final apply function mutates canonical state
```

`pg_cron` pode futuramente agendar varreduras/ticks, mas deve disparar funções estáveis que selecionam work items e não devem embutir segredo nem prompt completo na DDL. `pg_net` pode ser avaliado, mas somente depois da ADR e preferencialmente para side effects pós-commit com payload mínimo e idempotente.

## 5. Relação com feedback votes e dictionary promotion

Este boundary protege as duas lanes principais da slice:

1. Feedback/votes: voto do usuário é evidência fraca. A agregação/review do LFG decide recomendação. O apply global é função/gate LFG.
2. Dictionary promotion: proposta preparada é revisada/aplicada por política LeadFinder. Thor pode ser assistente futuro, mas não autoridade automática nesta slice.

Regra recomendada:

```text
human/user feedback != global truth
Thor analysis != automatic canonical mutation
review/apply policy owns promotion
```

## 6. Recomendações para Thor implementar nesta slice

Ao implementar as próximas tarefas desta issue:

1. Declarar `prop4you_user_workspace` em docs e, se necessário, em comentário/skeleton estritamente mínimo.
2. Não criar tabelas completas de workspace.
3. Manter DDL de feedback em `prop4you_leadfinder_group`, com weak refs para user/workspace/item.
4. Não criar endpoint Thor, chamada HTTP, cron, `pg_net`, segredo ou provider call.
5. Registrar endpoint Thor como roadmap/ADR futura, com status bloqueado por security review.
6. Se houver campo de metadata para análise futura, nomear como intenção neutra (`analysis_context`, `review_metadata`) sem URLs, tokens ou payload sensível.

## 7. Riscos se o boundary for violado

- Escopo da slice explode para autenticação, workspace product model e RLS final.
- Voto de usuário pode ser confundido com verdade global LFG.
- Endpoint Thor sem gate pode vazar PII, segredos ou raw payload.
- HTTP em trigger/transação crítica pode causar latência, retry duplicado e mutação não determinística.
- Cron/agent sem idempotência pode reprocessar ou aplicar recomendações automaticamente.
- DDL com URL/token/prompt sensível dificultaria auditoria e rotação.

## 8. Acceptance local desta review

- `prop4you_user_workspace` confirmado como nome canônico de schema de workspace.
- Boundary recomendado: declarado/docs only nesta slice; sem full tables.
- Thor endpoint recomendado como future ADR, gated by security; sem implementação.
- Nenhum DDL foi editado por este worker.
