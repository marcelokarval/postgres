-- package: prop4you/leadfinder
-- file: 0002_raw_evidence_gap_bridge.sql
-- status: experimental / non-final
-- purpose: LeadFinder-owned bridge from Matrix raw path aggregate evidence and filter pressure into canonical gaps and growth-pressure signals with explicit temporal phase lineage.
-- depends-on: database/ddl/base, database/ddl/projects/prop4you/0001_schemas.sql, database/ddl/projects/prop4you/leadfinder/0001_canonical_dictionary.sql, database/ddl/projects/prop4you/matrix/0003_raw_path_extractors.sql
-- idempotency: idempotent
-- destructive: false
-- review-gate: leadfinder_raw_evidence_gap_bridge
-- [LEADFINDER_OWNS_GAPS] LeadFinder owns canonical gaps and growth-pressure signals created by this bridge. Matrix remains the path/type/count evidence owner.
-- [TEMPORAL_PHASE_EXPLICIT] Every bridge row and generated downstream row carries explicit phase metadata separating raw observation, extraction, gap proposal, quality report, DTO, and materialization phases.
-- [NO_FIXTURES] This DDL creates structures and helper functions only; it does not insert raw/fake/redacted payload fixtures.
-- [NO_PROVIDER_CALLS] This DDL contains no provider client, HTTP call, runtime lookup, enrichment implementation, or external file access.
-- [NO_RAW_VALUES] Bridge structures store path labels, JSON types, counts, refs, hashes, statuses, and review metadata only; raw provider values and PII values do not belong here.

create schema if not exists prop4you_leadfinder;
comment on schema prop4you_leadfinder is
'Prop4You LeadFinder schema. Owns canonical dictionary gaps, growth-pressure signals, and the raw-evidence gap bridge; raw payload values stay outside this schema.';

create table if not exists prop4you_leadfinder.raw_evidence_gap_bridges (
  id uuid primary key default uuidv7(),
  public_ref text generated always as (base.make_public_ref('p4ylfgb', id)) stored,
  dictionary_version_id uuid not null references prop4you_leadfinder.canonical_dictionary_versions(id) on delete restrict,
  extraction_run_id uuid not null references prop4you_matrix.raw_path_extraction_runs(id) on delete restrict,
  summary_evidence_id uuid not null references prop4you_matrix.raw_path_summary_evidence(id) on delete restrict,
  provider_id uuid not null references prop4you_provider.providers(id) on delete restrict,
  payload_class_id uuid not null references prop4you_provider.payload_classes(id) on delete restrict,
  canonical_family_id uuid references prop4you_leadfinder.canonical_families(id) on delete set null,
  canonical_field_id uuid references prop4you_leadfinder.canonical_fields(id) on delete set null,
  canonical_gap_id uuid references prop4you_leadfinder.canonical_gaps(id) on delete set null,
  growth_pressure_signal_id uuid references prop4you_leadfinder.growth_pressure_signals(id) on delete set null,
  proposed_family_key text,
  proposed_field_key text,
  source_path text[] not null,
  source_path_label text not null,
  observed_json_type text not null,
  occurrence_count bigint not null,
  raw_record_count bigint not null,
  evidence_first_captured_at timestamptz,
  evidence_last_captured_at timestamptz,
  temporal_phase text not null,
  bridge_status text not null default 'candidate',
  gap_kind text not null default 'review_needed',
  severity text not null default 'medium',
  pressure_kind text not null default 'repeated_raw_path',
  pressure_level text not null default 'medium',
  filter_pressure_summary jsonb not null default '{}'::jsonb,
  evidence_origin jsonb not null default '{}'::jsonb,
  metadata jsonb not null default '{}'::jsonb,
  proposed_at timestamptz not null default now(),
  created_by_actor_id text,
  reviewed_by_actor_id text,
  reviewed_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint raw_evidence_gap_bridges_public_ref_key unique (public_ref),
  constraint raw_evidence_gap_bridges_identity_key unique nulls not distinct (dictionary_version_id, summary_evidence_id, temporal_phase, canonical_field_id, proposed_family_key, proposed_field_key),
  constraint raw_evidence_gap_bridges_proposed_family_key_format_chk check (proposed_family_key is null or proposed_family_key ~ '^[a-z][a-z0-9_]{1,79}$'),
  constraint raw_evidence_gap_bridges_proposed_field_key_format_chk check (proposed_field_key is null or proposed_field_key ~ '^[a-z][a-z0-9_]{1,79}$'),
  constraint raw_evidence_gap_bridges_target_chk check (
    canonical_field_id is not null
    or (proposed_family_key is not null and proposed_field_key is not null)
  ),
  constraint raw_evidence_gap_bridges_proposed_pair_chk check (
    (proposed_family_key is null and proposed_field_key is null)
    or (proposed_family_key is not null and proposed_field_key is not null)
  ),
  constraint raw_evidence_gap_bridges_source_path_not_empty_chk check (cardinality(source_path) > 0),
  constraint raw_evidence_gap_bridges_json_type_chk check (observed_json_type in ('object','array','string','number','boolean','null','unknown','mixed')),
  constraint raw_evidence_gap_bridges_counts_chk check (occurrence_count > 0 and raw_record_count > 0 and occurrence_count >= raw_record_count),
  constraint raw_evidence_gap_bridges_temporal_phase_chk check (temporal_phase in ('raw_observation','path_extraction','gap_proposal','quality_report','dto_candidate','materialization_candidate')),
  constraint raw_evidence_gap_bridges_status_chk check (bridge_status in ('candidate','in_review','accepted','resolved','deferred','rejected','superseded')),
  constraint raw_evidence_gap_bridges_gap_kind_chk check (gap_kind in ('missing_family','missing_field','ambiguous_meaning','conflicting_sources','materialization_blocked','privacy_boundary','lineage_gap','review_needed')),
  constraint raw_evidence_gap_bridges_severity_chk check (severity in ('low','medium','high','critical')),
  constraint raw_evidence_gap_bridges_pressure_kind_chk check (pressure_kind in ('new_provider_surface','repeated_raw_path','business_rule_pressure','lead_scoring_pressure','contactability_pressure','lineage_pressure','privacy_pressure','review_volume_pressure')),
  constraint raw_evidence_gap_bridges_pressure_level_chk check (pressure_level in ('low','medium','high','critical')),
  constraint raw_evidence_gap_bridges_filter_pressure_object_chk check (jsonb_typeof(filter_pressure_summary) = 'object'),
  constraint raw_evidence_gap_bridges_evidence_origin_object_chk check (jsonb_typeof(evidence_origin) = 'object'),
  constraint raw_evidence_gap_bridges_metadata_object_chk check (jsonb_typeof(metadata) = 'object'),
  constraint raw_evidence_gap_bridges_reviewed_after_created_chk check (reviewed_at is null or reviewed_at >= created_at),
  constraint raw_evidence_gap_bridges_window_order_chk check (evidence_last_captured_at is null or evidence_first_captured_at is null or evidence_last_captured_at >= evidence_first_captured_at)
);

