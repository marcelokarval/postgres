-- package: prop4you/sourcehub
-- file: 0001_sourcehub_corpus.sql
-- status: experimental / non-final
-- purpose: SourceHub raw payload records, private corpus sample metadata, lineage, and enrichment request queue concept for Prop4You corpus review.
-- depends-on: database/ddl/base, database/ddl/projects/prop4you/0001_schemas.sql, database/ddl/projects/prop4you/providers/0001_provider_registry.sql
-- idempotency: idempotent
-- destructive: false
-- review-gate: provider_payload_corpus_review
-- [NO_FIXTURES] This DDL creates only structures and indexes; it does not insert raw/fake/redacted payload fixtures.
-- [NO_PROVIDER_CALLS] This DDL stores request intent and raw_payload evidence only; it never invokes external providers.

create schema if not exists prop4you_sourcehub;
comment on schema prop4you_sourcehub is
'Prop4You SourceHub schema. Experimental non-final owner of raw payload ingress, private corpus metadata, source lineage, and enrichment request workflow state before Matrix and LeadFinder canonicalization are frozen.';

create table if not exists prop4you_sourcehub.raw_records (
  id uuid primary key default uuidv7(),
  public_ref text generated always as (base.make_public_ref('p4yshr', id)) stored,
  provider_id uuid not null references prop4you_provider.providers(id) on delete restrict,
  payload_class_id uuid not null references prop4you_provider.payload_classes(id) on delete restrict,
  provider_payload_class_id uuid references prop4you_provider.provider_payload_classes(id) on delete restrict,
  ingress_status text not null default 'captured',
  review_status text not null default 'unreviewed',
  source_kind text not null,
  source_label text,
  source_observed_at timestamptz,
  captured_at timestamptz not null default now(),
  raw_payload jsonb not null,
  raw_payload_sha256 text,
  payload_root_type text generated always as (jsonb_typeof(raw_payload)) stored,
  payload_bytes_estimate bigint generated always as (octet_length(raw_payload::text)) stored,
  provider_external_id text,
  provider_request_ref text,
  corpus_sample_id uuid,
  private_corpus_uri text,
  private_corpus_path text,
  privacy_classification text not null default 'unknown',
  contains_personal_data boolean not null default false,
  matrix_mapping_status text not null default 'not_started',
  leadfinder_publication_status text not null default 'not_ready',
  error_summary text,
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
  constraint raw_records_public_ref_key unique (public_ref),
  constraint raw_records_ingress_status_chk check (ingress_status in ('captured','queued','parsed','quarantined','rejected','archived')),
  constraint raw_records_review_status_chk check (review_status in ('unreviewed','in_review','accepted_for_mapping','needs_provider_context','rejected','archived')),
  constraint raw_records_source_kind_chk check (source_kind in ('provider_response','provider_export','internal_snapshot','manual_import','derived_review','unknown')),
  constraint raw_records_payload_root_type_chk check (jsonb_typeof(raw_payload) in ('object','array')),
  constraint raw_records_sha256_format_chk check (raw_payload_sha256 is null or raw_payload_sha256 ~ '^[0-9a-f]{64}$'),
  constraint raw_records_privacy_classification_chk check (privacy_classification in ('unknown','public','internal','confidential','restricted')),
  constraint raw_records_matrix_mapping_status_chk check (matrix_mapping_status in ('not_started','candidate_paths_detected','mapping_in_review','mapped','blocked','not_applicable')),
  constraint raw_records_leadfinder_publication_status_chk check (leadfinder_publication_status in ('not_ready','blocked','candidate_dto_ready','published','not_applicable')),
  constraint raw_records_private_location_chk check (private_corpus_uri is null or private_corpus_uri ~ '^[a-z][a-z0-9+.-]*:'),
  constraint raw_records_private_path_not_blank_chk check (private_corpus_path is null or length(btrim(private_corpus_path)) > 0),
  constraint raw_records_metadata_object_chk check (jsonb_typeof(metadata) = 'object'),
  constraint raw_records_payload_bytes_positive_chk check (payload_bytes_estimate > 0),
  constraint raw_records_version_positive_chk check (version > 0)
);

create index if not exists raw_records_provider_class_status_idx
  on prop4you_sourcehub.raw_records (provider_id, payload_class_id, ingress_status, review_status);
create index if not exists raw_records_captured_at_idx
  on prop4you_sourcehub.raw_records (captured_at desc);
create index if not exists raw_records_provider_external_id_idx
  on prop4you_sourcehub.raw_records (provider_id, provider_external_id)
  where provider_external_id is not null;
create index if not exists raw_records_raw_payload_gin_idx
  on prop4you_sourcehub.raw_records using gin (raw_payload jsonb_path_ops);
create index if not exists raw_records_metadata_gin_idx
  on prop4you_sourcehub.raw_records using gin (metadata jsonb_path_ops);

