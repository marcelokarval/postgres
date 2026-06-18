# Review — topologia multi-Postgres, FDW, deploy e carga LFG

Status: delivered
Worker: B — multi-Postgres/FDW/deploy/load topology
Escopo: revisão arquitetural repo-only; sem DDL concreto de FDW, sem credenciais, sem provider calls, sem browser.

## 1. Veredito curto

Recomendo tratar LFG/`system` como um sistema interno external-like com carga própria, não como simples conjunto de tabelas quentes do workspace do usuário logado.

A topologia alvo deve privilegiar:

```text
1. domínio de usuário/hot workspace isolado para OLTP interativo;
2. domínio LFG/SourceHub/Matrix isolado para ingestão variável, transformação, materialização e inteligência;
3. contratos entre domínios por ID, version, hash, snapshot e outbox;
4. FDW apenas para lookup pontual, transação de snapshot controlada e comparação de versão;
5. materialized/read models locais para consultas recorrentes e dashboards;
6. pgmq/pg_cron/pg_net/outbox/workers para assíncrono operacional fora da transação crítica.
```

FDW é aceitável neste desenho, mas não deve virar camada de consulta distribuída pesada nem mecanismo de escrita distribuída. Em especial: evitar joins vivos grandes entre nós, dashboards diretamente sobre foreign tables, `count(*)` exato sobre tabelas estrangeiras massivas e qualquer hipótese de transação distribuída forte.

## 2. Evidência repo-only revisada

Arquivos de orientação e contexto lidos:

- `docs/issues/11-prop4you-system-schema-lfg-topology/00-detection-and-analysis.md`
- `docs/issues/11-prop4you-system-schema-lfg-topology/01-prd.md`
- `docs/issues/11-prop4you-system-schema-lfg-topology/02-tasks.md`
- `docs/issues/11-prop4you-system-schema-lfg-topology/04-subagent-manifest.md`
- `AGENTS.md`
- `docs/canonical-docs-index.md`
- `docs/pg18-application-data-kernel-context.md`
- `docs/database-centric-app-model.md`
- `docs/issues/10-prop4you-lfg-staging-materialization-operational/09-lfg-materialization-review.md`
- `docs/issues/10-prop4you-lfg-staging-materialization-operational/10-lfg-operational-facets-review.md`
- `database/ddl/projects/prop4you/leadfinder_group/README.md`
- buscas repo-only por `FDW`, `postgres_fdw`, `wrappers`, `pgmq`, `pg_net`, `pg_cron`, `wal2json`, `outbox`, `realtime`.

Pontos canônicos encontrados no repo:

- O projeto já enquadra PG18 como Application Data Kernel: núcleo transacional + engine de domínio + eventos + JSONB contracts + async operacional + queues/jobs + FDW hub.
- A regra ativa diz: multi-schema para nosso sistema database-centric; multi-database para externos/third-party ou separações operacionais justificadas; FDW para correlação controlada; staging/materialized views para leituras pesadas recorrentes; outbox + pgmq/workers para consistência e side effects.
- O pacote base já possui `realtime.event_outbox`, trigger LISTEN/NOTIFY e ACKs.
- A política de `pg_cron` já é multi-db: `cron.database_name=postgres` como scheduler central e `cron.schedule_in_database(...)` para bancos de produto.
- A superfície PG18 validada/documentada inclui conceitos úteis para esta fatia: `postgres_fdw`/`wrappers`, `wal2json`, `pgmq`, `pg_cron`, `pg_net`, `pg_jsonschema`, `pg_partman`, `pgaudit`, observability e índices/search.
- O fluxo LFG atual já foi restringido: SourceHub traduz DTOs; LFG staging/materialization/operational minimum consome DTOs e hashes/lineage, não provider raw payload diretamente.

## 3. Topologia recomendada

### 3.1 Começar com fronteira lógica forte; separar fisicamente quando a carga pedir

A regra default do repo continua válida: schemas são bounded contexts dentro de um database-centric app. Porém, para LFG existe motivo operacional claro para separação física quando o volume crescer:

