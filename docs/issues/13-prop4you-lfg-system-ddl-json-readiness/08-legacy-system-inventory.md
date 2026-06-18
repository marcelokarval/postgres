# 08 — Inventário do legado Django system para LFG readiness

Status: inventário de leitura; sem alteração de DDL.
Fonte analisada: `/home/marcelo-karval/Backup/Projetos/prop4you/prop4you-inertia/backend/src`.
Escopo: `apps/system/lead_finder`, `apps/system/matrix`, `apps/system/sourcehub`, `domains/real_estate`, `domains/data` e fronteiras públicas `apps/public/lead_finder` / `interfaces/web/lead_finder`.
Nota de privacidade: este inventário não reproduz valores de payload, amostras, nomes, telefones, emails, endereços reais ou respostas de provedores; lista somente estruturas, campos semânticos e contratos.

## 1. Leitura executiva

O legado Django já expressa a arquitetura alvo de LFG como pipeline de sistema:

1. Matrix governa significado, mapeamentos, baselines, aprovação e reentrada semântica.
2. SourceHub governa ingresso, raw lineage, normalização, DTOs canônicos e envelopes de handoff.
3. Lead Finder governa materialização do grafo pesquisável de propriedades, owners, situações, contatos, histórico e overlays.
4. Public Lead Finder expõe apenas projeções/ações de produto, com contratos JSON/Inertia e mascaramento/contagem em pontos sensíveis.
5. `domains/real_estate` contém o grafo canônico durável hoje mais próximo do LFG atual; `domains/data` contém SourceHub raw, skip trace e cache sistêmico.

Para readiness do DDL/JSON atual, a maior diretriz é preservar a separação: raw payload/lineage em SourceHub, semântica e artefatos em Matrix, verdade materializada em Lead Finder/real_estate, e consumo público por projeções/refs.

## 2. Famílias, tabelas e modelos relevantes

### 2.1 Lead Finder system boundary (`apps/system/lead_finder`)

Não há modelos próprios persistidos no app system Lead Finder; ele orquestra materialização em `domains/real_estate`.

Arquivos/funções principais:

- `contracts.py`
  - Estágios e use cases: `lead_finder`, `consume_dto`, `hydrate_graph`, `promote_*_seed`, `build_owner_relationships`, `query_canonical_inventory`, `query_operator_inventory`, `build_reconciliation_snapshot`, `publish_workspace_reference`.
  - Famílias de materialização: `identity_address`, `property_details`, `owner_ownership`, `mailing_address`, `contact_satellites`, `party_roles`, `entity_representatives`, `relationship_evidence`, `legal_timeline`, `valuation_financial`, `systemic_taxonomy`.
  - Estados/decisões: `already_materialized`, `partially_materialized`, `seed_only`, `missing`; `materialize_now`, `materialize_reduced_slice_now`, `defer_with_proof`.
  - Taxonomia materializada: `property_type`, `active_situation_types`, `active_situation_statuses`, `source_list_type_slug`, `system_property_tag_slugs`, `system_property_label_slugs`, `owner_tag_slugs`, `phone_tag_slugs`, `email_tag_slugs`.
- `acquisition.py`
  - Boundary address-first: `CanonicalPropertyAcquisitionService.ensure_property_for_address_seed`.
  - Resolve `SystemAddress`, sincroniza `PropertyLocation`, garante `PropertyLeadFinder`, agenda geocode se necessário.
- `hydration.py`
  - Consome DTOs/envelopes SourceHub e materializa: `PropertyLocation`, `PropertyLeadFinder`, `OwnerEntity`, `Ownership`, `PropertySituation`, `PropertyHistory`, `PropertyDetails`, `OwnerContactAddress`, `OwnerPhone`, `OwnerEmail`, `PartyRole`, `OwnerEntityRepresentative`, `PersonRelationship`, `PropertyEvent`, `PropertyValuation`, overlays.
- `operator_search.py`
  - Projeções de operador/reconciliação: coverage flags, provider chain, source fact namespaces, provider conflicts, latest raw record ref, taxonomy materialization.
  - Flags conhecidas: `missing_system_address`, `missing_latest_snapshot`, `missing_address_source_facts`, `missing_property_source_facts`, `missing_current_owner`, `stale_property_details`, `provider_conflict:<namespace>`.
