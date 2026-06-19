# Worker C — revisão de contrato DDL/proof para SystemArea autocomplete geography projection

Status: done
Idioma: pt-BR
Gerado em: 2026-06-19T17:46:21-04:00
Escopo: revisão estática; sem mutação de banco; sem chamadas a provider; sem dump de payload bruto.

## Arquivos/contextos revisados

- `docs/issues/18-prop4you-lfg-systemarea-autocomplete-geography-ddl/00-detection-and-analysis.md`
- `docs/issues/18-prop4you-lfg-systemarea-autocomplete-geography-ddl/01-prd.md`
- `docs/issues/18-prop4you-lfg-systemarea-autocomplete-geography-ddl/02-tasks.md`
- `database/ddl/base/0002_extensions.sql`
- `database/ddl/base/0007_search_normalization.sql`
- `database/ddl/projects/prop4you/leadfinder_group/README.md`
- `database/ddl/projects/prop4you/leadfinder_group/0005_canonical_jsonschema_registry.sql`
- `database/ddl/projects/prop4you/leadfinder_group/0006_projection_candidate_review_board.sql`
- `scripts/proof-prop4you-ddl-lab.sh`
- `scripts/proof-prop4you-lfg-projection-candidate-board.sh`
- `docs/issues/17-prop4you-lfg-projection-candidate-review-board-ddl/09-geography-sequential-projection-review.md`
- `docs/issues/17-prop4you-lfg-projection-candidate-review-board-ddl/10-ddl-proof-contract-review.md`
- `docs/issues/01-prop4you-provider-payload-corpus/10-realtor-internal-payload-inventory.md`
- `docs/reports/prop4you-inertia-app-inventory-and-extraction-order.md`
- `docs/reports/prop4you-sourcehub-matrix-ddl-lab-proof.md`

## Leitura do estado atual

Slice 17 entregou um board de candidatos, não uma projeção final. O DDL `0006_projection_candidate_review_board.sql` seeda `realtor_geography_boundary_evidence`, `realtor_geography_autocomplete_match_evidence` e `reiq_property_geography_signal_evidence` como grupos `geography_first`, mas ainda deixa as paths como candidatos com gates não passados.

Slice 18 tem decisão explícita diferente: implementar DDL real para o primitivo geográfico de Lead Finder baseado em SystemArea/autocomplete. O PRD exige campos de identidade, provider identity, centro/bbox, search terms e função/contrato de autocomplete com `label/value/type/systemAreaId/center/bbox/registrationStatus`.

A base já oferece:

- `uuidv7()` e `base.make_public_ref(...)` para refs públicas.
- `base.normalize_search_terms(...)` / `base.normalize_search_text(...)` para `search_terms text[]` + GIN.
- tentativa de `CREATE EXTENSION postgis` no DDL base, registrada em `base.extension_install_results`.
- review-board com gates e views para provar compatibilidade e não aprovação indevida.

## Recomendação principal

Criar `database/ddl/projects/prop4you/leadfinder_group/0007_systemarea_autocomplete_geography_projection.sql` como DDL real, porém estreito: SystemArea canonical/projection + autocomplete/feed lineage. Não criar property, owner, market, valuation, legal, workspace, CRM ou final product graph neste slice.

O DDL 0007 deve ser posterior ao `0006_projection_candidate_review_board.sql` e anterior a qualquer tabela final de property/market/valuation. Ele deve consumir a decisão arquitetural geography-first sem depender de provider calls.

Cabeçalho recomendado:

```sql
-- package: prop4you/leadfinder_group
-- file: 0007_systemarea_autocomplete_geography_projection.sql
-- status: experimental / geography real projection
-- purpose: SystemArea canonical geography/autocomplete projection for LFG location filtering.
-- depends-on: leadfinder_group/0006_projection_candidate_review_board.sql; base/0007_search_normalization.sql; postgis when available
-- idempotency: idempotent
-- destructive: false
-- [GATEWAY_AGNOSTIC]
-- [NO_PROVIDER_CALLS]
-- [NO_RAW_PAYLOAD_VALUES]
-- [GEOGRAPHY_FIRST]
-- [NO_FINAL_PRODUCT_TABLE_EXPLOSION]
```

## Shape recomendado de DDL