create index if not exists raw_evidence_gap_bridges_dictionary_phase_status_idx
  on prop4you_leadfinder.raw_evidence_gap_bridges (dictionary_version_id, temporal_phase, bridge_status);
create index if not exists raw_evidence_gap_bridges_run_summary_idx
  on prop4you_leadfinder.raw_evidence_gap_bridges (extraction_run_id, summary_evidence_id);
create index if not exists raw_evidence_gap_bridges_provider_payload_idx
  on prop4you_leadfinder.raw_evidence_gap_bridges (provider_id, payload_class_id, occurrence_count desc, raw_record_count desc);
create index if not exists raw_evidence_gap_bridges_canonical_field_idx
  on prop4you_leadfinder.raw_evidence_gap_bridges (canonical_field_id, bridge_status)
  where canonical_field_id is not null;
create index if not exists raw_evidence_gap_bridges_proposed_key_idx
  on prop4you_leadfinder.raw_evidence_gap_bridges (proposed_family_key, proposed_field_key, bridge_status)
  where proposed_family_key is not null;
create index if not exists raw_evidence_gap_bridges_gap_idx
  on prop4you_leadfinder.raw_evidence_gap_bridges (canonical_gap_id)
  where canonical_gap_id is not null;
create index if not exists raw_evidence_gap_bridges_signal_idx
  on prop4you_leadfinder.raw_evidence_gap_bridges (growth_pressure_signal_id)
  where growth_pressure_signal_id is not null;
create index if not exists raw_evidence_gap_bridges_filter_pressure_gin_idx
  on prop4you_leadfinder.raw_evidence_gap_bridges using gin (filter_pressure_summary jsonb_path_ops);
create index if not exists raw_evidence_gap_bridges_evidence_origin_gin_idx
  on prop4you_leadfinder.raw_evidence_gap_bridges using gin (evidence_origin jsonb_path_ops);
create index if not exists raw_evidence_gap_bridges_metadata_gin_idx
  on prop4you_leadfinder.raw_evidence_gap_bridges using gin (metadata jsonb_path_ops);

