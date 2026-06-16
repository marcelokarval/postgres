# PRD — Prop4You raw extractors for LeadFinder Group modeling

Status: active

## Problem

The architecture is aligned that raw provider/internal data generates canonical candidates and also informs the shape of the LeadFinder Group. However, we need explicit SQL/Python extractor gates before SourceHub DTO publication so we can derive modeling evidence from raw JSONB and LeadFinder filters instead of guessing tables too early.

## Goals

- Implement SQL-side extractor DDL that can observe raw JSONB paths/types/counts from `prop4you_sourcehub.raw_records`.
- Implement Python-side scanner for local REIQ focused corpus that emits path/type/frequency summaries without values.
- Analyze LeadFinder filters/code pressure from Prop4You-Inertia as demand-side guide for needed organized/rastreável fields.
- Persist a LeadFinder modeling evidence report connecting raw path evidence + filter pressure + current LeadFinder candidate families.
- Extend lab proof to apply extractor DDL and validate raw ingestion + SQL extraction over REIQ raw_records.
- Keep SourceHub DTO publication deferred until extraction evidence exists.
- Browser-proof PRD/tasks/reviews/final/lab proof.

## Non-goals

- No final SourceHub translated DTO table implementation in this slice.
- No final LeadFinder materialization tables.
- No production deployment.
- No provider calls.
- No raw payload values or PII in repo artifacts.
- No candidate promotion to `in_review` until evidence is reviewed.

## Acceptance criteria

- `database/ddl/projects/prop4you/matrix/0003_raw_path_extractors.sql` exists and applies in PG18 lab.
- SQL extractor can read `raw_records` and produce path/type/count summaries.
- Python extractor can scan 97 focused REIQ JSON files and emit safe summary artifact.
- A LeadFinder filter-pressure/modeling report exists.
- Lab proof inserts 97 REIQ records and validates SQL path extraction count > 0 without printing payloads.
- Browser proof renders stack 06 and lab evidence with console 0 errors + vision PASS.