```text
p4y_hot / workspace de usuário
  - login/session context via gateway
  - listas salvas, snapshots escolhidos pelo usuário, análise, notas, campanhas, permissões
  - OLTP interativo, baixa latência, RLS/API facade

lfg_system / internal external-like system
  - SourceHub raw/lineage/DTO publications
  - Matrix mapping artifacts
  - LeadFinder/LFG staging, materialization, operational intelligence
  - ingestão alta e variável, batch, backfill, reprocessamento, reviews operacionais

postgres / scheduler-operational control plane
  - pg_cron central conforme política existente
  - schedules que chamam funções estáveis nos bancos alvo
```

Isto pode começar como schemas no mesmo banco durante laboratório e migrar para multi-Postgres quando ingestão, VACUUM, locks, WAL, manutenção de índices, refreshes ou CPU de transformação começarem a competir com o hot workspace.

### 3.2 Critério de separação multi-Postgres

Separar LFG/SourceHub/Matrix para instância ou banco dedicado quando uma ou mais condições ocorrerem:

- ingestão/backfill LFG causa variação visível de latência no workspace;
- tabelas raw/event/staging exigem particionamento, retenção e VACUUM com cadência diferente do OLTP de usuário;
- materializações ou refreshes precisam de janelas próprias;
- reprocessamentos de dictionary/Matrix/DTO geram picos de WAL/IO;
- dashboards/intelligence precisam de read models grandes;
- operadores LFG precisam permissões e rotinas distintas de usuários P4Y.

Não separar apenas por nomenclatura. Separar quando houver carga, ownership operacional, política de retenção ou risco de blast radius diferentes.

### 3.3 Fronteira conceitual entre instâncias

O workspace do usuário não deve depender de join vivo sobre a verdade completa do LFG. Ele deve guardar referências e snapshots:

```text
user_workspace.selected_lead_or_property
  lfg_entity_ref/id
  lfg_public_ref
  source_publication_id/ref
  dictionary_version_id
  matrix_artifact_id/ref
  source_hash / dto_hash / snapshot_hash
  lfg_version
  snapshot_payload compacto
  snapshot_taken_at
  refresh_status
```

O LFG permanece dono de ingestão, lineage, provider/public-record/contact intelligence e materialização. O workspace guarda o que o usuário escolheu/viu/usou, com version/hash para detectar desatualização.

## 4. FDW: onde usar e onde não usar

### 4.1 Usos recomendados

FDW é adequado para:

- lookup pontual por chave estável (`public_ref`, UUID, dedupe key, source hash);
- conferir se um snapshot do usuário está desatualizado via `version`, `updated_at`, `dto_sha256` ou `snapshot_hash`;
- montar uma transação curta de snapshot: buscar N registros explicitamente selecionados e gravar cópia local compacta;
- validação operacional de versão de dictionary/Matrix antes de uma promoção;
- refresh de materialized/read model com janela, limite, cursor e timeout;
- inspeção administrativa controlada por operadores, nunca como path quente de tela.

### 4.2 Usos a evitar explicitamente

Evitar FDW para:

- joins cross-node grandes entre workspace e LFG;
- `count(*)` exato sobre foreign tables massivas;
- dashboards que consultam diretamente foreign tables em tempo real;
- paginação profunda remota;
- escrita distribuída crítica;
- transações que exigem atomicidade forte entre bancos;
- chamadas em triggers do hot workspace que dependam de rede;
- expandir raw payload/DTO completo para a UI via FDW.

Regra prática: FDW pode buscar o que já foi escolhido e identificado; não deve descobrir, ranquear ou agregar massa de dados remotos no caminho quente.

### 4.3 Padrão FDW seguro para P4Y/LFG

Sem escrever DDL aqui, o padrão conceitual é:

```text
hot workspace transaction
  -> valida request/actor
  -> identifica refs LFG pequenas e explícitas
  -> opcionalmente lê versão/hash por FDW com timeout/limite
  -> grava snapshot local compacto ou marca refresh_needed
  -> emite outbox event
  -> worker/queue faz refresh pesado fora da transação quente
```

Se a leitura remota falhar, o workspace deve preferir estado explícito (`stale`, `refresh_failed`, `needs_manual_refresh`) em vez de bloquear indefinidamente a experiência do usuário.

## 5. Alta ingestão variável do LFG

### 5.1 Separar ingestão de materialização e hot workload

O fluxo recomendado permanece:

```text
provider/raw/input
  -> SourceHub raw/inbox com lineage e validação
  -> Matrix artifacts / dictionary version contracts
  -> SourceHub translated DTO publication
  -> LFG staging candidates
  -> LFG materialization runs/results
  -> LFG operational groups/events/facets minimum
  -> user workspace snapshot/selection/refresh
```

Cada seta deve ser reprocessável e versionada. A ingestão não deve escrever diretamente no workspace do usuário. A materialização LFG não deve fazer chamadas HTTP/provider. O workspace não deve consumir raw payload.

### 5.2 Controle de picos

Para carga variável, usar camadas explícitas:

- tabelas append-only para raw/event/lineage;
- particionamento/retention por tempo ou batch quando o volume justificar;
- staging com status, gate, hash e erro revisável;
- materialization runs com limites, contadores e idempotência;
- filas (`pgmq` ou tabela de queue domain-owned) para work items;
- `pg_cron` central chamando funções estáveis de tick;
- workers externos para CPU/HTTP/IO externo;
- read models/materialized views para consumo repetitivo;
- eventos outbox para notificar cache/UI/realtime.

### 5.3 Counts e dashboards

Para massa LFG, evitar contar tabela estrangeira ou raw table enorme sob demanda. Preferir:

- contadores por batch/run/status atualizados em tabelas de execução;
- rollups incrementais por janela;
- materialized views locais com refresh controlado;
- estimativas/telemetria quando o usuário não precisa de número exato;
- `count(*)` exato somente em escopo pequeno e indexado.

## 6. Hot user workload

O banco/schema de usuário deve ser protegido contra picos LFG:

- path de UI deve ler tabelas locais ou snapshots compactos;
- filtros/listagens devem operar sobre índices locais e read models próprios;
- refresh LFG deve ser uma ação explícita/assíncrona quando exigir massa remota;
- se precisar exibir frescor, mostrar `snapshot_taken_at`, `lfg_version`, `lfg_hash`, `refresh_status`;
- comandos do usuário devem emitir eventos/outbox e retornar rápido;
- RLS/API facade deve ficar no domínio de usuário, não sobre tabelas LFG cruas.

Isto preserva autonomia: usuário usa uma visão estável; LFG continua evoluindo ingestão e inteligência.

## 7. Realtime, outbox, async HTTP e queues

### 7.1 Realtime/outbox

`realtime.event_outbox` deve ser a ponte durável entre mutação de domínio e transporte. A regra é:

```text
domain write commit
  -> insert durable outbox event
  -> LISTEN/NOTIFY sinaliza
  -> bridge/worker lê, entrega, ACKa ou reprocessa
```

Não usar realtime como fonte de verdade. Não depender de WebSocket/SSE para consistência. O cliente pode receber sinal de que um snapshot ficou stale, uma materialization run terminou ou um refresh foi enfileirado, mas a verdade continua nas tabelas e snapshots.

### 7.2 Async HTTP/pg_net

`pg_net` ou HTTP async deve ser tratado como pós-commit/side-effect. Evitar HTTP dentro de transações LFG/workspace que precisam ser rápidas e determinísticas.

Uso aceitável:

- notificação assíncrona de evento já gravado;
- webhook operacional idempotente;
- integração disparada por worker ou job;
- callback com retry/DLQ e idempotency key.

Evitar:

- provider enrichment dentro de trigger OLTP;
- bloquear insert/update esperando resposta externa;
- gravar segredo/credential em DDL ou docs.

### 7.3 Queues e workers

Para LFG, queues devem carregar intenção, não payload sensível integral:

```text
job_type
aggregate_ref/id
source_publication_id
batch/run id
idempotency_key
attempt_count
not_before/available_at
last_error_code
metadata resumido
```

`pgmq` é adequado como queue durável quando instalado no banco alvo; uma tabela domain-owned é aceitável para gate conceitual inicial, como SourceHub já faz com enrichment requests. Workers externos executam CPU pesada, chamadas provider e refreshes grandes, retornando resultado via função estável e auditável.

## 8. Deploy operacional recomendado

### 8.1 Camadas