comment on table prop4you_leadfinder.raw_evidence_gap_bridges is
'LeadFinder-owned bridge from Matrix raw_path_extraction_runs/raw_path_summary_evidence and LeadFinder filter pressure into canonical_gaps and growth_pressure_signals. Stores only path/type/count/ref metadata with explicit temporal phase; no raw payload values.';
comment on column prop4you_leadfinder.raw_evidence_gap_bridges.id is 'UUIDv7 primary key for one LeadFinder raw-evidence gap bridge row.';
comment on column prop4you_leadfinder.raw_evidence_gap_bridges.public_ref is 'Generated public reference with p4ylfgb prefix for logs and reviews.';
comment on column prop4you_leadfinder.raw_evidence_gap_bridges.dictionary_version_id is 'LeadFinder-owned dictionary version being evaluated by this bridge row.';
comment on column prop4you_leadfinder.raw_evidence_gap_bridges.extraction_run_id is 'Matrix raw path extraction run that created the aggregate evidence.';
comment on column prop4you_leadfinder.raw_evidence_gap_bridges.summary_evidence_id is 'Matrix raw path summary evidence row carrying path/type/count evidence.';
comment on column prop4you_leadfinder.raw_evidence_gap_bridges.provider_id is 'Provider/origin copied from Matrix summary evidence for grouping and lineage only.';
comment on column prop4you_leadfinder.raw_evidence_gap_bridges.payload_class_id is 'Payload class copied from Matrix summary evidence for grouping and lineage only.';
comment on column prop4you_leadfinder.raw_evidence_gap_bridges.canonical_family_id is 'Optional matched LeadFinder canonical family when a canonical_field_id is supplied or can be resolved.';
comment on column prop4you_leadfinder.raw_evidence_gap_bridges.canonical_field_id is 'Optional matched LeadFinder canonical field. Null means this bridge represents a proposed new family/field key instead of an existing field match.';
comment on column prop4you_leadfinder.raw_evidence_gap_bridges.canonical_gap_id is 'Optional LeadFinder canonical_gaps row created or linked by bridge helper functions.';
comment on column prop4you_leadfinder.raw_evidence_gap_bridges.growth_pressure_signal_id is 'Optional LeadFinder growth_pressure_signals row created or linked by bridge helper functions.';
comment on column prop4you_leadfinder.raw_evidence_gap_bridges.proposed_family_key is 'Proposed LeadFinder family key when raw evidence has no existing canonical field match; no raw values are stored.';
comment on column prop4you_leadfinder.raw_evidence_gap_bridges.proposed_field_key is 'Proposed LeadFinder field key when raw evidence has no existing canonical field match; no raw values are stored.';
comment on column prop4you_leadfinder.raw_evidence_gap_bridges.source_path is 'PostgreSQL text[] JSONB source path components copied from Matrix aggregate evidence; path components only, no values.';
comment on column prop4you_leadfinder.raw_evidence_gap_bridges.source_path_label is 'Reviewer-friendly JSONB path label copied from Matrix evidence; contains path components only.';
comment on column prop4you_leadfinder.raw_evidence_gap_bridges.observed_json_type is 'Observed JSONB type at source_path from Matrix evidence.';
comment on column prop4you_leadfinder.raw_evidence_gap_bridges.occurrence_count is 'Aggregate occurrence count from Matrix evidence.';
comment on column prop4you_leadfinder.raw_evidence_gap_bridges.raw_record_count is 'Aggregate distinct raw-record count from Matrix evidence.';
comment on column prop4you_leadfinder.raw_evidence_gap_bridges.evidence_first_captured_at is 'Earliest captured_at timestamp from the contributing raw records, as aggregate lineage only.';
comment on column prop4you_leadfinder.raw_evidence_gap_bridges.evidence_last_captured_at is 'Latest captured_at timestamp from the contributing raw records, as aggregate lineage only.';
comment on column prop4you_leadfinder.raw_evidence_gap_bridges.temporal_phase is 'Explicit temporal phase represented by this bridge row: raw_observation, path_extraction, gap_proposal, quality_report, dto_candidate, or materialization_candidate.';
comment on column prop4you_leadfinder.raw_evidence_gap_bridges.bridge_status is 'Review status of the bridge row independent of canonical gap and pressure signal lifecycles.';
comment on column prop4you_leadfinder.raw_evidence_gap_bridges.gap_kind is 'Canonical gap kind to create or link, such as missing_field, missing_family, review_needed, lineage_gap, or privacy_boundary.';
comment on column prop4you_leadfinder.raw_evidence_gap_bridges.severity is 'Reviewer severity assigned to the proposed gap.';
comment on column prop4you_leadfinder.raw_evidence_gap_bridges.pressure_kind is 'Growth-pressure kind created from filter demand or repeated raw path evidence.';
comment on column prop4you_leadfinder.raw_evidence_gap_bridges.pressure_level is 'Priority level for the growth-pressure signal.';
comment on column prop4you_leadfinder.raw_evidence_gap_bridges.filter_pressure_summary is 'Non-secret JSONB summary of LeadFinder filter pressure such as filter keys, demand labels, or counts. Raw/provider values and PII do not belong here.';
comment on column prop4you_leadfinder.raw_evidence_gap_bridges.evidence_origin is 'Non-secret JSONB lineage labels linking Matrix extraction and LeadFinder gap/proposal phases; raw payload values do not belong here.';
comment on column prop4you_leadfinder.raw_evidence_gap_bridges.metadata is 'Non-secret JSONB review metadata for this bridge row.';
comment on column prop4you_leadfinder.raw_evidence_gap_bridges.proposed_at is 'Timestamp when the bridge proposed the LeadFinder gap/signal linkage.';
comment on column prop4you_leadfinder.raw_evidence_gap_bridges.created_by_actor_id is 'Optional reviewer/tool actor identifier that created the bridge row; not an authentication contract.';
comment on column prop4you_leadfinder.raw_evidence_gap_bridges.reviewed_by_actor_id is 'Optional reviewer actor identifier for bridge review.';
comment on column prop4you_leadfinder.raw_evidence_gap_bridges.reviewed_at is 'Timestamp when this bridge row was reviewed, if applicable.';
comment on column prop4you_leadfinder.raw_evidence_gap_bridges.created_at is 'Timestamp when this bridge row was inserted.';
comment on column prop4you_leadfinder.raw_evidence_gap_bridges.updated_at is 'Timestamp when this bridge row was last updated.';

