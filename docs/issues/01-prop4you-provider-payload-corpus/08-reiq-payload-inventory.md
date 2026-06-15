# Worker A — Inventário de evidências REIQ/base payload

Status: COMPLETED
Escopo: análise estática/read-only do corpus e código Prop4You Inertia para REIQ/base data.

[NO_PROVIDER_CALLS]
Nenhuma chamada a provider/API foi executada. A evidência abaixo vem apenas de arquivos locais em `/home/marcelo-karval/Backup/Projetos/prop4you/prop4you-inertia/backend/src` e do repositório de destino.

[NO_PII_DUMP]
Este relatório lista nomes de caminhos JSON, famílias de dados, versões e referências de arquivo/linha. Valores brutos de payloads, nomes, endereços, IDs externos e demais PII não são reproduzidos.

[REIQ_PATH_INVENTORY]

## 1. Inventário de fontes locais observadas

### Código SourceHub/REIQ

- `apps/system/sourcehub/producer.py:1236-1242`
  - `_extract_reiq_result()` aceita dois formatos de payload:
    - wrapper `$.data.result.*`
    - objeto plano no root `$.<field>`
  - Implicação: o dicionário Matrix deve registrar ambos os envelopes como formatos válidos até que a ingestão seja normalizada.

- `apps/system/sourcehub/producer.py:2323-2387`
  - `_build_reiq_base_canonical_dto()` cria o DTO canônico base:
    - `canonical_dto.property.location`
    - `canonical_dto.owners[]`
    - `canonical_dto.ownerships[]`
    - `canonical_dto.situations[]`
    - `canonical_dto.provenance`
    - `canonical_dto.address_source_facts[]`
    - `canonical_dto.property_source_facts[]`

- `apps/system/sourcehub/producer.py:2390-2416`
  - blocos opcionais comuns REIQ:
    - `property.details`
    - `party_roles[]`
    - `legal_timeline`
    - `valuation_financial`

- `apps/system/sourcehub/producer.py:2419-2476`
  - extensões atuais para `loan_modification` e `pre_foreclosure`:
    - `owner_projection_candidate`
    - `loan_terms_evidence` para `loan_modification`
    - `distress_evidence` para `pre_foreclosure`
    - `operator_context`

- `apps/system/sourcehub/producer.py:2479-2936` e `2960-3213`
  - builders/lanes existentes para outras list types REIQ, mesmo quando o corpus local completo não aparece para todas:
    - `probates`: `mailing_address`, `role_addresses[]`, `contact_phones[]`, `contact_emails[]`
    - `heirship`: `party_roles[]`, `role_addresses[]`, `contact_phones[]`, `contact_emails[]`
    - `eviction`: `role_addresses[]`
    - `tax_sale`: `owner_projection_candidate`, `mailing_address`, `tax_sale_evidence`
    - `divorce`: `owner_projection_candidate`, `mailing_address`, `divorce_evidence`
    - `appt_of_sub_trustee`: `owner_projection_candidate`, `loan_terms_evidence`, `lender_evidence`

- `apps/system/sourcehub/producer.py:3257-3395`
  - `produce_reiq_pilot_handoff()` exige aprovação Matrix via `assert_matrix_approved_sourcehub_admission()`, persiste `SourceHubRawRecord`, escolhe o builder por `list_type_slug`, adiciona `portable_intelligence` e retorna handoff SourceHub -> Lead Finder.
  - List types roteados no código: `loan_modification`, `probates`, `eviction`, `tax_sale`, `appt_of_sub_trustee`, `heirship`, `divorce`; fallback para `pre_foreclosure`.

- `apps/system/sourcehub/producer.py:3398-3418`
  - `build_reiq_raw_envelope()` fixa:
    - `provider_slug=reiq`
    - `payload_format=json`
    - `ingestion_mode=api`
    - `stage=sourcehub`
    - `list_type_slug` parametrizado, default `pre_foreclosure`
    - `state_slug` vindo do argumento ou de `property_state`
    - `external_reference_id` vindo de `internal_id`

