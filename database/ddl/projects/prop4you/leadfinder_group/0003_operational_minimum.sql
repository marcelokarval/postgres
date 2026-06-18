-- package: prop4you/leadfinder_group
-- file: 0003_operational_minimum.sql
-- status: experimental / non-final
-- purpose: T5.2 minimal operational LFG groups/events/facets from accepted materialization results.
-- depends-on: leadfinder_group/0002_materialization_runs.sql
-- idempotency: idempotent
-- destructive: false
-- [GATEWAY_AGNOSTIC] Callable by direct SQL, ORM, PostgREST RPC, Django/FastAPI passthrough, workers, or any other transport.
-- [MINIMAL_OPERATIONAL] Three-table operational minimum only: groups, events, facets.
-- [NO_TABLE_EXPLOSION] Does not create final property/owner/address/contact/scoring/list/detail table graph.
-- [NO_PROVIDER_CALLS] No HTTP/provider calls, no corpus reads, no secrets.
-- [NO_RAW_PAYLOAD_DUMP] Operational rows carry lineage/hashes, not raw provider payload dumps.

create schema if not exists prop4you_leadfinder_group;

create table if not exists prop4you_leadfinder_group.operational_groups (
  id uuid primary key default uuidv7(),
  public_ref text generated always as (base.make_public_ref('p4ylfgg', id)) stored,
  materialization_result_id uuid not null references prop4you_leadfinder_group.materialization_results(id) on delete restrict,
  materialization_run_id uuid not null references prop4you_leadfinder_group.materialization_runs(id) on delete restrict,
  group_key text not null,
  group_status text not null default 'candidate',
  review_status text not null default 'unreviewed',
  group_schema_version text not null default 'leadfinder_group.operational_group.v0',
  summary jsonb not null default '{}'::jsonb,
  lineage jsonb not null default '{}'::jsonb,
  metadata jsonb not null default '{}'::jsonb,
  materialized_at timestamptz not null default now(),
  materialized_by_actor_id text,
  active boolean not null default true,
  activated_at timestamptz,
  deactivated_at timestamptz,
  deleted boolean not null default false,
  deleted_at timestamptz,
  deleted_by_actor_id text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  last_modified_by_actor_id text,
  version integer not null default 1,
  constraint operational_groups_public_ref_key unique (public_ref),
  constraint operational_groups_result_key unique (materialization_result_id),
  constraint operational_groups_group_key_key unique (group_key),
  constraint operational_groups_group_key_format_chk check (group_key ~ '^[a-z][a-z0-9_.:-]{1,191}$'),
  constraint operational_groups_status_chk check (group_status in ('candidate','active_review','accepted_operational','blocked','rejected','superseded','archived')),
  constraint operational_groups_review_chk check (review_status in ('unreviewed','in_review','accepted','rejected','blocked','not_applicable')),
  constraint operational_groups_schema_version_chk check (group_schema_version ~ '^[a-z][a-z0-9_.:-]{1,79}$'),
  constraint operational_groups_json_chk check (jsonb_typeof(summary)='object' and jsonb_typeof(lineage)='object' and jsonb_typeof(metadata)='object'),
  constraint operational_groups_version_positive_chk check (version > 0)
);

create table if not exists prop4you_leadfinder_group.operational_group_events (
  id uuid primary key default uuidv7(),
  public_ref text generated always as (base.make_public_ref('p4ylfge', id)) stored,
  group_id uuid not null references prop4you_leadfinder_group.operational_groups(id) on delete restrict,
  materialization_result_id uuid references prop4you_leadfinder_group.materialization_results(id) on delete restrict,
  event_type text not null,
  event_status text not null default 'recorded',
  event_payload jsonb not null default '{}'::jsonb,
  lineage jsonb not null default '{}'::jsonb,
  occurred_at timestamptz not null default now(),
  active boolean not null default true,
  activated_at timestamptz,
  deactivated_at timestamptz,
  deleted boolean not null default false,
  deleted_at timestamptz,
  deleted_by_actor_id text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  last_modified_by_actor_id text,
  version integer not null default 1,
  constraint operational_group_events_public_ref_key unique (public_ref),
  constraint operational_group_events_type_chk check (event_type in ('group_materialized','facet_asserted','facet_changed','review_status_changed','group_superseded','materialization_blocked','unknown')),
  constraint operational_group_events_status_chk check (event_status in ('recorded','superseded','voided','archived')),
  constraint operational_group_events_json_chk check (jsonb_typeof(event_payload)='object' and jsonb_typeof(lineage)='object'),
  constraint operational_group_events_version_positive_chk check (version > 0)
);