comment on table prop4you_sourcehub.raw_records is
'Experimental SourceHub table for raw provider/internal JSONB payload evidence. Records are not canonical properties, owners, or leads; they preserve ingress facts for Matrix review and later DTO publication gates.';
comment on column prop4you_sourcehub.raw_records.id is 'UUIDv7 primary key for one raw SourceHub payload record.';
comment on column prop4you_sourcehub.raw_records.public_ref is 'Generated public reference with p4yshr prefix and the record UUID; intended for logs/reviews without exposing table internals.';
comment on column prop4you_sourcehub.raw_records.provider_id is 'Provider or internal origin that produced or supplied this raw payload.';
comment on column prop4you_sourcehub.raw_records.payload_class_id is 'Provider payload class describing the coarse domain and direction of the raw payload.';
comment on column prop4you_sourcehub.raw_records.provider_payload_class_id is 'Optional provider-to-payload-class catalog link when the exact provider/class relationship is known.';
comment on column prop4you_sourcehub.raw_records.ingress_status is 'Operational ingress status for raw evidence: captured, queued, parsed, quarantined, rejected, or archived.';
comment on column prop4you_sourcehub.raw_records.review_status is 'Human/data-review state before Matrix mapping and LeadFinder DTO publication are allowed.';
comment on column prop4you_sourcehub.raw_records.source_kind is 'How the payload entered SourceHub, such as provider_response, provider_export, internal_snapshot, manual_import, derived_review, or unknown.';
comment on column prop4you_sourcehub.raw_records.source_label is 'Optional non-secret human label for the endpoint, export, screen, job, or import batch that produced the payload.';
comment on column prop4you_sourcehub.raw_records.source_observed_at is 'Timestamp reported by the source system or corpus reviewer for when the payload was observed, when known.';
comment on column prop4you_sourcehub.raw_records.captured_at is 'Timestamp when the payload evidence was captured into SourceHub metadata in this database.';
comment on column prop4you_sourcehub.raw_records.raw_payload is 'Raw JSONB payload evidence stored in database for review. This column must contain a JSON object or array and is not a final canonical DTO.';
comment on column prop4you_sourcehub.raw_records.raw_payload_sha256 is 'Optional lowercase SHA-256 checksum of the raw payload text or private corpus object, supplied by ingestion/review tooling when available.';
comment on column prop4you_sourcehub.raw_records.payload_root_type is 'Generated jsonb_typeof value for raw_payload, constrained to object or array for this experimental SourceHub slice.';
comment on column prop4you_sourcehub.raw_records.payload_bytes_estimate is 'Generated byte estimate from the JSONB text representation; used only for review sizing and not exact wire size.';
comment on column prop4you_sourcehub.raw_records.provider_external_id is 'Optional provider/origin identifier observed in the raw payload or source metadata; not assumed globally unique.';
comment on column prop4you_sourcehub.raw_records.provider_request_ref is 'Optional non-secret provider request/correlation reference captured from an upstream call or import workflow.';
comment on column prop4you_sourcehub.raw_records.corpus_sample_id is 'Optional UUID pointer to corpus_samples.id; a foreign key is added after corpus_samples exists in this file.';
comment on column prop4you_sourcehub.raw_records.private_corpus_uri is 'Optional URI for a private corpus object outside git, such as file:// or s3:// metadata. The DDL does not create or read that object.';
comment on column prop4you_sourcehub.raw_records.private_corpus_path is 'Optional local/private path metadata for reviewers; no payload file is committed or generated by this DDL.';
comment on column prop4you_sourcehub.raw_records.privacy_classification is 'Review classification for sensitivity of the raw evidence: unknown, public, internal, confidential, or restricted.';
comment on column prop4you_sourcehub.raw_records.contains_personal_data is 'Boolean review flag indicating whether the raw payload may contain personal data or contact data.';
comment on column prop4you_sourcehub.raw_records.matrix_mapping_status is 'Status of Matrix path/dictionary mapping for this raw record; it gates semantic use of the payload.';
comment on column prop4you_sourcehub.raw_records.leadfinder_publication_status is 'Status of later LeadFinder DTO/publication readiness; raw records do not publish canonical entities directly.';
comment on column prop4you_sourcehub.raw_records.error_summary is 'Optional short review/ingress error summary; detailed error artifacts belong in metadata or logs, not provider calls.';
comment on column prop4you_sourcehub.raw_records.metadata is 'Non-secret JSONB object for additional review metadata, parser hints, and corpus notes.';
comment on column prop4you_sourcehub.raw_records.active is 'Lifecycle flag used to hide a record from active review without deleting raw lineage.';
comment on column prop4you_sourcehub.raw_records.activated_at is 'Timestamp when this raw record became active under the base lifecycle convention.';
comment on column prop4you_sourcehub.raw_records.deactivated_at is 'Timestamp when this raw record was deactivated without deleting lineage.';
comment on column prop4you_sourcehub.raw_records.deleted is 'Soft-delete lifecycle flag; raw evidence should normally be retained for lineage unless governed deletion is required.';
comment on column prop4you_sourcehub.raw_records.deleted_at is 'Timestamp when this raw record was soft-deleted, when applicable.';
comment on column prop4you_sourcehub.raw_records.deleted_by_actor_id is 'Optional actor identifier responsible for soft-deleting this raw record.';
comment on column prop4you_sourcehub.raw_records.created_at is 'Timestamp when the raw record row was inserted.';
comment on column prop4you_sourcehub.raw_records.updated_at is 'Timestamp when the raw record row was last updated.';
comment on column prop4you_sourcehub.raw_records.last_modified_by_actor_id is 'Optional actor identifier supplied by the database request context or review tooling.';
comment on column prop4you_sourcehub.raw_records.version is 'Optimistic lifecycle version incremented by the standard base trigger on updates.';

