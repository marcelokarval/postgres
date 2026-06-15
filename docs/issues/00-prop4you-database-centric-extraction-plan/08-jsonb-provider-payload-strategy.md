# Estratégia JSONB/provider payload — Prop4You extração database-centric

Status: draft para revisão Thor
Owner: Worker A
Escopo: estratégia; nenhum DDL real implementado neste arquivo.
Fonte backend lida em modo read-only: `/home/marcelo-karval/Backup/Projetos/prop4you/prop4you-inertia/backend/src`
Stack de issue: `docs/issues/00-prop4you-database-centric-extraction-plan`

## 1. Marcadores de validação

- [VALIDATION:SOURCE_READ] Evidências lidas em código existente: `domains/data/models/sourcehub.py`, `domains/data/models/skip_trace.py`, `domains/data/models/system_cache.py`, `domains/real_estate/models/history_models.py`, `apps/public/address_entry/queries.py`, `apps/system/matrix/models.py`.
- [VALIDATION:NO_PROVIDER_CALLS] Nenhuma chamada para APIs de terceiros foi feita. A análise foi estática e repo-local.
- [VALIDATION:NO_RUNTIME_MUTATION] Nenhum runtime, Docker, segredo ou sistema externo foi mutado.
- [VALIDATION:NO_REAL_DDL] Os blocos SQL abaixo são exemplos comentados de desenho; não foram aplicados em banco.
- [VALIDATION:JSONB_FIRST] Estratégia cobre preservação raw, linhagem, projeção canônica, campos projetados/gerados, índices, JSON_TABLE, política de mutação, plano de prova em laboratório e riscos residuais.

## 2. Conclusão executiva

A extração Prop4You deve tratar payloads de provider e payloads internos como um fluxo em camadas:

1. Bronze/raw: preservar payload bruto e envelope de execução/linhagem sem interpretação destrutiva.
2. Silver/normalized: registrar projeções normalizadas e métricas estáveis, ainda rastreáveis ao raw.
3. Gold/canonical: promover apenas fatos aceitos pelo dicionário canônico Matrix/LeadFinder/SourceHub para tabelas relacionais fortes ou snapshots canônicos.
4. Projection/index layer: materializar campos gerados/projetados a partir de JSONB somente quando o caminho tiver semântica estável e carga de consulta real.

Regra central: JSONB é substrato de contrato, auditoria e flexibilidade; não substitui tabelas relacionais para identidade, joins, permissões, constraints e workflows críticos.

## 3. Evidências encontradas no backend atual

### 3.1 SourceHub raw ingress

`domains/data/models/sourcehub.py` já modela uma camada raw mínima:

- `SourceHubRawRecord.provider_slug`, `list_type_slug`, `state_slug`.
- `ingestion_mode`: `api`, `csv`, `manual_upload`, `reprocess`, `product_originated`.
- `payload_format`: `json`, `csv`, `xml`, `unknown`, `product_seed`.
- `processing_status`: `pending`, `processed`, `failed`.
- `external_reference_id`.
- `payload_hash` com constraint única por escopo provider/list/state/hash.
- `raw_payload` como `JSONField`.
- `ingested_at`, `processed_at`.

Interpretação database-centric: este é o bronze record. Ele deve virar um contrato explícito em DDL, com raw imutável, deduplicação por hash e escopo, e referências públicas para reprocessamento.

### 3.2 Skip trace / DirectSkip

`domains/data/models/skip_trace.py` e `domains/data/models/system_cache.py` mostram dois padrões que devem ser preservados, mas reorganizados:

- `SkipTraceRequest` guarda input estruturado do usuário/produto, FK opcional para `real_estate.Property`, ids públicos SourceHub (`sourcehub_request_public_id`, `sourcehub_raw_record_public_id`, `sourcehub_seed_public_id`), retry e status.
- `SkipTraceResult` guarda resultado normalizado (`phones`, `emails`, `addresses`, `owner_returned`, `related_people`, `match_metrics`, `result_metrics`) e também `raw_response`.
- `SystemSkipTraceResult` é cache global/dedup por provider, nome/endereço/zip e `canonical_property_public_id`, com JSONs normalizados e métricas.
- `SkipTraceSnapshot` é trilha imutável de request/response provider com `request_payload`, `response_payload`, status, custo e tempo.