create table if not exists prop4you_leadfinder_group.operational_group_facets (
  id uuid primary key default uuidv7(),
  public_ref text generated always as (base.make_public_ref('p4ylfgf', id)) stored,
  group_id uuid not null references prop4you_leadfinder_group.operational_groups(id) on delete restrict,
  created_by_event_id uuid references prop4you_leadfinder_group.operational_group_events(id) on delete set null,
  facet_key text not null,
  facet_kind text not null default 'sourcehub_dto_publication',
  facet_status text not null default 'asserted',
  facet_value jsonb not null default '{}'::jsonb,
  confidence numeric(5,4) not null default 1.0,
  lineage jsonb not null default '{}'::jsonb,
  asserted_at timestamptz not null default now(),
  active boolean not null default true,
  activated_at timestamptz,
  deactivated_at timestamptz,
  deleted boolean not null default false,
  deleted_at timestamptz,
  deleted_by_actor_id text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  last_modified_by_actor_id text,
  version integer not null default 1,
  constraint operational_group_facets_public_ref_key unique (public_ref),
  constraint operational_group_facets_group_key_unique unique (group_id, facet_key),
  constraint operational_group_facets_key_format_chk check (facet_key ~ '^[a-z][a-z0-9_.:-]{1,191}$'),
  constraint operational_group_facets_kind_chk check (facet_kind in ('sourcehub_dto_publication','provider_class','dictionary_version','matrix_artifact','materialization_quality','translated_field_count','unknown')),
  constraint operational_group_facets_status_chk check (facet_status in ('asserted','changed','blocked','rejected','superseded','archived')),
  constraint operational_group_facets_confidence_chk check (confidence >= 0 and confidence <= 1),
  constraint operational_group_facets_json_chk check (jsonb_typeof(facet_value) in ('object','array','string','number','boolean','null') and jsonb_typeof(lineage)='object'),
  constraint operational_group_facets_version_positive_chk check (version > 0)
);

create index if not exists operational_groups_status_idx on prop4you_leadfinder_group.operational_groups (group_status, review_status, created_at desc) where deleted=false;
create index if not exists operational_group_events_group_idx on prop4you_leadfinder_group.operational_group_events (group_id, occurred_at desc) where deleted=false;
create index if not exists operational_group_facets_group_idx on prop4you_leadfinder_group.operational_group_facets (group_id, facet_kind, facet_key) where deleted=false;
create index if not exists operational_group_facets_lineage_gin_idx on prop4you_leadfinder_group.operational_group_facets using gin (lineage jsonb_path_ops);

comment on table prop4you_leadfinder_group.operational_groups is 'T5.2 minimal operational group envelope created from accepted materialization results. Not the final full LFG product graph.';
comment on table prop4you_leadfinder_group.operational_group_events is 'Minimal append-style events for operational LFG groups.';
comment on table prop4you_leadfinder_group.operational_group_facets is 'Minimal reviewable facets for LFG groups, intentionally avoiding premature property/owner/contact table explosion.';

drop trigger if exists operational_groups_set_lifecycle_defaults on prop4you_leadfinder_group.operational_groups;
create trigger operational_groups_set_lifecycle_defaults before insert on prop4you_leadfinder_group.operational_groups for each row execute function base.set_lifecycle_defaults();
drop trigger if exists operational_groups_touch_updated_at on prop4you_leadfinder_group.operational_groups;
create trigger operational_groups_touch_updated_at before update on prop4you_leadfinder_group.operational_groups for each row execute function base.touch_updated_at();
drop trigger if exists operational_groups_increment_version on prop4you_leadfinder_group.operational_groups;
create trigger operational_groups_increment_version before update on prop4you_leadfinder_group.operational_groups for each row execute function base.increment_version();

drop trigger if exists operational_group_events_set_lifecycle_defaults on prop4you_leadfinder_group.operational_group_events;
create trigger operational_group_events_set_lifecycle_defaults before insert on prop4you_leadfinder_group.operational_group_events for each row execute function base.set_lifecycle_defaults();
drop trigger if exists operational_group_events_touch_updated_at on prop4you_leadfinder_group.operational_group_events;
create trigger operational_group_events_touch_updated_at before update on prop4you_leadfinder_group.operational_group_events for each row execute function base.touch_updated_at();
drop trigger if exists operational_group_events_increment_version on prop4you_leadfinder_group.operational_group_events;
create trigger operational_group_events_increment_version before update on prop4you_leadfinder_group.operational_group_events for each row execute function base.increment_version();

drop trigger if exists operational_group_facets_set_lifecycle_defaults on prop4you_leadfinder_group.operational_group_facets;
create trigger operational_group_facets_set_lifecycle_defaults before insert on prop4you_leadfinder_group.operational_group_facets for each row execute function base.set_lifecycle_defaults();
drop trigger if exists operational_group_facets_touch_updated_at on prop4you_leadfinder_group.operational_group_facets;
create trigger operational_group_facets_touch_updated_at before update on prop4you_leadfinder_group.operational_group_facets for each row execute function base.touch_updated_at();
drop trigger if exists operational_group_facets_increment_version on prop4you_leadfinder_group.operational_group_facets;
create trigger operational_group_facets_increment_version before update on prop4you_leadfinder_group.operational_group_facets for each row execute function base.increment_version();

