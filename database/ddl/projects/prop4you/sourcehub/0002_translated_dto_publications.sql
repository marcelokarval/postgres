-- package: prop4you/sourcehub
-- file: 0002_translated_dto_publications.sql
-- status: experimental / non-final
-- purpose: SourceHub translated DTO publication records derived from raw SourceHub evidence and Matrix field_mapping_set artifacts.
-- depends-on: sourcehub/0001_sourcehub_corpus.sql, matrix/0005_field_mapping_set_artifacts.sql, leadfinder/0001_canonical_dictionary.sql
-- idempotency: idempotent
-- destructive: false
-- [GATEWAY_AGNOSTIC] Callable by direct SQL, SQLAlchemy, Django ORM, PostgREST, FastAPI, Go, desktop/mobile gateways, or any other transport.
-- [SOURCEHUB_T4] Publishes translated DTO records only; LeadFinder/LFG materialization remains T5_later.
-- [MATRIX_DEPENDENCY] Requires Matrix field_mapping_set artifacts; SourceHub does not own semantic translation.
-- [LEADFINDER_DICTIONARY_DEPENDENCY] Requires a LeadFinder dictionary version; SourceHub does not mutate canonical dictionary.
-- [NO_PROVIDER_CALLS] No HTTP/provider calls, workers, cron, secrets, or corpus reads.
-- [NO_LFG_MATERIALIZATION] Does not insert/update LeadFinder operational/materialized entities.

create schema if not exists prop4you_sourcehub;

create table if not exists prop4you_sourcehub.translated_dto_publications (
  id uuid primary key default uuidv7(),
  public_ref text generated always as (base.make_public_ref('p4yshd', id)) stored,
  raw_record_id uuid not null references prop4you_sourcehub.raw_records(id) on delete restrict,
  matrix_artifact_id uuid not null references prop4you_matrix.transformation_artifacts(id) on delete restrict,
  leadfinder_dictionary_version_id uuid not null references prop4you_leadfinder.canonical_dictionary_versions(id) on delete restrict,
  provider_id uuid references prop4you_provider.providers(id) on delete restrict,
  payload_class_id uuid references prop4you_provider.payload_classes(id) on delete restrict,
  publication_key text not null,
  publication_status text not null default 'candidate',
  publication_kind text not null default 'leadfinder_candidate',
  dto_schema_version text not null default 'sourcehub.translated_dto.v0',
  translated_dto jsonb not null,
  translated_dto_sha256 text,
  source_payload_sha256 text,
  matrix_artifact_sha256 text,
  publication_gate_status text not null default 'ready_for_review',
  review_status text not null default 'unreviewed',
  source_lineage_edge_id uuid references prop4you_sourcehub.source_lineage_edges(id) on delete set null,
  temporal_phase jsonb not null default '{"raw_capture":"T0","matrix_extraction":"T1","leadfinder_gap_bridge":"T2","matrix_quality_report":"T3","matrix_field_mapping_set":"T3_5","sourcehub_dto_publication":"T4","leadfinder_materialization":"T5_later"}'::jsonb,
  translation_summary jsonb not null default '{}'::jsonb,
  quality_summary jsonb not null default '{}'::jsonb,
  redaction_summary jsonb not null default '{}'::jsonb,
  metadata jsonb not null default '{}'::jsonb,
  published_at timestamptz,
  published_by_actor_id text,
  reviewed_at timestamptz,
  reviewed_by_actor_id text,
  superseded_by_publication_id uuid references prop4you_sourcehub.translated_dto_publications(id) on delete set null,
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
  constraint translated_dto_publications_public_ref_key unique (public_ref),
  constraint translated_dto_publications_publication_key_key unique (publication_key),
  constraint translated_dto_publications_publication_key_format_chk check (publication_key ~ '^[a-z][a-z0-9_.:-]{1,191}$'),
  constraint translated_dto_publications_status_chk check (publication_status in ('candidate','blocked','ready_for_review','published','rejected','superseded','archived')),
  constraint translated_dto_publications_kind_chk check (publication_kind in ('leadfinder_candidate','review_snapshot','gap_evidence','regression_fixture_metadata','unknown')),
  constraint translated_dto_publications_schema_version_chk check (dto_schema_version ~ '^[a-z][a-z0-9_.:-]{1,79}$'),
  constraint translated_dto_publications_dto_object_chk check (jsonb_typeof(translated_dto) = 'object'),
  constraint translated_dto_publications_dto_sha256_chk check (translated_dto_sha256 is null or translated_dto_sha256 ~ '^[0-9a-f]{64}$'),
  constraint translated_dto_publications_source_sha256_chk check (source_payload_sha256 is null or source_payload_sha256 ~ '^[0-9a-f]{64}$'),
  constraint translated_dto_publications_artifact_sha256_chk check (matrix_artifact_sha256 is null or matrix_artifact_sha256 ~ '^[0-9a-f]{64}$'),
  constraint translated_dto_publications_gate_status_chk check (publication_gate_status in ('not_started','ready_for_review','passed','blocked','not_applicable')),
  constraint translated_dto_publications_review_status_chk check (review_status in ('unreviewed','in_review','accepted_for_publication','needs_mapping_revision','needs_dictionary_revision','needs_redaction','rejected','not_applicable')),
  constraint translated_dto_publications_temporal_phase_object_chk check (jsonb_typeof(temporal_phase) = 'object'),
  constraint translated_dto_publications_translation_summary_object_chk check (jsonb_typeof(translation_summary) = 'object'),
  constraint translated_dto_publications_quality_summary_object_chk check (jsonb_typeof(quality_summary) = 'object'),
  constraint translated_dto_publications_redaction_summary_object_chk check (jsonb_typeof(redaction_summary) = 'object'),
  constraint translated_dto_publications_metadata_object_chk check (jsonb_typeof(metadata) = 'object'),
  constraint translated_dto_publications_published_gate_chk check (publication_status <> 'published' or publication_gate_status = 'passed'),
  constraint translated_dto_publications_version_positive_chk check (version > 0)
);

