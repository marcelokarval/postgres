# Python extractor review — REIQ path candidates

Status: delivered by Worker C at 2026-06-16T19:36:04Z.

## Scope

Implemented `scripts/extract-prop4you-reiq-path-candidates.py` to scan the focused local REIQ corpus and emit a safe path/type/frequency summary for LeadFinder modeling evidence.

Focused root used for validation:

`/home/marcelo-karval/Backup/Projetos/prop4you/prop4you-inertia/backend/src/apps/system/matrix/registry/reiq/loan_modification/fl`

## Safety posture

The scanner does not print raw JSON payload values. Its outputs are limited to:

- JSON paths and JSON types;
- occurrence counts and per-file frequencies;
- aggregate byte counts;
- short SHA-256 file hashes (`sha256_12`);
- relative file paths and artifact classes for traceability.

Array indexes are normalized as `[]`. Suspicious/non-identifier object-key path segments are represented as short key hashes rather than raw key text.

## Validation run

Commands executed from repo root `postgres/`:

```bash
python3 -m py_compile scripts/extract-prop4you-reiq-path-candidates.py
scripts/extract-prop4you-reiq-path-candidates.py \
  --root /home/marcelo-karval/Backup/Projetos/prop4you/prop4you-inertia/backend/src/apps/system/matrix/registry/reiq/loan_modification/fl \
  --expected-count 97 \
  --output-json .tmp/prop4you-raw-extractors/reiq-path-candidates.json \
  --output-md .tmp/prop4you-raw-extractors/reiq-path-candidates.md
```

Observed safe stdout summary:

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
  "parse_error_count": 0,
  "root_type_counts": {
    "object": 97
  },
  "total_bytes": 7027134,
  "unique_path_type_count": 3685
}
```

## Generated local artifacts

These are local proof artifacts under `.tmp/` and contain no raw JSON values:

- `.tmp/prop4you-raw-extractors/reiq-path-candidates.json`
- `.tmp/prop4you-raw-extractors/reiq-path-candidates.md`

## Result

Acceptance criterion for Task T4 is satisfied: the Python extractor scanned all 97 focused REIQ JSON files, found 3,685 unique path/type pairs, reported zero parse errors, and produced safe JSON/Markdown summaries without dumping provider/raw payload values or PII.
