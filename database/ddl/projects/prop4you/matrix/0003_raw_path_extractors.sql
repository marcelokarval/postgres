-- package: prop4you/matrix
-- file: 0003_raw_path_extractors.sql
-- status: experimental / non-final
-- purpose: safe Matrix raw path extraction summaries over SourceHub raw_records for LeadFinder modeling evidence.
-- depends-on: database/ddl/base, database/ddl/projects/prop4you/0001_schemas.sql, database/ddl/projects/prop4you/providers/0001_provider_registry.sql, database/ddl/projects/prop4you/sourcehub/0001_sourcehub_corpus.sql, database/ddl/projects/prop4you/matrix/0001_semantic_dictionary.sql
-- idempotency: idempotent
-- destructive: false
-- review-gate: provider_payload_corpus_review
-- [NO_FIXTURES] This DDL creates structures, views, and extractor functions only; it does not insert raw/fake/redacted payload fixtures.
-- [NO_PROVIDER_CALLS] This DDL contains no provider client, HTTP call, runtime lookup, enrichment implementation, or external file access.
-- [NO_RAW_VALUES] Extractors expose JSONB paths, JSONB types, counts, hashes/refs, and aggregate evidence only; they never return scalar raw payload values.

create schema if not exists prop4you_matrix;
comment on schema prop4you_matrix is
'Prop4You Matrix schema. Experimental non-final mapping review, transformation artifact, raw path extraction, provider path, and LeadFinder dictionary alignment boundary. Matrix stores path/type/count evidence only and does not own raw provider values.';

create or replace function prop4you_matrix.jsonb_path_label(path text[])
returns text
language sql
immutable
strict
as $$
  select '$' || coalesce(
    string_agg(
      case
        when elem ~ '^[0-9]+$' then '[' || elem || ']'
        when elem ~ '^[A-Za-z_][A-Za-z0-9_]*$' then '.' || elem
        else '[' || to_jsonb(elem)::text || ']'
      end,
      '' order by ordinality
    ),
    ''
  )
  from unnest(path) with ordinality as u(elem, ordinality)
$$;

comment on function prop4you_matrix.jsonb_path_label(text[]) is
'Formats a PostgreSQL text[] JSONB path as a reviewer-friendly label such as $.owner.name or $.items[0]. It formats path components only and never reads or returns raw payload values.';

create table if not exists prop4you_matrix.raw_path_extraction_runs (
  id uuid primary key default uuidv7(),
  public_ref text generated always as (base.make_public_ref('p4yrpe', id)) stored,
  run_key text not null,
  run_status text not null default 'running',
  provider_id uuid references prop4you_provider.providers(id) on delete restrict,
  payload_class_id uuid references prop4you_provider.payload_classes(id) on delete restrict,
  max_depth integer not null default 8,
  source_record_count bigint not null default 0,
  extracted_path_count bigint not null default 0,
  distinct_path_count bigint not null default 0,
  started_at timestamptz not null default now(),
  completed_at timestamptz,
  created_by_actor_id text,
  evidence_summary jsonb not null default '{}'::jsonb,
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint raw_path_extraction_runs_public_ref_key unique (public_ref),
  constraint raw_path_extraction_runs_run_key_key unique (run_key),
  constraint raw_path_extraction_runs_run_key_format_chk check (run_key ~ '^[a-z][a-z0-9_.:-]{1,159}$'),
  constraint raw_path_extraction_runs_status_chk check (run_status in ('running','completed','blocked','failed','superseded')),
  constraint raw_path_extraction_runs_max_depth_chk check (max_depth between 1 and 32),
  constraint raw_path_extraction_runs_counts_chk check (source_record_count >= 0 and extracted_path_count >= 0 and distinct_path_count >= 0),
  constraint raw_path_extraction_runs_completed_after_started_chk check (completed_at is null or completed_at >= started_at),
  constraint raw_path_extraction_runs_evidence_summary_object_chk check (jsonb_typeof(evidence_summary) = 'object'),
  constraint raw_path_extraction_runs_metadata_object_chk check (jsonb_typeof(metadata) = 'object')
);

create index if not exists raw_path_extraction_runs_status_idx
  on prop4you_matrix.raw_path_extraction_runs (run_status, started_at desc);
create index if not exists raw_path_extraction_runs_provider_payload_idx
  on prop4you_matrix.raw_path_extraction_runs (provider_id, payload_class_id, started_at desc)
  where provider_id is not null;
