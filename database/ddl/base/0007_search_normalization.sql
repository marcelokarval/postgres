-- PG18 database-centric base DDL package
-- 0007_search_normalization.sql
-- Framework-agnostic text/email/phone/search normalization helpers.

create schema if not exists base;

create or replace function base.clean_text(value text)
returns text
language sql
immutable
as $$
  select nullif(regexp_replace(btrim(coalesce(value, '')), '\s+', ' ', 'g'), '')
$$;

create or replace function base.normalize_email(value text)
returns text
language sql
immutable
as $$
  select lower(base.clean_text(value))
$$;

create or replace function base.normalize_phone(value text)
returns text
language plpgsql
immutable
as $$
declare
  digits text;
begin
  digits := regexp_replace(coalesce(value, ''), '[^0-9]+', '', 'g');
  if digits = '' then
    return null;
  end if;

  -- E.164-ish normalization for common US 10/11 digit input; otherwise return +<digits>.
  if length(digits) = 10 then
    return '+1' || digits;
  elsif length(digits) = 11 and left(digits, 1) = '1' then
    return '+' || digits;
  else
    return '+' || digits;
  end if;
end;
$$;

create or replace function base.normalize_search_terms(variadic input_values text[])
returns text[]
language sql
immutable
as $$
  with raw as (
    select unnest(coalesce(input_values, array[]::text[])) as value
  ), tokens as (
    select regexp_split_to_table(lower(coalesce(value, '')), '[^[:alnum:]]+') as token
      from raw
  ), cleaned as (
    select distinct token
      from tokens
     where length(token) >= 2
  )
  select coalesce(array_agg(token order by token), array[]::text[])
    from cleaned
$$;

create or replace function base.normalize_search_text(value text)
returns text[]
language sql
immutable
as $$
  select base.normalize_search_terms(value)
$$;

comment on function base.clean_text(text) is 'Trim and collapse whitespace; returns null for blank input.';
comment on function base.normalize_search_terms(text[]) is 'Lowercase tokenization/deduplication for search_terms text[] GIN conventions. Domain DDL may add tsvector, unaccent, PGroonga or RUM indexes based on query profile.';