Interpretação: skip trace enriquece; não define verdade final de owner/property. Payloads de request/response devem ser retidos como evidência, e contatos/identidades promovidos só por política canônica e Matrix.

### 3.3 Realtor/address entry

`apps/public/address_entry/queries.py` contém mapeamento de Realtor GraphQL para seed canônica de detalhes do imóvel:

- Extrai root de `data.home.property`, `data.home`, `data.property` ou payload bruto.
- Lê caminhos como `description.sub_type`, `description.type`, `description.beds`, `description.baths`, `description.sqft`, `description.year_built`, `lot.size`, `estimate.estimate.amount`, `estimates.current_values.amount`.
- Produz `build_canonical_property_details_seed(...)` e `serialize_public_property_details(...)`.

Interpretação: esses caminhos são candidatos a campos projetados/gerados, mas ainda devem passar por comparação com payloads reais e pelo dicionário canônico antes de congelar DDL.

### 3.4 Property history / snapshots

`domains/real_estate/models/history_models.py` guarda `PropertyHistory.dto` como snapshot JSON do DTO canônico, com `canonical`, `snapshot_kind`, `promotion_kind` e conceito de `portable_canonical_property_snapshot`.

Interpretação: snapshot canônico é gold/read/audit artifact; não deve ser confundido com raw provider. Ele referencia proveniência (`dto_public_id`, `raw_record_public_id` aparecem em testes) e deve ficar reprodutível a partir do raw + regras de promoção.

### 3.5 Matrix

`apps/system/matrix/models.py` usa JSONFields como `baseline_payload`, `metadata` e conceitos de genome, baseline, corpus, field review e growth pressure, incluindo `PROVIDER_DRIFT_OBSERVED`.

Interpretação: Matrix governa semântica e drift. Mudança em path provider não deve virar DDL imediatamente; deve entrar como pressão/field review e só depois promover campos.

## 4. Estratégia de camadas

### 4.1 Bronze: payload bruto imutável

Objetivos:

- Guardar o payload como recebido, preferencialmente `jsonb` quando o formato for JSON.
- Guardar envelope de execução separadamente do payload: provider, endpoint lógico, operação, ingestão, status HTTP quando existir, idempotency key, request id, correlation id, hash, versão de contrato observada, tenant/user/workspace quando permitido.
- Não sobrescrever `raw_payload`. Correções/reprocessamentos criam novo raw record ou nova versão derivada.
- Sanitizar/segregar segredos: API keys nunca entram em raw payload; dados sensíveis pessoais podem existir por obrigação funcional, mas precisam de RLS, minimização de exposição e retenção.

Modelo conceitual:

```sql
-- EXEMPLO CONCEITUAL, NÃO APLICAR COMO DDL NESTA FASE.
-- Bronze SourceHub/provider ingress. O raw é append-only.
create table sourcehub.raw_record_example (
  id uuid primary key default uuidv7(),
  public_ref text not null unique,              -- ex.: shraw_...
  provider_slug text not null,                  -- realtor, directskip, product, csv_vendor
  provider_operation text not null,             -- address_search, property_detail, skip_trace_response
  list_type_slug text not null default '',
  state_slug text not null default '',
  ingestion_mode text not null,                 -- api/csv/manual_upload/reprocess/product_originated
  payload_format text not null,                 -- json/csv/xml/product_seed/unknown
  external_reference_id text not null default '',
  correlation_ref text not null default '',      -- request/job/outbox/click path; não segredo
  payload_hash text not null,                   -- sha256 canônico do payload bruto normalizado
  raw_payload jsonb not null,                   -- payload preservado; append-only
  provider_envelope jsonb not null default '{}', -- status, headers allowlist, timing, contract version
  ingest_metadata jsonb not null default '{}',   -- importer, parser, file offset, source uri hash
  processing_status text not null default 'pending',
  ingested_at timestamptz not null,
  processed_at timestamptz,
  -- A unicidade deve deduplicar sem apagar evidência.
  unique (provider_slug, list_type_slug, state_slug, payload_hash)
);
```

