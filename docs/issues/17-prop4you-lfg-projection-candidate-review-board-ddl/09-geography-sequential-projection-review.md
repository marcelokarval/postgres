# 09 — Revisão geography-first e semantic lanes sequenciais

Status: concluído
Worker: B
Escopo: Realtor/REIQ/property/valuation/legal/taxonomy como lanes semânticas separadas, com geography primeiro e grupos downstream sequenciais.

Política de privacidade: este artefato reproduz apenas nomes de campos, caminhos estruturais, contagens e decisões de modelagem. Nenhum valor bruto de JSON, endereço, nome, telefone, e-mail, coordenada individual ou outro PII foi impresso.

## Decisão aplicada

A decisão do usuário é separar Realtor/REIQ semanticamente e iniciar por geography. A recomendação é seedar o review board com lanes ordenadas, não com uma massa única de property JSON:

1. `geography` — primeira lane, comum a Realtor boundary/geography, Realtor market geography e REIQ state/county/property geography.
2. `market` — depende de geography resolvida para snapshot por área/período.
3. `valuation` — depende de property/geography/lineage para AVM, assessed/appraised e saldos/loan/equity.
4. `property` — fatos físicos e listing enrichment; depende de identidade/endereço/geografia.
5. `legal` — situações REIQ, datas/document refs e sinais judiciais/tributários; depende de property geography e lineage.
6. `taxonomy` — suporte Matrix/LeadFinder/list type/state semantics; usada como aprovação semântica transversal, não como payload operacional.

Regra de sequencing para o DDL seed:

```text
geography -> market -> valuation -> property -> legal -> taxonomy/support checks
```

Observação: taxonomy também participa como gate/apoio desde o início, mas sua lane própria deve ficar separada para evitar misturar registry/support artifacts com payloads de provider.

## Evidência revisada

Fontes lidas:

- `docs/issues/16-prop4you-inertia-json-corpus-lfg-manifest/09-realtor-property-corpus-review.md`
- `docs/issues/16-prop4you-inertia-json-corpus-lfg-manifest/13-lfg-corpus-base-consolidation.md`
- `docs/corpus/prop4you/lfg/prop4you-inertia-lfg-corpus-base-summary.v1.json`
- `docs/schemas/prop4you/lfg/projection-policy.v1.json`
- `docs/issues/17-prop4you-lfg-projection-candidate-review-board-ddl/00-detection-and-analysis.md`
- `docs/issues/17-prop4you-lfg-projection-candidate-review-board-ddl/01-prd.md`

Achados reutilizados da revisão de corpus:

- Base LFG governada: 3.448 arquivos usados para corpus base, sem raw values.
- Família `realtor_property_market`: 27 candidatos LFG, todos em fixtures/provas.
- Família `reiq_property_legal_signal`: 3.094 arquivos no corpus base.
- Envelope hint `realtor_evidence`: 27.
- Envelope hint `property`: 3.104.
- Envelope hint `taxonomy`: 82.
- Realtor explícito revisado: 17 endpoint reports e 10 client snapshots.
- REIQ property/geography/valuation revisado no worker anterior: 2.812 objetos com chaves de propriedade/geografia/valor.
- Estados/list types observados no recorte REIQ: `tx`, `fl` e list types legais/tributários variados; a modelagem deve tratar state/list type como semântica, não como tag solta.

## Candidate groups recomendados

### 1. Geography — Realtor boundary/geography

`candidate_group_key` sugerido:

```text
realtor_geography_boundary_evidence
```

| Campo | Valor recomendado |
| --- | --- |
| `group_label` | Realtor geography boundary evidence |
| `source_family` | `realtor_property_market` |
| `canonical_envelope_hint` | `realtor_evidence` |
| `semantic_lane` | `geography` |
| `lane_order` | 10 |
| `provider_slug` | `realtor` |
| `list_type_slug` | `area_boundary` |
| `projection_policy_key` | `lfg_projection_policy.v1` |
| `privacy_class` | `provider_sensitive` |
| `default_decision` | `candidate_review_required` |
| `raw_values_allowed_in_docs` | false |

