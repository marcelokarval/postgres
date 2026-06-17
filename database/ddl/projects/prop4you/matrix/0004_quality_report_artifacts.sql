-- package: prop4you/matrix
-- file: 0004_quality_report_artifacts.sql
-- status: experimental / non-final
-- purpose: separate Matrix quality_report artifact contract/helper over raw path extraction evidence.
-- depends-on: database/ddl/base, database/ddl/projects/prop4you/0001_schemas.sql, database/ddl/projects/prop4you/providers/0001_provider_registry.sql, database/ddl/projects/prop4you/sourcehub/0001_sourcehub_corpus.sql, database/ddl/projects/prop4you/leadfinder/0001_canonical_dictionary.sql, database/ddl/projects/prop4you/matrix/0002_mapping_sessions.sql, database/ddl/projects/prop4you/matrix/0003_raw_path_extractors.sql
-- idempotency: idempotent
-- destructive: false
-- review-gate: matrix_quality_report_gate
-- [MATRIX_QUALITY_REPORT_SEPARATE] quality_report is a Matrix transformation_artifacts artifact_kind, not a LeadFinder bridge row and not SourceHub DTO publication.
-- [LEADFINDER_DICTIONARY_FK] quality_report artifacts reference prop4you_leadfinder.canonical_dictionary_versions through transformation_artifacts/mapping_sessions.
-- [NO_FIXTURES] This DDL creates functions/views only; it does not insert raw/fake/redacted payload fixtures or provider sample values.
-- [NO_PROVIDER_CALLS] This DDL contains no provider client, HTTP call, runtime lookup, enrichment implementation, or external file access.
-- [NO_RAW_VALUES] The helper copies only path labels, JSON types, counts, refs, and phase metadata from extractor evidence; it never copies raw scalar payload values.

create schema if not exists prop4you_matrix;
comment on schema prop4you_matrix is
'Prop4You Matrix schema. Experimental non-final mapping review, transformation artifact, raw path extraction, provider path, LeadFinder dictionary alignment, and separate quality_report artifact boundary. Matrix stores path/type/count evidence only and does not own raw provider values.';

create or replace view prop4you_matrix.v_quality_report_artifacts as
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
 where ta.artifact_kind = 'quality_report'
   and ta.deleted = false;

comment on view prop4you_matrix.v_quality_report_artifacts is
'Separate Matrix read projection for transformation_artifacts rows whose artifact_kind is quality_report. It exposes non-secret artifact metadata, path/type/count payloads, and quality summaries only; raw provider values remain in SourceHub.';
comment on column prop4you_matrix.v_quality_report_artifacts.artifact_payload is 'Quality report JSONB contract with extraction run refs, phase labels, path/type/count aggregates, and review checklist; no raw payload scalar values belong here.';
comment on column prop4you_matrix.v_quality_report_artifacts.quality_summary is 'Non-secret aggregate quality metrics derived from Matrix raw path extraction evidence.';

create or replace function prop4you_matrix.create_raw_path_quality_report_artifact(
  p_raw_path_extraction_run_id uuid,
  p_dictionary_version_id uuid,
  p_artifact_key text default null,
  p_actor_id text default null,
  p_metadata jsonb default '{}'::jsonb
)
returns prop4you_matrix.transformation_artifacts
language plpgsql
volatile
as $$
declare
  run_row prop4you_matrix.raw_path_extraction_runs;
  dictionary_row prop4you_leadfinder.canonical_dictionary_versions;
  session_row prop4you_matrix.mapping_sessions;
  artifact_row prop4you_matrix.transformation_artifacts;
  effective_artifact_key text;
  effective_session_key text;
  effective_status text;
  effective_session_status text;
  effective_gate_status text;
  path_type_summary jsonb;
  top_path_evidence jsonb;
  quality_payload jsonb;
  summary_payload jsonb;
