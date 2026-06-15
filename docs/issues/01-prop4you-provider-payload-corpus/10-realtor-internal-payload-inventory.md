# Worker C — Realtor.com/property enrichment + internal payload inventory

[NO_PROVIDER_CALLS]

Escopo executado: inspeção estática de código, testes, contratos e referências a fixtures locais no backend Prop4You. Não foram feitas chamadas a Realtor.com, InstantStreetView, skip-trace providers, Docker, banco runtime ou sistemas externos.

[NO_PII_DUMP]

Este inventário descreve famílias de caminhos JSON, formatos contratuais e implicações canônicas. Valores reais de endereços, nomes, e-mails, telefones, URLs completas, IDs públicos de usuários/propriedades e outros dados sensíveis foram omitidos ou generalizados.

## Evidência inspecionada

Backend read-only analisado em:

- `/home/marcelo-karval/Backup/Projetos/prop4you/prop4you-inertia/backend/src`

Arquivos principais:

- `apps/system/matrix/realtor_property_enrichment_pre_sourcehub_dto.py`
- `apps/system/matrix/realtor_property_enrichment_pre_sourcehub_contracts.py`
- `apps/system/matrix/tests/test_realtor_property_enrichment_pre_sourcehub_dto.py`
- `apps/system/matrix/tests/test_realtor_property_enrichment_pre_sourcehub_contracts.py`
- `apps/public/address_entry/queries.py`
- `apps/public/address_entry/contracts.py`
- `apps/public/address_entry/tests/test_queries.py`
- `infrastructure/integrations/realtor/autocomplete_resolution.py`
- `infrastructure/integrations/tests/test_realtor_autocomplete_resolution.py`
- `apps/system/sourcehub/producer.py`
- `apps/system/sourcehub/contracts.py`
- `domains/data/tests/test_realtor_sourcehub_producer.py`
- `apps/system/lead_finder/tests/test_realtor_property_enrichment_materialization.py`
- `apps/public/my_property/service.py`
- `apps/public/my_property/actions.py`
- `domains/data/services/skip_trace/validation.py`
- `domains/real_estate/services/address_entry_normalization_service.py`
- `domains/real_estate/tests/test_manual_property_coordinate_backfill_service.py`

Fixtures locais referenciadas por testes, sem dump de conteúdo:

- `_projeto-antigo/backend/.reports/realtor_api_endpoints_test/fetch_property_details.json`
- `_projeto-antigo/backend/.reports/realtor_api_endpoints_test/fetch_property_estimates.json`
- `_projeto-antigo/backend/.reports/realtor_api_endpoints_test/fetch_property_history.json`
- `_projeto-antigo/backend/.reports/realtor_api_endpoints_test/fetch_spot_offer_evaluation.json`
- `_projeto-antigo/backend/.reports/realtor_api_endpoints_test/fetch_similar_homes.json`
- `_projeto-antigo/backend/.reports/realtor_api_endpoints_test/fetch_nearby_homes.json`
- `_projeto-antigo/backend/.reports/realtor_api_endpoints_test/fetch_recently_sold.json`

[REALTOR_PATH_INVENTORY]

## 1. Realtor property enrichment — famílias de caminhos JSON

A camada Matrix compila payloads Realtor para `realtor_property_enrichment_pre_sourcehub_dto.v1`; SourceHub consome esse DTO para publicar handoff canônico/semicanônico.

### 1.1 Envelope e raiz

A raiz é normalizada por `_coerce_root(payload)`:

- Se `payload.data` é objeto: raiz = `payload.data`
- Caso contrário: raiz = `payload`

Caminhos de envelope preservados em `operator_context`:

- `endpoint`
- `timestamp`
- `status`

Caminhos usados para referência primária:

- `data.property_id` ou `property_id`
- `data.permalink` ou `permalink`
- `raw_envelope.external_reference_id` como fallback SourceHub

### 1.2 Identidade/endereço da propriedade

Caminhos Realtor para seed de localização/ref de propriedade:

- `data.location.address.line`
- `data.location.address.city`
- `data.location.address.state_code`
- `data.location.address.state`
- `data.location.address.postal_code`
- `data.property_id`

Destino Matrix:

- `property_seed_ref.street_address`
- `property_seed_ref.city`
- `property_seed_ref.state`
- `property_seed_ref.zip_code`
- `property_seed_ref.normalized_address`
- `property_seed_ref.address_hash`
- `property_seed_ref.provider_property_ref`

