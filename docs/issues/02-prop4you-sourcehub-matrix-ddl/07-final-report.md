# Final Report — Prop4You SourceHub + Matrix experimental DDL v0

Status: closed after browser proof; commit pending at report write time
Updated: 2026-06-15T19:18:10
Owner/reviewer: Thor/default

## Verdict

SUPPORTED for first experimental, non-final Prop4You provider registry + SourceHub corpus/enrichment queue + Matrix semantic dictionary DDL, with clean PG18 lab proof.

NOT CLAIMED:

- final Prop4You property/owner/lead schema;
- provider API calls;
- production deployment;
- LeadFinder materialization;
- raw real corpus ingestion.

## Delivered artifacts

Issue stack:

```text
docs/issues/02-prop4you-sourcehub-matrix-ddl/
```

DDL:

```text
database/ddl/projects/prop4you/providers/0001_provider_registry.sql
database/ddl/projects/prop4you/sourcehub/0001_sourcehub_corpus.sql
database/ddl/projects/prop4you/matrix/0001_semantic_dictionary.sql
```

Proof script/report:

```text
scripts/proof-prop4you-ddl-lab.sh
docs/reports/prop4you-sourcehub-matrix-ddl-lab-proof.md
```

Private corpus path:

```text
~/.hermes/private/prop4you-provider-corpus/
  reiq/
  directskip/
  realtor/
  internal/
```

## Lab proof summary

```text
Status: PASS
LAB_DB: pg18_prop4you_ddl_lab
base DDL applied: 10 files
Prop4You DDL applied: provider + sourcehub + matrix
missing_schemas: []
missing_tables: []
uncommented_tables: []
provider_count: 4
payload_class_count: 5
canonical_family_count: 7
mapping_version_count: 4
jsonb_path_type_smoke: number
jsonb_leaf_paths_smoke_count: 2
```

The script drops the clean lab DB after success unless `KEEP_DB=1`.

## Key design decisions

1. No fake/redacted fixtures are committed.
2. Real corpus path is private and outside git.
3. Django-style extra lookup trigger is now modeled as durable `enrichment_requests`, not as hidden app code.
4. SQL stores intent/state; it does not call providers.
5. Matrix gates provider paths before generated fields/final table columns are frozen.
6. SourceHub raw records preserve payload lineage but are not canonical property/owner/lead truth.

## Subagent execution

- Worker A delivered provider DDL.
- Worker B timed out after producing SourceHub artifacts; parent review accepted artifacts after validation.
- Worker C/C2 failed with Broken pipe; Thor replaced the Matrix lane directly and recorded the substitution.

## Corrections made

- Stale base DDL filename list fixed to dynamic ordered base SQL discovery.
- `jsonb_leaf_paths` recursive CTE fixed for PG18.
- Fragile grep validation replaced with Python JSON validation.
- Fixture policy patched to remove fake/redacted committed fixtures.

## Browser proof

PASS. Static browser proof rendered PRD, task review, final report, provider/sourcehub/matrix DDL reviews and lab proof. Console had 0 errors and vision confirmed the expected title/badges/content. See `06-browser-proof.md`.

## Next steps

1. Create private corpus indexing script that scans `~/.hermes/private/prop4you-provider-corpus/` and writes metadata only to SourceHub tables.
2. Add RLS/access-control design before loading sensitive raw payloads into DB.
3. Add source-specific Matrix path candidate extraction from private corpus, no raw value dumps.
4. Model provider lookup workers outside SQL for enrichment request execution.
5. Add LeadFinder DTO publication proof after Matrix approvals exist.
6. Only then begin canonical property/owner table freeze.

## Questions for next slice

1. Should private corpus indexing write raw JSONB into lab DB, or metadata-only first?
2. Should enrichment request execution be modeled as pgmq jobs, external worker polling, or both?
3. Should Matrix path candidate extraction use SQL JSONB helpers first or a Python scanner that writes candidates into DB?
