# PRD — SourceHub translated DTO publications

Status: active

## Problem

We have raw REIQ records, Matrix path extraction/quality_report/field_mapping_set, and LeadFinder prepare-only dictionary proposals. The missing next database-centric stage is SourceHub publication of versioned translated DTOs that reference raw lineage and Matrix semantics without materializing LFG operational tables.

## Goals

- Implement `sourcehub/0002_translated_dto_publications.sql`.
- Publish translated DTOs from `raw_record + Matrix field_mapping_set + LeadFinder dictionary_version`.
- Keep gateway/framework/runtime agnostic.
- Preserve raw lineage and hash reproducibility.
- Store DTO JSONB but do not print raw values in proof/docs.
- Keep LFG materialization at T5 later.
- Start with 10 mapped rows/records and support later expansion.

## Non-goals

- No Django-specific code.
- No PostgREST-specific code.
- No LFG materialized tables.
- No provider calls.
- No automatic canonical dictionary promotion.
- No raw payload dumps in docs.

## Acceptance

- PG18 lab applies SourceHub 0002 after Matrix 0005 and LeadFinder 0003.
- REIQ 97 raw ingest + extractor + 10 bridges + quality_report + field_mapping_set + prepare-only + translated DTO publication passes.
- Proof shows at least 10 translated DTO publications, linked to raw_record, Matrix artifact and dictionary version.
- Proof shows LFG materialization count remains 0.
