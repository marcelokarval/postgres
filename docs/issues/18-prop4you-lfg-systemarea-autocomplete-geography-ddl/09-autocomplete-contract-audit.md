# Auditoria Worker B — contrato Lead Finder autocomplete/API/frontend

Status: concluído
Data: 2026-06-19
Escopo: JSON shape de sugestões de localização, `system_area_ids`, `bbox`/`center`/`selectedAreaViewport`, expansão via provider, exclusão de endereço, `status`/`registrationStatus`.

## Fontes lidas

Legacy source (`prop4you-inertia`):

- `backend/src/apps/public/lead_finder/api_queries.py`
- `backend/src/apps/public/lead_finder/contracts.py`
- `backend/src/apps/public/lead_finder/filters.py`
- `backend/src/apps/public/lead_finder/queries.py`
- `backend/src/apps/public/lead_finder/presenters.py`
- `backend/src/apps/public/lead_finder/tests/test_boundary.py`
- `backend/src/apps/public/lead_finder/tests/test_runtime_queries.py`
- `backend/src/apps/public/lead_finder/tests/test_map_payload_contract.py`
- `backend/tests/lead_finder/test_public_queries.py`
- `backend/tests/lead_finder/test_query_service_contracts.py`
- `frontends/front-react/src/pages/private/lead-finder/hooks/useLeadMapState.ts`
- `frontends/front-react/src/pages/private/lead-finder/LeadFinderPageHandlers.ts`
- `frontends/front-react/src/types/lead-finder/filters.ts`
- `frontends/front-react/src/components/features/lead-finder/filters/types.ts`
- `frontends/front-react/src/components/features/lead-finder/filters/advanced/types.ts`

Não foram feitas chamadas de rede/provider. Esta auditoria não copia payload raw nem PII; exemplos abaixo usam somente nomes/campos estruturais ou fixtures sintéticas dos testes.

## Resumo executivo

O contrato legado atual para autocomplete do Lead Finder é area-only e deve ser o contrato-alvo do DDL da Slice 18. A resposta pública é:

```json
{
  "suggestions": [
    {
      "label": "<nome amigável>",
      "value": "<public_id da SystemArea>",
      "type": "city|state|county|zip",
      "meta": "<state opcional>",
      "systemAreaId": "<public_id da SystemArea>",
      "center": [lng, lat],
      "bbox": [west, south, east, north],
      "registrationStatus": "created|already_installed|... opcional"
    }
  ]
}
```

Campos obrigatórios na sugestão serializada pelo backend: `label`, `value`, `type`, `meta`, `systemAreaId`. Campos condicionais: `center`, `bbox`, `registrationStatus`.

O frontend consome `center` como `[lng, lat]`, `bbox` como `[west, south, east, north]`, envia seleção como query param `system_area_ids=<public_id[,public_id...]>`, e espera `selectedAreaViewport` na página Inertia para reposicionar o mapa quando um SystemArea já está aplicado na URL.

## Contrato de sugestões de localização

### Tipos suportados

Backend (`contracts.py`) define `LeadFinderLocationSuggestionType = Literal["city", "state", "county", "zip"]`. O serializer converte `AreaType.POSTAL_CODE` para `zip` e mantém `city`, `state`, `county` como strings diretas.

Frontend (`types/lead-finder/filters.ts`) ainda permite `neighborhood`, mas o endpoint auditado não retorna `neighborhood`; provider results com `area_type="neighborhood"` são explicitamente ignorados no backend. Para o DDL da Slice 18, o contrato compatível deve expor somente:

- `city`
- `state`
- `county`
- `zip` (derivado de `postal_code` no storage/modelo)

### Campos

`_serialize_system_area_suggestion(area)` em `api_queries.py` produz:

- `label`: rótulo amigável.
  - state: `state` ou `name`.
  - county: `<name> County, <state>` se o nome ainda não termina em County.
  - zip: `<postal_code>, <state>` quando há state.
  - city: `<name>, <state>` quando há state.