Candidate paths:

| Candidate path | Path family | Projection kind recomendado | Decisão default |
| --- | --- | --- | --- |
| `boundary.result.areas[]` | `area_collection` | `relational_child_projection` | `review_required` |
| `boundary.result.areas[].id` | `geo_identity` | `relational_column` | `review_required` |
| `boundary.result.areas[].name` | `geo_label` | `relational_column` | `review_required` |
| `boundary.result.areas[].center` | `geo_point` | `postgis_geometry_candidate` | `review_required` |
| `boundary.result.areas[].radius` | `geo_area_metric` | `derived_relational_column` | `review_required` |
| `boundary.result.areas[].breakpoints[]` | `provider_residue` | `keep_jsonb` | `keep_jsonb` |
| `boundary.result.boundary.type` | `geometry_metadata` | `relational_column` | `review_required` |
| `boundary.result.boundary.coordinates` | `geometry_payload` | `jsonb_lineage` + `postgis_geometry_candidate` | `review_required` |
| `data.result.areas[]` | `area_collection_alt_wrapper` | `relational_child_projection` | `review_required` |
| `data.result.boundary.coordinates` | `geometry_payload_alt_wrapper` | `jsonb_lineage` + `postgis_geometry_candidate` | `review_required` |

Justificativa:

- Geography vem antes porque resolve anchors espaciais usados por market snapshots, comparables, property matching e legal/state routing.
- Coordenadas brutas devem permanecer JSONB restrito; se houver necessidade de busca espacial, derivar PostGIS geometry de forma governada.
- Não expandir arrays de coordenadas em colunas comuns.

### 2. Geography — Realtor autocomplete/address selection

`candidate_group_key` sugerido:

```text
realtor_geography_autocomplete_match_evidence
```

| Campo | Valor recomendado |
| --- | --- |
| `source_family` | `realtor_property_market` |
| `canonical_envelope_hint` | `realtor_evidence` |
| `semantic_lane` | `geography` |
| `lane_order` | 20 |
| `provider_slug` | `realtor` |
| `list_type_slug` | `autocomplete` |
| `privacy_class` | `provider_sensitive` |
| `default_decision` | `candidate_review_required` |

Candidate paths:

| Candidate path | Path family | Projection kind recomendado | Decisão default |
| --- | --- | --- | --- |
| `results[]` | `suggestion_collection` | `relational_child_projection` | `review_required` |
| `data[]` | `suggestion_collection_report_wrapper` | `relational_child_projection` | `review_required` |
| `results[]._id` | `provider_ref` | `relational_column` | `review_required` |
| `results[]._score` | `match_metric` | `derived_relational_column` | `review_required` |
| `results[].area_type` | `geo_type` | `relational_column` | `review_required` |
| `results[].geo_id` | `geo_identity` | `relational_column` | `review_required` |
| `results[].slug_id` | `geo_identity` | `relational_column` | `review_required` |
| `results[].mpr_id` | `provider_property_ref` | `relational_column` | `review_required` |
| `results[].line` | `property_address_line` | `relational_column` com masking/acesso restrito | `review_required` |
| `results[].city` | `geo_component` | `relational_column` | `review_required` |
| `results[].state_code` | `geo_component` | `relational_column` | `review_required` |
| `results[].postal_code` | `geo_component` | `relational_column` | `review_required` |
| `results[].country` | `geo_component` | `relational_column` | `review_required` |
| `results[].centroid.lat` | `geo_point_component` | `postgis_geometry_candidate` | `review_required` |
| `results[].centroid.lon` | `geo_point_component` | `postgis_geometry_candidate` | `review_required` |
| `results[].counties[]` | `county_collection` | `relational_child_projection` | `review_required` |
| `results[].counties[].fips` | `county_identity` | `relational_column` | `review_required` |
| `results[].counties[].name` | `county_label` | `relational_column` | `review_required` |
| `results[].counties[].state_code` | `county_state` | `relational_column` | `review_required` |
| `results[].county_needed_for_uniq` | `disambiguation_flag` | `derived_relational_column` | `review_required` |
| `results[].full_address[]` | `address_residue` | `keep_jsonb` ou hash derivado | `keep_jsonb` |
| `results[].prop_status[]` | `provider_status_residue` | `keep_jsonb` | `keep_jsonb` |
| `results[].validation_code[]` | `provider_residue` | `keep_jsonb` | `keep_jsonb` |

