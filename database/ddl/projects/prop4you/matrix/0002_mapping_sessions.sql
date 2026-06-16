-- package: prop4you/matrix
-- file: 0002_mapping_sessions.sql
-- status: experimental / non-final
-- purpose: Matrix mapping sessions, transformation artifacts, and artifact field mappings for raw/provider evidence review against LeadFinder-owned dictionary versions.
-- depends-on: database/ddl/base, database/ddl/projects/prop4you/0001_schemas.sql, database/ddl/projects/prop4you/providers/0001_provider_registry.sql, database/ddl/projects/prop4you/sourcehub/0001_sourcehub_corpus.sql, database/ddl/projects/prop4you/leadfinder/0001_canonical_dictionary.sql, database/ddl/projects/prop4you/matrix/0001_semantic_dictionary.sql
-- idempotency: idempotent
-- destructive: false
-- review-gate: matrix_artifact_gate
-- [MATRIX_ARTIFACT_GATE] Artifacts produced here are review-gated Matrix outputs, not final SourceHub DTO publication or LeadFinder canonical materialization.
-- [LEADFINDER_DICTIONARY_FK] mapping_sessions, transformation_artifacts, and artifact_field_mappings reference prop4you_leadfinder.canonical_dictionary_versions.
-- [NO_FIXTURES] This DDL creates structures and indexes only; it does not insert raw/fake/redacted payload fixtures or provider sample values.
-- [NO_PROVIDER_CALLS] This DDL contains no provider client, HTTP call, runtime lookup, or enrichment implementation.

create schema if not exists prop4you_matrix;
comment on schema prop4you_matrix is
'Prop4You Matrix schema. Experimental non-final mapping review, transformation artifact, provider path, and LeadFinder dictionary alignment boundary. Matrix gates semantic translation artifacts but LeadFinder owns canonical dictionary versions.';

create table if not exists prop4you_matrix.mapping_sessions (
  id uuid primary key default uuidv7(),
  public_ref text generated always as (base.make_public_ref('p4yms', id)) stored,
  session_key text not null,
  dictionary_version_id uuid not null references prop4you_leadfinder.canonical_dictionary_versions(id) on delete restrict,
  provider_id uuid references prop4you_provider.providers(id) on delete restrict,
  payload_class_id uuid references prop4you_provider.payload_classes(id) on delete restrict,
  mapping_version_id uuid references prop4you_matrix.mapping_versions(id) on delete set null,
  source_raw_record_id uuid references prop4you_sourcehub.raw_records(id) on delete set null,
  session_status text not null default 'draft',
  session_purpose text not null default 'mapping_review',
  artifact_gate_status text not null default 'not_started',
  input_scope jsonb not null default '{}'::jsonb,
  extraction_summary jsonb not null default '{}'::jsonb,
  review_summary text,
  started_at timestamptz,
  completed_at timestamptz,
  created_by_actor_id text,
  reviewer_actor_id text,
  metadata jsonb not null default '{}'::jsonb,
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
  constraint mapping_sessions_public_ref_key unique (public_ref),
  constraint mapping_sessions_session_key_key unique (session_key),
  constraint mapping_sessions_session_key_format_chk check (session_key ~ '^[a-z][a-z0-9_.:-]{1,127}$'),
  constraint mapping_sessions_status_chk check (session_status in ('draft','queued','running','in_review','completed','blocked','abandoned','superseded')),
  constraint mapping_sessions_purpose_chk check (session_purpose in ('mapping_review','dictionary_alignment','artifact_generation','regression_check','lineage_review','unknown')),
  constraint mapping_sessions_artifact_gate_status_chk check (artifact_gate_status in ('not_started','collecting','ready_for_review','passed','blocked','not_applicable')),
  constraint mapping_sessions_input_scope_object_chk check (jsonb_typeof(input_scope) = 'object'),
  constraint mapping_sessions_extraction_summary_object_chk check (jsonb_typeof(extraction_summary) = 'object'),
  constraint mapping_sessions_metadata_object_chk check (jsonb_typeof(metadata) = 'object'),
  constraint mapping_sessions_completed_after_started_chk check (completed_at is null or started_at is null or completed_at >= started_at),
  constraint mapping_sessions_version_positive_chk check (version > 0)
);

