# PRD — Prop4You SourceHub + Matrix experimental DDL v0

Status: draft
Date: 2026-06-15T18:50:42
Owner: Thor/default

## Problem

Prop4You needs a database-centric foundation for provider/internal JSON payload comparison before final property/owner/lead tables are frozen. The old Django backend triggered extra provider lookups and then mapped responses into application models. The database-centric replacement must model that workflow explicitly using SourceHub ingress, Matrix semantic dictionary/mapping gates and later LeadFinder materialization.

## Goals

- Create first experimental DDL for provider registry, SourceHub raw/corpus records and Matrix canonical dictionary/path mappings.
- Keep all SQL objects commented clearly and objectively.
- Support private real corpus path outside git.
- Avoid committed fake/redacted payload fixtures.
- Extend the lab script from skeleton to apply base DDL + Prop4You experimental DDL into a clean lab DB.
- Prove schema/comment/function basics in PG18 lab.
- Persist task review, browser proof and final report.

## Non-goals

- No final canonical property/owner schema freeze.
- No provider calls.
- No production/runtime mutation.
- No committed raw/fake/redacted fixtures.
- No claims of full LeadFinder materialization.

## Acceptance criteria

- Private corpus path exists with provider subdirs.
- Experimental DDL files exist for providers, SourceHub and Matrix.
- Every schema/table/column/function added has objective comments where practical.
- Lab script can create/drop a clean lab DB and apply base + Prop4You package in dry-run or apply mode.
- Lab proof report is generated.
- Browser-proof renders PRD/review/final summary.
- All tasks marked delivered after parent review.
