# Base DDL Deep Scan and pgAudit Notes

Status: ACTIVE_RESCAN
Date: 2026-06-14
Scope: answer Karval's follow-up on public_id registry, deeper base DDL completeness, full UUID public reference, and pgAudit comparison.

## 1. Public ID registry answer

Verdict: YES.

The intermediate table that maps a public ID prefix to the correct schema/table/ID semantics exists in the base DDL:

```text
database/ddl/base/0003_public_id.sql
base.public_id_prefix_registry
```

Implemented columns:

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

Implemented functions:

```text
base.make_public_ref(prefix text, object_id uuid)
base.parse_public_ref(public_ref text)
base.resolve_public_ref(public_ref text)
base.register_public_id_prefix(...)
```

Canonical public reference shape:

```text
<prefix>_<uuid7>
```

The uuid7 is not hashed, compressed, encrypted, randomly regenerated, or destroyed. It remains the object's real UUID pointer. The prefix determines the target schema/table/id column through the registry.

## 2. Deep scan result

Re-scan against the active PRD/base scope:

```text
PASS: installer exists :: scripts/apply-ddl-package.sh
PASS: 0001-0009 present
PASS: base.ddl_migrations exists :: 0001
PASS: base.ddl_migrations uuidv7 id :: 0001
PASS: schemas base/audit/realtime/api :: 0002
PASS: context helpers :: 0002
PASS: public id registry exists :: 0003
PASS: public id registry has schema/table/id mapping :: 0003
PASS: public id parse/make/resolve/register :: 0003
PASS: public id canonical is not random/hash :: 0003
PASS: lifecycle helpers :: 0004
PASS: jsonb helpers :: 0005
PASS: search normalization helpers :: 0006
PASS: audit.log and record function :: 0007
PASS: realtime event_outbox/ack :: 0008
PASS: api facade :: 0009
summary 16 / 16
```

Important correction: an initial scan incorrectly looked for `base.lifecycle_state_valid`; the implemented lifecycle helpers are:

```text
base.touch_updated_at()
base.increment_version()
base.set_lifecycle_defaults()
base.mark_deleted()
base.mark_restored()
```

## 3. Public reference decision

Karval preference recorded for this project direction:

```text
Keep full public reference with full UUID text: <prefix>_<uuid7>
```

Reason: the migration away from random IDs was specifically for speed, storage/index clarity, orderability, and using uuid7 directly as a small efficient native UUID value internally.

Note: PostgreSQL `uuid` is 16 bytes internally. The external text rendering is larger, but the database identity/index remains compact and uuid7-ordered.

## 4. pgAudit research notes

Source checked:

```text
https://github.com/pgaudit/pgaudit/blob/main/README.md
https://www.postgresql.org/docs/current/event-triggers.html
https://www.postgresql.org/docs/current/sql-createeventtrigger.html
```

Current local PG18 image/runtime check:

```text
pgaudit_available=18.0
pgaudit_installed=false
shared_preload=pg_stat_statements, pgaudit, pg_cron, pg_net, pg_tle, safeupdate
```

Official pgAudit points from README:

```text
pgAudit provides detailed session and/or object audit logging via the standard PostgreSQL logging facility.
It is aimed at audit logs required for government, financial, or ISO-style compliance.
It must be loaded in shared_preload_libraries.
CREATE EXTENSION pgaudit should be called before pgaudit.log is set for proper DDL object metadata.
The extension installs event triggers for additional DDL auditing.
pgaudit.log classes include READ, WRITE, FUNCTION, ROLE, DDL, MISC, MISC_SET, ALL.
Object audit logging logs statements affecting particular relations and supports SELECT, INSERT, UPDATE, DELETE; TRUNCATE is not included.
pgAudit can generate enormous log volume; performance/latency and log storage must be tested.
Audit entries are written to PostgreSQL's standard logging facility, not to a queryable domain table by default.
```

## 5. pgAudit vs audit.log comparison

| Surface | pgAudit | audit.log |
|---|---|---|
| Primary purpose | Compliance/statement/session/object logging | Durable business/domain/object audit |
| Storage | PostgreSQL server logs | Queryable table in DB |
| Activation | Requires shared_preload_libraries and config | DDL table/functions |
| DDL object metadata | Good with extension installed/event triggers | Only if explicitly recorded by commands/triggers |
| DML statement tracing | Good for statement/object touched | Good only where application/domain writes audit records |
| Row old/new changes | Not designed as row change store | Designed for `changes jsonb` |
| object_public_id | Not native | Native field |
| actor/request/tenant context | Via log prefix/session settings if configured | Native columns/helpers |
| Query from API/PostgREST | Not directly | Yes |
| Volume risk | High if broad READ/WRITE enabled | Controlled by what we record |
| Best use here | Ops/compliance forensic layer | Product/domain audit source of truth |

## 6. Current recommendation

Do not replace `audit.log` with pgAudit.

Use both, with separate responsibilities:

```text
audit.log = durable domain/business/object audit, queryable and API-accessible.
pgaudit = optional operational/compliance trail at PostgreSQL log layer.
```

Next decision should compare pgAudit operating modes:

```text
1. DDL + ROLE only for platform governance.
2. WRITE only for selected roles/databases.
3. Object audit grants for specific sensitive relations.
4. FUNCTION logging for RPC/security-definer command functions.
5. Parameter logging disabled by default unless a redaction policy exists.
```

## 7. What remains before Prop4You DDL

Before starting Prop4You project DDL, do one more deeper scan layer:

```text
1. Scan all Prop4You BaseModel/mixin usages by domain and table.
2. Map each field/helper to base/capability/project-specific.
3. Compare missing base helpers against current 0001-0009.
4. Decide whether new base additions are needed before project packages.
5. Only then start `database/ddl/projects/prop4you/`.
```