create index if not exists mapping_sessions_dictionary_status_idx
  on prop4you_matrix.mapping_sessions (dictionary_version_id, session_status, artifact_gate_status);
create index if not exists mapping_sessions_provider_payload_status_idx
  on prop4you_matrix.mapping_sessions (provider_id, payload_class_id, session_status)
  where provider_id is not null;
create index if not exists mapping_sessions_mapping_version_idx
  on prop4you_matrix.mapping_sessions (mapping_version_id)
  where mapping_version_id is not null;
create index if not exists mapping_sessions_source_raw_record_idx
  on prop4you_matrix.mapping_sessions (source_raw_record_id)
  where source_raw_record_id is not null;
create index if not exists mapping_sessions_input_scope_gin_idx
  on prop4you_matrix.mapping_sessions using gin (input_scope jsonb_path_ops);
create index if not exists mapping_sessions_metadata_gin_idx
  on prop4you_matrix.mapping_sessions using gin (metadata jsonb_path_ops);

comment on table prop4you_matrix.mapping_sessions is
'Experimental Matrix work session for reviewing provider/internal raw evidence against one LeadFinder-owned dictionary version. Sessions collect scope, status, and review summaries only; they do not store raw payload values or call providers.';
comment on column prop4you_matrix.mapping_sessions.id is 'UUIDv7 primary key for one Matrix mapping session.';
comment on column prop4you_matrix.mapping_sessions.public_ref is 'Generated public reference with p4yms prefix for logs and reviews.';
comment on column prop4you_matrix.mapping_sessions.session_key is 'Stable reviewer/tool-defined session key, unique across Matrix mapping sessions.';
comment on column prop4you_matrix.mapping_sessions.dictionary_version_id is 'Required LeadFinder-owned canonical dictionary version being evaluated by this Matrix session. [LEADFINDER_DICTIONARY_FK]';
comment on column prop4you_matrix.mapping_sessions.provider_id is 'Optional provider/origin associated with the session scope.';
comment on column prop4you_matrix.mapping_sessions.payload_class_id is 'Optional provider payload class associated with the session scope.';
comment on column prop4you_matrix.mapping_sessions.mapping_version_id is 'Optional legacy Matrix mapping_versions row that this session supersedes, checks, or enriches.';
comment on column prop4you_matrix.mapping_sessions.source_raw_record_id is 'Optional SourceHub raw record used as private evidence lineage; raw values stay in SourceHub and are not copied here.';
comment on column prop4you_matrix.mapping_sessions.session_status is 'Workflow status for the mapping session: draft, queued, running, in_review, completed, blocked, abandoned, or superseded.';
comment on column prop4you_matrix.mapping_sessions.session_purpose is 'Why the session exists, such as mapping_review, dictionary_alignment, artifact_generation, regression_check, or lineage_review.';
comment on column prop4you_matrix.mapping_sessions.artifact_gate_status is 'Matrix artifact gate status. Passing this gate is required before downstream DTO publication treats artifacts as usable.';
comment on column prop4you_matrix.mapping_sessions.input_scope is 'Non-secret JSONB metadata describing source paths, corpus labels, counts, hashes, or filters; no raw provider values belong here.';
comment on column prop4you_matrix.mapping_sessions.extraction_summary is 'Non-secret JSONB aggregate summary of extracted path/type/count findings, never raw payload values.';
comment on column prop4you_matrix.mapping_sessions.review_summary is 'Short objective human review summary; no secrets, raw payload dumps, or PII values belong here.';
comment on column prop4you_matrix.mapping_sessions.started_at is 'Timestamp when mapping work began, if known.';
comment on column prop4you_matrix.mapping_sessions.completed_at is 'Timestamp when mapping work completed, if known.';
comment on column prop4you_matrix.mapping_sessions.created_by_actor_id is 'Optional actor/tool identifier that created the session; not an authentication contract.';
comment on column prop4you_matrix.mapping_sessions.reviewer_actor_id is 'Optional reviewer actor identifier for the session decision.';
comment on column prop4you_matrix.mapping_sessions.metadata is 'Non-secret JSONB session metadata and lineage labels.';
comment on column prop4you_matrix.mapping_sessions.active is 'Lifecycle flag used to keep the session active for review.';
comment on column prop4you_matrix.mapping_sessions.activated_at is 'Timestamp when this mapping session was activated.';
comment on column prop4you_matrix.mapping_sessions.deactivated_at is 'Timestamp when this mapping session was deactivated without losing lineage.';
comment on column prop4you_matrix.mapping_sessions.deleted is 'Soft-delete lifecycle flag.';
comment on column prop4you_matrix.mapping_sessions.deleted_at is 'Timestamp when this mapping session was soft-deleted, if applicable.';
comment on column prop4you_matrix.mapping_sessions.deleted_by_actor_id is 'Optional actor identifier responsible for soft-deleting this mapping session.';
comment on column prop4you_matrix.mapping_sessions.created_at is 'Timestamp when this mapping session row was inserted.';
comment on column prop4you_matrix.mapping_sessions.updated_at is 'Timestamp when this mapping session row was last updated.';
comment on column prop4you_matrix.mapping_sessions.last_modified_by_actor_id is 'Optional actor identifier supplied by review tooling on last modification.';
comment on column prop4you_matrix.mapping_sessions.version is 'Optimistic lifecycle version for application/tool coordination.';

