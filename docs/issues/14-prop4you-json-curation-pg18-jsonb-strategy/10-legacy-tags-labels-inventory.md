# Worker C — Inventário legado de tags/labels/status/list registries

Status: concluído
Escopo: inventariar vocabulários e registries legados antes do desenho de tag-groups.
Regra de segurança: sem DDL, sem seed novo, sem dados PII. Este arquivo registra apenas nomes estruturais, slugs/taxonomias de produto e referências de código/teste.

## Fontes analisadas

Raiz principal do legado:

- `/home/marcelo-karval/Backup/Projetos/prop4you/prop4you-inertia/backend/src/domains/real_estate`
- `/home/marcelo-karval/Backup/Projetos/prop4you/prop4you-inertia/backend/src/apps/system/lead_finder`
- `/home/marcelo-karval/Backup/Projetos/prop4you/prop4you-inertia/backend/src/apps/public/lead_finder`

Arquivos-chave lidos:

- `domains/real_estate/models/workspace_registry.py`
- `domains/real_estate/models/workspace_crm.py`
- `domains/real_estate/models/workspace_tag_base.py`
- `domains/real_estate/models/situation_models.py`
- `domains/real_estate/models/canonical_graph_overlays.py`
- `domains/real_estate/models/lead_score_models.py`
- `domains/real_estate/models/lead_intelligence_models.py`
- `domains/real_estate/models/legacy_simple_property.py`
- `domains/real_estate/models/canonical_party_graph.py`
- `domains/real_estate/models/owner_resolution_case.py`
- `domains/real_estate/models/owner_resolution_decision.py`
- `domains/real_estate/models/owner_resolution_evidence.py`
- `domains/real_estate/services/tag_registry_service.py`
- `domains/real_estate/services/property_status_service.py`
- `domains/real_estate/services/property_list_service.py`
- `domains/real_estate/management/commands/seed_registry_data.py`
- `domains/real_estate/tests/test_tag_registry_service.py`
- `apps/system/lead_finder/contracts.py`
- `apps/system/lead_finder/operator_search.py`
- `apps/system/lead_finder/artifacts/lead_finder_default_genome.lf_default.v1.json`
- `apps/system/lead_finder/tests/test_baseline.py`
- `apps/system/lead_finder/tests/test_operator_search_boundary.py`
- `apps/public/lead_finder/contracts.py`
- `apps/public/lead_finder/presenters.py`
- `apps/public/lead_finder/api_queries.py`
- `apps/public/lead_finder/tests/test_presenters.py`
- `apps/public/lead_finder/tests/test_map_payload_contract.py`

## Conclusão curta

Há duas famílias que o desenho futuro de tag-groups não deve misturar:

1. System taxonomy / Lead Finder inventory semantics:
   - fatos e taxonomias canônicas vindos de Lead Finder/Matrix/SourceHub;
   - `PropertySituation.situation_type` e `situation_status`;
   - materialização operacional `system_property_tag_slugs` derivada de situações ativas;
   - `source_list_type_slug` como linhagem de origem, não automaticamente como lead taxonomy;
   - genome/baseline com campos `source_list_type`, `lead_situation_type`, `system_property_tag`, `system_property_label`, `owner_tag`, `phone_tag`, `email_tag`.

2. Workspace tags/lists/statuses:
   - tags, listas e status pertencentes ao usuário/workspace;
   - registries `PropertyTagRegistry`, `PropertyStatusRegistry`, `PropertyListRegistry`;
   - CRM local `PropertyTag`, `PropertyList`, `SavedProperty.tags/lists`;
   - seeds de desenvolvimento como `Hot Lead`, `Follow Up`, `Available`, etc.

O legado já contém guardrails recentes contra promover workspace tags para taxonomia sistêmica. O risco principal é reintroduzir esse acoplamento por seed prematuro ou por usar nomes de tags do workspace como se fossem grupos canônicos.

## Inventário — workspace-facing registries

