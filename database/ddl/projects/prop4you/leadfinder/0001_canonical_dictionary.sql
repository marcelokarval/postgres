-- package: prop4you/leadfinder
-- file: 0001_canonical_dictionary.sql
-- status: experimental / non-final
-- purpose: LeadFinder-owned canonical dictionary v0 for raw-derived family/field candidates, dictionary gaps, and growth-pressure signals.
-- depends-on: database/ddl/base, database/ddl/projects/prop4you/0001_schemas.sql
-- idempotency: idempotent
-- destructive: false
-- review-gate: leadfinder_dictionary_from_raws
-- [LEADFINDER_OWNS_CANONICAL] LeadFinder owns this canonical dictionary boundary; Matrix may mirror/candidate-map meanings but does not own final canonical graph semantics.
-- [NO_FIXTURES] This DDL creates dictionary catalogs and candidate seeds only; it does not insert raw/fake/redacted payload fixtures or raw payload values.
-- [NO_PROVIDER_CALLS] This DDL contains no provider client, HTTP call, runtime lookup, or enrichment implementation.

create schema if not exists prop4you_leadfinder;
comment on schema prop4you_leadfinder is
'Prop4You LeadFinder schema. Owns the experimental non-final canonical dictionary and later canonical graph materialization boundary after raw evidence is authorized through SourceHub and Matrix review.';

create table if not exists prop4you_leadfinder.canonical_dictionary_versions (
  id uuid primary key default uuidv7(),
  version_key text not null,
  display_name text not null,
  version_status text not null default 'draft',
  ownership_scope text not null default 'leadfinder_canonical_dictionary',
  source_basis text not null default 'raw_derived_candidate_review',
  description text not null,
  activated_at timestamptz,
  superseded_at timestamptz,
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint canonical_dictionary_versions_version_key_key unique (version_key),
  constraint canonical_dictionary_versions_version_key_format_chk check (version_key ~ '^[a-z][a-z0-9_.:-]{1,127}$'),
  constraint canonical_dictionary_versions_status_chk check (version_status in ('draft','in_review','approved','active','superseded','rejected')),
  constraint canonical_dictionary_versions_ownership_scope_chk check (ownership_scope in ('leadfinder_canonical_dictionary')),
  constraint canonical_dictionary_versions_source_basis_chk check (source_basis in ('raw_derived_candidate_review','manual_dictionary_review','migration_import','unknown')),
  constraint canonical_dictionary_versions_superseded_after_active_chk check (superseded_at is null or activated_at is null or superseded_at >= activated_at),
  constraint canonical_dictionary_versions_metadata_object_chk check (jsonb_typeof(metadata) = 'object')
);

comment on table prop4you_leadfinder.canonical_dictionary_versions is
'LeadFinder-owned dictionary version catalog. Versions group candidate families and fields while the model is experimental and non-final.';
comment on column prop4you_leadfinder.canonical_dictionary_versions.id is 'UUIDv7 primary key for one LeadFinder canonical dictionary version.';
comment on column prop4you_leadfinder.canonical_dictionary_versions.version_key is 'Stable dictionary version key, for example leadfinder.raw_candidate.v0.';
comment on column prop4you_leadfinder.canonical_dictionary_versions.display_name is 'Human-readable dictionary version label.';
comment on column prop4you_leadfinder.canonical_dictionary_versions.version_status is 'Review lifecycle for the dictionary version: draft, in_review, approved, active, superseded, or rejected.';
comment on column prop4you_leadfinder.canonical_dictionary_versions.ownership_scope is 'Fixed ownership scope proving this dictionary is LeadFinder-owned, not Matrix-owned.';
comment on column prop4you_leadfinder.canonical_dictionary_versions.source_basis is 'How this dictionary version was proposed, without embedding raw payload values.';
comment on column prop4you_leadfinder.canonical_dictionary_versions.description is 'Objective version description and non-final boundary notes.';
comment on column prop4you_leadfinder.canonical_dictionary_versions.activated_at is 'Timestamp when this dictionary version became active, if ever.';
comment on column prop4you_leadfinder.canonical_dictionary_versions.superseded_at is 'Timestamp when this dictionary version was superseded, if ever.';
comment on column prop4you_leadfinder.canonical_dictionary_versions.metadata is 'Non-secret JSONB metadata for review provenance and evidence-origin labels; raw payload values do not belong here.';
comment on column prop4you_leadfinder.canonical_dictionary_versions.created_at is 'Timestamp when this dictionary version row was inserted.';
comment on column prop4you_leadfinder.canonical_dictionary_versions.updated_at is 'Timestamp when this dictionary version row was last updated.';

create table if not exists prop4you_leadfinder.canonical_families (
  id uuid primary key default uuidv7(),
  dictionary_version_id uuid not null references prop4you_leadfinder.canonical_dictionary_versions(id) on delete restrict,
  family_key text not null,
  display_name text not null,
  family_role text not null,
  candidate_status text not null default 'candidate',
  description text not null,
  evidence_origin jsonb not null default '{}'::jsonb,
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint canonical_families_dictionary_family_key unique (dictionary_version_id, family_key),
  constraint canonical_families_family_key_format_chk check (family_key ~ '^[a-z][a-z0-9_]{1,79}$'),
  constraint canonical_families_family_role_chk check (family_role in ('property','owner','ownership','party','contact','relationship','situation','valuation','lead','lineage','media','history')),
  constraint canonical_families_candidate_status_chk check (candidate_status in ('candidate','in_review','approved','deferred','deprecated','rejected')),
  constraint canonical_families_evidence_origin_object_chk check (jsonb_typeof(evidence_origin) = 'object'),
  constraint canonical_families_metadata_object_chk check (jsonb_typeof(metadata) = 'object')
);

