# 08 — Auditoria legado SystemArea / autocomplete / geografia

Status: concluído
Worker: A
Escopo auditado: `prop4you-inertia/backend/src/domains/geography/` — `models/area_models.py`, `services/system_area_registration_service.py`, `services/geokeo_system_area.py`, `services/area_discovery.py`, migrations `0007`, `0009`, `0010`, e testes relacionados.
Restrição aplicada: sem chamadas de rede/provider; sem copiar payloads brutos/PII/valores sensíveis. Este documento reporta contratos, campos, constraints, índices, estados e recomendações DDL.

## 1. Fontes lidas

- `models/area_models.py`
- `models/geokeo_candidate_models.py` para os contratos operacionais criados/consumidos por GeoKeo/Realtor autocomplete.
- `services/system_area_registration_service.py`
- `services/geokeo_system_area.py`
- `services/area_discovery.py`
- `services/area_db_helpers.py` para o caminho efetivo `get_or_create_area` -> registration service.
- Migrations:
  - `0001_initial.py` para a tabela `geography_system_area` original.
  - `0007_systemaddress_area_refs_json.py`
  - `0009_geokeo_system_area_feed.py`
  - `0010_systemarea_geo_area_search_gin_idx_and_more.py`
- Testes amostrados/relacionados:
  - `test_system_area_registration_service.py`
  - `test_geokeo_system_area_pipeline.py`
  - `test_geokeo_system_area_feed.py`
  - buscas em `tests/` por registration, candidate, attempt, known_existing, force_refresh, boundary_status, area_refs.

## 2. Modelo canônico legado: `SystemArea`

Tabela Django: `geography_system_area`.

Herança/mixins relevantes:

- `BaseModel`: `id`, `public_id`, `created`, `updated`, `active`, `deleted`, `version`, `search`, `data`, `metadata`, campos de auditoria/cache/soft-delete conforme base legada.
- `GeoSpatialMixin`: `location` e `boundary_geom` com PostGIS, ambos SRID 4326.

Tipos de área aceitos (`AreaType`, STI em uma única tabela):

- `state`
- `county`
- `city`
- `postal_code`
- `neighborhood`
- `street`
- `school`
- `school_district`
- `university`
- `park`
- `mlsid`
- `market_area`

Campos próprios de `SystemArea`:

| Campo | Tipo/contrato legado | DDL recomendado |
| --- | --- | --- |
| `slug_id` | texto até 255, obrigatório, único, indexado; identificador estável/canônico vindo do provider ou fallback controlado | `text not null unique`; manter índice/constraint único; considerar normalização apenas por contrato, não por trigger oculta |
| `realty_id` | texto até 255, opcional, indexado; id/object id do provider | `text null`; índice btree simples; se possível índice parcial `where realty_id is not null` |
| `area_type` | texto até 30, obrigatório, choices acima, indexado | `text not null` + `check area_type in (...)`; índice com `state` e autocomplete |
| `parent_id` | FK self nullable, `on_delete set null`, related `children` | FK self `on delete set null`; índice composto com `area_type` |
| `name` | texto até 255, obrigatório, indexado | `text not null`; índice conforme autocomplete |
| `state` | texto até 2, obrigatório, indexado; código US de 2 caracteres no uso principal | `text not null` + check sugerido `state ~ '^[A-Z]{2}$'` para SystemArea materializada; atenção: candidates usam contextos mais longos |
| `market_median_dom` | inteiro opcional | `integer null`; não é chave de autocomplete |
| `market_median_listing_price` | decimal 12,2 opcional | `numeric(12,2) null` |
| `inventory_count` | inteiro opcional | `integer null` |
| `flood_risk_level` | texto até 50 opcional | `text null` ou `varchar(50)` |
| `noise_level_score` | inteiro opcional | `integer null`; check sugerido `0 <= noise_level_score <= 100` quando não nulo |
| `boundary_fetch_attempted` | boolean default false | `boolean not null default false` |
| `location` | Point geography/geometry SRID 4326 nullable | `geography(Point,4326)` ou `geometry(Point,4326)` conforme padrão do pacote; índice GiST |
| `boundary_geom` | MultiPolygon geography/geometry SRID 4326 nullable | `geography(MultiPolygon,4326)` ou `geometry(MultiPolygon,4326)`; índice GiST |
| `search` | array texto preparado por `SearchProcessor`; inclui self + ancestrais | `text[] not null default '{}'` + GIN |
| `data` | JSON flexível; guarda provider/provenance/boundary_status/raw_payload legado | `jsonb not null default '{}'`; evitar expor/copiar `raw_payload` em seed/proof |
| `metadata` | JSON flexível; guarda registration metadata e timezone em states | `jsonb not null default '{}'` |