- `value`: `area.public_id`.
- `type`: `city|state|county|zip`.
- `meta`: `area.state`.
- `systemAreaId`: `area.public_id`.
- `center`: presente quando `area.location` existe; ordem `[lng, lat]` (`location.x`, `location.y`).
- `bbox`: presente quando `area.boundary_geom` existe; ordem `[west, south, east, north]` via `boundary_geom.extent`.
- `registrationStatus`: presente somente para sugestões materializadas/recuperadas via provider/feed; ausente para sugestões canônicas locais normais.

Implicação DDL: função/view de autocomplete precisa retornar shape JSON com `systemAreaId` e `value` ambos apontando para o public ref da área; não deve retornar PK interna. `center` e `bbox` devem ser arrays numéricos na ordem GeoJSON/mapbox-like `[lng, lat]` e `[min_lng, min_lat, max_lng, max_lat]`.

### Limite e ordenação

- Query com menos de 2 caracteres retorna `{"suggestions": []}`.
- Resultados locais são ranqueados e limitados a 20.
- Após expansão provider, merge por `systemAreaId` e limite final de 20.
- Ranking local favorece:
  1. state query exata quando query é estado.
  2. nome exato + estado.
  3. prefixo do nome.
  4. match em search terms.
  5. token match.
  6. desempate por tipo (`state`, `city`, `county`, `zip`), nome e state.

Implicação DDL: uma função `...autocomplete(q text, limit int default 20)` deve reproduzir, no mínimo, prefix/name/state/token ordering suficiente para preservar UX e testes.

## `system_area_ids` e aplicação de filtro

### Entrada frontend -> backend

`LeadFinderPageHandlers.buildLeadFinderQuery(...)` grava seleção de área como:

```text
system_area_ids=<id1,id2,...>
```

`filters.py` parseia para:

```python
filters["system_area_ids"] = [value.strip() for value in query_dict["system_area_ids"].split(",") if value.strip()]
```

Esse mesmo filtro é usado tanto na página Inertia (`load_lead_finder_page`) quanto no endpoint de mapa (`load_lead_finder_markers`). Testes cobrem que markers filtram por `system_area_ids` e ignoram área unsupported (`neighborhood`).

### Estado frontend

`useLeadMapState.ts` mantém `selectedSystemAreaIds: string[]`. Ao selecionar uma sugestão:

- `selectedSystemAreaIds = [suggestion.systemAreaId]` se presente.
- `locationSearch = suggestion.label`.
- `locationSuggestions = []`.
- mapa usa `suggestion.bbox` se presente; senão calcula bbox fallback a partir de `suggestion.center`.

Ao editar o texto após uma seleção, o hook limpa `selectedSystemAreaIds`. Ao limpar filtros, remove `system_area_ids` da URL e volta ao bbox default.

Implicação DDL/API: `systemAreaId` precisa estar presente para seleção útil. Embora o type frontend marque como opcional, a UX de filtro canônico depende dele.

## `bbox`, `center` e `selectedAreaViewport`

### Autocomplete suggestion

`bbox`/`center` na sugestão são hints imediatos de câmera. O frontend usa diretamente:

- `bbox`: aplicado como bounds.
- `center`: ordem `[lng, lat]`; fallback bounds `[lng±0.15, lat±0.15]`.

### Página Inertia

`contracts.py` define `LeadFinderSelectedAreaViewportContract`:

```json
{
  "systemAreaId": "<public_id>",
  "label": "<label>",
  "type": "city|state|county|zip",
  "bbox": [west, south, east, north],
  "center": [lng, lat],
  "zoom": 9|11,
  "source": "boundary|centroid|property_points"
}
```

`queries.py` constrói o viewport do primeiro SystemArea selecionado, com esta precedência:

1. `boundary_geom` presente:
   - `bbox = extent` arredondado a 6 casas.
   - `center = centroid_lon/centroid_lat` quando disponíveis, senão centro do bbox.
   - `zoom = 11`.
   - `source = "boundary"`.
2. centroide presente (`centroid_lon`/`centroid_lat`):
   - `center = [lng, lat]`.
   - `bbox = center ± 0.15°`.
   - `zoom = 11`.
   - `source = "centroid"`.