create index if not exists raw_path_extraction_runs_evidence_summary_gin_idx
  on prop4you_matrix.raw_path_extraction_runs using gin (evidence_summary jsonb_path_ops);
create index if not exists raw_path_extraction_runs_metadata_gin_idx
  on prop4you_matrix.raw_path_extraction_runs using gin (metadata jsonb_path_ops);

comment on table prop4you_matrix.raw_path_extraction_runs is
'Experimental Matrix lab run header for safe extraction of JSONB path/type/count evidence from SourceHub raw_records. It stores filters and aggregate counts only; raw payload values remain in SourceHub and are not copied.';
comment on column prop4you_matrix.raw_path_extraction_runs.id is 'UUIDv7 primary key for one raw path extraction run.';
comment on column prop4you_matrix.raw_path_extraction_runs.public_ref is 'Generated public reference with p4yrpe prefix for logs and review artifacts.';
comment on column prop4you_matrix.raw_path_extraction_runs.run_key is 'Stable reviewer/tool-defined key for idempotently refreshing one extraction run.';
comment on column prop4you_matrix.raw_path_extraction_runs.run_status is 'Run lifecycle status: running, completed, blocked, failed, or superseded.';
comment on column prop4you_matrix.raw_path_extraction_runs.provider_id is 'Optional provider/origin filter applied to SourceHub raw_records during extraction.';
comment on column prop4you_matrix.raw_path_extraction_runs.payload_class_id is 'Optional payload class filter applied to SourceHub raw_records during extraction.';
comment on column prop4you_matrix.raw_path_extraction_runs.max_depth is 'Maximum JSON traversal depth passed to prop4you_provider.jsonb_leaf_paths for this run.';
comment on column prop4you_matrix.raw_path_extraction_runs.source_record_count is 'Count of active, non-deleted SourceHub raw_records in scope for this run.';
comment on column prop4you_matrix.raw_path_extraction_runs.extracted_path_count is 'Total extracted leaf/type observations across in-scope raw records; this is count evidence, not value evidence.';
comment on column prop4you_matrix.raw_path_extraction_runs.distinct_path_count is 'Number of distinct JSONB paths observed in this run, independent of raw scalar values.';
comment on column prop4you_matrix.raw_path_extraction_runs.started_at is 'Timestamp when the extraction run row was started or refreshed.';
comment on column prop4you_matrix.raw_path_extraction_runs.completed_at is 'Timestamp when aggregate path evidence was refreshed, if completed.';
comment on column prop4you_matrix.raw_path_extraction_runs.created_by_actor_id is 'Optional reviewer/tool actor identifier that initiated the run; not an authentication contract.';
comment on column prop4you_matrix.raw_path_extraction_runs.evidence_summary is 'Non-secret JSONB aggregate evidence summary such as record counts, path counts, provider labels, and payload class labels. It must not contain raw payload values.';
comment on column prop4you_matrix.raw_path_extraction_runs.metadata is 'Non-secret JSONB run metadata and reviewer labels. It must not contain provider secrets, PII, or raw payload fragments.';
comment on column prop4you_matrix.raw_path_extraction_runs.created_at is 'Timestamp when this extraction run row was inserted.';
comment on column prop4you_matrix.raw_path_extraction_runs.updated_at is 'Timestamp when this extraction run row was last updated.';

create table if not exists prop4you_matrix.raw_path_summary_evidence (
  id uuid primary key default uuidv7(),
  extraction_run_id uuid not null references prop4you_matrix.raw_path_extraction_runs(id) on delete cascade,
  provider_id uuid not null references prop4you_provider.providers(id) on delete restrict,
  payload_class_id uuid not null references prop4you_provider.payload_classes(id) on delete restrict,
  source_path text[] not null,
  source_path_label text not null,
  observed_json_type text not null,
  occurrence_count bigint not null,
  raw_record_count bigint not null,
  first_captured_at timestamptz,
  last_captured_at timestamptz,
  max_depth integer not null,
  evidence_summary jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint raw_path_summary_evidence_run_path_type_key unique (extraction_run_id, provider_id, payload_class_id, source_path, observed_json_type),
  constraint raw_path_summary_evidence_source_path_not_empty_chk check (cardinality(source_path) > 0),
  constraint raw_path_summary_evidence_json_type_chk check (observed_json_type in ('object','array','string','number','boolean','null','unknown','mixed')),
  constraint raw_path_summary_evidence_counts_chk check (occurrence_count > 0 and raw_record_count > 0 and occurrence_count >= raw_record_count),
  constraint raw_path_summary_evidence_max_depth_chk check (max_depth between 1 and 32),
  constraint raw_path_summary_evidence_captured_order_chk check (last_captured_at is null or first_captured_at is null or last_captured_at >= first_captured_at),
  constraint raw_path_summary_evidence_summary_object_chk check (jsonb_typeof(evidence_summary) = 'object')
);

