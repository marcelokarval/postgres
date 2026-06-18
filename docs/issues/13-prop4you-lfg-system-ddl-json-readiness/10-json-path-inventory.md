# Worker C — Inventário JSON/path do corpus LFG

Status: concluído
Escopo: corpus JSON local de REIQ / loan_modification / FL.
Raiz analisada: `/home/marcelo-karval/Backup/Projetos/prop4you/prop4you-inertia/backend/src/apps/system/matrix/registry/reiq/loan_modification/fl`

## Política de redação

Este inventário registra somente evidências estruturais: contagens, classes de arquivo, tipos raiz, nomes de chaves e famílias de JSON paths.

Não foram copiados valores de campos, exemplos de payload, nomes de pessoas, endereços, IDs reais, números de processo/instrumento, valores financeiros ou qualquer outro dado potencialmente PII. Exemplos de nomes de arquivos foram redigidos com placeholders como `session_mxsess_<redacted>.json` e `<uuid-redacted>.json`.

## Metodologia

- Varredura recursiva de `*.json` sob a raiz do corpus.
- Parsing JSON local com Python `json.loads`.
- Classificação por diretório/função do artefato.
- Caminhos representados em notação JSONPath-like, usando `[]` para elementos de array e sem índices reais.
- Tipos registrados como `object`, `array`, `string`, `number`, `boolean` ou `null`.
- Valores nunca foram emitidos no artefato.

## Resultado geral

| Métrica | Resultado |
| --- | ---: |
| Arquivos JSON encontrados | 97 |
| Arquivos JSON parseados com sucesso | 97 |
| Erros de parsing | 0 |
| Tipos raiz observados | todos `object` |
| Pares únicos path+tipo observados | 3.685 |

Observação: há 1 artefato `analysis/discrepancy` com objeto raiz vazio; por isso essa classe tem 19 arquivos, mas suas chaves top-level aparecem em 18 arquivos.

## Contagem por classe

| Classe | Padrão de caminho redigido | Arquivos | Tipo raiz | Chaves top-level distintas | Pares path+tipo únicos |
| --- | --- | ---: | --- | ---: | ---: |
| `analysis/baseline-only` | `analysis/baseline-only/session_mxsess_<redacted>.json` | 19 | object | 13 | 3.359 |
| `analysis/contextual` | `analysis/contextual/session_mxsess_<redacted>.json` | 19 | object | 13 | 133 |
| `analysis/discrepancy` | `analysis/discrepancy/session_mxsess_<redacted>.json` | 19 | object | 7 | 28 |
| `context` | `context.json` | 1 | object | 7 | 23 |
| `contracts` | `contracts/session_mxsess_<redacted>.json` | 19 | object | 10 | 78 |
| `data/source_manifest` | `data/session_mxsess_<redacted>_source_manifest.json` | 19 | object | 9 | 51 |
| `data/source_payload` | `data/YYYY-MM-DD/FL_loan-modification_<uuid-redacted>.json` | 1 | object | 51 | 52 |

## Chaves top-level por classe

### `analysis/baseline-only` — 19/19 arquivos

- `alias_evidence_snapshot`
- `artifact_kind`
- `baseline_version`
- `canonical_dictionary_snapshot`
- `coverage_snapshot`
- `list_type_slug`
- `multi_provider_snapshot`
- `provider_drift_snapshot`
- `provider_slug`
- `published_contract_ref`
- `session_key`
- `session_public_id`
- `state_slug`

### `analysis/contextual` — 19/19 arquivos

- `artifact_kind`
- `baseline_version`
- `context_lineage`
- `dataset_discrepancy_snapshot`
- `field_analysis`
- `list_type_slug`
- `matrix_context_snapshot`
- `provider_slug`
- `published_contract_ref`
- `session_key`
- `session_public_id`
- `state_slug`
- `workspace_snapshot`

### `analysis/discrepancy` — 18/19 arquivos com chaves; 1/19 objeto vazio

- `cross_field_patterns`
- `dataset_profile`
- `field_discrepancies`
- `list_type_slug`
- `provider_slug`
- `source_dataset_dir`
- `state_slug`

### `context` — 1/1 arquivo

- `provider_slug`
- `list_type_slug`
- `state_slug`
- `source_dataset_dir`
- `provider_semantics_rules`
- `known_field_notes`
- `dataset_assumptions`

