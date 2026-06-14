# PRD — PG18 Database-Centric DDL Installer and Base Substrate

Status: ACTIVE_PRD
Date: 2026-06-14
Owner: Thor/default as orchestrator and final reviewer
Branch policy: `develop` is the principal branch; `karval/pg18-bootstrap` mirrors it for the PG18 bootstrap history.

## 1. Executive objective

Create the first executable DDL slice for the PG18 database-centric platform.

The slice must provide:

```text
1. a deterministic DDL package installer;
2. base install tracking;
3. framework-agnostic base schemas/context;
4. public ID mechanics using prefix registry + uuid7 pointer semantics;
5. lifecycle helpers extracted from Prop4You BaseModel/mixins;
6. JSONB/search normalization helpers;
7. audit base with explicit review of native/extension-based alternatives;
8. realtime/API base proof surfaces;
9. persisted task reviews and final requested-vs-delivered closeout;
10. browser-proof/vision QA for the generated local proof artifact.
```

## 2. Non-negotiable architecture corrections

### 2.1 Do not regress extensions

The database-centric discussion must not reduce the extension surface achieved by the PG18 image work.

This slice must treat the existing PG18/supabase-postgres-style extension inventory as a preserved runtime capability. It may add DDL on top, but must not remove, disable, or narrow compiled/runtime extensions.

Validation expectation:

```text
Query pg_available_extensions / pg_extension against the current PG18 proof DB.
Record that this DDL slice does not mutate the image or extension build surfaces.
```

### 2.2 Audit log: evaluate extension-backed path

Before finalizing audit implementation semantics, evaluate whether built-in/available PostgreSQL extensions or image-provided extensions simplify audit.

Candidate surfaces:

```text
pgaudit       -> statement/session audit via server logging, not row audit storage.
pg_stat_*     -> operational stats, not business audit.
event triggers -> DDL audit, not row DML audit alone.
custom audit.log -> durable application/domain audit.
```

Expected decision:

```text
Use extension audit where it helps operational/statement logging, but keep a durable `audit.log` DDL table for business/domain/object audit unless a better installed extension provides equivalent row/object semantics.
```

### 2.3 Public ID redesign

The old Django public ID used random 24-char hash suffixes.

The new database-centric design must not use that old random-hash shape as canonical.

New rule:

```text
public reference = prefix + uuid7
prefix resolves through an intermediate registry to schema_name -> table_name
uuid7 remains the object's real ID and is not destroyed/transformed
lookup path: prefix -> target schema/table, uuid7 -> object row
```

Consequences:

```text
- object tables should use `id uuid primary key default uuidv7()` where possible;
- external-facing object reference may be rendered as `<prefix>_<uuid7>`;
- `base.public_id_prefix_registry` maps prefix to schema/table/entity semantics;
- lookup functions split the reference and return target table metadata + object uuid;
- indexing/order benefits remain on uuid7 primary key;
- public_id no longer needs a 24-char random opaque suffix;
- generated `public_id` may be a convenience column, but canonical identity remains prefix + uuid7.
```

## 3. Sources and context

Read before implementation:

```text
AGENTS.md
README.md
llms.txt
llms-full.txt
docs/canonical-docs-index.md
docs/pg18-application-data-kernel-context.md
docs/prop4you-database-centric-base-extraction.md
docs/prop4you-core-db-to-ddl-analysis.md
docs/database-centric-soft-ddd-rule.md
docs/pg18-database-centric-ddl-strategy.md
```

Prop4You sources used for extraction:

```text
app.prop4you.com/backend/src/apps/core/db/
prop4you-inertia/backend/src/core/db/
```

## 4. Scope

