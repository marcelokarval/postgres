# 08 — Evidência de corpus raw/provider e estratégia path/type

[NO_PROVIDER_CALLS]
Nenhuma chamada a provider, web ou API foi executada. A análise ficou restrita a arquivos locais nos caminhos autorizados.

[NO_PII_DUMP]
Este relatório não despeja valores raw, nomes, endereços, telefones, emails, IDs, secrets ou payloads. A evidência usa apenas contagens, caminhos, categorias e tipos estruturais de alto nível.

[RAW_CORPUS_STATUS]
Escopo verificado:

- Repo PG18: `/home/marcelo-karval/Backup/Projetos/supabase-postgres-18-fork/postgres`
- Backend Prop4You read-only: `/home/marcelo-karval/Backup/Projetos/prop4you/prop4you-inertia/backend/src`
- Corpus privado: `/home/marcelo-karval/.hermes/private/prop4you-provider-corpus`

Status do corpus privado:

- Caminho existe: sim.
- Arquivos encontrados: 0.
- Conclusão: o corpus privado local está vazio para esta análise.

Status do corpus local no backend:

- JSONs totais sob `backend/src`: 345.
- JSONs com evidência de caminho Matrix/registry/baseline: 316.
- JSONs com token de caminho `directskip`: 211.
- JSONs com token de caminho `reiq`: 98.
- JSONs com token de caminho `lead_finder`: 9.
- JSONs com token de caminho `realtor`: 0.
- JSONs com token de caminho `sourcehub`: 0.

Registry Matrix encontrado:

- `apps/system/matrix/registry/directskip`: 210 JSONs
  - contracts: 46
  - schema: 7
  - analysis: 117
  - source manifests: 39
  - raw-like data payload files: 1
  - raw-like path: `apps/system/matrix/registry/directskip/skip_trace_contact_discovery/tx/data/undated/directskip_real_response.json`

- `apps/system/matrix/registry/reiq`: 98 JSONs
  - contracts: 19
  - schema: 0
  - analysis: 57
  - source manifests: 19
  - raw-like data payload files: 1
  - raw-like path: `apps/system/matrix/registry/reiq/loan_modification/fl/data/2025-11-27/FL_loan-modification_c45a1057-8de0-11ee-9e90-42010a800019.json`

- `apps/system/matrix/registry/contracts`: 7 JSONs
  - raw-like data payload files: 0

Raw-like type evidence, sem valores:

- DirectSkip raw-like file:
  - root type: object/dict
  - top-level key count: 4
  - observed top-level structural categories: input object, status object, contacts array, result-code object
  - contacts array count observed: 1 item

- REIQ loan-modification raw-like file:
  - root type: object/dict
  - top-level key count: 51
  - observed structural profile: flat scalar-heavy record with property, owner/contact-role, legal/loan and valuation/financial field families

Lead Finder baseline JSONs:

- `apps/system/lead_finder/baselines/owner/model_inventory/owner_entity.groups.v1.json`
- `apps/system/lead_finder/baselines/owner/model_inventory/owner_entity.v1.json`
- `apps/system/lead_finder/baselines/owner/owner_structural_position.v1.json`
- `apps/system/lead_finder/baselines/owner/owner_relationship_evidence.v1.json`
- `apps/system/lead_finder/baselines/owner/owner_contact_address.v1.json`
- `apps/system/lead_finder/baselines/owner/owner_email.v1.json`
- `apps/system/lead_finder/baselines/owner/owner_phone.v1.json`
- `apps/system/lead_finder/baselines/owner/owner_identity.v1.json`

Provider/code path availability evidence:

- DirectSkip: 70 Python files contain local code/test references. Key paths include:
  - `apps/system/matrix/directskip_owner_resolution_dto.py`
  - `apps/system/matrix/directskip_owner_resolution_mapping.py`
  - `apps/system/matrix/directskip_owner_resolution_contact_specs.py`
  - `apps/system/matrix/owner_resolution_pre_sourcehub_dto.py`
  - `apps/system/matrix/owner_resolution_pre_sourcehub_apply.py`
  - `apps/system/sourcehub/skip_trace_backfill.py`
  - `apps/system/sourcehub/producer.py`

- REIQ: 80 Python files contain local code/test references. Key paths include:
  - `apps/system/matrix/reiq_pre_foreclosure_pre_sourcehub_dto.py`
  - `apps/system/matrix/reiq_loan_modification_pre_sourcehub_dto.py`
  - `apps/system/matrix/reiq_probates_pre_sourcehub_dto.py`
  - `apps/system/matrix/reiq_heirship_pre_sourcehub_dto.py`
  - `apps/system/matrix/reiq_tax_sale_pre_sourcehub_dto.py`
  - `apps/system/matrix/reiq_divorce_pre_sourcehub_dto.py`
  - `apps/system/matrix/reiq_eviction_pre_sourcehub_dto.py`
  - corresponding `*_contracts.py` files for the same list families
  - `apps/system/sourcehub/reiq_pre_foreclosure_fl_ingestion.py`
  - `apps/system/sourcehub/reiq_pre_foreclosure_tx_ingestion.py`
  - `apps/system/sourcehub/reiq_loan_modification_fl_ingestion.py`
  - `apps/system/sourcehub/reiq_loan_modification_tx_ingestion.py`

