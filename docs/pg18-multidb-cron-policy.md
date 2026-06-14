# PG18 Multi-Database pg_cron Policy

Status: ACTIVE
Date: 2026-06-14

## Decision

Keep `cron.database_name=postgres` as the project-local/default scheduler database for the PG18 stack.

This is the default for the multi-product/multi-database strategy: one operational `postgres` database owns `pg_cron`, while product databases such as `p4y`, lead-capture databases, labs, or future products expose stable functions that the central scheduler calls.

## Why

Postgres extensions are not globally enabled per cluster. The image/cluster supplies binaries, control files, and preload libraries, but `CREATE EXTENSION` is per database.

`pg_cron` is special because the background worker is bound by `cron.database_name`. In this stack runtime truth is:

```text
cron.database_name=postgres
```

Therefore `CREATE EXTENSION pg_cron` is valid in database `postgres` and rejected in another target database such as `pg18_ddl_lab` or future `p4y`.

## Pattern

1. Install/keep `pg_cron` in database `postgres`.
2. Apply `database/ddl/base` to each product/lab database.
3. Product/lab databases record `pg_cron` as `skipped_by_cron_database_name` in `base.extension_install_results`.
4. Create job functions in the target product database, for example:

```sql
create schema if not exists jobs;

create or replace function jobs.tick()
returns void
language plpgsql
as $$
begin
  -- call product-owned maintenance/outbox/queue functions here
end;
$$;
```

5. Register schedules from database `postgres` using `cron.schedule_in_database(...)`:

```sql
select cron.schedule_in_database(
  'p4y-jobs-tick',
  '* * * * *',
  'select jobs.tick();',
  'p4y'
);
```

## Operational notes

- Product databases should not require direct `CREATE EXTENSION pg_cron`.
- The central scheduler can target multiple databases.
- Jobs should call stable functions in target databases rather than embedding large SQL bodies in cron definitions.
- Target database functions own domain permissions, idempotence, observability, and audit behavior.
- Changing `cron.database_name` to a product DB is reserved for a single-product deployment, not the default local/multi-product posture.

## Current proof

`docs/reports/pg18-ddl-base-lab-proof.md` proves the expected behavior in `pg18_ddl_lab`:

```text
pg_cron -> skipped_by_cron_database_name
extensions_installed=30
extension_results=30
ddl_migrations=10
```
