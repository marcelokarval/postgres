-- package: prop4you/matrix
-- file: 0001_semantic_dictionary.sql
-- status: experimental / non-final
-- purpose: Matrix semantic dictionary, canonical field catalog, provider JSON path mappings, and review gates for Prop4You corpus-driven DDL.
-- depends-on: database/ddl/base, database/ddl/projects/prop4you/0001_schemas.sql, database/ddl/projects/prop4you/providers/0001_provider_registry.sql, database/ddl/projects/prop4you/sourcehub/0001_sourcehub_corpus.sql
-- idempotency: idempotent
-- destructive: false
-- review-gate: provider_payload_corpus_review
-- [NO_FIXTURES] This DDL creates catalogs and dictionary seeds only; it does not insert raw/fake/redacted payload fixtures.
-- [NO_PROVIDER_CALLS] This DDL contains no provider client, HTTP call, or runtime lookup implementation.

create schema if not exists prop4you_matrix;
comment on schema prop4you_matrix is
'Prop4You Matrix schema. Experimental non-final semantic dictionary and provider JSON path mapping gate used before SourceHub payloads can be treated as LeadFinder canonical DTO inputs.';

create table if not exists prop4you_matrix.canonical_families (
  id uuid primary key default uuidv7(),
  family_key text not null,
  display_name text not null,
  family_role text not null,
  description text not null,
  review_status text not null default 'candidate',
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint canonical_families_family_key_key unique (family_key),
  constraint canonical_families_family_key_format_chk check (family_key ~ '^[a-z][a-z0-9_]{1,79}$'),
  constraint canonical_families_family_role_chk check (family_role in ('identity','property','owner','ownership','contact','situation','valuation','listing','lineage','operational','unknown')),
  constraint canonical_families_review_status_chk check (review_status in ('candidate','in_review','approved','deprecated','rejected')),
  constraint canonical_families_metadata_object_chk check (jsonb_typeof(metadata) = 'object')
);

comment on table prop4you_matrix.canonical_families is
'Experimental Matrix catalog of canonical semantic families used to compare provider/internal payload fields before Prop4You final tables are frozen.';
comment on column prop4you_matrix.canonical_families.id is 'UUIDv7 primary key for one Matrix canonical family.';
comment on column prop4you_matrix.canonical_families.family_key is 'Stable lowercase semantic family key, for example property_identity, owner_identity, contact, valuation, or lineage.';
comment on column prop4you_matrix.canonical_families.display_name is 'Human-readable semantic family label.';
comment on column prop4you_matrix.canonical_families.family_role is 'Coarse semantic role used for review grouping and DDL freeze decisions.';
comment on column prop4you_matrix.canonical_families.description is 'Objective explanation of what this semantic family means in Prop4You.';
comment on column prop4you_matrix.canonical_families.review_status is 'Matrix review state for this canonical family.';
comment on column prop4you_matrix.canonical_families.metadata is 'Non-secret JSONB review metadata for this canonical family.';
comment on column prop4you_matrix.canonical_families.created_at is 'Timestamp when this canonical family was inserted.';
comment on column prop4you_matrix.canonical_families.updated_at is 'Timestamp when this canonical family was last updated.';

create table if not exists prop4you_matrix.canonical_fields (
  id uuid primary key default uuidv7(),
  family_id uuid not null references prop4you_matrix.canonical_families(id) on delete restrict,
  field_key text not null,
  display_name text not null,
  value_kind text not null,
  cardinality text not null default 'one',
  materialization_policy text not null default 'review_required',
  description text not null,
  review_status text not null default 'candidate',
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint canonical_fields_family_field_key unique (family_id, field_key),
  constraint canonical_fields_field_key_format_chk check (field_key ~ '^[a-z][a-z0-9_]{1,79}$'),
  constraint canonical_fields_value_kind_chk check (value_kind in ('text','integer','numeric','boolean','date','timestamp','jsonb','uuid','enum','unknown')),
  constraint canonical_fields_cardinality_chk check (cardinality in ('one','optional','many','unknown')),
  constraint canonical_fields_materialization_policy_chk check (materialization_policy in ('raw_only','evidence_only','review_required','dto_candidate','canonical_candidate','canonical_approved')),
  constraint canonical_fields_review_status_chk check (review_status in ('candidate','in_review','approved','deprecated','rejected')),
  constraint canonical_fields_metadata_object_chk check (jsonb_typeof(metadata) = 'object')
);

create index if not exists canonical_fields_family_status_idx
  on prop4you_matrix.canonical_fields (family_id, review_status);

