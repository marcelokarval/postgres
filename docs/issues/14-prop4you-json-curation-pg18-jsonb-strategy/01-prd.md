# PRD — Prop4You JSON curation and PG18 JSONB canonical strategy

Status: active

## Problem

The previous readiness audit showed LFG is `ready-with-gaps`. A direct translation of the legacy Django table model into PG18 tables risks over-materializing the model before analyzing all provider/native JSON shapes. With Realtor, DirectSkip, REIQ and many future county/provider sources, the better next step is to curate JSON corpora and define how canonical JSON/JSONSchema, JSONB, projected fields, generated columns, indexes and final relational tables should cooperate.

## Goal

Produce a persisted, evidence-based strategy for:

1. DirectSkip response corpus and contact satellite modeling.
2. Realtor JSON/docs/backups and property/geography/market/comparable payload modeling.
3. Legacy tags/labels vocabulary inventory before designing tag groups.
4. PG18 JSONB-first canonical JSONSchema strategy.
5. Table-vs-JSONB decision policy for LFG graph/taxonomy next slice.

## Required outputs

- DirectSkip redacted corpus/path inventory.
- Realtor/backups redacted corpus/path/source inventory.
- Legacy tags/labels inventory.
- ADR: PG18 table-vs-jsonb modeling policy.
- Canonical JSONSchema strategy for multi-source LFG.
- Next-slice recommendation.

## Acceptance criteria

- PRD/tasks/ledger persisted.
- At most 3 simultaneous subagents because runtime cap is 3 despite user allowing 6.
- No raw payload values or PII in artifacts.
- Orchestrator reads/reviews worker artifacts.
- Browser-proof + vision QA pass.
- Final report compares requested vs delivered.
