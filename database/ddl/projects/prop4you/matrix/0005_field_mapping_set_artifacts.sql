-- package: prop4you/matrix
-- file: 0005_field_mapping_set_artifacts.sql
-- status: experimental / non-final
-- purpose: Matrix-owned field_mapping_set artifacts generated from LeadFinder raw evidence gap bridge rows.
-- depends-on: matrix/0002_mapping_sessions.sql, matrix/0004_quality_report_artifacts.sql, leadfinder/0002_raw_evidence_gap_bridge.sql
-- idempotency: idempotent
-- destructive: false
-- [GATEWAY_AGNOSTIC] No Django/PostgREST/ORM assumption; this is a database contract callable by any gateway.
-- [RAW_DUAL_ROLE] Raw evidence drives both LFG app modeling and LeadFinder canonical dictionary evolution.
-- [MATRIX_TRANSLATION_OWNER] Matrix owns the semantic translation artifact; SourceHub publication depends on this artifact.
-- [NO_PROVIDER_CALLS] No provider/API calls.
-- [NO_RAW_VALUES] Stores path/type/count/ref metadata only, no raw scalar values.

create schema if not exists prop4you_matrix;

create or replace view prop4you_matrix.v_field_mapping_set_artifacts as
select ta.id,
       ta.public_ref,
       ta.mapping_session_id,
       ms.session_key,
       ta.dictionary_version_id,
       cdv.version_key as dictionary_version_key,
       ta.provider_id,
       p.provider_key,
       ta.payload_class_id,
       pc.class_key as payload_class_key,
       ta.artifact_key,
       ta.artifact_status,
       ta.artifact_schema_version,
       ta.artifact_gate_status,
       ta.artifact_payload,
       ta.quality_summary,
       ta.metadata,
       ta.created_at,
       ta.updated_at
  from prop4you_matrix.transformation_artifacts ta
  join prop4you_matrix.mapping_sessions ms on ms.id = ta.mapping_session_id
  join prop4you_leadfinder.canonical_dictionary_versions cdv on cdv.id = ta.dictionary_version_id
  left join prop4you_provider.providers p on p.id = ta.provider_id
  left join prop4you_provider.payload_classes pc on pc.id = ta.payload_class_id
 where ta.artifact_kind = 'field_mapping_set'
   and ta.deleted = false;

comment on view prop4you_matrix.v_field_mapping_set_artifacts is
'Matrix projection for field_mapping_set artifacts. It exposes semantic mapping contracts generated from LeadFinder bridge rows; no raw provider values are stored.';

create or replace function prop4you_matrix.create_field_mapping_set_from_gap_bridges(
  p_dictionary_version_id uuid,
  p_extraction_run_id uuid,
  p_bridge_limit integer default 10,
  p_artifact_key text default null,
  p_actor_id text default null,
  p_metadata jsonb default '{}'::jsonb
)
returns prop4you_matrix.transformation_artifacts
language plpgsql
volatile
as $$
declare
  dictionary_row prop4you_leadfinder.canonical_dictionary_versions;
  run_row prop4you_matrix.raw_path_extraction_runs;
  session_row prop4you_matrix.mapping_sessions;
  artifact_row prop4you_matrix.transformation_artifacts;
  provider_id_value uuid;
  payload_class_id_value uuid;
  effective_limit integer;
  effective_artifact_key text;
  effective_session_key text;
  mapping_payload jsonb;
  mapping_count integer;
  proposed_count integer;
  matched_count integer;
