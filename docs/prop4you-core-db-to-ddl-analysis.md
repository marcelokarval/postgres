# Prop4You Core DB Base → Database-Centric DDL Analysis

Status: ACTIVE_ANALYSIS
Date: 2026-06-14
Scope: Prop4You Django-era base DB layer, mixins, managers, audit, repositories and service patterns translated into framework-agnostic PG18 DDL direction.

## 1. Sources inspected

Primary evolved source:

```text
prop4you-inertia/backend/src/core/db/
```

Legacy/base source:

```text
app.prop4you.com/backend/src/apps/core/db/
```

Important files/families inspected:

```text
core/db/models/base.py
core/db/mixins/django/*.py
core/db/mixins/pure/*.py
core/db/managers/__init__.py
core/db/audit/models.py
core/db/audit/mixin.py
core/db/audit_context.py
core/db/migrations/0001_initial.py
core/db/migrations/0002_uuid_v7_migration.py
core/db/migrations/0003_alter_dbauditlog_id.py
core/db/routers/system_schema_router.py
apps/core/db/README.md
apps/core/db/models/base.py
apps/core/db/mixins/base.py
apps/core/db/managers.py
apps/core/db/repositories/*.py
apps/core/db/services/model_service.py
apps/core/db/signals/*.py
```

## 2. Executive finding

Prop4You already has a reusable Django-era DB substrate. The substrate is not project-domain-specific; it is an operational base that nearly every app/model inherits.

The database-centric PG18 DDL should extract this substrate into framework-agnostic SQL primitives, not preserve Django as the target architecture.

Core extraction rule:

```text
Extract from Django; do not replicate Django.
```

## 3. Main inherited base capabilities found

### 3.1 Public ID generation

Evidence:

- `PublicIDMixin`
- `PublicIDPureMixin`
- `generate_public_id(prefix, length=24)`

Behavior found:

```text
public_id_prefix per model/class
public_id char/varchar max_length=100
unique public_id
db_index=True
random 24-char alphanumeric suffix
format: <prefix>_<random>
fallback prefix: first 3 chars of class name
```

DDL implication:

```text
base public ID registry and generation functions
prefix validation
unique public_id columns/indexes on inheriting tables
optional generated/trigger-assigned public_id
```

### 3.2 Timestamp lifecycle

Evidence:

- `TimestampMixin`

Fields found:

```text
created / created_at compatibility
updated / updated_at compatibility
created indexed
ordering by -created
```

DDL implication:

```text
created_at timestamptz not null default now()
updated_at timestamptz not null default now()
updated_at trigger
standard index on created_at where useful
```

Prefer database names:

```text
created_at
updated_at
```

instead of Django-era `created`/`updated` for new database-centric DDL.

### 3.3 Active/deactivation lifecycle

Evidence:

- `ActivatableMixin`

Fields found:

```text
active boolean default true indexed
activated_at / activated_on
deactivated_at
activate()
deactivate()
```

DDL implication:

```text
active boolean not null default true
activated_at timestamptz
deactivated_at timestamptz
base.activate_record(...)
base.deactivate_record(...)
status indexes
```

### 3.4 Logical delete / soft delete

Evidence:

- `SoftDeleteMixin`
- `ActiveManager.deleted()`
- `bulk_delete(hard_delete=False)`

Fields/behavior found:

```text
deleted boolean default false indexed
deleted_at timestamptz nullable
soft delete marks deleted=True and deleted_at=now()
restore resets deleted=False and deleted_at=null
bulk soft delete also active=False and activated_at=null
hard_delete exists but is explicit/exception path
```

DDL implication:

```text
deleted boolean not null default false
deleted_at timestamptz
base.soft_delete_record(...)
base.restore_record(...)
active-row views or RLS/query conventions
partial indexes where deleted=false
```

### 3.5 Actor/user tracking

Evidence:

- Legacy `TrackableMixin`
- `created_by`
- `updated_by`
- audit context/current user helpers

Fields found:

```text
created_by
updated_by
last_modified_by
```

DDL implication:

Framework-agnostic actor context should not reference Django auth tables directly.

Use:

```text
created_by_actor_id text/uuid nullable
updated_by_actor_id text/uuid nullable
deleted_by_actor_id text/uuid nullable
base.current_actor_id()
base.current_request_id()
base.current_actor_role()
```

The actual identity table/FK can be added by project/domain DDL when identity is installed.

### 3.6 Versioning / optimistic metadata

