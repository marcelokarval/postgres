# Worker C — LFG operational/facet minimum review

Status: delivered
Updated: 2026-06-17T20:54:54-04:00
Scope: T5.2 / futuro `leadfinder_group/0003_operational_minimum.sql`

## Veredito

Recomendo um mínimo operacional de 3 tabelas, no máximo, para provar o caminho T4 -> staging -> materialization gate -> operational sem congelar o produto final Lead Finder Group:

1. `prop4you_leadfinder_group.operational_groups`
2. `prop4you_leadfinder_group.operational_group_events`
3. `prop4you_leadfinder_group.operational_group_facets`

Esse desenho satisfaz a aceitação de "minimal operational groups/events/facets" e evita explodir agora em `properties`, `owners`, `addresses`, `phones`, `emails`, `situations`, `valuations`, `relationships`, etc. Essas entidades ainda não devem virar tabelas canônicas nesta fatia.

## Regra de fronteira

- LeadFinder/LFG pode criar o agrupamento operacional mínimo depois de um resultado de materialização revisável.
- SourceHub continua dono de ingress, raw evidence, lineage e DTO publication.
- Matrix continua dono dos artefatos de mapeamento/semântica.
- O mínimo operacional não deve copiar raw payload, não deve chamar provider, não deve expor RLS pública e não deve se tornar o modelo final de property/owner/lead.

## Strong FK vs lineage JSONB

Usar FK forte somente para contratos internos estáveis do próprio pacote `leadfinder_group`:

- `operational_groups.materialization_result_id -> materialization_results(id)` ou equivalente definido em `0002_materialization_runs.sql`.
- Opcionalmente `materialization_run_id -> materialization_runs(id)` se o Worker B/DDL T5.1 tornar esse contrato explícito e estável.
- `operational_group_events.group_id -> operational_groups(id)`.
- `operational_group_facets.group_id -> operational_groups(id)`.
- `operational_group_facets.created_by_event_id -> operational_group_events(id)` somente se o evento inicial for sempre criado junto; caso contrário manter nullable.

Não recomendo FK direta, nesta fatia, de operational/facets para provider/raw/class/Matrix/SourceHub externos. Preserve esses vínculos como `lineage jsonb`, porque o formato do evidence/provider ainda é instável e as decisões de canonical graph ainda não estão congeladas.

Lineage JSONB mínimo recomendado por row operacional/facet:

```json
{
  "sourcehub_publication_id": "uuid-as-text",
  "sourcehub_publication_public_ref": "p4yshd_...",
  "source_payload_sha256": "sha256-or-null",
  "matrix_artifact_id": "uuid-as-text",
  "matrix_artifact_key": "...",
  "leadfinder_dictionary_version_id": "uuid-as-text",
  "materialization_run_id": "uuid-as-text",
  "materialization_result_id": "uuid-as-text",
  "no_provider_calls": true,
  "raw_payload_not_copied": true
}
```

Guardar IDs como texto em `lineage` é aceitável aqui porque o contrato forte é o resultado de materialização; a evidência externa fica auditável sem acoplar o operacional a tabelas que podem mudar.

## Tabela 1 — operational_groups

Propósito: um envelope operacional revisável para o grupo candidato LFG produzido por uma materialização aceita.

Campos mínimos sugeridos, sem DDL final:

- `id uuid primary key default uuidv7()`
- `public_ref text generated ...` com prefixo novo, por exemplo `p4ylfg` ou similar registrado no pacote
- `materialization_result_id uuid not null` com FK forte para o contrato T5.1
- `group_key text not null` idempotente, derivada de contrato interno, não de raw address/name
- `group_status text not null default 'candidate'`
- `review_status text not null default 'unreviewed'`
- `summary jsonb not null default '{}'::jsonb`
- `lineage jsonb not null default '{}'::jsonb`
- lifecycle padrão: `active`, `deleted`, `created_at`, `updated_at`, `version`, actor fields conforme padrões existentes

Status mínimo:

- `candidate`
- `active_review`
- `accepted_operational`
- `blocked`
- `rejected`
- `superseded`
- `archived`

Checks importantes:

- `summary` e `lineage` precisam ser JSON object.
- grupo só pode nascer de resultado materializado aprovado/aceito pelo gate T5.1; se isso não couber em FK/check simples, fazer via função de materialização operacional.
- unique parcial em `group_key where deleted = false` ou unique em `materialization_result_id` para garantir 1 grupo operacional por resultado, dependendo da decisão do Worker B.

## Tabela 2 — operational_group_events

Propósito: log append-only mínimo do que aconteceu com o grupo, sem virar event-sourcing completo.

Campos mínimos sugeridos:

- `id uuid primary key default uuidv7()`
- `group_id uuid not null references operational_groups(id)`
- `event_type text not null`
- `event_status text not null default 'recorded'`
- `event_payload jsonb not null default '{}'::jsonb`
- `lineage jsonb not null default '{}'::jsonb`
- `occurred_at timestamptz not null default now()`
- actor/lifecycle mínimo, sem delete físico

