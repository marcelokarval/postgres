# LeadFinder filter-pressure analysis (Prop4You-Inertia)

Escopo: análise curta, somente por caminhos, nomes de código e strings estruturais do backend Prop4You-Inertia. Não foram lidos/dumpados payloads raw; a evidência abaixo vem de nomes de arquivos, funções, classes, campos e contratos de consulta.

## Evidência de pressão de filtros

1. LeadFinder é uma superfície própria, não apenas um relatório estático.
   - Rotas e boundaries aparecem em `interfaces/web/lead_finder/urls.py`, `views/api_endpoints.py`, `views/mutations.py` e `apps/public/lead_finder/*`.
   - Endpoints/nomeações indicam `markers`, `detail`, `summaries`, `enrich`, `location_search`, `save`, `unsave`, `bulk-save`, `presets`, `lists` e `tags`.
   - Isso pressiona a modelagem para suportar leitura geográfica, detalhe hidratado, enriquecimento de proprietário e organização CRM/workspace.

2. O contrato de filtros é amplo e composável.
   - `apps/public/lead_finder/filters.py` parseia `lead_types`, `property_types`, `bbox`, `system_area_ids`, `states`, `counties`, `zip_codes`, `city`, ranges físicos (`bedrooms`, `bathrooms`, `year_built`, `sqft`, `lot_size`, `stories`), flags (`has_pool`, `has_garage`, `is_vacant`, `is_owner_occupied`, `has_tax_debt`), valuation (`equity`, `estimated_value`, `mortgage_balance`, `listing_price`) e ownership (`owner_type`, `is_absentee`, `is_in_state`, `is_cash_buyer`, `portfolio_size`, `years_owned`).
   - `has_active_search_filters()` separa filtros reais de controles técnicos (`page`, `page_size`, `sort_by`), evitando busca ampla sem intenção explícita.

3. A engine de domínio confirma pressão por índices/colunas canônicas.
   - `domains/real_estate/services/property_filters.py` descreve quatro tiers: quick filters, location filters, advanced filters e sort/pagination.
   - Quick filters dependem de `situations__situation_type` + `SituationStatus.ACTIVE` e `details__property_type`.
   - Location usa PostGIS bbox (`location__location__intersects`) e texto normalizado por `state`, `county`, `zip_code`, `city`.
   - Valuation usa métricas mais recentes via subquery (`latest_equity_percentage`, `latest_estimated_equity`) e ranges de valor/saldo/listing.
   - Ownership combina `is_current`, `entity_type`, `is_absentee`, `is_in_state`, `is_cash_buyer`, `portfolio_size`, `from_date`.

4. Map/search exige resultados resumidos e estáveis.
   - `apps/public/lead_finder/api_queries.py` chama `PropertyQueryService.search_properties_for_map(..., limit=2000)` e emite `queryState`, `counts`, `meta`, `items`.
   - Marker render usa `score` para status `HOT/WARM/COLD`, além de `stackingCount`, `primaryLeadType`, `propertyType`, `priceBand`, coordenadas e clusterização.
   - Isso pressiona armazenamento canônico para score/classificação, coordenadas, tipo primário de lead, tipo de imóvel e bandas de preço/valor.

5. Owner/contact é parte do fluxo LeadFinder, mas contato bruto deve ficar controlado.
   - `actions.py` expõe `enrich_lead_finder_property_owner` e retorna contagens (`phonesAdded`, `emailsAdded`) em vez de promover payload raw.
   - `PropertyQueryService` monta page/detail querysets com `Ownership`, `OwnerPhone`, `OwnerEmail`, contagens de contatos válidos e prefetch de contatos válidos no detalhe.
   - `canonical_party_graph.py` possui `OwnerPhone` com status `correct/wrong/no_answer/dnc/dead_line`, `is_dnc`, `is_valid`, `confidence_score` e índice `re_phone_valid_dnc_idx`.
   - `OwnerEmail` possui status `active/inactive/bounced/invalid`, `bounce_type`, `bounce_reason`, `bounce_count`, `last_bounce_at`, `is_valid` e campos normalizados.

6. Status operacional e score também têm pressão própria.
   - `lead_score_models.py` modela `total_score`, sub-scores, `classification`, `score_drivers`, índices por classificação/score e menciona sinais de urgência, financeiros, qualidade de contato e recência.
   - `lead_intelligence_models.py` adiciona `qualification_status`, `queue_status` com `DEAD`, tentativas de contato, `next_contact_at`, outcomes e score corrente.
   - Esses nomes indicam que status de funil, dead-lead e score não são apenas deriváveis de raw; são estados operacionais a persistir.

## Implicações para modelagem PG18/raw extractors

- Separar claramente camadas: raw provider payload -> extrações path-level -> entidade canônica LeadFinder -> estado operacional/workspace.
- Priorizar colunas/indexes para filtros de alta pressão: geografia, situação ativa, tipo de imóvel, occupancy, valuation/equity, ownership atual e score/classificação.
- Modelar contato de proprietário como satélites com validade/status/DNC/bounce/dead-line; evitar materializar payload raw na superfície LeadFinder.
- Manter presets/listas/tags como workspace artifacts sobre filtros e propriedades canônicas, não como parte do raw provider corpus.
- Tratar `page/page_size/sort_by`, bbox/cluster e query signature como contrato de consulta, não como semântica de domínio.

## Riscos residuais

- A análise não prova cardinalidade real nem seletividade dos filtros, pois não acessou dados/raw payloads.
- Campos de front-end minificado em `static/front-react/assets/feature-lead-finder-*.js` não foram usados como fonte principal para evitar ruído.
- Pode haver filtros legados fora do boundary `apps/public/lead_finder`/`domains/real_estate` que exijam revisão posterior.
