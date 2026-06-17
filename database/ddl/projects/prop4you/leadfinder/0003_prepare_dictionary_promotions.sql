-- package: prop4you/leadfinder
-- file: 0003_prepare_dictionary_promotions.sql
-- status: experimental / non-final
-- purpose: prepare-only LeadFinder dictionary promotion proposals from Matrix field_mapping_set artifacts.
-- depends-on: leadfinder/0002_raw_evidence_gap_bridge.sql, matrix/0005_field_mapping_set_artifacts.sql
-- idempotency: idempotent
-- destructive: false
-- [PREPARE_ONLY] This DDL never inserts/updates canonical_families or canonical_fields. It prepares review proposals only.
-- [GATEWAY_AGNOSTIC] Callable by any gateway/ORM/PostgREST/direct SQL; no framework dependency.
-- [RAW_DUAL_ROLE] Raw-derived mappings prepare both LFG app modeling and canonical dictionary evolution.
-- [NO_RAW_VALUES] Stores path/type/count/ref metadata only.

create schema if not exists prop4you_leadfinder;

create table if not exists prop4you_leadfinder.dictionary_promotion_preparations (
  id uuid primary key default uuidv7(),
  public_ref text generated always as (base.make_public_ref('p4ylfpp', id)) stored,
  dictionary_version_id uuid not null references prop4you_leadfinder.canonical_dictionary_versions(id) on delete restrict,
  field_mapping_artifact_id uuid not null references prop4you_matrix.transformation_artifacts(id) on delete restrict,
  bridge_id uuid references prop4you_leadfinder.raw_evidence_gap_bridges(id) on delete set null,
  proposal_key text not null,
  proposal_kind text not null,
  proposal_status text not null default 'prepared',
  target_family_key text not null,
  target_field_key text,
  existing_family_id uuid references prop4you_leadfinder.canonical_families(id) on delete set null,
  existing_field_id uuid references prop4you_leadfinder.canonical_fields(id) on delete set null,
  proposed_family_role text not null default 'lineage',
  proposed_value_kind text not null default 'unknown',
  proposed_cardinality text not null default 'unknown',
  proposed_materialization_intent text not null default 'dictionary_candidate',
  proposed_pii_classification text not null default 'unknown',
  source_path text[] not null,
  source_path_label text not null,
  observed_json_type text not null,
  occurrence_count bigint not null,
  raw_record_count bigint not null,
  lfg_app_modeling_hint jsonb not null default '{}'::jsonb,
  canonical_dictionary_hint jsonb not null default '{}'::jsonb,
  review_payload jsonb not null default '{}'::jsonb,
  metadata jsonb not null default '{}'::jsonb,
  prepared_by_actor_id text,
  prepared_at timestamptz not null default now(),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint dictionary_promotion_preparations_public_ref_key unique (public_ref),
  constraint dictionary_promotion_preparations_artifact_proposal_key unique (field_mapping_artifact_id, proposal_key),
  constraint dictionary_promotion_preparations_proposal_key_format_chk check (proposal_key ~ '^[a-z][a-z0-9_.:-]{1,159}$'),
  constraint dictionary_promotion_preparations_proposal_kind_chk check (proposal_kind in ('create_family','create_field','link_existing_field','review_only')),
  constraint dictionary_promotion_preparations_status_chk check (proposal_status in ('prepared','in_review','accepted_for_manual_apply','deferred','rejected','superseded')),
  constraint dictionary_promotion_preparations_family_key_format_chk check (target_family_key ~ '^[a-z][a-z0-9_]{1,79}$'),
  constraint dictionary_promotion_preparations_field_key_format_chk check (target_field_key is null or target_field_key ~ '^[a-z][a-z0-9_]{1,79}$'),
  constraint dictionary_promotion_preparations_family_role_chk check (proposed_family_role in ('property','owner','ownership','party','contact','relationship','situation','valuation','lead','lineage','media','history')),
  constraint dictionary_promotion_preparations_value_kind_chk check (proposed_value_kind in ('text','integer','numeric','boolean','date','timestamp','uuid','enum','jsonb','unknown')),
  constraint dictionary_promotion_preparations_cardinality_chk check (proposed_cardinality in ('one','optional','many','unknown')),
  constraint dictionary_promotion_preparations_materialization_intent_chk check (proposed_materialization_intent in ('dictionary_candidate','dto_candidate','canonical_graph_candidate','evidence_only','do_not_materialize')),
  constraint dictionary_promotion_preparations_pii_chk check (proposed_pii_classification in ('none','possible','contact','person','sensitive','unknown')),
  constraint dictionary_promotion_preparations_path_nonempty_chk check (cardinality(source_path) > 0),
  constraint dictionary_promotion_preparations_counts_chk check (occurrence_count > 0 and raw_record_count > 0 and occurrence_count >= raw_record_count),
  constraint dictionary_promotion_preparations_json_type_chk check (observed_json_type in ('object','array','string','number','boolean','null','unknown','mixed')),
  constraint dictionary_promotion_preparations_payload_object_chk check (jsonb_typeof(review_payload) = 'object'),
  constraint dictionary_promotion_preparations_lfg_hint_object_chk check (jsonb_typeof(lfg_app_modeling_hint) = 'object'),
  constraint dictionary_promotion_preparations_dict_hint_object_chk check (jsonb_typeof(canonical_dictionary_hint) = 'object'),
  constraint dictionary_promotion_preparations_metadata_object_chk check (jsonb_typeof(metadata) = 'object')
);