create or replace view prop4you_leadfinder.v_raw_evidence_gap_bridge_review as
select b.id,
       b.public_ref,
       dv.version_key as dictionary_version_key,
       r.public_ref as extraction_run_public_ref,
       r.run_key as extraction_run_key,
       p.provider_key,
       pc.class_key as payload_class_key,
       b.temporal_phase,
       b.bridge_status,
       b.canonical_family_id,
       lf.family_key as canonical_family_key,
       b.canonical_field_id,
       lff.field_key as canonical_field_key,
       b.proposed_family_key,
       b.proposed_field_key,
       b.source_path_label,
       b.observed_json_type,
       b.occurrence_count,
       b.raw_record_count,
       b.gap_kind,
       b.severity,
       b.pressure_kind,
       b.pressure_level,
       b.canonical_gap_id,
       g.gap_key,
       b.growth_pressure_signal_id,
       s.signal_key,
       b.proposed_at,
       b.created_at,
       b.updated_at
  from prop4you_leadfinder.raw_evidence_gap_bridges b
  join prop4you_leadfinder.canonical_dictionary_versions dv on dv.id = b.dictionary_version_id
  join prop4you_matrix.raw_path_extraction_runs r on r.id = b.extraction_run_id
  join prop4you_provider.providers p on p.id = b.provider_id
  join prop4you_provider.payload_classes pc on pc.id = b.payload_class_id
  left join prop4you_leadfinder.canonical_families lf on lf.id = b.canonical_family_id
  left join prop4you_leadfinder.canonical_fields lff on lff.id = b.canonical_field_id
  left join prop4you_leadfinder.canonical_gaps g on g.id = b.canonical_gap_id
  left join prop4you_leadfinder.growth_pressure_signals s on s.id = b.growth_pressure_signal_id;

