# Executive synthesis — Matrix artifacts + REIQ raw corpus

Status: delivered
Updated: 2026-06-16T15:36:33
Reviewer: Thor/default

## Core result

This slice implements the next gate after LeadFinder dictionary v0:

```text
LeadFinder dictionary version
  -> Matrix mapping session
  -> Matrix transformation artifact
  -> artifact field mappings
  -> future SourceHub translated DTO publication
```

## REIQ corpus reality

The local REIQ registry has 98 JSON files, with 97 under `loan_modification/fl`.

The focused FL corpus contains:

```text
19 source manifests
1 dated provider raw payload
19 contracts
19 baseline-only analyses
19 contextual analyses
19 discrepancy analyses
1 context.json
```

All 97 focused JSON files parse as root objects. No raw values or PII were persisted in repo reports.

## DDL result

Added:

```text
database/ddl/projects/prop4you/matrix/0002_mapping_sessions.sql
```

Objects:

```text
prop4you_matrix.mapping_sessions
prop4you_matrix.transformation_artifacts
prop4you_matrix.artifact_field_mappings
```

All reference `prop4you_leadfinder.canonical_dictionary_versions` as the required dictionary authority.

## Ingestion result

Added:

```text
scripts/ingest-prop4you-reiq-raws-lab.py
```

Validated:

```text
dry-run: 97 files, object root type, no payload values printed
execute lab: INSERT 0 97 into prop4you_sourcehub.raw_records
```

The lab DB was dropped after proof. Payloads were not committed.

## SourceHub readiness

SourceHub translated DTO publication should be next, now that Matrix artifact IDs exist:

```text
raw_record_id
matrix_artifact_id -> prop4you_matrix.transformation_artifacts(id)
leadfinder_dictionary_version_id -> prop4you_leadfinder.canonical_dictionary_versions(id)
translated_dto jsonb
checksum/status/gap references
```