### `contracts` — 19/19 arquivos, exceto `effective_contract_snapshots` em 13/19

- `artifact_kind`
- `baseline_version`
- `context_lineage`
- `contract_refs`
- `list_type_slug`
- `provider_slug`
- `published_contract_ref`
- `session_public_id`
- `state_slug`
- `effective_contract_snapshots`

### `data/source_manifest` — 19/19 arquivos

- `artifact_kind`
- `corpus_stats`
- `list_type_slug`
- `provider_slug`
- `session_key`
- `session_public_id`
- `source_manifest`
- `source_surface`
- `state_slug`

### `data/source_payload` — 1/1 arquivo

Payload fonte tabular achatado com 51 chaves top-level. Nomes de chaves observados, sem valores:

- `internal_id`
- `date_added`
- `date_filed`
- `county`
- `file_number`
- `loan_modification_instrument_number`
- `mortgagor_first_name`
- `mortgagor_last_name`
- `property_address`
- `property_city`
- `property_state`
- `property_zip_code`
- `bed`
- `bath`
- `sq_ft`
- `garage`
- `pool`
- `yr_bt`
- `mortgagee_bank_name`
- `estimated_equity`
- `equity`
- `estimated_unpaid_balance`
- `original_loan_amount`
- `historical_interest_rate`
- `assessed_value`
- `appraised_value`
- `current_month`
- `current_year`
- `loan_origination_month`
- `loan_origination_year`
- `new_principal_balance`
- `maturity_date`
- `months_to_pay`
- `interest_rate`
- `interest_rate_date_change`
- `monthly_principal_interest_payment`
- `monthly_escrow_payment_amount`
- `total_monthly_payment`
- `payment_begins_on`
- `legal_description`
- `subdivision`
- `ownership`
- `owner_first_name`
- `owner_last_name`
- `owner_address`
- `owner_city`
- `owner_state`
- `owner_zip_code`
- `property_id`
- `comments`
- `lead_type`

## Famílias de JSON paths observadas

### Corpus bruto / payload fonte

Estrutura: objeto achatado, sem arrays no arquivo fonte observado.

Famílias de campos por nome de path:

- Identificação operacional: `$.internal_id`, `$.property_id`, `$.lead_type`, `$.comments`
- Datas e prazos: `$.date_added`, `$.date_filed`, `$.maturity_date`, `$.payment_begins_on`, `$.interest_rate_date_change`, `$.current_month`, `$.current_year`, `$.loan_origination_month`, `$.loan_origination_year`, `$.months_to_pay`
- Documento / filing: `$.county`, `$.file_number`, `$.loan_modification_instrument_number`
- Partes / nomes: `$.mortgagor_first_name`, `$.mortgagor_last_name`, `$.owner_first_name`, `$.owner_last_name`, `$.mortgagee_bank_name`, `$.ownership`
- Endereço do imóvel: `$.property_address`, `$.property_city`, `$.property_state`, `$.property_zip_code`
- Endereço postal/owner: `$.owner_address`, `$.owner_city`, `$.owner_state`, `$.owner_zip_code`
- Atributos físicos: `$.bed`, `$.bath`, `$.sq_ft`, `$.garage`, `$.pool`, `$.yr_bt`, `$.legal_description`, `$.subdivision`
- Valores financeiros / loan: `$.estimated_equity`, `$.equity`, `$.estimated_unpaid_balance`, `$.original_loan_amount`, `$.historical_interest_rate`, `$.assessed_value`, `$.appraised_value`, `$.new_principal_balance`, `$.interest_rate`, `$.monthly_principal_interest_payment`, `$.monthly_escrow_payment_amount`, `$.total_monthly_payment`

Campos com alta sensibilidade por nome de chave: nomes de pessoas, endereços, identificadores documentais, legal description e valores financeiros. O DDL deve manter raw lineage separado de projeções canônicas/operacionais.

### Discrepancy analysis

Famílias estruturais:

- `$.dataset_profile`
- `$.dataset_profile.fingerprint_fields[]`
- `$.dataset_profile.golden_record_path`
- `$.dataset_profile.non_null_density`
- `$.dataset_profile.sample_count`
- `$.field_discrepancies[]`
- `$.field_discrepancies[].field_name`
- `$.field_discrepancies[].presence_rate`
- `$.field_discrepancies[].meaningful_rate`
- `$.field_discrepancies[].null_rate`
- `$.field_discrepancies[].empty_string_rate`
- `$.field_discrepancies[].observed_types`
- `$.field_discrepancies[].observed_types.str`
- `$.field_discrepancies[].observed_types.NoneType`
- `$.field_discrepancies[].examples[]` — valores não inventariados, apenas path
- `$.cross_field_patterns[]`
- `$.cross_field_patterns[].pattern_key`
- `$.cross_field_patterns[].match_rate`
- `$.cross_field_patterns[].summary`

### Contextual analysis

Famílias estruturais:

- `$.context_lineage`
- `$.dataset_discrepancy_snapshot`
- `$.dataset_discrepancy_snapshot.dataset_profile`
- `$.dataset_discrepancy_snapshot.dataset_profile.fingerprint_fields[]`
- `$.dataset_discrepancy_snapshot.field_discrepancies[]`
- `$.dataset_discrepancy_snapshot.field_discrepancies[].field_name`
- `$.dataset_discrepancy_snapshot.field_discrepancies[].presence_rate`
- `$.dataset_discrepancy_snapshot.field_discrepancies[].meaningful_rate`
- `$.dataset_discrepancy_snapshot.field_discrepancies[].null_rate`
- `$.dataset_discrepancy_snapshot.field_discrepancies[].empty_string_rate`
- `$.dataset_discrepancy_snapshot.field_discrepancies[].observed_types`
- `$.dataset_discrepancy_snapshot.field_discrepancies[].examples[]` — valores não inventariados, apenas path
- `$.dataset_discrepancy_snapshot.cross_field_patterns[]`
- `$.field_analysis`
- `$.matrix_context_snapshot`
- `$.matrix_context_snapshot.business_context.primary_semantic_focus[]`
- `$.matrix_context_snapshot.opportunity_signals[]`
- `$.matrix_context_snapshot.target_roles[]`
- `$.matrix_context_snapshot.provider_semantics_rules[]`
- `$.matrix_context_snapshot.provider_semantics_rules[].rule_key`
- `$.matrix_context_snapshot.provider_semantics_rules[].when`
- `$.matrix_context_snapshot.provider_semantics_rules[].effect`
- `$.matrix_context_snapshot.provider_semantics_rules[].reasoning`
- `$.matrix_context_snapshot.known_field_notes[]`
- `$.matrix_context_snapshot.dataset_assumptions[]`
- `$.workspace_snapshot`
- `$.workspace_snapshot.corpus.provider_drift_snapshot.new_fields[]`
- `$.workspace_snapshot.review_queue.review_public_ids[]`

### Baseline-only analysis / canonical dictionary snapshot

Famílias estruturais predominantes:

- `$.alias_evidence_snapshot.entries[]`
- `$.alias_evidence_snapshot.entries[].alias`
- `$.alias_evidence_snapshot.entries[].normalized_alias`
- `$.alias_evidence_snapshot.entries[].canonical_field`
- `$.alias_evidence_snapshot.entries[].semantic_type`
- `$.alias_evidence_snapshot.entries[].family`
- `$.alias_evidence_snapshot.entries[].confidence`
- `$.alias_evidence_snapshot.entries[].match_type`
- `$.alias_evidence_snapshot.entries[].source_kind`
- `$.alias_evidence_snapshot.entries[].source_ref`
- `$.alias_evidence_snapshot.entries[].verified`
- `$.canonical_dictionary_snapshot.alias_entries[]`
- `$.canonical_dictionary_snapshot.alias_evidence_snapshot.entries[]`
- `$.canonical_dictionary_snapshot.canonical_fields.<field_name>.aliases[]`
- `$.canonical_dictionary_snapshot.canonical_fields.<field_name>.transforms[]`
- `$.canonical_dictionary_snapshot.canonical_fields.<field_name>.transforms[].type`
- `$.canonical_dictionary_snapshot.families.identity_address[]`
- `$.canonical_dictionary_snapshot.families.legal_timeline[]`
- `$.canonical_dictionary_snapshot.families.valuation_financial[]`
- `$.canonical_dictionary_snapshot.families.owner_ownership[]`
- `$.canonical_dictionary_snapshot.families.property_details[]`
- `$.canonical_dictionary_snapshot.families.relationship_evidence[]`
- `$.canonical_dictionary_snapshot.families.mailing_address[]`
- `$.canonical_dictionary_snapshot.families.systemic_taxonomy[]`
- `$.coverage_snapshot`
- `$.multi_provider_snapshot`
- `$.provider_drift_snapshot.new_fields[]`