create table if not exists prop4you_sourcehub.corpus_samples (
  id uuid primary key default uuidv7(),
  public_ref text generated always as (base.make_public_ref('p4yshs', id)) stored,
  provider_id uuid not null references prop4you_provider.providers(id) on delete restrict,
  payload_class_id uuid references prop4you_provider.payload_classes(id) on delete restrict,
  sample_key text not null,
  sample_status text not null default 'registered',
  sample_purpose text not null default 'mapping_review',
  corpus_collection text,
  private_corpus_uri text,
  private_corpus_path text,
  payload_sha256 text,
  payload_bytes bigint,
  observed_at timestamptz,
  reviewer_notes text,
  redaction_status text not null default 'not_redacted',
  storage_policy text not null default 'private_outside_git',
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
  constraint corpus_samples_public_ref_key unique (public_ref),
  constraint corpus_samples_provider_sample_key_key unique (provider_id, sample_key),
  constraint corpus_samples_sample_key_format_chk check (sample_key ~ '^[a-z][a-z0-9_.:-]{1,127}$'),
  constraint corpus_samples_sample_status_chk check (sample_status in ('registered','available_private','loaded_as_raw_record','quarantined','retired')),
  constraint corpus_samples_sample_purpose_chk check (sample_purpose in ('mapping_review','lineage_review','enrichment_review','regression_reference','unknown')),
  constraint corpus_samples_private_uri_chk check (private_corpus_uri is null or private_corpus_uri ~ '^[a-z][a-z0-9+.-]*:'),
  constraint corpus_samples_private_path_chk check (private_corpus_path is null or length(btrim(private_corpus_path)) > 0),
  constraint corpus_samples_payload_sha256_chk check (payload_sha256 is null or payload_sha256 ~ '^[0-9a-f]{64}$'),
  constraint corpus_samples_payload_bytes_chk check (payload_bytes is null or payload_bytes > 0),
  constraint corpus_samples_redaction_status_chk check (redaction_status in ('not_redacted','redacted_private_copy','not_required','unknown')),
  constraint corpus_samples_storage_policy_chk check (storage_policy in ('private_outside_git','metadata_only','database_raw_payload','unknown')),
  constraint corpus_samples_metadata_object_chk check (jsonb_typeof(metadata) = 'object'),
  constraint corpus_samples_version_positive_chk check (version > 0)
);

create index if not exists corpus_samples_provider_status_idx
  on prop4you_sourcehub.corpus_samples (provider_id, sample_status, sample_purpose);
create index if not exists corpus_samples_collection_idx
  on prop4you_sourcehub.corpus_samples (corpus_collection)
  where corpus_collection is not null;
create index if not exists corpus_samples_metadata_gin_idx
  on prop4you_sourcehub.corpus_samples using gin (metadata jsonb_path_ops);

comment on table prop4you_sourcehub.corpus_samples is
'Experimental metadata catalog for private real corpus samples used in Prop4You provider comparison. It stores URI/path/checksum/status metadata only unless a separate raw_records row explicitly stores JSONB evidence.';
comment on column prop4you_sourcehub.corpus_samples.id is 'UUIDv7 primary key for one private corpus sample metadata record.';
comment on column prop4you_sourcehub.corpus_samples.public_ref is 'Generated public reference with p4yshs prefix and the corpus sample UUID.';
comment on column prop4you_sourcehub.corpus_samples.provider_id is 'Provider or internal origin associated with the private corpus sample.';
comment on column prop4you_sourcehub.corpus_samples.payload_class_id is 'Optional payload class expected for the private corpus sample.';
comment on column prop4you_sourcehub.corpus_samples.sample_key is 'Stable reviewer-defined key for this corpus sample, unique per provider/origin.';
comment on column prop4you_sourcehub.corpus_samples.sample_status is 'Status of sample metadata: registered, available_private, loaded_as_raw_record, quarantined, or retired.';
comment on column prop4you_sourcehub.corpus_samples.sample_purpose is 'Primary review purpose for the sample metadata, such as mapping_review, lineage_review, enrichment_review, or regression_reference.';
comment on column prop4you_sourcehub.corpus_samples.corpus_collection is 'Optional private collection or batch label; this is metadata only and not a committed directory contract.';
comment on column prop4you_sourcehub.corpus_samples.private_corpus_uri is 'Optional private object URI outside git. SourceHub records the pointer but does not fetch or create the object.';
comment on column prop4you_sourcehub.corpus_samples.private_corpus_path is 'Optional private filesystem path metadata outside git. The DDL creates no payload files.';
comment on column prop4you_sourcehub.corpus_samples.payload_sha256 is 'Optional lowercase SHA-256 checksum supplied by private corpus tooling for integrity review.';
comment on column prop4you_sourcehub.corpus_samples.payload_bytes is 'Optional payload size in bytes supplied by private corpus tooling.';
comment on column prop4you_sourcehub.corpus_samples.observed_at is 'Optional timestamp when the private sample was observed or exported from its source.';
comment on column prop4you_sourcehub.corpus_samples.reviewer_notes is 'Optional objective reviewer note about the sample; no secrets or raw payload fragments should be stored here.';
comment on column prop4you_sourcehub.corpus_samples.redaction_status is 'Whether a private redacted copy exists or redaction is not required; no redacted fixture is committed by this DDL.';
comment on column prop4you_sourcehub.corpus_samples.storage_policy is 'Declared storage policy for sample evidence, emphasizing private_outside_git for real provider corpus files.';
comment on column prop4you_sourcehub.corpus_samples.metadata is 'Non-secret JSONB object for sample metadata and review tags.';
comment on column prop4you_sourcehub.corpus_samples.active is 'Lifecycle flag indicating whether the corpus sample remains in active review scope.';
comment on column prop4you_sourcehub.corpus_samples.activated_at is 'Timestamp when this corpus sample metadata became active under the base lifecycle convention.';
comment on column prop4you_sourcehub.corpus_samples.deactivated_at is 'Timestamp when this corpus sample metadata was deactivated without removing review history.';
comment on column prop4you_sourcehub.corpus_samples.deleted is 'Soft-delete lifecycle flag for corpus sample metadata; it does not delete private payload files.';
comment on column prop4you_sourcehub.corpus_samples.deleted_at is 'Timestamp when this corpus sample metadata was soft-deleted, when applicable.';
comment on column prop4you_sourcehub.corpus_samples.deleted_by_actor_id is 'Optional actor identifier responsible for soft-deleting this corpus sample metadata.';
comment on column prop4you_sourcehub.corpus_samples.created_at is 'Timestamp when this sample metadata row was inserted.';
comment on column prop4you_sourcehub.corpus_samples.updated_at is 'Timestamp when this sample metadata row was last updated.';
comment on column prop4you_sourcehub.corpus_samples.last_modified_by_actor_id is 'Optional actor identifier supplied by database request context or review tooling.';
comment on column prop4you_sourcehub.corpus_samples.version is 'Optimistic lifecycle version incremented by the standard base trigger on updates.';

