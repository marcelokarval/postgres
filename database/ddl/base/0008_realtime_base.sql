-- PG18 database-centric base DDL package
-- 0008_realtime_base.sql
-- Durable outbox and lightweight LISTEN/NOTIFY bridge primitives.

create schema if not exists realtime;

create table if not exists realtime.event_outbox (
  id uuid primary key default uuidv7(),
  topic text not null,
  event_type text not null,
  aggregate_schema name,
  aggregate_table name,
  aggregate_id uuid,
  public_ref text,
  tenant_id text default base.current_tenant_id(),
  actor_id text default base.current_actor_id(),
  request_id text default base.current_request_id(),
  payload jsonb not null default '{}'::jsonb,
  metadata jsonb not null default '{}'::jsonb,
  available_at timestamptz not null default now(),
  delivered_at timestamptz,
  created_at timestamptz not null default now(),
  constraint event_outbox_topic_chk check (topic ~ '^[a-z][a-z0-9_]*(\.[a-z][a-z0-9_]*){1,}$'),
  constraint event_outbox_payload_object_chk check (jsonb_typeof(payload) = 'object'),
  constraint event_outbox_metadata_object_chk check (jsonb_typeof(metadata) = 'object')
);

create index if not exists event_outbox_topic_created_idx
  on realtime.event_outbox (topic, created_at desc);

create index if not exists event_outbox_available_idx
  on realtime.event_outbox (available_at, id) where delivered_at is null;

create index if not exists event_outbox_aggregate_idx
  on realtime.event_outbox (aggregate_schema, aggregate_table, aggregate_id);

create table if not exists realtime.event_acks (
  id uuid primary key default uuidv7(),
  event_id uuid not null references realtime.event_outbox(id) on delete cascade,
  consumer text not null,
  acked_at timestamptz not null default now(),
  metadata jsonb not null default '{}'::jsonb,
  constraint event_acks_consumer_chk check (length(btrim(consumer)) > 0),
  constraint event_acks_metadata_object_chk check (jsonb_typeof(metadata) = 'object'),
  constraint event_acks_event_consumer_key unique (event_id, consumer)
);

create or replace function realtime.notify_event_outbox()
returns trigger
language plpgsql
as $$
declare
  msg text;
begin
  msg := jsonb_build_object(
    'id', new.id,
    'topic', new.topic,
    'event_type', new.event_type,
    'aggregate_schema', new.aggregate_schema,
    'aggregate_table', new.aggregate_table,
    'aggregate_id', new.aggregate_id,
    'public_ref', new.public_ref,
    'created_at', new.created_at
  )::text;

  perform pg_notify('realtime_event_outbox', msg);
  return new;
end;
$$;

drop trigger if exists event_outbox_notify_after_insert on realtime.event_outbox;
create trigger event_outbox_notify_after_insert
after insert on realtime.event_outbox
for each row execute function realtime.notify_event_outbox();

create or replace function realtime.ack_event(p_event_id uuid, p_consumer text, p_metadata jsonb default '{}'::jsonb)
returns uuid
language plpgsql
volatile
as $$
declare
  ack_id uuid;
begin
  insert into realtime.event_acks (event_id, consumer, metadata)
  values (p_event_id, p_consumer, coalesce(p_metadata, '{}'::jsonb))
  on conflict (event_id, consumer) do update
    set acked_at = now(), metadata = excluded.metadata
  returning id into ack_id;

  return ack_id;
end;
$$;

comment on table realtime.event_outbox is 'Reusable durable realtime/event outbox. Transport workers may LISTEN on realtime_event_outbox and/or poll undelivered rows.';