comment on view prop4you_leadfinder.v_raw_evidence_gap_bridge_review is
'Reviewer projection for LeadFinder raw-evidence gap bridges. It exposes dictionary, extraction run, provider/payload, path labels, counts, statuses, and linked gap/signal keys only; no raw values.';
comment on column prop4you_leadfinder.v_raw_evidence_gap_bridge_review.id is 'Bridge row UUID.';
comment on column prop4you_leadfinder.v_raw_evidence_gap_bridge_review.public_ref is 'Bridge row public reference.';
comment on column prop4you_leadfinder.v_raw_evidence_gap_bridge_review.dictionary_version_key is 'LeadFinder dictionary version key.';
comment on column prop4you_leadfinder.v_raw_evidence_gap_bridge_review.extraction_run_public_ref is 'Matrix extraction run public reference.';
comment on column prop4you_leadfinder.v_raw_evidence_gap_bridge_review.extraction_run_key is 'Matrix extraction run key.';
comment on column prop4you_leadfinder.v_raw_evidence_gap_bridge_review.provider_key is 'Provider/origin key.';
comment on column prop4you_leadfinder.v_raw_evidence_gap_bridge_review.payload_class_key is 'Payload class key.';
comment on column prop4you_leadfinder.v_raw_evidence_gap_bridge_review.temporal_phase is 'Explicit temporal phase for the bridge row.';
comment on column prop4you_leadfinder.v_raw_evidence_gap_bridge_review.bridge_status is 'Bridge review status.';
comment on column prop4you_leadfinder.v_raw_evidence_gap_bridge_review.canonical_family_id is 'Matched LeadFinder family UUID, if any.';
comment on column prop4you_leadfinder.v_raw_evidence_gap_bridge_review.canonical_family_key is 'Matched LeadFinder family key, if any.';
comment on column prop4you_leadfinder.v_raw_evidence_gap_bridge_review.canonical_field_id is 'Matched LeadFinder field UUID, if any.';
comment on column prop4you_leadfinder.v_raw_evidence_gap_bridge_review.canonical_field_key is 'Matched LeadFinder field key, if any.';
comment on column prop4you_leadfinder.v_raw_evidence_gap_bridge_review.proposed_family_key is 'Proposed new LeadFinder family key when no field match exists.';
comment on column prop4you_leadfinder.v_raw_evidence_gap_bridge_review.proposed_field_key is 'Proposed new LeadFinder field key when no field match exists.';
comment on column prop4you_leadfinder.v_raw_evidence_gap_bridge_review.source_path_label is 'JSONB source path label only, no raw value.';
comment on column prop4you_leadfinder.v_raw_evidence_gap_bridge_review.observed_json_type is 'Observed JSONB type at source path.';
comment on column prop4you_leadfinder.v_raw_evidence_gap_bridge_review.occurrence_count is 'Aggregate occurrence count.';
comment on column prop4you_leadfinder.v_raw_evidence_gap_bridge_review.raw_record_count is 'Aggregate raw-record count.';
comment on column prop4you_leadfinder.v_raw_evidence_gap_bridge_review.gap_kind is 'Gap kind proposed or linked by the bridge.';
comment on column prop4you_leadfinder.v_raw_evidence_gap_bridge_review.severity is 'Bridge gap severity.';
comment on column prop4you_leadfinder.v_raw_evidence_gap_bridge_review.pressure_kind is 'Growth-pressure kind.';
comment on column prop4you_leadfinder.v_raw_evidence_gap_bridge_review.pressure_level is 'Growth-pressure priority level.';
comment on column prop4you_leadfinder.v_raw_evidence_gap_bridge_review.canonical_gap_id is 'Linked canonical gap UUID, if created.';
comment on column prop4you_leadfinder.v_raw_evidence_gap_bridge_review.gap_key is 'Linked canonical gap key, if created.';
comment on column prop4you_leadfinder.v_raw_evidence_gap_bridge_review.growth_pressure_signal_id is 'Linked growth-pressure signal UUID, if created.';
comment on column prop4you_leadfinder.v_raw_evidence_gap_bridge_review.signal_key is 'Linked growth-pressure signal key, if created.';
comment on column prop4you_leadfinder.v_raw_evidence_gap_bridge_review.proposed_at is 'Timestamp when this bridge proposal was made.';
comment on column prop4you_leadfinder.v_raw_evidence_gap_bridge_review.created_at is 'Timestamp when the bridge row was inserted.';
comment on column prop4you_leadfinder.v_raw_evidence_gap_bridge_review.updated_at is 'Timestamp when the bridge row was last updated.';

create or replace function prop4you_leadfinder.propose_raw_evidence_gap_bridge(
  p_dictionary_version_id uuid,
  p_summary_evidence_id uuid,
  p_temporal_phase text default 'gap_proposal',
  p_canonical_field_id uuid default null,
  p_proposed_family_key text default null,
  p_proposed_field_key text default null,
  p_gap_kind text default null,
  p_severity text default 'medium',
  p_pressure_kind text default 'repeated_raw_path',
  p_pressure_level text default 'medium',
  p_filter_pressure_summary jsonb default '{}'::jsonb,
  p_actor_id text default null,
  p_metadata jsonb default '{}'::jsonb
)
returns prop4you_leadfinder.raw_evidence_gap_bridges
language plpgsql
volatile
as $$
declare
  evidence_row prop4you_matrix.raw_path_summary_evidence;
  field_row prop4you_leadfinder.canonical_fields;
  family_id uuid;
  normalized_family_key text;
  normalized_field_key text;
  effective_gap_kind text;
  gap_id uuid;
  signal_id uuid;
  bridge_row prop4you_leadfinder.raw_evidence_gap_bridges;
  target_key text;
  digest_key text;
  gap_key_value text;
  signal_key_value text;
  origin_payload jsonb;