alter table prop4you_sourcehub.raw_records
  drop constraint if exists raw_records_corpus_sample_fk;
alter table prop4you_sourcehub.raw_records
  add constraint raw_records_corpus_sample_fk
  foreign key (corpus_sample_id) references prop4you_sourcehub.corpus_samples(id) on delete set null;
comment on constraint raw_records_corpus_sample_fk on prop4you_sourcehub.raw_records is
'Optional link from a raw JSONB record to private corpus sample metadata. Deleting sample metadata does not delete raw evidence.';

create table if not exists prop4you_sourcehub.source_lineage_edges (
  id uuid primary key default uuidv7(),
  public_ref text generated always as (base.make_public_ref('p4yshl', id)) stored,
  from_raw_record_id uuid references prop4you_sourcehub.raw_records(id) on delete restrict,
  to_raw_record_id uuid references prop4you_sourcehub.raw_records(id) on delete restrict,
  derived_object_schema name,
  derived_object_table name,
  derived_object_id uuid,
  lineage_kind text not null,
  confidence_level text not null default 'unknown',
  evidence_summary text,
  mapping_metadata jsonb not null default '{}'::jsonb,
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
  constraint source_lineage_edges_public_ref_key unique (public_ref),
  constraint source_lineage_edges_has_target_chk check (to_raw_record_id is not null or (derived_object_schema is not null and derived_object_table is not null and derived_object_id is not null)),
  constraint source_lineage_edges_not_self_chk check (from_raw_record_id is null or to_raw_record_id is null or from_raw_record_id <> to_raw_record_id),
  constraint source_lineage_edges_lineage_kind_chk check (lineage_kind in ('same_source','supersedes','enrichment_response_for','derived_from','candidate_dto_for','matrix_mapping_input','manual_review_link','unknown')),
  constraint source_lineage_edges_confidence_level_chk check (confidence_level in ('unknown','low','medium','high','reviewed')),
  constraint source_lineage_edges_mapping_metadata_object_chk check (jsonb_typeof(mapping_metadata) = 'object'),
  constraint source_lineage_edges_version_positive_chk check (version > 0)
);

create index if not exists source_lineage_edges_from_idx
  on prop4you_sourcehub.source_lineage_edges (from_raw_record_id, lineage_kind);
create index if not exists source_lineage_edges_to_idx
  on prop4you_sourcehub.source_lineage_edges (to_raw_record_id, lineage_kind);
create index if not exists source_lineage_edges_derived_object_idx
  on prop4you_sourcehub.source_lineage_edges (derived_object_schema, derived_object_table, derived_object_id)
  where derived_object_id is not null;
create index if not exists source_lineage_edges_metadata_gin_idx
  on prop4you_sourcehub.source_lineage_edges using gin (mapping_metadata jsonb_path_ops);