Tipos mínimos:

- `group_materialized`
- `facet_asserted`
- `facet_changed`
- `review_status_changed`
- `group_superseded`
- `materialization_blocked`

Recomendação: eventos não precisam referenciar SourceHub/Matrix por FK. O evento herda `materialization_result_id`/SourceHub/Matrix no `lineage`, e a FK forte fica só em `group_id`.

## Tabela 3 — operational_group_facets

Propósito: armazenar fatos/facetas estruturadas suficientes para prova operacional, sem criar as entidades finais.

Campos mínimos sugeridos:

- `id uuid primary key default uuidv7()`
- `group_id uuid not null references operational_groups(id)`
- `created_by_event_id uuid references operational_group_events(id)` nullable
- `facet_type text not null`
- `facet_key text not null`
- `facet_value jsonb not null`
- `confidence numeric(5,4)` nullable, ou score JSONB se preferir evitar semântica prematura
- `facet_status text not null default 'candidate'`
- `review_status text not null default 'unreviewed'`
- `lineage jsonb not null default '{}'::jsonb`
- lifecycle padrão

Facet types mínimos para provar o caminho com DTOs traduzidos:

- `property_identity_hint`
- `owner_identity_hint`
- `contact_hint`
- `situation_fact`
- `valuation_hint`
- `relationship_hint`
- `source_quality`
- `lead_opportunity_signal`

Notas:

- `situation_fact` deve ser tratado como fato estruturado, não tag solta.
- `contact_hint` não deve virar phone/email table nesta fatia.
- `property_identity_hint` não deve virar property table nesta fatia.
- `owner_identity_hint` não deve virar owner table nesta fatia.
- `facet_value` precisa ser object ou scalar? Recomendo object para preservar `value`, `normalized`, `unit`, `observed_at`, `redaction`, `source_field` sem inventar colunas demais.
- Unique parcial sugerida: `(group_id, facet_type, facet_key, coalesce(lineage->>'sourcehub_publication_id','')) where deleted = false`, ou mais simples `(group_id, facet_type, facet_key) where deleted = false` se só houver uma faceta vigente por chave.

## Função operacional mínima

Para não deixar inserts livres criarem grupos a partir de resultados bloqueados, recomendo uma função gateway-agnostic, não DDL final aqui:

`prop4you_leadfinder_group.materialize_operational_minimum(p_materialization_run_id uuid, p_actor_id text default null, p_metadata jsonb default '{}'::jsonb)`

Responsabilidades:

1. Selecionar apenas `materialization_results` com gate/status aceito pelo T5.1.
2. Criar/upsert `operational_groups` idempotentemente.
3. Criar um evento `group_materialized`.
4. Expandir somente um conjunto controlado de facet types a partir do resultado/DTO traduzido.
5. Copiar para `lineage` os IDs/hashes/resumos, não raw payload.
6. Retornar contagens: groups, events, facets.

Essa função pode ser a única porta normal de escrita para as três tabelas na prova T5, mantendo o runtime/gateway agnóstico.

## O que evitar explicitamente nesta fatia

Não criar agora:

- `properties`
- `owners`
- `owner_property_links`
- `addresses`
- `parcels`
- `phones`
- `emails`
- `legal_situations`
- `valuations`
- `media`
- `skiptrace_results`
- `lead_scores`
- tabelas públicas/API/RLS

Também evitar:

- FKs para provider evidence instável fora do pacote.
- Colunas específicas demais extraídas de payload real.
- Dumps de `translated_dto.fields` em docs/proofs.
- Status que impliquem verdade canônica final, como `canonical_property_created`.

## Índices mínimos

- `operational_groups(materialization_result_id)` unique ou unique parcial.
- `operational_groups(group_status, review_status) where deleted = false`.
- `operational_group_events(group_id, occurred_at desc) where deleted = false`.
- `operational_group_events(event_type, occurred_at desc) where deleted = false`.
- `operational_group_facets(group_id, facet_type, facet_key) where deleted = false`.
- GIN em `operational_group_facets.lineage` ou `facet_value` só se a prova precisar consultar por JSONB; caso contrário pode esperar para não indexar prematuramente.

## Critérios de aceitação para o Worker C

A implementação T5.2 deve ser considerada compatível se:

- criar grupos/eventos/facetas a partir dos 10 resultados de materialização, sem DDL de produto final;
- manter FK forte apenas em `leadfinder_group`/materialization stable contracts;
- preservar SourceHub/Matrix/provider/raw como `lineage jsonb` e hashes/resumos;
- não copiar raw payload para operational;
- não criar provider calls, cron, workers ou exposição pública;
- permitir proof com contagens: 10 groups, pelo menos 10 events e facetas derivadas dos 10 resultados.

## Risco principal

O risco maior é deixar `operational_group_facets` virar uma lixeira de tags. A mitigação é exigir `facet_type`, `facet_key`, `facet_value` object, `lineage` object, status/review explícitos e uma lista pequena de facet types autorizados nesta primeira versão.