Evidence:

- `VersionableMixin`

Fields found:

```text
version positive integer default 1
last_modified_by
last_modified_reason varchar(255)
increment_version on update
```

DDL implication:

```text
version integer not null default 1 check (version >= 1)
last_modified_by_actor_id nullable
last_modified_reason text/varchar
trigger to increment version on update, or command-function-managed version increments
```

Prefer command-function-managed versioning when business semantics matter; generic trigger can be optional.

### 3.7 JSON data/metadata with safety limits

Evidence:

- `DataMixin`
- `MetadataMixin`
- `JSONFieldsMixin`
- `validate_json_field`

Fields/limits found:

```text
data json default dict, nullable in evolved source
metadata json default dict
max serialized JSON size: 65536 bytes
max depth: 10
max keys in object: 100
max array length: 500
dangerous string patterns: <script, javascript:, on*=, data:text/html
```

DDL implication:

```text
data jsonb not null/default '{}'
metadata jsonb not null/default '{}'
base.jsonb_is_safe(...)
base.jsonb_max_depth(...)
base.jsonb_has_dangerous_strings(...)
CHECK jsonb_typeof(...) = 'object'
optional pg_jsonschema validation hooks
```

Important: full recursive XSS/content validation is possible in SQL/PLpgSQL but may be expensive. Use DDL checks for coarse safety and command functions for deep validation.

### 3.8 Search terms / normalized search

Evidence:

- `SearchableMixin`
- `SearchManager`
- `SearchProcessor`

Fields/behavior found:

```text
search ArrayField of normalized terms
normalization removes accents, lowercases, strips special chars, dedupes terms
SearchManager.search(operator='overlap' or 'contains')
search_with_ranking exists in legacy
```

DDL implication:

Options:

1. base search_terms text[] + GIN index.
2. domain-specific tsvector generated columns.
3. PGroonga/RUM/GIN depending on query profile.

Initial base should provide:

```text
search_terms text[] not null default '{}'
base.normalize_search_text(text) returns text[]
GIN index convention for search_terms
```

### 3.9 Cacheable behavior

Evidence:

- `CacheableMixin`
- `CachedQuerySet`

Behavior found:

```text
cache instance
invalidate cache
cache_many
get_cached
legacy cache-first by pk was hardened in evolved source to preserve queryset filters
```

DDL implication:

Do not implement application object cache inside base DDL as core truth.

Possible database-centric extraction:

```text
optional cache invalidation events via realtime/outbox
cache version/counter columns only when needed
```

Base DDL should not include a generic table cache unless a real project need appears.

### 3.10 Audit log and auditable mixin

Evidence:

- `DbAuditLog`
- `DbAuditLogManager`
- `AuditableMixin`
- `SensitiveAuditableMixin`
- `audit_context.py`

Audit actions found:

```text
create
update
delete
view
export
import
login
logout
failed_login
password_change
permission_change
api_call
bulk_update
bulk_delete
restore
activate
deactivate
```

Severity levels found:

```text
debug
info
warning
error
critical
```

Audit fields found:

```text
id uuid, evolved to uuidv7 for new records
action
severity
model_name
object_id
object_repr
user
user_id nullable
description
changes json
ip_address
user_agent
metadata json
created_at indexed
```

Indexes found:

```text
(model_name, object_id)
(user, -created_at)
(action, -created_at)
(severity, -created_at)
(-created_at)
```

DDL implication:

```text
audit.log or audit.event table
uuidv7 primary key
action/severity constrained text/enums
object schema/table/object id fields
actor context fields framework-agnostic
changes jsonb
metadata jsonb
request metadata
indexes matching model/object actor/action/severity/time
```

### 3.11 Bulk operations

Evidence:

- `BaseModel.bulk_create`
- `BaseModel.bulk_update`
- `BaseModel.bulk_delete`
- `ActiveManager.safe_bulk_create`
- repository/service bulk operations

Behavior found:

```text
batch_size default often 100/1000
bulk soft delete updates deleted=True, deleted_at=now(), active=False, activated_at/null
logs success/error
```

DDL implication:

Bulk behavior becomes command functions or patterns:

```text
base.bulk_soft_delete(table/regclass, ids uuid[])
project/domain-specific bulk command functions
batch processing via pgmq/workers when heavy
```

Avoid over-generic dynamic SQL until the installer/base is stable.

### 3.12 Repository / service layer pattern

Evidence:

- `ModelRepositoryInterface`
- `DjangoModelRepository`
- `ModelService`