### `PropertyTagRegistry` (`real_estate_tag_registry`)

Modelo: `domains/real_estate/models/workspace_registry.py`.

Natureza: registry subscriber-facing de tags, não fonte de verdade da taxonomia sistêmica.

Campos relevantes:

- `user`: dono do workspace.
- `name`, `slug`, `description`, `color`, `icon`.
- `origin`: enum `TagOriginChoices`.
- `category`: enum `TagCategoryChoices`.
- `lf_tag_type`: ponte de compatibilidade para slug sistêmico; o próprio help text diz que não torna o registry source of truth.
- `usage_count`, `last_used_at`.

Vocabulários estruturais:

- `TagOriginChoices`: `lead_finder`, `user`, `system`.
- `TagCategoryChoices`: `property`, `contact`, `phone`, `email`, `activity`, `custom`.

Serviço: `TagRegistryService`.

Regras observadas:

- Máximo de 100 tags customizadas por usuário.
- Usuário só cria diretamente origem `user`.
- Tags `system`/`lead_finder`, quando existentes, são read-only/reference tags.
- `get_user_registry()` ainda retorna bloco chamado `system_tags`, mas o comentário indica resíduo de compatibilidade, não ownership semântico.
- `get_or_create_from_lead_finder()` e `PropertyTagRegistry.get_or_create_from_lf()` criam/adaptam reference tags por usuário; isto é bridge, não authoring.

Cores default legadas em `TagRegistryService.DEFAULT_TAG_COLORS`:

- `foreclosure`, `pre_foreclosure`, `probate`, `tax_lien`, `tax_delinquent`, `high_equity`, `absentee_owner`, `vacant`.
- `hot_lead`, `cold_lead`, `contacted`, `follow_up`, `qualified`, `not_interested`.

Observação: esses slugs misturam situações sistêmicas, heurísticas de lead score e status/atividades de workspace. Não devem ser transformados automaticamente em grupos finais.

### `PropertyStatusRegistry` (`real_estate_status_registry`)

Modelo: `domains/real_estate/models/workspace_registry.py`.

Natureza: pipeline/status customizável por usuário.

Campos relevantes:

- `user`, `name`, `description`, `color`.
- `ordering`.
- `is_default`.
- `is_closed`.

Defaults em `PropertyStatusService.DEFAULT_STATUSES`:

- `Available` (`is_default=true`, `ordering=100`).
- `Under Contract` (`ordering=200`).
- `Sold` (`is_closed=true`, `ordering=300`).
- `Archived` (`is_closed=true`, `ordering=400`).

Separação: isto é CRM/workspace lifecycle. Não é situação legal/canônica do imóvel.

### `PropertyListRegistry` (`real_estate_list_registry`)

Modelo: `domains/real_estate/models/workspace_registry.py`.

Natureza: listas salvas/workspace, incluindo listas smart e hot lists.

Campos relevantes:

- `user`, `name`, `description`, `color`, `icon`.
- `list_type`, `is_hot_list`, `is_default`.
- `smart_filter_criteria`, `auto_refresh`, `last_refreshed_at`.
- `property_count`, `sort_order`.

Vocabulário `ListTypeChoices`:

- `standard`
- `smart`
- `hot`
- `archive`

Default criado por `PropertyListRegistry.get_or_create_default()` / `PropertyListService.ensure_default_list()`:

- `All Properties`.

Seed dev em `seed_registry_data.py`:

- `Hot Leads` (`is_hot_list=true`).
- `Follow Up`.
- `Archive` (`list_type=archive`).

Separação: listas são organização workspace, não source list taxonomy de SourceHub/Lead Finder.

## Inventário — workspace CRM direto

### `PropertyList` (`real_estate_property_list`)

Modelo: `domains/real_estate/models/workspace_crm.py`.

Campos relevantes:

- `owner`, `name`, `description`, `color`, `icon`.
- `is_default`.
- `list_type`: enum `standard`, `smart`.
- `smart_filter_criteria`, `last_refreshed_at`, `auto_refresh`.

Docstring cita exemplos de nomes de lista: `Hot Leads`, `Follow Up`, `Cash Buyers`. São exemplos de organização do usuário; não vocabulário canônico.

### `PropertyTag` (`real_estate_property_tag`)

Modelo: `domains/real_estate/models/workspace_crm.py`, herdando `WorkspaceOwnedTag`.

Campos herdados/relevantes:

- `owner`.
- campos de `BaseTagModel` via herança, usados como `name`, `slug`, `category` etc.
- `default_category = property`.

Docstring cita exemplos de tags: `Priority`, `Contacted`, `Needs Follow-up`. São labels workspace.

### `SavedProperty` (`real_estate_saved_property`)

Modelo: `domains/real_estate/models/workspace_crm.py`.

Campos relevantes:

- `user`, `property`.
- M2M `lists` para `PropertyList`.
- M2M `tags` para `PropertyTag`.
- `notes`, `save_cost_usd`.

Separação: `SavedProperty.tags` e `SavedProperty.lists` são overlays do usuário sobre propriedade canônica.

## Inventário — system taxonomy / Lead Finder

### `PropertySituation` (`real_estate_property_situation`)

Modelo: `domains/real_estate/models/situation_models.py`.

Natureza: situação temporal/legal/financeira; não é tag livre.

Campos relevantes:

- `situation_type`: enum `SituationType`.
- `situation_status`: enum `SituationStatus`.
- `date_added`, `date_filed`, `date_scheduled`, `date_resolved`.
- `document_id`, `case_number`.
- `situation_data` JSON.
- `data_source`, `source_reference`, `confidence_score`.

Vocabulário `SituationType`:

- `appt_of_sub_trustee`
- `foreclosure`
- `pre_foreclosure`
- `tax_lien`
- `tax_sale`
- `probate`
- `heirship`
- `divorce`
- `bankruptcy`
- `code_violation`
- `vacant`
- `other`

Vocabulário `SituationStatus`:

- `active`
- `resolved`
- `cancelled`

Uso observado em `apps/system/lead_finder/operator_search.py`:

- Busca situações não deletadas e `situation_status=active`.
- `active_situation_types` é coletado de `situation_type`.
- `system_property_tag_slugs` é materializado como cópia dos `active_situation_types`.
- `system_property_label_slugs`, `owner_tag_slugs`, `phone_tag_slugs`, `email_tag_slugs` ainda aparecem como listas vazias no bloco materializado.

### Lead Finder materialized taxonomy contract

Arquivo: `apps/system/lead_finder/contracts.py`.

`LeadFinderMaterializedTaxonomyBlock` expõe:

- `property_type`
- `active_situation_types`
- `active_situation_statuses`
- `source_list_type_slug`
- `system_property_tag_slugs`
- `system_property_label_slugs`
- `owner_tag_slugs`
- `phone_tag_slugs`
- `email_tag_slugs`

Regras documentadas no próprio contrato:

- Valores no bloco são inventory/search semantics, não CRM overlays.
- `source_list_type_slug` é útil para linhagem/search, mas não vira automaticamente lead taxonomy sem materializer sancionado.
- `system_property_tag_slugs` é a primeira família derivada sancionada além das situações raw, materializada de situações sistêmicas ativas.

### Lead Finder default genome / Matrix baseline

Arquivo: `apps/system/lead_finder/artifacts/lead_finder_default_genome.lf_default.v1.json`.

Família `systemic_taxonomy` observada:

- `property_type`
- `source_list_type`
- `lead_situation_type`
- `system_property_tag`
- `system_property_label`
- `owner_tag`
- `phone_tag`
- `email_tag`

Aliases estruturais relevantes:

- `list_type` -> `source_list_type`.
- `list_type_slug` -> `source_list_type_slug` no alias catalog, e alias de `source_list_type`.
- `lead_type` -> `lead_situation_type`.
- `situation_type` -> `lead_situation_type`.
- `property_tag` -> `system_property_tag`.
- `property_label` -> `system_property_label`.
- `ownership_tag` -> `owner_tag`.
- `contact_phone_tag` -> `phone_tag`.
- `contact_email_tag` -> `email_tag`.

Transformações do genome:

- A maioria dos campos de taxonomy usa `strip` + `slugify`.
- `system_property_label` usa `strip` + `titlecase`.
- `property_type` usa `strip` + `titlecase` no field catalog, embora exista também enum em modelos.

### Source/list slugs estruturais encontrados em testes/código

Busca local em real_estate + apps/system/public lead_finder encontrou estes `list_type_slug` não-PII:

- `pre_foreclosure`
- `skip_trace_contact_discovery`
- `loan_modification`
- `probates`
- `divorce`
- `property_comparables`
- `manual_property`
- `eviction`
- `tax_sale`
- `appt_of_sub_trustee`
- `heirship`
- `foreclosure`
- `tax_lien`
- `address_discovery`
- `absentee_owner`
- `property_enrichment`

Interpretação cautelosa:

- Alguns coincidem com `SituationType` (`pre_foreclosure`, `tax_sale`, etc.).
- Alguns são produtos/processos de ingestão/enrichment (`skip_trace_contact_discovery`, `property_comparables`, `manual_property`, `address_discovery`, `property_enrichment`).
- `probates` aparece plural em list source, enquanto `SituationType` usa `probate` singular. Isto é um risco de normalização prematura.

## Inventário — labels/status derivados na API pública Lead Finder

Arquivos: `apps/public/lead_finder/contracts.py`, `api_queries.py`, `presenters.py`, testes.

Vocabulários/contratos relevantes:

- `LeadFinderLeadTypeContract`: `id`, `label`, `variant`, `color` opcional.
- `primary_lead`: string renderizada no contrato público.
- `lead_types`: lista de lead types sistêmicos no contrato público.
- `saved_to_lists`: listas do workspace.
- `saved_to_tags`: tags do workspace.
- `crm_status`: status CRM/workspace opcional.
- `skip_status`: status de skip/enrichment opcional.
- Query state pública: `idle_no_query`, `user_query_applied`, `preset_applied`.
- Activation reason: `none`, `user_query`, `default_preset`, `explicit_preset`.

Map marker status em `api_queries.py`:

- score >= 70 -> `HOT`.
- score >= 40 -> `WARM`.
- abaixo disso -> `COLD`.

Teste importante: `apps/public/lead_finder/tests/test_presenters.py` garante que `tags: [pre_foreclosure, vacant]` sem `situations` não viram `lead_types`. Isto protege a separação entre workspace tags e lead taxonomy.

## Inventário — outros enums/status/taxonomias relacionados

Estes vocabulários podem tocar o desenho futuro, mas não são todos “tags”. Devem ser tratados como facts/statuses específicos.

### Property/details

- `detail_models.PropertyType`: `single_family`, `multi_family`, `condo`, `townhouse`, `manufactured`, `land`, `commercial`, `industrial`, `mixed_use`, `other`.
- `detail_models.PropertyDetails.listing_status`: campo string livre/externo, sem enum observado.
- `detail_models.PropertyDetails.features`: array de strings; não inventariado como taxonomia canônica.

### Lead score / lead intelligence

- `LeadClassification`: `hot`, `warm`, `cold`.
- `LeadIntelligence.QualificationStatus`: `new`, `contacted`, `qualified`, `disqualified`.
- `LeadIntelligence.QueueStatus`: `ready`, `follow_up`, `qualified`, `dead`.
- `LeadContactAttempt.ContactMethod`: `phone`, `sms`, `email`, `other`.
- `LeadContactAttempt.ContactOutcome`: `no_answer`, `left_voicemail`, `connected`, `interested`, `qualified`, `appointment`, `not_interested`, `wrong_number`, `do_not_call`, `other`.

