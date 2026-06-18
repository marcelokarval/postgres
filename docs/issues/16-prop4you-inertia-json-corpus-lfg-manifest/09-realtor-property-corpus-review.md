# 09 — Revisão Realtor/property/market JSON corpus para LFG

Status: concluído
Worker: B
Source root revisado: `/home/marcelo-karval/Backup/Projetos/prop4you/prop4you-inertia`
Manifests usados:
- `docs/corpus/prop4you/lfg/prop4you-inertia-json-manifest.v1.jsonl`
- `docs/corpus/prop4you/lfg/prop4you-inertia-lfg-corpus-candidates.v1.jsonl`

Política de privacidade: nenhum valor bruto de JSON foi copiado. Esta revisão usa apenas nomes de chaves, tipos, contagens, famílias de paths e decisões de modelagem.

## 1. Escopo e contagens

Resumo global já presente no inventário:
- JSON recursivos totais: 13.160
- candidatos LFG: 3.545
- tag `realtor`: 28 no manifesto completo; 27 no manifesto de candidatos LFG
- tag `reiq`: 3.094 no manifesto completo; 3.087 nos candidatos LFG
- tag `sourcehub`: 58 no manifesto completo; 36 nos candidatos LFG

Recortes deste worker:
- Realtor explícito: 27 candidatos LFG, todos `object`, todos em fixtures/provas.
- Realtor endpoint reports: 17 arquivos em `_projeto-antigo/backend/.reports/realtor_api_endpoints_test/`.
- Realtor client snapshots: 10 arquivos em `_projeto-antigo/backend/src/lib/clients/realtor/tests/snapshots/`.
- REIQ property/geography/valuation: 2.812 objetos candidatos com chaves de propriedade/geografia/valor.
- Property enrichment / My Property proofs: 2 artefatos úteis de shape em `frontends/.tmp/my-property-rich-testbase-enrichment*`; mais 3 artefatos de UI/plano relacionados, mas não fonte canônica de corpus.

## 2. Famílias de path relevantes

### Realtor explícito

1. `_projeto-antigo/backend/.reports/realtor_api_endpoints_test/` — 17 objetos.
   - Shape comum: wrapper de endpoint com chaves `endpoint`, `timestamp`, `parameters`, `status`, `error`, `data`, `data_summary`.
   - Uso: bom para entender envelopes de ingestão/prova, mas `parameters` e `data` devem entrar como evidência sanitizada/lineage, não como verdade canônica.

2. `_projeto-antigo/backend/src/lib/clients/realtor/tests/snapshots/` — 10 objetos.
   - Shape comum: snapshot mais direto por operação, sem wrapper uniforme de relatório.
   - Uso: melhor corpus para normalizadores específicos de Realtor, porque expõe o payload esperado por método (`autocomplete`, boundary, market, details, estimates, history, nearby/sold).

3. Código atual de integração, fora do JSON corpus mas importante para envelopes:
   - `backend/src/infrastructure/integrations/realtor/property.py`
   - `backend/src/infrastructure/integrations/realtor/market.py`
   - `backend/src/infrastructure/integrations/realtor/geo.py`
   - `backend/src/infrastructure/integrations/realtor/maps.py`
   - `backend/src/apps/public/address_entry/queries.py`

### REIQ property/geography/valuation

Contagem do recorte por família:
- 1.400 objetos em `_projeto-antigo/backend/_archived/matrix/registry/reiq/...`
- 1.400 objetos em `_projeto-antigo/backend/src/lib/matrix_engine/registry/...`
- 12 objetos em provas/fixtures recentes (`.tmp/...` e `backend/src/apps/system/matrix/registry/...`)

Estados/list types no recorte:
- `tx`: 1.600 objetos
- `fl`: 1.201 objetos
- list types principais, com 200 objetos cada na maioria: `appt_of_sub_trustee/tx`, `divorce/fl`, `divorce/tx`, `eviction/fl`, `eviction/tx`, `heirship/tx`, `loan_modification/tx`, `pre_foreclosure/fl`, `pre_foreclosure/tx`, `probates/fl`, `probates/tx`, `tax_sale/fl`, `tax_sale/tx`; `loan_modification/fl` aparece com 201 por incluir prova extra.

## 3. Shapes de evidência observados

### 3.1 Realtor autocomplete

Shapes observados:
- Wrapper report: `data[]` com objetos de sugestão.
- Snapshot direto: `results[]` com objetos de sugestão.

Chaves/tipos recorrentes:
- identificação/escopo: `_id:string`, `_score:number`, `area_type:string`, `geo_id:string`, `slug_id:string`, `mpr_id:string`
- endereço/geografia: `line:string`, `city:string`, `state_code:string`, `postal_code:string`, `country:string`, `centroid.object`, `centroid.lat:number`, `centroid.lon:number`
- cidade/ZIP: `counties[]`, `counties[].fips:string`, `counties[].name:string`, `counties[].state_code:string`, `county_needed_for_uniq:boolean`
- property hints: `full_address[]:string`, `prop_status[]:string`, `validation_code[]:string`

