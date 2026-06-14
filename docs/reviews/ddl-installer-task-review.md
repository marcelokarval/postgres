# Task Review — PG18 DDL Installer/Base Slice

Status: PASS_AFTER_PARENT_VERIFICATION
Date: 2026-06-14
Reviewer: Thor/default orchestrator

## Side-by-side task review

| Task | Requested | Delivered | Review verdict | Evidence |
|---|---|---|---|---|
| T01 | Persist PRD and tasks with user adendos | `docs/ddl-installer-prd.md`, `docs/ddl-installer-tasks.md` | PASS | Read-back and indexed from AGENTS/llms/canonical docs |
| T02 | Implement deterministic installer | `scripts/apply-ddl-package.sh` | PASS_AFTER_FIXES | `bash -n`; dry-run; fresh apply; fresh reapply; status |
| T03 | Implement base DDL 0001-0009 | `database/ddl/base/0001...0009.sql` | PASS_AFTER_FIXES | Fresh temporary DB proof: 9 applied rows, reapply SKIP all |
| T04 | Architecture review | Initial review + rereview | PASS_AFTER_REREVIEW | `docs/reviews/ddl-installer-architecture-review.md`, `docs/reviews/ddl-installer-architecture-rereview.md` |
| T05 | Browser-proof + vision | HTML/MD proof | PASS | HTTP 200, browser title, console 0 errors, vision PASS |
| T06 | Persist reviews/final report | this file + final review/report | PASS | Files written and read-back pending final gate |
| T07 | Commit/push | Pending at time of writing | PENDING_FINAL_GATE | To be completed after final validation |

## Corrections made by parent without HITL

1. Installer env precedence bug:
   - Problem: inherited `DATABASE_URL` to host `postgres` overrode explicit `PGHOST/PGPORT`.
   - Fix: `--database-url` wins; explicit `PGHOST`/`PGSERVICE` wins over inherited `DATABASE_URL`; `DATABASE_URL` used only as fallback.

2. Installer psql variable interpolation bug:
   - Problem: `psql -c` did not handle `:'tracking_schema'` usage as expected.
   - Fix: generated safe SQL literals in shell after schema regex validation.

3. Bash metadata default bug:
   - Problem: `${6:-{}}` produced trailing `}` in JSON metadata.
   - Fix: explicit `${6-}` plus default assignment to `'{}'`.

4. SQL reserved word bug:
   - Problem: `variadic values text[]` used reserved word `values`.
   - Fix: renamed to `input_values`.

5. Public ID function ambiguity:
   - Problem: PL/pgSQL parameter `prefix` conflicted with table column in `ON CONFLICT`.
   - Fix: renamed parameters to `p_prefix`, `p_schema_name`, etc.

6. Documentation drift:
   - Problem: stale random 24-char public_id guidance and `private.ddl_migrations` references.
   - Fix: docs updated to prefix registry + uuid7 pointer and `base.ddl_migrations`.

## Verdict

```text
PASS_AFTER_PARENT_VERIFICATION
```