create table if not exists prop4you_matrix.transformation_artifacts (
  id uuid primary key default uuidv7(),
  public_ref text generated always as (base.make_public_ref('p4yta', id)) stored,
  mapping_session_id uuid not null references prop4you_matrix.mapping_sessions(id) on delete restrict,
  dictionary_version_id uuid not null references prop4you_leadfinder.canonical_dictionary_versions(id) on delete restrict,
  provider_id uuid references prop4you_provider.providers(id) on delete restrict,
  payload_class_id uuid references prop4you_provider.payload_classes(id) on delete restrict,
  mapping_version_id uuid references prop4you_matrix.mapping_versions(id) on delete set null,
  source_raw_record_id uuid references prop4you_sourcehub.raw_records(id) on delete set null,
  artifact_key text not null,
  artifact_kind text not null,
  artifact_status text not null default 'draft',
  artifact_schema_version text not null default 'matrix-artifact.v0',
  artifact_payload jsonb not null default '{}'::jsonb,
  quality_summary jsonb not null default '{}'::jsonb,
  content_sha256 text,
  artifact_gate_status text not null default 'not_started',
  generated_by_actor_id text,
  reviewed_by_actor_id text,
  approved_at timestamptz,
  superseded_at timestamptz,
  metadata jsonb not null default '{}'::jsonb,
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
  constraint transformation_artifacts_public_ref_key unique (public_ref),
  constraint transformation_artifacts_artifact_key_key unique (artifact_key),
  constraint transformation_artifacts_artifact_key_format_chk check (artifact_key ~ '^[a-z][a-z0-9_.:-]{1,159}$'),
  constraint transformation_artifacts_kind_chk check (artifact_kind in ('field_mapping_set','dto_candidate_contract','normalization_plan','lineage_summary','quality_report','review_bundle','unknown')),
  constraint transformation_artifacts_status_chk check (artifact_status in ('draft','generated','in_review','approved','blocked','rejected','superseded','archived')),
  constraint transformation_artifacts_schema_version_chk check (artifact_schema_version ~ '^[a-z][a-z0-9_.:-]{1,79}$'),
  constraint transformation_artifacts_payload_object_chk check (jsonb_typeof(artifact_payload) = 'object'),
  constraint transformation_artifacts_quality_summary_object_chk check (jsonb_typeof(quality_summary) = 'object'),
  constraint transformation_artifacts_content_sha256_chk check (content_sha256 is null or content_sha256 ~ '^[0-9a-f]{64}$'),
  constraint transformation_artifacts_gate_status_chk check (artifact_gate_status in ('not_started','ready_for_review','passed','blocked','not_applicable')),
  constraint transformation_artifacts_metadata_object_chk check (jsonb_typeof(metadata) = 'object'),
  constraint transformation_artifacts_superseded_after_approved_chk check (superseded_at is null or approved_at is null or superseded_at >= approved_at),
  constraint transformation_artifacts_version_positive_chk check (version > 0)
);

