# Worker B — Revisão de envelopes de evidência DirectSkip/Realtor

Status: complete
Escopo: recomendações para envelopes JSONSchema/evidence derivados dos inventários DirectSkip/Realtor e da ADR PG18 JSONB-first.
Fontes: `docs/issues/14-prop4you-json-curation-pg18-jsonb-strategy/08-directskip-corpus-inventory.md`, `09-realtor-corpus-inventory.md`, `12-adr-pg18-jsonb-first-canonical-modeling.md`.

[NO_PROVIDER_CALLS]

Esta revisão foi feita apenas por leitura estática dos artefatos locais acima. Não houve chamadas a DirectSkip, Realtor, APIs externas, banco runtime, Docker ou provedores.

[NO_RAW_VALUES_OR_PII]

Este documento registra apenas famílias de schema, classes semânticas, candidatos de projeção e políticas. Não reproduz nomes, telefones, e-mails, endereços, coordenadas, IDs reais, URLs completas, hashes de queries, payloads brutos ou outros valores sensíveis.

## 1. Decisão-base

Aplicar a política aceita da ADR PG18 JSONB-first:

```text
JSONB-first para evidence, payloads provider-native, envelopes e resíduos.
Relational-first para identidade durável, âncoras, FKs, constraints, PostGIS, snapshots temporais e projeções de alto valor.
```

Consequência para esta slice:

- DirectSkip deve informar o envelope `contact-satellites-envelope.v1`, mas não deve escrever verdade canônica de owner/property.
- Realtor deve informar o envelope `realtor-evidence-envelope.v1`, mas não deve criar property, SystemArea ou market truth sem âncora canônica.
- Valuation, market e comparable evidence devem ficar como subfamílias explícitas, com snapshots/projeções somente quando sancionados por contrato downstream.

## 2. Famílias de schema recomendadas

### 2.1 `contact-satellites-envelope.v1` informado por DirectSkip

Finalidade: representar evidência de contato/reachability associada a uma âncora de lead/person/property já resolvida por Lead Finder/SourceHub, preservando lineage até a resposta provider.

Famílias mínimas:

| Família | Shape esperado | Política |
| --- | --- | --- |
| `envelope` | metadados de provider, surface, captured_at, schema version, source ref, privacy class | colunas/projeções para filtro/auditoria; payload permanece JSONB |
| `request_input_evidence` | dados de entrada provider por nomes de campos, sem valores em docs | JSONB; não promover para truth canônica |
| `provider_status` | status/result code/error class | projeção operacional de baixo risco se redigida |
| `contact_candidates[]` | candidatos de contato do provider | JSONB-first; projetar contagens e linkage |
| `contact_candidates[].names[]` | hints de nome/idade/deceased flag | sensível; não sobrescrever owner identity |
| `contact_candidates[].phones[]` | telefones e tipos provider | candidato forte a satellite/projeção para dedupe/outreach com normalização e lineage |
| `contact_candidates[].emails[]` | e-mails | candidato condicional a satellite/projeção; alto PII |
| `contact_candidates[].addresses[]` | endereços confirmados ou históricos provider | JSONB-first; projetar só via fluxo canônico de endereço |
| `contact_candidates[].relatives[]` | relações e telefones de relativos | JSONB-first; satellite opcional se houver produto de relationship search |
| `quality_and_counts` | contagens por subarray, parse status, drift flags | projeção operacional não sensível quando sem valores |
| `jsonb_residue` | campos provider não mapeados, drift, blocos desconhecidos | obrigatório para forward compatibility |

Regras de `additionalProperties` sugeridas:

- Envelope externo: `additionalProperties: false` para campos governados do wrapper.
- Blocos provider/raw/residue: `additionalProperties: true` com classificação `provider_residue` e drift auditável.
- Satellites normalizados: `additionalProperties: false` para DTOs publicados, mantendo `source_json_path` e `provider_event_ref`.

### 2.2 `realtor-evidence-envelope.v1` informado por Realtor

Finalidade: representar evidência de property/geography/market/comparables/valuation de Realtor sem torná-la fonte ontológica de propriedade ou área.

Famílias mínimas:

| Família | Shape esperado | Política |
| --- | --- | --- |
| `envelope` | provider slug, surface slug, captured_at/observed_at, source ref, request fingerprint redigido, schema version, pii class | colunas/projeções para filtro/auditoria |
| `anchor` | `canonical_property_ref`, `system_area_ref`, `sourcehub_session_ref` ou consulta/coordinate anchor redigida | obrigatório para interpretar evidence; não inferir truth só do payload |
| `provider_references` | property/listing/area/geo refs provider, permalink/href class sem valor | projetar refs estáveis quando usadas para replay/dedupe |
| `property_detail_evidence` | fatos físicos/listing/media/features/status | JSONB-first com projeções sancionadas para beds/baths/sqft/year/type/status/list price quando ancorado |
| `valuation_evidence` | current/historical/forecast/AVM/spot-offer/last-sale evidence | séries em JSONB; snapshot temporal sancionado em tabela quando usado em decisão |
| `comparable_evidence` | candidatos de busca/similares/recently-sold/map/nearby | JSONB-first; tabela de candidate evidence só com contrato downstream |
| `market_evidence` | métricas territoriais, hotness, DOM, medianas, ratios | ancorar em SystemArea; snapshots sancionados para métricas mínimas |
| `area_boundary_evidence` | boundary GeoJSON, center/radius, breakpoints, provider area refs | PostGIS para geometria aprovada; resíduo de apresentação em JSONB |
| `autocomplete_resolution_evidence` | sugestões de endereço/área | cache/evidence; não cria property/area sozinha |
| `media_and_contact_residue` | photos/galleries/advertisers/consumer contacts/lead blocks | JSONB classificado; alto PII/comercial; redaction fora do cofre |
| `jsonb_residue` | campos não mapeados, blocos instáveis, provider drift | obrigatório |

Regras de `additionalProperties` sugeridas:

- Wrapper canônico do envelope: `additionalProperties: false`.
- Subdocumentos de provider evidence/residue: `additionalProperties: true` com `schema_family`, `source_surface_slug`, `source_json_path` e drift tracking.
- DTOs normalizados publicados a SourceHub/Lead Finder: `additionalProperties: false` e campos opcionais explícitos por versão.

## 3. Candidatos de projeção

### 3.1 Projeções comuns a DirectSkip e Realtor

Promover para colunas/tabelas apenas quando passarem pelos sete gates da ADR: corpus observado, semântica aprovada por Matrix/LeadFinder, estabilidade, necessidade de query/join/FK/RLS/PostGIS/constraint, coerção segura, lineage durável e classificação privacy/PII.

Candidatos comuns:

- `provider_slug`.
- `surface_slug` / endpoint/list type.
- `captured_at` / `observed_at`.
- `payload_schema_version`.
- `provider_event_ref` / sourcehub ingress/session ref.
- `payload_hash` ou fingerprint redigido.
- `response_status` / parse status / result class.
- `pii_classification`.
- `canonical_property_ref`, `owner_ref`, `person_ref`, `system_area_ref` quando já resolvidos.
- contagens não sensíveis: número de contacts, phones, emails, relatives, candidates, comparables, media items, history events.

### 3.2 DirectSkip/contact satellites

Bons candidatos, sob cofre/controle de PII:

- contact satellite table/view para phones: normalized phone hash/token, phone type label, role (`contact` vs `relative`), rank/order, `source_json_path`, `provider_event_ref`, confidence/status se houver.
- email satellite table/view somente se houver dedupe/search/outreach: normalized email hash/token, source path, provider event.
- response result/status e counts para auditoria operacional.
- relação relative/contact-edge somente se produto exigir relationship search; caso contrário manter JSONB.

Não promover diretamente:

- nomes provider como owner truth;
- idade/deceased hints como fatos canônicos sem validação;
- confirmed addresses como property/address truth;
- relatives como household/ownership truth;
- labels provider de phone/email como enum canônico sem Matrix mapping.

### 3.3 Realtor/property detail evidence

Bons candidatos quando há `canonical_property_ref`:

- provider property/listing refs e surface.
- status provider normalizado como evidence, não status canônico final.
- facts físicos sancionados: beds, baths, sqft, lot sqft, year built, garage, property type/subtype.
- preço/list date/last sold date/last sold price como evidence temporal quando usados em filtros.
- primary media presence/counts, não URLs completas em artefatos públicos.

Não promover diretamente:

- advertiser/consumer contact blocks;
- full media/gallery/deep listing copy;
- permalink/href/URLs completas em docs ou projections públicas;
- provider location como criação automática de property.