begin
  if p_dictionary_version_id is null then
    raise exception 'dictionary_version_id is required' using errcode = '22023';
  end if;

  select * into evidence_row
    from prop4you_matrix.raw_path_summary_evidence e
   where e.id = p_summary_evidence_id;

  if not found then
    raise exception 'raw_path_summary_evidence % not found', p_summary_evidence_id using errcode = '22023';
  end if;

  normalized_family_key := nullif(lower(btrim(p_proposed_family_key)), '');
  normalized_field_key := nullif(lower(btrim(p_proposed_field_key)), '');

  if p_canonical_field_id is null and (normalized_family_key is null or normalized_field_key is null) then
    raise exception 'canonical_field_id or proposed_family_key/proposed_field_key pair is required' using errcode = '22023';
  end if;

  if (normalized_family_key is null) <> (normalized_field_key is null) then
    raise exception 'proposed_family_key and proposed_field_key must be provided together' using errcode = '22023';
  end if;

  if normalized_family_key is not null and normalized_family_key !~ '^[a-z][a-z0-9_]{1,79}$' then
    raise exception 'invalid proposed_family_key: %', normalized_family_key using errcode = '22023';
  end if;

  if normalized_field_key is not null and normalized_field_key !~ '^[a-z][a-z0-9_]{1,79}$' then
    raise exception 'invalid proposed_field_key: %', normalized_field_key using errcode = '22023';
  end if;

  if p_canonical_field_id is not null then
    select * into field_row
      from prop4you_leadfinder.canonical_fields f
     where f.id = p_canonical_field_id
       and f.dictionary_version_id = p_dictionary_version_id;

    if not found then
      raise exception 'canonical_field_id % not found in dictionary_version_id %', p_canonical_field_id, p_dictionary_version_id using errcode = '22023';
    end if;

    family_id := field_row.family_id;
    target_key := 'field:' || p_canonical_field_id::text;
    effective_gap_kind := coalesce(p_gap_kind, 'review_needed');
  else
    select f.id into family_id
      from prop4you_leadfinder.canonical_families f
     where f.dictionary_version_id = p_dictionary_version_id
       and f.family_key = normalized_family_key;

    target_key := 'proposed:' || normalized_family_key || '.' || normalized_field_key;
    effective_gap_kind := coalesce(p_gap_kind, case when family_id is null then 'missing_family' else 'missing_field' end);
  end if;

  digest_key := substr(md5(p_dictionary_version_id::text || '|' || p_summary_evidence_id::text || '|' || target_key || '|' || coalesce(p_temporal_phase, 'gap_proposal')), 1, 24);
  gap_key_value := 'raw-gap:' || digest_key;
  signal_key_value := 'raw-pressure:' || digest_key;

  origin_payload := jsonb_build_object(
    'source', 'prop4you_leadfinder.propose_raw_evidence_gap_bridge',
    'value_policy', 'no_raw_values',
    'temporal_phase', coalesce(p_temporal_phase, 'gap_proposal'),
    'matrix_extraction_run_id', evidence_row.extraction_run_id,
    'matrix_summary_evidence_id', evidence_row.id,
    'source_path_label', evidence_row.source_path_label,
    'observed_json_type', evidence_row.observed_json_type,
    'occurrence_count', evidence_row.occurrence_count,
    'raw_record_count', evidence_row.raw_record_count,
    'target_key', target_key
  );

  insert into prop4you_leadfinder.canonical_gaps as g (
    dictionary_version_id,
    family_id,
    field_id,
    gap_key,
    gap_kind,
    severity,
    gap_status,
    description,
    evidence_origin,
    metadata
  ) values (
    p_dictionary_version_id,
    family_id,
    p_canonical_field_id,
    gap_key_value,
    effective_gap_kind,
    coalesce(p_severity, 'medium'),
    'open',
    'Raw path aggregate evidence requires LeadFinder dictionary review; bridge stores path/type/count evidence only and no raw values.',
    origin_payload,
    jsonb_build_object(
      'bridge_temporal_phase', coalesce(p_temporal_phase, 'gap_proposal'),
      'proposed_family_key', normalized_family_key,
      'proposed_field_key', normalized_field_key,
      'filter_pressure_summary', coalesce(p_filter_pressure_summary, '{}'::jsonb),
      'no_raw_values', true
    ) || coalesce(p_metadata, '{}'::jsonb)
  )
  on conflict (dictionary_version_id, gap_key) do update
    set family_id = excluded.family_id,
        field_id = excluded.field_id,
        gap_kind = excluded.gap_kind,
        severity = excluded.severity,
        description = excluded.description,
        evidence_origin = excluded.evidence_origin,
        metadata = excluded.metadata,
        updated_at = now()
  returning id into gap_id;

  insert into prop4you_leadfinder.growth_pressure_signals as s (
    dictionary_version_id,
    family_id,
    field_id,
    signal_key,
    signal_kind,
    signal_status,
    pressure_level,
    description,
    evidence_origin,
    metadata
  ) values (
    p_dictionary_version_id,
    family_id,
    p_canonical_field_id,
    signal_key_value,
    coalesce(p_pressure_kind, 'repeated_raw_path'),
    'candidate',
    coalesce(p_pressure_level, 'medium'),
    'Raw path aggregate evidence and LeadFinder filter pressure create dictionary growth/review pressure; no raw values are stored.',
    origin_payload,
    jsonb_build_object(
      'bridge_temporal_phase', coalesce(p_temporal_phase, 'gap_proposal'),
      'proposed_family_key', normalized_family_key,
      'proposed_field_key', normalized_field_key,
      'filter_pressure_summary', coalesce(p_filter_pressure_summary, '{}'::jsonb),
      'no_raw_values', true
    ) || coalesce(p_metadata, '{}'::jsonb)
  )
  on conflict (dictionary_version_id, signal_key) do update
    set family_id = excluded.family_id,
        field_id = excluded.field_id,
        signal_kind = excluded.signal_kind,
        pressure_level = excluded.pressure_level,
        description = excluded.description,
        evidence_origin = excluded.evidence_origin,
        metadata = excluded.metadata,
        updated_at = now()
  returning id into signal_id;

  insert into prop4you_leadfinder.raw_evidence_gap_bridges as b (
    dictionary_version_id,
    extraction_run_id,
    summary_evidence_id,
    provider_id,
    payload_class_id,
    canonical_family_id,
    canonical_field_id,
    canonical_gap_id,
    growth_pressure_signal_id,
    proposed_family_key,
    proposed_field_key,
    source_path,
    source_path_label,
    observed_json_type,
    occurrence_count,
    raw_record_count,
    evidence_first_captured_at,
    evidence_last_captured_at,
    temporal_phase,
    bridge_status,
    gap_kind,
    severity,
    pressure_kind,
    pressure_level,
    filter_pressure_summary,
    evidence_origin,
    metadata,
    created_by_actor_id
  ) values (
    p_dictionary_version_id,
    evidence_row.extraction_run_id,
    evidence_row.id,
    evidence_row.provider_id,
    evidence_row.payload_class_id,
    family_id,
    p_canonical_field_id,
    gap_id,
    signal_id,
    normalized_family_key,
    normalized_field_key,
    evidence_row.source_path,
    evidence_row.source_path_label,
    evidence_row.observed_json_type,
    evidence_row.occurrence_count,
    evidence_row.raw_record_count,
    evidence_row.first_captured_at,
    evidence_row.last_captured_at,
    coalesce(p_temporal_phase, 'gap_proposal'),
    'candidate',
    effective_gap_kind,
    coalesce(p_severity, 'medium'),
    coalesce(p_pressure_kind, 'repeated_raw_path'),
    coalesce(p_pressure_level, 'medium'),
    coalesce(p_filter_pressure_summary, '{}'::jsonb),
    origin_payload,
    coalesce(p_metadata, '{}'::jsonb),
    nullif(btrim(p_actor_id), '')
  )
  on conflict (dictionary_version_id, summary_evidence_id, temporal_phase, canonical_field_id, proposed_family_key, proposed_field_key) do update
    set canonical_family_id = excluded.canonical_family_id,
        canonical_gap_id = excluded.canonical_gap_id,
        growth_pressure_signal_id = excluded.growth_pressure_signal_id,
        provider_id = excluded.provider_id,
        payload_class_id = excluded.payload_class_id,
        source_path = excluded.source_path,
        source_path_label = excluded.source_path_label,
        observed_json_type = excluded.observed_json_type,
        occurrence_count = excluded.occurrence_count,
        raw_record_count = excluded.raw_record_count,
        evidence_first_captured_at = excluded.evidence_first_captured_at,
        evidence_last_captured_at = excluded.evidence_last_captured_at,
        gap_kind = excluded.gap_kind,
        severity = excluded.severity,
        pressure_kind = excluded.pressure_kind,
        pressure_level = excluded.pressure_level,
        filter_pressure_summary = excluded.filter_pressure_summary,
        evidence_origin = excluded.evidence_origin,
        metadata = excluded.metadata,
        created_by_actor_id = excluded.created_by_actor_id,
        updated_at = now()
  returning * into bridge_row;

  return bridge_row;