### Contracts

Famílias estruturais:

- `$.contract_refs`
- `$.contract_refs.baseline_only_analysis_contract`
- `$.contract_refs.contextual_analysis_contract`
- `$.contract_refs.dataset_discrepancy_report_contract`
- `$.contract_refs.source_manifest_contract`
- `$.context_lineage`
- `$.effective_contract_snapshots`
- `$.effective_contract_snapshots.contracts.source_manifest_contract.required_keys[]`
- `$.effective_contract_snapshots.contracts.dataset_discrepancy_report_contract.required_keys[]`
- `$.effective_contract_snapshots.contracts.dataset_discrepancy_report_contract.dataset_profile_required_keys[]`
- `$.effective_contract_snapshots.contracts.baseline_only_analysis_contract.required_keys[]`
- `$.effective_contract_snapshots.contracts.contextual_analysis_contract.required_keys[]`
- `$.effective_contract_snapshots.context.list_context.business_context.primary_semantic_focus[]`
- `$.effective_contract_snapshots.context.list_context.opportunity_signals[]`
- `$.effective_contract_snapshots.context.list_context.target_roles[]`
- `$.effective_contract_snapshots.context.state_context.provider_semantics_rules[]`
- `$.effective_contract_snapshots.context.state_context.known_field_notes[]`
- `$.effective_contract_snapshots.context.state_context.dataset_assumptions[]`

### Source manifests

Famílias estruturais:

- `$.corpus_stats`
- `$.corpus_stats.payload_count`
- `$.corpus_stats.observed_field_count`
- `$.corpus_stats.matched_field_count`
- `$.corpus_stats.alias_match_count`
- `$.corpus_stats.semantic_match_count`
- `$.corpus_stats.llm_match_count`
- `$.corpus_stats.conflict_field_count`
- `$.corpus_stats.coverage_snapshot`
- `$.corpus_stats.coverage_snapshot.namespace_coverage.root.field_count`
- `$.corpus_stats.coverage_snapshot.namespace_coverage.root.observed_count`
- `$.corpus_stats.coverage_snapshot.namespace_coverage.root.avg_fill_rate`
- `$.corpus_stats.multi_provider_snapshot`
- `$.corpus_stats.provider_drift_snapshot`
- `$.corpus_stats.provider_drift_snapshot.new_fields[]`
- `$.corpus_stats.provider_drift_snapshot.missing_fields[]`
- `$.corpus_stats.review_public_ids[]`
- `$.corpus_stats.source_corpus_refs[]`
- `$.source_manifest`
- `$.source_surface`

### Context file

Famílias estruturais:

- `$.provider_semantics_rules[]`
- `$.provider_semantics_rules[].rule_key`
- `$.provider_semantics_rules[].when`
- `$.provider_semantics_rules[].effect`
- `$.provider_semantics_rules[].reasoning`
- `$.known_field_notes[]`
- `$.known_field_notes[].field_name`
- `$.known_field_notes[].semantic_reading`
- `$.known_field_notes[].operator_note`
- `$.dataset_assumptions[]`

## Implicações para readiness LFG/DDL

1. O corpus mistura três camadas que o DDL deve preservar separadas: payload fonte bruto, artefatos de análise/mapeamento e contratos/publicação.
2. O payload fonte é achatado e PII-heavy por nome de chave; é candidato claro a armazenamento raw JSONB com lineage, acesso restrito e projeções derivadas.
3. Os artefatos `baseline-only` e `contextual` carregam material semântico/matrix suficiente para alimentar tabelas de dicionário, alias/evidência e análise de cobertura, mas não devem ser confundidos com owner/property truth.
4. `contracts` e `source_manifest` trazem shape operacional estável para publicação, auditoria e readiness checks.
5. `analysis/discrepancy` tem um caso vazio; qualquer ingestão/validação deve aceitar ou sinalizar explicitamente artefatos vazios por sessão.
6. Não há evidência neste inventário que exija edição de DDL nesta etapa; este arquivo é apenas corpus/path evidence para a consolidação posterior.