create index if not exists transformation_artifacts_session_status_idx
  on prop4you_matrix.transformation_artifacts (mapping_session_id, artifact_status, artifact_gate_status);
create index if not exists transformation_artifacts_dictionary_kind_status_idx
  on prop4you_matrix.transformation_artifacts (dictionary_version_id, artifact_kind, artifact_status);
create index if not exists transformation_artifacts_provider_payload_idx
  on prop4you_matrix.transformation_artifacts (provider_id, payload_class_id, artifact_status)
  where provider_id is not null;
create index if not exists transformation_artifacts_source_raw_record_idx
  on prop4you_matrix.transformation_artifacts (source_raw_record_id)
  where source_raw_record_id is not null;
create index if not exists transformation_artifacts_payload_gin_idx
  on prop4you_matrix.transformation_artifacts using gin (artifact_payload jsonb_path_ops);
create index if not exists transformation_artifacts_quality_summary_gin_idx
  on prop4you_matrix.transformation_artifacts using gin (quality_summary jsonb_path_ops);
create index if not exists transformation_artifacts_metadata_gin_idx
  on prop4you_matrix.transformation_artifacts using gin (metadata jsonb_path_ops);

comment on table prop4you_matrix.transformation_artifacts is
'Experimental Matrix artifacts produced by mapping sessions. Artifacts capture non-secret mapping/normalization/DTO-candidate structures for review against a LeadFinder dictionary version; they are not final SourceHub DTO publication and do not contain raw provider values.';
comment on column prop4you_matrix.transformation_artifacts.id is 'UUIDv7 primary key for one Matrix transformation artifact.';
comment on column prop4you_matrix.transformation_artifacts.public_ref is 'Generated public reference with p4yta prefix for logs and reviews.';
comment on column prop4you_matrix.transformation_artifacts.mapping_session_id is 'Matrix mapping session that produced or owns this artifact.';
comment on column prop4you_matrix.transformation_artifacts.dictionary_version_id is 'Required LeadFinder-owned canonical dictionary version targeted by this artifact. [LEADFINDER_DICTIONARY_FK]';
comment on column prop4you_matrix.transformation_artifacts.provider_id is 'Optional provider/origin associated with the artifact.';
comment on column prop4you_matrix.transformation_artifacts.payload_class_id is 'Optional payload class associated with the artifact.';
comment on column prop4you_matrix.transformation_artifacts.mapping_version_id is 'Optional legacy Matrix mapping_versions row associated with the artifact.';
comment on column prop4you_matrix.transformation_artifacts.source_raw_record_id is 'Optional SourceHub raw record lineage used to produce the artifact; raw values are not copied into artifact_payload.';
comment on column prop4you_matrix.transformation_artifacts.artifact_key is 'Stable artifact key, unique across Matrix artifacts.';
comment on column prop4you_matrix.transformation_artifacts.artifact_kind is 'Kind of artifact, such as field_mapping_set, dto_candidate_contract, normalization_plan, lineage_summary, quality_report, or review_bundle.';
comment on column prop4you_matrix.transformation_artifacts.artifact_status is 'Review lifecycle status for this artifact.';
comment on column prop4you_matrix.transformation_artifacts.artifact_schema_version is 'Non-final JSONB artifact contract version label.';
comment on column prop4you_matrix.transformation_artifacts.artifact_payload is 'Non-secret JSONB artifact body containing mapping structure, path labels, aggregate counts, or DTO shape hints; raw provider values and PII values do not belong here.';
comment on column prop4you_matrix.transformation_artifacts.quality_summary is 'Non-secret JSONB quality metrics or reviewer findings for this artifact.';
comment on column prop4you_matrix.transformation_artifacts.content_sha256 is 'Optional lowercase SHA-256 checksum of a deterministic non-secret artifact serialization.';
comment on column prop4you_matrix.transformation_artifacts.artifact_gate_status is 'Matrix artifact gate status for downstream readiness. [MATRIX_ARTIFACT_GATE]';
comment on column prop4you_matrix.transformation_artifacts.generated_by_actor_id is 'Optional actor/tool identifier that generated this artifact.';
comment on column prop4you_matrix.transformation_artifacts.reviewed_by_actor_id is 'Optional reviewer actor identifier for this artifact.';
comment on column prop4you_matrix.transformation_artifacts.approved_at is 'Timestamp when this artifact passed review, if ever.';
comment on column prop4you_matrix.transformation_artifacts.superseded_at is 'Timestamp when this artifact was superseded by another artifact, if ever.';
comment on column prop4you_matrix.transformation_artifacts.metadata is 'Non-secret JSONB artifact metadata and lineage labels.';
comment on column prop4you_matrix.transformation_artifacts.active is 'Lifecycle flag used to keep the artifact active for review/use.';
comment on column prop4you_matrix.transformation_artifacts.activated_at is 'Timestamp when this artifact was activated.';
comment on column prop4you_matrix.transformation_artifacts.deactivated_at is 'Timestamp when this artifact was deactivated without losing lineage.';
comment on column prop4you_matrix.transformation_artifacts.deleted is 'Soft-delete lifecycle flag.';
comment on column prop4you_matrix.transformation_artifacts.deleted_at is 'Timestamp when this artifact was soft-deleted, if applicable.';
comment on column prop4you_matrix.transformation_artifacts.deleted_by_actor_id is 'Optional actor identifier responsible for soft-deleting this artifact.';
comment on column prop4you_matrix.transformation_artifacts.created_at is 'Timestamp when this transformation artifact row was inserted.';
comment on column prop4you_matrix.transformation_artifacts.updated_at is 'Timestamp when this transformation artifact row was last updated.';
comment on column prop4you_matrix.transformation_artifacts.last_modified_by_actor_id is 'Optional actor identifier supplied by review tooling on last modification.';
comment on column prop4you_matrix.transformation_artifacts.version is 'Optimistic lifecycle version for application/tool coordination.';

