# Final Report — PG18 DDL Installer/Base Slice

Status: DELIVERED_LOCAL_DDL_BASE_PROOF
Date: 2026-06-14
Orchestrator/final reviewer: Thor/default

## 1. Executive summary

Delivered the first executable database-centric DDL slice for the PG18 platform.

The slice includes a deterministic package installer, base install tracking, public ID prefix registry + uuid7 pointer model, lifecycle/JSON/search/audit/realtime/API base DDL, PRD/tasks/reviews, and browser-proof/vision QA.

## 2. Files delivered

```text
scripts/apply-ddl-package.sh
database/ddl/base/0001_install_tracking.sql
database/ddl/base/0002_base_schemas_roles_context.sql
database/ddl/base/0003_public_id.sql
database/ddl/base/0004_lifecycle_columns_triggers.sql
database/ddl/base/0005_jsonb_contract_helpers.sql
database/ddl/base/0006_search_normalization.sql
database/ddl/base/0007_audit_log.sql
database/ddl/base/0008_realtime_base.sql
database/ddl/base/0009_api_base.sql
database/ddl/base/README.md
docs/ddl-installer-prd.md
docs/ddl-installer-tasks.md
docs/reviews/ddl-installer-architecture-review.md
docs/reviews/ddl-installer-architecture-rereview.md
docs/reviews/ddl-installer-task-review.md
docs/reviews/ddl-installer-final-review.md
docs/proofs/ddl-installer-browser-proof.html
docs/proofs/ddl-installer-browser-proof.md
docs/reports/ddl-installer-final-report.md
```

Also updated canonical entrypoints and docs:

```text
AGENTS.md
README.md
llms.txt
llms-full.txt
docs/canonical-docs-index.md
docs/prop4you-core-db-to-ddl-analysis.md
docs/pg18-database-centric-ddl-strategy.md
database/ddl/README.md
```

## 3. Key architectural decisions implemented

### 3.1 Extension preservation

The DDL slice does not mutate image/build extension surfaces and does not remove extensions.

Runtime proof recorded:

```text
available_extensions=79
installed_extensions=2
```

`pgcrypto` is used only as an additive runtime helper via `CREATE EXTENSION IF NOT EXISTS` in base tracking, not as image-regression work.

### 3.2 Audit

Implemented durable object/business audit:

```text
audit.log
audit.record_log(...)
```

Decision:

```text
pgaudit is complementary for statement/session/server logs; it does not replace durable business/domain audit.log.
```

### 3.3 Public ID

Implemented the new rule:

```text
<prefix>_<uuid7>
```

Where:

```text
prefix -> base.public_id_prefix_registry -> schema/table/id_column
uuid7 -> real object primary key pointer
```

Proof:

```text
registered_prefix=usr
public_ref=usr_019ec642-1a4a-7a8e-9877-9c31b7c427dc
parse_prefix=usr,uuid_version=7
resolve_schema=base,table=ddl_migrations
```

The old random 24-character suffix design is marked historical/superseded.

## 4. Runtime validation

Fresh temporary DB proof against the local PG18 container:

```text
fresh apply: all 9 files DONE
fresh reapply: all 9 files SKIP
status: 9 applied rows
version=18.0
schemas=4
migrations=9
uuidv7_version=7
audit insert returned audit_id
realtime event insert returned event_id
api_health_ok=true
ddl_status=9
```

## 5. Browser/vision QA

Proof artifact:

```text
docs/proofs/ddl-installer-browser-proof.html
```

QA result:

```text
HTTP HEAD: 200 OK
Browser title: PG18 DDL Installer Browser Proof
Console: one expected log, zero JS errors
Vision: visible PASS verdict, proof cards, SQL proof highlights and delivered files table
Server: agent-owned python http.server monitored and stopped after capture
```

## 6. Subagent orchestration

Used two bounded subagents:

```text
SA-impl: implementation lane
SA-arch: architecture review lane
SA-arch-rereview: focused re-review after parent fixes
```

Monitoring artifacts:

```text
.tmp/ddl-installer/subagents/SA-impl-status.md
.tmp/ddl-installer/subagents/SA-impl-final.md
.tmp/ddl-installer/subagents/SA-arch-status.md
.tmp/ddl-installer/subagents/SA-arch-final.md
.tmp/ddl-installer/subagents/SA-arch-rereview-status.md
.tmp/ddl-installer/subagents/SA-arch-rereview-final.md
```

No idle/trapped subagent remained active; synchronous delegate lanes returned cleanly. Browser server was parent-owned and killed after proof.

## 7. Corrections made during gates

```text
1. Fixed DATABASE_URL vs PGHOST precedence in installer.
2. Removed fragile psql -c :'var' interpolation.
3. Fixed bash metadata default that added extra JSON brace.
4. Renamed SQL variadic parameter from reserved word values to input_values.
5. Renamed public_id function params to avoid PL/pgSQL ambiguity.
6. Cleaned stale docs: random suffix public_id and private.ddl_migrations.
7. Corrected proof query for api.ddl_status() rowset.
```

## 8. Requested vs delivered

| Requested | Delivered | Verdict |
|---|---|---|
| PRD persisted | `docs/ddl-installer-prd.md` | PASS |
| Tasks persisted | `docs/ddl-installer-tasks.md` | PASS |
| Start execution | Installer + DDL 0001-0009 implemented | PASS |
| No extension regression | No image/build mutation; extension inventory proof recorded | PASS |
| Audit extension consideration | pgaudit documented as complementary; audit.log implemented | PASS |
| New public_id model | prefix registry + uuid7 pointer implemented/proofed | PASS |
| Task review + final review | persisted under `docs/reviews/` | PASS |
| Browser-proof + vision | proof HTML/MD + browser/console/vision QA | PASS |
| Final report persisted | this file | PASS |

## 9. Non-claims and residuals

```text
No production deployment.
No registry push.
No image rebuild.
No full Prop4You domain DDL yet.
No Nix no-skip release gate rerun in this slice.
```

## 10. Recommended next steps

1. Prop4You base inventory to first domain DDL:
   - `database/ddl/projects/prop4you/0001_identity.sql`
   - `0002_geography.sql`
   - `0003_property.sql`
   - `0004_sourcehub.sql`

2. Decide whether reusable non-base capabilities deserve their own packages:
   - `database/ddl/capabilities/identity/`
   - `database/ddl/capabilities/notifications/`
   - `database/ddl/capabilities/observability/`

3. Add pgTAP or SQL assertion tests for base helpers.

4. Add checksum-drift negative test for the installer.

5. Decide audit operating mode:
   - keep `audit.log` as durable business audit;
   - optionally enable pgaudit policy/config in runtime ops docs, not as replacement.

6. Decide if public-ref resolution should expose a SECURITY DEFINER safe lookup RPC for PostgREST:
   - `api.resolve_public_ref(public_ref text)`
   - with allowlist/RLS-aware behavior.

## 11. Questions for next slice

1. For Prop4You DDL, should `identity` be the first project domain, or should we start with `geography/property` because public ID and SourceHub depend heavily on property objects?
2. Should public ref format stay `<prefix>_<uuid>` with full UUID text, or do we want a display-only compact alias later while preserving uuid7 internally?
3. Do we want pgaudit configured in the proof stack now as an ops layer, or defer until production/runtime policy work?