comment on table prop4you_sourcehub.source_lineage_edges is
'Experimental lineage graph linking raw records to other raw records or later derived object identifiers. It preserves evidence relationships without declaring final property, owner, or lead truth.';
comment on column prop4you_sourcehub.source_lineage_edges.id is 'UUIDv7 primary key for one SourceHub lineage edge.';
comment on column prop4you_sourcehub.source_lineage_edges.public_ref is 'Generated public reference with p4yshl prefix and the lineage edge UUID.';
comment on column prop4you_sourcehub.source_lineage_edges.from_raw_record_id is 'Source raw record at the start of the lineage edge, when the relationship begins from raw evidence.';
comment on column prop4you_sourcehub.source_lineage_edges.to_raw_record_id is 'Target raw record for raw-to-raw lineage, such as an enrichment response linked to a prior raw record.';
comment on column prop4you_sourcehub.source_lineage_edges.derived_object_schema is 'Optional schema name for a later derived/canonical object target; used only as lineage metadata in this experimental slice.';
comment on column prop4you_sourcehub.source_lineage_edges.derived_object_table is 'Optional table name for a later derived/canonical object target; no foreign key is implied here.';
comment on column prop4you_sourcehub.source_lineage_edges.derived_object_id is 'Optional UUID of a later derived/canonical object target; semantics are owned by that future bounded context.';
comment on column prop4you_sourcehub.source_lineage_edges.lineage_kind is 'Relationship kind, such as enrichment_response_for, derived_from, candidate_dto_for, or matrix_mapping_input.';
comment on column prop4you_sourcehub.source_lineage_edges.confidence_level is 'Reviewer-assigned confidence for the lineage relationship: unknown, low, medium, high, or reviewed.';
comment on column prop4you_sourcehub.source_lineage_edges.evidence_summary is 'Optional short evidence note explaining why this lineage edge exists.';
comment on column prop4you_sourcehub.source_lineage_edges.mapping_metadata is 'Non-secret JSONB object containing path/mapping hints or reviewer evidence for the lineage edge.';
comment on column prop4you_sourcehub.source_lineage_edges.active is 'Lifecycle flag indicating whether this lineage edge is active for review.';
comment on column prop4you_sourcehub.source_lineage_edges.activated_at is 'Timestamp when this lineage edge became active under the base lifecycle convention.';
comment on column prop4you_sourcehub.source_lineage_edges.deactivated_at is 'Timestamp when this lineage edge was deactivated without deleting lineage history.';
comment on column prop4you_sourcehub.source_lineage_edges.deleted is 'Soft-delete lifecycle flag for lineage edge review scope.';
comment on column prop4you_sourcehub.source_lineage_edges.deleted_at is 'Timestamp when this lineage edge was soft-deleted, when applicable.';
comment on column prop4you_sourcehub.source_lineage_edges.deleted_by_actor_id is 'Optional actor identifier responsible for soft-deleting this lineage edge.';
comment on column prop4you_sourcehub.source_lineage_edges.created_at is 'Timestamp when this lineage edge row was inserted.';
comment on column prop4you_sourcehub.source_lineage_edges.updated_at is 'Timestamp when this lineage edge row was last updated.';
comment on column prop4you_sourcehub.source_lineage_edges.last_modified_by_actor_id is 'Optional actor identifier supplied by database request context or review tooling.';
comment on column prop4you_sourcehub.source_lineage_edges.version is 'Optimistic lifecycle version incremented by the standard base trigger on updates.';

create table if not exists prop4you_sourcehub.enrichment_requests (
  id uuid primary key default uuidv7(),
  public_ref text generated always as (base.make_public_ref('p4yshe', id)) stored,
  provider_id uuid not null references prop4you_provider.providers(id) on delete restrict,
  payload_class_id uuid references prop4you_provider.payload_classes(id) on delete restrict,
  requested_from_raw_record_id uuid references prop4you_sourcehub.raw_records(id) on delete set null,
  response_raw_record_id uuid references prop4you_sourcehub.raw_records(id) on delete set null,
  request_status text not null default 'queued',
  request_priority integer not null default 100,
  lookup_kind text not null,
  trigger_kind text not null default 'manual_review',
  trigger_object_schema name,
  trigger_object_table name,
  trigger_object_id uuid,
  idempotency_key text,
  requested_at timestamptz not null default now(),
  not_before timestamptz,
  started_at timestamptz,
  finished_at timestamptz,
  attempts integer not null default 0,
  max_attempts integer not null default 1,
  request_payload jsonb not null default '{}'::jsonb,
  provider_request_ref text,
  last_error_code text,
  last_error_summary text,
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
  constraint enrichment_requests_public_ref_key unique (public_ref),
  constraint enrichment_requests_provider_idempotency_key unique (provider_id, idempotency_key),
  constraint enrichment_requests_status_chk check (request_status in ('queued','blocked','ready','in_progress','succeeded','failed','cancelled','superseded')),
  constraint enrichment_requests_priority_chk check (request_priority between 0 and 1000),
  constraint enrichment_requests_lookup_kind_chk check (lookup_kind in ('property_detail','owner_profile','skip_trace','listing_search','contact_append','manual_context','unknown')),
  constraint enrichment_requests_trigger_kind_chk check (trigger_kind in ('django_style_signal','domain_event','manual_review','matrix_gap','leadfinder_gap','backfill','unknown')),
  constraint enrichment_requests_trigger_object_chk check ((trigger_object_schema is null and trigger_object_table is null and trigger_object_id is null) or (trigger_object_schema is not null and trigger_object_table is not null and trigger_object_id is not null)),
  constraint enrichment_requests_idempotency_key_chk check (idempotency_key is null or length(btrim(idempotency_key)) > 0),
  constraint enrichment_requests_attempts_chk check (attempts >= 0 and max_attempts > 0 and attempts <= max_attempts),
  constraint enrichment_requests_request_payload_object_chk check (jsonb_typeof(request_payload) = 'object'),
  constraint enrichment_requests_metadata_object_chk check (jsonb_typeof(metadata) = 'object'),
  constraint enrichment_requests_finish_after_start_chk check (finished_at is null or started_at is null or finished_at >= started_at),
  constraint enrichment_requests_version_positive_chk check (version > 0)
);

create index if not exists enrichment_requests_queue_idx
  on prop4you_sourcehub.enrichment_requests (request_status, request_priority, not_before, requested_at)
  where request_status in ('queued','ready','blocked');
create index if not exists enrichment_requests_provider_status_idx
  on prop4you_sourcehub.enrichment_requests (provider_id, request_status, lookup_kind);
create index if not exists enrichment_requests_trigger_object_idx
  on prop4you_sourcehub.enrichment_requests (trigger_object_schema, trigger_object_table, trigger_object_id)
  where trigger_object_id is not null;
