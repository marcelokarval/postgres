# 08 — Worker A: revisão dos envelopes core LFG property/owner/taxonomy

Status: concluído
Escopo: recomendações para JSONSchema envelopes canônicos de `property`, `owner` e `taxonomy/tag/label` no slice 15.
Restrições cumpridas: sem DDL final, sem PII, sem web/MCP, sem valores raw de payloads.

## Fontes de contexto lidas

- `docs/issues/14-prop4you-json-curation-pg18-jsonb-strategy/12-adr-pg18-jsonb-first-canonical-modeling.md`
- `docs/issues/14-prop4you-json-curation-pg18-jsonb-strategy/10-legacy-tags-labels-inventory.md`
- `docs/issues/14-prop4you-json-curation-pg18-jsonb-strategy/13-next-slice-gate-jsonschema-envelope-minimum.md`
- `docs/issues/13-prop4you-lfg-system-ddl-json-readiness/11-system-ddl-json-readiness-matrix.md`
- `docs/issues/15-prop4you-lfg-canonical-jsonschema-envelope-registry/01-prd.md`
- `docs/issues/15-prop4you-lfg-canonical-jsonschema-envelope-registry/02-tasks.md`

## Síntese executiva

O envelope core deve preservar a decisão JSONB-first do ADR:

```text
JSONB para evidência, resíduos e envelope canônico governado.
Relacional para identidade durável, edges, constraints, PostGIS, temporalidade e projeções de alto valor.
```

A recomendação é criar envelopes pequenos, estáveis e explícitos, com campos mínimos de identidade/linhagem/classificação e objetos JSONB permitidos para payload canônico controlado. O schema não deve tentar reproduzir todos os campos legados ou de providers; deve organizar o mínimo canônico que habilita a próxima etapa de projeções.

Separação obrigatória:

- Property/owner truth pertence ao Lead Finder canonical graph, não a Realtor/DirectSkip isoladamente.
- SourceHub publica DTO/linhagem; Matrix governa significado/mapeamento; LeadFinder materializa o grafo canônico.
- Taxonomia sistêmica é read-only/governada; workspace tags/list/status são overlays futuros e não entram como verdade sistêmica.
- Situações são fatos estruturados, não tags livres.

## Regras globais recomendadas para os envelopes

### Metadados mínimos comuns

Todos os envelopes devem aceitar um bloco comum de controle:

| Campo | Tipo recomendado | Obrigatório | Observação |
| --- | --- | --- | --- |
| `schema_version` | string const/pattern, ex. `v1` | sim | Versão do envelope, não versão do provider. |
| `envelope_kind` | enum | sim | `property`, `owner`, `taxonomy`. |
| `canonical_id` | string uuid/ref interna | recomendado | Pointer canônico quando já materializado; pode ser ausente em staging. |
| `sourcehub_record_refs` | array de refs/hashes não-PII | sim | Linhagem para raw restrito sem publicar payload. |
| `matrix_mapping_refs` | array de refs | recomendado | Conecta significado aprovado/candidato. |
| `quality` | object | recomendado | Confiança, completude e flags de revisão sem PII. |
| `privacy_class` | enum | sim | Ao menos `public_safe`, `restricted`, `pii_sensitive`. |
| `observed_at` / `updated_at` | string date-time | recomendado | Temporalidade do envelope/candidato, não necessariamente do fato real. |
| `residue` | object | opcional | JSONB controlado para campos não promovidos. |

### Política de `additionalProperties`

Recomendação padrão:

```text
additionalProperties: false no topo de cada envelope e nos objetos canônicos principais.
additionalProperties: true somente em objetos explicitamente designados como residue/evidence/debug_review, com limites de privacidade e sem exposição pública.
```

Justificativa:

- Top-level fechado evita drift silencioso de contrato.
- Objetos canônicos fechados permitem validação e documentação de caminho JSON.
- Resíduo controlado preserva JSONB-first sem transformar provider shape em verdade canônica.
- Qualquer caminho em `residue` só vira projeção após os 7 gates do ADR.