### Runners de ingestão

- `apps/system/sourcehub/reiq_pre_foreclosure_tx_ingestion.py:23-36`
  - default source dir aponta para arquivo histórico/arquivado sob `_projeto-antigo/.../matrix/registry/reiq/pre_foreclosure/tx/data/2025-11-27`, mas esse caminho não existe no checkout `backend/src` analisado.

- `apps/system/sourcehub/reiq_pre_foreclosure_tx_ingestion.py:57-64`
  - runner de produção-style:
    - `DEFAULT_LIST_TYPE_SLUG=pre_foreclosure`
    - `DEFAULT_STATE_SLUG=tx`
    - `DEFAULT_MAPPING_VERSION=reiq.pre_foreclosure.tx.v1`
    - `RUNNER_NAME=sourcehub.reiq_pre_foreclosure_tx_ingestion`

- `apps/system/sourcehub/reiq_pre_foreclosure_tx_ingestion.py:67-162`
  - `run_from_directory()` e `ingest_payload()` leem JSON local, montam envelope, persistem raw record, produzem handoff e hidratam Lead Finder; gerenciam `processed/skipped/failed/replayed` em `SourceHubRawRecord`.

- `apps/system/sourcehub/reiq_pre_foreclosure_fl_ingestion.py:22-37`
  - especialização FL para `pre_foreclosure`:
    - `DEFAULT_STATE_SLUG=fl`
    - `DEFAULT_MAPPING_VERSION=reiq.pre_foreclosure.fl.v1`
    - source dir esperado: `apps/system/matrix/registry/reiq/pre_foreclosure/fl/data/...`

- `apps/system/sourcehub/reiq_loan_modification_fl_ingestion.py:5-12` e `apps/system/sourcehub/reiq_loan_modification_tx_ingestion.py:5-12`
  - subclasses/reexports baseadas no runner `REIQPreForeclosureTXIngestionService` para lanes `loan_modification`.

### Testes e fixtures

- `domains/real_estate/tests/test_lead_finder_hydration.py:88-119`
  - fixture sintética `$.data.result` para `pre_foreclosure` com famílias: identidade de propriedade, proprietário, lead/situação, valuation/equity, timeline legal/processual, ocupação e tenant.

- `domains/real_estate/tests/test_lead_finder_hydration.py:121-245`
  - valida criação de `PropertyLeadFinder`, `PropertyLocation`, `OwnerEntity`, `Ownership`, `PropertySituation`, `PartyRole`, `PropertyHistory`, `PropertyValuation` e `PropertyEvent` a partir de REIQ.
  - Verifica provenance `provider_slug=reiq`, `list_type_slug=pre_foreclosure` e presença de `raw_record_public_id`.

- `domains/real_estate/tests/test_lead_finder_hydration.py:247-288`
  - caso com nomes de owner/mortgagor ambíguos e ampersand para `pre_foreclosure`, versão `reiq.pre_foreclosure.tx.v1`.

- `domains/real_estate/tests/test_lead_finder_hydration.py:297-328`
  - caso `loan_modification` FL, versão `reiq.loan_modification.fl.middle_name.v1`, focado em nome com middle initial.

- `apps/system/sourcehub/tests/test_reiq_pre_foreclosure_tx_ingestion.py:23-73`
  - seed Matrix runtime genome para `provider_slug=reiq`, `list_type_slug=pre_foreclosure`, `state_slug=tx`, `mapping_version=reiq.pre_foreclosure.tx.v1`, `artifact_version=1.0.0`.
  - baseline usado: `lf_default.v1`, ontology `matrix.ontology.lead_finder_baseline.v1`, provider mapping `matrix.provider_mapping.reiq.pre_foreclosure.tx.v1`, genome `matrix.genome.reiq.pre_foreclosure.tx.v1`.
  - famílias baseline: `identity_address`, `legal_timeline`, `owner_ownership`, `valuation_financial`; taxonomy: `lead_type`, `source_list_type`.

