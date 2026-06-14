-- PG18 database-centric base DDL package
-- 0007_audit_log.sql
-- Durable business/domain audit. pgaudit remains complementary server/statement logging, not a replacement.

create schema if not exists audit;

create table if not exists audit.log (
  id uuid primary key default uuidv7(),
  action text not null,
  severity text not null default 'info',
  schema_name name,
  table_name name,
  model_name text,
  object_id text,
  object_public_id text,
  object_repr text,
  actor_id text default base.current_actor_id(),
  actor_role text default base.current_actor_role(),
  tenant_id text default base.current_tenant_id(),
  request_id text default base.current_request_id(),
  ip_address inet,
  user_agent text,
  description text,
  changes jsonb not null default '{}'::jsonb,
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  constraint audit_log_action_chk check (action in (
    'create','update','delete','view','export','import','login','logout','failed_login',
    'password_change','permission_change','api_call','bulk_update','bulk_delete',
    'restore','activate','deactivate','system'
  )),
  constraint audit_log_severity_chk check (severity in ('debug','info','warning','error','critical')),
  constraint audit_log_changes_object_chk check (jsonb_typeof(changes) = 'object'),
  constraint audit_log_metadata_object_chk check (jsonb_typeof(metadata) = 'object')
);

create index if not exists audit_log_object_idx
  on audit.log (schema_name, table_name, object_id);

create index if not exists audit_log_actor_created_idx
  on audit.log (actor_id, created_at desc);

create index if not exists audit_log_action_created_idx
  on audit.log (action, created_at desc);

create index if not exists audit_log_severity_created_idx
  on audit.log (severity, created_at desc);

create index if not exists audit_log_created_idx
  on audit.log (created_at desc);

create index if not exists audit_log_request_idx
  on audit.log (request_id) where request_id is not null;

create or replace function audit.record_log(
  p_action text,
  p_severity text default 'info',
  p_schema_name name default null,
  p_table_name name default null,
  p_object_id text default null,
  p_object_public_id text default null,
  p_object_repr text default null,
  p_description text default null,
  p_changes jsonb default '{}'::jsonb,
  p_metadata jsonb default '{}'::jsonb
)
returns uuid
language plpgsql
volatile
as $$
declare
  new_id uuid;
begin
  insert into audit.log (
    action, severity, schema_name, table_name, model_name, object_id, object_public_id,
    object_repr, description, changes, metadata
  ) values (
    p_action, p_severity, p_schema_name, p_table_name, concat_ws('.', p_schema_name::text, p_table_name::text), p_object_id,
    p_object_public_id, p_object_repr, p_description, coalesce(p_changes, '{}'::jsonb), coalesce(p_metadata, '{}'::jsonb)
  ) returning id into new_id;

  return new_id;
end;
$$;

comment on table audit.log is 'Durable application/domain/object audit log. pgaudit can complement this with server statement/session logging but does not replace row/object business audit storage.';