begin
  if p_raw_path_extraction_run_id is null then
    raise exception 'raw_path_extraction_run_id is required' using errcode = '22023';
  end if;

  if p_dictionary_version_id is null then
    raise exception 'dictionary_version_id is required' using errcode = '22023';
  end if;

  select *
    into run_row
    from prop4you_matrix.raw_path_extraction_runs
   where id = p_raw_path_extraction_run_id;

  if not found then
    raise exception 'raw path extraction run not found: %', p_raw_path_extraction_run_id using errcode = '22023';
  end if;

  select *
    into dictionary_row
    from prop4you_leadfinder.canonical_dictionary_versions
   where id = p_dictionary_version_id;

  if not found then
    raise exception 'LeadFinder dictionary version not found: %', p_dictionary_version_id using errcode = '22023';
  end if;

  effective_artifact_key := coalesce(
    nullif(btrim(p_artifact_key), ''),
    'quality_report.raw_path.' || replace(run_row.id::text, '-', '')
  );

  if effective_artifact_key !~ '^[a-z][a-z0-9_.:-]{1,159}$' then
    raise exception 'invalid Matrix quality_report artifact_key: %', effective_artifact_key using errcode = '22023';
  end if;

  if exists (
    select 1
      from prop4you_matrix.transformation_artifacts ta
     where ta.artifact_key = effective_artifact_key
       and ta.artifact_kind <> 'quality_report'
  ) then
    raise exception 'artifact_key already belongs to a non-quality_report artifact: %', effective_artifact_key using errcode = '23505';
  end if;

  effective_session_key := 'quality_report.raw_path.' || replace(run_row.id::text, '-', '');

  if run_row.run_status = 'completed' and run_row.extracted_path_count > 0 and run_row.distinct_path_count > 0 then
    effective_status := 'generated';
    effective_session_status := 'completed';
    effective_gate_status := 'ready_for_review';
  else
    effective_status := 'blocked';
    effective_session_status := 'blocked';
    effective_gate_status := 'blocked';
  end if;

  select coalesce(
           jsonb_agg(
             jsonb_build_object(
               'observed_json_type', observed_json_type,
               'path_count', path_count,
               'occurrence_count', occurrence_count,
               'raw_record_count', raw_record_count
             ) order by occurrence_count desc, raw_record_count desc, observed_json_type
           ),
           '[]'::jsonb
         )
    into path_type_summary
    from (
      select observed_json_type,
             count(*)::bigint as path_count,
             coalesce(sum(occurrence_count), 0)::bigint as occurrence_count,
             coalesce(sum(raw_record_count), 0)::bigint as raw_record_count
        from prop4you_matrix.raw_path_summary_evidence
       where extraction_run_id = run_row.id
       group by observed_json_type
    ) s;

  select coalesce(
           jsonb_agg(
             jsonb_build_object(
               'source_path_label', source_path_label,
               'observed_json_type', observed_json_type,
               'occurrence_count', occurrence_count,
               'raw_record_count', raw_record_count,
               'first_captured_at', first_captured_at,
               'last_captured_at', last_captured_at
             ) order by occurrence_count desc, raw_record_count desc, source_path_label, observed_json_type
           ),
           '[]'::jsonb
         )
    into top_path_evidence
    from (
      select source_path_label,
             observed_json_type,
             occurrence_count,
             raw_record_count,
             first_captured_at,
             last_captured_at
        from prop4you_matrix.raw_path_summary_evidence
       where extraction_run_id = run_row.id
       order by occurrence_count desc, raw_record_count desc, source_path_label, observed_json_type
       limit 200
    ) s;

  summary_payload := jsonb_build_object(
    'quality_report_contract', 'matrix.quality_report.raw_path.v0',
    'value_policy', 'no_raw_values',
    'run_status', run_row.run_status,
    'source_record_count', run_row.source_record_count,
    'extracted_path_count', run_row.extracted_path_count,
    'distinct_path_count', run_row.distinct_path_count,
    'path_type_summary', path_type_summary,
    'gate_status', effective_gate_status,
    'review_required', true
  );

  quality_payload := jsonb_build_object(
    'contract', 'matrix.quality_report.raw_path.v0',
    'artifact_kind', 'quality_report',
    'temporal_phase', jsonb_build_object(
      'raw_observation', 'T0',
      'raw_path_extraction', 'T1',
      'leadfinder_gap_bridge', 'T2_separate_optional',
      'matrix_quality_report', 'T3',
      'sourcehub_dto_publication', 'T4_later',
      'leadfinder_materialization', 'T5_later'
    ),
    'boundaries', jsonb_build_object(
      'owner_schema', 'prop4you_matrix',
      'storage_table', 'prop4you_matrix.transformation_artifacts',
      'leadfinder_bridge_embedded', false,
      'sourcehub_dto_publication', false,
      'provider_calls', false,
      'raw_values', false
    ),
    'dictionary_version', jsonb_build_object(
      'id', dictionary_row.id,
      'version_key', dictionary_row.version_key,
      'status', dictionary_row.version_status
    ),
    'raw_path_extraction_run', jsonb_build_object(
      'id', run_row.id,
      'public_ref', run_row.public_ref,
      'run_key', run_row.run_key,
      'run_status', run_row.run_status,
      'provider_id', run_row.provider_id,
      'payload_class_id', run_row.payload_class_id,
      'max_depth', run_row.max_depth,
      'started_at', run_row.started_at,
      'completed_at', run_row.completed_at
    ),
    'aggregate_counts', jsonb_build_object(
      'source_record_count', run_row.source_record_count,
      'extracted_path_count', run_row.extracted_path_count,
      'distinct_path_count', run_row.distinct_path_count
    ),
    'path_type_summary', path_type_summary,
    'top_path_evidence', top_path_evidence,
    'review_checklist', jsonb_build_array(
      'confirm_path_labels_do_not_contain_raw_scalar_values',
      'confirm_dictionary_version_scope_matches_review_intent',
      'confirm_blocked_gate_when_extraction_has_no_evidence',
      'confirm_no_sourcehub_dto_publication_is_implied',
      'confirm_no_leadfinder_materialization_is_implied'
    )
  );

  insert into prop4you_matrix.mapping_sessions as ms (
    session_key,
    dictionary_version_id,
    provider_id,
    payload_class_id,
    session_status,
    session_purpose,
    artifact_gate_status,
    input_scope,
    extraction_summary,
    review_summary,
    started_at,
    completed_at,
    created_by_actor_id,
    metadata,
    active,
    activated_at,
    last_modified_by_actor_id
  ) values (
    effective_session_key,
    dictionary_row.id,
    run_row.provider_id,
    run_row.payload_class_id,
    effective_session_status,
    'artifact_generation',
    effective_gate_status,
    jsonb_build_object(
      'source', 'prop4you_matrix.raw_path_extraction_runs',
      'raw_path_extraction_run_id', run_row.id,
      'raw_path_extraction_run_public_ref', run_row.public_ref,
      'value_policy', 'no_raw_values'
    ),
    summary_payload,
    'Separate Matrix quality_report artifact generated from raw path/type/count evidence; no raw provider values copied.',
    run_row.started_at,
    coalesce(run_row.completed_at, now()),
    nullif(btrim(p_actor_id), ''),
    coalesce(p_metadata, '{}'::jsonb) || jsonb_build_object('helper_function', 'prop4you_matrix.create_raw_path_quality_report_artifact'),
    true,
    now(),
    nullif(btrim(p_actor_id), '')
  )
  on conflict (session_key) do update
    set dictionary_version_id = excluded.dictionary_version_id,
        provider_id = excluded.provider_id,
        payload_class_id = excluded.payload_class_id,
        session_status = excluded.session_status,
        session_purpose = excluded.session_purpose,
        artifact_gate_status = excluded.artifact_gate_status,
        input_scope = excluded.input_scope,
        extraction_summary = excluded.extraction_summary,
        review_summary = excluded.review_summary,
        started_at = excluded.started_at,
        completed_at = excluded.completed_at,
        created_by_actor_id = excluded.created_by_actor_id,
        metadata = excluded.metadata,
        active = true,
        deactivated_at = null,
        updated_at = now(),
        last_modified_by_actor_id = excluded.last_modified_by_actor_id,
        version = ms.version + 1
  returning * into session_row;

  insert into prop4you_matrix.transformation_artifacts as ta (
    mapping_session_id,
    dictionary_version_id,
    provider_id,
    payload_class_id,
    artifact_key,
    artifact_kind,
    artifact_status,
    artifact_schema_version,
    artifact_payload,
    quality_summary,
    artifact_gate_status,
    generated_by_actor_id,
    metadata,
    active,
    activated_at,
    last_modified_by_actor_id
  ) values (
    session_row.id,
    dictionary_row.id,
    run_row.provider_id,
    run_row.payload_class_id,
    effective_artifact_key,
    'quality_report',
    effective_status,
    'matrix.quality_report.raw_path.v0',
    quality_payload,
    summary_payload,
    effective_gate_status,
    nullif(btrim(p_actor_id), ''),
    coalesce(p_metadata, '{}'::jsonb) || jsonb_build_object(
      'helper_function', 'prop4you_matrix.create_raw_path_quality_report_artifact',
      'raw_path_extraction_run_id', run_row.id,
      'raw_path_extraction_run_public_ref', run_row.public_ref,
      'value_policy', 'no_raw_values'
    ),
    true,
    now(),
    nullif(btrim(p_actor_id), '')
  )
  on conflict (artifact_key) do update
    set mapping_session_id = excluded.mapping_session_id,
        dictionary_version_id = excluded.dictionary_version_id,
        provider_id = excluded.provider_id,
        payload_class_id = excluded.payload_class_id,
        artifact_kind = 'quality_report',
        artifact_status = excluded.artifact_status,
        artifact_schema_version = excluded.artifact_schema_version,
        artifact_payload = excluded.artifact_payload,
        quality_summary = excluded.quality_summary,
        artifact_gate_status = excluded.artifact_gate_status,
        generated_by_actor_id = excluded.generated_by_actor_id,
        metadata = excluded.metadata,
        active = true,
        deactivated_at = null,
        updated_at = now(),
        last_modified_by_actor_id = excluded.last_modified_by_actor_id,
        version = ta.version + 1
  returning * into artifact_row;

  return artifact_row;
end;
$$;

comment on function prop4you_matrix.create_raw_path_quality_report_artifact(uuid,uuid,text,text,jsonb) is
'Idempotently creates or refreshes a separate Matrix transformation_artifacts artifact_kind=quality_report from one raw_path_extraction_runs row and one LeadFinder dictionary version. The contract stores path labels, JSON types, counts, refs, and phase metadata only; it performs no provider calls, creates no fixtures, does not embed LeadFinder bridge records, and never copies raw scalar values.';
