# PRD — Prop4You LeadFinder dictionary from raws

Status: draft

## Problem

LeadFinder Group owns the canonical dictionary, but that dictionary is born from raw/provider/internal evidence. The current PG18 DDL has SourceHub and Matrix experimental structures, but lacks a LeadFinder-owned dictionary that can receive raw-derived candidate families/fields and govern what later becomes final LeadFinder materialization.

## Goals

- Analyze the locally found raw-like/provider/baseline evidence into LeadFinder families and fields without PII/raw dumps.
- Mark Matrix `canonical_*` as experimental mirror/candidate structures, not canonical ownership.
- Implement LeadFinder-owned canonical dictionary DDL v0 with families, fields, gaps and growth signals.
- Seed initial family/field candidates from raw/code evidence, including property/owner/phone/email/details/situations/valuation/lineage/opportunity families.
- Extend lab proof to apply LeadFinder dictionary DDL after provider/sourcehub/matrix experimental DDL.
- Persist review/final report and browser proof.

## Non-goals

- No final property/owner/phone/email materialization tables yet.
- No raw corpus ingestion into DB in this slice.
- No provider calls.
- No production deployment.
- No committed raw/fake/redacted fixtures.

## Acceptance criteria

- DDL exists under `database/ddl/projects/prop4you/leadfinder/0001_canonical_dictionary.sql`.
- Matrix DDL/docs clearly state `canonical_*` are experimental mirrors/candidates.
- Lab proof applies base + Prop4You provider/sourcehub/matrix/leadfinder DDL in clean PG18 lab DB.
- Report includes counts and non-claim boundaries.
- Browser proof renders PRD/task review/final/lab proof.