create index if not exists translated_dto_publications_raw_status_idx
  on prop4you_sourcehub.translated_dto_publications (raw_record_id, publication_status, publication_gate_status)
  where deleted = false;
create index if not exists translated_dto_publications_artifact_status_idx
  on prop4you_sourcehub.translated_dto_publications (matrix_artifact_id, publication_status, publication_gate_status)
  where deleted = false;
create index if not exists translated_dto_publications_dictionary_status_idx
  on prop4you_sourcehub.translated_dto_publications (leadfinder_dictionary_version_id, publication_status)
  where deleted = false;
create index if not exists translated_dto_publications_provider_payload_idx
  on prop4you_sourcehub.translated_dto_publications (provider_id, payload_class_id, publication_status)
  where deleted = false;
create index if not exists translated_dto_publications_dto_gin_idx
  on prop4you_sourcehub.translated_dto_publications using gin (translated_dto jsonb_path_ops);

comment on table prop4you_sourcehub.translated_dto_publications is
'SourceHub-owned T4 translated DTO publication records. Each row links one raw record, one Matrix field_mapping_set artifact, and one LeadFinder dictionary version. This is not LeadFinder/LFG materialization and creates no operational property/owner/lead rows.';
comment on column prop4you_sourcehub.translated_dto_publications.raw_record_id is 'SourceHub raw record that supplied the source evidence and lineage for this translated DTO publication.';
comment on column prop4you_sourcehub.translated_dto_publications.matrix_artifact_id is 'Matrix transformation_artifacts row. Must be artifact_kind=field_mapping_set; validated by trigger/function.';
comment on column prop4you_sourcehub.translated_dto_publications.leadfinder_dictionary_version_id is 'LeadFinder dictionary version used by the Matrix artifact and DTO semantic keys.';
comment on column prop4you_sourcehub.translated_dto_publications.translated_dto is 'Versioned translated DTO JSONB. May contain normalized values for review/publication, but not raw payload dumps or secrets.';
comment on column prop4you_sourcehub.translated_dto_publications.translated_dto_sha256 is 'Lowercase SHA-256 of translated_dto canonical text as generated by the publication function for reproducibility in this experimental gate.';
comment on column prop4you_sourcehub.translated_dto_publications.publication_status is 'SourceHub publication lifecycle status. This is not LFG materialization status.';
comment on column prop4you_sourcehub.translated_dto_publications.publication_gate_status is 'Gate status for the DTO publication itself; published rows require passed gate.';
comment on column prop4you_sourcehub.translated_dto_publications.review_status is 'Review status for the DTO publication and redaction/mapping readiness.';
comment on column prop4you_sourcehub.translated_dto_publications.temporal_phase is 'Explicit phase map: T4 SourceHub DTO publication, with T5 LeadFinder materialization later.';

create or replace function prop4you_sourcehub.validate_translated_dto_publication()
returns trigger
language plpgsql
as $$
declare
  artifact_row prop4you_matrix.transformation_artifacts;
  raw_row prop4you_sourcehub.raw_records;