create index if not exists canonical_families_family_key_idx
  on prop4you_leadfinder.canonical_families (family_key);
create index if not exists canonical_families_role_status_idx
  on prop4you_leadfinder.canonical_families (family_role, candidate_status);
create index if not exists canonical_families_evidence_origin_gin_idx
  on prop4you_leadfinder.canonical_families using gin (evidence_origin jsonb_path_ops);

comment on table prop4you_leadfinder.canonical_families is
'LeadFinder-owned candidate canonical families for the future canonical graph. These are semantic groupings, not final materialized property/owner/contact tables.';
comment on column prop4you_leadfinder.canonical_families.id is 'UUIDv7 primary key for one LeadFinder canonical family candidate.';
comment on column prop4you_leadfinder.canonical_families.dictionary_version_id is 'Dictionary version that owns this family candidate.';
comment on column prop4you_leadfinder.canonical_families.family_key is 'Stable lowercase LeadFinder family key within the dictionary version.';
comment on column prop4you_leadfinder.canonical_families.display_name is 'Human-readable LeadFinder family label.';
comment on column prop4you_leadfinder.canonical_families.family_role is 'Coarse LeadFinder role used to group family candidates.';
comment on column prop4you_leadfinder.canonical_families.candidate_status is 'Review state for this family candidate.';
comment on column prop4you_leadfinder.canonical_families.description is 'Objective family meaning and non-final boundary notes.';
comment on column prop4you_leadfinder.canonical_families.evidence_origin is 'Non-secret JSONB labels describing approved evidence categories that motivated this family; raw payload values do not belong here.';
comment on column prop4you_leadfinder.canonical_families.metadata is 'Non-secret JSONB review metadata for this family candidate.';
comment on column prop4you_leadfinder.canonical_families.created_at is 'Timestamp when this family candidate row was inserted.';
comment on column prop4you_leadfinder.canonical_families.updated_at is 'Timestamp when this family candidate row was last updated.';

create table if not exists prop4you_leadfinder.canonical_fields (
  id uuid primary key default uuidv7(),
  dictionary_version_id uuid not null references prop4you_leadfinder.canonical_dictionary_versions(id) on delete restrict,
  family_id uuid not null references prop4you_leadfinder.canonical_families(id) on delete restrict,
  field_key text not null,
  display_name text not null,
  value_kind text not null default 'unknown',
  cardinality text not null default 'unknown',
  candidate_status text not null default 'candidate',
  materialization_intent text not null default 'dictionary_candidate',
  pii_classification text not null default 'unknown',
  description text not null,
  evidence_origin jsonb not null default '{}'::jsonb,
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint canonical_fields_dictionary_field_key unique (dictionary_version_id, family_id, field_key),
  constraint canonical_fields_field_key_format_chk check (field_key ~ '^[a-z][a-z0-9_]{1,79}$'),
  constraint canonical_fields_value_kind_chk check (value_kind in ('text','integer','numeric','boolean','date','timestamp','uuid','enum','jsonb','unknown')),
  constraint canonical_fields_cardinality_chk check (cardinality in ('one','optional','many','unknown')),
  constraint canonical_fields_candidate_status_chk check (candidate_status in ('candidate','in_review','approved','deferred','deprecated','rejected')),
  constraint canonical_fields_materialization_intent_chk check (materialization_intent in ('dictionary_candidate','dto_candidate','canonical_graph_candidate','evidence_only','do_not_materialize')),
  constraint canonical_fields_pii_classification_chk check (pii_classification in ('none','possible','contact','person','sensitive','unknown')),
  constraint canonical_fields_evidence_origin_object_chk check (jsonb_typeof(evidence_origin) = 'object'),
  constraint canonical_fields_metadata_object_chk check (jsonb_typeof(metadata) = 'object')
);

create index if not exists canonical_fields_dictionary_status_idx
  on prop4you_leadfinder.canonical_fields (dictionary_version_id, candidate_status);
create index if not exists canonical_fields_family_status_idx
  on prop4you_leadfinder.canonical_fields (family_id, candidate_status);
create index if not exists canonical_fields_field_key_idx
  on prop4you_leadfinder.canonical_fields (field_key);
create index if not exists canonical_fields_evidence_origin_gin_idx
  on prop4you_leadfinder.canonical_fields using gin (evidence_origin jsonb_path_ops);
create index if not exists canonical_fields_metadata_gin_idx
  on prop4you_leadfinder.canonical_fields using gin (metadata jsonb_path_ops);