```text
PG18 image/build recipe
  - postgres + extensões compiladas/validadas
  - sem DDL Prop4You embutido

Base DDL
  - base/audit/realtime/api primitives
  - extension enablement por banco

Product DDL Prop4You
  - schemas domain-owned: SourceHub, Matrix, LeadFinder/LFG, workspace etc.

Runtime services
  - PostgREST/gateway opcional
  - realtime bridge opcional
  - workers LFG/SourceHub
  - scheduler pg_cron central
```

### 8.2 Ambientes

- Lab/dev: aceitar schemas no mesmo banco para prova rápida, desde que os contratos não assumam co-localidade eterna.
- Staging: simular multi-db para provar snapshots, version checks, job scheduling e falhas FDW.
- Produção futura: separar LFG ingestion/read models do hot workspace se métricas confirmarem disputa de recursos.

### 8.3 Observabilidade mínima

Antes de promoção, definir métricas por domínio:

- ingest rows/sec, batches/min, lag de fila, retry/DLQ;
- tempo de materialization run e contadores `input/result/passed/blocked/failed`;
- tempo de refresh de snapshot;
- latência p95/p99 do workspace;
- locks, WAL, autovacuum, bloat, tamanho de partições;
- erros FDW por tipo: timeout, auth/config, remote unavailable, row limit exceeded;
- outbox lag e ACK lag.

## 9. Decisões arquiteturais propostas

1. Não tratar LFG como schema de usuário; tratar como upstream interno external-like.
2. Permitir multi-schema no começo, mas desenhar contratos para poder mover LFG/SourceHub/Matrix para banco/instância dedicada.
3. Workspace de usuário consome snapshots por ID/version/hash, não joins vivos sobre toda massa LFG.
4. FDW é ferramenta de lookup/snapshot/version check, não query engine distribuída pesada.
5. Read models e materialized views devem ficar perto do consumidor que consulta com frequência.
6. Ingestão LFG deve ser append/status/gate/retry, desacoplada por queue/outbox/workers.
7. Realtime informa mudanças; não transporta verdade nem substitui snapshot.
8. HTTP/provider calls ficam fora de transações críticas e fora da DDL LFG.
9. Counts massivos exatos devem ser substituídos por rollups/contadores de run/estimativas quando possível.
10. Deploy deve preservar a regra do repo: imagem PG18 reutilizável separada de DDL base e DDL de produto.

## 10. Perguntas abertas para a síntese canônica

- Qual será o nome final do banco/schema hot workspace P4Y quando separado de LFG?
- O LFG ficará em um banco dedicado dentro da mesma instância, em instância dedicada, ou ambos por estágio de maturidade?
- Quais entidades do workspace precisam snapshot local imediatamente: property, owner, contact hint, lead opportunity, group/facets?
- Qual SLA de frescor aceitável para a tela do usuário: segundos, minutos ou manual refresh?
- Qual volume esperado de ingestão LFG por janela para decidir particionamento e instância dedicada?
- Quando `pgmq` deve substituir tabelas de queue domain-owned existentes?

## 11. Riscos residuais

- Se FDW for usado em dashboards ou filtros de massa, a separação física pode piorar latência em vez de proteger o workspace.
- Sem snapshots/version hashes claros, usuário pode ver estado LFG mutável sem saber que sua análise ficou stale.
- Sem métricas de lag/latência, a decisão multi-schema vs multi-Postgres ficará opinativa.
- Sem limites/cursores nos jobs, backfills podem competir com materialization e realtime.
- Se eventos realtime forem tratados como fonte de verdade, ACK/replay pode virar acoplamento indevido.
- Se workers/provider calls forem embutidos em função transacional, o sistema perde idempotência e previsibilidade.

## 12. Próxima task sugerida

Na síntese canônica, consolidar um diagrama textual único com três lanes:

```text
LFG/System ingest lane
  SourceHub -> Matrix -> LFG staging/materialization/operational

User hot workspace lane
  selected refs -> snapshots -> user annotations/actions -> API facade/RLS

Async/integration lane
  outbox -> pgmq/jobs -> workers -> pg_net/realtime -> read models
```

E definir uma política objetiva de FDW:

```text
permitido: point lookup, snapshot transaction, version/hash check
proibido: heavy cross-node joins, massive exact counts, dashboards live over foreign tables, distributed critical writes
```
