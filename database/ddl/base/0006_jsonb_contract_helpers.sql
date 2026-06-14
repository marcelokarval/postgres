-- PG18 database-centric base DDL package
-- 0006_jsonb_contract_helpers.sql
-- Coarse JSONB safety helpers for payload/data/metadata conventions.

create schema if not exists base;

create or replace function base.jsonb_is_object(value jsonb)
returns boolean
language sql
immutable
as $$
  select value is not null and jsonb_typeof(value) = 'object'
$$;

create or replace function base.jsonb_size_ok(value jsonb, max_bytes integer default 65536)
returns boolean
language sql
immutable
as $$
  select value is null or octet_length(value::text) <= greatest(max_bytes, 0)
$$;

create or replace function base.jsonb_has_dangerous_string(value jsonb)
returns boolean
language plpgsql
immutable
as $$
declare
  elem jsonb;
  txt text;
begin
  if value is null then
    return false;
  end if;

  case jsonb_typeof(value)
    when 'string' then
      txt := lower(value #>> '{}');
      return txt ~ '(<\s*script|javascript\s*:|data\s*:\s*text/html|on[a-z0-9_:-]+\s*=)';
    when 'array' then
      for elem in select jsonb_array_elements(value) loop
        if base.jsonb_has_dangerous_string(elem) then
          return true;
        end if;
      end loop;
      return false;
    when 'object' then
      for elem in select v from jsonb_each(value) as e(k, v) loop
        if base.jsonb_has_dangerous_string(elem) then
          return true;
        end if;
      end loop;
      return false;
    else
      return false;
  end case;
end;
$$;

create or replace function base.jsonb_max_depth(value jsonb)
returns integer
language plpgsql
immutable
as $$
declare
  elem jsonb;
  child_depth integer;
  max_child integer := 0;
begin
  if value is null then
    return 0;
  end if;

  if jsonb_typeof(value) not in ('array', 'object') then
    return 1;
  end if;

  if jsonb_typeof(value) = 'array' then
    for elem in select jsonb_array_elements(value) loop
      child_depth := base.jsonb_max_depth(elem);
      max_child := greatest(max_child, child_depth);
    end loop;
  else
    for elem in select v from jsonb_each(value) as e(k, v) loop
      child_depth := base.jsonb_max_depth(elem);
      max_child := greatest(max_child, child_depth);
    end loop;
  end if;

  return 1 + max_child;
end;
$$;

create or replace function base.jsonb_is_safe(value jsonb)
returns boolean
language sql
immutable
as $$
  select value is not null
     and base.jsonb_size_ok(value, 65536)
     and base.jsonb_max_depth(value) <= 10
     and not base.jsonb_has_dangerous_string(value)
$$;

comment on function base.jsonb_is_safe(jsonb) is 'Coarse JSONB contract guard: non-null, <=64KiB serialized, depth <=10, and no obvious dangerous HTML/JS strings. Domain DDL may add pg_jsonschema checks.';