comment on table prop4you_leadfinder.canonical_fields is
'LeadFinder-owned candidate canonical fields. A row declares semantic intent and evidence origin only; it does not store provider/raw payload values.';
comment on column prop4you_leadfinder.canonical_fields.id is 'UUIDv7 primary key for one LeadFinder canonical field candidate.';
comment on column prop4you_leadfinder.canonical_fields.dictionary_version_id is 'Dictionary version that owns this field candidate.';
comment on column prop4you_leadfinder.canonical_fields.family_id is 'LeadFinder family candidate that groups this field candidate.';
comment on column prop4you_leadfinder.canonical_fields.field_key is 'Stable lowercase field key within its LeadFinder family.';
comment on column prop4you_leadfinder.canonical_fields.display_name is 'Human-readable field label.';
comment on column prop4you_leadfinder.canonical_fields.value_kind is 'Expected normalized value kind for future DTO/canonical review.';
comment on column prop4you_leadfinder.canonical_fields.cardinality is 'Expected cardinality for the field candidate: one, optional, many, or unknown.';
comment on column prop4you_leadfinder.canonical_fields.candidate_status is 'Review state for this field candidate.';
comment on column prop4you_leadfinder.canonical_fields.materialization_intent is 'Non-final intent for whether this field may become DTO/canonical graph material or remain evidence-only.';
comment on column prop4you_leadfinder.canonical_fields.pii_classification is 'Coarse privacy class for the field meaning; no actual PII value is stored here.';
comment on column prop4you_leadfinder.canonical_fields.description is 'Objective field meaning and non-final materialization boundary notes.';
comment on column prop4you_leadfinder.canonical_fields.evidence_origin is 'Non-secret JSONB labels describing evidence categories or source surfaces; raw payload values do not belong here.';
comment on column prop4you_leadfinder.canonical_fields.metadata is 'Non-secret JSONB review metadata for this field candidate.';
comment on column prop4you_leadfinder.canonical_fields.created_at is 'Timestamp when this field candidate row was inserted.';
comment on column prop4you_leadfinder.canonical_fields.updated_at is 'Timestamp when this field candidate row was last updated.';

create table if not exists prop4you_leadfinder.canonical_gaps (
  id uuid primary key default uuidv7(),
  dictionary_version_id uuid not null references prop4you_leadfinder.canonical_dictionary_versions(id) on delete restrict,
  family_id uuid references prop4you_leadfinder.canonical_families(id) on delete set null,
  field_id uuid references prop4you_leadfinder.canonical_fields(id) on delete set null,
  gap_key text not null,
  gap_kind text not null,
  severity text not null default 'medium',
  gap_status text not null default 'open',
  description text not null,
  evidence_origin jsonb not null default '{}'::jsonb,
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint canonical_gaps_dictionary_gap_key unique (dictionary_version_id, gap_key),
  constraint canonical_gaps_gap_key_format_chk check (gap_key ~ '^[a-z][a-z0-9_.:-]{1,127}$'),
  constraint canonical_gaps_gap_kind_chk check (gap_kind in ('missing_family','missing_field','ambiguous_meaning','conflicting_sources','materialization_blocked','privacy_boundary','lineage_gap','review_needed')),
  constraint canonical_gaps_severity_chk check (severity in ('low','medium','high','critical')),
  constraint canonical_gaps_gap_status_chk check (gap_status in ('open','in_review','resolved','deferred','rejected')),
  constraint canonical_gaps_evidence_origin_object_chk check (jsonb_typeof(evidence_origin) = 'object'),
  constraint canonical_gaps_metadata_object_chk check (jsonb_typeof(metadata) = 'object')
);

create index if not exists canonical_gaps_status_severity_idx
  on prop4you_leadfinder.canonical_gaps (gap_status, severity);
create index if not exists canonical_gaps_family_idx
  on prop4you_leadfinder.canonical_gaps (family_id) where family_id is not null;
create index if not exists canonical_gaps_field_idx
  on prop4you_leadfinder.canonical_gaps (field_id) where field_id is not null;
create index if not exists canonical_gaps_evidence_origin_gin_idx
  on prop4you_leadfinder.canonical_gaps using gin (evidence_origin jsonb_path_ops);

comment on table prop4you_leadfinder.canonical_gaps is
'LeadFinder-owned review backlog of dictionary gaps found while converting raw/provider/internal evidence categories into canonical family and field candidates.';
comment on column prop4you_leadfinder.canonical_gaps.id is 'UUIDv7 primary key for one canonical dictionary gap.';
comment on column prop4you_leadfinder.canonical_gaps.dictionary_version_id is 'Dictionary version where the gap was observed.';
comment on column prop4you_leadfinder.canonical_gaps.family_id is 'Optional family candidate associated with the gap.';
comment on column prop4you_leadfinder.canonical_gaps.field_id is 'Optional field candidate associated with the gap.';
comment on column prop4you_leadfinder.canonical_gaps.gap_key is 'Stable gap key within a dictionary version.';
comment on column prop4you_leadfinder.canonical_gaps.gap_kind is 'Type of dictionary gap such as missing field, ambiguity, conflict, privacy boundary, or lineage gap.';
comment on column prop4you_leadfinder.canonical_gaps.severity is 'Reviewer severity assigned to this dictionary gap.';
comment on column prop4you_leadfinder.canonical_gaps.gap_status is 'Workflow status of this gap.';
comment on column prop4you_leadfinder.canonical_gaps.description is 'Objective gap summary; no raw payload values or secrets belong here.';
comment on column prop4you_leadfinder.canonical_gaps.evidence_origin is 'Non-secret JSONB labels describing the evidence categories that revealed the gap.';
comment on column prop4you_leadfinder.canonical_gaps.metadata is 'Non-secret JSONB review metadata for this dictionary gap.';
comment on column prop4you_leadfinder.canonical_gaps.created_at is 'Timestamp when this gap row was inserted.';
comment on column prop4you_leadfinder.canonical_gaps.updated_at is 'Timestamp when this gap row was last updated.';

