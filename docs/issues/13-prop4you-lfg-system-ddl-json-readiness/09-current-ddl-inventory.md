# Inventário DDL atual — PG18 Prop4You/LFG readiness

Status: worker-b-complete
Escopo: `database/ddl/projects/prop4you`
Método: leitura estática local dos arquivos SQL/README; sem browser/web/MCP/provider calls; sem valores de payload/PII.

## 1. Sumário executivo

O DDL atual já cobre uma esteira experimental completa até o mínimo operacional de LFG:

```text
Provider registry
  -> SourceHub raw/corpus/lineage/enrichment/translated DTO
  -> Matrix semantic mirror + mapping/extraction/quality/field_mapping_set artifacts
  -> LeadFinder canonical dictionary/gaps/promotion review/apply
  -> LeadFinder Group staging/materialization/operational groups/facets
  -> LFG feedback marker votes/aggregate/review/global apply gate
```

Resultado para readiness:

- Pronto para auditoria de pipeline e contratos JSON/DDL: sim.
- Pronto para ser tratado como baseline LFG final para construir `prop4you_user_workspace` rico: não.
- Pronto para um workspace mínimo baseado em weak refs/snapshots/version/hash: parcialmente, desde que o workspace não assuma owner/property/contact/scoring canônicos finais.

Principais razões: o pacote ainda é `experimental / non-final`; `prop4you_user_workspace` é apenas schema/comentário; várias pastas de domínio legado existem só com README; não há tabelas finais de property/owner/contact/geography/identity/skiptrace/realtor; LFG operacional é mínimo e facetado, não o grafo legado completo.

## 2. Arquivos DDL inventariados

Arquivos SQL atuais:

```text
0001_schemas.sql
providers/0001_provider_registry.sql
sourcehub/0001_sourcehub_corpus.sql
sourcehub/0002_translated_dto_publications.sql
matrix/0001_semantic_dictionary.sql
matrix/0002_mapping_sessions.sql
matrix/0003_raw_path_extractors.sql
matrix/0004_quality_report_artifacts.sql
matrix/0005_field_mapping_set_artifacts.sql
leadfinder/0001_canonical_dictionary.sql
leadfinder/0002_raw_evidence_gap_bridge.sql
leadfinder/0003_prepare_dictionary_promotions.sql
leadfinder/0004_dictionary_promotion_review_apply.sql
leadfinder_group/0001_staging_candidates.sql
leadfinder_group/0002_materialization_runs.sql
leadfinder_group/0003_operational_minimum.sql
leadfinder_group/0004_user_feedback_markers.sql
```

Pastas sem DDL além de README/skeleton, relevantes para gaps:

```text
geography/
identity/
internal/
owner/
property/
realtor/
reiq/
skiptrace/
user_workspace/
```

## 3. Contagem de objetos DDL

Leitura estática encontrou:

| Tipo | Total |
| --- | ---: |
| schemas | 6 |
| tables | 37 |
| views | 12 |
| functions | 25 |
| triggers | 43 |

Schemas:

```text
prop4you_provider
prop4you_sourcehub
prop4you_matrix
prop4you_leadfinder
prop4you_leadfinder_group
prop4you_user_workspace
```

Observação: `prop4you_user_workspace` existe só como boundary/schema comentado. Não possui tabelas, views, funções ou políticas neste pacote atual.

## 4. Inventário por schema

### 4.1 `prop4you_provider`

Papel: registro de provedores/classes de payload e funções JSONB utilitárias.

Tabelas:

```text
providers
payload_classes
provider_payload_classes
```

Funções:

```text
jsonb_path_exists(payload jsonb, path text[])
jsonb_path_type(payload jsonb, path text[])
jsonb_path_text(payload jsonb, path text[])
jsonb_leaf_paths(payload jsonb, max_depth integer default 8)
```

Famílias/provedores cobertos por seed:

```text
reiq                 -> property_search_result
realtor_com          -> property_detail
directskip           -> skip_trace_result
prop4you_internal    -> leadfinder_candidate_snapshot
```