### 3.4 Valuation evidence

Família recomendada: `valuation_evidence` dentro de Realtor envelope, com possível tabela `property_valuation_snapshot` quando sancionada.

Projeções candidatas:

- `canonical_property_ref`.
- `provider_slug` e valuation source class.
- `observed_at` e valuation effective date.
- value/low/high/confidence somente se aprovados e tipados.
- `valuation_kind`: current, historical, forecast, avm, spot_offer, last_sale_evidence.
- `provider_event_ref` e `source_json_path`.

Manter em JSONB:

- séries completas current/historical/forecast;
- múltiplas fontes/bandas internas;
- modelos AVM internos e campos instáveis;
- spot-offer residue.

### 3.5 Market evidence

Família recomendada: `market_evidence`, sempre ancorada a `system_area_ref` ou area anchor resolvido.

Projeções candidatas:

- `system_area_ref`.
- `provider_slug`.
- `observed_at`.
- median listing price, median sold price, median DOM, price per sqft quando sancionados.
- inventory/change metrics somente após contrato específico.

Manter em JSONB:

- hotness/badges/ranks provider-specific;
- ratios contra county/US typical property;
- payload achatado ou nested não sancionado;
- contexto de query/resolution quando não for âncora canônica.

Não anexar market evidence a property individual por zip/proximidade implícita.

### 3.6 Comparable evidence

Família recomendada: `comparable_evidence`, sem promoção automática a property.

Projeções candidatas se houver contrato de comp analysis:

- `anchor_property_ref` ou query anchor ref.
- `candidate_provider_ref` e listing ref.
- `surface_slug`: nearby, map, recently_sold, similar.
- `observed_at`.
- rank/order, distance/context bucket, status class.
- facts básicos do candidato para UI/analytics, sempre como evidence.
- `source_json_path` e `provider_event_ref`.

Manter em JSONB:

- arrays completos de candidatos;
- full candidate payloads;
- media/open-house/flags instáveis;
- request context detalhado e provider residue.

Promoção para property canônica exige fluxo separado de acquisition/dedupe.

### 3.7 Area boundary evidence

Projeções candidatas:

- `system_area_ref` obrigatório para update canônico.
- provider area/geo/slug refs.
- area type/state/centroid quando sancionados.
- `boundary_geom` em PostGIS após validação contra anchor.
- observed_at/provider/source lineage.

Manter em JSONB:

- GeoJSON bruto completo como evidence;
- breakpoints, zoom, radius, presentation fields;
- raw areas list e provider response envelope.

## 4. Classes sensíveis/PII

### 4.1 Classe P0/Pública segura

Pode aparecer em docs/schema sem valores reais:

- nomes de campos e famílias JSON;
- tipos JSON e cardinalidades;
- enum categories genéricas sem exemplos reais;
- contagens agregadas sem identificação;
- políticas de projection/residue.

### 4.2 Classe P1/Operacional baixa

Pode virar coluna interna se necessário, mas deve evitar exposição pública irrestrita:

- provider slug e surface slug;
- status/result class;
- schema version;
- captured_at/observed_at;
- counts por subarray;
- flags booleanas genéricas quando não reidentificantes.

### 4.3 Classe P2/Identificadores e localização sensíveis

Exige controle de acesso, redaction em docs e cautela em índices:

- provider property/listing/area IDs;
- permalinks/hrefs/URLs completas;
- request fingerprints/hashes de query;
- coordenadas exatas e centroids;
- endereço completo ou componentes com alta reidentificação;
- source refs correlacionáveis.

### 4.4 Classe P3/PII direta e comercial sensível

Não imprimir em artefatos; só cofre de ingestão/evidence com RLS/auditoria:

- nomes de pessoas/contatos/relatives/advertisers/agents;
- telefones;
- e-mails;
- full address values;
- idade, deceased hints e relationship hints;
- advertiser/consumer_advertiser/lead contact blocks;
- fotos/URLs completas quando correlacionáveis;
- payload bruto provider com combinações reidentificantes.

## 5. Política de JSONB residue

