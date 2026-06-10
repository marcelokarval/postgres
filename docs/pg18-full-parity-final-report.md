# PG18 Full-Parity Acceptance — Final Report

## Executive verdict

PASS for the requested local PG18 database-image acceptance slice.

The image `local/supabase-postgres:18-karval` is accepted locally with PostgreSQL 18.0, the target Supabase/Postgres PG17 extension surface ported to PG18-compatible versions, correct preload modules, reproducible smoke/promotion/status scripts, persisted PRD/tasks/reviews, and browser-proof report artifact.

## Requested vs delivered

| Requested by Karval | Delivered | Status |
|---|---|---|
| Persist complete executive plan / PRD | `docs/pg18-full-parity-prd.md` | PASS |
| Persist detailed tasks derived from PRD | `docs/pg18-full-parity-tasks.md` | PASS |
| Execute tasks with active correction and no HITL | Scripts/docs/runtime checks executed; safeupdate/preload contracts corrected | PASS |
| Review by task | `docs/pg18-full-parity-task-reviews.md` | PASS |
| Final review comparing requested vs delivered | This report | PASS |
| Runtime proof, not narrative only | Live Swarm service and disposable smoke path validated | PASS |
| Browser-proof QA + vision | Static report generated and served; browser/vision evidence recorded below | PASS |
| Persist final report in same artifact stack | This file under `docs/` | PASS |
| Ask/anticipate next-step questions | Included in next-step section | PASS |

## Runtime evidence anchor

- Final image ID: `sha256:576f2d7cb01fdd0dacd37679eb37100e3da37102c536ecb3ed39173cdd39e9e3`
- Final tags:
  - `local/supabase-postgres:18-karval`
  - `local/supabase-postgres:18-karval-full`
- Live service: `postgres18_postgres`
- Expected live state: `1/1`, healthy
- PostgreSQL: `18.0`
- Required preload: `pg_stat_statements, pgaudit, pg_cron, pg_net, pg_tle, safeupdate`

## Extension result summary

SQL extension smoke passed for:

`http hypopg index_advisor pg_cron pg_graphql pg_hashids pg_jsonschema pg_net pg_repack pg_stat_monitor pg_tle pgaudit pgjwt pgmq pgroonga pgroonga_database pgrouting pgsodium pgtap plpgsql_check postgis rum supabase_vault vector wal2json wrappers pg_partman`

Preload/library surfaces:

- `safeupdate`: PASS, behavior proved.
- `supautils`: PASS for library presence, WARN for deeper behavioral proof pending.
- `plan_filter`: PASS for library presence, WARN for deeper behavioral proof pending.

## Browser-proof evidence

- Local report URL: `http://127.0.0.1:18080/docs/pg18-full-parity-browser-proof.html`
- HTTP proof: `200`, static report fetched successfully with 2991 bytes during QA.
- Browser snapshot proof: page title `PG18 Full-Parity Acceptance`; visible sections include `ACCEPTED`, `PostgreSQL 18 Full-Parity Acceptance`, approved image SHA, `postgres18_postgres`, preload, probes, SQL extension table and next steps.
- Persisted browser evidence artifact: `docs/pg18-browser-proof-evidence.md`.
- Console status: browser console returned zero messages and zero JavaScript errors.
- Vision verdict: PASS. Visual inspection confirmed the report shows ACCEPTED status, PG18 title, image hash, live service, preload, probe list, PASS extension table and next steps. No broken layout or missing critical content observed.

## Residual risks

| Residual | Severity | Why not blocking this slice | Next action |
|---|---|---|---|
| `supautils` deeper behavior not tested | Medium | Library present; image acceptance scope did not require full policy semantics | Compare PG17 Supabase config and add behavior probes |
| `plan_filter` deeper behavior not tested | Medium | Library present; no SQL extension contract | Add config/plan rejection probe if intended active use |
| Full `docker-image-test` on clean Nix runner not rerun in this final slice | Medium | Local image/runtime smoke passed; previous acceptance lane exists | Run clean runner validation and triage outputs |
| Remote registry/digest pin not done | Low/Medium | User asked local stack slice; no registry scope/secrets provided | Push/pin in separate production promotion slice |

## Questions for next planning round

1. Do we want `supautils` and `plan_filter` active as enforced runtime policy in this local PG18 stack, or just present for parity until a Supabase-compatible config layer is ported?
2. Should `local/supabase-postgres:18-karval` be pushed to a private registry now, or remain local-only until a clean CI/Nix runner reproduces it?
3. Should the database-centric backend PRD assume PostgREST-style RPC, Django pass-through, or both as separate gateway profiles?
4. Which app client should be used for the first end-to-end database-centric proof: web, Python desktop, or mobile-shaped API contract?

## Commit evidence

- Local commit created for this slice; resolve exact SHA with `git log -1 --oneline`.
- Working tree after cleanup: clean.

## Recommended next steps

1. Run clean Nix runner validation with `scripts/validate-pg18.sh` and triage any regression output.
2. Add behavioral probes for `supautils` and `plan_filter` if they are meant to enforce policy in PG18.
3. Decide whether `pg_partman` should remain documented as a PG18 bundled extra or be excluded from the strict PG17 parity contract.
4. Start a new PRD for the database-centric backend architecture using schemas, RLS, RPC functions, pgmq, pg_cron, pgaudit, pgjwt, pgsodium/vault, pgroonga, rum, vector, postgis and pgrouting.
5. Decide registry/digest promotion strategy for Portainer/Swarm beyond the local tag.