### 4.2 Silver: normalização rastreável

Objetivos:

- Transformar raw provider em blocos normalizados de domínio, sem declarar verdade final.
- Guardar `normalized_payload`/`projection_payload` com versão do mapeador, status, erros e referências ao raw.
- Separar métricas operacionais de fatos canônicos.

Exemplo:

```sql
-- EXEMPLO CONCEITUAL.
-- Uma projeção normalizada pode ser reprocessada quando o mapper muda.
create table sourcehub.normalized_projection_example (
  id uuid primary key default uuidv7(),
  raw_record_id uuid not null,                  -- FK conceitual para sourcehub.raw_record_example
  mapper_key text not null,                     -- realtor_property_details_v1, directskip_contacts_v2
  mapper_version text not null,
  normalized_payload jsonb not null,            -- estrutura estável do mapper, não verdade final
  projection_status text not null default 'pending',
  validation_errors jsonb not null default '[]',
  created_at timestamptz not null default now(),
  unique (raw_record_id, mapper_key, mapper_version)
);
```

### 4.3 Gold: promoção canônica

Objetivos:

- Promover para tabelas fortes somente quando Matrix/LeadFinder/SourceHub concordam no significado.
- Guardar linhagem por fato: qual raw, qual mapper, qual decisão/política, qual snapshot.
- Permitir reconstrução: raw -> normalized -> canonical fact/snapshot.

Exemplo:

```sql
-- EXEMPLO CONCEITUAL.
-- Fatos canônicos devem apontar para evidência, não copiar provider como verdade cega.
create table real_estate.property_detail_fact_example (
  id uuid primary key default uuidv7(),
  property_id uuid not null,
  fact_name text not null,                      -- bedrooms, bathrooms, year_built, lot_size_sqft
  fact_value jsonb not null,                    -- mantém tipo/valor/unidade quando necessário
  confidence numeric(5,2) not null default 0,
  sourcehub_raw_record_ref text not null,        -- shraw_...
  normalized_projection_ref text not null default '',
  matrix_decision_ref text not null default '',
  effective_at timestamptz not null default now(),
  superseded_at timestamptz
);
```

## 5. Linhagem obrigatória

Cada payload/projeção/fato precisa carregar ou derivar estes campos mínimos:

- `public_ref`: id público estável e auditável.
- `provider_slug`: origem externa/interna (`realtor`, `directskip`, `sourcehub_csv`, `product_originated`).
- `provider_operation`: busca, detalhe, skip trace request, skip trace response, import, reprocess.
- `external_reference_id`: id do provider quando existe, por exemplo property_id Realtor ou tracking id provider.
- `payload_hash`: dedupe/replay.
- `ingestion_mode` e `payload_format`.
- `correlation_ref`: liga UI/request/job/outbox sem expor segredo.
- `mapper_key`/`mapper_version`: qual código transformou o raw.
- `promotion_policy_ref`: qual política decidiu promoção.
- `raw_record_public_id`: referência bronze usada pelo DTO/snapshot.
- `dto_public_id`/`snapshot_public_id`: quando produzido snapshot canônico.

No backend atual, parte disso já existe em `SourceHubRawRecord`, `SkipTraceRequest`, `SystemSkipTraceResult`, `SkipTraceSnapshot` e `PropertyHistory.dto.provenance`; a DDL deve consolidar essas ideias com nomes e constraints explícitos.

## 6. Projeção canônica e campos gerados/projetados

### 6.1 Critérios para promover um JSONB path

Um path JSONB vira coluna gerada/projetada apenas se todos forem verdadeiros:

1. Semântica aprovada no dicionário Matrix/LeadFinder.
2. Path observado em corpus real suficiente, não só em fixture ou suposição.
3. Consulta frequente ou join/filtro/sort exige performance previsível.
4. Tipo e unidade são estáveis ou normalizáveis.
5. Drift tem fallback seguro: path ausente não corrompe verdade; vira `null`/erro de validação.
6. Existe comentário DDL documentando payload origin, JSON path, regra de coerção e política de mutação.

### 6.2 Candidatos vindos do código lido

Realtor/address details:

- `raw_payload #>> '{data,home,property,description,sub_type}'` ou variações para `property_type`.
- `description.beds` -> `bedrooms`.
- `description.baths` -> `bathrooms`.
- `description.sqft`/`sqft_calc`/`building_size.size` -> `square_feet`.
- `description.year_built` -> `year_built`.
- `lot.size`/`lot_sqft` -> `lot_size_sqft`.
- `list_price`/`price`/`estimate.estimate.amount`/`estimates.current_values.amount` -> candidato a valuation seed, não necessariamente detail fact.

DirectSkip/skip trace:

- `response_payload`/`raw_response` -> contatos brutos.
- `phones`, `emails`, `addresses`, `owner_returned`, `related_people` já aparecem como JSON normalizado.
- Métricas frequentes: `match_metrics.ownerNameExactMatch`, `result_metrics.phonesFound`, `result_metrics.emailsFound`, `providerStatus`.

Property snapshot DTO:

- `dto.canonical`, `dto.snapshot_kind`, `dto.provenance.dto_public_id`, `dto.provenance.raw_record_public_id`, `dto.property.details.property_type`, `dto.situations[*].type_slug`.

### 6.3 Exemplos de generated columns

```sql
-- EXEMPLO CONCEITUAL. Usar STORED só quando houver consulta/index real.
create table sourcehub.realtor_property_payload_example (
  id uuid primary key default uuidv7(),
  raw_record_id uuid not null,
  raw_payload jsonb not null,

  -- Path preferencial conforme código atual; aceitar null quando provider muda shape.
  realtor_property_id text generated always as (
    raw_payload #>> '{data,home,property,property_id}'
  ) stored,

  bedrooms integer generated always as (
    nullif(raw_payload #>> '{data,home,property,description,beds}', '')::integer
  ) stored,

  property_type text generated always as (
    coalesce(
      raw_payload #>> '{data,home,property,description,sub_type}',
      raw_payload #>> '{data,home,property,description,type}',
      raw_payload #>> '{data,home,property,property_type}'
    )
  ) stored
);

-- Comentários esperados em DDL real:
-- comment on column ...property_type is
-- 'Projeção estável de raw_payload Realtor para tipo canônico candidato. Governado por Matrix; null indica path ausente/drift.';
```

Atenção: casts diretos podem falhar quando provider envia texto inesperado. Em DDL real, preferir função segura imutável de coerção (`try_int`, `try_numeric`) no pacote base/projeto antes de usar casts em generated columns.

## 7. Índices JSONB e relacionais

### 7.1 Princípios

- Índices B-tree para identidade, status, datas, provider/list/state/hash e colunas geradas usadas em filtros.
- GIN em `jsonb` apenas para queries ad hoc/controladas de containment/path; não indexar todo payload por padrão se a carga for append-heavy e grande.
- Índices parciais para filas/status (`pending`, `failed`) e payloads processáveis.
- Índices de expressão para paths raros, quando não justificarem coluna gerada.
- Medir com `EXPLAIN (ANALYZE, BUFFERS)` em `pg18_ddl_lab` antes de congelar.

Exemplos:

```sql
-- EXEMPLO CONCEITUAL.
-- Busca operacional por escopo e dedupe.
create index on sourcehub.raw_record_example
  (provider_slug, list_type_slug, state_slug, payload_hash);

-- Fila de processamento: menor e mais útil que indexar todos os status igualmente.
create index on sourcehub.raw_record_example (ingested_at)
  where processing_status = 'pending';

-- GIN para investigações controladas por payload; avaliar custo em payloads grandes.
create index sourcehub_raw_payload_gin_example
  on sourcehub.raw_record_example using gin (raw_payload jsonb_path_ops);

-- Expression index quando um path é usado, mas ainda não merece coluna gerada.
create index realtor_property_id_expr_example
  on sourcehub.raw_record_example ((raw_payload #>> '{data,home,property,property_id}'))
  where provider_slug = 'realtor';

-- Coluna gerada + B-tree para filtro/sort estável.
create index realtor_bedrooms_idx_example
  on sourcehub.realtor_property_payload_example (bedrooms)
  where bedrooms is not null;
```

