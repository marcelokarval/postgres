# Worker A — DirectSkip corpus/path inventory

Status: complete
Scope: DirectSkip real/sample responses + Matrix registry snapshot for `skip_trace_contact_discovery`.
PII policy: this inventory intentionally records only file names, counts, root types, key names, path families, and modeling implications. No raw payload values, names, phone numbers, e-mails, addresses, or session IDs are printed.

## Sources inspected

| Source | Files | Notes |
| --- | ---: | --- |
| `prop4you-inertia/backend/src/apps/system/matrix/registry/directskip/skip_trace_contact_discovery` | 210 JSON | Matrix registry artifacts for DirectSkip contact discovery. |
| `prop4you-inertia/backend/src/apps/system/matrix/tests/fixtures/directskip_real_response.json` | 1 JSON | Real fixture response shape. |
| `full-stack-prop4you/backend/src/data/directskip_sample_response.json` | 1 JSON | Sample response shape. |
| `full-stack-prop4you/backend/src/data/directskip_charlotte_basham_response.json` | 1 JSON | Sample/person-specific response shape; values not copied. |

Total inspected JSON files: 213. All parsed successfully as JSON objects.

Registry JSON distribution by immediate folder:

| Registry folder | JSON files |
| --- | ---: |
| `analysis` | 108 |
| `contracts` | 43 |
| `data` | 36 |
| `schema` | 7 |
| `tx` | 16 |
| Total | 210 |

One registry file is a copied raw DirectSkip fixture shape: `tx/data/undated/directskip_real_response.json`. It matches the same top-level response family as the real fixture and was counted in the registry total, but values were not inspected or copied into this document.

## Root types and top-level keys

All 213 files have JSON root type `object`.

Raw response top-level keys observed in all 3 external response files and in the registry raw copy:

- `input`
- `status`
- `contacts`
- `result_code`

Common Matrix registry top-level key families observed:

- Artifact identity/scope: `artifact_kind`, `artifact_version`, `provider_slug`, `list_type_slug`, `state_slug`, `session_public_id`, `genome_public_id`, `mapping_version`, `baseline_version`.
- Contract/schema references: `published_contract_ref`, `contract_refs`, `effective_contract_snapshots`, `compiled_schema`.
- Corpus and source lineage: `corpus_stats`, `source_manifest`, `source_surface`, `source_dataset_dir`, `context_lineage`, `workspace_snapshot`, `matrix_context_snapshot`.
- Analysis outputs: `alias_evidence_snapshot`, `canonical_dictionary_snapshot`, `coverage_snapshot`, `multi_provider_snapshot`, `provider_drift_snapshot`, `dataset_discrepancy_snapshot`, `field_analysis`, `cross_field_patterns`, `dataset_profile`, `field_discrepancies`.
- Embedded raw response shape in selected registry artifacts: `input`, `status`, `contacts`, `result_code`.

## Raw DirectSkip response path inventory

The external response files are structurally consistent. Each has one `contacts` element in the current corpus, but the model is array-based and must not assume cardinality one.

Per-file structural counts, without payload values:

| File | Root | Contacts | Contact phones | Contact emails | Confirmed addresses | Relatives | Relative phones |
| --- | --- | ---: | ---: | ---: | ---: | ---: | ---: |
| `directskip_real_response.json` | object | 1 | 3 | 2 | 1 | 2 | 2 |
| `directskip_sample_response.json` | object | 1 | 7 | 2 | 1 | 5 | 16 |
| `directskip_charlotte_basham_response.json` | object | 1 | 7 | 2 | 1 | 5 | 14 |
| External raw total | object | 3 | 17 | 6 | 3 | 12 | 32 |

Raw response union paths and types:

| Path | Type/cardinality observed |
| --- | --- |
| `$` | object |
| `$.status` | object |
| `$.status.error` | string |
| `$.result_code` | object |
| `$.result_code.result_code` | string |
| `$.input` | object |
| `$.input.firstname` | string |
| `$.input.lastname` | string |
| `$.input.address` | string |
| `$.input.city` | string |
| `$.input.state` | string |
| `$.input.zip` | string |
| `$.input.property_address` | string |
| `$.input.property_city` | string |
| `$.input.property_state` | string |
| `$.input.property_zip` | string |
| `$.input.custom_field1` | string |
| `$.input.custom_field2` | string |
| `$.input.custom_field3` | string |
| `$.contacts` | array |
| `$.contacts[]` | object |
| `$.contacts[].names` | array |
| `$.contacts[].names[]` | object |
| `$.contacts[].names[].firstname` | string |
| `$.contacts[].names[].lastname` | string |
| `$.contacts[].names[].age` | string |
| `$.contacts[].names[].deceased` | string |
| `$.contacts[].phones` | array |
| `$.contacts[].phones[]` | object |
| `$.contacts[].phones[].phonenumber` | string |
| `$.contacts[].phones[].phonetype` | string |
| `$.contacts[].emails` | array |
| `$.contacts[].emails[]` | object |
| `$.contacts[].emails[].email` | string |
| `$.contacts[].confirmed_address` | array |
| `$.contacts[].confirmed_address[]` | object |
| `$.contacts[].confirmed_address[].street` | string |
| `$.contacts[].confirmed_address[].city` | string |
| `$.contacts[].confirmed_address[].state` | string |
| `$.contacts[].confirmed_address[].zip` | string |
| `$.contacts[].relatives` | array |
| `$.contacts[].relatives[]` | object |
| `$.contacts[].relatives[].name` | string |
| `$.contacts[].relatives[].age` | string |
| `$.contacts[].relatives[].phones` | array |
| `$.contacts[].relatives[].phones[]` | object |
| `$.contacts[].relatives[].phones[].phonenumber` | string |
| `$.contacts[].relatives[].phones[].phonetype` | string |

## Matrix registry path families

The registry is not just raw DirectSkip output. It is a Matrix semantic registry around that output. Important path families:

1. Raw response families embedded or referenced by registry artifacts
   - `input.*`
   - `status.*`
   - `result_code.*`
   - `contacts[].names[]`
   - `contacts[].phones[]`
   - `contacts[].emails[]`
   - `contacts[].confirmed_address[]`
   - `contacts[].relatives[]`
   - `contacts[].relatives[].phones[]`

2. Schema genome / canonical mapping families
   - `schema_genome.contacts[].names.*`
   - `schema_genome.contacts[].phones.*`
   - `schema_genome.contacts[].emails.*`
   - `schema_genome.contacts[].confirmed_address.*`
   - `schema_genome.contacts[].relatives.*`
   - Field-level review metadata under `review_payload`, `route_classification`, `semantic_context`, `source_context`, `suggestion_bundle`, `transforms`, and `validation`.

3. Dictionary and alias families
   - `alias_evidence_snapshot.entries[]`
   - `canonical_dictionary_snapshot.alias_entries[]`
   - `canonical_dictionary_snapshot.families.*`
   - `canonical_dictionary_snapshot.canonical_fields.*.aliases[]`
   - These show DirectSkip fields are curated through semantic aliases rather than treated as final domain columns.

4. Corpus quality and drift families
   - `coverage_snapshot.namespace_coverage.*`
   - `provider_drift_snapshot.new_fields[]`
   - `dataset_discrepancy_snapshot.field_discrepancies[]`
   - `field_analysis.*`
   - `workspace_snapshot.corpus.*`

5. Contract families
   - `contracts.*.required_keys[]`
   - `compiled_schema.*`
   - `effective_contract_snapshots.*`
   - `published_contract_ref` and `contract_refs`.

## Contact satellite implications

DirectSkip enrichment is contact-satellite heavy. The payload structure argues against flattening everything into the lead/property/owner core tables.

Implications by satellite:

- Phones:
  - Contact phones and relative phones are separate nested arrays.
  - Both include a phone value field and type/classification field.
  - Repeated phones and provider-specific phone type labels should be expected.
  - Recommended durable projection: a contact phone satellite table or view materialized from JSONB, with source path, source role (`contact` vs `relative`), normalized phone, type label, and lineage back to raw response.

- Emails:
  - E-mails are an array under each contact.
  - Current corpus has e-mail value only, without explicit verified/primary flags.
  - Recommended durable projection only if e-mail search/deduplication is needed; otherwise keep as JSONB with optional generated/search index later.

- Addresses:
  - `confirmed_address[]` is a contact address satellite, not the same thing as the input property address.
  - The input contains both person/location fields and property address fields.
  - Recommended: keep provider raw address objects in JSONB; project canonical address components only through SourceHub/Lead Finder address canonicalization, not from DirectSkip alone.

- Relatives:
  - Relatives are nested below contacts and have their own phones.
  - Relatives are enrichment evidence, not canonical owner/property truth.
  - Recommended: preserve relatives as JSONB and optionally project to a relative/contact-edge satellite if product workflows need relationship search, scoring, or outreach expansion.

- Names/person hints:
  - `contacts[].names[]` can contain age/deceased hints.
  - These are person-enrichment facts and should not overwrite canonical owner identity without confidence/lineage rules.

## Table-vs-JSONB recommendation

Recommended strategy for DirectSkip in PG18:

1. Store every provider response as immutable raw JSONB with metadata.
   - Keep the exact response envelope (`input`, `status`, `result_code`, `contacts`) in a lineage table owned by SourceHub/Skip Trace ingestion.
   - Validate with a DirectSkip JSONSchema family generated/curated from the path inventory.
   - Include provider slug, request identity, response timestamp, source file/request lineage, parser/version, and redaction/audit metadata outside the raw JSONB.

2. Promote only stable query-critical facts to relational projections.
   - Good candidates: response status/result code, contact count, phone/email/address/relative counts, normalized phones/emails if dedupe/search is a product requirement, and linkage to lead/person/property candidate.
   - Do not promote provider-specific nested values directly into canonical Lead Finder owner/property tables.

3. Treat phones/e-mails/addresses/relatives as contact satellites.
   - Use narrow satellite tables or materialized views for operational search, dedupe, scoring, and audit.
   - Retain `source_json_path` and source response id for every projected satellite row.

4. Keep Matrix registry artifacts JSONB-first.
   - Registry artifacts are higher-order curation/contract state: alias evidence, dictionary snapshots, coverage, drift, discrepancies, compiled schemas, and review payloads.
   - These are better stored as versioned JSONB documents with a small relational envelope, not decomposed into many first-class tables at this stage.

5. Canonical graph boundary.
   - Lead Finder defines canonical owner/property/lead graph.
   - Matrix defines semantic meaning and mapping contracts.
   - SourceHub owns ingress, lineage, and canonical DTO publication.
   - DirectSkip enriches contact reachability and relationship evidence; it must not define canonical owner/property truth by itself.

## Suggested JSONSchema anchors

The DirectSkip response JSONSchema should cover at least:

- Required top-level envelope keys: `input`, `status`, `contacts`, `result_code`.
- Array/object shapes for `contacts`, `names`, `phones`, `emails`, `confirmed_address`, `relatives`, and relative `phones`.
- String-typed leaf fields observed in this corpus.
- Lenient unknown-field handling at provider boundaries to support drift detection, with Matrix drift artifacts recording newly observed paths.
- Separate canonical DTO schema for normalized contact satellites, rather than forcing DirectSkip raw shape to become the domain DTO.

## Verification performed

- Parsed 213 JSON files with Python `json.load` successfully.
- Counted registry files by subdirectory.
- Counted raw response arrays and union paths without printing values.
- Confirmed all inspected JSON roots are objects.
- Confirmed one raw DirectSkip response copy exists inside the registry under `tx/data/undated`.

No DDL was edited.
