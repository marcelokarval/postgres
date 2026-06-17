# Task Review — Matrix field_mapping_set + prepare-only promotions

Status: delivered
Updated: 2026-06-17T18:41:10
Reviewer: Thor/default

| Task | Requested | Delivered | Evidence | Verdict |
| --- | --- | --- | --- | --- |
| T1 | Keep gateway/runtime agnostic | DDL contracts have no Django/PostgREST/ORM dependency | Matrix 0005 / LeadFinder 0003 | PASS |
| T2 | Raw drives LFG app modeling and canonical dictionary | Artifact/proposals carry `raw_dual_role` and separate hints | proof JSON + DDL metadata | PASS |
| T3 | Matrix field_mapping_set first | `matrix/0005_field_mapping_set_artifacts.sql` | PG18 proof: 1 artifact, 10 mappings | PASS |
| T4 | LeadFinder prepare-only | `leadfinder/0003_prepare_dictionary_promotions.sql` | PG18 proof: 10 prepared proposals; canonical counts unchanged | PASS |
| T5 | No SourceHub DTO/LFG materialization | Explicit non-goals; proof counts 0 | `/tmp/slice08-counts.json` | PASS |
| T6 | Browser-proof + vision | Static page rendered; console 0 errors; vision PASS | 06/08 | PASS |

## Proof

```json
{
  "bridge_count": 10,
  "canonical_family_count_after_prepare": 15,
  "canonical_field_count_after_prepare": 36,
  "field_mapping_contract": "matrix.field_mapping_set.raw_path.v0",
  "field_mapping_gateway_agnostic": true,
  "field_mapping_mapping_count": 10,
  "field_mapping_set_count": 1,
  "lfg_materialization_created": 0,
  "no_raw_values_printed": true,
  "promotion_preparation_count": 10,
  "quality_report_count": 1,
  "raw_record_count": 97,
  "run_distinct_path_count": 9650,
  "run_extracted_path_count": 172700,
  "run_source_record_count": 97,
  "sourcehub_dto_publications_created": 0
}
```

## Corrections

- Corrected Matrix 0005 against real `mapping_sessions` columns (`session_purpose`, `input_scope`, `extraction_summary`, `review_summary`) instead of invented `session_kind/session_goal`.
- Corrected lab script for PostgreSQL safe-update guard by adding `where true` to temp-table update.