Cobertura: boa como registry e utilitário de introspecção JSONB. Não implementa chamadas a providers, credenciais, rate limit, retry, workers ou persistência provider-específica detalhada.

### 4.2 `prop4you_sourcehub`

Papel: ingressão, corpus, lineage, enrichment queue e publicação de DTO traduzido.

Tabelas:

```text
raw_records
corpus_samples
source_lineage_edges
enrichment_requests
translated_dto_publications
```

Views:

```text
v_translated_dto_publication_review
```

Funções:

```text
enqueue_enrichment_request(...)
mark_enrichment_response(...)
validate_translated_dto_publication()
publish_translated_dtos_from_field_mapping_set(...)
```

Cobertura: cobre raw records, amostras, lineage edge, fila declarativa de enriquecimento e publicação T4 de DTOs a partir de Matrix `field_mapping_set` + LeadFinder dictionary version.

Gaps: não há provider workers; não há política de retenção/particionamento; não há canonical owner/property tables; translated DTO permanece contrato JSONB/gateway-agnostic, não materialização final.

### 4.3 `prop4you_matrix`

Papel: semântica/mapeamento/artifacts; mirror/candidate/review, não dono final do dicionário.

Tabelas:

```text
canonical_families
canonical_fields
mapping_versions
provider_path_mappings
mapping_reviews
mapping_sessions
transformation_artifacts
artifact_field_mappings
raw_path_extraction_runs
raw_path_summary_evidence
```

Views:

```text
v_raw_record_leaf_path_evidence
v_raw_path_current_summary
v_quality_report_artifacts
v_field_mapping_set_artifacts
```

Funções:

```text
jsonb_path_label(path text[])
refresh_raw_path_summary_evidence(...)
raw_record_path_type_evidence(...)
create_raw_path_quality_report_artifact(...)
create_field_mapping_set_from_gap_bridges(...)
```

Famílias Matrix seedadas:

```text
property_identity
owner_identity
owner_contact
situation_legal
valuation_financial
listing_history_media
lineage_provenance
```

Cobertura: boa para path extraction, mapping sessions, quality reports e artifact bridge até `field_mapping_set`. O DDL explicita que `canonical_*` aqui é mirror/candidate/review e que LeadFinder é autoridade do dicionário.

Gaps: não resolve semanticamente todos os paths legados; não congela tabelas finais; ainda depende de auditoria JSON/path para saber se os families/fields são suficientes.

### 4.4 `prop4you_leadfinder`

Papel: dono do dicionário canônico experimental, gaps, pressure signals e promotion gate.

Tabelas:

```text
canonical_dictionary_versions
canonical_families
canonical_fields
canonical_gaps
growth_pressure_signals
raw_evidence_gap_bridges
dictionary_promotion_preparations
dictionary_promotion_reviews
dictionary_promotion_applications
```

Views:

```text
v_raw_evidence_gap_bridge_review
v_dictionary_promotion_preparation_review
v_dictionary_promotion_apply_review
```

Funções:

```text
propose_raw_evidence_gap_bridge(...)
bridge_raw_evidence_gap_candidates(...)
prepare_dictionary_promotions_from_field_mapping_set(...)
review_dictionary_promotion(...)
apply_dictionary_promotion_review(...)
```

Famílias LeadFinder seedadas no dicionário `leadfinder.raw_candidate.v0`:

```text
property_identity
property_details
property_media
property_history
situation_legal
valuation_financial
owner_identity
ownership_history
party_roles
owner_contact_address
owner_phone
owner_email
relationship_evidence
lead_opportunity
source_lineage
```

Campos seedados por família:

```text
property_identity: property_reference, address_identity, parcel_or_apn
property_details: property_type, structure_attributes
property_media: media_presence, media_count
property_history: event_timeline, last_observed_at
situation_legal: situation_type, situation_status, situation_event_date
valuation_financial: estimated_value, equity_indicator, loan_or_lien_indicator
owner_identity: owner_reference, owner_name_identity, owner_entity_type
ownership_history: ownership_start_date, transfer_event
party_roles: party_role_type, role_confidence
owner_contact_address: mailing_address_identity, address_deliverability
owner_phone: phone_identity, phone_quality
owner_email: email_identity, email_quality
relationship_evidence: relationship_type, relationship_confidence
lead_opportunity: opportunity_type, lead_score_signal, workflow_stage_candidate
source_lineage: source_system, raw_record_reference, mapping_review_reference
```

