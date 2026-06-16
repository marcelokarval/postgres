# 08 — Análise raw/local para candidatos LeadFinder família/campo

Status: entregue
Escopo: Worker A
Idioma: pt-BR

[NO_PROVIDER_CALLS]
Nenhuma chamada a provider, API externa, web ou serviço remoto foi executada. A análise usou apenas arquivos locais sob:

- PG18: `/home/marcelo-karval/Backup/Projetos/supabase-postgres-18-fork/postgres`
- Prop4You backend read-only: `/home/marcelo-karval/Backup/Projetos/prop4you/prop4you-inertia/backend/src`

[NO_PII_DUMP]
Este relatório não despeja valores raw, nomes reais, endereços, telefones, emails, IDs de pessoas/propriedades, payloads integrais, secrets ou respostas de provider. A evidência raw é limitada a caminhos, tipos estruturais, nomes de campos/chaves e contagens estruturais. Campos de contato/identidade aparecem apenas como nomes canônicos ou paths sem valores.

## Evidência local consultada

- Issue 03:
  - `docs/issues/03-prop4you-leadfinder-canonical-cycle-analysis/08-raw-corpus-evidence.md`
  - `docs/issues/03-prop4you-leadfinder-canonical-cycle-analysis/11-executive-synthesis.md`
- Raw-like local, por paths/tipos:
  - `apps/system/matrix/registry/directskip/skip_trace_contact_discovery/tx/data/undated/directskip_real_response.json`
  - `apps/system/matrix/registry/reiq/loan_modification/fl/data/2025-11-27/FL_loan-modification_c45a1057-8de0-11ee-9e90-42010a800019.json`
- LeadFinder baseline/genome:
  - `apps/system/lead_finder/artifacts/lead_finder_default_genome.lf_default.v1.json`
  - `apps/system/lead_finder/baselines/owner/*.json`
  - `apps/system/lead_finder/baselines/owner/model_inventory/*.json`
- LeadFinder/SourceHub contracts e materializers:
  - `apps/system/lead_finder/contracts.py`
  - `apps/system/lead_finder/hydration.py`
  - `apps/system/sourcehub/contracts.py`
  - `apps/system/sourcehub/property_details_normalization.py`
  - `apps/system/sourcehub/legal_timeline_normalization.py`
  - `apps/system/sourcehub/valuation_financial_normalization.py`
- Django-era canonical graph/model evidence:
  - `domains/real_estate/models/canonical_graph.py`
  - `domains/real_estate/models/canonical_party_graph.py`
  - `domains/real_estate/models/detail_models.py`
  - `domains/real_estate/models/valuation_models.py`
  - `domains/real_estate/models/situation_models.py`
  - `domains/real_estate/models/event_models.py`
  - `domains/real_estate/models/lead_intelligence_models.py`
  - `domains/real_estate/models/relationship_models.py`
  - `domains/real_estate/models/history_models.py`

## Resumo de suporte observado

- Raw-supported local forte/estreito:
  - DirectSkip: contato/skip trace com input de endereço/nome e arrays de contatos, emails, phones, relatives, confirmed_address.
  - REIQ loan_modification/fl: registro flat scalar-heavy com propriedade, owner/mortgagor, legal/loan, datas, valuation/financial e taxonomy/list type.
- Code/baseline-supported amplo:
  - LeadFinder default genome já enumera 10 famílias: `identity_address`, `property_details`, `owner_ownership`, `mailing_address`, `contact_satellites`, `party_roles`, `relationship_evidence`, `legal_timeline`, `valuation_financial`, `systemic_taxonomy`.
  - `LeadFinderMaterializationFamily` adiciona `entity_representatives` como família explícita em contratos/hydration, embora o artifact default genome consultado não a liste como family_catalog separada.
  - Baselines owner cobrem `owner_identity`, `owner_structural_position`, `owner_contact_address`, `owner_phone`, `owner_email`, `owner_relationship_evidence`.
- Não suportado por raw local nesta rodada:
  - Realtor raw JSON local; há code/test evidence para property enrichment/comparables/market, mas sem raw-like JSON em `backend/src` segundo issue 03.
  - Corpus privado local; issue 03 reportou caminho existente com 0 JSONs.

