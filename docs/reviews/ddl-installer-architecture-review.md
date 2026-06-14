# DDL Installer Architecture Review

Status: REQUEST_CHANGES
Date: 2026-06-14
Reviewer: SA-arch subagent
Scope: planned/implemented DDL installer/base slice with emphasis on extension preservation, audit extension tradeoff, public_id prefix registry + uuid7 semantics, framework-agnostic base, and soft-DDD / Application Data Kernel alignment.

## Review basis

Mandatory documents read:

- `AGENTS.md`
- `docs/ddl-installer-prd.md`
- `docs/ddl-installer-tasks.md`
- `docs/prop4you-core-db-to-ddl-analysis.md`
- `docs/pg18-application-data-kernel-context.md`
- `docs/database-centric-soft-ddd-rule.md`

Repository inspection:

- `scripts/apply-ddl-package.sh` does not exist yet.
- `database/ddl/base/*.sql` does not exist yet.
- `database/ddl/` currently contains README-only skeletons: `README.md`, `base/README.md`, `projects/prop4you/README.md`.
- `docs/ddl-installer-prd.md` and `docs/ddl-installer-tasks.md` exist and currently appear as untracked files in `git status --short`.

Because implementation files are absent, this review evaluates the planned slice and records anticipated implementation checks. Concrete implementation-level SQL defects cannot be confirmed yet.

## Verdict

REQUEST_CHANGES before treating the architecture package as fully review-clean.

The PRD/tasks capture the user adendos correctly, but there are stale/conflicting adjacent guidance points that should be resolved or explicitly superseded before implementation starts, because they can steer an implementer back to old random public_id behavior or a different install-tracking schema.

## Findings by review question

### 1. Public ID design: prefix registry + uuid7 pointer, no old random 24-char canonical suffix

Assessment: PASS in PRD/tasks; REQUEST_CHANGES for conflicting inherited analysis text.

Positive evidence:

- `docs/ddl-installer-prd.md` lines 61-86 explicitly reject old Django random 24-character public IDs and define `public reference = prefix + uuid7`.
- `docs/ddl-installer-prd.md` lines 79-85 require object rows to use `id uuid primary key default uuidv7()` where possible, render external refs as `<prefix>_<uuid7>`, map prefixes via `base.public_id_prefix_registry`, and keep uuid7 as the actual object ID.
- `docs/ddl-installer-prd.md` lines 214-250 specify `base.public_id_prefix_registry`, `parse_public_ref`, `make_public_ref`, `resolve_public_ref`, `register_public_id_prefix`, the `<prefix>_<uuid7>` format, and state that the function must not hash, compress, encrypt, or destroy the UUID.
- `docs/ddl-installer-tasks.md` lines 83-88 make this an acceptance criterion.

Conflict / requested change:

- `docs/prop4you-core-db-to-ddl-analysis.md` lines 699-710 still recommend `base.generate_public_id(prefix text, random_length int default 24)`, `base.ensure_public_id`, and random secure bytes. This conflicts with the later PRD/user adendo and could reintroduce the old canonical 24-character random suffix.

Required correction:

- Mark that analysis section as historical only, or update it so the recommended `0003_public_id.sql` implementation is `make_public_ref(prefix, object_id uuid)`, `parse_public_ref(public_ref text)`, `resolve_public_ref(public_ref text)`, and registry-based lookup over actual uuid7 IDs. Avoid a canonical `generate_public_id(... random_length default 24)` API.

Anticipated implementation checks:

- No default/generated public ID should call random string generation for canonical identity.
- Any convenience `public_id` column must be derivable from `prefix || '_' || id` and not become a second independent identifier.
- `parse_public_ref` should validate that the suffix is a UUID and return the unmodified UUID.
- `resolve_public_ref` should not dynamic-SQL fetch arbitrary rows unless access controls and identifier quoting are deliberately handled; returning metadata + object UUID is sufficient for the base layer.
- Prefixes should have strict format constraints and uniqueness; registry rows should include `schema_name`, `table_name`, `entity_name`, `id_column`, `active`, and `metadata` as in the PRD.