- Realtor: 110 Python files contain local code/test references, but no JSON registry/raw corpus path was found under `backend/src`. Key paths include:
  - `apps/system/matrix/realtor_area_boundary_pre_sourcehub_dto.py`
  - `apps/system/matrix/realtor_area_boundary_pre_sourcehub_contracts.py`
  - `apps/system/matrix/realtor_property_enrichment_pre_sourcehub_dto.py`
  - `apps/system/matrix/realtor_property_enrichment_pre_sourcehub_contracts.py`
  - `apps/system/matrix/realtor_property_comparables_pre_sourcehub_dto.py`
  - `apps/system/matrix/realtor_property_comparables_pre_sourcehub_contracts.py`
  - `apps/system/matrix/realtor_market_enrichment_pre_sourcehub_dto.py`
  - `apps/system/matrix/realtor_market_enrichment_pre_sourcehub_contracts.py`
  - `apps/system/lead_finder/hydration.py`

- SourceHub: 184 Python files contain local code/test references. Key paths include:
  - `apps/system/sourcehub/contracts.py`
  - `apps/system/sourcehub/producer.py`
  - `apps/system/sourcehub/property_details_normalization.py`
  - `apps/system/sourcehub/legal_timeline_normalization.py`
  - `apps/system/sourcehub/valuation_financial_normalization.py`
  - `apps/system/sourcehub/system_address_geocode_ingestion.py`
  - REIQ ingestion files listed above

- Matrix: 154 Python files contain local code/test references. Key paths include:
  - `apps/system/matrix/models.py`
  - `apps/system/matrix/contracts.py`
  - `apps/system/matrix/runtime.py`
  - `apps/system/matrix/intake.py`
  - `apps/system/matrix/provider_admission.py`
  - `apps/system/matrix/analysis_runtime.py`
  - `apps/system/matrix/contextual_probe_runtime.py`
  - `apps/system/matrix/registry_audit_surface.py`
  - `apps/system/matrix/ai_runtime.py`

- Lead Finder: 126 Python files contain local code/test references. Key paths include:
  - `apps/system/lead_finder/contracts.py`
  - `apps/system/lead_finder/baseline.py`
  - `apps/system/lead_finder/baseline_authoring.py`
  - `apps/system/lead_finder/hydration.py`
  - `apps/system/lead_finder/acquisition.py`
  - `apps/system/lead_finder/operator_search.py`

[PATH_TYPE_STRATEGY]
Estratégia recomendada para evidência path/type sem exposição de PII:

1. Treat `apps/system/matrix/registry/<provider>/<list_type>/<state?>/data/**` as the first local raw/provider corpus candidate.
   - Include only file count, relative path and structural type summary.
   - Never include raw values or row/payload dumps.

2. Treat `*_source_manifest.json` as lineage/manifest evidence, not raw payload evidence.
   - Use count and path to confirm corpus/session source presence.
   - Avoid dumping manifest internals unless separately redacted.

3. Treat `contracts/**`, `schema/**`, and `analysis/**` as Matrix artifact evidence.
   - Use them to prove semantic mapping, session and discrepancy/contextual review availability.
   - Do not classify these as raw provider payload corpus.

4. Tie provider raw-like paths to code paths by provider/list type:
   - DirectSkip raw-like data path maps to owner/skip-trace pre-SourceHub Matrix DTO and SourceHub backfill/producer paths.
   - REIQ loan-modification raw-like data path maps to REIQ loan-modification Matrix DTO/contracts and SourceHub ingestion paths.
   - Realtor has code path availability but no local JSON raw registry evidence in this scan; use tests/fixture references only as code evidence, not as corpus evidence.

5. Use type-level summaries only:
   - root JSON type
   - top-level key count
   - object/list/scalar family counts
   - list item count when useful
   - path category: raw-like data, source manifest, contract, schema, analysis, baseline

6. For canonical cycle analysis:
   - SourceHub owns raw lineage and canonical DTO publication.
   - Matrix owns provider mapping artifacts, genome/schema/analysis and semantic pressure.
   - Lead Finder owns canonical graph/materialization baselines.
   - Direct provider raw payloads should remain in raw-like data paths or SourceHub raw records, not inside Lead Finder materialization evidence.

[GAPS]

- Private corpus path exists but is empty: no private corpus evidence available.
- Local raw-like JSON payload evidence is narrow: only 1 DirectSkip raw-like file and 1 REIQ raw-like file found under Matrix registry data paths.
- Realtor has substantial code coverage but no local JSON raw/provider corpus under `backend/src/apps/system/matrix/registry` in this scan.
- SourceHub has extensive code paths but no JSON files with `sourcehub` in the path under `backend/src`; SourceHub evidence is code/model/contract-oriented rather than file-corpus-oriented here.
- REIQ local raw-like corpus evidence found only for `loan_modification/fl`; other REIQ list families are represented by DTO/contracts/tests but not by local raw-like registry data files in this scan.
- DirectSkip local raw-like corpus evidence found only for `skip_trace_contact_discovery/tx`; other DirectSkip evidence is mostly manifests/contracts/schema/analysis.
- No database inspection was performed; this report does not claim presence/absence of rows in SourceHubRawRecord or Matrix runtime tables.
- No provider/API calls were performed, so missing local fixture evidence was not supplemented externally.

[RECOMMENDATION]

- Use the two raw-like local JSON files as minimal path/type evidence only, not as broad corpus coverage.
- For the canonical Lead Finder cycle, rely on code-path evidence plus Matrix registry artifacts for semantic mapping, and explicitly mark corpus coverage gaps by provider/list type.
- If broader evidence is required later, ingest or export sanitized local SourceHubRawRecord/MatrixCorpusSession metadata into the private corpus path using a redaction process that records counts, path/type summaries and hashes, not payload values.
- Add a small provider-corpus inventory convention: `provider/list_type/state/category/{raw,manifest,contract,schema,analysis}` with a generated redacted index containing counts and structural types.
- Do not promote Realtor claims to raw corpus availability until local raw-like fixture files or redacted SourceHub raw metadata are present.