begin
  if p_dictionary_version_id is null then
    raise exception 'dictionary_version_id is required' using errcode = '22023';
  end if;
  if p_extraction_run_id is null then
    raise exception 'extraction_run_id is required' using errcode = '22023';
  end if;

  effective_limit := greatest(1, least(coalesce(p_bridge_limit, 10), 1000));

  select * into dictionary_row
    from prop4you_leadfinder.canonical_dictionary_versions
   where id = p_dictionary_version_id;
  if not found then
    raise exception 'LeadFinder dictionary version not found: %', p_dictionary_version_id using errcode = '22023';
  end if;

  select * into run_row
    from prop4you_matrix.raw_path_extraction_runs
   where id = p_extraction_run_id;
  if not found then
    raise exception 'Matrix raw path extraction run not found: %', p_extraction_run_id using errcode = '22023';
  end if;

  select provider_id, payload_class_id
    into provider_id_value, payload_class_id_value
    from prop4you_leadfinder.raw_evidence_gap_bridges
   where dictionary_version_id = p_dictionary_version_id
     and extraction_run_id = p_extraction_run_id
     and bridge_status in ('candidate','in_review','accepted')
   order by occurrence_count desc, raw_record_count desc, source_path_label
   limit 1;

  select coalesce(jsonb_agg(row_payload order by sort_occurrence desc, sort_raw_records desc, sort_path), '[]'::jsonb),
         count(*)::integer,
         count(*) filter (where row_payload->>'target_mode' = 'proposed')::integer,
         count(*) filter (where row_payload->>'target_mode' = 'canonical_match')::integer
    into mapping_payload, mapping_count, proposed_count, matched_count
    from (
      select b.occurrence_count as sort_occurrence,
             b.raw_record_count as sort_raw_records,
             b.source_path_label as sort_path,
             jsonb_build_object(
               'bridge_id', b.id,
               'bridge_public_ref', b.public_ref,
               'source_path', b.source_path,
               'source_path_label', b.source_path_label,
               'observed_json_type', b.observed_json_type,
               'occurrence_count', b.occurrence_count,
               'raw_record_count', b.raw_record_count,
               'target_mode', case when b.canonical_field_id is not null then 'canonical_match' else 'proposed' end,
               'canonical_family_id', b.canonical_family_id,
               'canonical_field_id', b.canonical_field_id,
               'proposed_family_key', b.proposed_family_key,
               'proposed_field_key', b.proposed_field_key,
               'semantic_target', jsonb_build_object(
                 'family_key', coalesce(lf.family_key, b.proposed_family_key),
                 'field_key', coalesce(lff.field_key, b.proposed_field_key)
               ),
               'transform_policy', jsonb_build_object(
                 'phase', 'T3_5_field_mapping_set',
                 'sourcehub_dto_publication', 'T4_later',
                 'leadfinder_materialization', 'T5_later',
                 'value_policy', 'no_raw_values',
                 'default_transform', 'copy_normalized_after_review'
               )
             ) as row_payload
        from prop4you_leadfinder.raw_evidence_gap_bridges b
        left join prop4you_leadfinder.canonical_families lf on lf.id = b.canonical_family_id
        left join prop4you_leadfinder.canonical_fields lff on lff.id = b.canonical_field_id
       where b.dictionary_version_id = p_dictionary_version_id
         and b.extraction_run_id = p_extraction_run_id
         and b.bridge_status in ('candidate','in_review','accepted')
       order by b.occurrence_count desc, b.raw_record_count desc, b.source_path_label
       limit effective_limit
    ) s;

  if mapping_count = 0 then
    raise exception 'no bridge rows found for dictionary %, extraction run %', p_dictionary_version_id, p_extraction_run_id using errcode = '22023';
  end if;

  effective_artifact_key := coalesce(nullif(btrim(p_artifact_key), ''), 'field_mapping_set.raw_path.' || replace(p_extraction_run_id::text, '-', ''));
  if effective_artifact_key !~ '^[a-z][a-z0-9_.:-]{1,159}$' then
    raise exception 'invalid field_mapping_set artifact_key: %', effective_artifact_key using errcode = '22023';
  end if;
  if exists (select 1 from prop4you_matrix.transformation_artifacts where artifact_key = effective_artifact_key and artifact_kind <> 'field_mapping_set') then
    raise exception 'artifact_key already belongs to non-field_mapping_set artifact: %', effective_artifact_key using errcode = '23505';
  end if;

  effective_session_key := 'field_mapping_set.raw_path.' || replace(p_extraction_run_id::text, '-', '');

  insert into prop4you_matrix.mapping_sessions as ms (
    dictionary_version_id, provider_id, payload_class_id, session_key,
    session_status, session_purpose, artifact_gate_status,
    input_scope, extraction_summary, review_summary,
    started_at, completed_at, created_by_actor_id, metadata
  ) values (
    p_dictionary_version_id, provider_id_value, payload_class_id_value, effective_session_key,
    'completed', 'artifact_generation', 'ready_for_review',
    jsonb_build_object('extraction_run_id', p_extraction_run_id, 'bridge_limit', effective_limit, 'phase', 'T3_5_field_mapping_set'),
    jsonb_build_object('mapping_count', mapping_count, 'proposed_count', proposed_count, 'matched_count', matched_count),
    'Generate Matrix field_mapping_set from LeadFinder bridge rows; gateway agnostic; no SourceHub DTO publication yet.',
    now(), now(), p_actor_id,
    jsonb_build_object('gateway_agnostic', true, 'raw_dual_role', jsonb_build_array('lfg_app_modeling','canonical_dictionary_generation')) || coalesce(p_metadata, '{}'::jsonb)
  ) on conflict (session_key) do update
    set session_status = excluded.session_status,
        artifact_gate_status = excluded.artifact_gate_status,
        extraction_summary = excluded.extraction_summary,
        review_summary = excluded.review_summary,
        metadata = excluded.metadata,
        updated_at = now(),
        last_modified_by_actor_id = p_actor_id
  returning * into session_row;

  insert into prop4you_matrix.transformation_artifacts as ta (
    mapping_session_id, dictionary_version_id, provider_id, payload_class_id,
    artifact_key, artifact_kind, artifact_status, artifact_schema_version,
    artifact_payload, quality_summary, artifact_gate_status,
    generated_by_actor_id, metadata, last_modified_by_actor_id
  ) values (
    session_row.id, p_dictionary_version_id, provider_id_value, payload_class_id_value,
    effective_artifact_key, 'field_mapping_set', 'generated', 'matrix.field_mapping_set.raw_path.v0',
    jsonb_build_object(
      'contract', 'matrix.field_mapping_set.raw_path.v0',
      'artifact_kind', 'field_mapping_set',
      'gateway_agnostic', true,
      'raw_dual_role', jsonb_build_array('lfg_app_modeling','canonical_dictionary_generation'),
      'sourcehub_dependency', 'SourceHub translated DTO publication must reference this artifact after review.',
      'temporal_phase', jsonb_build_object('raw_capture','T0','extraction','T1','gap_bridge','T2','quality_report','T3','field_mapping_set','T3_5','sourcehub_dto','T4_later','lfg_materialization','T5_later'),
      'extraction_run_id', p_extraction_run_id,
      'dictionary_version_id', p_dictionary_version_id,
      'mappings', mapping_payload
    ),
    jsonb_build_object('mapping_count', mapping_count, 'proposed_count', proposed_count, 'matched_count', matched_count, 'value_policy', 'no_raw_values'),
    'ready_for_review',
    p_actor_id,
    jsonb_build_object('source', 'prop4you_matrix.create_field_mapping_set_from_gap_bridges', 'no_provider_calls', true, 'no_raw_values', true) || coalesce(p_metadata, '{}'::jsonb),
    p_actor_id
  ) on conflict (artifact_key) do update
    set mapping_session_id = excluded.mapping_session_id,
        dictionary_version_id = excluded.dictionary_version_id,
        provider_id = excluded.provider_id,
        payload_class_id = excluded.payload_class_id,
        artifact_status = excluded.artifact_status,
        artifact_schema_version = excluded.artifact_schema_version,
        artifact_payload = excluded.artifact_payload,
        quality_summary = excluded.quality_summary,
        artifact_gate_status = excluded.artifact_gate_status,
        metadata = excluded.metadata,
        updated_at = now(),
        last_modified_by_actor_id = p_actor_id
  returning * into artifact_row;

  return artifact_row;
end;
$$;

comment on function prop4you_matrix.create_field_mapping_set_from_gap_bridges(uuid,uuid,integer,text,text,jsonb) is
'Creates/updates a Matrix field_mapping_set transformation artifact from LeadFinder raw_evidence_gap_bridges. The artifact is gateway-agnostic and stores path/type/count/ref mapping metadata only; no SourceHub DTO publication or LFG materialization is performed.';