create index if not exists dictionary_promotion_preparations_dictionary_status_idx
  on prop4you_leadfinder.dictionary_promotion_preparations (dictionary_version_id, proposal_status);
create index if not exists dictionary_promotion_preparations_artifact_idx
  on prop4you_leadfinder.dictionary_promotion_preparations (field_mapping_artifact_id, proposal_status);
create index if not exists dictionary_promotion_preparations_target_idx
  on prop4you_leadfinder.dictionary_promotion_preparations (target_family_key, target_field_key, proposal_status);

comment on table prop4you_leadfinder.dictionary_promotion_preparations is
'Prepare-only LeadFinder promotion proposals derived from Matrix field_mapping_set artifacts. This table does not mutate canonical_families/canonical_fields and stores no raw provider values.';

create or replace view prop4you_leadfinder.v_dictionary_promotion_preparation_review as
select p.id,
       p.public_ref,
       cdv.version_key as dictionary_version_key,
       ta.artifact_key as field_mapping_artifact_key,
       p.proposal_key,
       p.proposal_kind,
       p.proposal_status,
       p.target_family_key,
       p.target_field_key,
       p.existing_family_id,
       cf.family_key as existing_family_key,
       p.existing_field_id,
       cfi.field_key as existing_field_key,
       p.source_path_label,
       p.observed_json_type,
       p.occurrence_count,
       p.raw_record_count,
       p.prepared_at,
       p.created_at,
       p.updated_at
  from prop4you_leadfinder.dictionary_promotion_preparations p
  join prop4you_leadfinder.canonical_dictionary_versions cdv on cdv.id = p.dictionary_version_id
  join prop4you_matrix.transformation_artifacts ta on ta.id = p.field_mapping_artifact_id
  left join prop4you_leadfinder.canonical_families cf on cf.id = p.existing_family_id
  left join prop4you_leadfinder.canonical_fields cfi on cfi.id = p.existing_field_id;

comment on view prop4you_leadfinder.v_dictionary_promotion_preparation_review is
'Review projection for prepare-only dictionary promotion proposals. It is gateway-agnostic and exposes no raw provider values.';

create or replace function prop4you_leadfinder.prepare_dictionary_promotions_from_field_mapping_set(
  p_field_mapping_artifact_id uuid,
  p_limit integer default 10,
  p_actor_id text default null,
  p_metadata jsonb default '{}'::jsonb
)
returns setof prop4you_leadfinder.dictionary_promotion_preparations
language plpgsql
volatile
as $$
declare
  artifact_row prop4you_matrix.transformation_artifacts;
  mapping_item jsonb;
  effective_limit integer;
  target_family text;
  target_field text;
  bridge_uuid uuid;
  existing_family uuid;
  existing_field uuid;
  proposal_kind_value text;
  proposal_key_value text;
  result_row prop4you_leadfinder.dictionary_promotion_preparations;
