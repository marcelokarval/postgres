# DDL Installer Architecture Re-review

Status: PASS
Date: 2026-06-14
Reviewer: SA-arch-rereview subagent
Scope: completed PG18 DDL installer/base slice after parent fixes, focused on public reference semantics, audit semantics, extension preservation, framework independence, documentation alignment, and commit-readiness blockers.

## Review basis

Documents and implementation inspected:

- `AGENTS.md`
- `docs/ddl-installer-prd.md`
- `docs/ddl-installer-tasks.md`
- `docs/reviews/ddl-installer-architecture-review.md`
- `docs/prop4you-core-db-to-ddl-analysis.md`
- `database/ddl/README.md`
- `database/ddl/base/README.md`
- `scripts/apply-ddl-package.sh`
- `database/ddl/base/0001_install_tracking.sql`
- `database/ddl/base/0002_base_schemas_roles_context.sql`
- `database/ddl/base/0003_public_id.sql`
- `database/ddl/base/0004_lifecycle_columns_triggers.sql`
- `database/ddl/base/0005_jsonb_contract_helpers.sql`
- `database/ddl/base/0006_search_normalization.sql`
- `database/ddl/base/0007_audit_log.sql`
- `database/ddl/base/0008_realtime_base.sql`
- `database/ddl/base/0009_api_base.sql`

Local static checks run during this re-review:

```text
bash -n scripts/apply-ddl-package.sh
scripts/apply-ddl-package.sh --package database/ddl/base --dry-run
```

The dry-run listed the deterministic `0001` through `0009` file sequence with sha256 checksums. No implementation files were modified by this re-review.

Parent-provided live DB proof considered as runtime evidence:

```text
fresh dry-run listed 0001-0009
fresh apply all DONE
fresh reapply all SKIP
status 9 applied rows
uuidv7_version=7
public_ref=usr_<uuid7>
parse_prefix=usr, uuid_version=7
resolve_schema=base, table=ddl_migrations
audit insert returned audit_id
realtime event insert returned event_id
api_health_ok=true
ddl_status=9
available_extensions=79
installed_extensions=2
```

## Verdict

PASS.

The parent fixes resolve the previous REQUEST_CHANGES items. The active PRD, core analysis, and DDL README now align on `base.ddl_migrations` and prefix-registry + uuid7 public reference semantics. The concrete SQL/script implementation matches the architecture sufficiently for commit; no critical blocker was found.

## Findings by review question

### 1. Public ID prefix registry + uuid7 pointer semantics

Assessment: PASS.

Implementation evidence:

- `database/ddl/base/0003_public_id.sql` creates `base.public_id_prefix_registry` with `prefix`, `schema_name`, `table_name`, `entity_name`, `id_column`, `active`, `created_at`, and `metadata`.
- `base.make_public_ref(prefix text, object_id uuid)` renders `lower(prefix) || '_' || object_id::text`.
- `base.parse_public_ref(public_ref text)` splits on the underscore, validates the prefix with `^[a-z][a-z0-9]{1,31}$`, and casts the suffix directly to `uuid`.
- `base.resolve_public_ref(public_ref text)` returns registry metadata plus the parsed `object_id` uuid pointer. It does not hash, compress, encrypt, replace, or dynamically dereference the UUID.
- `base.register_public_id_prefix(...)` upserts registry rows.
- Parent runtime proof confirmed a generated `usr_<uuid7>` reference, parsed prefix `usr`, UUID version 7, and registry resolution to `base.ddl_migrations`.

Documentation evidence:

- `docs/ddl-installer-prd.md` explicitly rejects the old random 24-character suffix and defines `<prefix>_<uuid7>`.
- `docs/prop4you-core-db-to-ddl-analysis.md` now marks `generate_public_id(prefix, length=24)` as historical source evidence only and recommends `make_public_ref`, `parse_public_ref`, `resolve_public_ref`, and `register_public_id_prefix` for `0003_public_id.sql`.
- `database/ddl/README.md` now points install tracking to `base.ddl_migrations`.
- `database/ddl/base/README.md` explicitly states that the UUID suffix is the actual primary key and is not randomized into the legacy 24-character suffix.

No canonical random public ID generation API is present in the base SQL package.

### 2. Audit: pgaudit/server audit vs durable business audit

Assessment: PASS.

Implementation evidence:

- `database/ddl/base/0007_audit_log.sql` states in the file header that durable business/domain audit is separate from pgaudit, which remains complementary server/statement logging.
- The DDL creates durable `audit.log` with `id uuid default uuidv7()`, constrained `action` and `severity`, schema/table/object identity fields, actor/tenant/request context defaults, request metadata, `changes`, `metadata`, and `created_at`.
- The table has query indexes for object, actor/time, action/time, severity/time, created_at, and request_id.
- `audit.record_log(...)` provides a framework-agnostic insertion helper and returns the new audit UUID.
- Parent runtime proof confirmed an audit insert returned an `audit_id`.

The implementation does not pretend that pgaudit or pg_stat surfaces replace object/business audit storage. It uses pgaudit only as a documented complementary operational audit surface.

### 3. Extension non-regression and image/build immutability

Assessment: PASS.

Implementation evidence:

- The DDL package does not edit image/build recipes, Nix extension definitions, preload settings, release files, or registry/image surfaces.
- The SQL search found no `DROP EXTENSION`, `ALTER SYSTEM`, or `shared_preload` mutation in `database/ddl/base/*.sql`.
- `0001_install_tracking.sql` uses `create extension if not exists pgcrypto;` as an additive runtime guard and uses PG18 `uuidv7()` for package-owned row IDs. This is not an image/build mutation and does not narrow available extension inventory.
- Parent runtime proof recorded `available_extensions=79` and `installed_extensions=2` after the base DDL proof.

Non-blocking note: `pgcrypto` appears additive and harmless, but it is not materially used by the reviewed SQL. If later policy tightens from "no extension regression/image mutation" to "no runtime extension install from base DDL", this line should be reconsidered. Under the current PRD wording and parent proof, it is not a blocker.

### 4. Framework-agnostic design, not platform/Django

Assessment: PASS.

Implementation evidence:

- The DDL package creates cross-cutting schemas `base`, `audit`, `realtime`, and `api`; it does not create `platform/django` or Django-owned schemas/tables.
- Context helpers use transaction-local `app.*` settings and generic `actor_id`, `tenant_id`, `request_id`, and `actor_role` values.
- Audit object identity is schema/table/object oriented. `model_name` exists as a secondary compatibility/search field generated from schema/table in `audit.record_log`, not as the canonical owner.
- Realtime is a generic durable outbox plus ack helper and LISTEN/NOTIFY bridge.
- API is a minimal facade (`api.health`, `api.current_context`, `api.ddl_status`), not a Django/FastAPI/Kong-specific package and not broad generic CRUD.

### 5. Documentation alignment: active PRD, core analysis, DDL README

Assessment: PASS for the documents requested in this re-review.

The previous review blockers are corrected:

- `docs/prop4you-core-db-to-ddl-analysis.md` no longer recommends a canonical random 24-character generator in the base package sequence. The random generator is explicitly historical source evidence, and the active implementation note requires `<prefix>_<uuid7>` pointer semantics.
- `database/ddl/README.md` now says the active base installer tracks files in `base.ddl_migrations`.
- `database/ddl/base/README.md` reinforces the active public ID and installer rules.
- `docs/ddl-installer-prd.md` remains consistent with the implementation.

Post-rereview parent cleanup: the adjacent `docs/pg18-database-centric-ddl-strategy.md` historical `private.ddl_migrations` text was updated to point to the active `base.ddl_migrations` installer table, removing the ambiguity noted during rereview.

### 6. Critical defects before commit

Assessment: no critical defects found.

Reviewed implementation concerns:

- Installer supports `--package`, `--database-url` or libpq env, `--dry-run`, `--apply`, `--status`, and `--schema`.
- Dry-run is deterministic and prints filename/checksum order.
- Apply records filename/checksum/status/execution time, skips unchanged applied rows, and errors on checksum drift.
- Credentials are not printed by normal installer output; database URL is redacted in apply mode.
- SQL uses `uuidv7()` for base-owned primary keys where relevant.
- Base package is idempotent enough for the parent-proven apply/reapply path.

Minor non-blocking observations:

- `scripts/apply-ddl-package.sh` records `skipped` as an allowed status in the schema but skips unchanged files without inserting/updating a `skipped` row. This matches the parent proof expectation of 9 applied rows and is not a blocker.
- The installer uses `find` internally for file discovery; this is acceptable inside the script and the dry-run verified deterministic sorted ordering.
- Existing dirty/untracked repository state is broad because this slice is not committed yet. This re-review intentionally did not commit or push.

## Closeout

The completed DDL installer/base implementation is architecturally aligned with the PG18 database-centric substrate PRD after parent fixes. It implements public references as prefix registry + uuid7 pointers, distinguishes durable business audit from pgaudit/server audit, avoids extension regression and image mutation, remains framework-agnostic, and has aligned active documentation. Verdict: PASS.