- `apps/system/sourcehub/tests/test_reiq_pre_foreclosure_tx_ingestion.py:76-110`
  - fixture sintética wrapper `$.data.result` para `pre_foreclosure/tx` com campos de foreclosure, endereço, equity, ocupação e locked contact keys.

- `apps/system/sourcehub/tests/test_reiq_pre_foreclosure_tx_ingestion.py:117-278`
  - valida ingestão local sem provider call, idempotência por status processed, healing de runtime state, force replay, falha/retry e management command.

- `apps/system/sourcehub/tests/test_reiq_loan_modification_fl_ingestion.py:22-25`
  - fixture local real/arquivada referenciada em `apps/system/matrix/registry/reiq/loan_modification/fl/data/2025-11-27/FL_loan-modification_*.json`.

- `apps/system/sourcehub/tests/test_reiq_loan_modification_fl_ingestion.py:28-80`
  - seed Matrix runtime genome para `provider_slug=reiq`, `list_type_slug=loan_modification`, `state_slug=fl`, `mapping_version=reiq.loan_modification.fl.middle_name.v1`, `artifact_version=1.0.0`.
  - provider mapping `matrix.provider_mapping.reiq.loan_modification.fl.middle_name.v1`, genome `matrix.genome.reiq.loan_modification.fl.middle_name.v1`.

- `apps/system/sourcehub/tests/test_reiq_loan_modification_fl_ingestion.py:83-162`
  - lê fixture real local e valida materialização, status processed, idempotência e command `ingest_reiq_loan_modification_fl`.

### Matrix registry local observado

Comando estático executado: inventário Python local sobre `apps/system/matrix/registry/reiq/**/*.json`, sem imprimir valores de PII.

Resultado observado:

- Total REIQ registry JSON: 98 arquivos.
- Estrutura presente no checkout:
  - `apps/system/matrix/registry/reiq/loan_modification/context.json` — 1
  - `apps/system/matrix/registry/reiq/loan_modification/fl/context.json` — 1
  - `apps/system/matrix/registry/reiq/loan_modification/fl/contracts/*.json` — 19
  - `apps/system/matrix/registry/reiq/loan_modification/fl/analysis/baseline-only/*.json` — 19
  - `apps/system/matrix/registry/reiq/loan_modification/fl/analysis/contextual/*.json` — 19
  - `apps/system/matrix/registry/reiq/loan_modification/fl/analysis/discrepancy/*.json` — 19
  - `apps/system/matrix/registry/reiq/loan_modification/fl/data/*_source_manifest.json` — 19
  - `apps/system/matrix/registry/reiq/loan_modification/fl/data/2025-11-27/FL_loan-modification_*.json` — 1 payload raw local.

Contrato Matrix observado nos `contracts/session_*.json`:

- `artifact_kind` alterna entre `matrix_registry_contract_bundle` e `matrix_registry_contract_lineage`.
- `provider_slug=reiq`.
- `list_type_slug=loan_modification`.
- `state_slug=fl`.
- `baseline_version` aparece como `lf_default.v1` e em um artefato antigo como `lf-default.v1`.
- `published_contract_ref` aparece como `lead_finder.default_genome.lf_default.v1` e em um artefato antigo como `lead_finder.default_genome.lf-default.v1`.
- `contract_refs` recorrentes:
  - `registry/contracts/baseline_only_analysis.contract.json`
  - `registry/contracts/contextual_analysis.contract.json`
  - `registry/contracts/dataset_discrepancy_report.contract.json`
  - `registry/contracts/source_manifest.contract.json`
- Snapshots embutidos, quando presentes, usam contratos versão `1.0.0` para baseline-only/contextual/discrepancy/source-manifest.

### Payload raw local real observado sem valores

Arquivo: `apps/system/matrix/registry/reiq/loan_modification/fl/data/2025-11-27/FL_loan-modification_*.json`

Formato: objeto plano no root, não wrapper `$.data.result`.

Campos observados por família:

- Identidade/localização da propriedade:
  - `property_address`, `property_city`, `property_state`, `property_zip_code`, `property_id`, `county`, `subdivision`, `legal_description`
- Características físicas/assessoria:
  - `bed`, `bath`, `garage`, `pool`, `sq_ft`, `yr_bt`, `appraised_value`, `assessed_value`, `comments`
- Proprietário/mortgagor/mailing:
  - `owner_first_name`, `owner_last_name`, `owner_address`, `owner_city`, `owner_state`, `owner_zip_code`, `ownership`, `mortgagor_first_name`, `mortgagor_last_name`
- Situação/lista/timeline:
  - `internal_id`, `lead_type`, `date_added`, `date_filed`, `file_number`, `loan_modification_instrument_number`
- Valuation/financeiro:
  - `estimated_equity`, `equity`, `estimated_unpaid_balance`, `original_loan_amount`
- Loan modification terms:
  - `new_principal_balance`, `monthly_principal_interest_payment`, `monthly_escrow_payment_amount`, `total_monthly_payment`, `historical_interest_rate`, `interest_rate`, `interest_rate_date_change`, `payment_begins_on`, `months_to_pay`, `maturity_date`, `loan_origination_month`, `loan_origination_year`, `current_month`, `current_year`
- Lender/contexto:
  - `mortgagee_bank_name`

## 2. JSON path families consolidadas

### Envelopes aceitos

- Wrapper: `$.data.result.<provider_field>`
  - Evidência: testes de hydration e pre_foreclosure TX.
  - Código: `_extract_reiq_result()` em `producer.py:1236-1242`.

- Root object: `$.<provider_field>`
  - Evidência: fixture real local de `loan_modification/fl/data/2025-11-27`.
  - Código: fallback de `_extract_reiq_result()`.

### Raw provider fields por família

- `identity_address` / propriedade:
  - `property_address`, `property_street`, `property_city`, `property_state`, `property_zip_code`, `property_id`, `county`, `country`
  - Canonical targets: `property.location.street_address`, `city`, `state`, `zip_code`, `county`, `country`, `normalized_address`, `address_hash`, `apn`
  - Código: `producer.py:1808-1847`.

- `property_details`:
  - `bed`, `bath`, `garage`, `pool`, `sq_ft`, `yr_bt`, `comments`, `appraised_value`, `assessed_value`, `legal_description`, `subdivision`
  - Canonical targets: `property.details.*`
  - Código: `producer.py:2009-2067`.

- `owner_ownership` / owner projection:
  - `owner_first_name`, `owner_last_name`, `mortgagor_first_name`, `mortgagor_last_name`, `mortgagor_owner_name`, `ownership`, `owner_address`, `owner_city`, `owner_state`, `owner_zip_code`
  - Canonical/preserve targets: `owners[]`, `ownerships[]`, `party_roles[]`, `owner_projection_candidate`, `mailing_address`
  - Código: `producer.py:1419-1607`, `1610-1628`, `2069-2227`, `2736-2846`.

- `legal_timeline` / situation:
  - `lead_type`, `date_added`, `record_date`, `date_filed`, `auction_date_time`, `case_number`, `document_id`, `instrument_no`, `file_number`, list-type-specific instrument numbers
  - Canonical targets: `situations[]`, `legal_timeline`, `PropertyEvent` hydration.
  - Código: `producer.py:1381-1398`, `2253-2319`.

- `valuation_financial`:
  - `estimated_value`, `estimated_equity`, `equity`, `estimated_unpaid_balance`, `appraised_value`, `assessed_value`, `original_loan_amount`
  - Canonical targets: `valuation_financial`, `PropertyValuation`.
  - Código: `producer.py:2229-2251`; tests `test_lead_finder_hydration.py:216-232`.

- `loan_terms_evidence`:
  - `new_principal_balance`, `monthly_principal_interest_payment`, `monthly_escrow_payment_amount`, `total_monthly_payment`, `historical_interest_rate`, `payment_begins_on`, `interest_rate_date_change`, `months_to_pay`, `loan_origination_month`, `loan_origination_year`, `current_month`, `current_year`
  - Canonical/preserve target: `loan_terms_evidence`.
  - Código: `producer.py:1631-1671`.