Observação: nomes como `contacted`, `follow_up`, `qualified`, `not_interested` reaparecem em tags default do workspace. Não assumir identidade semântica entre status operacional e tag do usuário.

### Party/owner/contact canonical graph

- `EntityType`: `person`, `company`.
- `OwnershipType`: `owner`, `co_owner`, `investor`, `trust`, `llc_member`.
- `RoleType`: `owner`, `mortgagor`, `grantee`, `applicant`, `heir`, `decedent`, `tenant`, `landlord`, `petitioner`, `respondent`, `attorney`, `trustee`, `other`.
- `RepresentativeRole`: `officer`, `director`, `partner`, `manager`, `member`, `agent`, `other`.
- `AddressType`: `residential`, `commercial`, `po_box`, `mailing`.
- `PhoneType`: `mobile`, `landline`, `voip`, `unknown`.
- `PhoneSubtype`: `residential`, `business`, `unknown`.
- `PhoneStatus`: `correct`, `wrong`, `no_answer`, `dnc`, `dead_line`.
- `EmailType`: `personal`, `work`, `other`, `unknown`.
- `EmailStatus`: `active`, `inactive`, `bounced`, `invalid`.
- `BounceType`: `hard_bounce`, `soft_bounce`, `complaint`, `unknown`.

### Owner resolution

- `OwnerResolutionCase.TriggerKind`: `county_ingestion`, `skiptrace_result`, `my_property_submission`, `fresh_provider_refresh`, `timeline_conflict`, `manual_reprocess`, `ai_reassessment`.
- `OwnerResolutionCase.Status`: `open`, `candidate_generated`, `decided`, `materialized`, `needs_ai`, `needs_human`, `superseded`, `closed`.
- `ResolutionScope`: `identity`, `contact`, `relationship`, `ownership`, `mixed`.
- `EvidenceRole`: `subject`, `positive_signal`, `negative_signal`, `conflict_signal`, `context`, `raw_residue`.
- `CandidateKind`: `existing_entity`, `new_entity`, `related_person`, `conflicting_identity`, `insufficient_identity`.
- `DecisionHint` / `Decision`: `same_entity`, `possible_match`, `related_but_distinct`, `distinct_entity`, `conflicted`, `insufficient_evidence`.
- `MaterializationAction`: `none`, `attach_evidence_only`, `create_entity`, `merge_entity`, `link_relationship`, `attach_contact`, `update_canonical_fields`, `defer`.
- `Adjudicator`: `deterministic_rules`, `score_engine`, `ai_high_capacity`, `human_review`.
- `Action`: `created`, `updated`, `linked`, `skipped`, `superseded`, `rolled_back`.
- `EvidenceKind`: `identity`, `phone`, `email`, `address`, `relationship`, `ownership`, `party_role`, `provider_outcome`, `timeline`.
- `SourceKind`: `county`, `sourcehub`, `skiptrace`, `my_property`, `manual`, `ai`, `system_refresh`.

### Legacy/manual simple property residue

Arquivo: `domains/real_estate/models/legacy_simple_property.py`.

- `PropertyType`: `single_family`, `condo`, `townhouse`, `apartment`, `mobile_home`, `commercial`, `industrial`, `office`, `retail`, `multi_family`, `duplex`, `triplex`, `fourplex`, `vacant_land`, `other`.
- `PropertyStatus`: `active`, `pending`, `sold`, `archived`, `draft`.

Este modelo é resíduo manual/simple. Deve informar migração/compatibilidade, não substituir a taxonomia canônica do Lead Finder.

## Testes e guardrails existentes

### `test_tag_registry_service.py`

Cobertura observada:

- `test_allowed_origins_only_expose_user_created_tags`: `TagRegistryService.get_allowed_origins()` retorna somente `user`, com label `User Created` e `readonly=false`.
- `test_seed_registry_data_does_not_create_systemic_tags`: mesmo com `seed_registry_data --system-tags`, não cria registros com origem `system` ou `lead_finder`; saída inclui `Skipping systemic tag seed`.

Importância: estes testes são guardrails diretos contra seed prematuro de taxonomia sistêmica no registry de workspace.

### `test_presenters.py`

Cobertura observada:

- `test_build_lead_finder_property_contract_does_not_promote_tags_to_lead_types`: tags em payload (`pre_foreclosure`, `vacant`) não são promovidas para `lead_types` quando `situations` está vazio.

Importância: evita que tags/workspace labels mascarem lead taxonomy sistêmica.

### `test_operator_search_boundary.py`

Cobertura observada:

- Quando há situação ativa `pre_foreclosure`, `taxonomy_materialization.active_situation_types` e `system_property_tag_slugs` contêm `pre_foreclosure`.
- `source_list_type_slug` é preservado como linhagem (`pre_foreclosure` ou `address_discovery`).
- Caso de `address_discovery` mostra `system_property_tag_slugs=[]` mesmo com source list type presente, reforçando que source list não vira tag sistêmica automaticamente.

## Riscos antes do desenho de tag-groups

1. Seed prematuro de system tags no workspace registry:
   - O comando legado ainda aceita `--system-tags`, mas hoje deve apenas emitir skip.
   - Reverter isso recriaria a mistura entre taxonomia sistêmica e tags do usuário.

2. Confundir `source_list_type_slug` com tag canônica:
   - O contrato diz que source list é linhagem/search, não lead taxonomy automática.
   - Exemplo `address_discovery` comprova source list sem `system_property_tag_slugs`.

3. Normalizar slugs por aparência:
   - `probates` vs `probate` mostra plural/singular divergente.
   - `tax_delinquent` aparece em cores default, mas não em `SituationType` lido.
   - `high_equity` e `absentee_owner` aparecem como tags default/heurísticas, não situações legais.

4. Reusar labels de CRM como status sistêmico:
   - `Hot Lead`, `Cold Lead`, `Contacted`, `Follow Up`, `Not Interested` são seed/workspace tags.
   - `hot/warm/cold` também são score classifications.
   - `contacted/follow_up/qualified/not_interested` também aparecem em lead ops/status/outcomes.
   - Mesmo nome não implica mesmo domínio.

5. Promover `PropertyDetails.features` ou `listing_status` sem governança:
   - São arrays/string de enrichment/listing, não registry consolidado.

6. Manter dois registries de lista/tag em paralelo sem decidir ownership:
   - `workspace_crm.PropertyList/PropertyTag` e `workspace_registry.PropertyListRegistry/PropertyTagRegistry` coexistem.
   - O desenho futuro deve decidir pontes/compatibilidade, mas esta etapa não deve projetar grupos finais.

## Recomendação de boundary para próxima etapa

Sem projetar tag-groups finais ainda, a fronteira que o inventário sugere preservar é:

- System taxonomy: derivada de Matrix/Lead Finder/situações/source lineage e exposta read-only para busca/inventário.
- Workspace tags: usuário cria, edita, ordena, colore e aplica a propriedades salvas.
- Workspace status/list: pipeline e organização CRM por usuário.
- Bridges: permitidos apenas como referência read-only/adaptação (`lf_tag_type`, handoff contracts), nunca como fonte de verdade da taxonomia sistêmica.

## Comandos de verificação executados

- Busca recursiva de termos `tag|label|status|registry|taxonomy|list|choice|choices` nas fontes solicitadas.
- Leitura direta dos modelos/serviços/testes listados acima.
- Script Python local para extrair `models.TextChoices` dos modelos `real_estate`.
- Script Python local para listar campos da família `systemic_taxonomy` do genome Lead Finder.
- Script Python local para amostrar slugs estruturais `list_type_slug` em código/testes.

Nenhuma alteração de DDL foi feita.
