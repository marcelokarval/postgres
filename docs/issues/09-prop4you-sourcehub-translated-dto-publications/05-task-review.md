# Task Review — SourceHub translated DTO publications

Status: delivered
Updated: 2026-06-17T20:49:02
Reviewer: Thor/default

| Task | Requested | Delivered | Evidence | Verdict |
| --- | --- | --- | --- | --- |
| T1 | Persist PRD/tasks/ledger | Stack 09 created and maintained | 00-04 docs | PASS |
| T2 | Worker A contract review | Contract review delivered and independently read | 08-sourcehub-dto-contract-review.md | PASS |
| T3 | Worker B DDL proposal | DDL proposal delivered and independently read | 09-sourcehub-dto-ddl-review.md | PASS |
| T4 | Worker C gateway/temporal review | T0-T5/gateway review delivered and independently read | 10-gateway-temporal-review.md | PASS |
| T5 | Implement SourceHub translated DTO publication | `sourcehub/0002_translated_dto_publications.sql` implemented with table, trigger, view, function | PG18 proof | PASS |
| T6 | PG18 lab proof through T4 | 97 raws -> 10 DTO publications; hashes/lineage validated; LFG=0 | `/tmp/slice09-counts.json` | PASS |
| T7 | Browser-proof + vision | Static page rendered; console 0 errors; vision PASS | 06/08 | PASS |

## Proof JSON

```json
{
  "bridge_count": 10,
  "dictionary_match_count": 10,
  "field_mapping_artifact_kind_count": 10,
  "field_mapping_set_count": 1,
  "gateway_agnostic": true,
  "lfg_materialization_created": 0,
  "no_raw_values_printed": true,
  "promotion_preparation_count": 10,
  "quality_report_count": 1,
  "raw_record_count": 97,
  "run_distinct_path_count": 9650,
  "run_extracted_path_count": 172700,
  "run_source_record_count": 97,
  "sourcehub_t4_statuses": [
    "ready_for_review"
  ],
  "translated_dto_contract": "sourcehub.translated_dto.v0",
  "translated_dto_hash_count": 10,
  "translated_dto_publication_count": 10
}
```

## Active corrections

- Corrected `sourcehub/0002` apply order to run after Matrix 0005 + LeadFinder 0003.
- Enforced Matrix artifact validation through trigger because cross-table checks cannot be expressed as a plain CHECK constraint.
- Kept DTO proof redacted: counts/hashes/status only; no raw values printed.
