# Worker B — Inventário Realtor/docs/backups/source para estratégia PG18 JSONB

[NO_PROVIDER_CALLS]

Escopo executado por inspeção estática local. Não foram feitas chamadas a Realtor.com, APIs externas, banco runtime, Docker ou provedores. O inventário abaixo usa apenas documentação, código, contratos, testes e snapshots/backups já presentes em disco.

[NO_RAW_VALUES_OR_PII]

Este documento não reproduz endereços, nomes, e-mails, telefones, coordenadas específicas, URLs completas, IDs reais de propriedades/áreas/listings, hashes de queries ou payloads brutos. Campos e famílias JSON são descritos por nomes de chaves, padrões semânticos e implicações de modelagem.

## 1. Evidência inspecionada

### 1.1 Prop4You inertia — documentação de arquitetura

Base:

- `/home/marcelo-karval/Backup/Projetos/prop4you/prop4you-inertia/docs/architecture/realtor-enrichment-boundary.md`
- `/home/marcelo-karval/Backup/Projetos/prop4you/prop4you-inertia/docs/architecture/realtor-runtime-coverage-matrix.md`
- `/home/marcelo-karval/Backup/Projetos/prop4you/prop4you-inertia/docs/architecture/realtor-property-enrichment-pre-sourcehub-dto.md`
- `/home/marcelo-karval/Backup/Projetos/prop4you/prop4you-inertia/docs/architecture/realtor-property-comparables-pre-sourcehub-dto.md`
- `/home/marcelo-karval/Backup/Projetos/prop4you/prop4you-inertia/docs/architecture/realtor-market-enrichment-pre-sourcehub-dto.md`
- `/home/marcelo-karval/Backup/Projetos/prop4you/prop4you-inertia/docs/architecture/realtor-area-boundary-pre-sourcehub-dto.md`
- `/home/marcelo-karval/Backup/Projetos/prop4you/prop4you-inertia/docs/architecture/realtor-autocomplete-resolution-boundary.md`
- `/home/marcelo-karval/Backup/Projetos/prop4you/prop4you-inertia/docs/architecture/realtor-property-enrichment-pilot-gap-analysis.md`
- `/home/marcelo-karval/Backup/Projetos/prop4you/prop4you-inertia/docs/architecture/realtor-property-comparables-pilot-gap-analysis.md`
- `/home/marcelo-karval/Backup/Projetos/prop4you/prop4you-inertia/docs/architecture/realtor-market-enrichment-pilot-gap-analysis.md`
- `/home/marcelo-karval/Backup/Projetos/prop4you/prop4you-inertia/docs/architecture/realtor-area-boundary-pilot-gap-analysis.md`

Leitura principal: Realtor é provedor de enriquecimento, não fonte ontológica de existência de propriedade. A aquisição canônica vem primeiro por endereço/Lead Finder/SystemAddress/PropertyLocation/Property; Realtor entra depois como referência e evidência de enriquecimento.

### 1.2 Prop4You inertia — integração/provider client

Base:

- `/home/marcelo-karval/Backup/Projetos/prop4you/prop4you-inertia/backend/src/infrastructure/integrations/realtor/client.py`
- `/home/marcelo-karval/Backup/Projetos/prop4you/prop4you-inertia/backend/src/infrastructure/integrations/realtor/config.py`
- `/home/marcelo-karval/Backup/Projetos/prop4you/prop4you-inertia/backend/src/infrastructure/integrations/realtor/queries.py`
- `/home/marcelo-karval/Backup/Projetos/prop4you/prop4you-inertia/backend/src/infrastructure/integrations/realtor/property.py`
- `/home/marcelo-karval/Backup/Projetos/prop4you/prop4you-inertia/backend/src/infrastructure/integrations/realtor/search.py`
- `/home/marcelo-karval/Backup/Projetos/prop4you/prop4you-inertia/backend/src/infrastructure/integrations/realtor/market.py`
- `/home/marcelo-karval/Backup/Projetos/prop4you/prop4you-inertia/backend/src/infrastructure/integrations/realtor/maps.py`
- `/home/marcelo-karval/Backup/Projetos/prop4you/prop4you-inertia/backend/src/infrastructure/integrations/realtor/geo.py`
- `/home/marcelo-karval/Backup/Projetos/prop4you/prop4you-inertia/backend/src/infrastructure/integrations/realtor/autocomplete.py`
- `/home/marcelo-karval/Backup/Projetos/prop4you/prop4you-inertia/backend/src/infrastructure/integrations/realtor/autocomplete_resolution.py`