- `distress_evidence`:
  - `loan_expiration_month`, `loan_expiration_year`, `loan_modification`, `loan_expiration`, `instrument_no`
  - Canonical/preserve target: `distress_evidence`.
  - Código: `producer.py:1716-1735`.

- `tax_sale_evidence`:
  - `status`, `min_bid`, `adjudged_value`, `est_value`, `property_type`
  - Canonical/preserve target: `tax_sale_evidence`.
  - Código: `producer.py:1738-1756`.

- `divorce_evidence`:
  - `property_awarded_to`
  - Canonical/preserve target: `divorce_evidence`.
  - Código: `producer.py:1759-1769`.

- `lender_evidence`:
  - `mortgagee_bank_name`, `document_type`, `foreclosure_instrument_number`, `original_instrument_number`
  - Canonical/preserve target: `lender_evidence`.
  - Código: `producer.py:1674-1692`.

- `operator_context`:
  - `current_month`, `current_year`, `comments`, `loan_origination_month`, `loan_origination_year`
  - Canonical/preserve target: `operator_context`.
  - Código: `producer.py:1695-1713`.

- locked/contact hints:
  - `email_addresses_1`, `cell_phones_1`, `phone_numbers_1`, `lockedKeys`
  - Evidência: `test_reiq_pre_foreclosure_tx_ingestion.py:99-107`.
  - Implicação: tratar `Locked`/locked keys como ausência/restrição de dado, não contato canônico.

## 3. Mapping versions e list types observados

List types observados diretamente em código/testes/registry:

- `pre_foreclosure`
  - `tx`: `reiq.pre_foreclosure.tx.v1`, artifact `1.0.0`, genome `matrix.genome.reiq.pre_foreclosure.tx.v1`, provider mapping `matrix.provider_mapping.reiq.pre_foreclosure.tx.v1`.
  - `fl`: `reiq.pre_foreclosure.fl.v1` no runner FL.
  - `pilot`: `reiq.pilot.v1` em teste antigo de hydration.
  - Caso adicional: `reiq.pre_foreclosure.tx.v1` usado para nomes com ampersand.

- `loan_modification`
  - `fl`: `reiq.loan_modification.fl.middle_name.v1`, artifact `1.0.0`, genome `matrix.genome.reiq.loan_modification.fl.middle_name.v1`, provider mapping `matrix.provider_mapping.reiq.loan_modification.fl.middle_name.v1`.
  - `tx`: runner especializado existe, herdando infraestrutura do TX base; mapping version default não foi explicitamente confirmado no arquivo lido além do import/reexport.

- Roteados em `produce_reiq_pilot_handoff()` mas sem corpus raw local completo neste checkout:
  - `probates`
  - `eviction`
  - `tax_sale`
  - `appt_of_sub_trustee`
  - `heirship`
  - `divorce`

[CANONICAL_IMPLICATIONS]

1. REIQ deve permanecer como SourceHub/raw JSONB primeiro, Matrix-approved mapping depois, Lead Finder canonical graph por último.
   - Evidência: `produce_reiq_pilot_handoff()` valida Matrix admission antes de publicar handoff; `persist_raw_record()` mantém raw payload e hash.

2. Não congelar schema a partir de um único envelope.
   - O código aceita `$.data.result` e root flat payload; o payload real local de `loan_modification/fl` é flat, enquanto testes de `pre_foreclosure` usam wrapper.
   - Recomendação: Matrix dictionary deve ter `provider_path_family` com `envelope_shape in {root, data.result}`.

3. `lead_type` não é equivalente a `list_type_slug`.
   - Comentário em `producer.py:3264-3269`: lista comprada pode ser pre-foreclosure enquanto o record-level `lead_type` pode indicar foreclosure.
   - Recomendação: guardar ambos: `source_list_type_slug` e `record_lead_type`; situação canônica derivada deve apontar regra/versão Matrix.