Justificativa:

- Autocomplete é evidência de matching/seleção e não verdade canônica final.
- Projetar somente anchors de geography/matching úteis para join/dedupe; labels e linhas de endereço exigem privacidade e lineage.

### 3. Geography — REIQ state/county/property geography

`candidate_group_key` sugerido:

```text
reiq_property_geography_signal_evidence
```

| Campo | Valor recomendado |
| --- | --- |
| `source_family` | `reiq_property_legal_signal` |
| `canonical_envelope_hint` | `property` |
| `semantic_lane` | `geography` |
| `lane_order` | 30 |
| `provider_slug` | `reiq` |
| `list_type_slug` | `state_county_property_geography` |
| `privacy_class` | `pii_sensitive` |
| `default_decision` | `candidate_review_required` |

Candidate paths:

| Candidate path | Path family | Projection kind recomendado | Decisão default |
| --- | --- | --- | --- |
| `property_id` | `provider_property_ref` | `relational_column` | `review_required` |
| `property_address` | `property_address_line` | `relational_column` com masking/acesso restrito | `review_required` |
| `property_street` | `property_address_component` | `relational_column` | `review_required` |
| `property_city` | `geo_component` | `relational_column` | `review_required` |
| `property_state` | `geo_component` | `relational_column` | `review_required` |
| `property_zip_code` | `geo_component` | `relational_column` | `review_required` |
| `county` | `geo_component` | `relational_column` | `review_required` |
| `city` | `geo_component_alt` | `relational_column` | `review_required` |
| `state` | `geo_component_alt` | `relational_column` | `review_required` |
| `zip_code` | `geo_component_alt` | `relational_column` | `review_required` |
| `owner_address` | `contact_or_owner_address` | `keep_jsonb` ou lane DirectSkip/contact futura | `keep_jsonb` |
| `owner_city` | `contact_or_owner_geo` | `keep_jsonb` | `keep_jsonb` |
| `owner_state` | `contact_or_owner_geo` | `keep_jsonb` | `keep_jsonb` |
| `owner_zip_code` | `contact_or_owner_geo` | `keep_jsonb` | `keep_jsonb` |

Justificativa:

- Geography REIQ deve resolver property locality e state routing para list type/legal semantics.
- Owner/mailing geography não deve ser confundida com property geography; manter separada e restrita até uma lane de contato/owner resolver semântica e privacidade.

### 4. Market — Realtor market geography snapshots

`candidate_group_key` sugerido:

```text
realtor_market_geography_snapshot_evidence
```

| Campo | Valor recomendado |
| --- | --- |
| `source_family` | `realtor_property_market` |
| `canonical_envelope_hint` | `realtor_evidence` |
| `semantic_lane` | `market` |
| `lane_order` | 110 |
| `provider_slug` | `realtor` |
| `list_type_slug` | `market_details` |
| `depends_on_lane` | `geography` |
| `privacy_class` | `provider_sensitive` |
| `default_decision` | `candidate_review_required` |

Candidate paths:

| Candidate path | Path family | Projection kind recomendado | Decisão default |
| --- | --- | --- | --- |
| `market` | `market_payload` | `jsonb_lineage` | `review_required` |
| `market.housing_market` | `market_payload_alt` | `jsonb_lineage` | `review_required` |
| `market.housing_market.hot_market_badge` | `market_classification` | `relational_column` | `review_required` |
| `market.housing_market.hot_market_rank` | `market_metric` | `derived_relational_column` | `review_required` |
| `market.housing_market.local_hotness_score` | `market_metric` | `derived_relational_column` | `review_required` |
| `market.housing_market.local_temperature` | `market_metric` | `derived_relational_column` | `review_required` |
| `market.housing_market.median_days_on_market` | `market_metric` | `derived_relational_column` | `review_required` |
| `market.housing_market.median_listing_price` | `market_metric` | `derived_relational_column` | `review_required` |
| `market.housing_market.median_price_per_sqft` | `market_metric` | `derived_relational_column` | `review_required` |
| `market.housing_market.median_rent_price` | `market_metric` | `derived_relational_column` | `review_required` |
| `market.housing_market.median_sold_price` | `market_metric` | `derived_relational_column` | `review_required` |
| `market.housing_market.national_hotness_score` | `market_metric` | `derived_relational_column` | `review_required` |
| `market.housing_market.national_temperature` | `market_metric` | `derived_relational_column` | `review_required` |

Justificativa:

- Market é snapshot temporal por geografia/período, não atributo do imóvel.
- Requer `geo_ref`, `area_type`, período/captured_at e lineage para evitar comparação de mercados heterogêneos.

### 5. Valuation — Realtor estimates e REIQ valores financeiros

`candidate_group_key` sugerido:

```text
property_valuation_evidence_realtor_reiq
```

| Campo | Valor recomendado |
| --- | --- |
| `source_family` | `realtor_property_market` + `reiq_property_legal_signal` |
| `canonical_envelope_hint` | `property` |
| `semantic_lane` | `valuation` |
| `lane_order` | 210 |
| `provider_slug` | `mixed_provider_review` |
| `list_type_slug` | `property_valuation` |
| `depends_on_lane` | `geography` |
| `privacy_class` | `pii_sensitive` para REIQ, `provider_sensitive` para Realtor |
| `default_decision` | `candidate_review_required` |

Candidate paths:

| Candidate path | Path family | Projection kind recomendado | Decisão default |
| --- | --- | --- | --- |
| `estimates.current_values[]` | `valuation_series_current` | `relational_child_projection` | `review_required` |
| `estimates.current_values[].date` | `valuation_date` | `relational_column` | `review_required` |
| `estimates.current_values[].estimate` | `valuation_amount` | `relational_column` | `review_required` |
| `estimates.current_values[].estimate_low` | `valuation_range` | `relational_column` | `review_required` |
| `estimates.current_values[].estimate_high` | `valuation_range` | `relational_column` | `review_required` |
| `estimates.current_values[].isbest_homevalue` | `valuation_flag` | `derived_relational_column` | `review_required` |
| `estimates.current_values[].source` | `valuation_source` | `jsonb_lineage` + selected columns | `review_required` |
| `estimates.forecast_values[]` | `valuation_forecast_series` | `keep_jsonb` | `keep_jsonb` |
| `estimates.historical_values[]` | `valuation_historical_series` | `keep_jsonb` | `keep_jsonb` |
| `home_estimate.value` | `valuation_amount_alt` | `relational_column` | `review_required` |
| `home_estimate.source` | `valuation_source_alt` | `relational_column` | `review_required` |
| `assessed_value` | `tax_or_assessment_value` | `relational_column` | `review_required` |
| `appraised_value` | `valuation_amount_reiq` | `relational_column` | `review_required` |
| `estimated_equity` | `equity_amount` | `relational_column` | `review_required` |
| `equity` | `equity_amount_or_ratio` | `relational_column` com coerção revisada | `review_required` |
| `estimated_unpaid_balance` | `loan_balance` | `relational_column` | `review_required` |
| `original_loan_amount` | `loan_amount` | `relational_column` | `review_required` |
| `historical_interest_rate` | `loan_metric` | `derived_relational_column` | `review_required` |
| `loan_origination_month` | `loan_temporal_component` | `derived_relational_column` | `review_required` |
| `loan_origination_year` | `loan_temporal_component` | `derived_relational_column` | `review_required` |

Justificativa:

- Valuation deve preservar fonte, data e tipo de valor; AVM, assessment e loan/equity não são a mesma verdade.
- Séries forecast/historical continuam JSONB até existir modelo temporal completo.

### 6. Property — físicos/listing/details