- `baseline.py` / `baseline_authoring.py`
  - Publicação/normalização de baseline Lead Finder consumido por Matrix.

### 2.2 Matrix (`apps/system/matrix`)

Modelos persistidos:

| Tabela | Modelo | Papel |
| --- | --- | --- |
| `matrix_lead_finder_default_baseline` | `MatrixLeadFinderDefaultBaseline` | Baseline LF publicado/ativável; contrato LF consumido por Matrix. |
| `matrix_schema_genome` | `MatrixSchemaGenome` | Genome/mapeamento aprovado por provider/list/state/version; contém field mappings, transformations, validation rules, compiled schema, summaries e reentry triggers. |
| `matrix_approval_record` | `MatrixApprovalRecord` | Registro de decisão HITL/auto/reject/defer/activation sobre genome. |
| `matrix_corpus_session` | `MatrixCorpusSession` | Sessão de corpus/onboarding/revalidation; raw ids, manifest, samples internos, stats e outputs semânticos. |
| `matrix_field_review` | `MatrixFieldReview` | Revisão por campo detectado; sugestões, target family, confidence, conflicts, evidence. |
| `matrix_growth_pressure_signal` | `MatrixGrowthPressureSignal` | Pressão de crescimento: campo/canonical family/promotion/sourcehub framing/provider drift. |

Marcadores/status:

- Genome: `draft`, `pending_approval`, `approved`, `active`, `deprecated`, `archived`.
- Baseline: `draft`, `active`, `deprecated`.
- Approval status: `pending`, `approved`, `rejected`, `deferred`.
- Decision type: `auto_approved`, `hitl_approved`, `rejected`, `deferred`, `activation`.
- Corpus: `onboarding`, `revalidation`; status `pending`, `analyzing`, `awaiting_hitl`, `compiled`, `failed`.
- Field review: `detected`, `awaiting_hitl`, `approved`, `rejected`, `deferred`, `merged`.
- Growth pressure kinds: `missing_canonical_field`, `underfed_canonical_family`, `promotion_rule_gap`, `sourcehub_framing_gap`, `provider_drift_observed`.

Contratos/DTOs sem persistência direta:

- Pré-SourceHub por provider/família: REIQ pre foreclosure, loan modification, probate, divorce, heirship, appointment of substitute trustee, tax sale, eviction; Realtor property enrichment, market enrichment, area boundary, comparables.
- Primitivos semânticos: name, company, phone, email, address, relationship, associations, actions, sourcehub candidates.
- Owner resolution compiler/projections: owner identity, phone/email/address projection, related phone, relationship evidence bundle.

### 2.3 SourceHub (`apps/system/sourcehub` + `domains/data/models/sourcehub.py`)

Modelo persistido principal:

| Tabela | Modelo | Campos-chave |
| --- | --- | --- |
| `data_sourcehub_raw_record` | `SourceHubRawRecord` | `provider_slug`, `list_type_slug`, `state_slug`, `ingestion_mode`, `payload_format`, `processing_status`, `external_reference_id`, `payload_hash`, `raw_payload`, `ingested_at`, `processed_at` |

Regras de lineage:

- Unicidade por `provider_slug`, `list_type_slug`, `state_slug`, `payload_hash`.
- Status: `pending`, `processed`, `failed`.
- Ingestion modes: `api`, `csv`, `manual_upload`, `reprocess`, `product_originated`.
- Payload formats: `json`, `csv`, `xml`, `unknown`, `product_seed`.
- `raw_payload` existe, mas não deve atravessar fronteiras públicas nem ser reproduzido em inventários.

Contratos e envelopes:

- SourceHub stages/queues: `sourcehub`, queues `sourcehub_ingest`, `sourcehub_process`.
- Runtime approval mode: `consume_approved_matrix_artifact_only`.
- Matrix reentry triggers: `new_provider`, `new_list_type`, `new_mapping_version`, `new_canonical_family`, `new_taxonomy_family`, `promotion_rule_change`, `provider_drift_detected`, `semantic_conflict_detected`.
- Source fact namespaces: `address_identity`, `address_geocode`, `address_parcel`, `mailing_contact`, `party_role`, `company_representation`, `relationship_evidence`, `legal_timeline`, `property_distress`, `property_equity`, `property_valuation`, `provider_reference`.
- Family targets: `identity`, `building`, `land`, `owner_identity`, `owner_contact`, `mailing_contact`, `owner_representatives`, `party_roles`, `relationship_evidence`, `history`, `legal_timeline`, `valuation_financial`, `taxonomy_bridge`, `operator_lineage_only`.
- Handoffs principais para Lead Finder:
  - `SourceHubAddressSeedEnvelope`
  - `SourceHubProductOriginAddressSeedEnvelope`
  - `SourceHubPropertyDetailsSeedEnvelope`
  - `SourceHubMailingContactSeedEnvelope`
  - `SourceHubPartyRolesSeedEnvelope`
  - `SourceHubRelationshipEvidenceSeedEnvelope`
  - `SourceHubEntityRepresentativesSeedEnvelope`
  - `SourceHubLegalTimelineSeedEnvelope`
  - `SourceHubValuationFinancialSeedEnvelope`
  - `SourceHubCanonicalDTOEnvelope`

Normalizadores observados:

- `property_details_normalization.py`
- `valuation_financial_normalization.py`
- `legal_timeline_normalization.py`
- ingestion REIQ por lista/estado, geocode ingestion e backfill skip trace SourceHub.

### 2.4 `domains/real_estate`: grafo LFG canônico/materializado

#### Identidade/endereço/propriedade

| Tabela | Modelo | Papel |
| --- | --- | --- |
| `real_estate_property_location` | `PropertyLocation` | Projeção de endereço da propriedade; aponta para `SystemAddress`; campos de endereço, APN, source confidence, discovery source. |
| `real_estate_property` | `Property` / alias `PropertyLeadFinder` | Propriedade canônica LF; `location`, `system_address`, `is_owner_occupied`. |
| `real_estate_property_details` | `PropertyDetails` | Building/land/listing/details: tipo, quartos, banhos, sqft, lot, zoning, subdivision, legal, listing, photos/features/schools/HOA e stale/source fields. |
| `real_estate_property_enrichment_overlay` | `PropertyEnrichmentOverlay` | Overlay calculado: equity, motivated seller score, tags, latest DTO. |
| `real_estate_properties` | `PropertySimple` | Registro legado simples; resíduo de compatibilidade, não é a fonte canônica LFG. |

#### Owner/party graph

| Tabela | Modelo | Papel |
| --- | --- | --- |
| `real_estate_owner_entity` | `OwnerEntity` | Pessoa/empresa canônica; normalização, slug, source confidence, deceased/company metadata. |
| `real_estate_ownership` | `Ownership` | Ponte owner-property; tipo, percentual, current, datas, investor/cash buyer/portfolio/absentee/in-state/source. |
| `real_estate_property_party_role` | `PartyRole` | Papéis relacionados à propriedade/owner; relationship, role type, source ref, current, confidence. |
| `real_estate_owner_entity_representative` | `OwnerEntityRepresentative` | Representante pessoa de empresa; role/title/active/datas/source. |
| `real_estate_person_relationship` | `PersonRelationship` | Relação pessoa-pessoa; type/confidence/verified/sources. |

#### Contatos e mailing/contact address

| Tabela | Modelo | Papel |
| --- | --- | --- |
| `real_estate_owner_contact_address` | `OwnerContactAddress` | Endereço de contato/mailing por owner; linka `SystemAddress`; flags primary/current/PO box/property/deliverable/status. |
| `real_estate_owner_phone` | `OwnerPhone` | Telefone canônico por owner; normalizado; tipo/subtipo/status/DNC/call counts/quality. |
| `real_estate_owner_email` | `OwnerEmail` | Email canônico por owner; normalizado; tipo/status/bounce/send counters/quality. |

Detalhe DNC/wrong/bounce/sendability/callability:

- `OwnerPhone.PhoneStatus`: `correct`, `wrong`, `no_answer`, `dnc`, `dead_line`.
- `OwnerPhone` persiste `is_valid`, `is_dnc`, `dnc_registered_at`, `dnc_reason`, `last_called_at`, `call_count`, `quality_score`.
- `OwnerPhone.is_callable` é verdadeiro apenas quando válido, não DNC e status não está em `dnc`, `dead_line`, `wrong`.
- `OwnerEmail.EmailStatus`: `active`, `inactive`, `bounced`, `invalid`.
- `OwnerEmail.BounceType`: `hard_bounce`, `soft_bounce`, `complaint`, `unknown`.
- `OwnerEmail` persiste `is_valid`, `is_primary`, `bounce_type`, `bounce_reason`, `bounce_count`, `last_bounce_at`, `last_sent_at`, `sent_count`, `open_count`, `click_count`, `quality_score`.
- `OwnerEmail.is_sendable` é verdadeiro apenas quando válido e status `active`.
- `OwnerContactAddress.AddressType`: `residential`, `commercial`, `po_box`, `mailing`.
- `OwnerContactAddress` persiste `is_primary`, `is_current`, `is_po_box`, `is_property`, `is_deliverable`, `validation_status`; PO box não pode ter property anchor.

#### Situações, eventos, histórico e valuation

| Tabela | Modelo | Papel |
| --- | --- | --- |
| `real_estate_property_situation` | `PropertySituation` | Fatos estruturados de situação; tipo/status/datas/document/case/source/confidence. |
| `real_estate_property_event` | `PropertyEvent` | Eventos/timeline por property; event key/kind/list type/date/source/details. |
| `real_estate_property_history` | `PropertyHistory` | Snapshot DTO portátil por property. |
| `real_estate_property_valuation` | `PropertyValuation` | Valores financeiros: estimated/assessed/appraised/mortgage/original loan/equity/date/source/confidence. |

#### Semântica/taxonomia sistêmica

| Tabela | Modelo | Papel |
| --- | --- | --- |
| `real_estate_system_property_type` | `SystemPropertyType` | Tipo sistêmico de propriedade. |
| `real_estate_system_property_list_type` | `SystemPropertyListType` | Tipo sistêmico de lista, com categoria. |
| `real_estate_system_situation_type` | `SystemSituationType` | Tipo sistêmico de situação. |
| `real_estate_system_situation_status` | `SystemSituationStatus` | Status sistêmico de situação. |

#### CRM/workspace e overlays não-canônicos

| Tabela | Modelo | Observação |
| --- | --- | --- |
| `real_estate_property_list`, `real_estate_saved_property` | `PropertyList`, `SavedProperty` | Workspace/subscriber CRM; não define verdade canônica LFG. |
| `real_estate_tag_registry`, `real_estate_status_registry`, `real_estate_list_registry` | registries workspace | Registros configuráveis por usuário/workspace. |
| `real_estate_owner_entity_tag`, `real_estate_owner_phone_tag`, `real_estate_owner_email_tag` | tags workspace | Tags por workspace sobre entidades/contatos; separar de markers sistêmicos. |
| `real_estate_filter_preset`, `real_estate_filter_preset_folder` | filtros | Presets de produto. |
| `real_estate_property_activity`, `real_estate_property_notes` | activity/notes | Produto/operacional; não é source-of-truth LFG. |
| `real_estate_lead_score`, `real_estate_lead_intelligence`, `real_estate_lead_contact_attempt` | scoring/queue/contact ops | Inteligência/CRM em cima do grafo. |

#### Owner resolution

| Tabela | Modelo | Papel |
| --- | --- | --- |
| `real_estate_owner_identity_evidence` | `OwnerIdentityEvidence` | Evidências de identidade/contato/relacionamento com provider/list/source refs e campos observados. |
| `real_estate_owner_resolution_case` | `OwnerResolutionCase` | Caso de resolução. |
| `real_estate_owner_resolution_case_evidence` | `OwnerResolutionCaseEvidence` | Associação caso-evidência. |
| `real_estate_owner_resolution_candidate` | `OwnerResolutionCandidate` | Candidato e score/components/signals. |
| `real_estate_owner_resolution_decision` | `OwnerResolutionDecision` | Decisão, confiança, reasons, materialization action. |
| `real_estate_owner_resolution_materialization` | `OwnerResolutionMaterialization` | Registro de materialização before/after/skip. |