create table if not exists prop4you_leadfinder.growth_pressure_signals (
  id uuid primary key default uuidv7(),
  dictionary_version_id uuid not null references prop4you_leadfinder.canonical_dictionary_versions(id) on delete restrict,
  family_id uuid references prop4you_leadfinder.canonical_families(id) on delete set null,
  field_id uuid references prop4you_leadfinder.canonical_fields(id) on delete set null,
  signal_key text not null,
  signal_kind text not null,
  signal_status text not null default 'candidate',
  pressure_level text not null default 'medium',
  description text not null,
  evidence_origin jsonb not null default '{}'::jsonb,
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint growth_pressure_signals_dictionary_signal_key unique (dictionary_version_id, signal_key),
  constraint growth_pressure_signals_signal_key_format_chk check (signal_key ~ '^[a-z][a-z0-9_.:-]{1,127}$'),
  constraint growth_pressure_signals_kind_chk check (signal_kind in ('new_provider_surface','repeated_raw_path','business_rule_pressure','lead_scoring_pressure','contactability_pressure','lineage_pressure','privacy_pressure','review_volume_pressure')),
  constraint growth_pressure_signals_status_chk check (signal_status in ('candidate','in_review','accepted','deferred','rejected','closed')),
  constraint growth_pressure_signals_pressure_level_chk check (pressure_level in ('low','medium','high','critical')),
  constraint growth_pressure_signals_evidence_origin_object_chk check (jsonb_typeof(evidence_origin) = 'object'),
  constraint growth_pressure_signals_metadata_object_chk check (jsonb_typeof(metadata) = 'object')
);

create index if not exists growth_pressure_signals_status_level_idx
  on prop4you_leadfinder.growth_pressure_signals (signal_status, pressure_level);
create index if not exists growth_pressure_signals_kind_idx
  on prop4you_leadfinder.growth_pressure_signals (signal_kind);
create index if not exists growth_pressure_signals_family_idx
  on prop4you_leadfinder.growth_pressure_signals (family_id) where family_id is not null;
create index if not exists growth_pressure_signals_field_idx
  on prop4you_leadfinder.growth_pressure_signals (field_id) where field_id is not null;
create index if not exists growth_pressure_signals_evidence_origin_gin_idx
  on prop4you_leadfinder.growth_pressure_signals using gin (evidence_origin jsonb_path_ops);

comment on table prop4you_leadfinder.growth_pressure_signals is
'LeadFinder-owned signals showing where raw/provider/internal evidence creates pressure to grow or revise the canonical dictionary.';
comment on column prop4you_leadfinder.growth_pressure_signals.id is 'UUIDv7 primary key for one dictionary growth-pressure signal.';
comment on column prop4you_leadfinder.growth_pressure_signals.dictionary_version_id is 'Dictionary version where this pressure signal was recorded.';
comment on column prop4you_leadfinder.growth_pressure_signals.family_id is 'Optional family candidate associated with the pressure signal.';
comment on column prop4you_leadfinder.growth_pressure_signals.field_id is 'Optional field candidate associated with the pressure signal.';
comment on column prop4you_leadfinder.growth_pressure_signals.signal_key is 'Stable pressure signal key within a dictionary version.';
comment on column prop4you_leadfinder.growth_pressure_signals.signal_kind is 'Kind of pressure, such as new provider surface, repeated raw path, business rule, contactability, lineage, privacy, or review volume.';
comment on column prop4you_leadfinder.growth_pressure_signals.signal_status is 'Workflow status of this pressure signal.';
comment on column prop4you_leadfinder.growth_pressure_signals.pressure_level is 'Reviewer-assigned pressure level for prioritizing dictionary growth.';
comment on column prop4you_leadfinder.growth_pressure_signals.description is 'Objective signal summary; no raw payload values or secrets belong here.';
comment on column prop4you_leadfinder.growth_pressure_signals.evidence_origin is 'Non-secret JSONB labels describing evidence categories behind the pressure signal.';
comment on column prop4you_leadfinder.growth_pressure_signals.metadata is 'Non-secret JSONB review metadata for this pressure signal.';
comment on column prop4you_leadfinder.growth_pressure_signals.created_at is 'Timestamp when this pressure signal row was inserted.';
comment on column prop4you_leadfinder.growth_pressure_signals.updated_at is 'Timestamp when this pressure signal row was last updated.';

insert into prop4you_leadfinder.canonical_dictionary_versions
  (version_key, display_name, version_status, ownership_scope, source_basis, description, metadata)