Constraints/índices já expressos no legado:

- `unique(slug_id)`.
- `unique(name, area_type, state)` via `unique_together`.
- `unique(public_id)` herdado de `BaseModel`.
- Índices:
  - `idx_area_type_state` em `(area_type, state)`.
  - `idx_parent_area_type` em `(parent_id, area_type)`.
  - `idx_state_name` em `(state, name)`.
  - `idx_area_location_gist` GiST em `location`.
  - `idx_area_boundary_gist` GiST em `boundary_geom`.
  - `geo_area_search_gin_idx` GIN em `search` (migration 0010).
  - `geo_area_autocomplete_st_idx` em `(active, deleted, area_type, state, name)` (migration 0010).
  - `geo_area_autocomplete_name_idx` em `(active, deleted, area_type, name)` (migration 0010).

Recomendação DDL para Slice 18:

- Manter `SystemArea` como tabela canônica de geografia materializada; não transformar candidates/feed em verdade canônica.
- Implementar checks explícitos para `area_type`, `state`, score e não-negatividade de contadores de mercado quando aplicável.
- Manter `deleted`/`active` em índices de autocomplete se o pacote herdar soft-delete; idealmente usar índices parciais equivalentes em PG (`where active and not deleted`) para reduzir custo.
- O contrato de `search` depende de self + ancestrais. Se o DDL não portar `SearchProcessor`, criar função SQL/RPC ou processo de refresh documentado para popular termos equivalentes.

## 3. Contrato de busca/autocomplete local

`SystemArea.get_search_fields()` compõe termos de busca com:

- `name`
- `state`
- `area_type`
- `slug_id`
- `realty_id`
- nome completo do estado a partir de `state`
- alias de county com sufixo `County` quando necessário
- mesmos campos dos ancestrais (`parent`, avô etc.)

A migration `0010` reconstrói `search` para todos os SystemAreas e adiciona GIN + índices compostos de autocomplete. Isso indica que autocomplete local não deve depender exclusivamente de chamadas de provider depois que as linhas estão materializadas.

DDL recomendado:

- Coluna `search_terms text[]`/`search text[]` com GIN.
- Função de refresh de termos que replique: self + ancestrais + nome de estado + alias county.
- Índices para dois caminhos de consulta:
  - filtrado por `state`: `(area_type, state, name)` ou parcial `(area_type, state, name) where active and not deleted`.
  - sem state: `(area_type, name)` ou parcial equivalente.

## 4. Serviço de registro: `register_system_area`

Contrato de entrada (`SystemAreaRegistrationRequest`):

- Identidade/proveniência: `source`, `requester`, `provider`, `provider_object_id` obrigatório.
- Área: `area_type`, `label`, `state`, `provider_slug_id`, `provider_geo_id`, `centroid`, `parent` opcional.
- Operacional: `raw_payload`, `metadata`, `source_record_id`, `source_term`.
- Guards: `allow_system_write`, `allow_boundary_enqueue`, `boundary_fetch_attempted`, `boundary_status`.

Estados de saída (`SystemAreaRegistrationStatus`):

- `created`
- `already_installed`
- `dry_run_needs_write`
- `skipped_unsupported_type`
- `skipped_invalid_payload`

Regras observadas:

- `area_type = address` é explicitamente não materializável como `SystemArea`.
- `area_type` precisa estar em `AreaType.values`; outros tipos são skipped.
- `provider_object_id` e `label` são obrigatórios para criar/vincular.
- `state` é upper/trim e truncado a 2 caracteres; para `state` pode derivar de payload/label.
- `slug_id` usa `provider_slug_id` ou fallback derivado do label + state.
- Busca idempotente de existente nessa ordem:
  1. `realty_id = provider_object_id`
  2. `slug_id = provider_slug_id/fallback`
  3. `data.provider_geo_id = provider_geo_id`
  4. `(name, area_type, state)`
- Ao encontrar existente, atualiza campos vazios/seguros e mescla `data`/`metadata`; não sobrescreve nome se já havia identidade provider.
- Ao criar, grava `slug_id`, `realty_id`, `area_type`, `name`, `state`, `location`, `parent`, `boundary_fetch_attempted`, `data`, `metadata`.
- Sempre que permitido, agenda enriquecimento de boundary para row criada ou existente.

