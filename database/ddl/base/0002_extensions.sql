-- PG18 database-centric base DDL package
-- 0002_extensions.sql
-- Enables database-local extensions used by the base/platform substrate when possible.
-- Extension binaries/control files are image/cluster capabilities; CREATE EXTENSION is per database.

create schema if not exists base;
create schema if not exists extensions;

create table if not exists base.extension_install_results (
  extension_name text primary key,
  target_schema name,
  required boolean not null default false,
  status text not null,
  message text,
  installed_at timestamptz not null default now(),
  constraint extension_install_results_status_chk check (status in (
    'installed_or_present',
    'skipped_by_cron_database_name',
    'skipped_or_failed'
  ))
);

comment on table base.extension_install_results is 'Per-database CREATE EXTENSION results for the base DDL package. Extensions are installed per database; only image binaries/control files are shared.';

create or replace procedure base.try_create_extension(
  p_extension text,
  p_schema name default null,
  p_required boolean default false
)
language plpgsql
as $$
declare
  sql text;
  cron_db text;
begin
  if p_extension = 'pg_cron' then
    cron_db := nullif(current_setting('cron.database_name', true), '');
    if cron_db is not null and current_database() <> cron_db then
      insert into base.extension_install_results(extension_name, target_schema, required, status, message)
      values (
        p_extension,
        p_schema,
        p_required,
        'skipped_by_cron_database_name',
        format('pg_cron can only be created in cron.database_name=%s; current_database=%s', cron_db, current_database())
      )
      on conflict (extension_name) do update
        set target_schema = excluded.target_schema,
            required = excluded.required,
            status = excluded.status,
            message = excluded.message,
            installed_at = now();
      return;
    end if;
  end if;

  if p_schema is not null then
    execute format('create schema if not exists %I', p_schema);
    sql := format('create extension if not exists %I with schema %I', p_extension, p_schema);
  else
    sql := format('create extension if not exists %I', p_extension);
  end if;

  begin
    execute sql;
    insert into base.extension_install_results(extension_name, target_schema, required, status, message)
    values (p_extension, p_schema, p_required, 'installed_or_present', null)
    on conflict (extension_name) do update
      set target_schema = excluded.target_schema,
          required = excluded.required,
          status = excluded.status,
          message = excluded.message,
          installed_at = now();
  exception when others then
    insert into base.extension_install_results(extension_name, target_schema, required, status, message)
    values (p_extension, p_schema, p_required, 'skipped_or_failed', sqlstate || ': ' || sqlerrm)
    on conflict (extension_name) do update
      set target_schema = excluded.target_schema,
          required = excluded.required,
          status = excluded.status,
          message = excluded.message,
          installed_at = now();

    if p_required then
      raise;
    end if;
  end;
end;
$$;

-- Required by this base substrate / core platform primitives.
call base.try_create_extension('pgcrypto', 'extensions', true);
call base.try_create_extension('pg_stat_statements', 'extensions', false);
call base.try_create_extension('uuid-ossp', 'extensions', false);

-- Scheduling: pg_cron is database-bound by cron.database_name. It is guaranteed only in that database.
call base.try_create_extension('pg_cron', 'public', false);

-- Supabase/Postgres image capability surface useful for database-centric backends.
call base.try_create_extension('http', 'public', false);
call base.try_create_extension('hypopg', 'public', false);
call base.try_create_extension('index_advisor', 'public', false);
call base.try_create_extension('pg_graphql', 'graphql', false);
call base.try_create_extension('pg_hashids', 'public', false);
call base.try_create_extension('pg_jsonschema', 'public', false);
call base.try_create_extension('pg_net', 'public', false);
call base.try_create_extension('pg_partman', 'public', false);
call base.try_create_extension('pg_repack', 'public', false);
call base.try_create_extension('pg_stat_monitor', 'public', false);
call base.try_create_extension('pg_tle', 'pgtle', false);
call base.try_create_extension('pgaudit', 'public', false);
call base.try_create_extension('pgjwt', 'public', false);
call base.try_create_extension('pgmq', 'pgmq', false);
call base.try_create_extension('pgroonga', 'public', false);
call base.try_create_extension('pgroonga_database', 'public', false);
call base.try_create_extension('pgsodium', 'pgsodium', false);
call base.try_create_extension('pgtap', 'public', false);
call base.try_create_extension('plpgsql_check', 'public', false);
call base.try_create_extension('postgis', 'public', false);
call base.try_create_extension('pgrouting', 'public', false);
call base.try_create_extension('rum', 'public', false);
call base.try_create_extension('supabase_vault', 'vault', false);
call base.try_create_extension('vector', 'public', false);
call base.try_create_extension('wal2json', 'public', false);
call base.try_create_extension('wrappers', 'public', false);

comment on procedure base.try_create_extension(text, name, boolean) is 'Best-effort per-database extension installer used by base DDL. Required extensions re-raise failures; pg_cron respects cron.database_name.';
