# Executive synthesis — raw extractors for LeadFinder modeling

Status: delivered
Updated: 2026-06-16T16:52:19
Reviewer: Thor/default

## Decision resolved

Question: implement SourceHub DTO first or SQL/Python extractors first?

Answer:

```text
SQL/Python extractors first.
```

Reason:

```text
raw data are the matriz for canonical discovery and LeadFinder Group modeling;
LeadFinder filters are demand-side pressure for organized/rastreável data;
SourceHub translated DTO publication should not freeze before path/type/filter evidence shapes the LeadFinder Group contract.
```

## Delivered gates

```text
raw REIQ JSON files
  -> Python path/type/frequency scanner
  -> SourceHub raw_records JSONB lab ingestion
  -> SQL path extraction from raw_records
  -> Matrix aggregate path evidence
  -> LeadFinder modeling pressure synthesis
```

## Python extractor evidence

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

## SQL extractor evidence

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

## LeadFinder filter pressure

The existing LeadFinder code demands organized/indexable concepts around:

```text
geography/bbox/location
property type/specs
active situations
occupancy
valuation/equity/debt
ownership current/history
owner type/portfolio/cash buyer/absentee/in-state
phone validity/DNC/dead_line/status/priority
email validity/bounce/status
lead score/classification/queue/dead
lists/tags/presets/workspace overlays
```

## Architectural consequence

The next model should not be SourceHub DTO first. The correct next promoted artifact is a modeling/gap bridge:

```text
raw path evidence + filter pressure -> LeadFinder family/field gap candidates
```

Then SourceHub DTO can be implemented against known target families/fields.