Contrato JSON em `data` criado/mesclado:

- `provider`
- `provider_object_id`
- `provider_slug_id`
- `provider_geo_id`
- `source`
- `requester`
- `source_term`
- `source_record_id`
- `boundary_status` (default usado: `pending`)
- `registration_provenance` limitado aos últimos 10 itens
- `raw_payload` existe no legado, mas deve ser tratado como lineage restrita e não exposto/copiado em artefatos públicos

Contrato JSON em `metadata`:

- `system_area_registration` com `source`, `requester`, `provider`, `provider_object_id`.
- Preserva alguns campos canônicos/release evidence de metadata existente e evita sobrescrita indevida.

DDL recomendado:

- Para idempotência, além de `unique(slug_id)` e `unique(name, area_type, state)`, considerar índice funcional/parcial em `(data->>'provider_geo_id') where data ? 'provider_geo_id'` se esse lookup permanecer crítico.
- Separar provider lineage operacional de payload bruto: `data`/`metadata` JSONB podem ficar, mas o pacote DDL deve preferir colunas e tabelas ledger para chaves consultadas (`provider`, `provider_object_id`, `provider_geo_id`, `source_record_id`).
- Criar RPC/funcionalidade transacional equivalente a `register_system_area` para centralizar writes, em vez de writes diretos em tabelas raw.

## 5. GeoKeo / candidate / attempt: `geokeo_system_area.py`

Regra central do módulo: GeoKeo é gerador de termos/candidatos, não cria/atualiza `SystemArea` diretamente. O próprio arquivo declara que não deve materializar `SystemArea`; teste confirma ausência de `SystemArea.objects.create/update_or_create` nesse serviço.

Mapeamento de hipóteses GeoKeo -> área:

- Materializáveis/sancionáveis via Realtor autocomplete: `state`, `county`, `city`, `neighborhood`, `market_area`, e `postal_code` quando explicitamente aceito por `realtor_area_types_for`.
- Vários tipos de lacuna (`*_gap`), `address`, `mlsid`, `street`, `school`, etc. viram não-fit ou placeholders para auditoria, sem provider call quando não sancionados.

Objetos/estados:

- `CandidateTerm`: termo de origem, tipo de origem, label, country, state_context, hipótese de area_type, query Realtor, area_types permitidos, source ids/evidence note.
- `AutocompleteResolutionDecision`: decisão provider/ledger com outcomes.
- `RealtorAutocompleteMatch`: match provider confirmado com object id, label, area_type, country/state, boundary/geometry, slug e evidence limitado.

Outcomes do attempt:

- `confirmed`
- `known_existing`
- `skip`
- `miss`
- `non_fit`
- `ambiguous`
- `provider_error`
- `blocked`

Outcomes materializáveis:

- `confirmed`
- `known_existing`

Guardrails antes de ledger/materialização:

- Se já existe `SystemArea` local por label/area_type/state, short-circuit com `known_existing` e zero chamada provider.
- `address`, candidates sem `realtor_area_types` ou com decisão non-fit não chamam provider.
- Cache por `cache_key` evita segunda chamada provider.
- Decisão materializável precisa ter `area_match`.
- Ambiguidade > 1 vira `ambiguous`.
- `area_type` do match deve bater com hipótese e estar nos area_types sancionados.
- Country/state devem bater com contexto quando fornecido.
- Match precisa confirmar boundary e geometry diferente de point.

Tabelas operacionais em `models/geokeo_candidate_models.py`:

### `geography_system_area_candidate`

Campos próprios:

- `source_name`, `source_type`, `source_record_id`, `snapshot_version`
- `original_label`, `normalized_label`
- `country_code`, `state_context`
- `provider_query`, `realtor_area_types` JSON
- `target_area_type_hypothesis`
- `dedupe_key` único sha256
- `status`: `new`, `eligible`, `resolved`, `rejected`, `deferred`
- `latest_decision`
- `evidence_note`
- `normalization_version`
- `materialized_area_id` FK nullable para `SystemArea`

Índices/constraints:

- `unique(dedupe_key)`.
- `idx_area_cand_source_type(source_name, source_type, target_area_type_hypothesis)`.
- `idx_area_cand_context_label(country_code, state_context, normalized_label)`.

### `geography_system_area_candidate_attempt`

Campos próprios:

- `candidate_id` FK cascade
- `provider_name`, `provider_query`
- `cache_key` único sha256
- `normalization_version`
- `outcome`
- provider identity/label/category/country/state
- `ambiguity_count`, `has_boundary`, `geometry_type`, `rejection_reason`, `http_status`, `duration_ms`
- `evidence` JSON limitado
- `materialized_area_id` FK nullable para `SystemArea`

Índices/constraints:

- `unique(cache_key)`.
- `idx_area_att_candidate_out(candidate_id, outcome)`.
- `idx_area_att_provider_out(provider_name, outcome)`.

DDL recomendado:

- Preservar candidate/attempt como ledger operacional, não como tabela canônica de área.
- Checks para enums de `status`/`outcome`/`target_area_type_hypothesis`.
- Unique keys sha256 podem ser `char(64)` com check hex opcional.
- `evidence`/payload JSONB deve ser bounded por contrato de aplicação; em PG puro, considerar check leve por tamanho de `evidence::text` se necessário.

## 6. Feed GeoKeo/Realtor autocomplete: migration `0009`

A migration `0009` adiciona duas tabelas de feed operacional.

### `geography_system_area_feed_term`

Campos próprios:

- `source_name`, `source_record_id`, `snapshot_version`
- `original_label`, `normalized_label`, `country_code`
- `provider_name` default `realtor_autocomplete`
- `provider_query`
- `realtor_area_types` JSON
- `limit` default 100
- `cache_key` único
- `feed_version` default `geokeo-systemarea-feed-v2`
- `status`: `pending`, `searching`, `completed`, `failed`, `stale`
- métricas: `provider_call_made`, `result_count`, `created_count`, `already_installed_count`, `skipped_count`, `failed_count`
- `last_error`, `search_started_at`, `search_completed_at`

Índices/constraints:

- `unique(cache_key)`.
- `idx_area_feed_term_label(source_name, country_code, normalized_label)`.
- `idx_area_feed_term_provider(provider_name, status)`.

### `geography_system_area_feed_result`

Campos próprios:

- `feed_term_id` FK cascade
- `provider_name`
- `provider_object_id`
- `provider_result_key` único
- `provider_area_type`
- `provider_label`
- `provider_slug_id`
- `provider_geo_id`
- `provider_state_code`, `provider_country_code`
- `provider_score`
- `provider_centroid` JSON
- `provider_payload` JSON bounded
- `materialization_status`: `pending`, `created`, `already_installed`, `skipped_unsupported_type`, `skipped_invalid_payload`, `failed`
- `materialization_reason`
- `system_area_id` FK nullable `set null`
- `feed_version`

Índices/constraints:

- `unique(provider_result_key)`.
- `idx_area_feed_res_status(feed_term_id, materialization_status)`.
- `idx_area_feed_res_type(provider_name, provider_area_type)`.
- `idx_area_feed_res_slug(provider_slug_id, provider_area_type)`.

DDL recomendado:

- Se Slice 18 precisa somente autocomplete geography DDL, incluir essas tabelas apenas se o pacote também cobrir o pipeline de feed/ledger. Caso contrário, documentar como operacional posterior.
- Não expor `provider_payload` publicamente; tratar como lineage/diagnóstico.
- `provider_result_key` e `cache_key` devem ser deterministicamente calculados por camada app/RPC.

## 7. `area_discovery.py` e `area_db_helpers.py`

`AreaDiscoveryService` usa Realtor autocomplete/boundary provider em runtime, mas nesta auditoria não houve chamadas externas. Contrato observado:

- `discover_counties(state)`: consulta autocomplete por nome do estado e `area_types=['county']`, materializa via `get_or_create_area` e parent=state.
- `discover_cities(county)`: consulta por county/state e `area_types=['city']`, exige location, materializa com parent=county e tenta enrich_boundary quando criado.
- `discover_zipcodes(city)`: consulta por city/state e `area_types=['postal_code']`, exige location, materializa com parent=city.
- `_extract_suggestion_data` normaliza suggestion externo para: `name`, `state_code`, `slug_id`, `location`, `realty_id`, `data`.

`area_db_helpers.get_or_create_area` agora passa pelo registration service, gerando `provider_object_id` se ausente e preservando idempotência central.

DDL recomendado:

- A hierarquia mínima deve aceitar `state -> county -> city -> postal_code`, mas o modelo permite outras relações via self-FK.
- Não codificar limite parcial do discovery legado (ex.: amostragens de counties/cities) no DDL; isso é comportamento de job/teste.
- Boundary enrichment é async/operacional; no DDL, representar status (`boundary_status`) e geometry, mas não acoplar provider calls.