### Objetos JSONB permitidos globalmente

Estes objetos podem existir como JSONB dentro das futuras tabelas/staging, mas não devem ser expostos raw em API pública:

| Objeto | Uso | additionalProperties |
| --- | --- | --- |
| `lineage` | refs para raw/source/DTO/mapping, hashes, source family, sem payload raw | false para chaves conhecidas; arrays de refs fechados |
| `quality` | score, confidence, completeness, conflict flags, review status | false |
| `evidence_summary` | resumo não-PII de evidência observada e contagens por source family | false |
| `residue` | paths ainda não promovidos, sanitizados | true, restrito |
| `review` | motivo de necessidade humana/Matrix, warnings, gap codes | false |
| `projection_hints` | candidatos declarativos a generated column/index/table, sem virar DDL ainda | false |

## Envelope `property-envelope.v1.schema.json`

### Responsabilidade

Representar a propriedade canônica mínima do Lead Finder: identidade de imóvel/endereço/localização/detalhes essenciais, com linhagem e resíduos. Não deve ser um espelho de Realtor, county ou legacy Django.

### Campos mínimos recomendados

| Campo | Tipo | Obrigatório | Política |
| --- | --- | --- | --- |
| `schema_version` | string | sim | `v1`. |
| `envelope_kind` | const | sim | `property`. |
| `canonical_property_ref` | string | recomendado | Ref interna estável quando já existe; não precisa codificar regra final de ID. |
| `identity` | object | sim | Âncoras de identidade de imóvel. |
| `address` | object | sim | Endereço canônico normalizado mínimo. |
| `geography` | object | opcional | Coordenadas/geom refs/parcel boundary refs quando aprovados. |
| `details` | object | opcional | Características físicas estáveis. |
| `legal` | object | opcional | APN/parcel/legal/subdivision/document refs quando seguros. |
| `situations` | array | opcional | Fatos estruturados ativos/históricos resumidos; tags derivadas ficam em taxonomy. |
| `source_lineage` | object | sim | SourceHub/Matrix refs, source families, hashes. |
| `quality` | object | recomendado | Confiança e revisão. |
| `privacy_class` | enum | sim | Em geral `restricted` quando combina dados sensíveis. |
| `residue` | object | opcional | Campos sanitizados não promovidos. |

### Estrutura sugerida por objeto

`identity`:

- `canonical_key_parts`: array de nomes de componentes, não valores raw em docs.
- `parcel_ref`: string opcional.
- `apn_ref`: string opcional.
- `external_record_refs`: array de refs/hashes.
- `identity_confidence`: number 0..1.
- `conflict_status`: enum `none`, `possible_duplicate`, `conflicting_evidence`, `needs_review`.

`address`:

- `line1_normalized`: string opcional.
- `city`: string opcional.
- `state`: string opcional, pattern de estado quando aplicável.
- `postal_code`: string opcional.
- `county`: string opcional.
- `country`: string opcional default lógico `US` apenas se o corpus confirmar.
- `address_hash`: string opcional para comparação sem expor valor em docs/proofs.
- `normalization_status`: enum `raw_only`, `normalized`, `verified`, `conflict`.

`geography`:

- `point`: object opcional com `longitude`, `latitude` numéricos; candidato forte a PostGIS.
- `parcel_boundary_ref`: string opcional para geometria armazenada/projetada fora do envelope.
- `geocode_precision`: enum `parcel`, `rooftop`, `street`, `zip`, `unknown`.

`details`:

- `property_type`: string/enum futura, governada por taxonomy.
- `year_built`, `bedrooms`, `bathrooms`, `living_area_sqft`, `lot_area_sqft`: opcionais e tipados.
- `features`: array opcional de strings normalizadas, mas não promover como taxonomy sem governança.
- `listing_status`: string opcional em residue/details, não canonical status ainda.

`legal`:

- `legal_description_ref`: string opcional, preferir ref/hash se sensível/longo.
- `subdivision`: string opcional.
- `document_refs`: array de refs não-PII.