end;
$$;

comment on function prop4you_leadfinder.propose_raw_evidence_gap_bridge(uuid,uuid,text,uuid,text,text,text,text,text,text,jsonb,text,jsonb) is
'Idempotently links one Matrix raw_path_summary_evidence row to LeadFinder canonical_gaps and growth_pressure_signals, then records a raw_evidence_gap_bridges row. Supports either an existing canonical_field_id or proposed_family_key/proposed_field_key for a new gap, carries explicit temporal_phase, performs no provider calls, creates no fixtures, and stores no raw values.';

create or replace function prop4you_leadfinder.bridge_raw_evidence_gap_candidates(
  p_dictionary_version_id uuid,
  p_extraction_run_id uuid,
  p_min_raw_record_count bigint default 1,
  p_limit integer default 100,
  p_temporal_phase text default 'gap_proposal',
  p_default_proposed_family_key text default 'source_lineage',
  p_pressure_kind text default 'repeated_raw_path',
  p_pressure_level text default 'medium',
  p_actor_id text default null,
  p_metadata jsonb default '{}'::jsonb
)
returns setof prop4you_leadfinder.raw_evidence_gap_bridges
language plpgsql
volatile
as $$
declare
  evidence_rec record;
  derived_field_key text;
  bridge_row prop4you_leadfinder.raw_evidence_gap_bridges;
  effective_limit integer;