`candidate_group_key` sugerido:

```text
property_physical_listing_evidence_realtor_reiq
```

| Campo | Valor recomendado |
| --- | --- |
| `source_family` | `realtor_property_market` + `reiq_property_legal_signal` |
| `canonical_envelope_hint` | `property` |
| `semantic_lane` | `property` |
| `lane_order` | 310 |
| `provider_slug` | `mixed_provider_review` |
| `list_type_slug` | `property_physical_listing` |
| `depends_on_lane` | `geography` |
| `privacy_class` | `provider_sensitive` / `pii_sensitive` conforme fonte |
| `default_decision` | `candidate_review_required` |

Candidate paths:

| Candidate path | Path family | Projection kind recomendado | Decisão default |
| --- | --- | --- | --- |
| `description.type` | `physical_attribute` | `relational_column` | `review_required` |
| `description.sub_type` | `physical_attribute` | `relational_column` | `review_required` |
| `description.beds` | `physical_attribute` | `relational_column` | `review_required` |
| `description.baths` | `physical_attribute` | `relational_column` | `review_required` |
| `description.baths_full` | `physical_attribute` | `relational_column` | `review_required` |
| `description.baths_half` | `physical_attribute` | `relational_column` | `review_required` |
| `description.sqft` | `physical_attribute` | `relational_column` | `review_required` |
| `description.lot_sqft` | `physical_attribute` | `relational_column` | `review_required` |
| `description.year_built` | `physical_attribute` | `relational_column` | `review_required` |
| `list_price` | `listing_attribute` | `relational_column` | `review_required` |
| `price` | `listing_attribute_alt` | `relational_column` | `review_required` |
| `status` | `listing_status` | `relational_column` | `review_required` |
| `listing_id` | `listing_identity` | `relational_column` | `review_required` |
| `permalink` | `listing_ref` | `relational_column` com política de exposição | `review_required` |
| `href` | `listing_ref_alt` | `relational_column` com política de exposição | `review_required` |
| `photos[]` | `media_array` | `keep_jsonb` | `keep_jsonb` |
| `primary_photo` | `media_summary` | `jsonb_lineage` ou selected ref | `review_required` |
| `advertisers[]` | `contact_provider_payload` | `keep_jsonb` restrito | `keep_jsonb` |
| `consumer_advertisers[]` | `contact_provider_payload` | `keep_jsonb` restrito | `keep_jsonb` |
| `buyers[]` | `contact_provider_payload` | `keep_jsonb` restrito | `keep_jsonb` |
| `bed` | `physical_attribute_reiq` | `relational_column` | `review_required` |
| `bath` | `physical_attribute_reiq` | `relational_column` | `review_required` |
| `garage` | `physical_attribute_reiq` | `relational_column` | `review_required` |
| `pool` | `physical_attribute_reiq` | `relational_column` | `review_required` |
| `sq_ft` | `physical_attribute_reiq` | `relational_column` | `review_required` |
| `yr_bt` | `physical_attribute_reiq` | `relational_column` | `review_required` |

Justificativa:

- Fatos físicos são bons candidatos quando têm coerção segura e lineage.
- Arrays de mídia e subárvores de contato/anunciante permanecem JSONB restrito; não entram em projeção pública.

### 7. Legal/tax — REIQ situations, dates, document refs e tax history

`candidate_group_key` sugerido:

```text
reiq_property_legal_tax_signal_evidence
```

| Campo | Valor recomendado |
| --- | --- |
| `source_family` | `reiq_property_legal_signal` |
| `canonical_envelope_hint` | `property` |
| `semantic_lane` | `legal` |
| `lane_order` | 410 |
| `provider_slug` | `reiq` |
| `list_type_slug` | `property_legal_tax_signal` |
| `depends_on_lane` | `geography` |
| `privacy_class` | `pii_sensitive` |
| `default_decision` | `candidate_review_required` |

Candidate paths:

| Candidate path | Path family | Projection kind recomendado | Decisão default |
| --- | --- | --- | --- |
| `lead_type` | `situation_type` | `relational_column` | `review_required` |
| `internal_id` | `provider_record_ref` | `relational_column` | `review_required` |
| `date_added` | `provider_temporal` | `relational_column` | `review_required` |
| `date_filed` | `legal_temporal` | `relational_column` | `review_required` |
| `case_number` | `legal_ref` | `relational_column` com acesso restrito | `review_required` |
| `instrument_no` | `legal_ref` | `relational_column` com acesso restrito | `review_required` |
| `auction_date_time` | `legal_temporal` | `relational_column` | `review_required` |
| `current_month` | `legal_temporal_component` | `derived_relational_column` | `review_required` |
| `current_year` | `legal_temporal_component` | `derived_relational_column` | `review_required` |
| `tax_history[]` | `tax_history_provider` | `relational_child_projection` se normalizado | `review_required` |
| `tax_history[].year` | `tax_temporal` | `relational_column` | `review_required` |
| `tax_history[].tax` | `tax_amount` | `relational_column` | `review_required` |
| `tax_history[].assessment.total` | `assessment_value` | `relational_column` | `review_required` |
| `tax_history[].market.total` | `market_assessment_value` | `relational_column` | `review_required` |
| `legal_description` | `legal_text` | `keep_jsonb` restrito | `keep_jsonb` |
| `comments` | `legal_text_or_provider_residue` | `keep_jsonb` restrito | `keep_jsonb` |
| `mortgagee_bank_name` | `institution_name` | `keep_jsonb` ou restricted column após gate | `review_required` |
| `mortgagor_first_name` | `person_name` | `keep_jsonb` restrito | `keep_jsonb` |
| `mortgagor_last_name` | `person_name` | `keep_jsonb` restrito | `keep_jsonb` |
| `owner_first_name` | `person_name` | `keep_jsonb` restrito | `keep_jsonb` |
| `owner_last_name` | `person_name` | `keep_jsonb` restrito | `keep_jsonb` |
| `ownership` | `ownership_text_or_status` | `jsonb_lineage` + selected review column | `review_required` |

Justificativa:

- Legal/situation facts são estruturados; não devem virar tags soltas.
- Nomes, textos legais e comentários permanecem restritos; refs e datas podem virar colunas se gate de privacidade e necessidade de query passar.

### 8. Taxonomy/support — Matrix/LeadFinder semantics

`candidate_group_key` sugerido:

```text
lfg_taxonomy_projection_semantic_support
```

| Campo | Valor recomendado |
| --- | --- |
| `source_family` | `matrix_registry_or_artifact` + `leadfinder_baseline` |
| `canonical_envelope_hint` | `taxonomy` |
| `semantic_lane` | `taxonomy` |
| `lane_order` | 510 |
| `provider_slug` | `internal_support` |
| `list_type_slug` | `projection_semantic_support` |
| `privacy_class` | `internal` |
| `default_decision` | `candidate_review_required` |

Candidate paths:

| Candidate path | Path family | Projection kind recomendado | Decisão default |
| --- | --- | --- | --- |
| `source_family` | `support_classification` | `relational_column` | `review_required` |
| `canonical_envelope_hint` | `support_classification` | `relational_column` | `review_required` |
| `evidence_role` | `support_classification` | `relational_column` | `review_required` |
| `privacy_tier` | `privacy_classification` | `relational_column` | `review_required` |
| `decision` | `corpus_decision` | `relational_column` | `review_required` |
| `priority` | `review_priority` | `relational_column` | `review_required` |
| `context_tags[]` | `support_tags` | `keep_jsonb` ou `relational_child_projection` se vocabulário estabilizar | `review_required` |
| `path_shape` | `shape_lineage` | `jsonb_lineage` | `review_required` |
| `hash` | `evidence_hash` | `relational_column` | `review_required` |

Justificativa:

- Taxonomy governa significado e aprovação semântica, mas não deve contaminar property/realtor/reiq payloads.
- Deve alimentar gate 2 (`matrix_leadfinder_semantic_approval`) e gate 7 (`privacy_pii_classified`).

