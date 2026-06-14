# Prop4You Database-Centric Base Extraction

Status: ACTIVE_ANALYSIS
Purpose: guide extraction of reusable database-centric base capabilities from Prop4You Django history without binding the DDL layer to Django.

## 1. Executive decision

Do not create a canonical `database/ddl/platform/django/` package.

Reason: we are not preserving Django as the owner of business truth. We are extracting recurring business and operational rules from Django-era projects into a framework-agnostic database-centric base.

Django, FastAPI, Kong, PostgREST, workers and frontends are transports/consumers. The database-centric kernel owns durable business truth and invariants.

## 2. Prop4You sources to analyze together

Two repositories/sources matter:

```text
app.prop4you.com
  older/base Django app surface with reusable operational apps

prop4you-inertia
  evolved domain-oriented implementation and better soft-DDD direction
```

Use both. Extract the best and most functional rules from each.

## 3. Evidence from current inspection

`app.prop4you.com` exposes Django app-oriented modules such as:

```text
activities
auth
cache
core
email
events
monitoring
notifications
observability
settings
tokens
users
```

Representative model/capability names found:

```text
Profile
UserConfig
OAuthClient
OAuthAuthorizationCode
OAuthToken
UserLoginHistory
UserLoginAttempt
UserActivityLog
SettingCategory
Setting
SettingValue
SettingHistory
NotificationTemplate
NotificationChannel
Notification
NotificationPreference
NotificationDelivery
Timeline
SystemAlert
Metric
AlertRule
ObservabilityConfig
DynamicEventPlugin
```

`prop4you-inertia` exposes domain-oriented modules such as:

```text
identity
geography
real_estate
finance
communication
data
reporting
sales
invitations
marketplace
system/matrix
core/db/audit
```

Representative model/capability areas found:

```text
identity: user, blacklist, legal, mfa, deletion, email, feature flags
geography: area, address, geokeo candidates
real_estate: situation, lead score, valuation, history, notes, semantic base, lead intelligence, filters, events, relationships, details, CRM/activity
finance: billing, plan changes, plan features, checkout, balance, credits
communication: campaigns
data: skip trace, system cache, lead source
system/matrix: schema genome, approvals, baselines, corpus/review statuses
core/db/audit: audit logs
```

## 4. Package naming rule

Use:

```text
database/ddl/base/
```

for reusable, framework-agnostic database-centric primitives.

Use:

```text
database/ddl/projects/prop4you/
```

for Prop4You-specific domain DDL.

If a middle reusable package is needed later, name it by capability, not framework. Acceptable examples:

```text
database/ddl/capabilities/identity/
database/ddl/capabilities/notifications/
database/ddl/capabilities/observability/
```

But start simple: base first, project second.

Avoid:

```text
database/ddl/platform/django/
```

as a canonical package name.

## 5. Base capabilities likely reusable across 99.999% of projects

These should be candidates for `database/ddl/base/`, subject to implementation review:

### Install/migration tracking

```text
ddl_migrations
filename/checksum/status/applied_at/applied_by/execution_ms/error_message
```

### Public ID generation

A project-wide pattern for stable public IDs, separate from internal primary keys.

Candidate concepts:

```text
public_id prefix registry
public_id generation function
unique public_id constraints
non-sequential external identifiers
```

Public IDs are common across most Karval projects and should not be reimplemented per domain.

### Standard row lifecycle

Common columns/patterns:

```text
created_at
updated_at
deleted_at
created_by
updated_by
deleted_by
is_active / status where appropriate
```

Prefer logical delete for user/business entities where audit/history matters.

### Update timestamp trigger/function

Reusable deterministic `updated_at` behavior.

### Actor/request context

Functions to read current actor/tenant/org/request context from transaction-local settings or validated RPC input.

Example concepts:

```text
base.current_actor_id()
base.current_tenant_id()
base.current_request_id()
```

### Audit base

Generic audit/change/event recording primitives.

Not every table needs full row auditing on day one, but the base must provide a consistent place to record critical changes.

### Realtime base

Reusable event outbox/subscription/ACK/cursor primitives, ideally under `realtime.*`, not `private.*`.

### API health/profile base

Minimal `api.*` facade for health and current context.

### JSONB contract helpers

Reusable helpers/checks for:

```text
jsonb object validation
schema validation hooks
payload shape checks
safe metadata defaults
```

### Logical deletion helpers

A consistent soft-delete pattern:

```text
mark deleted
restore where allowed
query active records via views or policies
```

### Naming/constraint conventions

Reusable conventions for:

```text
primary keys
public IDs
unique constraints
foreign keys
RLS policy names
index names
trigger names
```

## 6. What belongs to Prop4You project DDL

Prop4You-specific DDL should stay under:

```text
database/ddl/projects/prop4you/
```

Candidate domains:

```text
identity
property
geography
leadfinder
matrix
sourcehub
skiptrace
realtime
finance
communication
audit
api
```

Do not bake these into the PG18 image.

## 7. What must be inventoried before SQL creation

Before writing the first real Prop4You DDL package, create an inventory mapping:

```text
source repo
source path
model/class/function
current Django app/domain
proposed database schema
proposed table/function/view/policy
base vs project classification
risk
priority
notes
```

Recommended inventory doc:

```text
docs/prop4you-django-ddl-inventory.md
```

## 8. Initial DDL installer direction

The next implementation slice should create only the installer and the first base migration:

```text
scripts/apply-ddl-package.sh
database/ddl/base/0001_install_tracking.sql
```

Then prove:

```text
dry-run lists ordered SQL files
apply records filename/checksum
reapply skips identical checksums
checksum change is blocked
status can be read back through SQL/API proof
```

## 9. Key rule

Extract from Django; do not replicate Django.

The target is a reusable Application Data Kernel where business invariants live in ordered SQL packages and every external framework is a replaceable transport.
