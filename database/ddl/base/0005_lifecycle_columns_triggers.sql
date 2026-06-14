-- PG18 database-centric base DDL package
-- 0005_lifecycle_columns_triggers.sql
-- Reusable trigger helpers for tables using the documented lifecycle column convention.

create schema if not exists base;

create or replace function base.touch_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at := now();
  new.last_modified_by_actor_id := coalesce(new.last_modified_by_actor_id, base.current_actor_id());
  return new;
end;
$$;

create or replace function base.increment_version()
returns trigger
language plpgsql
as $$
begin
  new.version := coalesce(old.version, 0) + 1;
  return new;
end;
$$;

create or replace function base.set_lifecycle_defaults()
returns trigger
language plpgsql
as $$
begin
  new.created_at := coalesce(new.created_at, now());
  new.updated_at := coalesce(new.updated_at, new.created_at, now());
  new.active := coalesce(new.active, true);
  new.deleted := coalesce(new.deleted, false);
  new.version := coalesce(new.version, 1);

  if new.active and new.activated_at is null then
    new.activated_at := new.created_at;
  end if;

  if new.deleted and new.deleted_at is null then
    new.deleted_at := now();
  end if;

  new.last_modified_by_actor_id := coalesce(new.last_modified_by_actor_id, base.current_actor_id());
  return new;
end;
$$;

create or replace function base.mark_deleted(
  deleted_at timestamptz default now(),
  deleted_by_actor_id text default base.current_actor_id()
)
returns jsonb
language sql
stable
as $$
  select jsonb_build_object(
    'deleted', true,
    'deleted_at', deleted_at,
    'deleted_by_actor_id', deleted_by_actor_id,
    'active', false
  )
$$;

create or replace function base.mark_restored()
returns jsonb
language sql
stable
as $$
  select jsonb_build_object(
    'deleted', false,
    'deleted_at', null,
    'deleted_by_actor_id', null,
    'active', true,
    'activated_at', now(),
    'deactivated_at', null
  )
$$;

comment on function base.touch_updated_at() is 'BEFORE UPDATE trigger helper for tables with updated_at and last_modified_by_actor_id columns.';
comment on function base.increment_version() is 'BEFORE UPDATE trigger helper for tables with integer version column. Domain command functions may manage versioning explicitly when needed.';
comment on function base.set_lifecycle_defaults() is 'BEFORE INSERT trigger helper for documented lifecycle columns: created_at, updated_at, active, activated_at, deleted, deleted_at, version, last_modified_by_actor_id.';