[RAW_TO_CANONICAL]

Mapeamento recomendado de evidência raw/local para famílias LeadFinder. `Suporte` usa:

- RAW: aparece em raw-like JSON local por path/tipo/campo.
- CODE: aparece em SourceHub/LeadFinder contracts, normalizers, hydration ou Django models/tests.
- BASELINE: aparece em LeadFinder default genome ou owner baselines.

| Evidência local sem valores | Família LeadFinder candidata | Campos canônicos iniciais | Suporte |
|---|---|---|---|
| DirectSkip `input.*` com endereço de propriedade e contexto de busca | `identity_address` | `street_address`, `city`, `state`, `zip_code`, `normalized_address`, `address_hash`, `country`, `provider_property_ref` quando houver ref externa | RAW, CODE, BASELINE |
| DirectSkip `contacts[].confirmed_address[]` | `mailing_address` / `owner_contact_address` | `mailing_address`, `contact_address_type`, `is_po_box`, `mailing_equals_property`, `property_address_match_status`, `property_address_confirmed_by_provider`, `system_address`, `address_type`, `validation_status`, `is_deliverable` | RAW, CODE, BASELINE |
| DirectSkip `contacts[].phones[]` | `contact_satellites` / `owner_phone` | `phone_number`, `phone_normalized`, `phone_type`, `phone_subtype`, `contact_role`, `contact_source_confidence`, `status`, `is_valid`, `is_dnc`, `quality_score`, `last_called_at`, `call_count` | RAW, CODE, BASELINE |
| DirectSkip `contacts[].emails[]` | `contact_satellites` / `owner_email` | `email`, `email_address`, `email_normalized`, `email_type`, `contact_role`, `contact_source_confidence`, `status`, `is_valid`, `is_primary`, `quality_score`, `bounce_type`, `bounce_count` | RAW, CODE, BASELINE |
| DirectSkip `contacts[].names[]` | `owner_ownership`, `owner_identity`, `party_roles` | `display_name`, `entity_type`, `first_name`, `middle_name`, `last_name`, `company_name`, `role_in_record`, `party_ref` | RAW, CODE, BASELINE |
| DirectSkip `contacts[].relatives[]` | `relationship_evidence` | `evidence_ref`, `display_name`, `first_name`, `middle_name`, `last_name`, `relationship_label`, `relationship_type`, `age`, `identity_resolution_status`, `owner_match_confidence`, `relationship_evidence_confidence` | RAW, CODE, BASELINE |
| DirectSkip `status` / `result_code` | `source_lineage` / operational metadata, não domínio final | `provider_slug`, `list_type_slug`, `raw_record_public_id`, `payload_hash`, `provider_mapping_ref`, `mapping_version`, `runtime_approval_mode`, `ingested_at`, `processed_at` | RAW, CODE |
| REIQ property address fields | `identity_address` | `street_address`, `city`, `state`, `zip_code`, `county`, `apn`, `provider_property_ref`, `normalized_address`, `address_hash` | RAW, CODE, BASELINE |
| REIQ building/detail fields | `property_details` | `bedrooms`, `bathrooms`, `square_feet`, `garage`, `pool`, `year_built`, `subdivision`, `legal_description`, `property_type`, `lot_size_sqft` | RAW, CODE, BASELINE |
| REIQ date/file/instrument/list fields | `legal_timeline` | `source_list_type_slug`, `lead_type`, `record_date`, `date_filed`, `instrument_no`, `external_reference_id`, `document_id`, `case_number`, `situation_type`, `situation_status` | RAW, CODE, BASELINE |
| REIQ loan/equity/value fields | `valuation_financial` | `estimated_value`, `assessed_value`, `appraised_value`, `estimated_equity`, `equity_amount`, `equity_percentage`, `estimated_unpaid_balance`, `original_loan_amount`, `interest_rate`, `maturity_date`, `creditor_name`, `loan_type` | RAW, CODE, BASELINE |
| REIQ owner/mortgagor/ownership fields | `owner_ownership`, `owner_identity`, `party_roles` | `display_name`, `entity_type`, `first_name`, `last_name`, `ownership_type`, `owner_occupancy_status`, `absentee_owner`, `occupancy_hint`, `role_type`, `role_in_record` | RAW, CODE, BASELINE |
| REIQ owner mailing fields | `mailing_address` / `owner_contact_address` | `mailing_address`, `contact_address_type`, `mailing_equals_property`, `is_po_box`, `system_address`, `source_confidence` | RAW, CODE, BASELINE |
| REIQ `lead_type` / source list context | `systemic_taxonomy` plus `legal_timeline` provenance | `source_list_type`, `source_list_type_slug`, `lead_situation_type`, `system_property_tag`, `system_property_label`; do not auto-promote source list to final situation without Matrix/LF dictionary rule | RAW, CODE, BASELINE |

