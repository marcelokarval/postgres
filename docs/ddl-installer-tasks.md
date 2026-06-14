# Tasks — PG18 DDL Installer and Base Substrate

Status: ACTIVE_TASK_LEDGER
Date: 2026-06-14
PRD: `docs/ddl-installer-prd.md`

## Task status legend

```text
PENDING
IN_PROGRESS
DONE
BLOCKED
REVIEW_REQUEST_CHANGES
PASS_AFTER_PARENT_VERIFICATION
```

## T01 — Persist PRD and task ledger

Status: DONE
Owner: Thor/orchestrator

Requested:

```text
Persist complete executive PRD and tasks before implementation.
Incorporate user adendos: no extension regression, audit extension evaluation, public_id prefix registry + uuid7 pointer.
```

Delivered files:

```text
docs/ddl-installer-prd.md
docs/ddl-installer-tasks.md
```

Validation:

```text
Read-back by parent required before final report.
```

## T02 — Implement DDL installer script

Status: DONE
Owner: subagent implementer

Deliver:

```text
scripts/apply-ddl-package.sh
```

Acceptance:

```text
bash -n scripts/apply-ddl-package.sh
scripts/apply-ddl-package.sh --package database/ddl/base --dry-run
scripts/apply-ddl-package.sh --package database/ddl/base --status
```

## T03 — Implement base DDL files 0001-0009

Status: DONE
Owner: subagent implementer

Deliver:

```text
database/ddl/base/0001_install_tracking.sql
database/ddl/base/0002_base_schemas_roles_context.sql
database/ddl/base/0003_public_id.sql
database/ddl/base/0004_lifecycle_columns_triggers.sql
database/ddl/base/0005_jsonb_contract_helpers.sql
database/ddl/base/0006_search_normalization.sql
database/ddl/base/0007_audit_log.sql
database/ddl/base/0008_realtime_base.sql
database/ddl/base/0009_api_base.sql
```

Acceptance:

```text
All SQL applies to PG18 proof DB.
Reapply is idempotent.
Public ID uses prefix + uuid7; no random 24-char suffix canonical behavior.
Audit table exists and extension decision is documented.
```

## T04 — Audit/public_id/extensions architecture review

Status: DONE
Owner: subagent reviewer

Deliver:

```text
docs/reviews/ddl-installer-architecture-review.md
```

Review questions:

```text
Does public_id match prefix registry + uuid7 pointer?
Does audit correctly distinguish pgaudit/extension from durable business audit.log?
Does slice avoid extension regression and image mutation?
Does base stay framework-agnostic and not Django-bound?
```

## T05 — Parent verification and QA proof

Status: DONE
Owner: Thor/orchestrator

Deliver:

```text
docs/proofs/ddl-installer-browser-proof.html
docs/proofs/ddl-installer-browser-proof.md
```

Acceptance:

```text
Run shell/SQL gates.
Serve HTML proof on 127.0.0.1.
Browser navigate to proof.
Inspect console.
Run vision screenshot analysis.
Monitor server liveness before/during/after capture.
Cleanup agent-owned server process.
```

## T06 — Task reviews and final review

Status: DONE
Owner: Thor/orchestrator

Deliver:

```text
docs/reviews/ddl-installer-task-review.md
docs/reviews/ddl-installer-final-review.md
```

Acceptance:

```text
Side-by-side requested vs delivered by task.
REQUEST_CHANGES items corrected before final.
```

## T07 — Final report

Status: DONE
Owner: Thor/orchestrator

Deliver:

```text
docs/reports/ddl-installer-final-report.md
```

Acceptance:

```text
Complete final report persisted and summarized in chat.
Includes next steps and explicit questions/recommendations for next slice.
```

## T08 — Commit and push

Status: DONE
Owner: Thor/orchestrator

Acceptance:

```text
git status clean
push to origin/karval/pg18-bootstrap
push same HEAD to origin/develop
```


## Execution evidence update — 2026-06-14

```text
T02/T03: implemented by SA-impl; parent fixed installer/env precedence, bash metadata default, SQL variadic reserved word, and public_id parameter conflict found by real gates.
T04: initial REQUEST_CHANGES, then PASS on rereview after parent fixes.
T05: PASS fresh temporary DB proof + browser/vision QA.
T06: PASS task/final review persisted.
T07: pending until commit/push command completes; final report records exact commit after push.
```
