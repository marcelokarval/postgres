# PRD — Matrix field_mapping_set + LeadFinder prepare-only promotions

Status: active

## Problem

The current stack has raw evidence, LeadFinder gap bridge rows, and Matrix quality_report artifacts. We now need the missing semantic translation artifact: a Matrix `field_mapping_set` generated from the first 10 LeadFinder bridge rows, plus a LeadFinder prepare-only promotion surface that turns those mappings into review proposals without mutating canonical fields/families.

## Goals

- Keep gateway/framework/runtime agnostic.
- Treat raws as both LFG app-model generators and canonical dictionary generators.
- Implement Matrix `0005_field_mapping_set_artifacts.sql`.
- Implement LeadFinder `0003_prepare_dictionary_promotions.sql`.
- Start from 10 bridge rows; support later expansion.
- Do not publish SourceHub DTO yet.
- Do not materialize LFG runtime tables yet.
- Do not auto-promote canonical dictionary rows.

## Non-goals

- No Django-specific contract.
- No PostgREST-specific contract.
- No SourceHub translated DTO publication.
- No LFG materialization/runtime filters.
- No raw values/PII printing or commit.
- No provider calls.

## Acceptance

- PG18 lab applies all DDL through Matrix 0005 + LeadFinder 0003.
- REIQ 97 raw ingest + extractor + 10 bridges + quality_report + field_mapping_set + prepare-only promotions pass.
- Proof shows 1 field_mapping_set and promotion proposals > 0 without canonical field mutation.
