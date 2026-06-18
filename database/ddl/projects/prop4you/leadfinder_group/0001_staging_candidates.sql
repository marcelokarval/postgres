-- package: prop4you/leadfinder_group
-- file: 0001_staging_candidates.sql
-- status: experimental / non-final
-- purpose: T5.0 LFG staging candidates derived from SourceHub T4 translated DTO publications.
-- depends-on: sourcehub/0002_translated_dto_publications.sql
-- idempotency: idempotent
-- destructive: false
-- [GATEWAY_AGNOSTIC] Callable by direct SQL, ORM, PostgREST RPC, Django/FastAPI passthrough, workers, or any other transport.
-- [SOURCEHUB_T4_INPUT] Consumes only SourceHub translated DTO publication rows.
-- [LFG_T5_STAGING_ONLY] Creates staging candidates only; materialization runs/results and operational entities remain later files.
-- [NO_PROVIDER_CALLS] No HTTP/provider SDK/worker/cron/file reads.
-- [NO_RAW_DUMPS] Does not copy SourceHub raw_payload; docs/proofs must not print DTO scalar payloads.

create schema if not exists prop4you_leadfinder_group;
comment on schema prop4you_leadfinder_group is
'Prop4You LeadFinder Group operational boundary. Owns T5 staging/materialization/operational projections after SourceHub translated DTO publication. Experimental non-final.';

create table if not exists prop4you_leadfinder_group.staging_candidates (
  id uuid primary key default uuidv7(),
  public_ref text generated always as (base.make_public_ref('p4ylfgs', id)) stored,
  source_publication_id uuid not null references prop4you_sourcehub.translated_dto_publications(id) on delete restrict,
  raw_record_id uuid not null references prop4you_sourcehub.raw_records(id) on delete restrict,
  matrix_artifact_id uuid not null references prop4you_matrix.transformation_artifacts(id) on delete restrict,
  leadfinder_dictionary_version_id uuid not null references prop4you_leadfinder.canonical_dictionary_versions(id) on delete restrict,
  provider_id uuid references prop4you_provider.providers(id) on delete restrict,
  payload_class_id uuid references prop4you_provider.payload_classes(id) on delete restrict,
  candidate_key text not null,
  candidate_status text not null default 'staged',
  candidate_gate_status text not null default 'ready_for_review',
  review_status text not null default 'unreviewed',
  candidate_kind text not null default 'lfg_staging_candidate',
  candidate_schema_version text not null default 'leadfinder_group.staging_candidate.v0',
  source_publication_key text not null,
  source_publication_status text not null,
  source_publication_gate_status text not null,
  source_publication_review_status text not null,
  source_translated_dto_sha256 text,
  source_payload_sha256 text,
  matrix_artifact_sha256 text,
  candidate_facts jsonb not null default '{}'::jsonb,
  candidate_summary jsonb not null default '{}'::jsonb,
  quality_summary jsonb not null default '{}'::jsonb,
  lineage_summary jsonb not null default '{}'::jsonb,
  redaction_summary jsonb not null default '{}'::jsonb,
  temporal_phase jsonb not null default '{"sourcehub_dto_publication":"T4","lfg_staging_candidate":"T5_0","lfg_materialization_run":"T5_1_later","lfg_operational_minimum":"T5_2_later"}'::jsonb,
  metadata jsonb not null default '{}'::jsonb,
  staged_at timestamptz not null default now(),
  staged_by_actor_id text,
  reviewed_at timestamptz,
  reviewed_by_actor_id text,
  superseded_by_candidate_id uuid references prop4you_leadfinder_group.staging_candidates(id) on delete set null,
  superseded_at timestamptz,
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
  constraint staging_candidates_public_ref_key unique (public_ref),
  constraint staging_candidates_source_publication_key unique (source_publication_id),
  constraint staging_candidates_candidate_key_key unique (candidate_key),
  constraint staging_candidates_candidate_key_format_chk check (candidate_key ~ '^[a-z][a-z0-9_.:-]{1,191}$'),
  constraint staging_candidates_status_chk check (candidate_status in ('staged','ready_for_materialization','blocked','materialized','rejected','superseded','archived')),
  constraint staging_candidates_gate_chk check (candidate_gate_status in ('not_started','ready_for_review','passed','blocked','not_applicable')),
  constraint staging_candidates_review_chk check (review_status in ('unreviewed','in_review','accepted_for_materialization','needs_dto_revision','needs_dictionary_revision','rejected','not_applicable')),
  constraint staging_candidates_kind_chk check (candidate_kind in ('lfg_staging_candidate','review_snapshot','regression_fixture_metadata','unknown')),
  constraint staging_candidates_schema_version_chk check (candidate_schema_version ~ '^[a-z][a-z0-9_.:-]{1,79}$'),
  constraint staging_candidates_hash_chk check (source_translated_dto_sha256 is null or source_translated_dto_sha256 ~ '^[0-9a-f]{64}$'),
  constraint staging_candidates_payload_hash_chk check (source_payload_sha256 is null or source_payload_sha256 ~ '^[0-9a-f]{64}$'),
  constraint staging_candidates_artifact_hash_chk check (matrix_artifact_sha256 is null or matrix_artifact_sha256 ~ '^[0-9a-f]{64}$'),
  constraint staging_candidates_json_objects_chk check (
    jsonb_typeof(candidate_facts) = 'object' and jsonb_typeof(candidate_summary) = 'object' and
    jsonb_typeof(quality_summary) = 'object' and jsonb_typeof(lineage_summary) = 'object' and
    jsonb_typeof(redaction_summary) = 'object' and jsonb_typeof(temporal_phase) = 'object' and jsonb_typeof(metadata) = 'object'
  ),
  constraint staging_candidates_version_positive_chk check (version > 0)
);