Operations found:

```text
get_by_id
get_by_public_id
list
list_active
list_inactive
list_deleted
create
update
delete
restore
bulk_create
bulk_update
bulk_delete
search
```

DDL implication:

This maps directly to database-centric RPC conventions:

```text
api.<domain>_get_by_public_id(...)
api.<domain>_list(...)
api.<domain>_create(...)
api.<domain>_update(...)
api.<domain>_soft_delete(...)
api.<domain>_restore(...)
api.<domain>_search(...)
```

But do not generate generic CRUD over every table by default. Use this as a command/query naming standard.

### 3.13 System schema/write guard

Evidence:

- `SystemSchemaRouter`
- `allow_system_writes()` context manager
- protected model labels for SourceHub, Matrix, geography, real_estate system/reference models.

Behavior found:

```text
same database, different schemas
blocks direct writes to protected system models unless explicit context allows it
system/reference/canonical data is guarded
```

DDL implication:

This is important for database-centric architecture.

Translate to:

```text
system-owned schemas/tables with restricted grants
write only via SECURITY DEFINER command functions
RLS/policies prevent direct writes
system_write capability/role instead of Python context manager
```

Candidate roles/capabilities:

```text
app_runtime: read/execute allowed API facade
system_writer: can execute controlled write functions
admin_operator: maintenance/admin paths
realtime_bridge: realtime internals
```

### 3.14 Normalization primitives

Evidence:

- `NormalizedTextPureMixin`
- `AddressAtomizationPureMixin`
- `EmailNormalizationPureMixin`
- `PhoneNormalizationPureMixin`
- `TemporalNormalizationPureMixin`

Behavior found:

```text
clean text: trim/collapse whitespace
email normalize: lower/trim
phone normalize: digits-only + E.164-ish + US 10/11 digit handling
address atomization: address number, street line/name, directionals, occupancy
temporal normalization: date/datetime precision preservation
```

DDL implication:

Strong base candidate:

```text
base.clean_text(text)
base.normalize_email(text)
base.normalize_phone(text) returns composite/jsonb
base.normalize_temporal(text/timestamptz/date) returns structured composite/jsonb
```

Address atomization may be project/capability-specific unless we commit to a SQL parser. Keep in Prop4You/geography first, or implement as integration worker-backed enrichment rather than base SQL.

### 3.15 Geo mixins

Evidence:

Legacy:

```text
PointMixin
MultiPointMixin
LineStringMixin
PolygonMixin
MultiPolygonMixin
GeoMixin
```

Evolved:

```text
PointGeoMixin
BoundaryGeoMixin
GeoSpatialMixin
```

DDL implication:

Do not put all geo in base. Base can document PostGIS availability and naming conventions. Actual geometry columns belong to domains like `geography` or `property`.

## 4. BaseModel composite found

Evolved `BaseModel` combines:

```text
TimestampMixin
ActivatableMixin
SoftDeleteMixin
PublicIDMixin
VersionableMixin
CacheableMixin
SearchableMixin
JSONFieldsMixin
AuditableMixin
Model
```

Legacy `BaseModel` combines:

```text
TimestampMixin
ActivatableMixin
SoftDeleteMixin
PublicIDMixin
CacheableMixin
SearchableMixin
JSONFieldsMixin
Model
```

The evolved source adds stronger audit/versioning and all-objects manager.

## 5. Reach / adoption evidence

`BaseModel` is widely inherited.

Evolved source examples:

```text
apps/system/matrix: 56 BaseModel-derived classes
domains/real_estate: 37
domains/identity: 13
domains/finance: 12
domains/sales: 12
domains/data: 11
domains/geography: 6
```

Legacy app examples:

```text
apps/auth: 15
apps/observability: 15
apps/tokens: 9
apps/events: 8
apps/email: 6
apps/notifications: 5
apps/settings: 4
apps/cache: 2
apps/users: 1
```

Conclusion: this is truly a base substrate, not an incidental helper.

## 6. Recommended DDL package from this analysis

### Base package sequence

Recommended first base package under `database/ddl/base/`:

```text
0001_install_tracking.sql
0002_base_schemas_roles_context.sql
0003_public_id.sql
0004_lifecycle_columns_triggers.sql
0005_jsonb_contract_helpers.sql
0006_search_normalization.sql
0007_audit_log.sql
0008_realtime_base.sql
0009_api_base.sql
```

### 0001_install_tracking.sql