create or replace view prop4you_leadfinder_group.v_operational_group_review as
select g.id,
       g.public_ref,
       g.group_key,
       g.group_status,
       g.review_status,
       g.materialization_run_id,
       g.materialization_result_id,
       count(distinct e.id) as event_count,
       count(distinct f.id) as facet_count,
       g.summary,
       g.lineage,
       g.created_at,
       g.updated_at
  from prop4you_leadfinder_group.operational_groups g
  left join prop4you_leadfinder_group.operational_group_events e on e.group_id=g.id and e.deleted=false
  left join prop4you_leadfinder_group.operational_group_facets f on f.group_id=g.id and f.deleted=false
 where g.deleted=false
 group by g.id;

create or replace function prop4you_leadfinder_group.promote_materialization_results_to_operational_minimum(
  p_run_id uuid,
  p_limit integer default 10,
  p_actor_id text default null,
  p_metadata jsonb default '{}'::jsonb
)
returns setof prop4you_leadfinder_group.operational_groups
language plpgsql
volatile
as $$
declare
  result_row prop4you_leadfinder_group.materialization_results;
  group_row prop4you_leadfinder_group.operational_groups;
  event_id uuid;
  effective_limit integer;
  field_count integer;
  lineage_payload jsonb;
begin
  if p_run_id is null then
    raise exception 'run_id is required' using errcode='22023';
  end if;
  effective_limit := greatest(1, least(coalesce(p_limit, 10), 1000));

  for result_row in
    select * from prop4you_leadfinder_group.materialization_results mr
     where mr.deleted=false and mr.active=true
       and mr.materialization_run_id=p_run_id
       and mr.result_status='passed'
       and mr.result_gate_status='passed'
     order by mr.created_at, mr.id
     limit effective_limit
  loop
    field_count := coalesce((select count(*) from jsonb_object_keys(coalesce(result_row.operational_payload #> '{candidate_facts}', '{}'::jsonb))), 0);
    lineage_payload := result_row.lineage_summary || jsonb_build_object(
      'materialization_run_id', result_row.materialization_run_id,
      'materialization_result_id', result_row.id,
      'sourcehub_publication_id', result_row.source_publication_id,
      'no_provider_calls', true,
      'raw_payload_not_copied', true
    );

    insert into prop4you_leadfinder_group.operational_groups as g (
      materialization_result_id, materialization_run_id, group_key, group_status, review_status,
      summary, lineage, metadata, materialized_by_actor_id, last_modified_by_actor_id
    ) values (
      result_row.id, result_row.materialization_run_id, 'lfg_group:' || replace(result_row.id::text,'-',''), 'candidate', 'unreviewed',
      jsonb_build_object('contract','leadfinder_group.operational_group.v0','field_count',field_count,'source','materialization_result','minimal_operational',true),
      lineage_payload,
      jsonb_build_object('source','prop4you_leadfinder_group.promote_materialization_results_to_operational_minimum','gateway_agnostic',true,'minimal_operational',true) || coalesce(p_metadata,'{}'::jsonb),
      p_actor_id, p_actor_id
    ) on conflict (materialization_result_id) do update
      set summary=excluded.summary, lineage=excluded.lineage, metadata=excluded.metadata, updated_at=now(), last_modified_by_actor_id=p_actor_id
    returning * into group_row;

    insert into prop4you_leadfinder_group.operational_group_events (group_id, materialization_result_id, event_type, event_status, event_payload, lineage, last_modified_by_actor_id)
    values (group_row.id, result_row.id, 'group_materialized', 'recorded', jsonb_build_object('field_count',field_count,'minimal_operational',true), lineage_payload, p_actor_id)
    returning id into event_id;

    insert into prop4you_leadfinder_group.operational_group_facets as f (group_id, created_by_event_id, facet_key, facet_kind, facet_status, facet_value, confidence, lineage, last_modified_by_actor_id)
    values
      (group_row.id, event_id, 'sourcehub_dto_publication', 'sourcehub_dto_publication', 'asserted', jsonb_build_object('source_publication_id', result_row.source_publication_id), 1.0, lineage_payload, p_actor_id),
      (group_row.id, event_id, 'translated_field_count', 'translated_field_count', 'asserted', to_jsonb(field_count), 1.0, lineage_payload, p_actor_id),
      (group_row.id, event_id, 'materialization_quality', 'materialization_quality', 'asserted', jsonb_build_object('result_status', result_row.result_status, 'result_gate_status', result_row.result_gate_status), 1.0, lineage_payload, p_actor_id)
    on conflict (group_id, facet_key) do update
      set facet_value=excluded.facet_value, created_by_event_id=excluded.created_by_event_id, lineage=excluded.lineage, updated_at=now(), last_modified_by_actor_id=p_actor_id;

    return next group_row;
  end loop;

  return;
end;
$$;

comment on function prop4you_leadfinder_group.promote_materialization_results_to_operational_minimum(uuid,integer,text,jsonb) is
'T5.2 gateway-agnostic promotion from passed materialization results to minimal operational LFG groups/events/facets. Avoids final product table explosion.';