create table if not exists prop4you_matrix.artifact_field_mappings (
  id uuid primary key default uuidv7(),
  public_ref text generated always as (base.make_public_ref('p4yafm', id)) stored,
  artifact_id uuid not null references prop4you_matrix.transformation_artifacts(id) on delete cascade,
  mapping_session_id uuid not null references prop4you_matrix.mapping_sessions(id) on delete restrict,
  dictionary_version_id uuid not null references prop4you_leadfinder.canonical_dictionary_versions(id) on delete restrict,
  leadfinder_field_id uuid references prop4you_leadfinder.canonical_fields(id) on delete restrict,
  matrix_field_id uuid references prop4you_matrix.canonical_fields(id) on delete set null,
  provider_path_mapping_id uuid references prop4you_matrix.provider_path_mappings(id) on delete set null,
  provider_id uuid references prop4you_provider.providers(id) on delete restrict,
  payload_class_id uuid references prop4you_provider.payload_classes(id) on delete restrict,
  source_raw_record_id uuid references prop4you_sourcehub.raw_records(id) on delete set null,
  source_path text[] not null,
  source_path_label text,
  target_field_key text not null,
  target_value_kind text not null default 'unknown',
  transform_policy text not null default 'review_required',
  mapping_status text not null default 'candidate',
  confidence_level text not null default 'unknown',
  ordinal integer not null default 100,
  evidence_summary jsonb not null default '{}'::jsonb,
  transform_spec jsonb not null default '{}'::jsonb,
  notes text,
  metadata jsonb not null default '{}'::jsonb,
  active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  last_modified_by_actor_id text,
  version integer not null default 1,
  constraint artifact_field_mappings_public_ref_key unique (public_ref),
  constraint artifact_field_mappings_source_path_not_empty_chk check (cardinality(source_path) > 0),
  constraint artifact_field_mappings_target_field_key_format_chk check (target_field_key ~ '^[a-z][a-z0-9_.:-]{1,159}$'),
  constraint artifact_field_mappings_target_value_kind_chk check (target_value_kind in ('text','integer','numeric','boolean','date','timestamp','uuid','enum','jsonb','unknown')),
  constraint artifact_field_mappings_transform_policy_chk check (transform_policy in ('copy','cast','normalize','derive','split','join','lookup','evidence_only','review_required','ignore')),
  constraint artifact_field_mappings_status_chk check (mapping_status in ('candidate','in_review','approved','blocked','conflicting','rejected','deprecated')),
  constraint artifact_field_mappings_confidence_chk check (confidence_level in ('unknown','low','medium','high','authoritative')),
  constraint artifact_field_mappings_ordinal_positive_chk check (ordinal > 0),
  constraint artifact_field_mappings_evidence_summary_object_chk check (jsonb_typeof(evidence_summary) = 'object'),
  constraint artifact_field_mappings_transform_spec_object_chk check (jsonb_typeof(transform_spec) = 'object'),
  constraint artifact_field_mappings_metadata_object_chk check (jsonb_typeof(metadata) = 'object'),
  constraint artifact_field_mappings_version_positive_chk check (version > 0)
);