comment on table prop4you_matrix.canonical_fields is
'Experimental Matrix catalog of canonical field meanings. A row here declares meaning, not final physical table placement.';
comment on column prop4you_matrix.canonical_fields.id is 'UUIDv7 primary key for one canonical field meaning.';
comment on column prop4you_matrix.canonical_fields.family_id is 'Canonical semantic family that owns this field meaning.';
comment on column prop4you_matrix.canonical_fields.field_key is 'Stable field key within its family, independent of provider path names.';
comment on column prop4you_matrix.canonical_fields.display_name is 'Human-readable canonical field name.';
comment on column prop4you_matrix.canonical_fields.value_kind is 'Expected normalized value kind for this field meaning.';
comment on column prop4you_matrix.canonical_fields.cardinality is 'Whether the field meaning is one, optional, many, or not yet known.';
comment on column prop4you_matrix.canonical_fields.materialization_policy is 'Controls whether provider values stay raw/evidence, can form DTO candidates, or may be promoted later.';
comment on column prop4you_matrix.canonical_fields.description is 'Objective explanation of this field meaning and why it matters.';
comment on column prop4you_matrix.canonical_fields.review_status is 'Matrix review state for this canonical field.';
comment on column prop4you_matrix.canonical_fields.metadata is 'Non-secret JSONB review metadata for this canonical field.';
comment on column prop4you_matrix.canonical_fields.created_at is 'Timestamp when this canonical field was inserted.';
comment on column prop4you_matrix.canonical_fields.updated_at is 'Timestamp when this canonical field was last updated.';

create table if not exists prop4you_matrix.mapping_versions (
  id uuid primary key default uuidv7(),
  version_key text not null,
  provider_id uuid references prop4you_provider.providers(id) on delete restrict,
  payload_class_id uuid references prop4you_provider.payload_classes(id) on delete restrict,
  artifact_status text not null default 'draft',
  review_notes text,
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint mapping_versions_version_key_key unique (version_key),
  constraint mapping_versions_version_key_format_chk check (version_key ~ '^[a-z][a-z0-9_.:-]{1,127}$'),
  constraint mapping_versions_artifact_status_chk check (artifact_status in ('draft','in_review','approved','superseded','rejected')),
  constraint mapping_versions_metadata_object_chk check (jsonb_typeof(metadata) = 'object')
);

comment on table prop4you_matrix.mapping_versions is
'Experimental catalog of Matrix mapping artifacts. Approved mappings gate SourceHub DTO publication and later LeadFinder materialization.';
comment on column prop4you_matrix.mapping_versions.id is 'UUIDv7 primary key for one mapping version artifact.';
comment on column prop4you_matrix.mapping_versions.version_key is 'Stable mapping version key, such as reiq.pre_foreclosure.tx.v1 or directskip.skip_trace_contact_discovery.v2.';
comment on column prop4you_matrix.mapping_versions.provider_id is 'Provider/origin associated with this mapping artifact, when known.';
comment on column prop4you_matrix.mapping_versions.payload_class_id is 'Payload class associated with this mapping artifact, when known.';
comment on column prop4you_matrix.mapping_versions.artifact_status is 'Review status of the mapping artifact.';
comment on column prop4you_matrix.mapping_versions.review_notes is 'Optional objective reviewer notes; no raw payload values or secrets belong here.';
comment on column prop4you_matrix.mapping_versions.metadata is 'Non-secret JSONB metadata for the mapping artifact.';
comment on column prop4you_matrix.mapping_versions.created_at is 'Timestamp when this mapping version was inserted.';
comment on column prop4you_matrix.mapping_versions.updated_at is 'Timestamp when this mapping version was last updated.';

create table if not exists prop4you_matrix.provider_path_mappings (
  id uuid primary key default uuidv7(),
  provider_id uuid not null references prop4you_provider.providers(id) on delete restrict,
  payload_class_id uuid references prop4you_provider.payload_classes(id) on delete restrict,
  mapping_version_id uuid references prop4you_matrix.mapping_versions(id) on delete set null,
  canonical_field_id uuid not null references prop4you_matrix.canonical_fields(id) on delete restrict,
  provider_path text[] not null,
  provider_path_label text,
  observed_json_type text not null default 'unknown',
  path_status text not null default 'candidate',
  confidence_level text not null default 'unknown',
  transform_hint text,
  source_priority integer not null default 100,
  notes text,
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint provider_path_mappings_unique_path unique (provider_id, payload_class_id, canonical_field_id, provider_path),
  constraint provider_path_mappings_path_not_empty_chk check (cardinality(provider_path) > 0),
  constraint provider_path_mappings_json_type_chk check (observed_json_type in ('object','array','string','number','boolean','null','unknown','mixed')),
  constraint provider_path_mappings_path_status_chk check (path_status in ('candidate','in_review','approved','conflicting','deprecated','rejected')),
  constraint provider_path_mappings_confidence_chk check (confidence_level in ('unknown','low','medium','high','authoritative')),
  constraint provider_path_mappings_priority_positive_chk check (source_priority > 0),
  constraint provider_path_mappings_metadata_object_chk check (jsonb_typeof(metadata) = 'object')
);