`situations`:

- `situation_type`: enum derivado de vocabulário governado, ex. `foreclosure`, `pre_foreclosure`, `tax_lien`, etc.
- `situation_status`: enum `active`, `resolved`, `cancelled`.
- `source_ref`: string.
- `date_refs`/datas opcionais conforme segurança.
- `confidence`: number.

### Objetos JSONB permitidos no property envelope

- `identity`, `address`, `geography`, `details`, `legal`, `situations`, `source_lineage`, `quality`, `residue`, `projection_hints`.
- Não permitir objetos provider-native como `realtor_payload`, `county_payload`, `directskip_payload` dentro do envelope core; esses pertencem a evidence envelopes/raw restritos.

### Projection candidates — property

Candidatos de projeção inicial, ainda sem DDL final:

| Caminho | Motivo |
| --- | --- |
| `canonical_property_ref` | join/lookup/edge. |
| `identity.parcel_ref` / `identity.apn_ref` | dedupe, uniqueness candidata, source matching. |
| `address.city`, `address.state`, `address.postal_code`, `address.county` | filtros/search comuns, API futura. |
| `address.address_hash` | dedupe sem depender de string raw. |
| `geography.point` | PostGIS, mapa, distância. |
| `details.property_type` | filtro semântico, taxonomy. |
| `details.year_built`, `bedrooms`, `bathrooms`, `living_area_sqft`, `lot_area_sqft` | filtros/ordenamento de alto valor se estáveis. |
| `situations[].situation_type/status` | busca Lead Finder e materialização de tags sistêmicas derivadas. |
| `quality.confidence`, `quality.conflict_status` | filas de revisão/materialização. |

## Envelope `owner-envelope.v1.schema.json`

### Responsabilidade

Representar owner/party canônico mínimo e sua relação com propriedade. DirectSkip/contact enrichment pode contribuir evidência, mas não define sozinho a verdade de owner. O envelope deve evitar expor PII em docs/proofs e permitir classificação/linhagem/revisão.

### Campos mínimos recomendados

| Campo | Tipo | Obrigatório | Política |
| --- | --- | --- | --- |
| `schema_version` | string | sim | `v1`. |
| `envelope_kind` | const | sim | `owner`. |
| `canonical_owner_ref` | string | recomendado | Ref interna de entity/party. |
| `entity` | object | sim | Identidade canônica mínima. |
| `ownership_edges` | array | recomendado | Relações owner-property. |
| `mailing_address` | object | opcional | Pode ser PII/restricted; docs sem valores. |
| `contact_summary` | object | opcional | Apenas contagens/status agregados; contato detalhado fica no envelope contact-satellites. |
| `resolution` | object | recomendado | Estado de owner resolution/adjudicação. |
| `source_lineage` | object | sim | SourceHub/Matrix/skiptrace refs sem payload. |
| `quality` | object | recomendado | Confiança, conflitos, review. |
| `privacy_class` | enum | sim | Normalmente `pii_sensitive` para owner. |
| `residue` | object | opcional | Campos não promovidos e sanitizados. |

### Estrutura sugerida por objeto

`entity`:

- `entity_type`: enum `person`, `company`, `trust`, `unknown`.
- `display_name_hash`: string opcional para dedupe/proof sem revelar nome.
- `name_components_present`: object booleano (`first`, `last`, `company`, etc.) sem valores em docs.
- `normalized_name_ref`: string opcional se houver armazenamento restrito.
- `entity_confidence`: number.
- `conflict_status`: enum `none`, `possible_match`, `conflicting_identity`, `insufficient_evidence`, `needs_review`.

`ownership_edges`:

- `property_ref`: string.
- `ownership_type`: enum compatível com inventário (`owner`, `co_owner`, `investor`, `trust`, `llc_member`, `unknown`).
- `role_type`: enum governado (`owner`, `mortgagor`, `grantee`, etc.) quando aplicável.
- `percent_interest`: number opcional.
- `effective_date_ref` ou datas seguras opcionais.
- `source_ref`: string.
- `confidence`: number.