Creates installer state:

```text
base.ddl_migrations
package_name
filename
checksum
applied_at
applied_by
execution_ms
status
error_message
```

### 0002_base_schemas_roles_context.sql

Creates foundation:

```text
schemas: base, audit, realtime, api
context helpers: current_actor_id, current_tenant_id, current_request_id, current_actor_role
role/grant conventions, but no project identity coupling
```

### 0003_public_id.sql

Implements:

```text
base.public_id_prefix_registry
base.generate_public_id(prefix text, random_length int default 24)
base.ensure_public_id trigger function
format/prefix constraints
```

Postgres implementation note: use `pgcrypto`/secure random bytes and encode to URL-safe/base62-like alphabet. Do not use predictable sequences for public IDs.

### 0004_lifecycle_columns_triggers.sql

Implements reusable functions/conventions:

```text
created_at default now()
updated_at trigger
active boolean default true
activated_at/deactivated_at
soft delete: deleted/deleted_at/deleted_by_actor_id
version integer default 1
last_modified_by_actor_id
last_modified_reason
```

Potential functions:

```text
base.touch_updated_at()
base.increment_version()
base.soft_delete_row(...)
base.restore_row(...)
```

Keep generic dynamic row updates limited; prefer per-domain command functions for critical behavior.

### 0005_jsonb_contract_helpers.sql

Implements coarse reusable JSONB safety:

```text
base.jsonb_is_object(jsonb)
base.jsonb_max_depth(jsonb)
base.jsonb_size_ok(jsonb, max_bytes default 65536)
base.jsonb_has_dangerous_string(jsonb)
base.jsonb_is_safe(jsonb)
```

And conventions:

```text
data jsonb not null default '{}'
metadata jsonb not null default '{}'
CHECK jsonb_typeof(data) = 'object'
CHECK jsonb_typeof(metadata) = 'object'
```

### 0006_search_normalization.sql

Implements:

```text
base.clean_text(text)
base.normalize_search_terms(variadic text[]) returns text[]
base.normalize_email(text)
base.normalize_phone(text) returns jsonb/composite
```

Search convention:

```text
search_terms text[] not null default '{}'
GIN index on search_terms
```

### 0007_audit_log.sql

Creates:

```text
audit.log
```

with:

```text
id uuid default uuidv7()
action text constrained
severity text constrained
schema_name/table_name/model_name
object_id text
object_public_id text
object_repr text
actor_id text/uuid nullable
request_id text/uuid nullable
ip_address inet nullable
user_agent text
changes jsonb
metadata jsonb
created_at timestamptz default now()
```

Indexes:

```text
(schema_name, table_name, object_id)
(actor_id, created_at desc)
(action, created_at desc)
(severity, created_at desc)
(created_at desc)
```

### 0008_realtime_base.sql

Move proof semantics toward reusable base:

```text
realtime.event_outbox
realtime.event_acks
realtime.subscriptions / cursors
realtime.notify_event_outbox()
realtime.ack_event(...)
```

Keep project authorization hooks pluggable.

### 0009_api_base.sql

Creates minimal facade:

```text
api.health()
api.current_context()
api.ddl_status()
```

This is not app/business API yet.

## 7. What should NOT be in base DDL initially

Do not put these in base yet:

```text
full Django auth model
oauth clients/tokens
notification templates/channels
email templates/campaigns
observability metrics/alerts
Geo/PostGIS property geometries
Matrix contracts
SourceHub raw records
SkipTrace provider models
Prop4You real estate entities
```

These are reusable candidates or project domains, but not first base substrate.

They belong later in either:

```text
database/ddl/projects/prop4you/
```

or, if proven generic across projects:

```text
database/ddl/capabilities/<capability>/
```

## 8. Proposed capability candidates after base

If we later split reusable capabilities, use capability names, not framework names:

```text
capabilities/identity
capabilities/notifications
capabilities/observability
capabilities/settings
capabilities/events
capabilities/email
```

Do not use:

```text
platform/django
```

## 9. Final DDL vision from this analysis

The first DDL slice should not attempt to port Prop4You domains.

It should implement the substrate that Django BaseModel/mixins/managers repeatedly provided:

```text
install tracking
public IDs
lifecycle columns
logical delete
actor context
versioning
JSONB safety
search normalization
audit log
realtime outbox base
api health/context facade
```

After that, Prop4You domain DDL can safely inherit the database-native conventions the same way Django apps inherited `BaseModel`.