3. sem geometria na área, mas propriedades retornadas têm coordenadas:
   - `bbox` calculado dos property points.
   - `center` do bbox.
   - `zoom = 9`.
   - `source = "property_points"`.
4. sem área/sem pontos: `selectedAreaViewport = null`.

Multi-select: `_selected_system_area` ordena por `area_type`, `name` e usa `.first()`. Teste legado espera que, entre state e city, o city vença por ordenação lexical de `area_type` (`city` antes de `state`). A Slice 18 deve decidir se preserva exatamente esse comportamento ou documenta uma ordem semântica; para compatibilidade imediata, manter a escolha do primeiro por `area_type, name`.

## Expansão provider e ledger/cache

`search_lead_finder_locations(query, provider_search=None)` faz:

1. Trim e mínimo de 2 chars.
2. Busca sugestões em `SystemArea` local.
3. Parse de query em `(name_query, state_query)`.
4. Decide expansão provider:
   - se query é somente estado (`state_query` sem `name_query`): não expande.
   - senão expande quando o texto de discovery tem 3+ chars.
5. Cria/recupera `SystemAreaFeedTerm` para a query normalizada.
6. Se o feed term está `COMPLETED`, usa cache/ledger (`SystemAreaFeedResult`) e não chama provider.
7. Caso contrário, marca `SEARCHING`, chama provider, registra feed results, materializa SystemArea suportado, marca `COMPLETED` ou `FAILED`.

Provider call contract legado:

```python
provider_search(query, ["city", "state", "county", "postal_code"], 100)
```

Tipos provider suportados para materialização/autocomplete:

- `city`
- `state`
- `county`
- `postal_code`

Tipos unsupported, como `neighborhood`, são gravados/ignorados conforme ledger, mas não chamam `register_system_area` e não aparecem nas sugestões.

Implicação DDL: precisa haver estrutura equivalente para:

- term/cache key por query normalizada, país, tipos e limit.
- results por provider object id/result key.
- materialization status por result.
- ponte opcional para `system_area` materializada.
- contadores de term: result_count, created_count, already_installed_count, skipped_count, failed_count.
- status de term: searching/completed/failed (e estado inicial do modelo legado).

A função SQL de autocomplete pode ser local-only no proof da Slice 18, mas o schema deve acomodar provider/feed lineage e `registrationStatus` para provider-backed rows.

## `registrationStatus` e `status`

### `registrationStatus` na sugestão

A sugestão só inclui `registrationStatus` quando vem de provider/feed:

- Nova área materializada: `created`.
- Área já existente: `already_installed`.
- Cache completado reutiliza `materialization_status` do feed result; na prática os testes esperam `created`/`already_installed` nas sugestões.

Unsupported/invalid/failed não devem virar sugestão retornada.

### Status do feed term/result

O contrato operacional usa status de ledger, não expõe raw provider payload no autocomplete:

- Term: `SEARCHING`, `COMPLETED`, `FAILED` (além do default no modelo).
- Result/materialization: `CREATED`, `ALREADY_INSTALLED`, `SKIPPED_UNSUPPORTED_TYPE`, `SKIPPED_INVALID_PAYLOAD`, `FAILED`.

Implicação DDL: `registrationStatus` no JSON pode ser nulo/omitido para áreas locais; quando derivado de feed result deve mapear exatamente para strings snake_case (`created`, `already_installed`, etc.) para compatibilidade com tests/frontend.

## Exclusão de endereço e PII

A fronteira é explícita: autocomplete do Lead Finder é agrupado por área, não aquisição de endereço.

Evidências:

- Docstring de `search_lead_finder_locations`: endpoint limitado a inventory-discovery areas; address results remain outside.
- `filters.py` ignora `address`, `street_address`, `full_address`.
- Teste `test_parse_filters_from_query_keeps_area_filters_and_ignores_full_address_keys` cobre essa exclusão.
- Teste `test_search_lead_finder_locations_returns_grouped_area_suggestions_only` garante que sugestões não incluem label de rua nem `type="address"`.
- Map payload é “thin”: marker JSON contém somente `kind`, `id`, `coordinates`, `render`; teste garante que `address` não sai no marker.

