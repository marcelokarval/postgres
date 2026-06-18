# 00 — Detection and analysis

Status: active
Generated: 2026-06-18T18:38:31

## User request

Find and list all `.json` files in `prop4you-inertia`, analyze all of them, determine which are in the project/LFG context, and use them as LFG corpus base.

## Interpretation

- `prop4you-inertia` root: `/home/marcelo-karval/Backup/Projetos/prop4you/prop4you-inertia`.
- Top-level root JSONs are listed separately.
- Recursive JSON inventory includes every `.json` under the repo, including support/dependency/config files, but only project-relevant JSONs are promoted as LFG corpus candidates.
- No raw JSON values or PII are copied into docs. Only path, hash, size, root type, top-level keys, path/type shapes, and classification are persisted.

## Goal

Create a governed LFG corpus manifest from prop4you-inertia JSON evidence and prepare the next projection-candidate slice.

## Non-goals

- no provider/API calls;
- no raw payload dumps;
- no PII values;
- no database ingestion mutation;
- no final table/column projections yet;
- no public API/RLS changes.
