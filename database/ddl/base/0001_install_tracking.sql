-- PG18 database-centric base DDL package
-- 0001_install_tracking.sql
-- Creates installer tracking in base.ddl_migrations.

create schema if not exists base;

create table if not exists base.ddl_migrations (
  id uuid primary key default uuidv7(),
  package_name text not null,
  filename text not null,
  checksum text not null,
  applied_at timestamptz not null default now(),
  applied_by text not null default current_user,
  execution_ms integer,
  status text not null check (status in ('applied','failed','skipped')),
  error_message text,
  metadata jsonb not null default '{}'::jsonb,
  constraint ddl_migrations_package_filename_key unique (package_name, filename),
  constraint ddl_migrations_checksum_sha256_chk check (checksum ~ '^[0-9a-f]{64}$'),
  constraint ddl_migrations_execution_ms_chk check (execution_ms is null or execution_ms >= 0),
  constraint ddl_migrations_metadata_object_chk check (jsonb_typeof(metadata) = 'object')
);

create index if not exists ddl_migrations_package_status_idx
  on base.ddl_migrations (package_name, status, filename);

create index if not exists ddl_migrations_applied_at_idx
  on base.ddl_migrations (applied_at desc);

comment on schema base is 'Reusable database-centric base primitives and installer tracking.';
comment on table base.ddl_migrations is 'Idempotent DDL package installer tracking. Package+filename checksum drift is a hard installer error.';
comment on column base.ddl_migrations.id is 'PG18 uuidv7 migration row identifier.';