Uso recomendado:
- `realtor_evidence.autocomplete`: guardar payload bruto sanitizado em JSONB de evidência.
- Projetar somente seleção e matching: `provider_ref`, `suggestion_kind`, `full_address_hash`, `city`, `state_code`, `postal_code`, `county_fips`, `lat`, `lng`, `matched_at`.
- Não usar label/endereço bruto em logs ou docs; no banco, tratar como dado sensível de propriedade/contato.

### 3.2 Realtor property details

Shapes observados:
- Wrapper report: `data` com detalhes amplos.
- Snapshot direto: `details` com o mesmo tipo de bloco.
- Código atual extrai root via `data.home.property`, `data.property` ou payload raiz.

Chaves/tipos de alta utilidade:
- descrição física: `description.object`, `description.beds:integer`, `description.baths_*`, `description.sqft:integer`, `description.lot_sqft`, `description.year_built`, `description.type:string`, `description.sub_type`
- preço/status: `list_price:integer`, `price`, `status:string`, `last_sold_date:string`, `last_sold_price`
- localização: `location.object`, `location.address.object`, `location.county.object`
- mídia/listing: `photos[]`, `primary_photo.object`, `permalink:string`, `href:string`, `listing_id:string`
- agentes/anunciantes: `advertisers[]`, `consumer_advertisers[]`, `buyers[]` com e-mail/telefone/nome em subárvores; estas são PII/contato e devem ficar fora de projeções públicas.

Uso recomendado:
- `property_evidence.provider_payload_cache` ou envelope `realtor_evidence.property_details` para payload bruto sanitizado/lineage.
- Projetar para `property`/`property_details` apenas atributos físicos e públicos: tipo, quartos, banheiros, sqft, ano, lote, status, listing URL/ref, foto-count/primary-photo-ref se necessário.
- Não projetar subárvores de advertisers/buyers/office/phones/emails para o grafo canônico LFG; manter em JSONB restrito, ou descartar se não houver caso de uso legal/consentido.

### 3.3 Realtor estimates/valuation

Shapes observados:
- `estimates.current_values[]` com `date:string`, `estimate:integer`, `estimate_high:integer`, `estimate_low:integer`, `isbest_homevalue:boolean`, `source.object`.
- `estimates.forecast_values[]` e `estimates.historical_values[]` como séries.
- `avm` pode ser `null`.
- Spot offer: `home_estimate.object`, `home_estimate.value:integer`, `home_estimate.source:string`, `last_sold_date:string`, `last_sold_price:null|number`, `status:string`.

Uso recomendado:
- Criar eventos/snapshots em `property_valuation` por data/fonte quando o valor for estável e útil para busca/sort.
- Manter séries forecast/historical completas em JSONB de evidência, porque granularidade e fonte variam.
- Projetar campos: `estimated_value`, `valuation_date`, `data_source`, `confidence_score`, `estimate_low`, `estimate_high` opcionalmente em uma extensão de valuation se a DDL aceitar intervalo.

### 3.4 Realtor property history/tax/building permits

Shapes observados:
- `property_history[]` com `date`, `event_name`, `price`, `price_change`, `price_sqft`, `source_listing_id`, `source_name`, e `listing.object`.
- `tax_history[]` com `year`, `tax`, `assessment.object`, `market.object`; dentro de `assessment`/`market`: `building`, `land`, `total`.
- `building_permits_history[]` com `permit_effective_date`, `permit_project_type_*`, `permit_status`, `permit_type_of_work`, `project_name`.

Uso recomendado:
- Projetar eventos de alta utilidade: venda/listagem/preço/tax assessment por ano.
- Manter permit history e listing history completo em JSONB até existir bounded context para histórico imobiliário.
- Separar `tax_assessment`/`market_assessment` de AVM: são evidências distintas.

### 3.5 Realtor nearby/similar/recently sold

Shapes observados:
- `properties[]`, `homes[]` ou `related_homes.results[]`.
- Cada item combina `property_id`, `listing_id`, `status`, `list_price`, `description.object`, `location.address.object`, `location.county.object`, fotos, flags e estimates.
- Arrays observados em amostras: 3, 10, 19 ou 25 itens conforme endpoint/snapshot.

Uso recomendado:
- Usar como comparáveis/market context, não como verdade canônica do imóvel-alvo.
- Envelope sugerido: `realtor_evidence.comparables` com `subject_property_ref`, `search_radius`, `search_center_hash`, `result_count`, `retrieved_at`, `payload_jsonb`.
- Projetar apenas agregados ou referências: contagem, mediana local calculada, ids de comparáveis, status/preço se for necessário para ranking.

