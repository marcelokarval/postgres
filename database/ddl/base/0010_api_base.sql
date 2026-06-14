-- PG18 database-centric base DDL package
-- 0010_api_base.sql
-- Minimal API facade proof surface.

create schema if not exists api;

create or replace function api.health()
returns jsonb
language sql
stable
as $$
  select jsonb_build_object(
    'ok', true,
    'database', current_database(),
    'server_version', current_setting('server_version'),
    'checked_at', now()
  )
$$;

create or replace function api.current_context()
returns jsonb
language sql
stable
as $$
  select jsonb_build_object(
    'actor_id', base.current_actor_id(),
    'tenant_id', base.current_tenant_id(),
    'request_id', base.current_request_id(),
    'actor_role', base.current_actor_role(),
    'database_user', current_user
  )
$$;

create or replace function api.ddl_status(p_package_name text default null)
returns table(
  package_name text,
  filename text,
  checksum text,
  status text,
  applied_at timestamptz,
  applied_by text,
  execution_ms integer,
  error_message text
)
language sql
stable
as $$
  select m.package_name,
         m.filename,
         m.checksum,
         m.status,
         m.applied_at,
         m.applied_by,
         m.execution_ms,
         m.error_message
    from base.ddl_migrations m
   where p_package_name is null
      or m.package_name = p_package_name
   order by m.package_name, m.filename
$$;

comment on function api.health() is 'Minimal API facade health proof for PostgREST/client access.';
comment on function api.current_context() is 'Returns transaction-local app.* request context visible to database-centric authorization/audit code.';
comment on function api.ddl_status(text) is 'Client-facing DDL installer status facade over base.ddl_migrations.';