Destino SourceHub canonical DTO:

- `canonical_dto.property.location.street_address`
- `canonical_dto.property.location.city`
- `canonical_dto.property.location.state`
- `canonical_dto.property.location.zip_code`
- `canonical_dto.property.location.normalized_address`
- `canonical_dto.property.location.address_hash`

Fallback SourceHub quando payload de estimates/history não traz endereço:

- `canonical_property_public_id` é usado para buscar a propriedade canônica existente via `PropertyLeadFinder.objects.select_related("location")` e preencher `canonical_dto.property.location` a partir da localização canônica.

### 1.3 Referências do provider/listing/source

Caminhos Realtor:

- `data.property_id`
- `data.permalink`
- `data.href`
- `data.source.id`
- `data.source.name`
- `data.source.type`
- `data.source.listing_id`
- `data.property_history[].listing.listing_id`
- `data.property_history[].source_listing_id`
- `data.property_history[].source_name`

Destino:

- `provider_reference.provider_property_ref`
- `provider_reference.provider_listing_id`
- `provider_reference.provider_permalink`
- `provider_reference.provider_url`
- `provider_reference.provider_source_id`
- `provider_reference.provider_source_name`
- `provider_reference.provider_source_type`

Observação: `provider_reference` preserva identidade do provider; não deve virar identidade canônica de propriedade/owner por si só.

### 1.4 Beds/baths/sqft/year/lot/property type/garage

Caminhos Realtor em property details:

- `data.description.type`
- `data.description.sub_type`
- `data.description.beds`
- `data.description.baths_full`
- `data.description.baths`
- `data.description.sqft`
- `data.description.year_built`
- `data.description.lot_sqft`
- `data.description.garage`
- `data.list_price` como `estimated_value` no seed de detalhes

Destino Matrix:

- `property_details_seed.property_type`
- `property_details_seed.bedrooms`
- `property_details_seed.bathrooms`
- `property_details_seed.square_feet`
- `property_details_seed.year_built`
- `property_details_seed.lot_size_sqft`
- `property_details_seed.estimated_value`
- `property_details_seed.garage`

Destino SourceHub canonical DTO:

- `canonical_dto.property.details.property_type`
- `canonical_dto.property.details.bedrooms`
- `canonical_dto.property.details.bathrooms`
- `canonical_dto.property.details.square_feet`
- `canonical_dto.property.details.year_built`
- `canonical_dto.property.details.garage`
- `canonical_dto.valuation_financial.estimated_value` quando derivado de `property_details_seed.estimated_value`

Nota: `lot_size_sqft` existe no seed e no contrato de detalhes públicos, mas o runtime SourceHub/Lead Finder visto para Realtor materializa principalmente building/details + valuation; checar materialização explícita de land/lot como evolução separada.

### 1.5 Valuation/estimates/spot offer

Caminhos Realtor de valuation:

- `data.estimates.current_values[]`
- `data.estimates.current_values[].isbest_homevalue`
- `data.estimates.current_values[].estimate`
- `data.estimates.current_values[].estimate_high`
- `data.estimates.current_values[].estimate_low`
- `data.estimates.current_values[].date`
- `data.estimates.current_values[].source.type`
- `data.estimates.current_values[].source.name`
- `data.estimates.historical_values[]`
- `data.estimates.forecast_values[]`
- `data.home_estimate.value`
- `data.home_estimate.source`
- `data.last_sold_price`
- `data.last_sold_date`

Destino canônico reduzido:

- `valuation_financial_seed.estimated_value`
- `canonical_dto.valuation_financial.estimated_value`

Destino residue/evidência preservada:

- `residue.valuation_estimate_series.current_values[]`
- `residue.valuation_estimate_series.historical_values[]`
- `residue.valuation_estimate_series.forecast_values[]`
- `residue.spot_offer_evaluation.last_sold_price`
- `residue.spot_offer_evaluation.last_sold_date`
- `residue.spot_offer_evaluation.home_estimate_source`

Regra observada: `_pick_best_current_estimate` prefere item em `current_values[]` com `isbest_homevalue=true`; se ausente, usa o primeiro item parseável. `home_estimate.value` é fallback.

### 1.6 Listing/history/status

Caminhos Realtor:

- `data.status`
- `data.list_price`
- `data.price_per_sqft`
- `data.source.last_update_date`
- `data.source.listing_id`
- `data.source.raw.status`
- `data.source.name`
- `data.source.type`
- `data.property_history[]`
- `data.property_history[].event_name`
- `data.property_history[].listing.status`
- `data.property_history[].listing.list_price`
- `data.property_history[].listing.last_update_date`
- `data.property_history[].price_sqft`
- `data.property_history[].source_listing_id`
- `data.property_history[].source_name`

Destinos:

- `listing_evidence.listing_status`
- `listing_evidence.list_price`
- `listing_evidence.price_per_sqft`
- `listing_evidence.last_update_date`
- `listing_evidence.source_listing_id`
- `listing_evidence.source_status`
- `market_status_evidence.property_status`
- `market_status_evidence.source_status`
- `market_status_evidence.source_name`
- `market_status_evidence.source_type`
- `residue.property_history[]`
- `residue.tax_history[]`
- `residue.building_permits_history[]`

### 1.7 Media/photo/gallery

Caminhos Realtor:

- `data.primary_photo.href`
- `data.photos[]`
- `data.photos[].href`
- `data.photos[].type`
- `data.photos[].tags[]`
- `data.photos[].tags[].label`
- `data.augmented_gallery[]`
- `data.augmented_gallery[].key`
- `data.augmented_gallery[].category`
- `data.augmented_gallery[].photoCount`

Destino:

- `media_evidence.primary_photo_href`
- `media_evidence.photo_count`
- `media_evidence.photos[].href`
- `media_evidence.photos[].type`
- `media_evidence.photos[].tags[]`
- `media_evidence.gallery_sections[].key`
- `media_evidence.gallery_sections[].category`
- `media_evidence.gallery_sections[].photo_count`

Limites/redução observados:

- `photos[]` é truncado para até 12 itens.
- `augmented_gallery[]` é truncado para até 6 seções.
- Item de foto sem `href` é ignorado.

### 1.8 Address autocomplete Realtor

Normalizador `normalize_realtor_address_suggestion(raw)` aceita caminhos:

- `_id`
- `mpr_id`
- `full_address[]`
- `line`
- `city`
- `postal_code`
- `zip`
- `state_code`
- `state`
- `country`
- `centroid.lat`
- `centroid.lon`
- `prop_status[]`
- `validation_code[]`

Contrato público de autocomplete (`AddressEntrySuggestionContract`):

- `suggestions[].label`
- `suggestions[].value` no formato opaco `realtor:<provider_ref>`
- `suggestions[].kind` = `property` ou `mailing`
- `suggestions[].parsedAddress.fullAddress`
- `suggestions[].parsedAddress.street`
- `suggestions[].parsedAddress.line2`
- `suggestions[].parsedAddress.city`
- `suggestions[].parsedAddress.state`
- `suggestions[].parsedAddress.zipCode`
- `suggestions[].parsedAddress.county`
- `suggestions[].parsedAddress.lat`
- `suggestions[].parsedAddress.lng`

Regra de superfície pública: testes garantem que `source`/`provider` não aparecem no payload público de sugestão ou detalhes.

### 1.9 Address autocomplete de área Realtor

Normalizador `normalize_realtor_area_suggestion(raw, expected_area_type=...)` aceita:

- `_id`
- `area_type`
- campo nome por tipo: `city`, `county`, `postal_code` conforme `expected_area_type`
- `state_code`
- `state`
- `slug_id`
- `geo_id`
- `country`
- `centroid.lat`
- `centroid.lon`
- `counties[].name`
- `counties[].fips`
- `counties[].state_code`
- `county_needed_for_uniq`

Destino interno normalizado:

- `provider_ref`
- `area_type`
- `name`
- `state_code`
- `slug_id`
- `country`
- `lat`
- `lng`
- `geo_id`
- `counties[]`
- `county_needed_for_uniq`

### 1.10 Public property-details prefill após seleção de endereço

Endpoint lógico:

- `GET address_entry/api/property-details/?selection=...&address=...`

Caminhos aceitos pela normalização pública em `apps/public/address_entry/queries.py`:

Raiz GraphQL/property details:

- `data.home.property` se existir
- senão `data.home`
- senão `data.property`
- senão payload raiz

Detalhes:

- `description.sub_type`
- `description.type`
- `description.property_type`
- `prop_type`
- `property_type`
- `description.beds`
- `beds`
- `description.baths`
- `baths`
- `description.sqft`
- `description.sqft_calc`
- `sqft`
- `building_size.size`
- `description.year_built`
- `year_built`
- `description.lot_sqft`
- `lot.size`
- `lot_sqft`
- `list_price`
- `price`
- `estimate.estimate.amount`
- `estimates.current_values.amount` (observação: esta forma só funciona se `current_values` for mapping; se array, entra melhor pela rota Matrix acima)

Contrato público de detalhes:

- `details.propertyType`
- `details.bedrooms`
- `details.bathrooms`
- `details.squareFeet`
- `details.yearBuilt`
- `details.lotSizeSqft`
- `details.estimatedValue`

Fallback de busca exata por endereço:

- se `fetch_property_details(provider_ref)` não traz detalhes, `fetch_nearby_homes_for_map(address_query, buffer=0.1)` pode ser usado;
- o match usa `results[].property_id` ou igualdade conservadora de endereço em `results[].location.address.*`.

## 2. SourceHub property detail normalization

Normalizadores centrais:

- `build_canonical_property_details_seed(...)`
- `normalize_canonical_property_type(...)`
- `serialize_public_property_details(...)`
- `build_canonical_valuation_financial_seed(...)`

Famílias canônicas aceitas:

- `property_type`
- `bedrooms`
- `bathrooms`
- `square_feet`
- `year_built`
- `lot_size_sqft`
- `estimated_value`
- `garage`
- `pool`
- `subdivision`
- `legal_description`

Aliases de tipo relevantes:

- single family / single-family / SFR -> `single_family`
- multi family / MFR -> `multi_family`
- condo / condominium -> `condo`
- townhome -> `townhouse`
- manufactured/mobile -> `manufactured`
- vacant/residential/lot land -> `land`
- mixed use -> `mixed_use`
- desconhecido -> `other`

Public serialization converte snake_case para camelCase apenas na borda pública; SourceHub/Lead Finder preservam snake_case nos DTOs internos.

[INTERNAL_PAYLOADS]

## 3. Payloads internos/manuais/product-originated

### 3.1 Produto `my_property` — criação manual de propriedade

Fluxo:

- `interfaces/web/real_estate/views.py` chama `create_my_property_action(user, data)`.
- `apps/public/my_property/service.py::PropertyService.create_property` valida e normaliza o payload.
- SourceHub ingressa como `prop4you_product` via `produce_product_origin_address_seed(...)`.
- Lead Finder materializa via `materialize_product_origin_address_seed(...)`.

Payload de entrada do produto — famílias observadas:

- `title`
- `address`
- `unit` / `address_line_2` / `line2`
- `city`
- `state`
- `zip_code`
- `county`
- `latitude`
- `longitude`
- `property_type`
- `bedrooms`
- `bathrooms`
- `square_feet`
- `year_built`
- `lot_size_sqft`
- `estimated_value`
- `estimated_equity`
- `equity_percentage`
- `motivated_seller_score`
- `notes`
- `is_owner_occupied`
- `address_entry_selection_value`
- `owner` ou campos owner top-level:
  - `first_name` / `firstName`
  - `last_name` / `lastName`
  - `company_name` / `company`
- `mailing_address` ou `owner_mailing_address`:
  - `street`
  - `line2` / `unit`
  - `city`
  - `state`
  - `zip` / `zipCode` / `zip_code`

SourceHub raw payload product-originated:

- `provider_slug = prop4you_product`
- `list_type_slug = manual_property`
- `ingestion_mode = product_originated`
- `payload_format = product_seed`
- `raw_payload.product_origin.origin_surface = my_property`
- `raw_payload.product_origin.origin_action = manual_property_create`
- `raw_payload.product_origin.actor_public_id`
- `raw_payload.product_origin.request_public_id`
- `raw_payload.normalized_seed.street_address`
- `raw_payload.normalized_seed.secondary_address_line`
- `raw_payload.normalized_seed.city`
- `raw_payload.normalized_seed.state`
- `raw_payload.normalized_seed.zip_code`
- `raw_payload.normalized_seed.county`
- `raw_payload.normalized_seed.country`
- `raw_payload.normalized_seed.latitude`
- `raw_payload.normalized_seed.longitude`
- `raw_payload.normalized_seed.discovery_source = manual`
- `raw_payload.normalized_seed.data_source = manual_my_property`
- `raw_payload.normalized_seed.provider_confidence = 60`
- `raw_payload.operational_shadow.notes.title`