`mailing_address`:

- Mesmo shape básico de address, com `address_type`: `mailing`, `residential`, `commercial`, `po_box`, `unknown`.
- `address_hash` recomendado.
- Marcar `privacy_class` local como `pii_sensitive` quando presente.

`contact_summary`:

- `phone_count`, `email_count`, `mailing_address_count`.
- `has_reachable_phone`, `has_deliverable_email`: boolean opcional, só se derivado por política.
- `best_contact_ref`: string opcional, sem número/email.
- `dnc_or_suppression_present`: boolean opcional.

`resolution`:

- `case_ref`: string opcional.
- `status`: enum inspirado no inventário (`open`, `candidate_generated`, `decided`, `materialized`, `needs_ai`, `needs_human`, `superseded`, `closed`).
- `decision`: enum (`same_entity`, `possible_match`, `related_but_distinct`, `distinct_entity`, `conflicted`, `insufficient_evidence`).
- `adjudicator`: enum (`deterministic_rules`, `score_engine`, `ai_high_capacity`, `human_review`) quando houver.

### Objetos JSONB permitidos no owner envelope

- `entity`, `ownership_edges`, `mailing_address`, `contact_summary`, `resolution`, `source_lineage`, `quality`, `residue`, `projection_hints`.
- Não embutir telefone/email completos; isso pertence a `contact-satellites-envelope` e/ou tabelas restritas futuras.
- Não embutir provider raw skiptrace payload.

### Projection candidates — owner

| Caminho | Motivo |
| --- | --- |
| `canonical_owner_ref` | join/identity. |
| `entity.entity_type` | filtro e resolução. |
| `entity.display_name_hash` | dedupe sem publicar nome. |
| `entity.conflict_status` | filas de revisão. |
| `ownership_edges[].property_ref` | edge owner-property. |
| `ownership_edges[].ownership_type` | busca/segmentação. |
| `ownership_edges[].role_type` | análise legal/party graph. |
| `mailing_address.address_hash`, `state`, `postal_code` | matching e filtros restritos. |
| `contact_summary.phone_count/email_count` | readiness operacional sem PII. |
| `resolution.status/decision/adjudicator` | workflow e auditoria. |
| `quality.confidence` | gate de materialização. |

## Envelope `taxonomy-envelope.v1.schema.json`

### Responsabilidade

Representar vocabulário sistêmico governado para Lead Finder: property type, source list lineage, situation types/statuses, system property tags/labels derivados e owner/phone/email tag families. O envelope não é workspace registry nem design final de tag-groups.

### Separação semântica obrigatória

| Família | Owner semântico | Política |
| --- | --- | --- |
| `lead_situation_type` | Lead Finder/Matrix | Fato estruturado; pode materializar tag sistêmica derivada quando ativo e sancionado. |
| `source_list_type` | SourceHub lineage/search | Não vira tag sistêmica automaticamente. |
| `system_property_tag` | Lead Finder materializer | Read-only; derivado/sancionado, não criado pelo workspace. |
| `system_property_label` | Lead Finder/Matrix | Label sistêmica controlada, não CRM status. |
| `owner_tag`, `phone_tag`, `email_tag` | Lead Finder/contact policy | Só após contrato de semântica; evitar seeds prematuros. |
| `workspace_tag/list/status` | Futuro workspace | Fora do envelope core sistêmico. |

### Campos mínimos recomendados

| Campo | Tipo | Obrigatório | Política |
| --- | --- | --- | --- |
| `schema_version` | string | sim | `v1`. |
| `envelope_kind` | const | sim | `taxonomy`. |
| `vocabulary_version` | string | sim | Versão governada do vocabulário. |
| `families` | array | sim | Famílias taxonômicas aceitas. |
| `terms` | array | sim | Termos/slugs governados ou candidatos. |
| `aliases` | array | recomendado | Alias catalog Matrix/Lead Finder. |
| `derivation_rules` | array | recomendado | Ex.: active situation -> system_property_tag quando sancionado. |
| `workspace_bridge_policy` | object | sim | Read-only bridge, não ownership. |
| `source_lineage` | object | recomendado | Genome/baseline/matrix refs. |
| `quality` | object | recomendado | Status de aprovação, conflitos. |
| `residue` | object | opcional | Candidatos não aprovados. |