## Vocabulário recomendado de lanes

| Lane | Ordem | Papel | Dependências |
| --- | ---: | --- | --- |
| `geography` | 10-30 | Normalizar geo refs, city/state/ZIP/county, boundary/centroid e property geography | corpus observado + privacy class |
| `market` | 110 | Snapshots/agregados de mercado por geo/time bucket | `geography` |
| `valuation` | 210 | Valores estimados, assessed/appraised, loan/equity | `geography` + property/provider lineage |
| `property` | 310 | Fatos físicos, listing status/ref e atributos estáveis | `geography` |
| `legal` | 410 | Situações REIQ, datas, refs legais/tributárias | `geography` + taxonomy/list type |
| `taxonomy` | 510 | Semântica Matrix/LeadFinder, evidence role, privacy tier e path shape | transversal; não payload operacional |

## Vocabulário recomendado de `projection_kind`

Usar o mesmo vocabulário mínimo do Worker A, acrescido de PostGIS/materialized snapshot quando necessário:

- `relational_column` — campo escalar usado para join, filtro, sort, uniqueness, FK, RLS ou constraint.
- `derived_relational_column` — campo derivado/coagido de JSON, status, flag ou métrica que não deve substituir lineage.
- `relational_child_projection` — arrays com itens estáveis que precisam virar linhas filhas de review/snapshot.
- `relational_edge_candidate` — edges candidatos entre entidades, somente após aprovação semântica.
- `postgis_geometry_candidate` — ponto/polígono derivado para busca espacial; raw coordinates continuam JSONB.
- `temporal_snapshot_projection` — snapshot por `geo_ref`/property/provider/período, especialmente market e valuation.
- `jsonb_lineage` — envelope/payload sanitizado preservado para auditoria e replay.
- `keep_jsonb` — raw/provider residue, arrays variáveis, textos, contato, mídia completa e campos raros.

## Gate defaults recomendados

A política v1 exige sete gates para qualquer candidato. Defaults por lane:

| Gate | Chave | Geography | Market | Valuation | Property | Legal | Taxonomy |
| ---: | --- | --- | --- | --- | --- | --- | --- |
| 1 | `representative_corpus_observed` | `pass_candidate` para paths observados | `pass_candidate` para Realtor market paths | `pass_candidate` para paths observados | `pass_candidate` para detalhes/físicos observados | `pass_candidate` para REIQ frequente | `pass_candidate` para corpus support |
| 2 | `matrix_leadfinder_semantic_approval` | `pending_review` | `pending_review` | `pending_review` | `pending_review` | `pending_review` obrigatório por list type/state | `pass_candidate` apenas para support validado |
| 3 | `stable_or_intentionally_provider_specific` | `pass_candidate` para wrappers conhecidos; boundary coords provider-specific | `pending_review` por métrica/provedor | `pending_review` por tipo de valor | `pending_review` por fonte/cast | `pending_review` por divergência estadual | `pass_candidate` se versionado |
| 4 | `query_join_filter_sort_unique_fk_rls_postgis_or_constraint_need` | `pass_candidate` para geo anchors/PostGIS | `pass_candidate` para snapshots indexados | `pass_candidate` para sort/ranking | `pass_candidate` para filtros físicos/listing | `pass_candidate` para filas legais/datas | `pass_candidate` para review board |
| 5 | `safe_cast_or_coercion_exists` | `pending_review` para lat/lng/ZIP/coords | `pending_review` para métricas | `pending_review` para currency/ranges | `pending_review` para baths/sqft/years | `pending_review` para datas/refs | `pass_candidate` para enums internos |
| 6 | `durable_lineage_to_raw_json` | `pass_candidate` se envelope ref/hash existir | `pass_candidate` se captured_at/geo_ref existir | `pass_candidate` se source/date/provider ref existir | `pass_candidate` se provider ref/raw ref existir | `pass_candidate` se internal/raw ref existir | `pass_candidate` |
| 7 | `privacy_pii_classified` | `pass_candidate` com classes explícitas | `pass_candidate` provider_sensitive | `pending_review` para REIQ financeiro | `pending_review` por endereço/media/contact | `pending_review` por PII/legal text | `pass_candidate` internal |