create index if not exists raw_path_summary_evidence_run_count_idx
  on prop4you_matrix.raw_path_summary_evidence (extraction_run_id, occurrence_count desc, raw_record_count desc);
create index if not exists raw_path_summary_evidence_provider_payload_path_idx
  on prop4you_matrix.raw_path_summary_evidence (provider_id, payload_class_id, source_path);
create index if not exists raw_path_summary_evidence_json_type_idx
  on prop4you_matrix.raw_path_summary_evidence (observed_json_type, occurrence_count desc);
create index if not exists raw_path_summary_evidence_summary_gin_idx
  on prop4you_matrix.raw_path_summary_evidence using gin (evidence_summary jsonb_path_ops);

comment on table prop4you_matrix.raw_path_summary_evidence is
'Experimental Matrix aggregate evidence table for SourceHub raw_records JSONB paths. Rows store provider, payload class, source path, observed JSON type, and counts only; no raw scalar values are stored.';
comment on column prop4you_matrix.raw_path_summary_evidence.id is 'UUIDv7 primary key for one aggregate path/type evidence row.';
comment on column prop4you_matrix.raw_path_summary_evidence.extraction_run_id is 'Extraction run that produced or refreshed this aggregate evidence row.';
comment on column prop4you_matrix.raw_path_summary_evidence.provider_id is 'Provider or internal origin observed for this aggregate path evidence.';
comment on column prop4you_matrix.raw_path_summary_evidence.payload_class_id is 'Payload class observed for this aggregate path evidence.';
comment on column prop4you_matrix.raw_path_summary_evidence.source_path is 'PostgreSQL text[] JSONB source path components; array indexes are numeric strings for review.';
comment on column prop4you_matrix.raw_path_summary_evidence.source_path_label is 'Reviewer-friendly JSONB path label generated from source_path; it contains path components only, not raw values.';
comment on column prop4you_matrix.raw_path_summary_evidence.observed_json_type is 'Observed JSONB type at source_path: object, array, string, number, boolean, null, unknown, or mixed.';
comment on column prop4you_matrix.raw_path_summary_evidence.occurrence_count is 'Number of leaf/type observations for this provider, payload class, path, and type across in-scope raw records.';
comment on column prop4you_matrix.raw_path_summary_evidence.raw_record_count is 'Number of distinct SourceHub raw_records contributing this provider, payload class, path, and type evidence.';
comment on column prop4you_matrix.raw_path_summary_evidence.first_captured_at is 'Earliest captured_at timestamp among contributing SourceHub raw_records.';
comment on column prop4you_matrix.raw_path_summary_evidence.last_captured_at is 'Latest captured_at timestamp among contributing SourceHub raw_records.';
comment on column prop4you_matrix.raw_path_summary_evidence.max_depth is 'Maximum traversal depth used when extracting this evidence row.';
comment on column prop4you_matrix.raw_path_summary_evidence.evidence_summary is 'Non-secret JSONB aggregate evidence such as sample public refs or lineage labels; it must not contain raw provider values or PII values.';
comment on column prop4you_matrix.raw_path_summary_evidence.created_at is 'Timestamp when this aggregate evidence row was inserted.';
comment on column prop4you_matrix.raw_path_summary_evidence.updated_at is 'Timestamp when this aggregate evidence row was last updated.';

create or replace view prop4you_matrix.v_raw_record_leaf_path_evidence as
select rr.id as raw_record_id,
       rr.public_ref as raw_record_public_ref,
       rr.provider_id,
       p.provider_key,
       rr.payload_class_id,
       pc.class_key as payload_class_key,
       rr.provider_payload_class_id,
       rr.ingress_status,
       rr.review_status,
       rr.matrix_mapping_status,
       rr.privacy_classification,
       rr.contains_personal_data,
       rr.captured_at,
       lp.path as source_path,
       prop4you_matrix.jsonb_path_label(lp.path) as source_path_label,
       lp.value_type as observed_json_type
  from prop4you_sourcehub.raw_records rr
  join prop4you_provider.providers p on p.id = rr.provider_id
  join prop4you_provider.payload_classes pc on pc.id = rr.payload_class_id
  cross join lateral prop4you_provider.jsonb_leaf_paths(rr.raw_payload, 8) as lp(path, value_type)
 where rr.active = true
   and rr.deleted = false
   and cardinality(lp.path) > 0;

