# PG18 Release-Readiness Slice — Task Ledger

Status values: `PENDING`, `IN_PROGRESS`, `DONE`, `WARN`, `BLOCKED`.

| ID | Task | Scope | Acceptance gate | Status |
|---|---|---|---|---|
| RR-01 | Persist PRD | Write release-readiness PRD with user decisions and gates. | `docs/pg18-release-readiness-prd.md` exists. | DONE |
| RR-02 | Persist tasks | Write this task ledger. | `docs/pg18-release-readiness-tasks.md` exists. | DONE |
| RR-03 | Preflight | Inspect git status, README, scripts and live runtime. | Preflight evidence in final report. | DONE |
| RR-04 | Local validation | Run syntax, runtime status, smoke, validate-only promotion, Docker build path, and validation-image smoke. | `docs/pg18-release-readiness-local-tests-evidence.md`; host-Nix runner caveat documented. | DONE |
| RR-05 | README realignment | Rewrite README to match PG18 accepted local release path. | README no longer says PG18 is only bootstrap/WIP and names validation commands. | DONE |
| RR-06 | Parity contracts | Persist `safeupdate`, `supautils`, `plan_filter` contract. | `docs/pg18-parity-contracts.md`. | DONE |
| RR-07 | Database-centric PRD | Persist next-slice PRD for PostgREST + web, no Django. | `docs/pg18-database-centric-postgrest-web-prd.md`. | DONE |
| RR-08 | Browser-proof | Serve final report locally, inspect browser + vision. | `docs/pg18-release-readiness-browser-proof-evidence.md`. | DONE |
| RR-09 | Review by task | Independent review plus parent corrections. | `docs/pg18-release-readiness-task-reviews.md`. | DONE |
| RR-10 | Final report/commit | Persist final report, commit slice, clean tree. | Local commit created; exact SHA via `git log -1 --oneline`. | DONE |

## Subagent use

Four read-only subagent reviews were used across the slice:

1. README/docs audit.
2. Parity contract + PostgREST/web PRD audit.
3. Final docs/evidence audit.
4. Final scripts/evidence audit.

All subagents were bounded to `terminal` and `file` toolsets. The controller owns all writes, runtime gates, browser proof, final review and commit.