[FAMILY_FIELD_CANDIDATES]

Famílias recomendadas para LeadFinder dictionary v0, com candidatos iniciais. A lista prioriza campos com pelo menos um dos suportes locais acima e separa aliases/overlays de verdade canônica final.

1. `identity_address`
   - Objetivo: identidade física/endereço/parcel anchor do imóvel.
   - Campos iniciais: `street_address`, `secondary_address_line`, `address_number`, `street_line`, `street_name`, `street_pre_directional`, `street_post_type`, `street_post_directional`, `occupancy_type`, `occupancy_identifier`, `city`, `state`, `zip_code`, `county`, `country`, `apn`, `normalized_address`, `address_hash`, `latitude`, `longitude`, `provider_property_ref`.
   - Suporte: RAW DirectSkip/REIQ; CODE SourceHub `CanonicalPropertyLocationBlock`, `CanonicalAddressSeedBlock`, LeadFinder acquisition/hydration, `PropertyLocation`; BASELINE default genome.

2. `property_details`
   - Objetivo: características físicas, land/building e detalhes reduzidos para materialização.
   - Campos iniciais: `property_type`, `bedrooms`, `bathrooms`, `square_feet`, `year_built`, `garage`, `pool`, `lot_size_sqft`, `subdivision`, `legal_description`, `listing_status`, `listing_price`, `days_on_market`, `features`, `hoa_fee`, `hoa_name`, `neighborhood`.
   - Suporte: RAW REIQ para bed/bath/sqft/garage/pool/year/legal/subdivision; CODE normalizer/details model/Realtor materialization tests; BASELINE default genome para core reduced slice.
   - Nota: `estimated_value` aparece como details-seed em normalizer mas pertence semanticamente a `valuation_financial`; manter como cross-family candidate ou projection-only no seed.

3. `owner_identity`
   - Objetivo: identidade da entidade proprietária/pessoa/empresa antes de papéis ou contato.
   - Campos iniciais: `entity_type`, `display_name`, `legal_name`, `first_name`, `middle_name`, `last_name`, `full_name_normalized`, `age`, `is_deceased`, `company_name`, `company_name_normalized`, `company_ein`, `company_type`, `primary_address_normalized`, `slug_id`, `data_sources`, `source_confidence`.
   - Suporte: RAW DirectSkip names e REIQ mortgagor/owner fields; CODE `OwnerEntity`, SourceHub owner/projection blocks, LeadFinder hydration; BASELINE owner identity.

4. `owner_ownership`
   - Objetivo: relação owner-property e postura de ocupação/investidor.
   - Campos iniciais: `owner_ref`, `ownership_type`, `ownership_percentage`, `is_current`, `from_date`, `to_date`, `owner_occupancy_status`, `absentee_owner`, `occupancy_hint`, `is_absentee`, `absentee_state`, `is_in_state`, `investor_score`, `is_cash_buyer`, `portfolio_size`, `purchase_price`, `purchase_method`, `role_in_record`.
   - Suporte: RAW REIQ ownership/mortgagor hints; CODE `Ownership`, owner projection promotion rules; BASELINE default genome and owner_structural_position.