Superfícies de client observadas:

- `autocomplete.search(...)`
- `property.fetch_details(...)`
- `property.fetch_history(...)`
- `property.fetch_estimates(...)`
- `property.fetch_spot_offer_evaluation(...)`
- `search.nearby_homes_by_coordinates(...)`
- `search.nearby_homes_for_map(...)`
- `search.recently_sold(...)`
- `search.similar_homes(...)`
- `market.fetch_details(...)`
- `maps.fetch_area_boundary(...)`
- `geo.fetch_boundary(...)`

### 1.3 Prop4You inertia — Matrix DTOs, contratos e testes

Base:

- `backend/src/apps/system/matrix/realtor_property_enrichment_pre_sourcehub_dto.py`
- `backend/src/apps/system/matrix/realtor_property_enrichment_pre_sourcehub_contracts.py`
- `backend/src/apps/system/matrix/tests/test_realtor_property_enrichment_pre_sourcehub_dto.py`
- `backend/src/apps/system/matrix/tests/test_realtor_property_enrichment_pre_sourcehub_contracts.py`
- `backend/src/apps/system/matrix/realtor_property_comparables_pre_sourcehub_dto.py`
- `backend/src/apps/system/matrix/realtor_property_comparables_pre_sourcehub_contracts.py`
- `backend/src/apps/system/matrix/tests/test_realtor_property_comparables_pre_sourcehub_dto.py`
- `backend/src/apps/system/matrix/realtor_market_enrichment_pre_sourcehub_dto.py`
- `backend/src/apps/system/matrix/realtor_market_enrichment_pre_sourcehub_contracts.py`
- `backend/src/apps/system/matrix/tests/test_realtor_market_enrichment_pre_sourcehub_dto.py`
- `backend/src/apps/system/matrix/realtor_area_boundary_pre_sourcehub_dto.py`
- `backend/src/apps/system/matrix/realtor_area_boundary_pre_sourcehub_contracts.py`
- `backend/src/apps/system/matrix/tests/test_realtor_area_boundary_pre_sourcehub_dto.py`

DTO families confirmadas:

- `realtor_property_enrichment_pre_sourcehub_dto.v1`
- `realtor_property_comparables_pre_sourcehub_dto.v1`
- `realtor_market_enrichment_pre_sourcehub_dto.v1`
- `realtor_area_boundary_pre_sourcehub_dto.v1`

### 1.4 full-stack-prop4you — docs, resultados e snapshots/backups

Base:

- `/home/marcelo-karval/Backup/Projetos/prop4you/full-stack-prop4you/docs/api-reference/realtor-api.md`
- `/home/marcelo-karval/Backup/Projetos/prop4you/full-stack-prop4you/docs/analysis/api/realtor-api-schema.md`
- `/home/marcelo-karval/Backup/Projetos/prop4you/full-stack-prop4you/docs/analysis/api/realtor-api-legacy.md`
- `/home/marcelo-karval/Backup/Projetos/prop4you/full-stack-prop4you/docs/analysis/api/realtor-maps-area-types.md`
- `/home/marcelo-karval/Backup/Projetos/prop4you/full-stack-prop4you/docs/analysis/api/realtor-maps-area-payload.md`
- `/home/marcelo-karval/Backup/Projetos/prop4you/full-stack-prop4you/docs/realtor-api-test-results.jsonl`
- `/home/marcelo-karval/Backup/Projetos/prop4you/full-stack-prop4you/docs/realtor-legacy-api-test-results.json`
- `/home/marcelo-karval/Backup/Projetos/prop4you/full-stack-prop4you/backend/src/lib/clients/realtor/tests/snapshots/*.json`
- `/home/marcelo-karval/Backup/Projetos/prop4you/full-stack-prop4you/backend/src/modules/data/integrations/services/realtor_api_client.py`
- `/home/marcelo-karval/Backup/Projetos/prop4you/full-stack-prop4you/backend/src/system/area/services/realtor_area_populator.py`
- `/home/marcelo-karval/Backup/Projetos/prop4you/full-stack-prop4you/backend/src/system/lead_finder/_archive/address/services/realtor_enrichment_service.py`
- `/home/marcelo-karval/Backup/Projetos/prop4you/full-stack-prop4you/backend/src/_archived/system_address_backup_20251108_221012/address/services/realtor_property_service.py`
- `/home/marcelo-karval/Backup/Projetos/prop4you/full-stack-prop4you/backend/src/_archived/system_address_backup_20251108_221012/address/services/realtor_address_populator.py`
- `/home/marcelo-karval/Backup/Projetos/prop4you/full-stack-prop4you/backend/src/_archived/system_address_backup_20251108_221012/address/tasks/realtor_api_tasks.py`