Handoff product-originated:

- `product_origin.origin_surface`
- `product_origin.origin_action`
- `product_origin.actor_public_id`
- `product_origin.request_public_id`
- `product_origin.visibility = system_only`
- `sourcehub_handoff.provider_slug`
- `sourcehub_handoff.list_type_slug`
- `sourcehub_handoff.mapping_version = product.manual_property.v1`
- `sourcehub_handoff.normalized_seed.*`
- `sourcehub_handoff.address_source_facts[]`
- `sourcehub_handoff.transformation_lineage.*`

Overlay/manual DTO:

- `PropertyEnrichmentOverlay.latest_dto` recebe `build_manual_creation_dto(...)` com:
  - título/draft title
  - `draft_address.street`
  - `draft_address.line2`
  - `draft_address.city`
  - `draft_address.state`
  - `draft_address.zipCode`
  - `draft_details.propertyType`
  - `draft_details.bedrooms`
  - `draft_details.bathrooms`
  - `draft_details.squareFeet`
  - `draft_details.yearBuilt`
  - `draft_details.lotSizeSqft`
  - `draft_details.estimatedValue`
  - `draft_details.notes`
  - `address_entry_selection_value`

Canonical writes diretos observados no fluxo manual:

- `PropertyDetails` pode receber detalhes manuais no update (`property_type`, `bedrooms`, `bathrooms`, `total_sqft`, `year_built`, `lot_size_sqft`, `listing_price`).
- `PropertyEnrichmentOverlay` recebe equity/motivation/manual draft.
- Owner manual é persistido como `OwnerEntity` + `Ownership` com `data_sources=[manual_my_property]` e mailing em `data.manual_my_property.mailing_address`.

### 3.2 Produto `skip_trace` — submit manual

Fluxo:

- `domains/data/services/skip_trace/validation.py::_create_request`
- Gera request `stseed...`.
- Usa `produce_product_origin_address_seed(...)` com:
  - `origin_surface = skip_trace`
  - `origin_action = skip_trace_submit`
  - `list_type_slug = skip_trace_manual_submit`
  - `mapping_version = product.skip_trace.v1`

SourceHub raw payload:

- `raw_payload.product_origin.origin_surface = skip_trace`
- `raw_payload.product_origin.origin_action = skip_trace_submit`
- `raw_payload.product_origin.actor_public_id`
- `raw_payload.product_origin.request_public_id`
- `raw_payload.normalized_seed.street_address`
- `raw_payload.normalized_seed.secondary_address_line`
- `raw_payload.normalized_seed.city`
- `raw_payload.normalized_seed.state`
- `raw_payload.normalized_seed.zip_code`
- `raw_payload.normalized_seed.country`
- `raw_payload.normalized_seed.discovery_source = canonical_inventory`
- `raw_payload.normalized_seed.data_source = canonical_skip_trace`
- `raw_payload.normalized_seed.provider_confidence = 100`
- `raw_payload.operational_shadow.canonical_property_public_id`
- `raw_payload.operational_shadow.owner_input.first_name`
- `raw_payload.operational_shadow.owner_input.middle_name`
- `raw_payload.operational_shadow.owner_input.last_name`
- `raw_payload.operational_shadow.owner_input.full_name`
- `raw_payload.operational_shadow.mailing_address.street_address`
- `raw_payload.operational_shadow.mailing_address.city`
- `raw_payload.operational_shadow.mailing_address.state`
- `raw_payload.operational_shadow.mailing_address.zip_code`
- `raw_payload.operational_shadow.mailing_address.country`
- `raw_payload.operational_shadow.mailing_address.discovery_source = manual`
- `raw_payload.operational_shadow.mailing_address.data_source = manual_skip_trace_mailing`
- `raw_payload.operational_shadow.address_entry.property.selection_value`
- `raw_payload.operational_shadow.address_entry.property.search_value`
- `raw_payload.operational_shadow.address_entry.mailing.selection_value`
- `raw_payload.operational_shadow.address_entry.mailing.search_value`