values
  (
    'leadfinder.raw_candidate.v0',
    'LeadFinder raw-derived candidate dictionary v0',
    'draft',
    'leadfinder_canonical_dictionary',
    'raw_derived_candidate_review',
    'Experimental non-final LeadFinder-owned dictionary seeded from approved raw/provider/internal evidence categories. It contains semantic candidates only and no raw payload values.',
    '{"seeded_by":"leadfinder_ddl_v0","non_final":true,"no_raw_payload_values":true,"evidence_origin":{"basis":"approved_family_list","scope":"raw/provider/internal category labels only"}}'::jsonb
  )
on conflict (version_key) do update
  set display_name = excluded.display_name,
      version_status = excluded.version_status,
      ownership_scope = excluded.ownership_scope,
      source_basis = excluded.source_basis,
      description = excluded.description,
      metadata = excluded.metadata,
      updated_at = now();

with dictionary_version as (
  select id from prop4you_leadfinder.canonical_dictionary_versions
  where version_key = 'leadfinder.raw_candidate.v0'
), family_seed(family_key, display_name, family_role, description, evidence_origin, metadata) as (
  values
    ('property_identity','Property identity','property','Property-level identity candidates such as durable property references, parcel/address identity and match keys, without storing raw address payload values.','{"basis":"approved_family_list","evidence_surfaces":["provider_property_identity","internal_property_baseline"]}'::jsonb,'{"seeded_by":"leadfinder_ddl_v0"}'::jsonb),
    ('property_details','Property details','property','Physical and descriptive property detail candidates that may later inform canonical property facts after review.','{"basis":"approved_family_list","evidence_surfaces":["provider_property_details","listing_detail_surfaces"]}'::jsonb,'{"seeded_by":"leadfinder_ddl_v0"}'::jsonb),
    ('property_media','Property media','media','Media and media-count candidates for property enrichment; this is not a binary asset store.','{"basis":"approved_family_list","evidence_surfaces":["listing_media_metadata"]}'::jsonb,'{"seeded_by":"leadfinder_ddl_v0"}'::jsonb),
    ('property_history','Property history','history','Timeline candidates for listing, sale, tax, event, or observed property-history evidence.','{"basis":"approved_family_list","evidence_surfaces":["provider_property_history","internal_candidate_snapshots"]}'::jsonb,'{"seeded_by":"leadfinder_ddl_v0"}'::jsonb),
    ('situation_legal','Situation legal','situation','Structured situation and legal status candidates such as foreclosure, probate, tax, eviction or other distress categories.','{"basis":"approved_family_list","evidence_surfaces":["legal_situation_sources","provider_status_categories"]}'::jsonb,'{"seeded_by":"leadfinder_ddl_v0"}'::jsonb),
    ('valuation_financial','Valuation financial','valuation','Valuation, equity, mortgage, loan, tax and financial estimate candidates requiring review before materialization.','{"basis":"approved_family_list","evidence_surfaces":["provider_valuation_financial","listing_price_surfaces"]}'::jsonb,'{"seeded_by":"leadfinder_ddl_v0"}'::jsonb),
    ('owner_identity','Owner identity','owner','Owner person/entity identity candidates used for future owner resolution and deduplication.','{"basis":"approved_family_list","evidence_surfaces":["provider_owner_identity","skiptrace_identity"]}'::jsonb,'{"seeded_by":"leadfinder_ddl_v0"}'::jsonb),
    ('ownership_history','Ownership history','ownership','Ownership interval, transfer and relationship-to-property timeline candidates.','{"basis":"approved_family_list","evidence_surfaces":["provider_ownership_history","deed_or_transfer_categories"]}'::jsonb,'{"seeded_by":"leadfinder_ddl_v0"}'::jsonb),
    ('party_roles','Party roles','party','Role candidates connecting people, entities, owners, relatives, agents or other parties to properties/leads.','{"basis":"approved_family_list","evidence_surfaces":["party_role_categories","relationship_surfaces"]}'::jsonb,'{"seeded_by":"leadfinder_ddl_v0"}'::jsonb),
    ('owner_contact_address','Owner contact address','contact','Mailing and contact-address candidates for owners/parties; semantic only, no address value storage.','{"basis":"approved_family_list","evidence_surfaces":["skiptrace_contact_address","provider_mailing_address"]}'::jsonb,'{"seeded_by":"leadfinder_ddl_v0"}'::jsonb),
    ('owner_phone','Owner phone','contact','Owner/party phone candidates and phone quality semantics; no phone numbers are stored in this dictionary.','{"basis":"approved_family_list","evidence_surfaces":["skiptrace_phone","provider_contact_phone"]}'::jsonb,'{"seeded_by":"leadfinder_ddl_v0"}'::jsonb),
    ('owner_email','Owner email','contact','Owner/party email candidates and email quality semantics; no email addresses are stored in this dictionary.','{"basis":"approved_family_list","evidence_surfaces":["skiptrace_email","provider_contact_email"]}'::jsonb,'{"seeded_by":"leadfinder_ddl_v0"}'::jsonb),
    ('relationship_evidence','Relationship evidence','relationship','Evidence candidates linking owners, relatives, contacts, properties, sources and leads with explicit lineage/review needs.','{"basis":"approved_family_list","evidence_surfaces":["skiptrace_relationships","internal_resolution_edges"]}'::jsonb,'{"seeded_by":"leadfinder_ddl_v0"}'::jsonb),
    ('lead_opportunity','Lead opportunity','lead','Opportunity, motivation, score and workflow candidates for future LeadFinder lead generation.','{"basis":"approved_family_list","evidence_surfaces":["leadfinder_candidate_snapshot","business_rule_pressure"]}'::jsonb,'{"seeded_by":"leadfinder_ddl_v0"}'::jsonb),
    ('source_lineage','Source lineage','lineage','Source, provider, raw-record, DTO-publication and review-lineage candidates required to prove where canonical candidates came from.','{"basis":"approved_family_list","evidence_surfaces":["sourcehub_lineage","matrix_mapping_review"]}'::jsonb,'{"seeded_by":"leadfinder_ddl_v0"}'::jsonb)
)
insert into prop4you_leadfinder.canonical_families
  (dictionary_version_id, family_key, display_name, family_role, candidate_status, description, evidence_origin, metadata)