5. `mailing_address` / `owner_contact_address`
   - Objetivo: endereço de contato/mailing distinto da identidade física do imóvel.
   - Campos iniciais: `mailing_address`, `address_line`, `secondary_address_line`, `city`, `state`, `zip_code`, `county`, `country`, `normalized_address`, `address_hash`, `contact_address_type`, `address_type`, `is_primary`, `is_current`, `is_po_box`, `is_property`, `is_deliverable`, `mailing_equals_property`, `mailing_truth_status`, `property_address_match_status`, `property_address_confirmed_by_provider`, `validation_status`, `system_address`, `source_confidence`.
   - Suporte: RAW DirectSkip confirmed address and REIQ owner address fields; CODE SourceHub mailing/role address seed blocks and `OwnerContactAddress`; BASELINE default genome + owner_contact_address.

6. `contact_satellites` / `owner_phone` / `owner_email`
   - Objetivo: telefones/emails como satélites de contato da entidade, com qualidade/status operacional.
   - Campos phone: `phone_number`, `phone_normalized`, `phone_type`, `phone_subtype`, `contact_role`, `contact_source_confidence`, `status`, `is_valid`, `is_dnc`, `dnc_registered_at`, `dnc_reason`, `last_called_at`, `call_count`, `quality_score`.
   - Campos email: `email`, `email_address`, `email_normalized`, `email_type`, `contact_role`, `contact_source_confidence`, `status`, `is_valid`, `is_primary`, `bounce_type`, `bounce_reason`, `bounce_count`, `last_bounce_at`, `last_sent_at`, `sent_count`, `open_count`, `click_count`, `quality_score`.
   - Suporte: RAW DirectSkip phones/emails; CODE SourceHub contact seed blocks, LeadFinder hydration, `OwnerPhone`, `OwnerEmail`; BASELINE default genome + owner_phone/owner_email.

7. `party_roles`
   - Objetivo: papéis heterogêneos de pessoas/entidades em um registro sem forçar tudo a owner atual.
   - Campos iniciais: `party_ref`, `role_type`, `display_name`, `entity_type`, `first_name`, `middle_name`, `last_name`, `company_name`, `related_owner_ref`, `relationship`, `source_reference`, `is_current`, `source_confidence`.
   - Suporte: RAW REIQ mortgagor/owner role pressure, DirectSkip names adjacent to contact result; CODE `CanonicalPartyRoleSeedBlock`, `PartyRole`; BASELINE default genome + owner_structural_position.

8. `entity_representatives`
   - Objetivo: representação empresa -> pessoa quando provider ou resolução distinguir company owner de representante.
   - Campos iniciais: `representative_ref`, `company_owner_ref`, `role_type`, `display_name`, `first_name`, `last_name`, `title`, `is_active`, `from_date`, `to_date`, `source_reference`, `source_confidence`.
   - Suporte: CODE LeadFinder materialization family, SourceHub `CanonicalEntityRepresentativeSeedBlock`, `OwnerEntityRepresentative`, hydration/tests; BASELINE owner_structural_position has representative fields. RAW local direto: não observado no corpus estreito, portanto `code/baseline-supported`, não `raw-supported`.

9. `relationship_evidence`
   - Objetivo: evidência de parentes/associados e relação pessoa-pessoa sem promover a owner/property role.
   - Campos iniciais: `evidence_ref`, `display_name`, `first_name`, `middle_name`, `last_name`, `relationship_label`, `relationship_type`, `age`, `identity_resolution_status`, `possible_duplicate_of_owner`, `duplicate_intelligence_note`, `duplicate_resolution_vote_required`, `owner_match_confidence`, `relationship_evidence_confidence`, `phone_seeds`, `email_seeds`.
   - Suporte: RAW DirectSkip relatives; CODE SourceHub relationship seed, LeadFinder relationship materialization, `PersonRelationship`; BASELINE default genome + owner_relationship_evidence.