### 2.5 `domains/data`: SourceHub, skip trace e caches

| Tabela | Modelo | Papel |
| --- | --- | --- |
| `data_sourcehub_raw_record` | `SourceHubRawRecord` | Bronze/raw lineage SourceHub. |
| `data_skip_trace_request` | `SkipTraceRequest` | Solicitação ST; user/batch/property/sourcehub refs, owner/property/mailing input, status, cost, lifecycle. |
| `data_skip_trace_result` | `SkipTraceResult` | Resultado ST; sucesso/confidence, phones/emails/addresses/owner/related people/match metrics/result metrics/raw response/provider/performance. |
| `data_skip_trace_batch` | `SkipTraceBatch` | Batch ST; counts, status, file keys, costs. |
| `data_skip_trace_financial_projection_v` | `SkipTraceFinancialProjection` | View/projeção financeira de billing/refund/usage. |
| `data_system_skip_trace_providers` | `SystemSkipTraceProvider` | Config/cache sistêmico de provider ST; contém secret API key no legado, não inventariar valores. |
| `data_system_skip_trace_results` | `SystemSkipTraceResult` | Cache sistêmico ST por owner/mailing/property/sourcehub refs; phones/emails/addresses/related payloads e metrics. |
| `data_skip_trace_snapshots` | `SkipTraceSnapshot` | Snapshot request/response para auditoria/cobrança; payloads não devem vazar. |
| `data_system_skip_trace_hits` | `SystemSkipTraceHit` | Hit/cache usage e refresh flags. |
| `data_lead_sources`, `data_lead_imports` | `LeadSource`, `LeadImport` | Import/lead-source legado/produto. |
| `data_download_history` | `DownloadHistory` | Histórico de export/download. |

## 3. Tags, labels e system markers

### 3.1 Separação observada

- Situações são fatos estruturados (`PropertySituation`) e não tags livres.
- Tags workspace (`OwnerEntityTag`, `OwnerPhoneTag`, `OwnerEmailTag`, registries e saved tags) pertencem ao subscriber/CRM; não devem virar taxonomia sistêmica sem promoção explícita.
- Lead Finder materializa `system_property_tag_slugs` inicialmente a partir de `active_situation_types` no operador; `system_property_label_slugs`, `owner_tag_slugs`, `phone_tag_slugs`, `email_tag_slugs` estão previstos mas vazios/incipientes.
- SourceHub `SourceHubTaxonomyFramingBlock` transporta `source_list_type_slug`, `system_list_type_slug`, `system_tag_slugs`, `system_label_slugs`, `downstream_family_targets` e notas de framing.
- Matrix é o local de aprovação para novas famílias/campos/taxonomias; growth pressure e field review são o mecanismo de lacuna.

### 3.2 Markers operacionais úteis para LFG atual

- `stage`: `sourcehub`, `lead_finder`.
- `producer_stage` / `consumer_stage`: SourceHub para LF, LF acquisition etc.
- `provider_slug`, `list_type_slug`, `state_slug`, `mapping_version`, `canonical_schema_version`.
- `raw_record_public_id`, `dto_public_id`, `seed_public_id`, `payload_hash`.
- `taxonomy_framing`, `transformation_lineage`, `source_facts`.
- `source_confidence`, `confidence_score`, `quality_score`.
- `discovery_source`, `data_source` em property location/acquisition.
- `public_id_prefix` importantes: `shraw`, `ent`, `own`, `caddr`, `phn`, `eml`, `mbase`, `genome`.

## 4. Fronteiras públicas Lead Finder

### 4.1 HTTP/JSON (`interfaces/web/lead_finder/views/api_endpoints.py`)

Endpoints JSON justificados:

- `markers_view` GET: marcadores leves para mapa; chama `load_lead_finder_markers`.
- `detail_view` GET: detalhe em modal; chama `load_lead_finder_detail`.
- `summaries_view` GET: summaries por IDs para popovers; chama `load_lead_finder_summaries`.
- `enrich_view` POST: enriquecimento via skip trace; retorna contagens/custo, não contatos crus.
- `location_search_view` GET: autocomplete de áreas; chama `search_lead_finder_locations`.