Observação de privacidade: `operational_shadow.owner_input` e `operational_shadow.mailing_address` são dados de usuário/produto e devem permanecer `system_only`, com redaction em corpus compartilhável.

### 3.3 Manual coordinate backfill

Serviço/teste evidencia payload SourceHub processado para `prop4you_product/manual_property` usado para backfill de coordenadas:

- filtro em `SourceHubRawRecord(provider_slug=prop4you_product, list_type_slug=manual_property, processing_status=processed)`
- `raw_payload.product_origin.*`
- `raw_payload.normalized_seed.*`
- uso de InstantStreetView em teste mockado para resolver coordenadas quando ausentes

Não foi executada chamada ISV; apenas inspeção estática/test fixtures.

[CANONICAL_IMPLICATIONS]

## 4. Implicações para o corpus canônico de providers

1. Separar três níveis no corpus:
   - raw provider payload: `raw_payload`/fixtures Realtor originais;
   - Matrix DTO pré-SourceHub: `realtor_property_enrichment_pre_sourcehub_dto.v1`;
   - SourceHub canonical DTO/handoff: `canonical_dto` e `sourcehub_handoff`.

2. Realtor property enrichment é enriquecimento ancorado, não aquisição livre:
   - `materialization_policy = enrichment_only_after_canonical_property_exists`;
   - `anchor_property_ref.canonical_property_public_id` é obrigatório;
   - testes exigem erro quando o anchor falta, não existe ou diverge.

3. Endereço de Realtor pode produzir `property_seed_ref`, mas SourceHub só deve materializar enrichment contra uma propriedade canônica já existente.

4. Valuation deve ser família separada de details:
   - `list_price` em property details entra como `estimated_value` seed;
   - endpoints de estimates/spot offer entram por `valuation_financial_seed.estimated_value`;
   - séries e forecast/historical ficam em `residue`, não em verdade canônica direta.

5. Media é evidence/overlay, não identidade canônica:
   - preserve `primary_photo_href`, lista reduzida de fotos e gallery summary;
   - não tornar URL de imagem chave canônica.

6. Public address-entry deve continuar sem provider/source exposto:
   - `selection.value` é token opaco (`realtor:<ref>` ou fallback), mas resposta pública de detalhes é neutra.

7. Product-originated payloads devem entrar no corpus como provider interno `prop4you_product`, com `ingestion_mode=product_originated` e `payload_format=product_seed`.

8. Manual/product payloads têm PII de usuário e owner/mailing; o corpus compartilhável deve armazenar só path families/contratos ou exemplos sintéticos redigidos.

9. `address_entry_selection_value` conecta a UX de autocomplete ao manual creation overlay; é evidência operacional, não fonte de verdade de provider por si só.

10. `SourceHub` já contém a costura de lineage/Matrix admission: qualquer novo corpus deveria registrar `mapping_version`, `provider_mapping_ref`, `schema_genome_ref`, `raw_record_public_id`, `payload_hash` e `transformation_lineage`.

[RESIDUAL_RISKS]

## 5. Riscos residuais / lacunas

- Fixtures Realtor locais podem conter PII/endereço real; não foram dumpadas. Para corpus versionado, gerar versões redigidas/sintéticas ou extrair apenas schema/path inventory.
- Public property-details normalizer trata `estimates.current_values.amount` como mapping; o payload Matrix trata `estimates.current_values[]` como array. Se endpoints variarem, cobrir ambos no contrato canônico.
- `lot_size_sqft` é normalizado no seed e contrato público, mas a materialização Realtor observada foca `PropertyDetails`/valuation/listing/media. Avaliar destino canônico de land/lot separadamente.
- Realtor history/latest event usa primeiro item de `property_history[]` com `listing`; se a ordem do provider mudar, pode escolher evento incorreto. Corpus deve registrar ordering assumptions.
- `provider_reference.provider_property_ref` alterna entre ID numérico e ref com prefixo em endpoints diferentes; canonical deve guardar ambos como provider refs, sem usar como único match universal sem normalização.
- Product-originated `operational_shadow` contém dados sensíveis de usuário/owner; precisa de política explícita de redaction, retenção e visibilidade `system_only`.
- Testes usam mocks e fixtures locais; não validam drift atual do provider. Isso é deliberado para este worker (`NO_PROVIDER_CALLS`), mas deve ser tratado em rotina separada autorizada.
