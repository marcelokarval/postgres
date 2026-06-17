# PRD — Prop4You LeadFinder raw evidence gap bridge + Matrix quality report

Status: active

## Problem

The previous extractor slice proved that REIQ raw JSON can generate path/type/count evidence and that LeadFinder filters express demand-side pressure for organized, rastreável data. We now need a bridge that turns extractor evidence into LeadFinder-owned gap/proposal records while keeping Matrix quality reporting as a separate review artifact.

## Goals

- Implement LeadFinder DDL `0002_raw_evidence_gap_bridge.sql`.
- Support both:
  - matched gaps against existing `canonical_field_id`;
  - proposed new family/field keys when no canonical field exists yet.
- Preserve temporal separation of phases: raw observation, extraction, gap proposal, quality report, DTO, materialization.
- Implement Matrix quality report support as a separate artifact type/contract using existing `transformation_artifacts` and/or added helper structures/functions.
- Prove DDL in PG18 lab with REIQ 97 raw_records, SQL path extraction, gap bridge creation, and quality report creation without raw value output.
- Persist PRD/tasks/reviews/final/browser-proof.

## Non-goals

- No SourceHub translated DTO publication table in this slice.
- No final LeadFinder materialization tables.
- No production deployment.
- No provider/API calls.
- No raw values/PII committed or printed.
- No automatic candidate promotion to `in_review`.

## Acceptance criteria

- `database/ddl/projects/prop4you/leadfinder/0002_raw_evidence_gap_bridge.sql` exists and applies after LeadFinder 0001 + Matrix 0003.
- Bridge tables/functions capture raw path evidence and filter pressure with temporal phase metadata.
- Bridge supports nullable `canonical_field_id` plus proposed family/field keys.
- Matrix quality_report artifact remains separate from LeadFinder bridge.
- Lab proof creates at least one gap/proposal record and one separate Matrix quality_report artifact from extractor evidence.
- Browser proof shows PRD/task review/final/report and lab evidence with console 0 errors + vision PASS.
