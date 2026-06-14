# Base DDL Package

Reusable database-centric substrate for PG18 databases.

Apply with:

```bash
scripts/apply-ddl-package.sh --package database/ddl/base --apply
```

Files:

- `0001_install_tracking.sql` — creates `base.ddl_migrations` installer tracking.
- `0002_extensions.sql` — enables database-local extensions where possible and records results in `base.extension_install_results`; `pg_cron` is created only when the target DB equals `cron.database_name`.
- `0003_base_schemas_roles_context.sql` — creates `base`, `audit`, `realtime`, `api` schemas and app context helpers.
- `0004_public_id.sql` — creates prefix registry and `<prefix>_<uuid7>` public reference helpers.
- `0005_lifecycle_columns_triggers.sql` — reusable lifecycle trigger helpers.
- `0006_jsonb_contract_helpers.sql` — JSONB shape/size/depth/dangerous-string helpers.
- `0007_search_normalization.sql` — text/email/phone/search-term normalization helpers.
- `0008_audit_log.sql` — durable domain/object audit table and record function.
- `0009_realtime_base.sql` — durable outbox, LISTEN/NOTIFY trigger, ACK table/function.
- `0010_api_base.sql` — minimal `api.*` facade functions.

Extension rule:

Postgres extension binaries/control files are supplied by the image/cluster, but `CREATE EXTENSION` is per database. Therefore this package enables target-database extensions as part of ordered DDL.

`pg_cron` policy for this project: keep `cron.database_name=postgres` as the local/default multi-product scheduler database. Product databases such as `p4y`, lead-capture databases, and labs should not try to install `pg_cron` directly; they record `skipped_by_cron_database_name` in `base.extension_install_results`. Cross-database schedules should be registered from `postgres` with `cron.schedule_in_database(...)`, calling stable functions inside the target database.

Example:

```sql
select cron.schedule_in_database(
  'p4y-outbox-every-minute',
  '* * * * *',
  'select jobs.tick();',
  'p4y'
);
```