create index if not exists provider_path_mappings_provider_status_idx
  on prop4you_matrix.provider_path_mappings (provider_id, path_status, source_priority);
create index if not exists provider_path_mappings_canonical_idx
  on prop4you_matrix.provider_path_mappings (canonical_field_id, path_status);
create index if not exists provider_path_mappings_metadata_gin_idx
  on prop4you_matrix.provider_path_mappings using gin (metadata jsonb_path_ops);

comment on table prop4you_matrix.provider_path_mappings is
'Experimental mapping from provider/internal JSONB text[] paths to Matrix canonical fields. This table is the review gate before generated fields or final DDL columns are frozen.';
comment on column prop4you_matrix.provider_path_mappings.id is 'UUIDv7 primary key for one provider path mapping candidate or approved mapping.';
comment on column prop4you_matrix.provider_path_mappings.provider_id is 'Provider or internal origin that exposes the JSON path.';
comment on column prop4you_matrix.provider_path_mappings.payload_class_id is 'Optional payload class where this path was observed.';
comment on column prop4you_matrix.provider_path_mappings.mapping_version_id is 'Optional Matrix mapping artifact version that owns or proposed this path mapping.';
comment on column prop4you_matrix.provider_path_mappings.canonical_field_id is 'Canonical Matrix field meaning that the provider path may represent.';
comment on column prop4you_matrix.provider_path_mappings.provider_path is 'PostgreSQL text[] JSONB path components. Array indexes may be represented as numeric path strings for review.';
comment on column prop4you_matrix.provider_path_mappings.provider_path_label is 'Optional human-readable dotted/bracket path label for reviewers.';
comment on column prop4you_matrix.provider_path_mappings.observed_json_type is 'Observed JSON type or mixed/unknown classification for values at the provider path.';
comment on column prop4you_matrix.provider_path_mappings.path_status is 'Review state of this provider path mapping.';
comment on column prop4you_matrix.provider_path_mappings.confidence_level is 'Confidence that the provider path represents the selected canonical field.';
comment on column prop4you_matrix.provider_path_mappings.transform_hint is 'Optional non-executable transformation hint such as trim, normalize_phone, cast_numeric, or json_table_array.';
comment on column prop4you_matrix.provider_path_mappings.source_priority is 'Provider priority for conflict review. Lower numbers are preferred when competing sources map to the same canonical meaning.';
comment on column prop4you_matrix.provider_path_mappings.notes is 'Objective reviewer notes; no raw payload values or secrets belong here.';
comment on column prop4you_matrix.provider_path_mappings.metadata is 'Non-secret JSONB review metadata for this provider path mapping.';
comment on column prop4you_matrix.provider_path_mappings.created_at is 'Timestamp when this provider path mapping was inserted.';
comment on column prop4you_matrix.provider_path_mappings.updated_at is 'Timestamp when this provider path mapping was last updated.';

create table if not exists prop4you_matrix.mapping_reviews (
  id uuid primary key default uuidv7(),
  mapping_version_id uuid references prop4you_matrix.mapping_versions(id) on delete set null,
  canonical_field_id uuid references prop4you_matrix.canonical_fields(id) on delete set null,
  raw_record_id uuid references prop4you_sourcehub.raw_records(id) on delete set null,
  review_status text not null default 'open',
  decision text not null default 'undecided',
  reviewer_actor_id text,
  decision_summary text,
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint mapping_reviews_review_status_chk check (review_status in ('open','in_review','closed','superseded')),
  constraint mapping_reviews_decision_chk check (decision in ('undecided','approve','reject','needs_more_corpus','conflict','defer')),
  constraint mapping_reviews_metadata_object_chk check (jsonb_typeof(metadata) = 'object')
);

