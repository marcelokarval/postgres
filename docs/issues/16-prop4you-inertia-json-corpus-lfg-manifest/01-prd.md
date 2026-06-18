# PRD — Prop4You Inertia JSON corpus manifest for LFG

Status: active

## Problem

The LFG JSONB-first registry exists, but the actual JSON corpus inside `prop4you-inertia` has not been fully enumerated from the repo root. DirectSkip real skiptrace responses and Realtor/Matrix artifacts may exist in JSON files and should be available as evidence before deciding projections.

## Goal

Create a complete, redacted, machine-readable inventory of all `.json` files under `prop4you-inertia`, classify which are relevant to Prop4You/LFG, and create a corpus manifest usable by future LFG projection-candidate slices.

## Deliverables

1. Top-level JSON list from `prop4you-inertia` root.
2. Recursive JSON manifest for every `.json` under `prop4you-inertia`.
3. Classification: `lfg_corpus_candidate`, `project_support`, `dependency_or_tooling`, `unknown_or_out_of_scope`, `parse_error`.
4. Provider/context tags: DirectSkip, Realtor, REIQ, Matrix, SourceHub, LeadFinder, legacy/system, test/fixture, config/tooling.
5. Path/type summary for relevant corpus candidates.
6. Machine-readable manifest under `docs/corpus/prop4you/lfg/`.
7. Persisted reviews, browser-proof, final report.

## Acceptance criteria

- All recursive `.json` files are represented in the machine-readable manifest.
- Top-level root `.json` files are explicitly listed.
- No raw JSON values or PII are emitted.
- Relevant LFG corpus candidates are classified and counted.
- DirectSkip/skiptrace and Realtor JSONs are specifically analyzed.
- Static validation proves counts and parse coverage.
- Browser-proof and vision QA pass.