### 1. `system_areas`

Tabela central e durável. Representa a SystemArea canônica/projetada para busca local e filtros LFG.

Campos recomendados:

- `id uuid primary key default uuidv7()`
- `public_ref text generated always as (base.make_public_ref('p4ylfgsa', id)) stored`
- `slug_id text not null`
- `area_type text not null`
- `name text not null`
- `state_code text`
- `country_code text not null default 'US'`
- `parent_id uuid references prop4you_leadfinder_group.system_areas(id) on delete restrict`
- `provider_slug text not null default 'realtor'`
- `provider_geo_id text`
- `provider_area_ref text` para `_id`/provider ref quando existir
- `realty_id text` ou `provider_object_ref text` para conservar o campo legado `realty_id/provider object` sem afirmar propriedade canônica
- `provider_area_type text`
- `centroid geometry(Point, 4326)` se PostGIS disponível; se não, ver nota de fallback abaixo
- `bbox geometry(Polygon, 4326)` para viewport/bounding box derivado
- `boundary geometry(MultiPolygon, 4326)` opcional/restrito para geometrias validadas
- `boundary_status text not null default 'unknown'`
- `viewport_status text not null default 'unknown'`
- `registration_status text not null default 'projected'`
- `search_label text generated/stored ou mantido por seed`
- `search_terms text[] not null default '{}'::text[]`
- `lineage jsonb not null default '{}'::jsonb`
- `metadata jsonb not null default '{}'::jsonb`
- lifecycle: `active`, `created_at`, `updated_at`, `version`

Constraints recomendadas:

- `unique(public_ref)`
- `unique(provider_slug, provider_geo_id)` where provider_geo_id not null não pode ser partial unique constraint inline; criar unique index parcial.
- `unique(provider_slug, slug_id, area_type, state_code)` ou `unique(slug_id, area_type, state_code, country_code)` conforme a auditoria A confirmar.
- `area_type in ('state','county','city','postal_code','neighborhood','school_district','metro','market','unknown')` com abertura controlada se legado usar outros tipos.
- `state_code is null or state_code ~ '^[A-Z]{2}$'`
- `country_code ~ '^[A-Z]{2}$'`
- `boundary_status in ('unknown','not_available','pending','derived','validated','failed','restricted')`
- `viewport_status in ('unknown','not_available','pending','derived','validated','failed')`
- `registration_status in ('canonical','projected','provider_only','pending_registration','blocked','superseded','archived')`
- `jsonb_typeof(lineage)='object'`, `jsonb_typeof(metadata)='object'`

Notas:

- `name`, `state_code`, `slug_id`, `provider_geo_id`, centro e bbox são aceitáveis como projeção porque são anchors de geography/autocomplete. Não incluir endereço completo de propriedade nesta tabela.
- `provider_geo_id`/`slug_id` são identidade de geography, não identidade de property.
- `realty_id`/`provider_object_ref` deve ser tratado como provider identity/lineage, não FK para property.

### 2. `system_area_provider_identities`

Separar identidades por provider evita encher `system_areas` com colunas específicas de Realtor, Geokeo ou futuros providers.

Campos recomendados:

- `id uuid primary key default uuidv7()`
- `public_ref generated` com prefixo `p4ylfgsap`
- `system_area_id uuid not null references system_areas(id) on delete cascade`
- `provider_slug text not null`
- `provider_area_ref text`
- `provider_geo_id text`
- `provider_slug_id text`
- `provider_area_type text`
- `provider_confidence numeric(5,2)` opcional
- `identity_status text not null default 'active'`
- `lineage jsonb not null default '{}'::jsonb`
- lifecycle

Constraints/índices:

- `unique(provider_slug, provider_geo_id)` quando `provider_geo_id is not null`
- `unique(provider_slug, provider_slug_id, provider_area_type, system_area_id)` ou variante sem `system_area_id` se legado garantir unicidade global
- `(system_area_id, provider_slug, identity_status)`
- GIN em `lineage jsonb_path_ops` somente para refs/hashes/contagens; sem valores brutos.

### 3. `system_area_aliases`

Tabela estreita para nomes alternativos e termos de autocomplete sem misturar provider residue.

Campos:

- `id uuid primary key default uuidv7()`
- `system_area_id uuid not null references system_areas(id) on delete cascade`
- `alias text not null`
- `alias_kind text not null default 'search'`
- `locale text default 'en-US'`
- `search_terms text[] not null default '{}'::text[]`
- `active boolean not null default true`
- lifecycle

Constraints:

- `unique(system_area_id, alias_kind, alias)`
- `alias_kind in ('primary','search','provider_label','display','legacy','synonym')`

### 4. `system_area_feed_terms`

Representa termos consultados/observados para alimentação/autocomplete, sem chamar provider.

Campos recomendados inspirados no inventário legado `SystemAreaFeedTerm`:

- `id uuid primary key default uuidv7()`
- `public_ref generated` prefixo `p4ylfgsaft`
- `term text not null`
- `normalized_term text not null`
- `expected_area_type text`
- `state_code text`
- `provider_slug text not null default 'realtor'`
- `feed_status text not null default 'pending'`
- `last_attempted_at timestamptz`
- `result_count integer not null default 0`
- `lineage jsonb not null default '{}'::jsonb`
- lifecycle

Constraints:

- `unique(provider_slug, normalized_term, coalesce(expected_area_type,''), coalesce(state_code,''))` deve ser implementado por unique index expression, não inline.
- `feed_status in ('pending','observed','matched','no_match','failed','blocked','archived')`
- Sem payload provider bruto. `lineage` só refs/hashes/contagens/mapping versions.

### 5. `system_area_feed_results`

Relaciona resultado observado/feed/autocomplete a uma `system_area` materializada ou pendente.

Campos recomendados inspirados em `SystemAreaFeedResult`:

- `id uuid primary key default uuidv7()`
- `public_ref generated` prefixo `p4ylfgsafr`
- `feed_term_id uuid references system_area_feed_terms(id) on delete restrict`
- `system_area_id uuid references system_areas(id) on delete set null`
- `provider_slug text not null`
- `provider_area_ref text`
- `provider_geo_id text`
- `provider_slug_id text`
- `area_type text`
- `name text`
- `state_code text`
- `rank integer`
- `match_score numeric(8,4)`
- `result_status text not null default 'candidate'`
- `lineage jsonb not null default '{}'::jsonb`
- lifecycle

Constraints:

- `result_status in ('candidate','materialized','matched','ignored','blocked','superseded','archived')`
- `rank is null or rank > 0`
- `match_score is null or match_score >= 0`
- índice em `(feed_term_id, rank)`
- índice em `(provider_slug, provider_geo_id)`

### 6. Evitar `SystemAreaCandidate` completo neste slice

O legado tem `SystemAreaCandidate` e `SystemAreaCandidateAttempt`. Para o 0007, recomendo não recriar todo o workflow legado. Se necessário para prova/lineage, usar `system_area_feed_terms` + `system_area_feed_results` e o review-board 0006. Um clone completo de candidate/attempt antes da necessidade operacional tende a virar table explosion e duplicar o board.

Se o implementador decidir que precisa de attempts, limitar a uma tabela `system_area_registration_attempts` com status, refs, contagens e erro sanitizado, sem request/response bruto.

## Views recomendadas

### `v_system_area_autocomplete_suggestions`

View base que materializa o shape público/operacional neutro:

- `label`
- `value`
- `type`
- `systemAreaId`
- `center`
- `bbox`
- `registrationStatus`
- campos internos adicionais opcionais: `rank_hint`, `search_terms`, `state_code`, `area_type`

Contrato recomendado:

- `label`: nome display, ex. `name || coalesce(', ' || state_code, '')`.
- `value`: opaco e estável, preferencialmente `systemarea:` || `public_ref`; não expor provider ref como value público.
- `type`: `area_type`.
- `systemAreaId`: `public_ref`.
- `center`: JSON `{ "lat": ..., "lng": ... }` derivado de `ST_Y(centroid)` / `ST_X(centroid)`.
- `bbox`: JSON `{ "west": ..., "south": ..., "east": ..., "north": ... }` derivado de `ST_XMin/ST_YMin/ST_XMax/ST_YMax` em `bbox` ou `ST_Envelope(boundary)`.
- `registrationStatus`: `registration_status`.

### `v_system_area_provider_lineage`