## 8. Migration `0007`: `SystemAddress.area_refs`

`0007_systemaddress_area_refs_json.py` adiciona em `SystemAddress`:

- `area_refs` JSONField default `{}` blank, help text: weak SystemArea refs keyed by `area_type` with `slug_id` values.

Contrato inferido:

- É vínculo fraco de endereço para áreas por tipo -> slug, não FK rígida.
- O valor é para resolver autocomplete/geografia sem obrigar existência imediata de todas as áreas.

DDL recomendado:

- Em tabela equivalente de endereço, usar `area_refs jsonb not null default '{}'`.
- Check opcional: `jsonb_typeof(area_refs) = 'object'`.
- Se consultas por tipo específico forem frequentes, usar GIN em `area_refs` ou índices funcionais por chaves específicas; não exigir FK para cada valor.

## 9. Testes e invariantes comprovados no legado

Principais invariantes testados:

- Registro provider cria `SystemArea` e agenda boundary quando permitido.
- Reexecução do mesmo provider result não duplica row; retorna `already_installed`.
- Existing por `slug_id`/identidade é atualizado/mesclado e schedule de boundary ocorre sem recriar.
- `allow_system_write=False` retorna dry run e não cria row.
- `area_type='address'` é skipped e não materializa SystemArea.
- Fonte não GeoKeo também usa o mesmo registration service.
- GeoKeo candidate import deduplica e não cria SystemArea.
- Serviço GeoKeo não expõe materializer direto nem usa `SystemArea.objects.create/update_or_create`.
- `known_existing` evita provider call e materializa/linka tentativa a área existente via write-release posterior.
- Attempt ledger é idempotente por cache key.
- Decisão non-fit/endereços não materializam.
- `none` em realtor_area_types evita provider call.
- Provider decision confirmada pode materializar SystemArea idempotentemente via write release.
- Estados de boundary usam `boundary_status='pending'/'complete'` e `boundary_fetch_attempted` para requeue/closure sem depender apenas de geometry.

## 10. Recomendações DDL consolidadas para Slice 18

1. Criar/portar tabela canônica `geography.system_area` com colunas explícitas do modelo, constraints de enum/check e índices de busca/autocomplete/spatial.
2. Preservar `slug_id` único e `unique(name, area_type, state)`; considerar índice parcial/funcional para `realty_id` e `data->>'provider_geo_id'`.
3. Modelar `area_type` como enum/check. Não permitir `address` como `SystemArea`.
4. Usar self-FK `parent_id on delete set null`; não impor árvore rígida além dos checks básicos.
5. Portar `search text[]` + GIN e função de refresh incluindo ancestrais, nomes de estados e alias county.
6. Se o pacote inclui autocomplete/feed, criar ledgers separados para candidate, attempt, feed_term e feed_result com status/outcome checks, unique cache keys e FKs nullable para `system_area`.
7. Separar canonical truth de operational lineage: `SystemArea` é verdade canônica; candidates/attempts/feed/results são cache/auditoria/ingress.
8. Não expor/copiar payload provider bruto. Usar `jsonb` para lineage restrita e colunas explícitas para chaves consultadas.
9. Boundary: manter geometry e status operacional (`boundary_fetch_attempted`, `data.boundary_status` ou coluna equivalente). Em DDL puro, preferir coluna `boundary_status` se a query operacional for frequente; se ficar em JSONB, criar índice funcional apenas se necessário.
10. Materialização deve acontecer por RPC/função transacional equivalente ao registration/write-release, nunca por inserções livres de candidates.

## 11. Riscos/observações

- O legado mistura campos canônicos e lineage em `data`; portar tudo cegamente para JSONB dificultaria constraints e índices. Recomenda-se promover chaves consultadas para colunas ou ledgers.
- `state` no `SystemArea` é max 2, mas candidate `state_context` aceita sentinel/contextos mais longos. Não reutilizar o mesmo check de `state` em tabelas candidate/feed.
- A migration `0010` depende de `SearchProcessor`; o DDL precisa substituir esse comportamento por função SQL/RPC ou job de refresh.
- `GeoSpatialMixin` no legado usa fields `geography=True`; o pacote PG18 deve decidir e documentar se adotará `geography` ou `geometry` conforme padrão espacial do projeto, mas precisa manter SRID 4326 e GiST.
