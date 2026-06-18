# PRD — Prop4You LFG staging/materialization/operational minimum

Status: active

## Problem

We now have SourceHub T4 translated DTO publications. The next discussed task is to move into LFG without prematurely exploding into dozens of highly-coupled tables.

## Goals

- Create `leadfinder_group` package for T5.
- Implement staging candidates from SourceHub translated DTO publications.
- Implement materialization runs/results as a reviewable execution gate.
- Implement minimal operational tables/facets from materialized staging, enough to prove the path without freezing the final LFG product.
- Keep gateway/runtime agnostic.
- Prove against 97 REIQ raws and 10 DTO publications.

## Non-goals

- No final full LFG app table explosion.
- No Django/PostgREST/ORM dependency.
- No provider calls.
- No direct raw payload dump in docs/proofs.
- No public RLS exposure.
- No scoring/final map/list/detail UI.

## Acceptance

- PG18 lab applies T0-T5 package chain.
- Creates 10 SourceHub translated DTO publications.
- Creates 10 LFG staging candidates.
- Creates 1 materialization run + 10 materialization results.
- Creates minimal operational groups/events/facets from those results.
- Browser-proof + vision confirms evidence.