comment on view prop4you_matrix.v_raw_record_leaf_path_evidence is
'Safe Matrix lab view of SourceHub raw_records leaf JSONB path/type evidence at default depth 8. It exposes raw record refs, provider/payload labels, paths, and JSON types only; it never exposes raw_payload or scalar values.';
comment on column prop4you_matrix.v_raw_record_leaf_path_evidence.raw_record_id is 'SourceHub raw_records UUID that contains the path evidence; raw payload values are not exposed.';
comment on column prop4you_matrix.v_raw_record_leaf_path_evidence.raw_record_public_ref is 'Generated SourceHub public reference for review logs without exposing raw values.';
comment on column prop4you_matrix.v_raw_record_leaf_path_evidence.provider_id is 'Provider/origin UUID for the raw record.';
comment on column prop4you_matrix.v_raw_record_leaf_path_evidence.provider_key is 'Stable provider/origin key for grouping path evidence.';
comment on column prop4you_matrix.v_raw_record_leaf_path_evidence.payload_class_id is 'Payload class UUID for the raw record.';
comment on column prop4you_matrix.v_raw_record_leaf_path_evidence.payload_class_key is 'Stable payload class key for grouping path evidence.';
comment on column prop4you_matrix.v_raw_record_leaf_path_evidence.provider_payload_class_id is 'Optional provider-to-payload-class link copied from SourceHub metadata.';
comment on column prop4you_matrix.v_raw_record_leaf_path_evidence.ingress_status is 'SourceHub ingress status for the raw record contributing the path.';
comment on column prop4you_matrix.v_raw_record_leaf_path_evidence.review_status is 'SourceHub review status for the raw record contributing the path.';
comment on column prop4you_matrix.v_raw_record_leaf_path_evidence.matrix_mapping_status is 'SourceHub Matrix mapping status for the raw record contributing the path.';
comment on column prop4you_matrix.v_raw_record_leaf_path_evidence.privacy_classification is 'SourceHub privacy classification metadata for the raw record; no raw values are exposed.';
comment on column prop4you_matrix.v_raw_record_leaf_path_evidence.contains_personal_data is 'SourceHub personal-data review flag for the raw record; values themselves are not exposed.';
comment on column prop4you_matrix.v_raw_record_leaf_path_evidence.captured_at is 'SourceHub captured_at timestamp used for aggregate evidence windows.';
comment on column prop4you_matrix.v_raw_record_leaf_path_evidence.source_path is 'PostgreSQL text[] JSONB leaf path emitted by prop4you_provider.jsonb_leaf_paths.';
comment on column prop4you_matrix.v_raw_record_leaf_path_evidence.source_path_label is 'Reviewer-friendly label generated from source_path; contains path components only.';
comment on column prop4you_matrix.v_raw_record_leaf_path_evidence.observed_json_type is 'JSONB type observed at source_path; no raw scalar value is included.';

create or replace view prop4you_matrix.v_raw_path_current_summary as
select provider_id,
       provider_key,
       payload_class_id,
       payload_class_key,
       source_path,
       source_path_label,
       observed_json_type,
       count(*)::bigint as occurrence_count,
       count(distinct raw_record_id)::bigint as raw_record_count,
       min(captured_at) as first_captured_at,
       max(captured_at) as last_captured_at
  from prop4you_matrix.v_raw_record_leaf_path_evidence
 group by provider_id,
          provider_key,
          payload_class_id,
          payload_class_key,
          source_path,
          source_path_label,
          observed_json_type;