Regra de aprovação:

- Nenhum candidate path deve ser `approved_for_projection` enquanto os sete gates não estiverem passados.
- Default operacional de todos os grupos deste artefato: `candidate_review_required`.
- Geography pode ser priorizada na fila, mas não auto-aprovada.

## Recomendações para DDL seed

1. Seedar grupos de geography primeiro:
   - `realtor_geography_boundary_evidence`
   - `realtor_geography_autocomplete_match_evidence`
   - `reiq_property_geography_signal_evidence`
2. Seedar grupos downstream com `depends_on_lane=geography`:
   - `realtor_market_geography_snapshot_evidence`
   - `property_valuation_evidence_realtor_reiq`
   - `property_physical_listing_evidence_realtor_reiq`
   - `reiq_property_legal_tax_signal_evidence`
3. Seedar `lfg_taxonomy_projection_semantic_support` separadamente, como suporte/gate e não como provider payload.
4. Registrar `semantic_lane`, `lane_order`, `depends_on_lane`, `provider_slug`, `source_family`, `canonical_envelope_hint`, `privacy_class`, `default_decision` e `raw_values_allowed_in_docs=false` em todos os grupos.
5. Registrar path-level candidates sem valores raw, usando apenas structural paths.
6. Seedar sete gate rows por candidate path, com `pending_review` como default conservador onde cast, privacidade ou semântica ainda dependam de normalizador/Matrix.
7. Marcar explicitamente como `keep_jsonb`:
   - payload bruto e provider residue;
   - arrays variáveis sem necessidade de query;
   - advertisers/buyers/phones/emails/names;
   - owner/mortgagor names e legal text;
   - raw boundary coordinate arrays;
   - forecast/historical AVM detalhado;
   - mídia/fotos completas;
   - comments e campos raros por estado/list type.
8. Marcar como `postgis_geometry_candidate` apenas geometria derivada e validada, não coordenadas raw impressas em docs.
9. Separar `property_address` de `owner_address`/mailing address para não confundir truth de imóvel com evidência de contato.
10. Deduplicar REIQ por provider/list/state/internal_id/hash antes de qualquer seed canônico operacional.

## Riscos e controles

Riscos principais:

- Projetar market/valuation/legal antes de geography e criar snapshots sem geo anchor confiável.
- Misturar Realtor e REIQ em uma única lane ampla, apagando diferenças de privacidade, fonte e semântica.
- Tratar REIQ como owner/property truth canônica sem lineage e dedupe.
- Projetar legal text, names, advertiser/buyer contact ou owner/mailing address como colunas públicas.
- Expandir boundary coordinates brutas em colunas sem PostGIS derivado e sem necessidade de query.
- Confundir assessed/appraised/AVM/market/loan/equity como um único valor.
- Criar taxonomy como payload operacional em vez de suporte de gate.

Controles recomendados:

- Sequência obrigatória por `semantic_lane`/`lane_order`.
- `depends_on_lane=geography` para market, valuation, property e legal.
- Sete gates obrigatórios por candidate path.
- `jsonb_lineage` para envelopes e `keep_jsonb` para resíduos/PII/textos/arrays variáveis.
- `privacy_class` explícito por grupo e por path sensível.
- PostGIS apenas como derivação validada.
- Review board como fonte de decisão, não como tabela final de projeção.

## Conclusão

A recomendação é avançar com geography-first no review board. Geography deve ser seedada como três grupos semânticos iniciais: Realtor boundary, Realtor autocomplete/matching e REIQ property geography. Market, valuation, property physical/listing e legal/tax entram como lanes downstream dependentes de geography. Taxonomy/Matrix/LeadFinder permanece separada como suporte semântico e gate transversal. A projeção deve ser seletiva: anchors, refs, métricas, snapshots e geometria derivada podem virar candidatos relacionais; raw payloads, PII, textos legais, mídia, arrays variáveis e provider residue permanecem JSONB-first.