begin
  select * into artifact_row
    from prop4you_matrix.transformation_artifacts
   where id = new.matrix_artifact_id
     and deleted = false;
  if not found then
    raise exception 'Matrix artifact not found or deleted: %', new.matrix_artifact_id using errcode = '22023';
  end if;
  if artifact_row.artifact_kind <> 'field_mapping_set' then
    raise exception 'Matrix artifact % must be artifact_kind=field_mapping_set, got %', new.matrix_artifact_id, artifact_row.artifact_kind using errcode = '22023';
  end if;
  if artifact_row.dictionary_version_id <> new.leadfinder_dictionary_version_id then
    raise exception 'dictionary version mismatch: artifact %, publication %', artifact_row.dictionary_version_id, new.leadfinder_dictionary_version_id using errcode = '22023';
  end if;
  if artifact_row.artifact_gate_status not in ('ready_for_review','passed') then
    raise exception 'Matrix field_mapping_set artifact gate not publishable: %', artifact_row.artifact_gate_status using errcode = '22023';
  end if;

  select * into raw_row
    from prop4you_sourcehub.raw_records
   where id = new.raw_record_id
     and deleted = false
     and active = true;
  if not found then
    raise exception 'raw record not found/active: %', new.raw_record_id using errcode = '22023';
  end if;

  if artifact_row.provider_id is not null and raw_row.provider_id <> artifact_row.provider_id then
    raise exception 'provider mismatch between raw record and Matrix artifact' using errcode = '22023';
  end if;
  if artifact_row.payload_class_id is not null and raw_row.payload_class_id <> artifact_row.payload_class_id then
    raise exception 'payload class mismatch between raw record and Matrix artifact' using errcode = '22023';
  end if;

  new.provider_id := raw_row.provider_id;
  new.payload_class_id := raw_row.payload_class_id;
  new.source_payload_sha256 := raw_row.raw_payload_sha256;
  new.matrix_artifact_sha256 := artifact_row.content_sha256;
  if new.translated_dto_sha256 is null then
    new.translated_dto_sha256 := encode(digest(new.translated_dto::text, 'sha256'), 'hex');
  end if;
  new.updated_at := now();
  return new;
end;
$$;

comment on function prop4you_sourcehub.validate_translated_dto_publication() is
'Validates SourceHub translated DTO publications: Matrix artifact must be a field_mapping_set, dictionary versions must match, raw record/artifact provider/class must match, and no LeadFinder/LFG materialization occurs.';

drop trigger if exists translated_dto_publications_validate on prop4you_sourcehub.translated_dto_publications;
create trigger translated_dto_publications_validate
before insert or update on prop4you_sourcehub.translated_dto_publications
for each row execute function prop4you_sourcehub.validate_translated_dto_publication();

drop trigger if exists translated_dto_publications_set_lifecycle_defaults on prop4you_sourcehub.translated_dto_publications;
create trigger translated_dto_publications_set_lifecycle_defaults
before insert on prop4you_sourcehub.translated_dto_publications
for each row execute function base.set_lifecycle_defaults();

drop trigger if exists translated_dto_publications_touch_updated_at on prop4you_sourcehub.translated_dto_publications;
create trigger translated_dto_publications_touch_updated_at
before update on prop4you_sourcehub.translated_dto_publications
for each row execute function base.touch_updated_at();

drop trigger if exists translated_dto_publications_increment_version on prop4you_sourcehub.translated_dto_publications;
create trigger translated_dto_publications_increment_version
before update on prop4you_sourcehub.translated_dto_publications
for each row execute function base.increment_version();

create or replace view prop4you_sourcehub.v_translated_dto_publication_review as
select p.id,
       p.public_ref,
       p.publication_key,
       p.publication_status,
       p.publication_gate_status,
       p.review_status,
       p.dto_schema_version,
       p.raw_record_id,
       rr.public_ref as raw_record_public_ref,
       p.matrix_artifact_id,
       ma.artifact_key as matrix_artifact_key,
       ma.artifact_kind as matrix_artifact_kind,
       p.leadfinder_dictionary_version_id,
       cdv.version_key as dictionary_version_key,
       pr.provider_key,
       pc.class_key as payload_class_key,
       p.translated_dto_sha256,
       p.source_payload_sha256,
       p.matrix_artifact_sha256,
       p.translation_summary,
       p.quality_summary,
       p.redaction_summary,
       p.temporal_phase,
       p.created_at,
       p.updated_at,
       p.published_at
  from prop4you_sourcehub.translated_dto_publications p
  join prop4you_sourcehub.raw_records rr on rr.id = p.raw_record_id
  join prop4you_matrix.transformation_artifacts ma on ma.id = p.matrix_artifact_id
  join prop4you_leadfinder.canonical_dictionary_versions cdv on cdv.id = p.leadfinder_dictionary_version_id
  left join prop4you_provider.providers pr on pr.id = p.provider_id
  left join prop4you_provider.payload_classes pc on pc.id = p.payload_class_id
 where p.deleted = false;

