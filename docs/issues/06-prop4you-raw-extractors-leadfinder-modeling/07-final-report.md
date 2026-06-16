# Final Report — raw extractors for LeadFinder modeling

Status: delivered after browser proof; commit pending at report write time
Updated: 2026-06-16T16:52:19
Owner/reviewer: Thor/default

## Verdict

SUPPORTED for extractor-first modeling gate.

The right next move was not SourceHub translated DTO publication. SQL/Python extractors give the modeling context needed for the LeadFinder Group because raw data is the matrix for canonical discovery, while LeadFinder filters define demand-side organization and traceability pressure.

## Delivered artifacts

```text
database/ddl/projects/prop4you/matrix/0003_raw_path_extractors.sql
scripts/extract-prop4you-reiq-path-candidates.py
docs/issues/06-prop4you-raw-extractors-leadfinder-modeling/08-leadfinder-filter-pressure-analysis.md
docs/issues/06-prop4you-raw-extractors-leadfinder-modeling/09-sql-extractor-ddl-review.md
docs/issues/06-prop4you-raw-extractors-leadfinder-modeling/10-python-extractor-review.md
```

## SQL DDL objects

```text
prop4you_matrix.jsonb_path_label(text[])
prop4you_matrix.raw_path_extraction_runs
prop4you_matrix.raw_path_summary_evidence
prop4you_matrix.v_raw_record_leaf_path_evidence
prop4you_matrix.v_raw_path_current_summary
prop4you_matrix.refresh_raw_path_summary_evidence(...)
prop4you_matrix.raw_record_path_type_evidence(uuid, integer)
```

## Python extractor proof

```json
{
  "artifact_class_counts": {
    "context": 1,
    "matrix_analysis_baseline_only": 19,
    "matrix_analysis_contextual": 19,
    "matrix_analysis_discrepancy": 19,
    "matrix_contract": 19,
    "provider_raw_payload": 1,
    "source_manifest": 19
  },
  "expected_count": 97,
  "expected_count_ok": true,
  "file_count": 97,
  "ok": true,
  "output_json": ".tmp/prop4you-raw-extractors/reiq-path-candidates-final.json",
  "output_md": ".tmp/prop4you-raw-extractors/reiq-path-candidates-final.md",
  "parse_error_count": 0,
  "privacy_contract": "No raw JSON values are emitted; only paths, JSON types, counts, byte sizes, and short SHA-256 samples.",
  "root": "/home/marcelo-karval/Backup/Projetos/prop4you/prop4you-inertia/backend/src/apps/system/matrix/registry/reiq/loan_modification/fl",
  "root_type_counts": {
    "object": 97
  },
  "total_bytes": 7027134,
  "unique_path_type_count": 3685
}
```

## SQL extractor proof

```json
{
  "live_summary_rows": 9650,
  "no_raw_values_printed": true,
  "raw_record_count": 97,
  "run_count": 1,
  "run_counts": [
    {
      "distinct_path_count": 9650,
      "extracted_path_count": 172700,
      "source_record_count": 97
    }
  ],
  "summary_rows": 9650
}
```

## Boundaries

Not claimed:

- SourceHub translated DTO table implemented;
- final LeadFinder materialization implemented;
- field candidates promoted to `in_review`;
- production deployment;
- provider/API calls;
- raw payloads committed or printed.

## Subagent status

- Worker A timed out and produced no usable artifact.
- Worker A2 completed the reduced filter-pressure analysis.
- Worker B completed SQL extractor DDL.
- Worker C completed Python extractor script.
- Thor independently reviewed artifacts and ran proof.

## Next steps

1. Implement a gap/proposal bridge from `raw_path_summary_evidence` + Python summaries + filter pressure into `prop4you_leadfinder.canonical_gaps` / `growth_pressure_signals`.
2. Generate first Matrix `quality_report` artifact from extractor evidence.
3. Generate first Matrix `field_mapping_set` artifact only after gap bridge exists.
4. Then implement SourceHub `translated_dto_publications` against selected artifact + dictionary version.
5. Only after that promote selected field candidates from `candidate` to `in_review`.


## Browser proof

PASS. See `06-browser-proof.md`. Static page rendered expected title/badges/content, browser console had 0 errors, and vision QA passed.