comment on table prop4you_matrix.mapping_reviews is
'Experimental Matrix review log for field/path/mapping decisions. It can reference SourceHub raw records without embedding raw payload values in review notes.';
comment on column prop4you_matrix.mapping_reviews.id is 'UUIDv7 primary key for one Matrix mapping review row.';
comment on column prop4you_matrix.mapping_reviews.mapping_version_id is 'Optional mapping version under review.';
comment on column prop4you_matrix.mapping_reviews.canonical_field_id is 'Optional canonical field under review.';
comment on column prop4you_matrix.mapping_reviews.raw_record_id is 'Optional SourceHub raw record providing private evidence for the review.';
comment on column prop4you_matrix.mapping_reviews.review_status is 'Workflow status of this mapping review.';
comment on column prop4you_matrix.mapping_reviews.decision is 'Current review decision: undecided, approve, reject, needs_more_corpus, conflict, or defer.';
comment on column prop4you_matrix.mapping_reviews.reviewer_actor_id is 'Optional reviewer actor identifier; not a user authentication contract.';
comment on column prop4you_matrix.mapping_reviews.decision_summary is 'Short objective review summary; no raw payload values or secrets belong here.';
comment on column prop4you_matrix.mapping_reviews.metadata is 'Non-secret JSONB metadata about the review.';
comment on column prop4you_matrix.mapping_reviews.created_at is 'Timestamp when this review row was inserted.';
comment on column prop4you_matrix.mapping_reviews.updated_at is 'Timestamp when this review row was last updated.';

insert into prop4you_matrix.canonical_families
  (family_key, display_name, family_role, description, review_status, metadata)
values
  ('property_identity', 'Property identity and address', 'property', 'Canonical family for property address, provider property references, and address matching evidence.', 'candidate', '{"seeded_by":"experimental_ddl"}'::jsonb),
  ('owner_identity', 'Owner identity', 'owner', 'Canonical family for owner/entity identity evidence and candidate owner resolution.', 'candidate', '{"seeded_by":"experimental_ddl"}'::jsonb),
  ('owner_contact', 'Owner contact evidence', 'contact', 'Canonical family for phone, email, mailing address, relative and relationship contact evidence.', 'candidate', '{"seeded_by":"experimental_ddl"}'::jsonb),
  ('situation_legal', 'Situation and legal timeline', 'situation', 'Canonical family for distress, legal, foreclosure, probate, eviction, tax and related situation evidence.', 'candidate', '{"seeded_by":"experimental_ddl"}'::jsonb),
  ('valuation_financial', 'Valuation and financial evidence', 'valuation', 'Canonical family for equity, valuation, estimate, listing price, loan and financial evidence.', 'candidate', '{"seeded_by":"experimental_ddl"}'::jsonb),
  ('listing_history_media', 'Listing, history and media', 'listing', 'Canonical family for Realtor/listing history, media and enrichment-only property facts.', 'candidate', '{"seeded_by":"experimental_ddl"}'::jsonb),
  ('lineage_provenance', 'Lineage and provenance', 'lineage', 'Canonical family for raw record, provider, mapping and publication provenance.', 'candidate', '{"seeded_by":"experimental_ddl"}'::jsonb)
on conflict (family_key) do update
  set display_name = excluded.display_name,
      family_role = excluded.family_role,
      description = excluded.description,
      review_status = excluded.review_status,
      metadata = excluded.metadata,
      updated_at = now();

insert into prop4you_matrix.mapping_versions
  (version_key, provider_id, payload_class_id, artifact_status, review_notes, metadata)
select v.version_key,
       p.id,
       pc.id,
       'draft',
       v.review_notes,
       v.metadata
from (values
  ('reiq.provider_corpus.v0', 'reiq', 'property_search_result', 'Draft umbrella mapping version for REIQ base/current data corpus review.', '{"source_priority":10}'::jsonb),
  ('directskip.provider_corpus.v0', 'directskip', 'skip_trace_result', 'Draft umbrella mapping version for DirectSkip owner/contact evidence corpus review.', '{"source_priority":20}'::jsonb),
  ('realtor.provider_corpus.v0', 'realtor_com', 'property_detail', 'Draft umbrella mapping version for Realtor.com enrichment corpus review.', '{"source_priority":30}'::jsonb),
  ('internal.provider_corpus.v0', 'prop4you_internal', 'leadfinder_candidate_snapshot', 'Draft umbrella mapping version for Prop4You internal/product-originated payload review.', '{"source_priority":40}'::jsonb)
) as v(version_key, provider_key, class_key, review_notes, metadata)
join prop4you_provider.providers p on p.provider_key = v.provider_key
join prop4you_provider.payload_classes pc on pc.class_key = v.class_key
on conflict (version_key) do update
  set provider_id = excluded.provider_id,
      payload_class_id = excluded.payload_class_id,
      artifact_status = excluded.artifact_status,
      review_notes = excluded.review_notes,
      metadata = excluded.metadata,
      updated_at = now();
