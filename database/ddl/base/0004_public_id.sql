-- PG18 database-centric base DDL package
-- 0004_public_id.sql
-- Canonical public reference: <prefix>_<uuid7>, where uuid7 is the object's real primary key.

create schema if not exists base;

create table if not exists base.public_id_prefix_registry (
  prefix text primary key,
  schema_name name not null,
  table_name name not null,
  entity_name text not null,
  id_column name not null default 'id',
  active boolean not null default true,
  created_at timestamptz not null default now(),
  metadata jsonb not null default '{}'::jsonb,
  constraint public_id_prefix_format_chk check (prefix ~ '^[a-z][a-z0-9]{1,31}$'),
  constraint public_id_entity_name_chk check (length(btrim(entity_name)) > 0),
  constraint public_id_metadata_object_chk check (jsonb_typeof(metadata) = 'object')
);

comment on table base.public_id_prefix_registry is 'Maps public reference prefixes to target schema/table/id semantics. Canonical public ref is <prefix>_<uuid7>.';
comment on column base.public_id_prefix_registry.prefix is 'Lowercase alphanumeric prefix without underscore so <prefix>_<uuid> parses deterministically.';

create or replace function base.make_public_ref(prefix text, object_id uuid)
returns text
language sql
immutable
strict
as $$
  select lower(prefix) || '_' || object_id::text
$$;

create or replace function base.parse_public_ref(public_ref text)
returns table(prefix text, object_id uuid)
language plpgsql
immutable
strict
as $$
declare
  sep integer;
  raw_prefix text;
  raw_uuid text;
begin
  sep := strpos(public_ref, '_');
  if sep <= 1 then
    raise exception 'invalid public_ref %, expected <prefix>_<uuid>', public_ref using errcode = '22023';
  end if;

  raw_prefix := substr(public_ref, 1, sep - 1);
  raw_uuid := substr(public_ref, sep + 1);

  if raw_prefix !~ '^[a-z][a-z0-9]{1,31}$' then
    raise exception 'invalid public_ref prefix %', raw_prefix using errcode = '22023';
  end if;

  prefix := raw_prefix;
  object_id := raw_uuid::uuid;
  return next;
end;
$$;

create or replace function base.resolve_public_ref(public_ref text)
returns table(
  prefix text,
  schema_name name,
  table_name name,
  id_column name,
  entity_name text,
  object_id uuid,
  active boolean,
  metadata jsonb
)
language sql
stable
strict
as $$
  select r.prefix,
         r.schema_name,
         r.table_name,
         r.id_column,
         r.entity_name,
         p.object_id,
         r.active,
         r.metadata
    from base.parse_public_ref(public_ref) p
    join base.public_id_prefix_registry r
      on r.prefix = p.prefix
$$;

create or replace function base.register_public_id_prefix(
  p_prefix text,
  p_schema_name name,
  p_table_name name,
  p_entity_name text,
  p_id_column name default 'id',
  p_active boolean default true,
  p_metadata jsonb default '{}'::jsonb
)
returns base.public_id_prefix_registry
language plpgsql
volatile
as $$
declare
  row_out base.public_id_prefix_registry;
begin
  insert into base.public_id_prefix_registry as r
    (prefix, schema_name, table_name, entity_name, id_column, active, metadata)
  values
    (lower(p_prefix), p_schema_name, p_table_name, p_entity_name, p_id_column, p_active, coalesce(p_metadata, '{}'::jsonb))
  on conflict (prefix) do update
    set schema_name = excluded.schema_name,
        table_name = excluded.table_name,
        entity_name = excluded.entity_name,
        id_column = excluded.id_column,
        active = excluded.active,
        metadata = excluded.metadata
  returning * into row_out;

  return row_out;
end;
$$;

comment on function base.make_public_ref(text, uuid) is 'Renders canonical public reference <prefix>_<uuid>; UUID is not hashed, compressed, encrypted, or replaced.';
comment on function base.resolve_public_ref(text) is 'Resolves prefix registry metadata and object UUID pointer for a canonical public reference.';