create index if not exists enrichment_requests_requested_from_raw_idx
  on prop4you_sourcehub.enrichment_requests (requested_from_raw_record_id)
  where requested_from_raw_record_id is not null;
create index if not exists enrichment_requests_metadata_gin_idx
  on prop4you_sourcehub.enrichment_requests using gin (metadata jsonb_path_ops);

comment on table prop4you_sourcehub.enrichment_requests is
'Experimental SourceHub queue concept for Django-style extra data lookup triggers. Rows describe enrichment intent and status only; external workers may consume them later, but this DDL never calls providers.';
comment on column prop4you_sourcehub.enrichment_requests.id is 'UUIDv7 primary key for one enrichment request intent.';
comment on column prop4you_sourcehub.enrichment_requests.public_ref is 'Generated public reference with p4yshe prefix and the enrichment request UUID.';
comment on column prop4you_sourcehub.enrichment_requests.provider_id is 'Provider or internal origin that would satisfy the requested enrichment if a future worker is authorized.';
comment on column prop4you_sourcehub.enrichment_requests.payload_class_id is 'Optional expected payload class for the future enrichment response.';
comment on column prop4you_sourcehub.enrichment_requests.requested_from_raw_record_id is 'Optional raw record whose content or review gap triggered the enrichment request.';
comment on column prop4you_sourcehub.enrichment_requests.response_raw_record_id is 'Optional raw record storing the later provider/internal response payload when available.';
comment on column prop4you_sourcehub.enrichment_requests.request_status is 'Queue/review state: queued, blocked, ready, in_progress, succeeded, failed, cancelled, or superseded.';
comment on column prop4you_sourcehub.enrichment_requests.request_priority is 'Integer priority for future queue consumers; lower values are intended to run first.';
comment on column prop4you_sourcehub.enrichment_requests.lookup_kind is 'Kind of extra lookup requested, preserving the old Django-style trigger idea without embedding provider client code.';
comment on column prop4you_sourcehub.enrichment_requests.trigger_kind is 'Kind of application/database event that requested extra data, such as django_style_signal, matrix_gap, or leadfinder_gap.';
comment on column prop4you_sourcehub.enrichment_requests.trigger_object_schema is 'Optional schema for the domain object or review artifact that triggered the enrichment request.';
comment on column prop4you_sourcehub.enrichment_requests.trigger_object_table is 'Optional table for the domain object or review artifact that triggered the enrichment request.';
comment on column prop4you_sourcehub.enrichment_requests.trigger_object_id is 'Optional UUID for the domain object or review artifact that triggered the enrichment request.';
comment on column prop4you_sourcehub.enrichment_requests.idempotency_key is 'Optional provider-scoped deduplication key for future workers; it must not contain secrets.';
comment on column prop4you_sourcehub.enrichment_requests.requested_at is 'Timestamp when the enrichment intent was recorded in SourceHub.';
comment on column prop4you_sourcehub.enrichment_requests.not_before is 'Optional scheduling guard for future queue consumers; no pg_cron or external worker is created here.';
comment on column prop4you_sourcehub.enrichment_requests.started_at is 'Optional timestamp when a future authorized worker starts processing the request.';
comment on column prop4you_sourcehub.enrichment_requests.finished_at is 'Optional timestamp when future processing succeeds, fails, or is cancelled.';
comment on column prop4you_sourcehub.enrichment_requests.attempts is 'Number of processing attempts recorded by future workers or review tooling.';
comment on column prop4you_sourcehub.enrichment_requests.max_attempts is 'Maximum processing attempts allowed by future queue policy.';
comment on column prop4you_sourcehub.enrichment_requests.request_payload is 'Non-secret JSONB object describing lookup parameters for review/future workers; it is not a provider call and must not contain credentials.';
comment on column prop4you_sourcehub.enrichment_requests.provider_request_ref is 'Optional non-secret provider correlation reference after a future worker acts.';
comment on column prop4you_sourcehub.enrichment_requests.last_error_code is 'Optional short machine-readable error code recorded by future processing or review.';
comment on column prop4you_sourcehub.enrichment_requests.last_error_summary is 'Optional short human-readable error summary; no provider secrets or raw payload fragments should be stored here.';
comment on column prop4you_sourcehub.enrichment_requests.metadata is 'Non-secret JSONB object for queue/review metadata and gating decisions.';
comment on column prop4you_sourcehub.enrichment_requests.active is 'Lifecycle flag indicating whether the enrichment request remains active for queue/review scope.';
comment on column prop4you_sourcehub.enrichment_requests.activated_at is 'Timestamp when this enrichment request became active under the base lifecycle convention.';
comment on column prop4you_sourcehub.enrichment_requests.deactivated_at is 'Timestamp when this enrichment request was deactivated without deleting queue history.';
comment on column prop4you_sourcehub.enrichment_requests.deleted is 'Soft-delete lifecycle flag for enrichment request review scope.';
comment on column prop4you_sourcehub.enrichment_requests.deleted_at is 'Timestamp when this enrichment request was soft-deleted, when applicable.';
comment on column prop4you_sourcehub.enrichment_requests.deleted_by_actor_id is 'Optional actor identifier responsible for soft-deleting this enrichment request.';
comment on column prop4you_sourcehub.enrichment_requests.created_at is 'Timestamp when this enrichment request row was inserted.';
comment on column prop4you_sourcehub.enrichment_requests.updated_at is 'Timestamp when this enrichment request row was last updated.';
comment on column prop4you_sourcehub.enrichment_requests.last_modified_by_actor_id is 'Optional actor identifier supplied by database request context or review tooling.';
comment on column prop4you_sourcehub.enrichment_requests.version is 'Optimistic lifecycle version incremented by the standard base trigger on updates.';