comment on view prop4you_matrix.v_raw_path_current_summary is
'Live safe aggregate summary of SourceHub raw_records JSONB path/type evidence at default depth 8. The view returns path labels, JSON types, counts, and capture windows only; it never returns raw payload values.';
comment on column prop4you_matrix.v_raw_path_current_summary.provider_id is 'Provider/origin UUID for this aggregate path evidence.';
comment on column prop4you_matrix.v_raw_path_current_summary.provider_key is 'Stable provider/origin key for this aggregate path evidence.';
comment on column prop4you_matrix.v_raw_path_current_summary.payload_class_id is 'Payload class UUID for this aggregate path evidence.';
comment on column prop4you_matrix.v_raw_path_current_summary.payload_class_key is 'Stable payload class key for this aggregate path evidence.';
comment on column prop4you_matrix.v_raw_path_current_summary.source_path is 'PostgreSQL text[] JSONB path components observed in SourceHub raw_records.';
comment on column prop4you_matrix.v_raw_path_current_summary.source_path_label is 'Reviewer-friendly JSONB path label generated from source_path only.';
comment on column prop4you_matrix.v_raw_path_current_summary.observed_json_type is 'Observed JSONB type for this path.';
comment on column prop4you_matrix.v_raw_path_current_summary.occurrence_count is 'Number of path/type observations across active, non-deleted SourceHub raw_records.';
comment on column prop4you_matrix.v_raw_path_current_summary.raw_record_count is 'Number of distinct SourceHub raw_records contributing this path/type evidence.';
comment on column prop4you_matrix.v_raw_path_current_summary.first_captured_at is 'Earliest captured_at timestamp among contributing records.';
comment on column prop4you_matrix.v_raw_path_current_summary.last_captured_at is 'Latest captured_at timestamp among contributing records.';

create or replace function prop4you_matrix.refresh_raw_path_summary_evidence(
  p_run_key text,
  p_provider_id uuid default null,
  p_payload_class_id uuid default null,
  p_max_depth integer default 8,
  p_actor_id text default null,
  p_metadata jsonb default '{}'::jsonb
)
returns prop4you_matrix.raw_path_extraction_runs
language plpgsql
volatile
as $$
declare
  effective_max_depth integer;
  row_out prop4you_matrix.raw_path_extraction_runs;
  record_count bigint;
  extracted_count bigint;
  distinct_count bigint;
begin
  if p_run_key is null or p_run_key !~ '^[a-z][a-z0-9_.:-]{1,159}$' then
    raise exception 'invalid raw path extraction run_key: %', p_run_key using errcode = '22023';
  end if;

  effective_max_depth := least(greatest(coalesce(p_max_depth, 8), 1), 32);

  insert into prop4you_matrix.raw_path_extraction_runs as r (
    run_key,
    run_status,
    provider_id,
    payload_class_id,
    max_depth,
    source_record_count,
    extracted_path_count,
    distinct_path_count,
    started_at,
    completed_at,
    created_by_actor_id,
    evidence_summary,
    metadata
  ) values (
    p_run_key,
    'running',
    p_provider_id,
    p_payload_class_id,
    effective_max_depth,
    0,
    0,
    0,
    now(),
    null,
    nullif(btrim(p_actor_id), ''),
    jsonb_build_object('extractor', 'prop4you_matrix.refresh_raw_path_summary_evidence', 'value_policy', 'no_raw_values'),
    coalesce(p_metadata, '{}'::jsonb)
  )
  on conflict (run_key) do update
    set run_status = 'running',
        provider_id = excluded.provider_id,
        payload_class_id = excluded.payload_class_id,
        max_depth = excluded.max_depth,
        source_record_count = 0,
        extracted_path_count = 0,
        distinct_path_count = 0,
        started_at = now(),
        completed_at = null,
        created_by_actor_id = excluded.created_by_actor_id,
        evidence_summary = excluded.evidence_summary,
        metadata = excluded.metadata,
        updated_at = now()
  returning * into row_out;

  delete from prop4you_matrix.raw_path_summary_evidence
   where extraction_run_id = row_out.id;

  with scoped_records as (
    select rr.id,
           rr.public_ref,
           rr.provider_id,
           rr.payload_class_id,
           rr.captured_at,
           rr.raw_payload
      from prop4you_sourcehub.raw_records rr
     where rr.active = true
       and rr.deleted = false
       and (p_provider_id is null or rr.provider_id = p_provider_id)
       and (p_payload_class_id is null or rr.payload_class_id = p_payload_class_id)
  ), leaf_evidence as (
    select sr.id as raw_record_id,
           sr.public_ref,
           sr.provider_id,
           sr.payload_class_id,
           sr.captured_at,
           lp.path as source_path,
           coalesce(lp.value_type, 'unknown') as observed_json_type
      from scoped_records sr
      cross join lateral prop4you_provider.jsonb_leaf_paths(sr.raw_payload, effective_max_depth) as lp(path, value_type)
     where cardinality(lp.path) > 0
  ), inserted as (
    insert into prop4you_matrix.raw_path_summary_evidence (
      extraction_run_id,
      provider_id,
      payload_class_id,
      source_path,
      source_path_label,
      observed_json_type,
      occurrence_count,
      raw_record_count,
      first_captured_at,
      last_captured_at,
      max_depth,
      evidence_summary
    )
    select row_out.id,
           le.provider_id,
           le.payload_class_id,
           le.source_path,
           prop4you_matrix.jsonb_path_label(le.source_path),
           le.observed_json_type,
           count(*)::bigint,
           count(distinct le.raw_record_id)::bigint,
           min(le.captured_at),
           max(le.captured_at),
           effective_max_depth,
           jsonb_build_object(
             'sample_raw_record_public_refs', jsonb_agg(distinct le.public_ref order by le.public_ref) filter (where le.public_ref is not null),
             'value_policy', 'no_raw_values',
             'extractor', 'prop4you_provider.jsonb_leaf_paths'
           )
      from leaf_evidence le
     group by le.provider_id,
              le.payload_class_id,
              le.source_path,
              le.observed_json_type
    returning occurrence_count, source_path
  )
  select (select count(*)::bigint from scoped_records),
         coalesce(sum(i.occurrence_count), 0)::bigint,
         count(distinct i.source_path)::bigint
    into record_count, extracted_count, distinct_count
    from inserted i;

  update prop4you_matrix.raw_path_extraction_runs r
     set run_status = 'completed',
         source_record_count = coalesce(record_count, 0),
         extracted_path_count = coalesce(extracted_count, 0),
         distinct_path_count = coalesce(distinct_count, 0),
         completed_at = now(),
         evidence_summary = jsonb_build_object(
           'extractor', 'prop4you_matrix.refresh_raw_path_summary_evidence',
           'source_table', 'prop4you_sourcehub.raw_records',
           'helper_function', 'prop4you_provider.jsonb_leaf_paths',
           'type_function', 'prop4you_provider.jsonb_path_type',
           'value_policy', 'no_raw_values',
           'source_record_count', coalesce(record_count, 0),
           'extracted_path_count', coalesce(extracted_count, 0),
           'distinct_path_count', coalesce(distinct_count, 0),
           'max_depth', effective_max_depth
         ),
         updated_at = now()
   where r.id = row_out.id
   returning * into row_out;

  return row_out;