select dv.id, fs.family_key, fs.display_name, fs.family_role, 'candidate', fs.description, fs.evidence_origin, fs.metadata
from dictionary_version dv
cross join family_seed fs
on conflict (dictionary_version_id, family_key) do update
  set display_name = excluded.display_name,
      family_role = excluded.family_role,
      candidate_status = excluded.candidate_status,
      description = excluded.description,
      evidence_origin = excluded.evidence_origin,
      metadata = excluded.metadata,
      updated_at = now();

with dictionary_version as (
  select id from prop4you_leadfinder.canonical_dictionary_versions
  where version_key = 'leadfinder.raw_candidate.v0'
), field_seed(family_key, field_key, display_name, value_kind, cardinality, materialization_intent, pii_classification, description, evidence_origin, metadata) as (
  values
    ('property_identity','property_reference','Property reference','text','optional','dto_candidate','none','Candidate stable property reference or external key semantics; no provider value is stored here.','{"basis":"approved_family_list","evidence_surfaces":["provider_property_identity"]}'::jsonb,'{"seeded_by":"leadfinder_ddl_v0"}'::jsonb),
    ('property_identity','address_identity','Address identity','jsonb','optional','dto_candidate','possible','Candidate normalized address identity semantics for later canonical review; no address payload value is stored.','{"basis":"approved_family_list","evidence_surfaces":["provider_property_address","internal_property_baseline"]}'::jsonb,'{"seeded_by":"leadfinder_ddl_v0"}'::jsonb),
    ('property_identity','parcel_or_apn','Parcel or APN','text','optional','dto_candidate','none','Candidate parcel/APN semantic slot when present in reviewed evidence categories.','{"basis":"approved_family_list","evidence_surfaces":["provider_property_identity"]}'::jsonb,'{"seeded_by":"leadfinder_ddl_v0"}'::jsonb),
    ('property_details','property_type','Property type','enum','optional','dto_candidate','none','Candidate property type/classification meaning.','{"basis":"approved_family_list","evidence_surfaces":["provider_property_details"]}'::jsonb,'{"seeded_by":"leadfinder_ddl_v0"}'::jsonb),
    ('property_details','structure_attributes','Structure attributes','jsonb','optional','dictionary_candidate','none','Candidate grouped physical attributes such as beds/baths/area/year categories without raw values.','{"basis":"approved_family_list","evidence_surfaces":["listing_detail_surfaces","provider_property_details"]}'::jsonb,'{"seeded_by":"leadfinder_ddl_v0"}'::jsonb),
    ('property_media','media_presence','Media presence','boolean','optional','dictionary_candidate','none','Candidate semantic marker that property media evidence exists.','{"basis":"approved_family_list","evidence_surfaces":["listing_media_metadata"]}'::jsonb,'{"seeded_by":"leadfinder_ddl_v0"}'::jsonb),
    ('property_media','media_count','Media count','integer','optional','dictionary_candidate','none','Candidate media-count meaning for review; no media URLs or assets are stored.','{"basis":"approved_family_list","evidence_surfaces":["listing_media_metadata"]}'::jsonb,'{"seeded_by":"leadfinder_ddl_v0"}'::jsonb),
    ('property_history','event_timeline','Event timeline','jsonb','many','dto_candidate','none','Candidate property event timeline semantics for sale/listing/tax/observation categories.','{"basis":"approved_family_list","evidence_surfaces":["provider_property_history"]}'::jsonb,'{"seeded_by":"leadfinder_ddl_v0"}'::jsonb),
    ('property_history','last_observed_at','Last observed at','timestamp','optional','dto_candidate','none','Candidate timestamp meaning for when the property evidence category was last observed.','{"basis":"approved_family_list","evidence_surfaces":["internal_candidate_snapshots","provider_property_history"]}'::jsonb,'{"seeded_by":"leadfinder_ddl_v0"}'::jsonb),
    ('situation_legal','situation_type','Situation type','enum','many','canonical_graph_candidate','none','Candidate structured situation category such as foreclosure/probate/tax/eviction after review.','{"basis":"approved_family_list","evidence_surfaces":["legal_situation_sources"]}'::jsonb,'{"seeded_by":"leadfinder_ddl_v0"}'::jsonb),
    ('situation_legal','situation_status','Situation status','enum','optional','dto_candidate','none','Candidate status/stage meaning for a legal or distress situation.','{"basis":"approved_family_list","evidence_surfaces":["provider_status_categories"]}'::jsonb,'{"seeded_by":"leadfinder_ddl_v0"}'::jsonb),
    ('situation_legal','situation_event_date','Situation event date','date','optional','dto_candidate','none','Candidate event-date meaning for situation/legal evidence.','{"basis":"approved_family_list","evidence_surfaces":["legal_situation_sources"]}'::jsonb,'{"seeded_by":"leadfinder_ddl_v0"}'::jsonb),
    ('valuation_financial','estimated_value','Estimated value','numeric','optional','dto_candidate','none','Candidate property valuation/estimate meaning requiring source priority and freshness review.','{"basis":"approved_family_list","evidence_surfaces":["provider_valuation_financial"]}'::jsonb,'{"seeded_by":"leadfinder_ddl_v0"}'::jsonb),
    ('valuation_financial','equity_indicator','Equity indicator','numeric','optional','dictionary_candidate','none','Candidate equity or equity-band meaning; no raw numeric payload claim is stored here.','{"basis":"approved_family_list","evidence_surfaces":["provider_valuation_financial"]}'::jsonb,'{"seeded_by":"leadfinder_ddl_v0"}'::jsonb),
    ('valuation_financial','loan_or_lien_indicator','Loan or lien indicator','jsonb','optional','dictionary_candidate','none','Candidate loan/lien/mortgage semantic group for later canonical review.','{"basis":"approved_family_list","evidence_surfaces":["provider_valuation_financial"]}'::jsonb,'{"seeded_by":"leadfinder_ddl_v0"}'::jsonb),
    ('owner_identity','owner_reference','Owner reference','text','optional','dto_candidate','person','Candidate stable owner/person/entity reference meaning; no raw identity value is stored.','{"basis":"approved_family_list","evidence_surfaces":["provider_owner_identity","skiptrace_identity"]}'::jsonb,'{"seeded_by":"leadfinder_ddl_v0"}'::jsonb),
    ('owner_identity','owner_name_identity','Owner name identity','jsonb','optional','dto_candidate','person','Candidate owner-name identity semantics for resolution; no raw name value is stored.','{"basis":"approved_family_list","evidence_surfaces":["provider_owner_identity","skiptrace_identity"]}'::jsonb,'{"seeded_by":"leadfinder_ddl_v0"}'::jsonb),
    ('owner_identity','owner_entity_type','Owner entity type','enum','optional','dictionary_candidate','person','Candidate person/entity/trust/company ownership identity classification.','{"basis":"approved_family_list","evidence_surfaces":["provider_owner_identity"]}'::jsonb,'{"seeded_by":"leadfinder_ddl_v0"}'::jsonb),
    ('ownership_history','ownership_start_date','Ownership start date','date','optional','dto_candidate','none','Candidate date meaning for the start of an ownership interval.','{"basis":"approved_family_list","evidence_surfaces":["provider_ownership_history"]}'::jsonb,'{"seeded_by":"leadfinder_ddl_v0"}'::jsonb),
    ('ownership_history','transfer_event','Transfer event','jsonb','many','dictionary_candidate','none','Candidate ownership transfer/deed event semantics.','{"basis":"approved_family_list","evidence_surfaces":["deed_or_transfer_categories"]}'::jsonb,'{"seeded_by":"leadfinder_ddl_v0"}'::jsonb),
    ('party_roles','party_role_type','Party role type','enum','many','canonical_graph_candidate','person','Candidate role meaning connecting owners, relatives, agents, parties, properties or leads.','{"basis":"approved_family_list","evidence_surfaces":["party_role_categories","relationship_surfaces"]}'::jsonb,'{"seeded_by":"leadfinder_ddl_v0"}'::jsonb),
    ('party_roles','role_confidence','Role confidence','enum','optional','dictionary_candidate','none','Candidate confidence semantics for party-role evidence.','{"basis":"approved_family_list","evidence_surfaces":["relationship_surfaces"]}'::jsonb,'{"seeded_by":"leadfinder_ddl_v0"}'::jsonb),
    ('owner_contact_address','mailing_address_identity','Mailing address identity','jsonb','optional','dto_candidate','contact','Candidate owner/contact mailing-address semantics; no raw address value is stored.','{"basis":"approved_family_list","evidence_surfaces":["skiptrace_contact_address","provider_mailing_address"]}'::jsonb,'{"seeded_by":"leadfinder_ddl_v0"}'::jsonb),
    ('owner_contact_address','address_deliverability','Address deliverability','enum','optional','dictionary_candidate','contact','Candidate deliverability/validity meaning for contact-address evidence.','{"basis":"approved_family_list","evidence_surfaces":["skiptrace_contact_address"]}'::jsonb,'{"seeded_by":"leadfinder_ddl_v0"}'::jsonb),
    ('owner_phone','phone_identity','Phone identity','text','many','dto_candidate','contact','Candidate phone identity semantics for later contact graph review; no phone number value is stored.','{"basis":"approved_family_list","evidence_surfaces":["skiptrace_phone","provider_contact_phone"]}'::jsonb,'{"seeded_by":"leadfinder_ddl_v0"}'::jsonb),
    ('owner_phone','phone_quality','Phone quality','enum','optional','dictionary_candidate','contact','Candidate phone quality/reachability meaning.','{"basis":"approved_family_list","evidence_surfaces":["skiptrace_phone"]}'::jsonb,'{"seeded_by":"leadfinder_ddl_v0"}'::jsonb),
    ('owner_email','email_identity','Email identity','text','many','dto_candidate','contact','Candidate email identity semantics for later contact graph review; no email value is stored.','{"basis":"approved_family_list","evidence_surfaces":["skiptrace_email","provider_contact_email"]}'::jsonb,'{"seeded_by":"leadfinder_ddl_v0"}'::jsonb),
    ('owner_email','email_quality','Email quality','enum','optional','dictionary_candidate','contact','Candidate email quality/reachability meaning.','{"basis":"approved_family_list","evidence_surfaces":["skiptrace_email"]}'::jsonb,'{"seeded_by":"leadfinder_ddl_v0"}'::jsonb),
    ('relationship_evidence','relationship_type','Relationship type','enum','many','canonical_graph_candidate','person','Candidate relationship type between parties, contacts, properties, sources or leads.','{"basis":"approved_family_list","evidence_surfaces":["skiptrace_relationships","internal_resolution_edges"]}'::jsonb,'{"seeded_by":"leadfinder_ddl_v0"}'::jsonb),
    ('relationship_evidence','relationship_confidence','Relationship confidence','enum','optional','dictionary_candidate','none','Candidate confidence semantics for relationship evidence.','{"basis":"approved_family_list","evidence_surfaces":["skiptrace_relationships","internal_resolution_edges"]}'::jsonb,'{"seeded_by":"leadfinder_ddl_v0"}'::jsonb),
    ('lead_opportunity','opportunity_type','Opportunity type','enum','many','canonical_graph_candidate','none','Candidate opportunity category for future LeadFinder lead generation.','{"basis":"approved_family_list","evidence_surfaces":["leadfinder_candidate_snapshot","business_rule_pressure"]}'::jsonb,'{"seeded_by":"leadfinder_ddl_v0"}'::jsonb),
    ('lead_opportunity','lead_score_signal','Lead score signal','jsonb','many','dictionary_candidate','none','Candidate score/motivation/signal semantics without final scoring implementation.','{"basis":"approved_family_list","evidence_surfaces":["business_rule_pressure"]}'::jsonb,'{"seeded_by":"leadfinder_ddl_v0"}'::jsonb),
    ('lead_opportunity','workflow_stage_candidate','Workflow stage candidate','enum','optional','dictionary_candidate','none','Candidate workflow/stage meaning for future lead operations.','{"basis":"approved_family_list","evidence_surfaces":["leadfinder_candidate_snapshot"]}'::jsonb,'{"seeded_by":"leadfinder_ddl_v0"}'::jsonb),
    ('source_lineage','source_system','Source system','text','many','evidence_only','none','Candidate source-system semantics used for lineage and review, not provider runtime calls.','{"basis":"approved_family_list","evidence_surfaces":["sourcehub_lineage"]}'::jsonb,'{"seeded_by":"leadfinder_ddl_v0"}'::jsonb),
    ('source_lineage','raw_record_reference','Raw record reference','uuid','many','evidence_only','none','Candidate raw-record reference semantics; references are IDs only and do not embed raw payload values.','{"basis":"approved_family_list","evidence_surfaces":["sourcehub_lineage"]}'::jsonb,'{"seeded_by":"leadfinder_ddl_v0"}'::jsonb),
    ('source_lineage','mapping_review_reference','Mapping review reference','uuid','many','evidence_only','none','Candidate reference semantics for Matrix/SourceHub mapping review lineage.','{"basis":"approved_family_list","evidence_surfaces":["matrix_mapping_review"]}'::jsonb,'{"seeded_by":"leadfinder_ddl_v0"}'::jsonb)
)
insert into prop4you_leadfinder.canonical_fields
  (dictionary_version_id, family_id, field_key, display_name, value_kind, cardinality, candidate_status, materialization_intent, pii_classification, description, evidence_origin, metadata)
select dv.id,
       cf.id,
       fs.field_key,
       fs.display_name,
       fs.value_kind,
       fs.cardinality,
       'candidate',
       fs.materialization_intent,
       fs.pii_classification,
       fs.description,
       fs.evidence_origin,
       fs.metadata
from dictionary_version dv
join prop4you_leadfinder.canonical_families cf
  on cf.dictionary_version_id = dv.id
join field_seed fs
  on fs.family_key = cf.family_key
on conflict (dictionary_version_id, family_id, field_key) do update
  set display_name = excluded.display_name,
      value_kind = excluded.value_kind,
      cardinality = excluded.cardinality,
      candidate_status = excluded.candidate_status,
      materialization_intent = excluded.materialization_intent,
      pii_classification = excluded.pii_classification,
      description = excluded.description,
      evidence_origin = excluded.evidence_origin,
      metadata = excluded.metadata,
      updated_at = now();