### In scope

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
docs/ddl-installer-prd.md
docs/ddl-installer-tasks.md
docs/reviews/ddl-installer-task-review.md
docs/reviews/ddl-installer-final-review.md
docs/reports/ddl-installer-final-report.md
```

### Out of scope

```text
No registry push.
No image rebuild.
No extension removal.
No production mutation.
No Prop4You full domain DDL port yet.
No Django/FastAPI/Kong-specific package.
No broad generic CRUD over every table.
```

## 5. Base DDL target design

### 5.1 DDL package installer

`scripts/apply-ddl-package.sh` must support:

```text
--package <path>
--database-url <url> OR PG* environment variables
--dry-run
--apply
--status
--schema <tracking_schema default base>
```

Behavior:

```text
- deterministic sorted execution of `*.sql` files;
- dry-run prints ordered file list and checksum without applying;
- apply bootstraps 0001 install tracking if needed;
- apply records filename/checksum/status/execution_ms;
- reapply skips already-applied files with identical checksum;
- checksum drift on previously applied file is a hard error;
- does not print credentials;
- fails fast on SQL error;
- supports local PG18 proof DB.
```

### 5.2 Install tracking

`base.ddl_migrations`:

```text
id uuid primary key default uuidv7()
package_name text not null
filename text not null
checksum text not null
applied_at timestamptz not null default now()
applied_by text not null default current_user
execution_ms integer
status text not null check in ('applied','failed','skipped')
error_message text
metadata jsonb not null default '{}'
unique(package_name, filename)
```

### 5.3 Schemas/context

Create framework-agnostic schemas:

```text
base
audit
realtime
api
```

Context helpers:

```text
base.current_actor_id()
base.current_tenant_id()
base.current_request_id()
base.current_actor_role()
base.set_local_context(...)
```

### 5.4 Public ID

Create:

```text
base.public_id_prefix_registry
base.parse_public_ref(public_ref text)
base.make_public_ref(prefix text, object_id uuid)
base.resolve_public_ref(public_ref text)
base.register_public_id_prefix(...)
```

Registry fields:

```text
prefix text primary key
schema_name name not null
table_name name not null
entity_name text not null
id_column name not null default 'id'
active boolean not null default true
created_at timestamptz not null default now()
metadata jsonb not null default '{}'
```

Reference format:

```text
<prefix>_<uuid7>
```

Important:

```text
The uuid7 suffix is the object's actual primary key.
The function does not hash, compress, encrypt, or destroy the UUID.
```

### 5.5 Lifecycle

Base helpers from Prop4You BaseModel:

```text
base.touch_updated_at()
base.set_lifecycle_defaults()
base.increment_version()
```

Column convention:

```text
created_at timestamptz not null default now()
updated_at timestamptz not null default now()
active boolean not null default true
activated_at timestamptz
deactivated_at timestamptz
deleted boolean not null default false
deleted_at timestamptz
deleted_by_actor_id text
version integer not null default 1 check (version >= 1)
last_modified_by_actor_id text
last_modified_reason text
```

### 5.6 JSONB/search

Helpers:

```text
base.clean_text(text)
base.normalize_email(text)
base.normalize_phone(text)
base.normalize_search_terms(variadic text[])
base.jsonb_is_object(jsonb)
base.jsonb_size_ok(jsonb, max_bytes int default 65536)
base.jsonb_has_dangerous_string(jsonb)
base.jsonb_is_safe(jsonb)
```

### 5.7 Audit

Create durable table:

```text
audit.log
```

But document the extension decision:

```text
pgaudit is complementary server/statement audit, not a replacement for business/domain audit.log.
```

### 5.8 Realtime/API

Reusable base proof:

```text
realtime.event_outbox
realtime.notify_event_outbox()
api.health()
api.current_context()
api.ddl_status()
```

## 6. Acceptance gates

Required gates:

```text
1. Shell syntax check for scripts/apply-ddl-package.sh.
2. Dry-run lists all DDL files with checksums.
3. Apply succeeds against PG18 proof DB.
4. Reapply is idempotent and skips unchanged applied files.
5. SQL proof queries validate schemas/functions/tables.
6. Public ref proof: register prefix -> make ref -> parse ref -> resolve metadata.
7. Audit proof: insert audit row; confirm indexed/queryable row.
8. Extension non-regression evidence: query available/installed extensions; no image changes.
9. Browser proof: generated local HTML report served on 127.0.0.1 and inspected with browser + vision.
10. Task reviews and final side-by-side review persisted.
```

## 7. Deliverable verdict target

Target verdict:

```text
DELIVERED_LOCAL_DDL_BASE_PROOF
```

Not claimed:

```text
production deployment
final Prop4You domain DDL
registry/image mutation
full Nix no-skip release gate
```