comment on view prop4you_sourcehub.v_translated_dto_publication_review is
'Review projection for SourceHub T4 translated DTO publications. It exposes lineage, hashes and summaries without raw payload dumps.';

create or replace function prop4you_sourcehub.publish_translated_dtos_from_field_mapping_set(
  p_field_mapping_artifact_id uuid,
  p_limit integer default 10,
  p_publication_status text default 'ready_for_review',
  p_publication_gate_status text default 'ready_for_review',
  p_actor_id text default null,
  p_metadata jsonb default '{}'::jsonb
)
returns setof prop4you_sourcehub.translated_dto_publications
language plpgsql
volatile
as $$
declare
  artifact_row prop4you_matrix.transformation_artifacts;
  dictionary_row prop4you_leadfinder.canonical_dictionary_versions;
  raw_row prop4you_sourcehub.raw_records;
  mapping_count integer;
  applied_count integer;
  effective_limit integer;
  dto_fields jsonb;
  dto_payload jsonb;
  publication_key_value text;
  result_row prop4you_sourcehub.translated_dto_publications;
begin
  if p_field_mapping_artifact_id is null then
    raise exception 'field_mapping_artifact_id is required' using errcode = '22023';
  end if;

  if p_publication_status not in ('candidate','blocked','ready_for_review','published','rejected','superseded','archived') then
    raise exception 'invalid publication status: %', p_publication_status using errcode = '22023';
  end if;
  if p_publication_gate_status not in ('not_started','ready_for_review','passed','blocked','not_applicable') then
    raise exception 'invalid publication gate status: %', p_publication_gate_status using errcode = '22023';
  end if;
  if p_publication_status = 'published' and p_publication_gate_status <> 'passed' then
    raise exception 'published DTO publication requires passed gate' using errcode = '22023';
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
  if artifact_row.artifact_gate_status not in ('ready_for_review','passed') then
    raise exception 'field_mapping_set gate is not publishable: %', artifact_row.artifact_gate_status using errcode = '22023';
  end if;

  select * into dictionary_row
    from prop4you_leadfinder.canonical_dictionary_versions
   where id = artifact_row.dictionary_version_id;
  if not found then
    raise exception 'dictionary version not found: %', artifact_row.dictionary_version_id using errcode = '22023';
  end if;

  select count(*)::integer into mapping_count
    from jsonb_array_elements(coalesce(artifact_row.artifact_payload->'mappings', '[]'::jsonb));
  if mapping_count = 0 then
    raise exception 'field_mapping_set has no mappings: %', artifact_row.id using errcode = '22023';
  end if;

  for raw_row in
    select *
      from prop4you_sourcehub.raw_records rr
     where rr.deleted = false
       and rr.active = true
       and (artifact_row.provider_id is null or rr.provider_id = artifact_row.provider_id)
       and (artifact_row.payload_class_id is null or rr.payload_class_id = artifact_row.payload_class_id)
       and rr.review_status in ('accepted_for_mapping','in_review','unreviewed')
       and rr.matrix_mapping_status in ('mapped','candidate_paths_detected','mapping_in_review','not_started')
     order by rr.captured_at, rr.id
     limit effective_limit
  loop
    select coalesce(jsonb_object_agg(target_key, target_value) filter (where target_value is not null), '{}'::jsonb),
           count(*) filter (where target_value is not null)::integer
      into dto_fields, applied_count
      from (
        select coalesce(m.value #>> '{semantic_target,family_key}', m.value->>'proposed_family_key', 'source') || '.' ||
               coalesce(m.value #>> '{semantic_target,field_key}', m.value->>'proposed_field_key', replace(m.value->>'source_path_label', '.', '_'), 'field') as target_key,
               raw_row.raw_payload #> array(select jsonb_array_elements_text(m.value->'source_path')) as target_value
          from jsonb_array_elements(coalesce(artifact_row.artifact_payload->'mappings', '[]'::jsonb)) as m(value)
      ) mapped_values;

    publication_key_value := 'translated_dto:' || replace(raw_row.id::text, '-', '') || ':' || left(replace(artifact_row.id::text, '-', ''), 24);

    dto_payload := jsonb_build_object(
      'contract', 'sourcehub.translated_dto.v0',
      'gateway_agnostic', true,
      'temporal_phase', jsonb_build_object('sourcehub_dto_publication','T4','leadfinder_materialization','T5_later'),
      'source', jsonb_build_object(
        'raw_record_id', raw_row.id,
        'raw_record_public_ref', raw_row.public_ref,
        'provider_id', raw_row.provider_id,
        'payload_class_id', raw_row.payload_class_id,
        'raw_payload_sha256', raw_row.raw_payload_sha256
      ),
      'matrix', jsonb_build_object(
        'field_mapping_artifact_id', artifact_row.id,
        'artifact_key', artifact_row.artifact_key,
        'artifact_schema_version', artifact_row.artifact_schema_version,
        'artifact_gate_status', artifact_row.artifact_gate_status
      ),
      'leadfinder', jsonb_build_object(
        'dictionary_version_id', dictionary_row.id,
        'dictionary_version_key', dictionary_row.version_key,
        'materialization', 'T5_later'
      ),
      'fields', dto_fields,
      'quality', jsonb_build_object(
        'mapping_count', mapping_count,
        'applied_field_count', coalesce(applied_count, 0),
        'value_policy', 'translated_dto_values_stored_in_sourcehub_not_printed_in_proofs'
      ),
      'lineage', jsonb_build_object(
        'raw_dual_role', jsonb_build_array('lfg_app_modeling','canonical_dictionary_generation'),
        'no_provider_calls', true,
        'no_lfg_materialization', true
      )
    );

    insert into prop4you_sourcehub.translated_dto_publications as pub (
      raw_record_id, matrix_artifact_id, leadfinder_dictionary_version_id,
      publication_key, publication_status, publication_kind, dto_schema_version,
      translated_dto, translated_dto_sha256,
      publication_gate_status, review_status,
      translation_summary, quality_summary, redaction_summary,
      metadata, published_at, published_by_actor_id, last_modified_by_actor_id
    ) values (
      raw_row.id, artifact_row.id, artifact_row.dictionary_version_id,
      publication_key_value, p_publication_status, 'leadfinder_candidate', 'sourcehub.translated_dto.v0',
      dto_payload, encode(digest(dto_payload::text, 'sha256'), 'hex'),
      p_publication_gate_status,
      case when p_publication_status = 'published' then 'accepted_for_publication' else 'unreviewed' end,
      jsonb_build_object('mapping_count', mapping_count, 'applied_field_count', coalesce(applied_count, 0), 'sourcehub_dto_publication', 'T4'),
      coalesce(artifact_row.quality_summary, '{}'::jsonb),
      jsonb_build_object('policy', 'no_raw_payload_dump_in_docs_or_proofs', 'pii_review_required_before_public_exposure', true),
      jsonb_build_object('source','prop4you_sourcehub.publish_translated_dtos_from_field_mapping_set','gateway_agnostic',true,'no_provider_calls',true,'no_lfg_materialization',true) || coalesce(p_metadata, '{}'::jsonb),
      case when p_publication_status = 'published' then now() else null end,
      case when p_publication_status = 'published' then p_actor_id else null end,
      p_actor_id
    ) on conflict (publication_key) do update
      set publication_status = excluded.publication_status,
          publication_kind = excluded.publication_kind,
          dto_schema_version = excluded.dto_schema_version,
          translated_dto = excluded.translated_dto,
          translated_dto_sha256 = excluded.translated_dto_sha256,
          publication_gate_status = excluded.publication_gate_status,
          review_status = excluded.review_status,
          translation_summary = excluded.translation_summary,
          quality_summary = excluded.quality_summary,
          redaction_summary = excluded.redaction_summary,
          metadata = excluded.metadata,
          published_at = excluded.published_at,
          published_by_actor_id = excluded.published_by_actor_id,
          updated_at = now(),
          last_modified_by_actor_id = p_actor_id
    returning * into result_row;

    update prop4you_sourcehub.raw_records
       set leadfinder_publication_status = case when p_publication_status = 'published' then 'published' else 'candidate_dto_ready' end,
           updated_at = now(),
           last_modified_by_actor_id = p_actor_id
     where id = raw_row.id;

    return next result_row;
  end loop;

  return;
end;
$$;

comment on function prop4you_sourcehub.publish_translated_dtos_from_field_mapping_set(uuid,integer,text,text,text,jsonb) is
'Publishes SourceHub T4 translated DTO candidates from one Matrix field_mapping_set artifact and active raw records. Gateway-agnostic, idempotent by publication_key, no provider calls, no canonical dictionary mutation, and no LeadFinder/LFG materialization.';