### Estrutura sugerida

`families[]`:

- `family_slug`: enum inicial `property_type`, `source_list_type`, `lead_situation_type`, `situation_status`, `system_property_tag`, `system_property_label`, `owner_tag`, `phone_tag`, `email_tag`.
- `semantic_owner`: enum `leadfinder`, `matrix`, `sourcehub`, `contact_policy`.
- `is_workspace_owned`: boolean sempre `false` neste envelope.
- `is_public_api_safe`: boolean, default `false` até API/RLS futura.
- `additionalProperties`: false.

`terms[]`:

- `family_slug`.
- `term_slug`.
- `display_label` opcional.
- `status`: enum `candidate`, `approved`, `deprecated`, `rejected`, `legacy_compat`.
- `risk_class`: enum `low`, `medium`, `high`, `unknown`.
- `source_kind`: enum `situation`, `source_lineage`, `matrix_mapping`, `legacy_compat`, `provider_evidence`, `manual_governance`.
- `canonicalizes_to`: string opcional para plural/synonym handling, ex. manter risco `probates` vs `probate` sem auto-normalizar.
- `notes_code`: string opcional, sem dados raw.

`aliases[]`:

- `alias`.
- `canonical_family_slug`.
- `canonical_term_slug` opcional.
- `transform`: enum `strip`, `slugify`, `titlecase`, `none` ou array controlado.
- `approval_status`.

`derivation_rules[]`:

- `rule_slug`.
- `from_family`.
- `to_family`.
- `condition`: string controlada, ex. `situation_status=active`.
- `requires_matrix_approval`: boolean.
- `auto_materialize`: boolean default `false` salvo regra sancionada.

`workspace_bridge_policy`:

- `workspace_can_reference_system_terms`: true.
- `workspace_can_create_system_terms`: false.
- `workspace_tags_are_overlays`: true.
- `lf_tag_type_is_bridge_only`: true.
- `do_not_seed_system_terms_into_workspace_registry`: true.

### Vocabulários iniciais observados, com cautela

Não são seeds finais. São candidatos/compatibilidade a serem validados no schema/policy:

- `lead_situation_type`: `appt_of_sub_trustee`, `foreclosure`, `pre_foreclosure`, `tax_lien`, `tax_sale`, `probate`, `heirship`, `divorce`, `bankruptcy`, `code_violation`, `vacant`, `other`.
- `situation_status`: `active`, `resolved`, `cancelled`.
- `property_type`: exemplos de inventário incluem `single_family`, `multi_family`, `condo`, `townhouse`, `manufactured`, `land`, `commercial`, `industrial`, `mixed_use`, `other`; há divergências legadas como `apartment`, `mobile_home`, `vacant_land` que devem entrar como compat/candidate, não substituir o vocabulário final.
- `source_list_type`: exemplos estruturais incluem `pre_foreclosure`, `skip_trace_contact_discovery`, `loan_modification`, `probates`, `divorce`, `property_comparables`, `manual_property`, `eviction`, `tax_sale`, `address_discovery`, `property_enrichment`; manter como lineage/search e não tag automática.

### Objetos JSONB permitidos no taxonomy envelope

- `families`, `terms`, `aliases`, `derivation_rules`, `workspace_bridge_policy`, `source_lineage`, `quality`, `residue`, `projection_hints`.
- Não incluir workspace CRM registries (`PropertyTagRegistry`, `PropertyListRegistry`, `PropertyStatusRegistry`) como termos sistêmicos.

### Projection candidates — taxonomy