create unique index if not exists artifact_field_mappings_artifact_path_target_key
  on prop4you_matrix.artifact_field_mappings (artifact_id, source_path, target_field_key);
create index if not exists artifact_field_mappings_artifact_status_idx
  on prop4you_matrix.artifact_field_mappings (artifact_id, mapping_status, ordinal);
create index if not exists artifact_field_mappings_dictionary_status_idx
  on prop4you_matrix.artifact_field_mappings (dictionary_version_id, mapping_status);
create index if not exists artifact_field_mappings_leadfinder_field_idx
  on prop4you_matrix.artifact_field_mappings (leadfinder_field_id, mapping_status)
  where leadfinder_field_id is not null;
create index if not exists artifact_field_mappings_provider_path_mapping_idx
  on prop4you_matrix.artifact_field_mappings (provider_path_mapping_id)
  where provider_path_mapping_id is not null;
create index if not exists artifact_field_mappings_provider_payload_idx
  on prop4you_matrix.artifact_field_mappings (provider_id, payload_class_id, mapping_status)
  where provider_id is not null;
create index if not exists artifact_field_mappings_evidence_summary_gin_idx
  on prop4you_matrix.artifact_field_mappings using gin (evidence_summary jsonb_path_ops);
create index if not exists artifact_field_mappings_transform_spec_gin_idx
  on prop4you_matrix.artifact_field_mappings using gin (transform_spec jsonb_path_ops);
create index if not exists artifact_field_mappings_metadata_gin_idx
  on prop4you_matrix.artifact_field_mappings using gin (metadata jsonb_path_ops);