### 2. Audit design: pgaudit/server audit vs durable business/object `audit.log`

Assessment: PASS in planned architecture.

Positive evidence:

- `docs/ddl-installer-prd.md` lines 42-59 correctly distinguishes candidate audit surfaces:
  - `pgaudit` = statement/session audit via server logging, not row audit storage.
  - `pg_stat_*` = operational statistics, not business audit.
  - event triggers = DDL audit, not row DML audit alone.
  - custom `audit.log` = durable application/domain audit.
- `docs/ddl-installer-prd.md` lines 293-305 require durable `audit.log` and explicitly state that pgaudit is complementary, not a replacement.
- `docs/pg18-application-data-kernel-context.md` lines 265-273 aligns with gateway/app authentication, Postgres authorization/RLS, and pgaudit/audit tables recording critical actions.
- `docs/prop4you-core-db-to-ddl-analysis.md` lines 335-418 support a durable audit table with object, actor, action, severity, changes, metadata, and time indexes.

Anticipated implementation checks:

- `audit.log` should be a durable table, not only server log configuration.
- `audit.log.id` should use `uuid default uuidv7()` where available.
- Object identity should use schema/table/object_id fields and may include `object_public_id` as a convenience, but should not depend on framework model names as canonical identity.
- Actor/request context should be framework-agnostic (`actor_id`, `request_id`, `tenant_id`, role/context settings), not a Django user FK.
- pgaudit configuration, if documented, should remain an operational/server audit supplement and should not be installed/mutated by base DDL unless intentionally in scope.

### 3. Extension preservation and image/build surface immutability

Assessment: PASS in PRD/tasks; implementation absent.

Positive evidence:

- `docs/ddl-installer-prd.md` lines 29-40 says this slice must preserve the existing PG18/supabase-postgres-style extension inventory, may add DDL on top, and must not remove, disable, or narrow compiled/runtime extensions.
- `docs/ddl-installer-prd.md` lines 134-143 put image rebuild, extension removal, and registry push out of scope.
- `docs/ddl-installer-prd.md` lines 319-334 require extension non-regression evidence by querying available/installed extensions and proving no image changes.
- `AGENTS.md` lines 79-95 separates PG18 image/build recipe, sibling stack services, base DDL packages, and project DDL packages.
- Existing repository evidence shows pgaudit and other extensions are image/runtime capabilities, not DDL package responsibilities, e.g. `Dockerfile-18` and runtime smoke scripts include pgaudit/preload/extension checks.

Anticipated implementation checks:

- Base DDL should not edit `Dockerfile-18`, Nix extension definitions, migration bootstrap extension surfaces, or preload settings.
- Base DDL should not contain `DROP EXTENSION` or extension-removal logic.
- If `CREATE EXTENSION IF NOT EXISTS` appears in DDL, it must be minimal, justified, and not narrow the existing surface. Prefer relying on PG18 built-ins such as `uuidv7()` and separately proving extension availability.
- Parent verification should capture before/after extension inventory or at least query `pg_available_extensions` / `pg_extension` in the proof DB and state that the DDL slice did not mutate image/build files.

### 4. Framework-agnostic base, no platform/Django naming/coupling

Assessment: PASS with one documentation consistency watch.

Positive evidence:

- `AGENTS.md` lines 115-116 explicitly prohibits `platform/django` as the canonical target and says Django/FastAPI/Kong/PostgREST are consumers/transports.
- `docs/ddl-installer-prd.md` lines 17-21 and 193-212 require framework-agnostic base schemas/context.
- `docs/ddl-installer-prd.md` lines 134-143 exclude Django/FastAPI/Kong-specific packages.
- `database/ddl/README.md` lines 55-57 repeats the framework extraction rule.
- `docs/prop4you-core-db-to-ddl-analysis.md` lines 44-54 correctly states: extract from Django; do not replicate Django.

