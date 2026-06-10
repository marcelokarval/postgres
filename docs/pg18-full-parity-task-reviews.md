# PG18 Full-Parity Acceptance — Task Reviews

## Review policy

Each task is reviewed against the requested scope and the delivered artifact/evidence. Verdicts:

- PASS: delivered and verified.
- WARN: delivered with explicitly bounded residual.
- FAIL: not delivered or not verified.

## Task-by-task review

| Task | Requested | Delivered | Evidence | Verdict |
|---|---|---|---|---|
| T01 PRD | Persist full executive PRD | `docs/pg18-full-parity-prd.md` | File exists with goal, scope, ACs, risks, plan, future questions | PASS |
| T02 Tasks | Persist detailed task ledger | `docs/pg18-full-parity-tasks.md` | Ledger covers 12 tasks and status | PASS |
| T03 Acceptance | Persist extension/runtime acceptance | `docs/pg18-full-parity-acceptance.md` | Matrix separates SQL/preload/library surfaces | PASS |
| T04 Smoke script | Reproducible isolated smoke | `scripts/smoke-pg18-full-parity.sh` | Syntax checked and executed during validation | PASS |
| T05 Promotion script | Reproducible Swarm promotion | `scripts/promote-pg18-stack.sh` | Syntax checked; live service already on approved image; script supports forced update | PASS |
| T06 Runtime status | Triage/status helper | `scripts/pg18-runtime-status.sh` | Executed against live stack | PASS |
| T07 Script validation | Test script syntax/status | `bash -n` + status execution | Captured in final report | PASS |
| T08 Live stack validation | Validate live service/runtime/extensions/probes | Live `postgres18_postgres` checked | `1/1`, healthy, PG18, preload, probes | PASS |
| T09 Isolated smoke | Disposable container smoke | Smoke script run against final image | Container started, extensions/probes passed, cleanup done | PASS |
| T10 Task reviews | Per-task review artifact | This file | Requested vs delivered matrix | PASS |
| T11 Browser-proof | Local report served and inspected | `docs/pg18-full-parity-browser-proof.html` | Browser/vision evidence added to final report after execution | PASS |
| T12 Final report | Final side-by-side report | `docs/pg18-full-parity-final-report.md` | Requested-vs-delivered, evidence, residuals, next steps | PASS |

## Active corrections applied during review

- Treated `safeupdate` correctly as preload-only, not `CREATE EXTENSION`.
- Kept `supautils` and `plan_filter` as library/config surfaces with residual behavioral follow-up rather than false SQL-extension claims.
- Avoided reopening stale background build failures after the accepted runtime anchor was established.


## Independent reviewer findings and corrections

Two bounded review lanes returned `REQUEST_CHANGES`. All blocking findings were addressed:

1. `wal2json` contract was clarified as `CREATE EXTENSION` plus output-plugin surface.
2. `pg_partman` was added consistently as a PG18 bundled extra validated by smoke/status/promotion scripts.
3. Browser evidence was persisted in `docs/pg18-browser-proof-evidence.md`.
4. `smoke-pg18-full-parity.sh` now fails if the Supabase init completion marker is not observed before final readiness.
5. Functional probes now assert exact values for `pg_jsonschema`, `postgis`, `vector`, and the expected `safeupdate` error.
6. `promote-pg18-stack.sh` now validates the expected image ID, uses `docker service update --detach=false` when mutating, checks exact extension presence, and has safer arg parsing.
7. `pg18-runtime-status.sh` now validates the accepted image ID and required extension set, including `pg_partman`.

Post-correction validation reran successfully:

- `bash -n` for all three scripts: PASS.
- `scripts/pg18-runtime-status.sh`: PASS, including expected image ID, live container image ID, full extension matrix and library-only surface assertions.
- `scripts/smoke-pg18-full-parity.sh --image local/supabase-postgres:18-karval-full`: PASS with `PG18_FULL_PARITY_SMOKE_OK`.
- `scripts/promote-pg18-stack.sh --skip-update`: PASS with `PG18_STACK_PROMOTION_OK`, including live container image ID, full extension matrix and library-only surface assertions.
- Independent post-fix script reviewer verdict: PASS.