Implicação DDL/proofs: não incluir payload raw de provider, endereços completos ou owner/contact data em docs/proofs. A projection da Slice 18 deve modelar SystemArea, não SystemAddress/full address acquisition.

## Divergências/atenções de contrato

1. Frontend aceita `LocationSuggestionType` com `neighborhood`, mas backend e PRD Slice 18 não retornam esse tipo. Recomenda-se manter DDL/API restritos a `city|state|county|zip`; se o frontend for limpo no futuro, remover `neighborhood` do type shared.
2. `LeadFinderLocationSuggestionContract` no backend marca `systemAreaId` como `NotRequired`, mas o serializer sempre envia para SystemArea. Para a Slice 18, tratar como obrigatório no contrato público de autocomplete.
3. `meta` é `NotRequired` no type, mas serializer atual sempre define `meta: area.state` (possivelmente string vazia/nula conforme modelo). DDL deve preferir state text quando existir; não depender de `meta` para identidade.
4. `selectedAreaViewport` escolhe a primeira área por ordenação de string `area_type, name`, não pela ordem enviada na URL. Isso está coberto por teste e deve ser preservado se o objetivo for compatibilidade total.
5. `center` usa `[lng, lat]`, não `{lat,lng}`. Já markers usam `{lat,lng}`. Essa diferença é intencional no legado e deve ser documentada no DDL/proof.

## Requisitos recomendados para a DDL 0007

### Tabelas/colunas mínimas para contrato

SystemArea projection:

- public ref (`area_...`) para `value` e `systemAreaId`.
- `area_type` storage com `postal_code` e função/view expondo `zip`.
- `name`, `state`, `parent`.
- `slug_id`, `realty_id`/provider object identity, `provider_geo_id`.
- `centroid_lng`, `centroid_lat` ou geometry point equivalente.
- `boundary`/extent ou colunas deriváveis para `bbox`.
- `active`, `deleted` ou equivalente para filtrar autocomplete.
- search terms/token materializado para prefix/token query.

Provider/feed lineage:

- feed term por query normalizada/provider/types/limit/country.
- feed result por provider result key/object id.
- materialization status e reason.
- link nullable para SystemArea.
- contadores/status do term.
- payload raw pode existir no runtime legado, mas proofs/docs da Slice 18 não devem expor valores raw; se a DDL guardar JSONB raw, documentar retenção/PII separadamente.

### Função/view JSON sugerida

Uma função de proof compatível deve retornar array/rows com campos equivalentes:

- `label text`
- `value text`
- `type text`
- `meta text`
- `systemAreaId text`
- `center numeric[] nullable` na ordem `[lng,lat]`
- `bbox numeric[] nullable` na ordem `[west,south,east,north]`
- `registrationStatus text nullable`

O envelope público deve ser `{"suggestions": [...]}` quando exposto via RPC/API.

## Checklist de aceitação para Slice 18 baseado nesta auditoria

- [ ] Query curta (<2 chars) retorna lista vazia.
- [ ] Autocomplete local retorna somente `city|state|county|zip`.
- [ ] `value == systemAreaId == public ref da SystemArea`.
- [ ] `postal_code` no storage sai como `type="zip"`.
- [ ] `center` é `[lng, lat]`.
- [ ] `bbox` é `[west, south, east, north]`.
- [ ] `registrationStatus` é ausente/nulo para local-only e snake_case para provider/feed.
- [ ] `system_area_ids` filtra por public refs separados por vírgula.
- [ ] `selectedAreaViewport` preserva source `boundary|centroid|property_points` e bbox/center/zoom.
- [ ] Endereço completo/street-level não entra em filtros, sugestões ou markers.
- [ ] Provider expansion/ledger é modelável sem chamadas reais no proof.
- [ ] Docs/proofs não imprimem provider raw payload nem PII.