1. Todo provider event deve preservar payload/residue em JSONB imutável ou append-only, com hash/fingerprint, source ref, schema version e privacy class.
2. Nenhum path provider deve ser descartado apenas por não estar no DTO atual; campos desconhecidos entram em `jsonb_residue` e drift tracking.
3. Resíduo é lineage/evidence, não API pública. Publicação para clientes deve passar por DTO canônico redigido.
4. JSONB provider pode ter `additionalProperties: true`; envelopes/DTOs canônicos publicados devem ser fechados (`additionalProperties: false`) salvo extensão explicitamente versionada.
5. Projeções relacionais devem armazenar `provider_event_ref` e `source_json_path` para auditabilidade e replay.
6. GIN em JSONB só quando houver requisito real de busca ad hoc/review; não indexar payload grande cegamente.
7. Para geometry, extrair para PostGIS após validação; não depender de consultas geográficas sobre JSONB bruto.
8. Para séries temporais, usar tabela append-only de snapshots sancionados; JSONB carrega a série completa e campos provider-specific.
9. Para PII direta, preferir token/hash normalizado em projection e valor claro somente no cofre adequado, se permitido pela política do produto.
10. Docs, fixtures públicas e provas devem ser schema-only/sintéticas; nunca payloads reais com valores.

## 6. Recomendações para o registry desta issue

### 6.1 Schema families a criar/validar

- `contact-satellites-envelope.v1.schema.json`
  - wrapper fechado;
  - `provider_event_ref`, `anchor`, `contacts`, `satellites`, `quality`, `jsonb_residue`;
  - subfamilies para phone/email/address/relative/name hints;
  - classification obrigatória por subtree.

- `realtor-evidence-envelope.v1.schema.json`
  - wrapper fechado;
  - `anchor`, `provider_references`, `property_detail_evidence`, `valuation_evidence`, `market_evidence`, `comparable_evidence`, `area_boundary_evidence`, `autocomplete_resolution_evidence`, `jsonb_residue`;
  - exigir `surface_slug` para interpretar subshape;
  - permitir residue por surface.

- `projection-policy.v1.json`
  - incluir os sete gates da ADR;
  - registrar defaults: DirectSkip contact values são P3; Realtor advertiser/contact/media URLs são P3/P2; market metrics sancionadas podem ser P1/P2 conforme anchor; geometry é P2.

### 6.2 Projection defaults por família

| Família | Default | Exceção de promoção |
| --- | --- | --- |
| DirectSkip status/counts | projetar | desde que sem PII |
| DirectSkip phone/email values | JSONB/cofre | token/hash/projeção interna se dedupe/outreach exigir |
| DirectSkip relatives | JSONB | edge satellite se houver contrato de relationship search |
| Realtor provider refs | projetar internamente | redigir em docs/API pública |
| Realtor property facts básicos | projetar quando ancorado | apenas campos sancionados por Matrix/LeadFinder |
| Realtor valuation séries | JSONB | snapshot temporal sancionado |
| Realtor market | JSONB | snapshot territorial sancionado com SystemArea anchor |
| Realtor comparables | JSONB | candidate evidence table com contrato downstream |
| Realtor boundary | JSONB + PostGIS | PostGIS só com SystemArea anchor validado |
| Advertiser/contact/media deep blocks | JSONB classificado | não publicar; projeções só redigidas/tokenizadas |

## 7. Riscos e gates

- Risco: transformar provider IDs em chaves canônicas. Gate: sempre distinguir provider ref de public_id/FK canônica.
- Risco: vazar PII em fixtures. Gate: fixtures schema-only/sintéticas e revisão de PII antes de commit.
- Risco: perder auditabilidade ao materializar projections. Gate: `provider_event_ref` + `source_json_path` obrigatório.
- Risco: JSONB sem governança virar dump opaco. Gate: envelope versionado, schema family, privacy class, drift/residue policy.
- Risco: comparables criarem properties automaticamente. Gate: promotion separada por acquisition/dedupe.
- Risco: market ser anexado a property sem território. Gate: `system_area_ref` ou area anchor resolvido.

## 8. Resultado executivo

DirectSkip e Realtor devem informar envelopes de evidence separados, não tabelas canônicas provider-shaped. O envelope DirectSkip é uma família de contact satellites com PII forte e projeções internas restritas para reachability/dedupe. O envelope Realtor é uma família ampla de property/geography/valuation/market/comparable evidence, com projeções apenas para âncoras, refs, snapshots e fatos sancionados. Em ambos os casos, JSONB residue é obrigatório, versionado, classificado por sensibilidade e sempre conectado às projeções por lineage.