## 8. Uso de PG18 JSON/JSON_TABLE

O contexto do repo trata PG18 como Application Data Kernel com `JSONB / SQL-JSON / JSON_TABLE`. Use `JSON_TABLE` para explodir arrays complexos em staging/read models sem escrever parsers Python para cada relatório.

Bons usos para Prop4You:

- DirectSkip `contacts`, phones, emails e related people.
- Realtor arrays de propriedades em map/search results.
- PropertyHistory DTO `situations` e `source_facts` para validação Matrix.
- Imports CSV convertidos para payload JSON com linhas/erros por registro.

Exemplo:

```sql
-- EXEMPLO CONCEITUAL de leitura; adaptar sintaxe ao dialeto confirmado no PG18 final.
-- Objetivo: transformar contatos em linhas de staging sem perder o raw original.
select
  r.public_ref as raw_record_ref,
  jt.ordinality as contact_ordinal,
  jt.first_name,
  jt.last_name,
  jt.phone_number,
  jt.email
from sourcehub.raw_record_example r,
json_table(
  r.raw_payload,
  '$.contacts[*]'
  columns (
    ordinality for ordinality,
    first_name text path '$.first_name' null on empty,
    last_name  text path '$.last_name' null on empty,
    phone_number text path '$.phones[0].number' null on empty,
    email text path '$.emails[0].email' null on empty
  )
) as jt
where r.provider_slug = 'directskip';
```

Se a sintaxe/feature exata divergir no container final, manter fallback com `jsonb_array_elements`/lateral views. A decisão de DDL deve ser validada contra `pg18_ddl_lab`.

## 9. Política de mutação

### 9.1 Raw records

- Append-only.
- `raw_payload`, `provider_envelope`, `payload_hash`, `ingested_at` não devem ser atualizados após ingestão.
- Erros de classificação/processamento atualizam apenas status e campos operacionais (`processing_status`, `processed_at`, `validation_errors`) ou criam projection record.
- Reprocessamento cria nova projection version, não altera raw.
- Se houver necessidade legal de remoção/mascaração, registrar tombstone/redaction event e aplicar política específica; não apagar silenciosamente sem trilha.

### 9.2 Normalized projections

- Versionadas por `mapper_key`/`mapper_version`.
- Podem ser invalidadas/superseded, não editadas in-place sem versão.
- Validação falha deve preservar o payload e registrar erro estruturado.

### 9.3 Canonical facts/snapshots

- Canonical tables recebem fatos promovidos por função/procedure controlada, nunca por update manual em JSON raw.
- Snapshots canônicos são imutáveis ou versionados; novas promoções criam novo snapshot/fato e supersedem o anterior quando necessário.
- Correção humana deve apontar para decisão Matrix/HITL e raw evidence.

### 9.4 Provider config e segredos

- API keys e tokens não entram em payload raw nem em docs.
- Configuração de provider deve residir em tabela/secret store apropriado com criptografia/RLS; payload strategy só armazena metadados allowlist.

## 10. Prova de laboratório proposta

Não implementar agora; este é o plano de prova para futura execução em `pg18_ddl_lab`.

1. Criar pacote experimental temporário de DDL em sandbox, não no produto final.
2. Inserir fixtures sintéticas e sanitizadas para:
   - Realtor property details com shapes `data.home.property`, `data.property`, root direto.
   - DirectSkip response com contacts/phones/emails/related people.
   - SourceHub product-originated seed.
   - PropertyHistory canonical DTO com provenance.
