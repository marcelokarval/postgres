# Base DDL package

Status: ACTIVE_BASE_DDL_SLICE

This package contains reusable, framework-agnostic database-centric primitives for the PG18 Application Data Kernel. It is installed after the PG18 runtime is running; it is not baked into the reusable image build and does not remove or narrow extension surfaces.

## Implemented files

```text
0001_install_tracking.sql
  Creates base.ddl_migrations installer tracking and pgcrypto extension guard.

0002_base_schemas_roles_context.sql
  Creates base, audit, realtime and api schemas plus transaction-local context helpers.

0003_public_id.sql
  Creates base.public_id_prefix_registry and public reference functions.

0004_lifecycle_columns_triggers.sql
  Creates lifecycle trigger helpers for timestamp, activation, soft-delete and version conventions.

0005_jsonb_contract_helpers.sql
  Creates JSONB object/size/depth/dangerous-string safety helpers.

0006_search_normalization.sql
  Creates clean text, normalized email, normalized phone and search term helpers.

0007_audit_log.sql
  Creates durable audit.log and audit.record_log(). pgaudit is complementary statement/session logging, not a replacement for this table.

0008_realtime_base.sql
  Creates realtime.event_outbox, realtime.event_acks, LISTEN/NOTIFY trigger and ack helper.

0009_api_base.sql
  Creates api.health(), api.current_context() and api.ddl_status().
```

## Public ID rule

Canonical public references use prefix registry + uuid7 pointer semantics:

```text
<prefix>_<uuid7>
```

Rules:

- `prefix` is registered in `base.public_id_prefix_registry`.
- Registry rows map `prefix -> schema_name, table_name, id_column, entity_name`.
- The UUID suffix is the object's real primary key value, normally from `id uuid primary key default uuidv7()`.
- The UUID is not hashed, compressed, encrypted, randomized into a legacy 24-character suffix, or otherwise destroyed.
- Lookup path is: parse prefix, resolve registry metadata, use UUID to find the target object row in the registered table.

The old Django-era random 24-character public ID suffix is not canonical for this PG18 database-centric DDL line.

## Installer

Use the deterministic package installer from the repository root:

```bash
scripts/apply-ddl-package.sh --package database/ddl/base --dry-run
scripts/apply-ddl-package.sh --package database/ddl/base --status
scripts/apply-ddl-package.sh --package database/ddl/base --apply
```

Connection behavior:

- Use `--database-url <url>` when an explicit connection URL is required.
- Otherwise `psql` uses `DATABASE_URL` and/or `PG*` environment variables.
- The installer must not print full database URLs or credentials.