Todos exigem login; workspace owner é derivado de `request.workspace_owner` ou `request.user`.

### 4.2 App público (`apps/public/lead_finder`)

- `contracts.py`: contrato de página e payloads: properties, pagination, query state, selected area viewport, saved IDs, presets, counts, CRM lists/tags/summary.
- `queries.py`: entrypoint Inertia `load_lead_finder_page`; só busca propriedades se filtros ativos; cria estado `idle_no_query` para evitar vazamento/carregamento amplo.
- `api_queries.py`: map markers, summaries, detail, location suggestions; location search limitado a `SystemArea` city/state/county/postal code e provider expansion controlado por feed ledger.
- `presenters.py`: owner preview mascarado (`maskedName`) e CTA “Send to My Property to reveal owner”; lead badges por situações; métricas e score.
- `actions.py`: enrichment público chama inteligência/skip trace e retorna `phonesAdded`, `emailsAdded`, `cost`; não retorna phone/email/address payload.

Implicação DDL/API: manter fachada pública com refs e projeções; não expor tabelas raw/domain diretamente via PostgREST sem views/RPCs/Policies específicas.

## 5. Lacunas conhecidas / riscos de readiness

1. `apps/system/lead_finder` não persiste modelos próprios; a fronteira canônica depende de `domains/real_estate`. No DDL atual, preferir schemas/tabelas por bounded context sem copiar a estrutura Django literalmente.
2. `system_property_label_slugs`, `owner_tag_slugs`, `phone_tag_slugs`, `email_tag_slugs` aparecem como campos de contrato, mas a materialização sistêmica ainda está vazia/incipiente.
3. Tags workspace coexistem com taxonomia sistêmica; risco de misturar CRM subscriber com truth/semantics de sistema.
4. Raw payloads e snapshots existem em `data_sourcehub_raw_record`, `SkipTraceResult.raw_response`, `SkipTraceSnapshot.request_payload/response_payload`, `SystemSkipTraceResult` JSONs. Precisam de isolamento forte, mascaramento e políticas de não exposição.
5. Provider API key no modelo `SystemSkipTraceProvider.api_key` é segredo legado; em DDL atual deve estar em vault/secret manager ou tabela protegida, nunca em contrato público.
6. Owner resolution possui muitos campos observados/snapshots; é rico para decisão, mas precisa de separação entre evidência, decisão e materialização no DDL para não contaminar o grafo canônico automaticamente.
7. `PropertySimple` (`real_estate_properties`) é resíduo legado e não deve ser promovido como fonte LFG canônica.
8. `PropertyHistory.dto` armazena snapshot DTO JSON; útil para lineage/replay, mas deve ser distinto de fatos materializados e de raw payload.
9. `SourceHubRawRecord.processing_status` é simples (`pending/processed/failed`); LFG atual pode precisar de estados mais explícitos para replay, quarantine, skipped, duplicate e superseded.
10. `OwnerContactAddress.validation_status` é string livre; DDL atual pode precisar enum/lookup para deliverability/wrong/undeliverable/unknown.
11. `OwnerPhone` tem DNC e wrong/dead-line, mas não há opt-out geral por canal/workspace no trecho inventariado; avaliar consent/Do Not Contact multi-canal.
12. `OwnerEmail.is_sendable` não considera complaint/bounce_count além do status; DDL/API pode calcular sendability como projeção derivada mais rígida.
13. Matrix corpus guarda `sample_payloads`; deve ser tratado como potencial PII/raw sample, com retenção e ACL.
14. Public `detail` pode retornar payload rico via `PropertyQueryService.get_property_detail`; exige revisão de projeção para garantir mascaramento/entitlement equivalente no DDL/API.
15. Location autocomplete escreve feed terms/results no fluxo público com `allow_system_writes`; em Postgres-centric precisa virar RPC/job com rate limit/idempotência.

## 6. Mapeamento conceitual para LFG atual