View interna/restrita para auditoria de provider identities, feed terms e feed results. Não deve expor payload bruto; apenas provider_slug, refs, counts, hashes, mapping_version e timestamps.

### `v_system_area_projection_gate_status`

View de compatibilidade com `0006` para mostrar se as candidates de geography/autocomplete continuam em review, e quais campos do 0007 correspondem às candidates aprováveis.

Campos úteis:

- `candidate_key`
- `projection_shape`
- `target_table`
- `target_column`
- `systemarea_projection_present boolean`
- `all_required_gates_passed`
- `review_status`

Essa view permite provar que o 0007 implementa a projeção real sem apagar o contrato do review-board.

## Funções recomendadas

### `search_system_area_autocomplete(p_query text, p_area_types text[] default null, p_state_code text default null, p_limit integer default 10)`

Função estável, gateway-agnostic, sem provider call. Retorna `jsonb` ou `table(...)`; para PostgREST costuma ser mais simples `returns table(label text, value text, type text, "systemAreaId" text, center jsonb, bbox jsonb, "registrationStatus" text)`.

Regras:

- `p_query` deve ser limpo com `base.clean_text` e tokenizado com `base.normalize_search_terms`.
- Limitar `p_limit` por check interno, ex. `least(greatest(coalesce(p_limit,10),1),50)`.
- Priorizar áreas `registration_status in ('canonical','projected')` e `active=true`.
- Filtro opcional por `area_type` e `state_code`.
- Ranking inicial simples: prefix match em `name/search_label`, overlap de `search_terms`, exatidão de state, depois nome.
- Não consultar provider remoto quando não houver match; feed externo fica fora do DDL/proof.

### `upsert_system_area_projection(...)`

Função opcional para inserir/atualizar SystemArea a partir de pipeline autorizado. Deve receber somente campos normalizados e lineage sanitizada, não payload bruto.

Parâmetros mínimos:

- `p_slug_id`, `p_provider_geo_id`, `p_area_type`, `p_name`, `p_state_code`
- `p_center_lat`, `p_center_lng`
- bbox como west/south/east/north ou geometry validada
- `p_provider_slug`, `p_provider_area_ref`, `p_lineage`

Regras:

- Validar latitude/longitude.
- Criar `centroid` com `ST_SetSRID(ST_MakePoint(lng, lat),4326)`.
- Criar bbox com `ST_MakeEnvelope(west, south, east, north, 4326)`.
- Calcular `search_terms` com `base.normalize_search_terms(name, slug_id, state_code, provider_geo_id)`.
- Não armazenar raw provider payload em `metadata`/`lineage`.

### `record_system_area_feed_result(...)`

Opcional para registrar resultado de feed/autocomplete já normalizado, sem request/response bruto. Deve conectar feed term, provider identity e possível `system_area_id`.

## PostGIS, geometry, bbox e indexes

### Extensão/PostGIS

`base/0002_extensions.sql` tenta instalar PostGIS como extensão opcional. O DDL 0007 tem duas opções:

1. Requerer PostGIS para geometry e falhar se não existir, porque o PRD pede geography projection real.
2. Ser defensivo e criar objetos geometry apenas se PostGIS existir.

Recomendação: para este slice, exigir PostGIS no proof. A aceitação fala de geometry/bbox/centroid e o build PG18 inclui extensão. O proof deve validar `exists (select 1 from pg_extension where extname='postgis')` e falhar com mensagem clara se ausente.

### Geometria

- `centroid geometry(Point, 4326)` para busca/centro de viewport.
- `bbox geometry(Polygon, 4326)` para filtro rápido por viewport.
- `boundary geometry(MultiPolygon, 4326)` apenas para boundary derivada/validada. Raw coordinate arrays ficam JSONB restrito em SourceHub/lineage, não no 0007.
- Se provider boundary vier como Polygon, normalizar para MultiPolygon com `ST_Multi(...)`.
- Checks recomendados:
  - `centroid is null or ST_SRID(centroid)=4326`
  - `bbox is null or ST_SRID(bbox)=4326`
  - `boundary is null or ST_SRID(boundary)=4326`
  - `centroid is null or ST_IsValid(centroid)`
  - `bbox is null or ST_IsValid(bbox)`
  - `boundary is null or ST_IsValid(boundary)`