10. `legal_timeline`
    - Objetivo: datas/documentos/casos/list-origin que descrevem eventos legais e situação do imóvel.
    - Campos iniciais: `source_list_type_slug`, `lead_type`, `record_date`, `record_date_at`, `date_filed`, `date_filed_at`, `auction_date_time`, `court_hearing_date`, `date_of_death`, `date_of_death_at`, `case_number`, `document_id`, `instrument_no`, `external_reference_id`, `doc_type`, `situation_type`, `situation_status`.
    - Suporte: RAW REIQ date/file/instrument/lead type fields; CODE SourceHub legal timeline normalizer, `PropertySituation`, `PropertyEvent`; BASELINE default genome.

11. `valuation_financial`
    - Objetivo: valuation, equity, mortgage/loan/creditor evidence.
    - Campos iniciais: `estimated_value`, `assessed_value`, `appraised_value`, `estimated_equity`, `equity_amount`, `equity_percentage`, `mortgage_balance`, `estimated_unpaid_balance`, `original_loan_amount`, `interest_rate`, `historical_interest_rate`, `loan_type`, `maturity_date`, `maturity_date_at`, `new_principal_balance`, `monthly_principal_interest_payment`, `monthly_escrow_payment_amount`, `total_monthly_payment`, `payment_begins_on`, `interest_rate_date_change`, `months_to_pay`, `loan_origination_month`, `loan_origination_year`, `creditor_name`, `mortgagee_bank_name`, `min_bid`, `adjudged_value`.
    - Suporte: RAW REIQ loan/equity/value fields; CODE SourceHub valuation normalizer/contracts, `PropertyValuation`; BASELINE default genome.

12. `systemic_taxonomy`
    - Objetivo: taxonomy sistêmica de LeadFinder/search, distinta de tags/listas de workspace/subscriber.
    - Campos iniciais: `source_list_type`, `source_list_type_slug`, `lead_situation_type`, `active_situation_types`, `active_situation_statuses`, `system_property_tag`, `system_property_label`, `system_property_tag_slugs`, `system_property_label_slugs`, `owner_tag`, `phone_tag`, `email_tag`, `materialization_mode`.
    - Suporte: RAW REIQ lead/list type pressure; CODE `LeadFinderMaterializedTaxonomyBlock`, `SourceHubTaxonomyFramingBlock`, tests preventing workspace tags from masquerading as systemic lead taxonomy; BASELINE default genome.
    - Guardrail: não transformar `lead_type` ou provider list slug em situação canônica final sem regra do dictionary + Matrix artifact.

13. `source_lineage` / `provenance` (recomendado como família operacional/dictionary-adjacent)
    - Objetivo: preservar lineage e reprodutibilidade sem virar verdade de domínio final.
    - Campos iniciais: `provider_slug`, `list_type_slug`, `state_slug`, `canonical_schema_version`, `mapping_version`, `provider_mapping_ref`, `canonical_ontology_ref`, `raw_record_public_id`, `dto_public_id`, `payload_hash`, `ingested_at`, `processed_at`, `runtime_approval_mode`, `matrix_compiled_artifact_ref`, `matrix_compiled_artifact_version`, `lead_finder_published_contract_ref`, `lead_finder_published_contract_version`.
    - Suporte: RAW DirectSkip status/result-code path pressure; CODE SourceHub/LeadFinder contracts; BASELINE not a default materialization family. Recomendado manter como operational/provenance family para JSONB projection e audit, não materializar como entity truth.

14. `opportunity_intelligence` (defer/growth candidate)
    - Objetivo: score, qualification, queue/contact workflow; útil para LeadFinder operator/workspace mas derivado de materializações anteriores.
    - Campos iniciais: `current_score`, `current_classification`, `score_drivers_snapshot`, `qualification_status`, `queue_status`, `contact_attempt_count`, `connected_attempt_count`, `last_contacted_at`, `next_contact_at`, `last_contact_method`, `last_contact_outcome`, `qualified_at`, `disqualified_at`, `qualification_notes`, `last_scored_at`.
    - Suporte: CODE `LeadIntelligence`; RAW local: não observado diretamente; BASELINE default genome: não como família explícita. Recomendado como later/deferred, não v0 core.

[JSONB_PROJECTION_CANDIDATES]