| Legado Django | Conceito LFG atual sugerido | Observação |
| --- | --- | --- |
| `SourceHubRawRecord` | `sourcehub.raw_records` / bronze ingress | Raw payload + hash + provider/list/state lineage; acesso restrito. |
| SourceHub envelopes/seeds | `sourcehub.canonical_handoffs` ou JSONB contract tables/outbox | Handoff versionado para LF; publicar DTO/seed sem raw payload. |
| `MatrixSchemaGenome` | `matrix.schema_genomes` | Artefato aprovado por provider/list/state/version. |
| `MatrixApprovalRecord` | `matrix.approvals` | Decisões HITL/auto e activation. |
| `MatrixCorpusSession` / `MatrixFieldReview` | `matrix.corpus_sessions`, `matrix.field_reviews` | Discovery/review; sample payloads protegidos. |
| `MatrixGrowthPressureSignal` | `matrix.growth_pressure_signals` | Solicitação de evolução semântica e reentrada. |
| `PropertyLocation` + `SystemAddress` | `lead_finder.property_locations` + shared geography/address identity | Endereço canônico/projeção e geocoding. |
| `Property` / `PropertyLeadFinder` | `lead_finder.properties` | Nó canônico de propriedade. |
| `PropertyDetails` | `lead_finder.property_details` | Building/land/listing details materializados. |
| `OwnerEntity` | `lead_finder.owner_entities` | Pessoa/empresa canônica com normalização/dedup. |
| `Ownership` | `lead_finder.ownerships` | Relação owner-property atual/histórica. |
| `OwnerContactAddress` | `lead_finder.owner_contact_addresses` | Mailing/contact address, deliverability e PO box semantics. |
| `OwnerPhone` | `lead_finder.owner_phones` | DNC/wrong/dead-line/callability. |
| `OwnerEmail` | `lead_finder.owner_emails` | Bounce/sendability/engagement. |
| `PartyRole`, `OwnerEntityRepresentative`, `PersonRelationship` | `lead_finder.party_roles`, `entity_representatives`, `relationships` | Relações/roles separados de ownership. |
| `PropertySituation` | `lead_finder.property_situations` | Situações como fatos estruturados, não tags. |
| `PropertyEvent` / legal timeline seed | `lead_finder.property_events` / `legal_timeline` | Eventos com source reference e timeline. |
| `PropertyValuation` | `lead_finder.property_valuations` | Financeiro/valuation/equity. |
| `PropertyHistory.dto` | `lead_finder.property_snapshots` | Snapshot canônico/replay, separado de raw. |
| `PropertyEnrichmentOverlay`, `LeadScore`, `LeadIntelligence` | `lead_finder.enrichment_overlays`, `scores`, `ops_queue` | Derivados/calculados; não fonte de verdade. |
| Workspace registries/tags/lists | `workspace.*` ou `crm.*` | Subscriber-owned overlays; separar de system taxonomy. |
| Public Lead Finder app contracts | `api` views/RPCs/projections | Expor refs, masked owner preview, counts e detalhes autorizados. |

## 7. Recomendações para o próximo slice DDL/JSON

1. Modelar schemas separados: `matrix`, `sourcehub`, `lead_finder`, `workspace/crm` e `api` facade.
2. Tratar `situations` como tabela/fatos com enums/lookups e lineage, não como tags.
3. Criar contracts JSONB versionados para SourceHub handoffs; incluir `provider_slug`, `list_type_slug`, `state_slug`, `mapping_version`, `canonical_schema_version`, refs e lineage.
4. Manter raw payloads em tabelas restritas; snapshots canônicos podem ser JSONB, mas sem confundir com raw payload.
5. Formalizar contactability:
   - phone: status + `is_dnc` + `is_valid` + derived `is_callable`.
   - email: status + bounce fields + derived `is_sendable`.
   - address: `is_deliverable` + `validation_status` normalizado.
6. Formalizar system taxonomy materialization separada de workspace tags; tags/labels sistêmicas só via Matrix/SourceHub/LF sanctioned materializer.
7. Preservar public boundary: markers/summaries/detail/enrichment/location search por RPC/views com RLS e entitlement; nunca raw tables.
8. Incluir owner-resolution como evidência/caso/decisão/materialização, para controlar quando evidência vira grafo canônico.