end;
$$;

comment on function prop4you_matrix.refresh_raw_path_summary_evidence(text,uuid,uuid,integer,text,jsonb) is
'Idempotently refreshes safe aggregate JSONB path/type/count evidence from prop4you_sourcehub.raw_records into Matrix tables. It uses prop4you_provider.jsonb_leaf_paths/jsonb_path_type lineage, performs no provider calls, creates no fixtures, and never stores raw scalar values.';

create or replace function prop4you_matrix.raw_record_path_type_evidence(
  p_raw_record_id uuid,
  p_max_depth integer default 8
)
returns table(
  raw_record_id uuid,
  raw_record_public_ref text,
  provider_id uuid,
  provider_key text,
  payload_class_id uuid,
  payload_class_key text,
  source_path text[],
  source_path_label text,
  observed_json_type text
)
language sql
stable
strict
as $$
  select rr.id,
         rr.public_ref,
         rr.provider_id,
         p.provider_key,
         rr.payload_class_id,
         pc.class_key,
         lp.path,
         prop4you_matrix.jsonb_path_label(lp.path),
         prop4you_provider.jsonb_path_type(rr.raw_payload, lp.path)
    from prop4you_sourcehub.raw_records rr
    join prop4you_provider.providers p on p.id = rr.provider_id
    join prop4you_provider.payload_classes pc on pc.id = rr.payload_class_id
    cross join lateral prop4you_provider.jsonb_leaf_paths(rr.raw_payload, least(greatest(coalesce(p_max_depth, 8), 1), 32)) as lp(path, value_type)
   where rr.id = p_raw_record_id
     and rr.active = true
     and rr.deleted = false
     and cardinality(lp.path) > 0
$$;

comment on function prop4you_matrix.raw_record_path_type_evidence(uuid,integer) is
'Returns safe per-record JSONB path/type evidence for one SourceHub raw_record using prop4you_provider.jsonb_leaf_paths and jsonb_path_type. The function returns path labels and JSON types only; it never returns raw payload values.';

select base.register_public_id_prefix('p4yrpe', 'prop4you_matrix', 'raw_path_extraction_runs', 'Prop4You Matrix raw path extraction run');