Snapshots locais identificados, sem dump de conteúdo:

- `autocomplete_search.json`
- `connection_test.json`
- `fetch_property_details.json`
- `fetch_property_estimates.json`
- `fetch_property_history.json`
- `fetch_market_details.json`
- `fetch_area_boundary.json`
- `nearby_homes_by_coordinates.json`
- `nearby_homes_for_map.json`
- `recently_sold.json`

## 2. Endpoints/superfícies e famílias funcionais

| Superfície | Transporte observado | Família semântica | Observação de estratégia |
| --- | --- | --- | --- |
| Autocomplete/suggest | REST JSON | `autocomplete_resolution` / address+area suggestion | Entrada de descoberta/resolução. Pode sugerir endereço, cidade, condado, postal code, bairro, rua etc. Não cria propriedade canônica sozinha. |
| Property details | GraphQL persisted query | `property_enrichment` | Detalhes estruturais, listing, mídia, flags, localização provider, anunciantes/contatos e resíduo rico. |
| Property estimates | GraphQL persisted/full query | `property_enrichment` / valuation | Séries ou blocos de AVM/current/historical/forecast; promover apenas estimativa sancionada, preservar séries em JSONB. |
| Property history/tax/permits | GraphQL full query | listing/history/tax/building-permit evidence | Histórico é multivalorado e temporal; não deve substituir identidade canônica. |
| Spot offer evaluation | GraphQL full query | valuation/status evidence | Bloco reduzido para status provider, last-sold evidence e home-estimate source. |
| Nearby homes by coordinates | GraphQL persisted query | `property_comparables` / discovery | Lista de candidatos ancorada por geografia. Evidência de comparáveis, não criação automática de propriedade. |
| Nearby homes for map | GraphQL persisted query | `property_comparables` / map candidates | Candidatos com localização, flags, descrição compacta, foto primária e listing. |
| Recently sold | GraphQL persisted query | `property_comparables` / sold evidence | Candidatos vendidos/recentes; útil para mercado/comparáveis, não truth central. |
| Similar homes | GraphQL persisted query | `property_comparables` | Candidatos relacionados a uma propriedade âncora. |
| Market details | GraphQL persisted query | `market_enrichment` | Métricas territoriais: mediana, DOM, preço por sqft, hotness, temperaturas, ratios. Requer âncora territorial explícita. |
| Area boundary | REST maps ou GraphQL GeoBoundary | `area_boundary` | Geometria GeoJSON/boundary, centro, radius/breakpoints. Deve gravar com âncora de SystemArea. |
| Legacy area populator | serviços Django antigos | geography/source evidence | Confirma pressão para `SystemArea.data`/boundary, mas código é legado/deprecated. |

## 3. Famílias de shape JSON observadas

### 3.1 Envelope/provider context

Padrões de envelope:

- raiz direta ou `data` como raiz normalizada por `_coerce_root(payload)`;
- `endpoint`, `timestamp`, `status` como contexto operacional;
- `operationName`, `variables`, `extensions.persistedQuery` no cliente GraphQL, mas hashes/valores não devem entrar em corpus público;
- `meta` em autocomplete com estatísticas de busca;
- blocos de resultado sob `autocomplete`, `home`, `home_search`, `geo`, `geo_statistics`, `result`, `boundary` conforme endpoint.

Recomendação PG18:

- tabela de ingestão/provider event com colunas: `provider_slug`, `surface_slug`, `captured_at`, `source_ref`, `request_fingerprint`, `response_status`, `payload jsonb`, `payload_schema_version`, `pii_classification`;
- `payload` deve ser JSONB bruto/sanitizado de evidência, não tabela canônica;
- chaves de envelope frequentemente filtradas devem ser colunas ou generated columns: `provider_slug`, `surface_slug`, `source_ref`, `captured_at`, `status`.

### 3.2 Autocomplete/address-area suggestions

Shape families:

- base comum: `_id`, `_score`, `area_type`, `centroid.lat/lon`, `state_code`;
- area suggestions: `city`, `county`, `postal_code`, `neighborhood`, `street`, `university`, `state`, `slug_id`, `geo_id`, `counties[]`, `county_needed_for_uniq`;
- address suggestions: `line`, `full_address[]`, `postal_code`, `mpr_id`, `prop_status[]`, `validation_code[]`;
- normalização inertia separa `RealtorAutocompleteAddressSuggestion` de `RealtorAutocompleteAreaSuggestion`.