create index if not exists staging_candidates_status_idx
  on prop4you_leadfinder_group.staging_candidates (candidate_status, candidate_gate_status, review_status, created_at desc)
  where deleted = false;
create index if not exists staging_candidates_publication_idx
  on prop4you_leadfinder_group.staging_candidates (source_publication_id)
  where deleted = false;
create index if not exists staging_candidates_provider_payload_idx
  on prop4you_leadfinder_group.staging_candidates (provider_id, payload_class_id, candidate_status)
  where deleted = false;
create index if not exists staging_candidates_lineage_gin_idx
  on prop4you_leadfinder_group.staging_candidates using gin (lineage_summary jsonb_path_ops);

comment on table prop4you_leadfinder_group.staging_candidates is
'T5.0 staging candidates derived from SourceHub translated DTO publications. Staging is reviewable input to LFG materialization; it is not final operational LFG state.';
comment on column prop4you_leadfinder_group.staging_candidates.candidate_facts is 'Compact translated DTO fields copied from SourceHub publication for internal staging/materialization. Do not dump values in docs/proofs.';
comment on column prop4you_leadfinder_group.staging_candidates.lineage_summary is 'Lineage references/hashes proving SourceHub/Matrix/LeadFinder provenance without copying raw_payload.';

drop trigger if exists staging_candidates_set_lifecycle_defaults on prop4you_leadfinder_group.staging_candidates;
create trigger staging_candidates_set_lifecycle_defaults
before insert on prop4you_leadfinder_group.staging_candidates
for each row execute function base.set_lifecycle_defaults();

drop trigger if exists staging_candidates_touch_updated_at on prop4you_leadfinder_group.staging_candidates;
create trigger staging_candidates_touch_updated_at
before update on prop4you_leadfinder_group.staging_candidates
for each row execute function base.touch_updated_at();

drop trigger if exists staging_candidates_increment_version on prop4you_leadfinder_group.staging_candidates;
create trigger staging_candidates_increment_version
before update on prop4you_leadfinder_group.staging_candidates
for each row execute function base.increment_version();

create or replace view prop4you_leadfinder_group.v_staging_candidate_review as
select sc.id,
       sc.public_ref,
       sc.candidate_key,
       sc.candidate_status,
       sc.candidate_gate_status,
       sc.review_status,
       sc.source_publication_id,
       pub.public_ref as source_publication_public_ref,
       pub.publication_key as source_publication_key,
       sc.raw_record_id,
       sc.matrix_artifact_id,
       ma.artifact_key as matrix_artifact_key,
       sc.leadfinder_dictionary_version_id,
       cdv.version_key as dictionary_version_key,
       pr.provider_key,
       pc.class_key as payload_class_key,
       sc.source_translated_dto_sha256,
       sc.source_payload_sha256,
       sc.matrix_artifact_sha256,
       sc.candidate_summary,
       sc.quality_summary,
       sc.lineage_summary,
       sc.created_at,
       sc.updated_at
  from prop4you_leadfinder_group.staging_candidates sc
  join prop4you_sourcehub.translated_dto_publications pub on pub.id = sc.source_publication_id
  join prop4you_matrix.transformation_artifacts ma on ma.id = sc.matrix_artifact_id
  join prop4you_leadfinder.canonical_dictionary_versions cdv on cdv.id = sc.leadfinder_dictionary_version_id
  left join prop4you_provider.providers pr on pr.id = sc.provider_id
  left join prop4you_provider.payload_classes pc on pc.id = sc.payload_class_id
 where sc.deleted = false;

create or replace function prop4you_leadfinder_group.stage_candidates_from_translated_dto_publications(
  p_limit integer default 10,
  p_candidate_status text default 'ready_for_materialization',
  p_candidate_gate_status text default 'ready_for_review',
  p_actor_id text default null,
  p_metadata jsonb default '{}'::jsonb
)
returns setof prop4you_leadfinder_group.staging_candidates
language plpgsql
volatile
as $$
declare
  publication_row prop4you_sourcehub.translated_dto_publications;
  effective_limit integer;
  facts jsonb;
  candidate_key_value text;
  result_row prop4you_leadfinder_group.staging_candidates;