Cobertura: o dicionário já modela property/owner/contact/situation/valuation/lineage/lead opportunity como famílias semânticas. Também possui fluxo explícito de bridge/gap/pressure e review/apply para promoções.

Gaps: ainda são candidatos semânticos; não há grafo final de leads, owners, ownership, contacts, property facts, scores/listas/workflows. A seed é ampla, mas não prova completude frente ao legado e ao corpus JSON.

### 4.5 `prop4you_leadfinder_group`

Papel: LFG/system global e materialização operacional mínima.

Tabelas:

```text
staging_candidates
materialization_runs
materialization_results
operational_groups
operational_group_events
operational_group_facets
user_feedback_votes
feedback_marker_aggregates
feedback_marker_reviews
global_item_markers
```

Views:

```text
v_staging_candidate_review
v_materialization_result_review
v_operational_group_review
v_feedback_marker_review_queue
```

Funções:

```text
stage_candidates_from_translated_dto_publications(...)
materialize_staging_candidates(...)
promote_materialization_results_to_operational_minimum(...)
refresh_feedback_marker_aggregate(...)
record_user_feedback_vote(...)
open_feedback_marker_review(...)
apply_feedback_marker_review(...)
```

Feedback markers:

```text
item_kind: phone, email, mailing_address, owner, property, contact, group, facet, unknown
marker_kind: dnc, wrong, invalid, stale, corrected, verified, unreachable, deliverable, undeliverable, other
vote_value: assert, dispute, confirm, withdraw
recommendation: insufficient_signal, human_review_candidate, auto_apply_candidate, reject_candidate, conflict_review
```

Boundary com workspace: `user_feedback_votes` guarda `workspace_ref`, `workspace_account_ref`, `user_ref`, `snapshot_ref`, `campaign_ref` como weak refs/textual refs e exige `workspace_schema_name = 'prop4you_user_workspace'`. O agregado e o global marker incluem lineage/metadados indicando relação fraca e ausência de auto-promoção global por voto único.

Cobertura: boa para provar staging -> materialization -> operational groups/facets e feedback global por review/apply.

Gaps: `operational_groups/facets` é mínimo, JSONB/facetado e não substitui um modelo legado final de property/owner/contact/lead. Não há RLS/API workspace, campanhas/listas tenant, snapshots locais ou billing/usage/export.

### 4.6 `prop4you_user_workspace`

Papel declarado: boundary do usuário logado.

Objetos atuais:

```text
schema only
```

Comentário do schema indica futuro ownership de selections, snapshots, annotations, lists, actions, local markers, refresh decisions e workflow state. Porém nada disso está implementado ainda.

## 5. Famílias cobertas x superfície legado esperada

Coberto por DDL atual:

| Família/superfície | Cobertura atual |
| --- | --- |
| Provider registry | Sim, registry genérico para REIQ/DirectSkip/Realtor/Internal |
| Raw ingress/corpus | Sim, SourceHub `raw_records` e `corpus_samples` |
| Lineage | Sim, SourceHub edges + refs em DTO/artifacts/materialização |
| JSON path evidence | Sim, Matrix extractor/summary |
| Semantic mirror/review | Sim, Matrix families/fields/reviews/artifacts |
| LeadFinder dictionary | Sim, candidato v0 com 15 famílias e 36 campos seedados |
| Gap/pressure loop | Sim, bridge/gaps/growth_pressure_signals |
| DTO publication | Sim, SourceHub translated DTO publications |
| LFG staging/materialization | Sim, staging_candidates/materialization_runs/results |
| LFG operational minimum | Sim, groups/events/facets |
| Feedback markers | Sim, votes/aggregates/reviews/global markers |
| Dictionary promotion apply | Sim, preparation/review/application |
| User workspace | Boundary apenas; sem implementação |

