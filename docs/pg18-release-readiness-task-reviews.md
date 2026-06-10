# PG18 Release-Readiness — Task Reviews

## Review policy

- PASS: delivered and verified.
- WARN: delivered with bounded residual or environment limitation.
- FAIL: not delivered or unverified.

## Task-by-task review

| Task | Requested | Delivered | Evidence | Verdict |
|---|---|---|---|---|
| RR-01 PRD | Persist executive PRD | `docs/pg18-release-readiness-prd.md` | File exists and captures user decisions | PASS |
| RR-02 Tasks | Persist detailed tasks from PRD | `docs/pg18-release-readiness-tasks.md` | Task ledger exists with acceptance criteria | PASS |
| RR-03 Preflight | Repo/runtime/README preflight | Git/runtime/README/scripts inspected before edits | README rewrite and runtime evidence | PASS |
| RR-04 Local validation | Run local release-readiness gates | syntax/status/baseline smoke/promote skip-update/Docker build path/validation-image smoke | `docs/pg18-release-readiness-local-tests-evidence.md` | PASS |
| RR-05 README | Realign README to PG18 reality | `README.md` rewritten around PG18 local release-readiness | Legacy WIP/upstream claims removed | PASS |
| RR-06 Parity contracts | Document safeupdate/supautils/plan_filter | `docs/pg18-parity-contracts.md` | `supautils`/`plan_filter` parity-only; `safeupdate` behavioral proof | PASS |
| RR-07 Database-centric PRD | Persist PostgREST/web next PRD | `docs/pg18-database-centric-postgrest-web-prd.md` | Gateway=PostgREST, client=web, Django excluded | PASS |
| RR-08 Browser-proof | Browser + vision over report | Local server, HTTP 200, console clear, vision PASS | `docs/pg18-release-readiness-browser-proof-evidence.md` | PASS |
| RR-09 Reviews | Independent review and parent correction | Two read-only audits plus parent final review; corrections applied | This file and final report | PASS |
| RR-10 Commit/close | Commit and final chat report | Pending commit at time of this file generation | final chat after commit | PENDING_UNTIL_COMMIT |

## Requested vs delivered side-by-side

| User asked | Delivered |
|---|---|
| Next steps 1..6 | Covered by local tests/release-readiness/docs/parity/PostgREST-web planning |
| PRD persisted | `docs/pg18-release-readiness-prd.md` |
| Tasks persisted | `docs/pg18-release-readiness-tasks.md` |
| Execute tasks | All executable local gates ran; host-Nix documented as runner requirement |
| Review by task | This document |
| Final review | `docs/pg18-release-readiness-final-report.md` |
| Correct without HITL | validate script, evidence docs, README, and smoke invocation corrected |
| Browser-proof + vision | PASS evidence persisted |
| Mark tasks delivered | Hermes todo ledger updated; RR-10 closes after commit |

## Independent audit summary

### README/docs audit

Verdict: actionable findings accepted.

Key findings applied:

- README still described PG18 as bootstrap/WIP.
- README duplicated legacy/upstream content and hid current PG18 truth.
- README did not explain PG18 extension/runtime contract distinctions.
- README over-broadened production readiness language.

Correction:

- README was rewritten to state local PG18 release-readiness, accepted image, build/validation scripts, contract model, and non-claims.

### Validation/scripts audit

Verdict: actionable findings accepted.

Key findings applied:

- `validate-pg18.sh` argument value handling was not defensive enough.
- `validate-pg18.sh` did not append FAIL entries to summary on failed step.
- local test evidence file was missing.
- browser evidence was missing.
- final report still had pending statuses.

Correction:

- `validate-pg18.sh` patched.
- Docker-only validate completed successfully.
- Fresh validation image smoke completed successfully.
- evidence/final report updated.

## Residual warning

Host-Nix validation is WARN/BLOCKED on this workstation due to missing `nix` on PATH. This is documented as a runner requirement, not a Docker release path failure.

## Final correction round

- `scripts/promote-pg18-stack.sh` changed to validate-only by default; `--apply` is required for retag and Swarm update.
- Singular local-test evidence file marked superseded by plural canonical file.
- Task ledger synchronized with final state; RR-10 marked DONE after commit.
- Final report taxonomy changed to `LOCAL_RELEASE_READINESS_WARN` with Docker release-candidate posture explicitly explained.