begin
  if p_candidate_status not in ('staged','ready_for_materialization','blocked','materialized','rejected','superseded','archived') then
    raise exception 'invalid candidate_status: %', p_candidate_status using errcode = '22023';
  end if;
  if p_candidate_gate_status not in ('not_started','ready_for_review','passed','blocked','not_applicable') then
    raise exception 'invalid candidate_gate_status: %', p_candidate_gate_status using errcode = '22023';
  end if;
  effective_limit := greatest(1, least(coalesce(p_limit, 10), 1000));

  for publication_row in
    select *
      from prop4you_sourcehub.translated_dto_publications p
     where p.deleted = false
       and p.active = true
       and p.publication_status in ('ready_for_review','published')
       and p.publication_gate_status in ('ready_for_review','passed')
     order by p.created_at, p.id
     limit effective_limit
  loop
    facts := coalesce(publication_row.translated_dto->'fields', '{}'::jsonb);
    if jsonb_typeof(facts) is distinct from 'object' then
      facts := '{}'::jsonb;
    end if;
    candidate_key_value := 'lfg_staging:' || replace(publication_row.id::text, '-', '');

    insert into prop4you_leadfinder_group.staging_candidates as sc (
      source_publication_id, raw_record_id, matrix_artifact_id, leadfinder_dictionary_version_id,
      provider_id, payload_class_id,
      candidate_key, candidate_status, candidate_gate_status, review_status,
      source_publication_key, source_publication_status, source_publication_gate_status, source_publication_review_status,
      source_translated_dto_sha256, source_payload_sha256, matrix_artifact_sha256,
      candidate_facts, candidate_summary, quality_summary, lineage_summary, redaction_summary, metadata,
      staged_by_actor_id, last_modified_by_actor_id
    ) values (
      publication_row.id, publication_row.raw_record_id, publication_row.matrix_artifact_id, publication_row.leadfinder_dictionary_version_id,
      publication_row.provider_id, publication_row.payload_class_id,
      candidate_key_value, p_candidate_status, p_candidate_gate_status,
      case when p_candidate_status = 'ready_for_materialization' then 'accepted_for_materialization' else 'unreviewed' end,
      publication_row.publication_key, publication_row.publication_status, publication_row.publication_gate_status, publication_row.review_status,
      publication_row.translated_dto_sha256, publication_row.source_payload_sha256, publication_row.matrix_artifact_sha256,
      facts,
      jsonb_build_object('sourcehub_publication','T4','lfg_staging_candidate','T5_0','field_count', (select count(*) from jsonb_object_keys(facts)),'value_policy','values_stored_not_printed_in_proofs'),
      publication_row.quality_summary,
      jsonb_build_object('sourcehub_publication_id', publication_row.id, 'sourcehub_publication_public_ref', publication_row.public_ref, 'matrix_artifact_id', publication_row.matrix_artifact_id, 'leadfinder_dictionary_version_id', publication_row.leadfinder_dictionary_version_id, 'source_payload_sha256', publication_row.source_payload_sha256, 'translated_dto_sha256', publication_row.translated_dto_sha256, 'no_provider_calls', true, 'raw_payload_not_copied', true),
      publication_row.redaction_summary,
      jsonb_build_object('source','prop4you_leadfinder_group.stage_candidates_from_translated_dto_publications','gateway_agnostic',true,'no_provider_calls',true,'no_raw_payload_copy',true) || coalesce(p_metadata, '{}'::jsonb),
      p_actor_id, p_actor_id
    ) on conflict (source_publication_id) do update
      set candidate_status = excluded.candidate_status,
          candidate_gate_status = excluded.candidate_gate_status,
          review_status = excluded.review_status,
          source_publication_status = excluded.source_publication_status,
          source_publication_gate_status = excluded.source_publication_gate_status,
          source_publication_review_status = excluded.source_publication_review_status,
          source_translated_dto_sha256 = excluded.source_translated_dto_sha256,
          candidate_facts = excluded.candidate_facts,
          candidate_summary = excluded.candidate_summary,
          quality_summary = excluded.quality_summary,
          lineage_summary = excluded.lineage_summary,
          redaction_summary = excluded.redaction_summary,
          metadata = excluded.metadata,
          updated_at = now(),
          last_modified_by_actor_id = p_actor_id
    returning * into result_row;

    return next result_row;
  end loop;

  return;
end;
$$;

comment on function prop4you_leadfinder_group.stage_candidates_from_translated_dto_publications(integer,text,text,text,jsonb) is
'T5.0 gateway-agnostic staging function that creates LFG staging candidates from SourceHub T4 translated DTO publications. No provider calls and no raw_payload copy.';