3. Verificar dedupe por `(provider_slug, list_type_slug, state_slug, payload_hash)`.
4. Verificar append-only com trigger/policy que bloqueia update de `raw_payload`.
5. Testar generated columns com paths estáveis e casts seguros.
6. Testar expression indexes e GIN com `EXPLAIN (ANALYZE, BUFFERS)`.
7. Testar `JSON_TABLE`; se indisponível/incompatível no container, registrar fallback `jsonb_array_elements`.
8. Reprocessar o mesmo raw com `mapper_version` diferente e confirmar coexistência de projections.
9. Promover facts canônicos com lineage completa: raw -> projection -> canonical fact/snapshot.
10. Validar RLS/permission boundary para que raw PII/provider payload não seja exposto em `api.*` por padrão.

Critérios de sucesso do lab:

- [LAB:RAW_APPEND_ONLY] tentativa de update no raw falha ou é rejeitada por função governada.
- [LAB:DEDUPE_HASH] duplicate payload no mesmo escopo não cria evidência duplicada acidental.
- [LAB:LINEAGE_ROUNDTRIP] fact/snapshot canônico aponta para raw e projection.
- [LAB:JSON_PROJECTION] generated/expression paths retornam valores esperados em fixtures.
- [LAB:JSON_TABLE_OR_FALLBACK] arrays provider viram linhas via JSON_TABLE ou fallback documentado.
- [LAB:EXPLAIN_RECORDED] planos de índices registrados antes do freeze.

## 11. Padrão de exposição via API

- `api.*` deve expor canonical views e read models, não raw payloads por padrão.
- Admin/forensics podem acessar raw com RLS e redaction explícita.
- Payloads provider com PII devem ter views sanitizadas: phones/emails podem aparecer só conforme autorização, finalidade e plano.
- `PropertyHistory.dto` pode alimentar leitura portátil, mas endpoints de produto devem preferir canonical tables/views quando estabilizadas.

## 12. Resíduos e riscos

- [RISK:PROVIDER_CONTRACTS_INCOMPLETE] Contratos reais de Realtor/DirectSkip/SourceHub ainda não foram colhidos integralmente; paths atuais vêm de código e testes, não de amostragem provider completa.
- [RISK:STATIC_ANALYSIS_ONLY] Análise foi estática; comportamento dinâmico, filas, caches e flags podem alterar fluxo real.
- [RISK:PII_RETENTION] Skip trace contém PII sensível; retenção, redaction e RLS precisam de decisão jurídica/produto antes do DDL final.
- [RISK:CAST_SAFETY] Generated columns com casts diretos podem falhar em payload drift; criar funções de coerção segura antes de DDL final.
- [RISK:GIN_COST] GIN amplo em raw payload pode degradar ingestão/maintenance; usar só com prova de query real.
- [RISK:JSON_TABLE_SYNTAX] Sintaxe/limitações de `JSON_TABLE` devem ser verificadas no container PG18 alvo; fallback lateral JSONB precisa estar documentado.
- [RISK:CANONICAL_OVERPROMOTION] Promover campos rápido demais congela suposições de provider como verdade canônica. Matrix deve governar admissões.
- [RISK:SECRET_LEAKAGE] Provider envelopes devem ser allowlist; headers e request bodies podem conter tokens se não filtrados antes da persistência.

## 13. Decisão recomendada

Adotar uma arquitetura JSONB-first governada por SourceHub:

- `sourcehub.raw_*` como bronze append-only e deduplicado.
- `sourcehub.normalized_*` como projections versionadas por mapper.
- `real_estate.*`/`data.*` como canonical/enrichment facts com lineage obrigatória.
- Matrix como gate semântico para promover paths e detectar drift.
- Generated columns/indexes somente após corpus + query proof.
- `JSON_TABLE` como ferramenta de staging/read-model no PG18 lab quando arrays complexos justificarem.

Esta estratégia preserva payloads e auditabilidade sem transformar Postgres em Mongo-style store, e mantém LeadFinder/real_estate como verdade canônica, SourceHub como ingresso/linhagem, Skip Trace como enriquecimento, e Matrix como governança semântica.