### Índices

Em `system_areas`:

- btree `(area_type, state_code, name)` where `active=true`
- btree `(slug_id, area_type, state_code)`
- unique parcial `(provider_slug, provider_geo_id)` where `provider_geo_id is not null`
- GIN `search_terms` via `using gin (search_terms)`
- GiST `centroid` where `centroid is not null`
- GiST `bbox` where `bbox is not null`
- GiST `boundary` where `boundary is not null`
- GIN `lineage jsonb_path_ops` se lineage for consultada por refs/hashes

Em `system_area_aliases`:

- GIN `search_terms`
- btree `(alias_kind, alias)` where `active=true`

Em feed:

- `(provider_slug, normalized_term, expected_area_type, state_code)`
- `(feed_status, updated_at desc)`
- `(feed_term_id, rank)`
- `(provider_slug, provider_geo_id)`

### Search

Usar `base.normalize_search_terms`. Não recomendo introduzir PGroonga/RUM/unaccent no 0007 sem query profile; um GIN em `text[]` + prefix/ILIKE controlado é suficiente para proof local. Se `pg_trgm` estiver disponível e o autocomplete precisar fuzzy matching, adicionar como melhoria posterior, não como contrato obrigatório inicial.

## Compatibilidade com o review-board 0006

O DDL 0007 deve continuar compatível com as candidates existentes:

- `realtor_geography_autocomplete_match_evidence:geo_id` -> `system_area_provider_identities.provider_geo_id` e/ou `system_areas.provider_geo_id`
- `...:slug_id` -> `system_areas.slug_id`
- `...:city` -> `system_areas.name` quando `area_type='city'`, não campo separado universal
- `...:state_code` -> `system_areas.state_code`
- `...:postal_code` -> `system_areas.name` ou `slug_id` quando `area_type='postal_code'`; avaliar com audit A/B
- `...:county_fips` -> não precisa virar coluna em `system_areas` neste slice; se necessário, usar `metadata` sanitizada ou tabela futura `system_area_county_links`
- `...:centroid` -> `system_areas.centroid`
- `realtor_geography_boundary_evidence:*` -> `bbox`/`boundary` apenas derivadas/validadas

Importante: implementar uma projeção real de geography não significa marcar automaticamente todos os candidates do 0006 como approved. O proof deve mostrar que o board segue existente e que a projection real é governada/compatível; aprovações continuam exigindo gates/decisão explícita.

## Contrato de proof recomendado

Criar script específico:

- `scripts/proof-prop4you-lfg-systemarea-autocomplete-geography.sh`

O script deve:

1. Usar DB limpa via `scripts/proof-prop4you-ddl-lab.sh` ou apply order próprio.
2. Aplicar base + Prop4You até `leadfinder_group/0007_systemarea_autocomplete_geography_projection.sql`.
3. Não chamar provider.
4. Não inserir payload bruto; usar somente seeds sintéticos mínimos ou DDL seeds de áreas sintéticas/redigidas.
5. Gerar JSON machine-checkable.
6. Escrever report em `docs/reports/prop4you-lfg-systemarea-autocomplete-geography-proof.md`.

### Assertions mínimas

Exemplo de objeto JSON esperado:

```json
{
  "postgis_available": true,
  "system_area_table_count": 1,
  "provider_identity_table_count": 1,
  "feed_term_table_count": 1,
  "feed_result_table_count": 1,
  "autocomplete_function_count": 1,
  "autocomplete_view_count": 1,
  "system_area_count": 3,
  "areas_with_public_ref_count": 3,
  "areas_with_search_terms_count": 3,
  "areas_with_centroid_count": 3,
  "areas_with_bbox_count": 3,
  "provider_geo_identity_count": 3,
  "raw_payload_column_count": 0,
  "autocomplete_suggestion_count": 3,
  "suggestion_shape_ok": true,
  "bbox_shape_ok": true,
  "center_shape_ok": true,
  "review_board_compat_view_count": 1,
  "approved_candidate_count_still_zero": 0
}
```

Critérios de PASS:

- PostGIS instalado no lab DB.
- Tabelas reais existem: `system_areas`, `system_area_provider_identities`, `system_area_aliases`, `system_area_feed_terms`, `system_area_feed_results`.
- Views/funções existem: `v_system_area_autocomplete_suggestions`, `search_system_area_autocomplete(...)` e view de lineage/compatibilidade.
- Dados sintéticos mínimos provam city/county/postal_code ou tipos confirmados pela auditoria A/B.
- Todas as sugestões retornam as chaves `label`, `value`, `type`, `systemAreaId`, `center`, `bbox`, `registrationStatus`.
- `value` e `systemAreaId` usam ref pública/opaca; não expõem provider raw id como contrato público.
- `center` tem `lat/lng` numéricos; `bbox` tem `west/south/east/north` numéricos.
- `search_terms` usa `base.normalize_search_terms` e é indexado por GIN.
- Índices GiST existem para `centroid` e `bbox`.
- Nenhuma coluna chamada `raw_payload`, `provider_payload`, `response_body`, `request_body` em tabelas do 0007.
- `v_approved_projection_candidates` permanece vazia se nenhum gate/review foi deliberadamente aprovado.

### SQL checks úteis

- Existência de PostGIS:

```sql
select exists(select 1 from pg_extension where extname='postgis') as postgis_available;
```

- Shape de função:

```sql
select jsonb_agg(jsonb_build_object(
  'label', label,
  'value', value,
  'type', type,
  'systemAreaId', "systemAreaId",
  'center', center,
  'bbox', bbox,
  'registrationStatus', "registrationStatus"
))
from prop4you_leadfinder_group.search_system_area_autocomplete('spring', null, null, 10);
```

- Proibição de raw payload:

```sql
select count(*)
from information_schema.columns
where table_schema='prop4you_leadfinder_group'
  and table_name like 'system_area%'
  and column_name in ('raw_payload','provider_payload','request_body','response_body','raw_response','raw_request');
```

- Índices geometry/search:

```sql
select indexname
from pg_indexes
where schemaname='prop4you_leadfinder_group'
  and tablename='system_areas'
  and (indexdef ilike '%gist%' or indexdef ilike '%gin%');
```

## Apply order recomendado

Atualizar `scripts/proof-prop4you-ddl-lab.sh` após criação do DDL:

```text
leadfinder_group/0005_canonical_jsonschema_registry.sql
leadfinder_group/0006_projection_candidate_review_board.sql
leadfinder_group/0007_systemarea_autocomplete_geography_projection.sql
leadfinder/0004_dictionary_promotion_review_apply.sql
```

Atualizar também `database/ddl/projects/prop4you/leadfinder_group/README.md` com uma linha para `0007` e com boundary explícito: SystemArea geography/autocomplete, sem final property graph.

## Riscos e controles

1. Table explosion de produto.
   - Controle: limitar 0007 a geography/autocomplete/feed lineage. Não criar property/owner/market/valuation/legal/workspace.

2. Exposição de provider/raw identity como contrato público.
   - Controle: `value` público deve ser `systemarea:<public_ref>`; provider refs ficam em tabela interna/lineage.

3. Confundir autocomplete de endereço/propriedade com SystemArea.
   - Controle: SystemArea lida com city/county/postal/area; endereço completo e property details ficam fora do 0007.

4. PostGIS ausente em ambiente alvo.
   - Controle: proof falha claramente; se necessário depois, criar fallback explícito de lat/lng numeric, mas não diluir o contrato real de geography deste slice.

5. Boundary raw coordinates virarem colunas ou docs.
   - Controle: raw coords continuam JSONB restrito na origem; 0007 guarda geometry derivada/validada, bbox e centroid.

6. Auto-aprovar candidates do 0006 só porque o 0007 existe.
   - Controle: não alterar gates/reviews; criar view de compatibilidade sem mudar status.

7. Search ruim por falta de normalização.
   - Controle: `search_terms` obrigatório, calculado por `base.normalize_search_terms`, índice GIN e proof de query -> sugestões.

## Conclusão

O DDL 0007 deve ser uma projeção real e estreita de geography-first: `system_areas` como primitivo central, provider identities separadas, aliases/search terms, feed terms/results sanitizados, PostGIS centroid/bbox/boundary derivado, função local de autocomplete e views de prova. Isso satisfaz o PRD sem criar uma explosão prematura de tabelas finais de produto e sem violar o contrato do review-board 0006.
