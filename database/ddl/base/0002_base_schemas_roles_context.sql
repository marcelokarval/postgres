-- PG18 database-centric base DDL package
-- 0002_base_schemas_roles_context.sql
-- Creates framework-agnostic schemas and request context helpers.

create schema if not exists base;
create schema if not exists audit;
create schema if not exists realtime;
create schema if not exists api;

comment on schema audit is 'Durable business/domain audit records. Complements server/statement audit extensions such as pgaudit.';
comment on schema realtime is 'Reusable outbox and realtime bridge primitives.';
comment on schema api is 'Stable facade schema for PostgREST/client-facing RPCs and read projections.';

create or replace function base.current_actor_id()
returns text
language sql
stable
as $$
  select nullif(current_setting('app.actor_id', true), '')
$$;

create or replace function base.current_tenant_id()
returns text
language sql
stable
as $$
  select nullif(current_setting('app.tenant_id', true), '')
$$;

create or replace function base.current_request_id()
returns text
language sql
stable
as $$
  select nullif(current_setting('app.request_id', true), '')
$$;

create or replace function base.current_actor_role()
returns text
language sql
stable
as $$
  select coalesce(nullif(current_setting('app.actor_role', true), ''), current_user)
$$;

create or replace function base.set_local_context(
  actor_id text default null,
  tenant_id text default null,
  request_id text default null,
  actor_role text default null
)
returns jsonb
language plpgsql
volatile
as $$
begin
  if actor_id is not null then
    perform set_config('app.actor_id', actor_id, true);
  end if;
  if tenant_id is not null then
    perform set_config('app.tenant_id', tenant_id, true);
  end if;
  if request_id is not null then
    perform set_config('app.request_id', request_id, true);
  end if;
  if actor_role is not null then
    perform set_config('app.actor_role', actor_role, true);
  end if;

  return jsonb_build_object(
    'actor_id', base.current_actor_id(),
    'tenant_id', base.current_tenant_id(),
    'request_id', base.current_request_id(),
    'actor_role', base.current_actor_role()
  );
end;
$$;

comment on function base.set_local_context(text,text,text,text) is 'Sets transaction-local app.* request context for RLS, triggers, audit and API facade functions.';