Gaps frente ao modelo legado/system esperado:

| Área legado/system | Gap DDL atual |
| --- | --- |
| `system` como boundary separado | Representado conceitualmente por LFG/SourceHub/Matrix, mas não há schema `system` nem inventário legado materializado 1:1. |
| Property/real estate final | Pasta `property/` só README; nenhuma tabela final de property, parcel/APN, address, facts, valuations. |
| Owner/party final | Pasta `owner/` só README; sem owner canonical, owner-property link, party resolution final. |
| Contact final | Contatos aparecem como fields/facets/markers; sem phone/email/address contact graph final. |
| Geography | Pasta `geography/` só README; sem geocoding/county/state/city/geometry final. |
| Identity/account/workspace | Pasta `identity/` e `user_workspace/` só README/schema; sem tenant/account/user/workspace tables. |
| SkipTrace/Realtor/REIQ específicos | Registries/classes existem; pastas específicas só README; sem DDL provider-specific. |
| Lead lists/searches/scoring | `lead_opportunity` é semântico; sem lead list, search, campaign, scoring final. |
| Tags/labels workspace | Global LFG markers existem; marcadores/tags/labels locais workspace não existem. |
| RLS/API facade | Nenhuma policy/API facade inventariada neste pacote. |
| Jobs/outbox/realtime | Enrichment requests existem como tabela; sem pgmq/outbox/cron/realtime contracts específicos do domínio. |
| Retenção/particionamento/ops | Sem políticas de retenção, particionamento ou manutenção para raw/staging/materialization. |

## 6. Risco de partir para `prop4you_user_workspace` agora

Risco: alto para workspace completo; médio para workspace mínimo baseado em snapshots/refs.

Riscos concretos:

1. Congelar contratos workspace sobre facetas LFG experimentais pode cristalizar nomes/estruturas antes da comparação system x DDL x JSON.
2. Workspace pode confundir marcador global LFG com marcador local de tenant se não houver tabelas próprias de escopo/auditoria/RLS.
3. Snapshots de property/owner/contact podem nascer sobre DTOs incompletos, gerando migração cara quando owner/property/contact final for modelado.
4. Sem identity/account/workspace tables, qualquer FK real para usuário/workspace seria prematura; por isso o DDL atual usa weak refs textuais.
5. Sem RLS/API facade, não há superfície segura tenant-visible para expor as tabelas LFG diretamente.
6. Sem política de refresh/version/hash local, o workspace pode consumir LFG como truth estática quando a arquitetura exige snapshots/versionamento.

Caminho seguro: manter LFG como upstream interno e só iniciar workspace com contratos mínimos de referência/snapshot/version/hash depois da matriz consolidada do issue 13. Evitar property/owner/contact final e evitar tags/markers locais até o inventário legado + JSON confirmar semântica.

## 7. Veredito Worker B

Veredito DDL-only: ready-with-gaps.

O DDL atual é coerente para uma prova pipeline database-centric e já inclui SourceHub, Matrix, LeadFinder, LFG operational minimum, feedback markers e boundary de workspace. Porém ele ainda não está completo contra o modelo legado/system nem contra o corpus JSON. O próximo passo não deve ser construir o workspace completo; deve ser consolidar a matriz system x DDL x JSON e decidir quais gaps viram o próximo slice DDL.

Recomendação para Thor/T5:

```text
1. Cruzar Worker A legacy system inventory com as famílias LeadFinder/Matrix acima.
2. Cruzar Worker C JSON/path inventory com SourceHub/Matrix path evidence e fields do dictionary v0.
3. Classificar cada área como: covered, weak-ref-only, semantic-candidate-only, missing-final-table, or intentionally-out-of-scope.
4. Só depois escolher entre:
   a) ampliar LFG/system canonical graph; ou
   b) iniciar workspace mínimo de snapshot/ref com contrato explicitamente fraco.
```
