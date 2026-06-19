# 00 — Detection and analysis

Status: active
Generated: 2026-06-19T14:40:30

## User decisions

1. Move now to DDL, not docs-only.
2. DirectSkip phone/email, mailing address, and relationship evidence must be modeled together because DirectSkip returns one coherent skiptrace JSON/envelope.
3. Separate Realtor/REIQ semantically and start with geography plus sequential downstream candidates.

## Slice interpretation

Create a PG18 queryable projection candidate review board. This is a durable DDL registry for path-level decisions before implementing final generated columns, expression indexes, narrow tables, PostGIS geometry, or materialized projections.

## Goal

Create DDL that records candidate groups, candidate JSON paths, semantic lanes, projection decisions, and seven-gate evaluation state using the Slice 15 projection policy and Slice 16 prop4you-inertia corpus base.

## Non-goals

- no final projection tables yet;
- no raw JSON values;
- no provider calls;
- no public API/RLS exposure;
- no workspace tables;
- no broad property/owner/contact table expansion.