Implicações:

- `_id`, `mpr_id`, `geo_id` e `slug_id` são provider references, não chaves canônicas universais;
- `centroid` é útil como hint geográfico, mas não substitui geocodificação/normalização canônica;
- `prop_status[]` em autocomplete é evidência de mercado/provider, não status canônico final.

PG18:

- normalizar `SystemArea` canônico em tabelas/geometry quando há âncora suficiente;
- manter cada suggestion bruto em JSONB de evidência/cache com TTL/audit;
- promover para colunas apenas: `area_type`, `state_code`, `slug_id`, `geo_id/provider_ref`, `centroid geography/geometry`, `city/postal_code` quando a família for territorial;
- para address suggestion, não criar propriedade; usar como entrada de resolução de endereço e referência provider.

### 3.3 Property enrichment/details

Shape families:

- identidade provider/listing: `property_id`, `listing_id`, `permalink`, `href`, `source.*`;
- localização provider: `location.address.*`, `coordinate`, componentes de rua/unidade, cidade/estado/zip;
- descrição física: `description.type/sub_type`, beds, baths, sqft, year, lot, garage, stories, construction/features;
- listing/status: `status`, `list_price`, `price_per_sqft`, `list_date`, `last_sold_date`, `last_sold_price`, `last_price_change_amount`, `flags.*`;
- mídia: `primary_photo`, `photos[]`, `augmented_gallery[]`, tours;
- anunciantes/contatos: `advertisers[]`, `consumer_advertisers[]`, lead attributes, broker/office/agent style blocks;
- resíduo rico: features, rooms, amenities, presentation metadata, legal/showing/open-house/deep listing copy.

Implicações:

- alto risco de PII/comercial em advertisers/consumer_advertisers/phones/emails/names; estes blocos devem ficar classificados e redigidos quando saem do cofre de ingestão;
- dados físicos básicos podem alimentar overlay de detalhes, mas com provenance e anchor explícito;
- provider location não pode reidentificar ou criar propriedade sem `canonical_property_public_id` ou fluxo canônico prévio.

PG18:

- tabelas para fatos canônicos/semicanônicos estáveis: `property_details`, `property_provider_reference`, `property_enrichment_overlay`, `property_media_evidence` se necessário;
- JSONB para blocos ricos e instáveis: gallery completa, feature lists, advertiser/contact blocks, lead attributes, room copy, raw details;
- generated columns/indexes apenas para caminhos usados em filtros/auditoria: provider property ref, listing id, status provider, list price, beds/baths/sqft/year/lot, primary photo presence.

### 3.4 Valuation/estimates/spot offer

Shape families:

- `estimates.current_values[]`, `historical_values[]`, `forecast_values[]`;
- itens com `estimate`, `estimate_high`, `estimate_low`, `date`, `source.*`, `isbest_homevalue`;
- fallback/alternative: `home_estimate.value`, `home_estimate.source`, `avm.amount/high/low/confidence`;
- last-sale evidence: `last_sold_price`, `last_sold_date`.

Implicações:

- há diferença entre valor canônico atual e série provider; misturar ambos em uma coluna única perde auditoria;
- histórico/forecast é naturalmente temporal/multivalorado e muda conforme provider;
- source de valuation precisa ser preservado para explainability.

PG18:

- tabela temporal para snapshots de valuation sancionados quando usados em decisão (`property_valuation_snapshot` com `provider_slug`, `observed_at`, `value`, `low`, `high`, `source`, `confidence`);
- JSONB para série completa provider e resíduo AVM;
- índices B-tree/BRIN em `observed_at`, `provider_slug`, `canonical_property_id`; GIN JSONB apenas para auditorias ad hoc.

### 3.5 Listing/history/tax/permits

Shape families:

- `property_history[]` com evento, datas, preço, price change, price sqft, listing nested, source listing/name;
- `tax_history[]` com assessment/market/tax/year;
- `building_permits_history[]` com projeto, tipo de trabalho/projeto, data efetiva e status.

Implicações:

- são eventos/evidência temporais, não colunas únicas no registro de propriedade;
- tax e permits têm granularidades próprias e podem exigir modelos dedicados se virarem produto;
- por enquanto, funcionam melhor como residue/evidence com uma pequena projeção de last/current status.