4. Owner semantics são incertas para listas jurídicas/financeiras.
   - `loan_modification`, `pre_foreclosure`, `tax_sale`, `divorce`, `appt_of_sub_trustee` usam `owner_projection_candidate` em vez de owner canônico direto em várias rotas.
   - Recomendação: Matrix deve comparar `owner_*`, `mortgagor_*`, `ownership` e mailing fields em seção de confidence/role, não promover todos diretamente a `owners[]`.

5. Parcel/address facts devem ser separados de identidade canônica.
   - `address_source_facts` inclui `address_identity` e `address_parcel`; `property_id` vira `apn` quando disponível.
   - Recomendação: comparar `property_id` como APN/provider parcel candidate, não como `property_public_id`.

6. Valores financeiros precisam de normalização typed + preservação raw.
   - Evidência: currency/percent strings em testes e fixture real; parsers convertem para float/decimal em blocos canônicos.
   - Recomendação: Matrix dictionary deve guardar `raw_type_observed`, `normalized_type`, `currency_percent_parser`, e `nullish/locked behavior`.

7. PII/contact fields bloqueados não devem virar contato canônico.
   - `lockedKeys` e valores locked aparecem em teste; `_nullish()` trata `locked` como nullish.
   - Recomendação: dictionary deve classificar esses campos como `restricted_contact_hint`, com `promotion_allowed=false` sem evidência desbloqueada.

## 4. Campos recomendados para comparação Matrix dictionary

Mínimo recomendado por field/path:

- `provider_slug`
- `list_type_slug`
- `state_slug`
- `mapping_version`
- `artifact_version`
- `envelope_shape` (`root` ou `data.result`)
- `provider_json_path`
- `provider_field_name`
- `field_family`
- `canonical_candidate_path`
- `canonical_family`
- `observed_in_sources` (fixture/test/registry/code)
- `observed_type_family` (string/number/date/datetime/currency-string/percent-string/list/nullish)
- `normalizer/parser` (address/name/date/decimal/percent/nullish/locked)
- `promotion_policy` (`canonical`, `preserve_only`, `projection_candidate`, `restricted`, `lineage_only`)
- `confidence_default`/`confidence_rule_ref` quando aplicável
- `semantic_owner` (`matrix_artifact`, `sourcehub_ingress`, `lead_finder_graph`)
- `raw_payload_retention_required=true`
- `pii_classification` (address/name/contact/legal/financial/non-pii)
- `lineage_fields_required` (`raw_record_public_id`, `dto_public_id`, `payload_hash`, `source_reference`, `ingested_at`, `mapping_version`)
- `drift_action` (`provider_drift_detected`, review required, no-op)
- `notes_uncertainty`

[RESIDUAL_RISKS]

- O checkout analisado contém corpus real local apenas para `reiq/loan_modification/fl`; `pre_foreclosure/tx` tem runner e testes, mas o diretório arquivado default referenciado não existe no `backend/src` local.
- Muitos builders REIQ existem para list types (`probates`, `eviction`, `tax_sale`, `appt_of_sub_trustee`, `heirship`, `divorce`) sem payload raw local completo neste inventário. Eles são evidência de contrato/código, não de distribuição real de corpus.
- Há inconsistência histórica `lf-default.v1` vs `lf_default.v1` em contratos Matrix. A comparação deve normalizar/registrar aliases antes de declarar drift.
- `ingestion_mode` no envelope REIQ é `api`, mas os runners atuais leem arquivos locais; isso pode ser semântico legado. Não tratar como prova de chamada externa.
- A lista `loan_modification/tx` foi identificada por arquivo de subclass/import, mas mapping version default específico não foi confirmado no trecho lido; requer inspeção adicional se essa lane entrar na matriz final.
- Payloads reais podem conter PII; qualquer inventário futuro deve continuar emitindo apenas caminhos, tipos e famílias, não valores.