Candidatos a projeção JSONB no LeadFinder dictionary/materialization v0. Objetivo: carregar evidência sem congelar colunas prematuras, mantendo lineage, decisão e auditabilidade.

1. `source_lineage_jsonb`
   - Conteúdo: provider/list/state, raw/dto public refs, mapping/dictionary refs, hashes, timestamps, Matrix artifact refs.
   - Justificativa: necessário para responder qual dictionary version, Matrix artifact, SourceHub publication e LF materialization aceitaram/rejeitaram o dado.
   - Suporte: SourceHub `CanonicalProvenanceBlock`, LeadFinder DTO input.

2. `raw_path_type_summary_jsonb`
   - Conteúdo: paths de campo, tipos estruturais, presença/ausência e contagens de arrays; sem valores.
   - Justificativa: permite revisar corpus local e gaps sem expor PII.
   - Suporte: issue 03 path/type strategy e raw-like local.

3. `field_mapping_candidates_jsonb`
   - Conteúdo: provider path -> candidate family/field -> confidence/reason/status.
   - Justificativa: Matrix consome dictionary version e raw evidence para produzir artifact; LF precisa registrar candidatos/gaps sem ownership confusion.
   - Suporte: corrected canonical cycle issue 03.

4. `owner_projection_candidates_jsonb`
   - Conteúdo: candidatos de owner/mortgagor/contact, candidate_source, confidence, rationale, occupancy/mailing hints.
   - Justificativa: REIQ/DirectSkip podem sugerir owner, mas LF só promove via regra conservadora.
   - Suporte: SourceHub `CanonicalOwnerProjectionCandidateBlock`, hydration promotion rule.

5. `contact_satellite_candidates_jsonb`
   - Conteúdo: phone/email seed candidates, role hints, source confidence, quality/status placeholders.
   - Justificativa: DirectSkip tem arrays de contacts, phones e emails; preservar multi-candidate sem colunas finais para cada posição de array.
   - Suporte: DirectSkip raw-like, SourceHub contact seed blocks, OwnerPhone/OwnerEmail baselines.

6. `relationship_evidence_candidates_jsonb`
   - Conteúdo: relatives/associates evidence refs, relationship labels/types, duplicate/intelligence hints, nested phone/email seeds.
   - Justificativa: parentes/associados não devem virar party role ou owner automaticamente.
   - Suporte: DirectSkip relatives, relationship evidence contracts/baselines.

7. `mailing_vs_property_comparison_jsonb`
   - Conteúdo: mailing truth status, property address match status, comparison basis, property-address-confirmed flag.
   - Justificativa: raw aponta endereços físicos e de contato; a comparação é semântica derivada, não raw truth simples.
   - Suporte: `PropertyAddressComparisonBlock`, owner_contact_address baseline.

8. `legal_timeline_evidence_jsonb`
   - Conteúdo: record/file/court/death dates, instrument/case/document refs, list/source type and doc type candidates.
   - Justificativa: nem todo campo legal deve virar coluna final no primeiro DDL; alguns são list-specific.
   - Suporte: REIQ raw-like, SourceHub legal timeline seed.

9. `loan_terms_evidence_jsonb`
   - Conteúdo: principal/payment/escrow/months/payment-begins/interest-change/origination fields.
   - Justificativa: REIQ loan modification tem granularidade maior que o default `valuation_financial` genome; guardar em evidence até dictionary N+1.
   - Suporte: SourceHub `CanonicalLoanTermsEvidenceBlock`; RAW REIQ loan/payment fields.

10. `operator_context_jsonb`
    - Conteúdo: comments/status/current-month-year/origination-period/source notes, sem valores sensíveis em relatório; em DB real deve seguir política de PII.
    - Justificativa: campos operacionais não são canonical domain truth, mas ajudam auditoria/backoffice.
    - Suporte: SourceHub `CanonicalOperatorContextBlock`, REIQ context pressure.

11. `taxonomy_framing_jsonb`
    - Conteúdo: source list type, system hints, mapping version, materialization mode, rejected/promoted taxonomy decisions.
    - Justificativa: manter `source_list_type_slug` distinto de `situation_type` canônico.
    - Suporte: SourceHub `SourceHubTaxonomyFramingBlock`, LeadFinder taxonomy block/tests.