| Caminho | Motivo |
| --- | --- |
| `vocabulary_version` | auditoria/replay. |
| `families[].family_slug` | lookup/constraint futura. |
| `families[].semantic_owner` | boundary enforcement. |
| `terms[].family_slug`, `terms[].term_slug` | unicidade/lookup. |
| `terms[].status` | promoção/revisão. |
| `terms[].risk_class` | auto-apply marker policy. |
| `terms[].canonicalizes_to` | normalização controlada sem apagar alias. |
| `aliases[].alias` -> canonical | Matrix/search compatibility. |
| `derivation_rules[].rule_slug` | materializer/auditoria. |
| `workspace_bridge_policy.*` | guardrails contra mistura workspace/system. |

## Política de projeção transversal

Aplicar os 7 gates do ADR antes de qualquer caminho virar coluna/tabela/index:

1. observado em corpus representativo;
2. significado aprovado por Matrix/LeadFinder;
3. estável entre sources ou explicitamente provider-specific;
4. necessário para query, join, filtro, ordenação, unicidade, FK, RLS, PostGIS ou constraint operacional;
5. cast/coerção segura;
6. linhagem raw durável;
7. classificação de privacidade/PII concluída.

### Candidatos fortes imediatos

- Property identity/address/geography anchors.
- Owner/property edge refs e owner entity type/conflict status.
- Situation type/status como fatos e materialização de system property tags sancionadas.
- Taxonomy family/term/status/risk class.
- Quality/conflict/review status para filas de materialização.

### Candidatos fracos/deferidos

- `features` de property details como taxonomy.
- `listing_status` provider/native como status canônico.
- `source_list_type` virando system tag automaticamente.
- Workspace labels como lead types.
- Phone/email tags antes do envelope contact-satellites e DirectSkip review.
- Provider-native evidence paths sem envelope próprio.

## Non-goals desta revisão

- Não criar DDL final, tabelas, constraints ou registry rows.
- Não definir design final de tag-groups ou seeds de vocabulário sistêmico.
- Não implementar workspace tags/lists/status/snapshots.
- Não expor raw JSONB, payloads provider-native ou PII.
- Não criar API pública/RLS facade.
- Não decidir IDs finais (`uuid7`, ref prefix, etc.) além de recomendar refs estáveis.
- Não modelar DirectSkip/Realtor evidence envelopes detalhados; isso pertence aos outros workers.
- Não transformar nomes iguais em semântica igual entre CRM, score, situação e source lineage.

## Riscos e guardrails

1. `source_list_type_slug` deve permanecer linhagem/search, não tag canônica automática.
2. Workspace tags/lists/status são overlays do usuário; não podem preencher lacunas da taxonomia sistêmica.
3. Situações ativas podem derivar `system_property_tag_slugs`, mas apenas por materializer sancionado.
4. `probates` vs `probate`, `tax_delinquent` vs `tax_lien/tax_sale`, `high_equity` e `absentee_owner` mostram risco de normalização por aparência.
5. Owner envelope é PII-sensitive por padrão; docs/proofs devem usar refs/hashes/contagens, não valores.
6. `additionalProperties: true` fora de `residue` cria drift e deve ser evitado.

## Recomendação final para Thor/T5

Para os três schemas core, usar top-level fechado com blocos comuns (`schema_version`, `envelope_kind`, `source_lineage`, `quality`, `privacy_class`, `residue`) e reservar extensibilidade apenas em `residue` restrito. O `projection-policy.v1.json` deve registrar os candidatos acima como `candidate` ou `deferred`, nunca como DDL implícita.

A ordem segura de implementação dos arquivos JSONSchema é:

1. `taxonomy-envelope.v1.schema.json`, porque governa enums/famílias usadas por property/owner.
2. `property-envelope.v1.schema.json`, com situações estruturadas e refs para taxonomy.
3. `owner-envelope.v1.schema.json`, com owner/property edges e contato apenas resumido.

Nenhum desses envelopes deve publicar PII ou provider raw; todo caminho sensível deve apontar para refs/hashes e lineage restrita.
