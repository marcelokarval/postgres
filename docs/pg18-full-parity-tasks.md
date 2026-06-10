# PG18 Full-Parity Acceptance — Task Ledger

Status values: `PENDING`, `IN_PROGRESS`, `DONE`, `BLOCKED`, `WARN`.

| ID | Task | Detailed scope | Acceptance / review gate | Status |
|---|---|---|---|---|
| T01 | Persist PRD | Create `docs/pg18-full-parity-prd.md` with executive goal, scope, acceptance criteria, risks, delivery plan and future questions. | PRD file exists and names requested-vs-delivered closure requirements. | DONE |
| T02 | Persist task ledger | Create this task ledger from the PRD with detailed task scopes and status. | Ledger covers documentation, scripts, validation, reviews, browser-proof and final report. | DONE |
| T03 | Persist acceptance report | Create `docs/pg18-full-parity-acceptance.md` documenting image ID, PG18 runtime, extension/version matrix, preload/library contracts and probes. | Report separates SQL extensions from preload/library-only modules. | DONE |
| T04 | Add isolated smoke script | Create `scripts/smoke-pg18-full-parity.sh`. | Script starts disposable container, waits readiness, checks preload, runs extension smoke, functional probes, library checks and cleanup. | DONE |
| T05 | Add Swarm promotion script | Create `scripts/promote-pg18-stack.sh`. | Script retags `:18-karval-full` to `:18-karval`, forces service update, waits convergence, validates live task and runs stack probes. | DONE |
| T06 | Add runtime status script | Create `scripts/pg18-runtime-status.sh`. | Script reports image IDs, active builds, service/container status, preload and installed target extensions. | DONE |
| T07 | Validate scripts | Run bash syntax checks and help/status paths. | All scripts parse with `bash -n`; status script executes. | DONE |
| T08 | Validate live stack | Run live-stack checks: service health, server version, preload, extension availability, probes. | Live stack remains `1/1` and probes pass. | DONE |
| T09 | Validate isolated smoke | Run disposable container smoke against final image. | Smoke passes and container is cleaned. | DONE |
| T10 | Persist task reviews | Create `docs/pg18-full-parity-task-reviews.md`. | Each task compared requested vs delivered with PASS/WARN/FAIL. | DONE |
| T11 | Browser-proof report | Create static HTML report, serve locally, inspect with browser + screenshot/vision. | Browser opens report, console clean enough, vision confirms report content. | DONE |
| T12 | Persist final report | Create `docs/pg18-full-parity-final-report.md` with requested-vs-delivered matrix, evidence, risks, next steps and questions. | Final report exists and is read back before chat closure. | DONE |

## Subagent policy used

No autonomous implementation subagents were required for the file-writing and runtime-validation lane because the decisive work required privileged local Docker/Swarm/runtime verification in the controller session. Review discipline is still applied through persisted task reviews, direct runtime proof, and final side-by-side acceptance verification. If future behavioral work for `supautils`/`plan_filter` expands, bounded subagents should be used for source analysis and independent review only, not for secrets/runtime mutation.