### 3.6 Realtor market/geography/boundary

Market shape:
- `market` ou `market.housing_market` com chaves `hot_market_badge`, `hot_market_rank`, `local_hotness_score`, `local_temperature`, `median_days_on_market`, `median_listing_price`, `median_price_per_sqft`, `median_rent_price`, `median_sold_price`, `national_hotness_score`, `national_temperature`, e razões de DOM/LD views.

Boundary shape:
- `boundary.result.areas[]` ou `data.result.areas[]`.
- `boundary.result.boundary.type:string` e `boundary.result.boundary.coordinates:array`.
- `areas[].center.object`, `areas[].id:string`, `areas[].name:string`, `areas[].radius:number`, `areas[].breakpoints[]`.

Uso recomendado:
- Market metrics: bons candidatos para projeção por ZIP/geography/time bucket.
- Boundary GeoJSON: manter em JSONB + geometria derivada PostGIS se/ quando for usada em busca espacial. O array bruto de coordenadas não deve ser expandido em colunas comuns.
- Envelope: `geography_evidence.realtor_boundary` com `geo_ref`, `area_type`, `slug_id`, `retrieved_at`, `geometry_jsonb`, `provider_status`.

### 3.7 REIQ property/geography/valuation corpus

Chaves top-level mais frequentes no recorte de 2.812 objetos:
- 2.812: `date_added`, `internal_id`, `lead_type`, `property_city`, `property_id`, `property_state`, `property_zip_code`
- 2.411: `assessed_value`, `county`
- 2.010: `date_filed`
- 1.809: `owner_address`, `owner_first_name`, `owner_last_name`, `ownership`, `property_address`
- 1.408: `owner_city`, `owner_state`, `owner_zip_code`
- 1.404: `case_number`
- 1.207: `bath`, `bed`, `garage`, `pool`, `sq_ft`, `yr_bt`
- 1.007: `appraised_value`, `current_month`, `current_year`, `equity`, `estimated_equity`, `estimated_unpaid_balance`, `historical_interest_rate`, `legal_description`, `loan_origination_month`, `loan_origination_year`, `mortgagee_bank_name`, `mortgagor_first_name`, `mortgagor_last_name`, `original_loan_amount`
- 1.003: `property_street`
- 802: `city`, `state`, `zip_code`, `auction_date_time`, `instrument_no`

Uso recomendado:
- REIQ é fonte de sinais/situações e atributos de lead; não deve sobrescrever verdade canônica de proprietário/imóvel sem lineage.
- Projetar: `provider_record_ref/internal_id`, `lead_type`, `state`, `county`, `property_id`, componentes de endereço da propriedade, datas legais relevantes, valores financeiros normalizados e situação/list type.
- Manter JSONB: campos legais específicos por list type, nomes/endereços de pessoas, comentários, texto legal, detalhes de instrumento, campos raros e campos com semântica estadual divergente.

### 3.8 Property enrichment / My Property overlays

Shapes observados nos proofs:
- `workspace-link-proof`: `address`, `details.object`, `history_snapshots:integer`, `known_gaps.object`, `overlay.object`, `public_id`, `valuation.object`, `workspace.object`.
- `details`: `exists:boolean`, `property_type:string`, `beds:integer`, `baths:string`, `sqft:integer`, `year_built:integer`, `listing_status:string`, `listing_url:string`, `photo_count:integer`.
- `overlay`: `exists:boolean`, `provider:string`, `providerPropertyRef:string`, `listingStatus:string`.
- `valuation`: `exists:boolean`, `estimated_value:string`, `source:string`.
- `workspace`: contadores e `saved_public_ids[]`.

Modelo atual relevante:
- `PropertyEnrichmentOverlay.latest_dto` é JSONField e o comentário do código marca explicitamente como cache DTO de provedor/manual, não fonte de verdade.
- `PropertyDetails.photos` e `PropertyDetails.schools` também são JSONField.
- `PropertyValuation` já cobre valores estimado/assessed/appraised, saldo/loan/equity e fonte/data.

Uso recomendado:
- `latest_dto` deve virar envelope de cache/evidência, não schema canônico primário.
- Campos físicos/financeiros estáveis devem sair do DTO para tabelas/projeções canônicas (`property_details`, `property_valuation`, localidade/endereço).
- `workspace` é contexto de usuário/salvamento, não corpus de evidência imobiliária; manter fora de `realtor_evidence`.

## 4. Como usar nos envelopes `realtor_evidence` e `property`

Envelope mínimo recomendado para Realtor:

- `provider_slug`: constante lógica do provedor
- `provider_operation`: autocomplete, property_details, property_estimates, property_history, nearby_homes, similar_homes, recently_sold, market_details, area_boundary
- `provider_ref`: ref externa quando houver, por exemplo property/mpr/geo/listing ref
- `subject_property_id`: FK/opcional para o imóvel canônico
- `source_path_family`: família do corpus/manifests usada como prova
- `retrieved_at` / `captured_at`
- `request_shape`: chaves de parâmetros, sem valores sensíveis em logs
- `payload_shape_version`: versão interna da normalização
- `payload_jsonb`: payload sanitizado/guardado com acesso restrito
- `shape_summary`: keys/types/counts opcionais para auditoria sem PII
- `normalization_status`: parsed, partially_parsed, rejected, stale
- `projection_refs`: IDs das projeções geradas (`property_details`, `property_valuation`, `market_snapshot`, etc.)

Envelope `property`/LFG recomendado:

- Identidade canônica: public_id, provider refs associados, endereço normalizado, geografia normalizada.
- Detalhes físicos: tipo, quartos, banheiros, sqft, ano, lote, garagem, pool, stories.
- Valuation: estimado/assessed/appraised, faixa opcional, fonte, data, confiança.
- Listing enrichment: status, listing_id/provider ref, price, permalink/listing URL, fetched_at/ttl.
- Situações: eventos/list type/sinais vindos de REIQ ou outros provedores, sempre com lineage.
- Evidence links: nunca perder ponte para raw/sanitized JSONB, hash, provider operation e captured_at.

## 5. Projection candidates vs keep_jsonb

### Projetar em colunas/tabelas

Alta prioridade:
- refs: provider_slug, provider_property_ref, listing_id, geo_ref/slug_id
- endereço normalizado: street/line, city, state_code, postal_code, county, county_fips, lat/lng quando disponível
- atributos físicos: property_type, bedrooms, bathrooms, total_sqft, year_built, lot_size_sqft, garage_spaces, pool flag
- listing: status, list_price, listing_url/permalink, days_on_market quando disponível, fetched_at, ttl_expires_at
- valuation: estimated_value, assessed_value, appraised_value, mortgage_balance/estimated_unpaid_balance, original_loan_amount, equity_amount/equity_percentage, valuation_date, data_source
- market snapshot por geografia/período: median_listing_price, median_sold_price, median_rent_price, median_price_per_sqft, median_days_on_market, local/national hotness score, local/national temperature
- legal/situation basics REIQ: lead_type, state, county, case_number/document/instrument refs, date_filed, auction_date_time, situation/list type

Média prioridade:
- tax history anual: year, tax, assessment_total, market_total
- price/listing history: event date, event name/status, price, price change, source listing ref
- comparables summary: result_count, median/min/max preço, subject geo/radius hash, retrieved_at

### Manter em JSONB restrito

- payload bruto de Realtor/REIQ com PII ou contato
- advertisers, buyers, office, phones, emails, lead_email, names de agentes/contatos
- fotos completas e URLs de mídia quando não forem necessárias para display público
- GeoJSON coordinates brutos de boundary; derivar PostGIS geometry separadamente quando necessário
- forecast/historical AVM detalhado por fonte até haver modelo temporal completo
- building permits completos
- comments, legal_description extensivo, textos de instrumento, campos raros por list type/estado
- `latest_dto` de overlay enquanto cache de provedor/manual
- `request parameters` completos; se necessário guardar, mascarar ou hashear valores sensíveis

## 6. Riscos e observações

- Realtor reports incluem dados de contato em subárvores de anunciantes/compradores/escritórios; não devem ir para docs, logs nem projeções públicas.
- REIQ contém nomes/endereços de proprietários e partes legais; para LFG é corpus valioso, mas exige envelope de lineage e política de acesso.
- As famílias `_archived` e `matrix_engine` duplicam muitos registros REIQ; deduplicar por provider/list/state/internal_id/hash antes de criar seed canônico.
- `market_details` e `boundary` são geografia/mercado, não propriedade; devem ter envelopes separados ou subtipos de evidence.
- My Property proof confirma que o overlay atual é cache/apresentação; não promover `latest_dto` inteiro a contrato canônico.

## 7. Evidência de execução

Comandos/scripts locais usados somente para contagens e shapes, sem imprimir valores brutos:
- leitura dos manifests JSONL para contagens por tag/classificação/família
- recorte Realtor por `context_tags` e paths contendo `realtor`
- recorte REIQ por chaves top-level de propriedade/geografia/valuation
- introspecção de tipos/keys dos JSONs selecionados com depth limitado
- leitura de código fonte dos normalizadores/modelos para confirmar campos e semântica

Resultado: corpus Realtor/property/market/geography revisado e recomendações de envelope/projeção documentadas.