12. `growth_pressure_signals_jsonb`
    - Conteúdo: missing_field, unsupported_provider_path, conflicting_family_candidate, confidence, proposed dictionary action.
    - Justificativa: LF-owned dictionary deve evoluir a partir de gaps, não deixar Matrix/SourceHub virar dono de canonical truth.
    - Suporte: issue 03 corrected cycle; PRD issue 04 goals for gaps/growth signals.

[GAPS]

- Corpus local raw-like é estreito: somente 1 DirectSkip raw-like e 1 REIQ loan_modification/fl raw-like foram usados como path/type evidence.
- Private corpus reportado pela issue 03 está vazio; sem amostras adicionais nesta rodada.
- Realtor tem code/test evidence mas sem raw-like JSON local; não marcar campos Realtor-only como raw-supported.
- `entity_representatives` é forte em contracts/models/hydration, mas sem suporte raw local direto nos dois arquivos raw-like consultados.
- `opportunity_intelligence` é code-supported, mas não baseline/raw-supported como família v0 core; deve ser deferred/growth.
- `source_lineage` é essencial para audit/contract, porém não aparece como family_catalog no default LeadFinder genome; tratar como operational/provenance family ou dictionary-adjacent, não materialização de entidade.
- Loan modification REIQ expõe granularidade financeira/loan maior que o default `valuation_financial`; usar JSONB evidence/growth pressure antes de criar muitas colunas finais.
- `lead_type`/`source_list_type_slug` não deve virar automaticamente `situation_type`; precisa regra no dictionary + Matrix artifact + SourceHub publication.
- Campos raw com strings numéricas/datas precisam type normalization antes de materialização; o relatório não valida valores nem formatos reais.
- Sem inspeção de banco/linhas runtime; evidência é arquivo/código/test local.

[RECOMMENDATION]

1. Criar LeadFinder dictionary v0 com core families:
   - `identity_address`
   - `property_details`
   - `owner_identity`
   - `owner_ownership`
   - `mailing_address` / `owner_contact_address`
   - `contact_satellites`
   - `party_roles`
   - `relationship_evidence`
   - `legal_timeline`
   - `valuation_financial`
   - `systemic_taxonomy`
   - `source_lineage` como operational/provenance family ou dictionary-adjacent.

2. Incluir `entity_representatives` como code/baseline-supported family candidate, mas marcar initial materialization status como `seed_only`/`defer_with_proof` até raw evidence ou use case explícito.

3. Manter `opportunity_intelligence` fora do core v0 DDL de dictionary/final fields; registrar como growth/deferred family candidate.

4. Para cada campo seeded, persistir metadata mínima:
   - `family_key`
   - `field_key`
   - `canonical_name`
   - `semantic_type`
   - `field_class` (`data`, `evidence`, `operational`, `derived`)
   - `support_level` (`raw_supported`, `code_supported`, `baseline_supported`)
   - `source_evidence_refs` por path/código/baseline, sem valores
   - `materialization_policy` (`materialize_now`, `materialize_reduced_slice_now`, `seed_only`, `defer_with_proof`)
   - `jsonb_projection_candidate` boolean/reason.

5. Usar JSONB para evidence/candidates/provenance em vez de criar colunas finais para cada provider-specific detalhe, especialmente:
   - raw path/type summaries
   - field mapping candidates
   - owner/contact/relationship candidates
   - loan terms granular evidence
   - taxonomy framing
   - growth pressure signals.

6. Guardrail para DDL subsequente: nenhuma coluna final provider-derived deve ser adicionada sem apontar para:
   - LeadFinder dictionary version
   - Matrix artifact/mapping session
   - SourceHub publication/handoff
   - LeadFinder materialization acceptance/rejection.

7. Tratar Matrix `canonical_*` existente como mirror/candidate experimental, não como owner da verdade canônica. LeadFinder deve possuir dictionary versions/families/fields/gaps/growth signals; Matrix consome essa versão para mapear raw/provider paths.