comment on table prop4you_matrix.artifact_field_mappings is
'Experimental Matrix artifact detail rows that map source JSONB paths to LeadFinder dictionary field candidates or Matrix mirror fields. Rows store path labels, status, transform policy, and non-secret summaries only; they do not store raw payload values.';
comment on column prop4you_matrix.artifact_field_mappings.id is 'UUIDv7 primary key for one artifact field mapping row.';
comment on column prop4you_matrix.artifact_field_mappings.public_ref is 'Generated public reference with p4yafm prefix for logs and reviews.';
comment on column prop4you_matrix.artifact_field_mappings.artifact_id is 'Transformation artifact that owns this field mapping row.';
comment on column prop4you_matrix.artifact_field_mappings.mapping_session_id is 'Mapping session that produced this field mapping row.';
comment on column prop4you_matrix.artifact_field_mappings.dictionary_version_id is 'Required LeadFinder-owned canonical dictionary version targeted by this mapping row. [LEADFINDER_DICTIONARY_FK]';
comment on column prop4you_matrix.artifact_field_mappings.leadfinder_field_id is 'Optional LeadFinder-owned canonical field candidate targeted by this mapping row.';
comment on column prop4you_matrix.artifact_field_mappings.matrix_field_id is 'Optional Matrix mirror/candidate/review field retained for compatibility during transition to LeadFinder dictionary ownership.';
comment on column prop4you_matrix.artifact_field_mappings.provider_path_mapping_id is 'Optional existing Matrix provider_path_mappings row that this artifact mapping reuses or evaluates.';
comment on column prop4you_matrix.artifact_field_mappings.provider_id is 'Optional provider/origin that exposes source_path.';
comment on column prop4you_matrix.artifact_field_mappings.payload_class_id is 'Optional payload class where source_path was observed.';
comment on column prop4you_matrix.artifact_field_mappings.source_raw_record_id is 'Optional SourceHub raw record lineage; raw values stay in SourceHub and are not copied here.';
comment on column prop4you_matrix.artifact_field_mappings.source_path is 'PostgreSQL text[] JSONB source path components. Array indexes may be represented as numeric strings for review.';
comment on column prop4you_matrix.artifact_field_mappings.source_path_label is 'Optional human-readable dotted/bracket source path label; must not include raw values.';
comment on column prop4you_matrix.artifact_field_mappings.target_field_key is 'LeadFinder dictionary field key or candidate target key expected after transformation.';
comment on column prop4you_matrix.artifact_field_mappings.target_value_kind is 'Expected target value kind after transformation.';
comment on column prop4you_matrix.artifact_field_mappings.transform_policy is 'Non-executable transform policy label such as copy, normalize, derive, evidence_only, review_required, or ignore.';
comment on column prop4you_matrix.artifact_field_mappings.mapping_status is 'Review lifecycle status for this field mapping.';
comment on column prop4you_matrix.artifact_field_mappings.confidence_level is 'Confidence that source_path maps to the target field.';
comment on column prop4you_matrix.artifact_field_mappings.ordinal is 'Stable ordering within an artifact; lower numbers are evaluated first.';
comment on column prop4you_matrix.artifact_field_mappings.evidence_summary is 'Non-secret JSONB aggregate evidence such as counts, observed types, or hash labels; raw values and PII do not belong here.';
comment on column prop4you_matrix.artifact_field_mappings.transform_spec is 'Non-secret JSONB declarative transform spec for review. It is not executable provider code.';
comment on column prop4you_matrix.artifact_field_mappings.notes is 'Short objective notes; no raw payload values, provider secrets, or PII values belong here.';
comment on column prop4you_matrix.artifact_field_mappings.metadata is 'Non-secret JSONB mapping metadata and lineage labels.';
comment on column prop4you_matrix.artifact_field_mappings.active is 'Lifecycle flag used to keep the field mapping active for review/use.';
comment on column prop4you_matrix.artifact_field_mappings.created_at is 'Timestamp when this artifact field mapping row was inserted.';
comment on column prop4you_matrix.artifact_field_mappings.updated_at is 'Timestamp when this artifact field mapping row was last updated.';
comment on column prop4you_matrix.artifact_field_mappings.last_modified_by_actor_id is 'Optional actor identifier supplied by review tooling on last modification.';
comment on column prop4you_matrix.artifact_field_mappings.version is 'Optimistic lifecycle version for application/tool coordination.';