PG18:

- JSONB preservar arrays completos;
- materializar tabela de eventos somente para casos de uso explícitos: valuation trend, flip/deal analysis, permit risk, tax history product;
- se materializar, usar `provider_event_id`/hash estável, `event_date`, `event_type`, `amount`, `source_listing_id` e `payload jsonb` para resto.

### 3.6 Property comparables/search candidates

Shape families:

- raízes possíveis: `related_homes.results[]`, `properties[]`, `homes[]`, `home_search.results[]`;
- candidate identity: `property_id`, `listing_id`, `permalink`, `href`, `source.*`;
- candidate location: address line/city/state/postal, coordinate, county;
- candidate facts: status, list price, estimated/current estimates, sold price/date, beds/baths/sqft/lot/year/garage/type;
- flags: new construction, price reduced, new listing, pending/contingent/foreclosure/rent/plan/subdivision etc.;
- media: primary photo, photos, open houses;
- request context: coordinates/radius, address/buffer, query/status/limit.

Implicações:

- comparáveis são candidatos relativos a uma âncora ou consulta; não equivalem a criação de imóveis canônicos;
- request context é parte essencial da semântica: o mesmo candidato em outro raio/status tem meaning diferente;
- precisam preservar ranking/source/ref para explicabilidade.

PG18:

- tabela/evento de `comparable_candidate_evidence` se houver produto de comp analysis: `anchor_property_id`, `candidate_provider_ref`, `surface_slug`, `observed_at`, `rank`, `distance/context`, `payload jsonb`;
- sem contrato downstream dedicado, manter como JSONB evidence-only conforme DTO atual;
- promover para canonical property apenas por fluxo separado de aquisição/deduplicação.

### 3.7 Market enrichment

Shape families:

- `market` ou `geo.geo_statistics` com `housing_market` ou payload achatado;
- medianas: listing price, sold price, rent price, days on market, price per sqft;
- hotness: local/national scores, local/national temperature, badge/rank;
- ratios: DOM/views vs county and US typical property;
- inventory/change em queries legadas.

Implicações:

- fatos são territoriais, não de propriedade;
- raw payload geralmente não carrega identidade territorial forte o bastante sozinho;
- precisa de `area_anchor_ref` explícito e validação contra `SystemArea`.

PG18:

- tabelas para `system_area_market_snapshot` com campos sancionados: median DOM, median listing price, observed_at, provider;
- JSONB em `SystemArea.data.market_enrichment` ou tabela evidence para métricas não sancionadas;
- não inferir/criar SystemArea apenas pelo payload de market.

### 3.8 Area boundary/geography

Shape families:

- REST maps: `result.areas[]`, `result.boundary`;
- GraphQL: `geo.boundary`;
- geometry: GeoJSON `Polygon`/`MultiPolygon`, coordinates;
- ancillary: provider area id, center lat/lon, radius, breakpoints/zoom/width/height;
- area anchor: `area_type`, `slug_id`, `area_name`, `state`, `area_public_id`.

Implicações:

- boundary é fato territorial de alto valor, mas precisa de âncora canônica;
- geometry pode ser grande; JSONB preserva payload, PostGIS guarda geometria consultável;
- breakpoints/tiles são apresentação/provider residue.

PG18:

- `SystemArea.boundary_geom`/PostGIS para geometria consultável;
- `SystemArea.data.area_boundary` ou evidence JSONB para payload bruto, provider ids, center/radius/breakpoints;
- validar incompatibilidade entre anchor e DB truth antes de atualizar geometria.

## 4. Implicações por domínio

### 4.1 Property

- Realtor não deve ser owner de existência de propriedade.
- `mpr_id/property_id/listing_id/permalink` são provider references e replay keys.
- Campos físicos básicos são bons candidatos a colunas/projeções quando ancorados a propriedade canônica existente.
- Listing/media/advertiser blocks devem ser evidence/residue; advertiser/contact é sensível e não deve aparecer em artefatos públicos.
- Enrichment deve escrever por `canonical_property_public_id` ou FK canônica já resolvida, não por address string isolado.

### 4.2 Geography

- Autocomplete e maps pressionam `SystemArea` para cidade/condado/postal/neighborhood/street/university/school/park/state.
- `slug_id`, `geo_id`, `_id` são bons provider refs; `state_code`, `area_type`, `centroid` são úteis para lookup.
- Boundary deve ser PostGIS + JSONB evidence.
- City-to-counties é multivalorado; se virar consulta operacional, separar relação em tabela ao invés de enterrar apenas em JSONB.