create or replace function prop4you_sourcehub.enqueue_enrichment_request(
  p_provider_id uuid,
  p_lookup_kind text,
  p_trigger_kind text default 'manual_review',
  p_payload_class_id uuid default null,
  p_requested_from_raw_record_id uuid default null,
  p_trigger_object_schema name default null,
  p_trigger_object_table name default null,
  p_trigger_object_id uuid default null,
  p_idempotency_key text default null,
  p_request_payload jsonb default '{}'::jsonb,
  p_request_priority integer default 100,
  p_not_before timestamptz default null,
  p_metadata jsonb default '{}'::jsonb
)
returns prop4you_sourcehub.enrichment_requests
language plpgsql
volatile
as $$
declare
  row_out prop4you_sourcehub.enrichment_requests;
begin
  insert into prop4you_sourcehub.enrichment_requests as r (
    provider_id,
    payload_class_id,
    requested_from_raw_record_id,
    request_status,
    request_priority,
    lookup_kind,
    trigger_kind,
    trigger_object_schema,
    trigger_object_table,
    trigger_object_id,
    idempotency_key,
    not_before,
    request_payload,
    metadata
  ) values (
    p_provider_id,
    p_payload_class_id,
    p_requested_from_raw_record_id,
    case when p_not_before is null or p_not_before <= now() then 'ready' else 'queued' end,
    p_request_priority,
    p_lookup_kind,
    p_trigger_kind,
    p_trigger_object_schema,
    p_trigger_object_table,
    p_trigger_object_id,
    nullif(btrim(p_idempotency_key), ''),
    p_not_before,
    coalesce(p_request_payload, '{}'::jsonb),
    coalesce(p_metadata, '{}'::jsonb)
  )
  on conflict (provider_id, idempotency_key) do update
    set payload_class_id = coalesce(excluded.payload_class_id, r.payload_class_id),
        requested_from_raw_record_id = coalesce(excluded.requested_from_raw_record_id, r.requested_from_raw_record_id),
        request_status = case when r.request_status in ('succeeded','in_progress') then r.request_status else excluded.request_status end,
        request_priority = least(r.request_priority, excluded.request_priority),
        lookup_kind = excluded.lookup_kind,
        trigger_kind = excluded.trigger_kind,
        trigger_object_schema = excluded.trigger_object_schema,
        trigger_object_table = excluded.trigger_object_table,
        trigger_object_id = excluded.trigger_object_id,
        not_before = excluded.not_before,
        request_payload = excluded.request_payload,
        metadata = r.metadata || excluded.metadata,
        updated_at = now()
  returning * into row_out;

  return row_out;
end;
$$;

comment on function prop4you_sourcehub.enqueue_enrichment_request(uuid,text,text,uuid,uuid,name,name,uuid,text,jsonb,integer,timestamptz,jsonb) is
'Records or deduplicates an enrichment request intent for future workers. This preserves Django-style extra lookup triggering as database state and performs no provider call.';

create or replace function prop4you_sourcehub.mark_enrichment_response(
  p_enrichment_request_id uuid,
  p_response_raw_record_id uuid,
  p_provider_request_ref text default null,
  p_metadata jsonb default '{}'::jsonb
)
returns prop4you_sourcehub.enrichment_requests
language plpgsql
volatile
as $$
declare
  row_out prop4you_sourcehub.enrichment_requests;
begin
  update prop4you_sourcehub.enrichment_requests
     set response_raw_record_id = p_response_raw_record_id,
         request_status = 'succeeded',
         provider_request_ref = coalesce(p_provider_request_ref, provider_request_ref),
         finished_at = coalesce(finished_at, now()),
         metadata = metadata || coalesce(p_metadata, '{}'::jsonb),
         updated_at = now()
   where id = p_enrichment_request_id
   returning * into row_out;

  if row_out.id is null then
    raise exception 'enrichment request % not found', p_enrichment_request_id using errcode = '22023';
  end if;

  insert into prop4you_sourcehub.source_lineage_edges (
    from_raw_record_id,
    to_raw_record_id,
    lineage_kind,
    confidence_level,
    evidence_summary,
    mapping_metadata
  ) values (
    row_out.requested_from_raw_record_id,
    p_response_raw_record_id,
    'enrichment_response_for',
    'reviewed',
    'Enrichment response linked by mark_enrichment_response.',
    jsonb_build_object('enrichment_request_id', p_enrichment_request_id)
  );

  return row_out;
end;
$$;

comment on function prop4you_sourcehub.mark_enrichment_response(uuid,uuid,text,jsonb) is
'Links a completed enrichment request to a SourceHub raw response record and writes a lineage edge. It does not validate provider payload semantics or publish canonical DTOs.';

drop trigger if exists raw_records_set_lifecycle_defaults on prop4you_sourcehub.raw_records;
create trigger raw_records_set_lifecycle_defaults
  before insert on prop4you_sourcehub.raw_records
  for each row execute function base.set_lifecycle_defaults();
comment on trigger raw_records_set_lifecycle_defaults on prop4you_sourcehub.raw_records is
'Applies standard base lifecycle defaults before inserting raw SourceHub records.';