begin
  if p_dictionary_version_id is null then
    raise exception 'dictionary_version_id is required' using errcode = '22023';
  end if;

  if p_extraction_run_id is null then
    raise exception 'extraction_run_id is required' using errcode = '22023';
  end if;

  effective_limit := least(greatest(coalesce(p_limit, 100), 1), 1000);

  for evidence_rec in
    select e.*
      from prop4you_matrix.raw_path_summary_evidence e
     where e.extraction_run_id = p_extraction_run_id
       and e.raw_record_count >= greatest(coalesce(p_min_raw_record_count, 1), 1)
     order by e.raw_record_count desc, e.occurrence_count desc, e.source_path_label
     limit effective_limit
  loop
    derived_field_key := lower(regexp_replace(array_to_string(evidence_rec.source_path, '_'), '[^a-zA-Z0-9_]+', '_', 'g'));
    derived_field_key := regexp_replace(derived_field_key, '_+', '_', 'g');
    derived_field_key := trim(both '_' from derived_field_key);

    if derived_field_key = '' or derived_field_key !~ '^[a-z]' then
      derived_field_key := 'raw_path_' || substr(md5(evidence_rec.source_path_label), 1, 16);
    end if;

    derived_field_key := substr(derived_field_key, 1, 80);

    bridge_row := prop4you_leadfinder.propose_raw_evidence_gap_bridge(
      p_dictionary_version_id => p_dictionary_version_id,
      p_summary_evidence_id => evidence_rec.id,
      p_temporal_phase => coalesce(p_temporal_phase, 'gap_proposal'),
      p_canonical_field_id => null,
      p_proposed_family_key => coalesce(nullif(lower(btrim(p_default_proposed_family_key)), ''), 'source_lineage'),
      p_proposed_field_key => derived_field_key,
      p_gap_kind => null,
      p_severity => 'medium',
      p_pressure_kind => coalesce(p_pressure_kind, 'repeated_raw_path'),
      p_pressure_level => coalesce(p_pressure_level, 'medium'),
      p_filter_pressure_summary => jsonb_build_object(
        'pressure_source', 'raw_path_frequency',
        'min_raw_record_count', greatest(coalesce(p_min_raw_record_count, 1), 1),
        'selected_by', 'prop4you_leadfinder.bridge_raw_evidence_gap_candidates',
        'value_policy', 'no_raw_values'
      ),
      p_actor_id => p_actor_id,
      p_metadata => jsonb_build_object(
        'batch_helper', 'prop4you_leadfinder.bridge_raw_evidence_gap_candidates',
        'no_raw_values', true
      ) || coalesce(p_metadata, '{}'::jsonb)
    );

    return next bridge_row;
  end loop;

  return;
end;
$$;

comment on function prop4you_leadfinder.bridge_raw_evidence_gap_candidates(uuid,uuid,bigint,integer,text,text,text,text,text,jsonb) is
'Batch helper that proposes LeadFinder raw_evidence_gap_bridges for Matrix summary evidence above a raw-record-count threshold. It derives safe proposed field keys from JSONB path components, records explicit temporal_phase, creates linked gaps/signals through propose_raw_evidence_gap_bridge, performs no provider calls, and stores no raw values.';

select base.register_public_id_prefix(
  'p4ylfgb',
  'prop4you_leadfinder',
  'raw_evidence_gap_bridges',
  'Prop4You LeadFinder raw evidence gap bridge'
);