begin
  if p_field_mapping_artifact_id is null then
    raise exception 'field_mapping_artifact_id is required' using errcode = '22023';
  end if;

  effective_limit := greatest(1, least(coalesce(p_limit, 10), 1000));

  select * into artifact_row
    from prop4you_matrix.transformation_artifacts
   where id = p_field_mapping_artifact_id
     and artifact_kind = 'field_mapping_set'
     and deleted = false;
  if not found then
    raise exception 'field_mapping_set artifact not found: %', p_field_mapping_artifact_id using errcode = '22023';
  end if;

  for mapping_item in
    select value
      from jsonb_array_elements(coalesce(artifact_row.artifact_payload->'mappings', '[]'::jsonb)) with ordinality as m(value, ord)
     order by (value->>'occurrence_count')::bigint desc, (value->>'raw_record_count')::bigint desc, ord
     limit effective_limit
  loop
    target_family := nullif(mapping_item #>> '{semantic_target,family_key}', '');
    target_field := nullif(mapping_item #>> '{semantic_target,field_key}', '');
    bridge_uuid := nullif(mapping_item->>'bridge_id','')::uuid;

    if target_family is null then
      target_family := 'source_lineage';
    end if;
    if target_field is null then
      target_field := regexp_replace(coalesce(mapping_item->>'source_path_label','field'), '[^a-zA-Z0-9]+', '_', 'g');
      target_field := lower(trim(both '_' from target_field));
      if target_field = '' then target_field := 'raw_path_field'; end if;
      target_field := left(target_field, 79);
    end if;

    select id into existing_family
      from prop4you_leadfinder.canonical_families
     where dictionary_version_id = artifact_row.dictionary_version_id
       and family_key = target_family
     limit 1;

    select f.id into existing_field
      from prop4you_leadfinder.canonical_fields f
      join prop4you_leadfinder.canonical_families fam on fam.id = f.family_id
     where f.dictionary_version_id = artifact_row.dictionary_version_id
       and fam.family_key = target_family
       and f.field_key = target_field
     limit 1;

    proposal_kind_value := case
      when existing_field is not null then 'link_existing_field'
      when existing_family is not null then 'create_field'
      else 'create_family'
    end;

    proposal_key_value := 'prepare:' || target_family || ':' || target_field || ':' || left(replace(coalesce(mapping_item->>'bridge_id', artifact_row.id::text), '-', ''), 24);

    insert into prop4you_leadfinder.dictionary_promotion_preparations as p (
      dictionary_version_id, field_mapping_artifact_id, bridge_id,
      proposal_key, proposal_kind, proposal_status,
      target_family_key, target_field_key, existing_family_id, existing_field_id,
      proposed_family_role, proposed_value_kind, proposed_cardinality, proposed_materialization_intent, proposed_pii_classification,
      source_path, source_path_label, observed_json_type, occurrence_count, raw_record_count,
      lfg_app_modeling_hint, canonical_dictionary_hint, review_payload, metadata, prepared_by_actor_id
    ) values (
      artifact_row.dictionary_version_id, artifact_row.id, bridge_uuid,
      proposal_key_value, proposal_kind_value, 'prepared',
      target_family, target_field, existing_family, existing_field,
      case when target_family in ('property','owner','contact','lead','valuation','lineage','history') then target_family else 'lineage' end,
      case mapping_item->>'observed_json_type'
        when 'number' then 'numeric'
        when 'boolean' then 'boolean'
        when 'string' then 'text'
        when 'array' then 'jsonb'
        when 'object' then 'jsonb'
        else 'unknown'
      end,
      case when mapping_item->>'observed_json_type' = 'array' then 'many' else 'unknown' end,
      'dictionary_candidate',
      case when target_family in ('owner','contact','party') then 'possible' else 'unknown' end,
      array(select jsonb_array_elements_text(mapping_item->'source_path')),
      mapping_item->>'source_path_label',
      mapping_item->>'observed_json_type',
      (mapping_item->>'occurrence_count')::bigint,
      (mapping_item->>'raw_record_count')::bigint,
      jsonb_build_object('role','lfg_app_modeling','gateway_agnostic',true,'materialization','T5_later','sourcehub_dto','T4_later'),
      jsonb_build_object('role','canonical_dictionary_generation','prepare_only',true,'auto_mutates_dictionary',false),
      jsonb_build_object('mapping_item', mapping_item, 'no_raw_values', true),
      jsonb_build_object('source','prop4you_leadfinder.prepare_dictionary_promotions_from_field_mapping_set','raw_dual_role',jsonb_build_array('lfg_app_modeling','canonical_dictionary_generation')) || coalesce(p_metadata, '{}'::jsonb),
      p_actor_id
    ) on conflict (field_mapping_artifact_id, proposal_key) do update
      set proposal_kind = excluded.proposal_kind,
          proposal_status = 'prepared',
          existing_family_id = excluded.existing_family_id,
          existing_field_id = excluded.existing_field_id,
          lfg_app_modeling_hint = excluded.lfg_app_modeling_hint,
          canonical_dictionary_hint = excluded.canonical_dictionary_hint,
          review_payload = excluded.review_payload,
          metadata = excluded.metadata,
          updated_at = now(),
          prepared_by_actor_id = p_actor_id
    returning * into result_row;

    return next result_row;
  end loop;

  return;
end;
$$;

comment on function prop4you_leadfinder.prepare_dictionary_promotions_from_field_mapping_set(uuid,integer,text,jsonb) is
'Prepare-only function that turns a Matrix field_mapping_set artifact into LeadFinder dictionary promotion proposals. It never inserts or updates canonical_families/canonical_fields; reviewers or later explicit apply functions must do that.';