Watch item:

- The mandatory analysis document appropriately describes Django-era sources as evidence, but implementation should avoid terms such as `model_name` as the primary object owner. If included for compatibility/search, it should be secondary metadata; canonical object reference should be schema/table/object UUID.

Anticipated implementation checks:

- No `database/ddl/platform/django/` package.
- No `django_*` schemas/tables/functions as canonical base objects.
- No FKs from base tables to Django auth/user tables.
- Base identity/context helpers should use request/session settings and generic actor IDs.
- PostgREST/API functions should live in `api` as a facade and should not imply a specific web framework.

### 5. Alignment with soft-DDD and Application Data Kernel docs

Assessment: PASS in planned architecture.

Positive evidence:

- `docs/database-centric-soft-ddd-rule.md` lines 13-24 defines schemas as domains/bounded contexts, tables as durable records, functions/RPCs as use cases, policies as authorization, triggers/jobs as domain automation, and `api` as public facade.
- `docs/ddl-installer-prd.md` lines 193-202 creates base capability schemas `base`, `audit`, `realtime`, and `api`, which are appropriate cross-cutting kernel schemas rather than project-domain tables under `public`.
- `docs/ddl-installer-prd.md` lines 307-317 creates `realtime.event_outbox`, notify helper, and `api.health/current_context/ddl_status`, consistent with Application Data Kernel event/API facade patterns.
- `docs/pg18-application-data-kernel-context.md` lines 105-132 warns against Mongo-style JSONB modeling; the PRD only defines JSONB helpers and safety checks, not a JSONB-only model.
- `docs/pg18-application-data-kernel-context.md` lines 231-250 distinguishes raw lineage, events, domain command functions, relational truth, outbox/pgmq/workers; the base slice establishes foundation without prematurely porting project domains.

Documentation consistency requested:

- `database/ddl/README.md` lines 49-53 says a future installer should track applied files in a table such as `private.ddl_migrations`, while the active PRD specifies `base.ddl_migrations`. Update or explicitly supersede the README so implementers do not create a `private` tracking schema/table contrary to the active slice.

Anticipated implementation checks:

- Do not put all durable project tables under `public`.
- Do not bake Prop4You DDL into the reusable image.
- Keep `base` generic, `audit` durable operational history, `realtime` outbox/transport primitives, and `api` facade functions only.
- Defer Prop4You domains (`identity`, `property`, `leadfinder`, `matrix`, `sourcehub`, `skiptrace`, etc.) to project packages.

## Concrete requested changes

1. Update or supersede `docs/prop4you-core-db-to-ddl-analysis.md` lines 699-710 so the recommended public_id implementation no longer names a canonical `generate_public_id(prefix, random_length int default 24)` / random-byte strategy. The active strategy must be registry + `<prefix>_<uuid7>` pointer semantics.
2. Update or supersede `database/ddl/README.md` lines 49-53 so install tracking points to `base.ddl_migrations`, matching the PRD, rather than `private.ddl_migrations`.
3. When implementation lands, run a follow-up architecture review against concrete SQL/script files before final acceptance. Current review cannot validate code-level behavior because the files are not present.

## Residual risks

- The PRD is strong, but absent implementation means no proof yet for idempotency, SQL correctness, extension non-regression, public ref parsing/resolution, audit row insertion, or API/realtime proof surfaces.
- Conflicting historical guidance in the analysis document could cause accidental reintroduction of old random public IDs if an implementer follows that section instead of the PRD.
- Extension non-regression requires live DB evidence in parent verification; this review only verifies that the plan asks for that evidence.

## Closeout

The planned DDL slice is directionally aligned with the user adendos and the database-centric PG18 architecture. The active PRD/tasks should be treated as the authority for implementation. Resolve the two stale documentation conflicts above before declaring the architecture review fully clean, then re-review the concrete SQL/script implementation when it exists.