drop trigger if exists raw_records_touch_updated_at on prop4you_sourcehub.raw_records;
create trigger raw_records_touch_updated_at
  before update on prop4you_sourcehub.raw_records
  for each row execute function base.touch_updated_at();
comment on trigger raw_records_touch_updated_at on prop4you_sourcehub.raw_records is
'Updates updated_at and last_modified_by_actor_id before raw SourceHub records change.';

drop trigger if exists raw_records_increment_version on prop4you_sourcehub.raw_records;
create trigger raw_records_increment_version
  before update on prop4you_sourcehub.raw_records
  for each row execute function base.increment_version();
comment on trigger raw_records_increment_version on prop4you_sourcehub.raw_records is
'Increments the lifecycle version before raw SourceHub records change.';

drop trigger if exists corpus_samples_set_lifecycle_defaults on prop4you_sourcehub.corpus_samples;
create trigger corpus_samples_set_lifecycle_defaults
  before insert on prop4you_sourcehub.corpus_samples
  for each row execute function base.set_lifecycle_defaults();
comment on trigger corpus_samples_set_lifecycle_defaults on prop4you_sourcehub.corpus_samples is
'Applies standard base lifecycle defaults before inserting private corpus sample metadata.';

drop trigger if exists corpus_samples_touch_updated_at on prop4you_sourcehub.corpus_samples;
create trigger corpus_samples_touch_updated_at
  before update on prop4you_sourcehub.corpus_samples
  for each row execute function base.touch_updated_at();
comment on trigger corpus_samples_touch_updated_at on prop4you_sourcehub.corpus_samples is
'Updates updated_at and last_modified_by_actor_id before private corpus sample metadata changes.';

drop trigger if exists corpus_samples_increment_version on prop4you_sourcehub.corpus_samples;
create trigger corpus_samples_increment_version
  before update on prop4you_sourcehub.corpus_samples
  for each row execute function base.increment_version();
comment on trigger corpus_samples_increment_version on prop4you_sourcehub.corpus_samples is
'Increments the lifecycle version before private corpus sample metadata changes.';

drop trigger if exists source_lineage_edges_set_lifecycle_defaults on prop4you_sourcehub.source_lineage_edges;
create trigger source_lineage_edges_set_lifecycle_defaults
  before insert on prop4you_sourcehub.source_lineage_edges
  for each row execute function base.set_lifecycle_defaults();
comment on trigger source_lineage_edges_set_lifecycle_defaults on prop4you_sourcehub.source_lineage_edges is
'Applies standard base lifecycle defaults before inserting SourceHub lineage edges.';

drop trigger if exists source_lineage_edges_touch_updated_at on prop4you_sourcehub.source_lineage_edges;
create trigger source_lineage_edges_touch_updated_at
  before update on prop4you_sourcehub.source_lineage_edges
  for each row execute function base.touch_updated_at();
comment on trigger source_lineage_edges_touch_updated_at on prop4you_sourcehub.source_lineage_edges is
'Updates updated_at and last_modified_by_actor_id before SourceHub lineage edges change.';

drop trigger if exists source_lineage_edges_increment_version on prop4you_sourcehub.source_lineage_edges;
create trigger source_lineage_edges_increment_version
  before update on prop4you_sourcehub.source_lineage_edges
  for each row execute function base.increment_version();
comment on trigger source_lineage_edges_increment_version on prop4you_sourcehub.source_lineage_edges is
'Increments the lifecycle version before SourceHub lineage edges change.';

drop trigger if exists enrichment_requests_set_lifecycle_defaults on prop4you_sourcehub.enrichment_requests;
create trigger enrichment_requests_set_lifecycle_defaults
  before insert on prop4you_sourcehub.enrichment_requests
  for each row execute function base.set_lifecycle_defaults();
comment on trigger enrichment_requests_set_lifecycle_defaults on prop4you_sourcehub.enrichment_requests is
'Applies standard base lifecycle defaults before inserting enrichment request queue rows.';

drop trigger if exists enrichment_requests_touch_updated_at on prop4you_sourcehub.enrichment_requests;
create trigger enrichment_requests_touch_updated_at
  before update on prop4you_sourcehub.enrichment_requests
  for each row execute function base.touch_updated_at();
comment on trigger enrichment_requests_touch_updated_at on prop4you_sourcehub.enrichment_requests is
'Updates updated_at and last_modified_by_actor_id before enrichment request rows change.';

drop trigger if exists enrichment_requests_increment_version on prop4you_sourcehub.enrichment_requests;
create trigger enrichment_requests_increment_version
  before update on prop4you_sourcehub.enrichment_requests
  for each row execute function base.increment_version();
comment on trigger enrichment_requests_increment_version on prop4you_sourcehub.enrichment_requests is
'Increments the lifecycle version before enrichment request rows change.';

select base.register_public_id_prefix('p4yshr', 'prop4you_sourcehub', 'raw_records', 'Prop4You SourceHub raw record');
select base.register_public_id_prefix('p4yshs', 'prop4you_sourcehub', 'corpus_samples', 'Prop4You SourceHub corpus sample');
select base.register_public_id_prefix('p4yshl', 'prop4you_sourcehub', 'source_lineage_edges', 'Prop4You SourceHub lineage edge');
select base.register_public_id_prefix('p4yshe', 'prop4you_sourcehub', 'enrichment_requests', 'Prop4You SourceHub enrichment request');