### 4.3 Market

- Market enrichment pertence a area/system geography.
- Métricas sancionadas podem virar snapshots temporais tabulares.
- Hotness/ratios/badges ainda parecem provider-specific e devem ficar em JSONB até existir produto/semântica canônica.
- Nunca anexar market payload a propriedade individual só por proximidade/zip implícito.

### 4.4 Comparable/search

- Comparables são evidência relativa a âncora/consulta; não são propriedades canônicas por si.
- O contexto da consulta deve acompanhar os candidatos em JSONB ou colunas de evidence (`anchor`, `radius`, `status`, `surface`, `observed_at`).
- Candidate facts podem alimentar UI/analytics, mas promoção para propriedade exige fluxo de canonical acquisition/dedupe.

## 5. Recomendação table-vs-JSONB para PG18

### 5.1 Manter como tabelas/colunas canônicas ou semicanônicas

- Provider reference: provider slug, surface/list type, provider property ref, provider listing id, provider area id, geo id/slug id.
- Anchor FKs: canonical property, system area, sourcehub ingress/session, observed_at/captured_at.
- Property details sancionados: beds, baths, sqft, lot sqft, year built, garage, property type, normalized provider status quando explicitamente permitido.
- Valuation snapshot sancionado: estimate value/bands/source/date/confidence quando usado operacionalmente.
- Geography: area type, state, slug, centroid, PostGIS `boundary_geom`.
- Market snapshot sancionado: median DOM e median listing price agora; expandir só por ADR/contrato.
- Operational metadata: status, endpoint/surface slug, schema version, payload hash/fingerprint, PII class.

### 5.2 Manter em JSONB evidence/residue

- Payload bruto/sanitizado por endpoint.
- Full autocomplete results, including alternative suggestions.
- Media gallery completa, feature/amenity/room/deep listing details.
- Advertiser/consumer contact/lead blocks, com classificação sensível e redaction em artefatos.
- Estimate series completas, forecast/historical arrays, AVM internals.
- Property history/tax/permit arrays enquanto não houver produto dedicado.
- Comparable candidate arrays enquanto downstream contract não materializar tabela específica.
- Market hotness/ratios/badges não sancionados.
- Boundary ancillary provider presentation fields: breakpoints, radius, raw areas.

### 5.3 Índices e PG18 JSONB strategy

- Usar `jsonb` para evidence immutable/auditável; não transformar cada chave provider em coluna.
- Preferir colunas geradas/extraídas para caminhos consultados frequentemente e estáveis por família.
- GIN `jsonb_path_ops` ou equivalente somente em tabelas de evidence onde busca ad hoc em payload seja requisito real.
- Para séries temporais, priorizar tabelas append-only com `observed_at` e FK; JSONB carrega o resto do item.
- Para PostGIS, nunca consultar geometria apenas via JSONB: extrair para geometry/geography canônica com provenance.
- Separar raw lineage de canonical truth: `sourcehub`/provider evidence guarda payload; domínio canônico guarda projeções aprovadas.

## 6. Gates para consolidação Thor/ADR

1. Congelar quatro DTO families Realtor como unidades separadas: property enrichment, property comparables, market enrichment, area boundary.
2. Reafirmar boundary: Realtor enriches; Lead Finder/SystemAddress/SystemArea governam truth.
3. Definir PII classes por subárvore JSON antes de qualquer corpus fixture público:
   - alto risco: advertisers, consumer_advertisers, phones, emails, names, full address values, photos URLs completas;
   - médio: exact coordinates, provider IDs/listing IDs/permalinks, raw query strings;
   - baixo: field names, enum categories, boolean flags, numeric schema types sem valores.
4. Criar fixtures sintéticas/schema-only para documentação e testes de contrato; não usar snapshots reais com valores.
5. Abrir materialização de comparables somente quando houver contrato downstream dedicado; até lá evidence-only.
6. Expandir market materialization por campos sancionados em ADR, não por simples disponibilidade provider.

## 7. Resumo executivo

O corpus Realtor é amplo, heterogêneo e fortemente provider-specific. A melhor estratégia PG18 é híbrida: tabelas para âncoras, provenance, geometrias, snapshots e projeções sancionadas; JSONB para raw/residue, séries, arrays e blocos de alto churn. Realtor não deve virar fonte de verdade para criação de propriedade; sua força está em enriquecimento de propriedade já canônica, inteligência territorial, boundary, market snapshots e comparables evidence.
