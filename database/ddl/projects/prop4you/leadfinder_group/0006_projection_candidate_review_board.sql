-- package: prop4you/leadfinder_group
-- file: 0006_projection_candidate_review_board.sql
-- status: experimental / non-final
-- purpose: Review-board queryable registry for JSONB -> relational projection candidates, gates, and decisions.
-- depends-on: leadfinder_group/0005_canonical_jsonschema_registry.sql
-- idempotency: idempotent
-- destructive: false
-- [GATEWAY_AGNOSTIC]
-- [REVIEW_BOARD_ONLY]
-- [NO_PROVIDER_CALLS]
-- [NO_RAW_PAYLOAD_VALUES]
-- [NO_FINAL_PRODUCT_TABLE_EXPLOSION]

set search_path = prop4you_leadfinder_group, public;

create table if not exists prop4you_leadfinder_group.projection_candidate_groups (
  id uuid primary key default uuidv7(),
  public_ref text generated always as (base.make_public_ref('p4ylfgpcg', id)) stored,
  group_key text not null,
  group_label text not null,
  group_status text not null default 'candidate',
  group_kind text not null,
  sequence_number integer not null,
  lane_key text not null,
  lane_title text not null,
  canonical_envelope_key text not null,
  schema_version text not null default 'v1',
  projection_policy_key text not null default 'lfg_projection_policy.v1',
  source_family text not null,
  semantic_lane text not null,
  provider_slug text,
  list_type_slug text,
  semantic_owner text not null default 'leadfinder_group',
  privacy_class text not null default 'mixed_review_required',
  relational_target_kind text not null default 'jsonb_projection_candidate',
  review_priority integer not null default 100,
  decision_status text not null default 'pending',
  decision_reason text,
  lineage jsonb not null default '{}'::jsonb,
  metadata jsonb not null default '{}'::jsonb,
  active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  version integer not null default 1,
  constraint projection_candidate_groups_public_ref_key unique (public_ref),
  constraint projection_candidate_groups_key_key unique (group_key),
  constraint projection_candidate_groups_key_format_chk check (group_key ~ '^[a-z][a-z0-9_.:-]{1,191}$'),
  constraint projection_candidate_groups_status_chk check (group_status in ('candidate','in_review','approved','blocked','rejected','superseded','archived')),
  constraint projection_candidate_groups_kind_chk check (group_kind in ('directskip_contact_satellites','geography_boundary','geography_market','geography_property','valuation','property_physical_facts','legal_situation_signals','taxonomy_support','unknown')),
  constraint projection_candidate_groups_lane_chk check (lane_key in ('directskip_unified','geography_first','market_downstream','valuation_downstream','property_facts_downstream','legal_situation_downstream','taxonomy_support_downstream')),
  constraint projection_candidate_groups_privacy_chk check (privacy_class in ('public_safe','restricted','pii_sensitive','provider_sensitive','mixed_review_required','unknown')),
  constraint projection_candidate_groups_decision_chk check (decision_status in ('pending','ready_for_review','approved','blocked','rejected','needs_more_evidence','superseded','archived','review_required')),
  constraint projection_candidate_groups_sequence_chk check (sequence_number > 0),
  constraint projection_candidate_groups_priority_chk check (review_priority > 0),
  constraint projection_candidate_groups_lineage_object_chk check (jsonb_typeof(lineage)='object'),
  constraint projection_candidate_groups_metadata_object_chk check (jsonb_typeof(metadata)='object'),
  constraint projection_candidate_groups_version_chk check (version > 0),
  constraint projection_candidate_groups_envelope_fk foreign key (canonical_envelope_key, schema_version)
    references prop4you_leadfinder_group.canonical_jsonschema_envelopes(envelope_key, schema_version)
    deferrable initially deferred,
  constraint projection_candidate_groups_policy_fk foreign key (projection_policy_key, schema_version)
    references prop4you_leadfinder_group.projection_policies(policy_key, policy_version)
    deferrable initially deferred
);

comment on table prop4you_leadfinder_group.projection_candidate_groups is
'LFG projection review-board groups. DDL registry only: no raw values, no provider calls, no final projection tables.';

create table if not exists prop4you_leadfinder_group.projection_candidates (
  id uuid primary key default uuidv7(),
  public_ref text generated always as (base.make_public_ref('p4ylfgpc', id)) stored,
  group_id uuid not null references prop4you_leadfinder_group.projection_candidate_groups(id) on delete restrict,
  candidate_key text not null,
  candidate_status text not null default 'candidate',
  candidate_kind text not null default 'json_path_projection',
  canonical_envelope_key text not null,
  schema_version text not null default 'v1',
  json_path text not null,
  path_label text not null,
  path_value_kind text not null default 'unknown',
  candidate_reason text not null,
  relational_need text not null,
  proposed_table text,
  proposed_column text,
  proposed_type text,
  projection_shape text not null default 'scalar_column',
  privacy_class text not null default 'mixed_review_required',
  raw_value_policy text not null default 'no_raw_payload_values',
  corpus_evidence jsonb not null default '{}'::jsonb,
  lineage jsonb not null default '{}'::jsonb,
  review_status text not null default 'pending',
  approved_at timestamptz,
  approved_by_actor_id text,
  active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  version integer not null default 1,
  constraint projection_candidates_public_ref_key unique (public_ref),
  constraint projection_candidates_key_key unique (candidate_key),
  constraint projection_candidates_group_path_key unique (group_id, json_path),
  constraint projection_candidates_key_format_chk check (candidate_key ~ '^[a-z][a-z0-9_.:-]{1,191}$'),
  constraint projection_candidates_status_chk check (candidate_status in ('candidate','in_review','approved','blocked','rejected','superseded','archived')),
  constraint projection_candidates_kind_chk check (candidate_kind in ('json_path_projection','derived_projection','group_projection','index_hint','constraint_hint','unknown')),
  constraint projection_candidates_json_path_chk check (json_path = '$' or json_path like '$.%'),
  constraint projection_candidates_value_kind_chk check (path_value_kind in ('string','number','integer','boolean','object','array','geo','temporal','enum','mixed','unknown')),
  constraint projection_candidates_shape_chk check (projection_shape in ('scalar_column','generated_column','expression_index','join_table','edge_table','postgis_geometry','materialized_view','jsonb_only','unknown')),
  constraint projection_candidates_privacy_chk check (privacy_class in ('public_safe','restricted','pii_sensitive','provider_sensitive','mixed_review_required','unknown')),
  constraint projection_candidates_raw_policy_chk check (raw_value_policy in ('no_raw_payload_values','hashes_and_refs_only','normalized_values_allowed_internal','unknown')),
  constraint projection_candidates_review_status_chk check (review_status in ('pending','review_required','ready_for_review','approved','blocked','rejected','needs_more_evidence','superseded','archived','keep_jsonb')),
  constraint projection_candidates_approved_chk check (candidate_status <> 'approved' or review_status = 'approved'),
  constraint projection_candidates_corpus_object_chk check (jsonb_typeof(corpus_evidence)='object'),
  constraint projection_candidates_lineage_object_chk check (jsonb_typeof(lineage)='object'),
  constraint projection_candidates_version_chk check (version > 0),
  constraint projection_candidates_envelope_fk foreign key (canonical_envelope_key, schema_version)
    references prop4you_leadfinder_group.canonical_jsonschema_envelopes(envelope_key, schema_version)
    deferrable initially deferred
);

comment on table prop4you_leadfinder_group.projection_candidates is
'Path-level LFG projection candidates. Stores path, evidence metadata and decision state only; never stores raw provider values.';

create table if not exists prop4you_leadfinder_group.projection_candidate_gate_evaluations (
  id uuid primary key default uuidv7(),
  public_ref text generated always as (base.make_public_ref('p4ylfggt', id)) stored,
  candidate_id uuid not null references prop4you_leadfinder_group.projection_candidates(id) on delete cascade,
  policy_key text not null default 'lfg_projection_policy.v1',
  policy_version text not null default 'v1',
  gate_key text not null,
  gate_number integer not null,
  required boolean not null default true,
  gate_status text not null default 'not_evaluated',
  evaluation_result text not null default 'pending',
  evidence_summary jsonb not null default '{}'::jsonb,
  blocking_reason text,
  evaluated_at timestamptz,
  evaluated_by_actor_id text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  version integer not null default 1,
  constraint projection_candidate_gate_evaluations_public_ref_key unique (public_ref),
  constraint projection_candidate_gate_evaluations_candidate_gate_key unique (candidate_id, gate_key),
  constraint projection_candidate_gate_evaluations_candidate_gate_number_key unique (candidate_id, gate_number),
  constraint projection_candidate_gate_evaluations_gate_number_chk check (gate_number between 1 and 7),
  constraint projection_candidate_gate_evaluations_gate_status_chk check (gate_status in ('not_evaluated','passed','failed','blocked','not_applicable')),
  constraint projection_candidate_gate_evaluations_result_chk check (evaluation_result in ('pending','pass','fail','blocked','not_applicable')),
  constraint projection_candidate_gate_evaluations_pass_consistency_chk check ((gate_status = 'passed') = (evaluation_result = 'pass')),
  constraint projection_candidate_gate_evaluations_required_na_chk check (not (required = true and gate_status = 'not_applicable')),
  constraint projection_candidate_gate_evaluations_evidence_object_chk check (jsonb_typeof(evidence_summary)='object'),
  constraint projection_candidate_gate_evaluations_version_chk check (version > 0),
  constraint projection_candidate_gate_evaluations_policy_fk foreign key (policy_key, policy_version)
    references prop4you_leadfinder_group.projection_policies(policy_key, policy_version)
    deferrable initially deferred
);

comment on table prop4you_leadfinder_group.projection_candidate_gate_evaluations is
'One row per projection candidate per active promotion gate. Approval is forbidden until all required gates pass.';

create table if not exists prop4you_leadfinder_group.projection_candidate_reviews (
  id uuid primary key default uuidv7(),
  public_ref text generated always as (base.make_public_ref('p4ylfgpcr', id)) stored,
  candidate_id uuid not null references prop4you_leadfinder_group.projection_candidates(id) on delete restrict,
  review_key text not null,
  review_status text not null default 'in_review',
  review_decision text not null default 'pending',
  decision_reason text,
  reviewer_actor_id text,
  reviewed_at timestamptz,
  all_required_gates_passed boolean not null default false,
  review_payload jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  version integer not null default 1,
  constraint projection_candidate_reviews_public_ref_key unique (public_ref),
  constraint projection_candidate_reviews_key_key unique (review_key),
  constraint projection_candidate_reviews_status_chk check (review_status in ('in_review','approved','blocked','rejected','superseded','archived')),
  constraint projection_candidate_reviews_decision_chk check (review_decision in ('pending','keep_jsonb','generated_column_candidate','expression_index_candidate','narrow_table_candidate','postgis_projection_candidate','needs_review','rejected')),
  constraint projection_candidate_reviews_approved_requires_gates_chk check (review_status <> 'approved' or (all_required_gates_passed = true and review_decision in ('generated_column_candidate','expression_index_candidate','narrow_table_candidate','postgis_projection_candidate'))),
  constraint projection_candidate_reviews_payload_object_chk check (jsonb_typeof(review_payload)='object'),
  constraint projection_candidate_reviews_version_chk check (version > 0)
);

comment on table prop4you_leadfinder_group.projection_candidate_reviews is
'Review board decisions for projection candidates. Explicitly separates keep-jsonb, generated column, index, narrow table, PostGIS, and needs-review outcomes.';

create index if not exists projection_candidate_groups_lane_idx on prop4you_leadfinder_group.projection_candidate_groups (lane_key, sequence_number, group_status) where active = true;
create index if not exists projection_candidate_groups_decision_idx on prop4you_leadfinder_group.projection_candidate_groups (decision_status, review_priority, updated_at desc) where active = true;
create index if not exists projection_candidate_groups_lineage_gin_idx on prop4you_leadfinder_group.projection_candidate_groups using gin (lineage jsonb_path_ops);
create index if not exists projection_candidates_group_status_idx on prop4you_leadfinder_group.projection_candidates (group_id, candidate_status, review_status) where active = true;
create index if not exists projection_candidates_envelope_path_idx on prop4you_leadfinder_group.projection_candidates (canonical_envelope_key, json_path) where active = true;
create index if not exists projection_candidates_review_idx on prop4you_leadfinder_group.projection_candidates (review_status, updated_at desc) where active = true;
create index if not exists projection_candidates_evidence_gin_idx on prop4you_leadfinder_group.projection_candidates using gin (corpus_evidence jsonb_path_ops);
create index if not exists projection_candidate_gate_evaluations_candidate_idx on prop4you_leadfinder_group.projection_candidate_gate_evaluations (candidate_id, gate_number);
create index if not exists projection_candidate_gate_evaluations_gate_status_idx on prop4you_leadfinder_group.projection_candidate_gate_evaluations (gate_key, gate_status);
create index if not exists projection_candidate_reviews_candidate_idx on prop4you_leadfinder_group.projection_candidate_reviews (candidate_id, review_status, reviewed_at desc);

with seed(group_key, group_label, group_kind, sequence_number, lane_key, lane_title, canonical_envelope_key, source_family, semantic_lane, provider_slug, list_type_slug, privacy_class, decision_status, decision_reason, metadata) as (
  values
  ('directskip_skip_trace_unified_contact_evidence','DirectSkip skip trace unified contact evidence','directskip_contact_satellites',50,'directskip_unified','DirectSkip unified contact enrichment','contact-satellites-envelope','directskip_skiptrace','contact_enrichment','directskip','skip_trace_contact_discovery','pii_sensitive','review_required','Phone/email, mailing address, and relationship evidence are reviewed together because DirectSkip returns one coherent skiptrace envelope.','{"raw_values_allowed_in_docs": false, "seed_source": "slice17"}'::jsonb),
  ('realtor_geography_boundary_evidence','Realtor geography boundary evidence','geography_boundary',10,'geography_first','Geography first','realtor-evidence-envelope','realtor_property_market','geography','realtor','area_boundary','provider_sensitive','review_required','Boundary/geography is first because it anchors downstream market, comparables, property matching, and PostGIS decisions.','{"raw_values_allowed_in_docs": false, "seed_source": "slice17"}'::jsonb),
  ('realtor_geography_autocomplete_match_evidence','Realtor autocomplete geography match evidence','geography_boundary',20,'geography_first','Geography first','realtor-evidence-envelope','realtor_property_market','geography','realtor','autocomplete','provider_sensitive','review_required','Autocomplete/address selection is evidence for matching and geography selection, not canonical property truth.','{"raw_values_allowed_in_docs": false, "seed_source": "slice17"}'::jsonb),
  ('reiq_property_geography_signal_evidence','REIQ property geography signal evidence','geography_property',30,'geography_first','Geography first','property-envelope','reiq_property_legal_signal','geography','reiq','state_county_property_geography','pii_sensitive','review_required','REIQ property geography provides state/county/property routing and must remain distinct from owner/mailing geography.','{"raw_values_allowed_in_docs": false, "seed_source": "slice17"}'::jsonb),
  ('realtor_market_geography_snapshot_evidence','Realtor market geography snapshot evidence','geography_market',110,'market_downstream','Market downstream after geography','realtor-evidence-envelope','realtor_property_market','market','realtor','market_details','provider_sensitive','review_required','Market metrics depend on geography anchors and should become temporal snapshots only after geography gates pass.','{"raw_values_allowed_in_docs": false, "seed_source": "slice17"}'::jsonb),
  ('property_valuation_evidence_realtor_reiq','Property valuation evidence from Realtor and REIQ','valuation',210,'valuation_downstream','Valuation downstream after geography','property-envelope','realtor_reiq_valuation','valuation','mixed','valuation','mixed_review_required','review_required','Valuation combines AVM, assessed/appraised, equity and loan signals; lineage and source separation are mandatory.','{"raw_values_allowed_in_docs": false, "seed_source": "slice17"}'::jsonb),
  ('property_physical_listing_evidence_realtor_reiq','Property physical and listing evidence','property_physical_facts',310,'property_facts_downstream','Property facts downstream after geography','property-envelope','realtor_reiq_property_facts','property','mixed','property_facts','mixed_review_required','review_required','Physical facts and listing enrichment are high-value projections but must not overwrite canonical property identity without lineage.','{"raw_values_allowed_in_docs": false, "seed_source": "slice17"}'::jsonb),
  ('reiq_property_legal_tax_signal_evidence','REIQ property legal and tax signal evidence','legal_situation_signals',410,'legal_situation_downstream','Legal situation downstream after geography','property-envelope','reiq_property_legal_signal','legal','reiq','legal_tax_signal','pii_sensitive','review_required','Legal/situation signals need state/list type semantics and should remain separate from generic property facts.','{"raw_values_allowed_in_docs": false, "seed_source": "slice17"}'::jsonb),
  ('lfg_taxonomy_projection_semantic_support','LFG taxonomy projection semantic support','taxonomy_support',900,'taxonomy_support_downstream','Taxonomy support checks','taxonomy-envelope','matrix_leadfinder_support','taxonomy','matrix_leadfinder','taxonomy_support','restricted','review_required','Matrix and LeadFinder taxonomy support projection gates; they are not provider payloads.','{"raw_values_allowed_in_docs": false, "seed_source": "slice17"}'::jsonb)
)
insert into prop4you_leadfinder_group.projection_candidate_groups (group_key, group_label, group_kind, sequence_number, lane_key, lane_title, canonical_envelope_key, source_family, semantic_lane, provider_slug, list_type_slug, privacy_class, decision_status, decision_reason, metadata)
select group_key, group_label, group_kind, sequence_number, lane_key, lane_title, canonical_envelope_key, source_family, semantic_lane, provider_slug, list_type_slug, privacy_class, decision_status, decision_reason, metadata
from seed
on conflict (group_key) do update set group_label=excluded.group_label, group_kind=excluded.group_kind, sequence_number=excluded.sequence_number, lane_key=excluded.lane_key, lane_title=excluded.lane_title, canonical_envelope_key=excluded.canonical_envelope_key, source_family=excluded.source_family, semantic_lane=excluded.semantic_lane, provider_slug=excluded.provider_slug, list_type_slug=excluded.list_type_slug, privacy_class=excluded.privacy_class, decision_status=excluded.decision_status, decision_reason=excluded.decision_reason, metadata=excluded.metadata, updated_at=now(), version=prop4you_leadfinder_group.projection_candidate_groups.version+1;

with seed(group_key, candidate_key, json_path, path_label, candidate_kind, projection_shape, path_value_kind, relational_need, privacy_class, review_status, proposed_table, proposed_column, proposed_type, candidate_reason, corpus_evidence, lineage) as (
  values
  ('directskip_skip_trace_unified_contact_evidence','directskip_skip_trace_unified_contact_evidence:provider_slug','$.contact_satellites_handoff.provider_slug','DirectSkip provider slug','json_path_projection','scalar_column','string','provider/list filtering and lineage','restricted','review_required',null,null,null,'DirectSkip unified: phone/email, mailing, relationship evidence evaluated together by shared lineage.','{"directskip_lfg_candidates": 261, "sourcehub_handoffs_observed": 6, "unified_group_required": true}'::jsonb,'{"no_raw_values": true, "seed_source": "slice17"}'::jsonb),
  ('directskip_skip_trace_unified_contact_evidence','directskip_skip_trace_unified_contact_evidence:list_type_slug','$.contact_satellites_handoff.list_type_slug','DirectSkip list type slug','json_path_projection','scalar_column','string','provider/list filtering and lineage','restricted','review_required',null,null,null,'DirectSkip unified: phone/email, mailing, relationship evidence evaluated together by shared lineage.','{"directskip_lfg_candidates": 261, "sourcehub_handoffs_observed": 6, "unified_group_required": true}'::jsonb,'{"no_raw_values": true, "seed_source": "slice17"}'::jsonb),
  ('directskip_skip_trace_unified_contact_evidence','directskip_skip_trace_unified_contact_evidence:raw_record_public_id','$.contact_satellites_handoff.raw_record_public_id','DirectSkip raw record public id','json_path_projection','scalar_column','string','durable lineage to raw/sourcehub record','restricted','review_required',null,null,null,'DirectSkip unified: phone/email, mailing, relationship evidence evaluated together by shared lineage.','{"directskip_lfg_candidates": 261, "sourcehub_handoffs_observed": 6, "unified_group_required": true}'::jsonb,'{"no_raw_values": true, "seed_source": "slice17"}'::jsonb),
  ('directskip_skip_trace_unified_contact_evidence','directskip_skip_trace_unified_contact_evidence:canonical_property_public_id','$.contact_satellites_handoff.canonical_property_public_id','Canonical property public id anchor','json_path_projection','scalar_column','string','join candidate to canonical property when approved','restricted','review_required',null,null,null,'DirectSkip unified: phone/email, mailing, relationship evidence evaluated together by shared lineage.','{"directskip_lfg_candidates": 261, "sourcehub_handoffs_observed": 6, "unified_group_required": true}'::jsonb,'{"no_raw_values": true, "seed_source": "slice17"}'::jsonb),
  ('directskip_skip_trace_unified_contact_evidence','directskip_skip_trace_unified_contact_evidence:phone_seeds','$.contact_satellites_handoff.phone_seeds[]','Phone seed collection','group_projection','join_table','array','searchable contact seed review rows','pii_sensitive','review_required','prop4you_leadfinder_group.contact_satellite_projection_candidates',null,null,'DirectSkip unified: phone/email, mailing, relationship evidence evaluated together by shared lineage.','{"directskip_lfg_candidates": 261, "sourcehub_handoffs_observed": 6, "unified_group_required": true}'::jsonb,'{"no_raw_values": true, "seed_source": "slice17"}'::jsonb),
  ('directskip_skip_trace_unified_contact_evidence','directskip_skip_trace_unified_contact_evidence:phone_number','$.contact_satellites_handoff.phone_seeds[].phone_number','Phone seed number path','json_path_projection','join_table','string','normalized/masked runtime contact projection after gates','pii_sensitive','review_required','prop4you_leadfinder_group.contact_satellite_projection_candidates',null,null,'DirectSkip unified: phone/email, mailing, relationship evidence evaluated together by shared lineage.','{"directskip_lfg_candidates": 261, "sourcehub_handoffs_observed": 6, "unified_group_required": true}'::jsonb,'{"no_raw_values": true, "seed_source": "slice17"}'::jsonb),
  ('directskip_skip_trace_unified_contact_evidence','directskip_skip_trace_unified_contact_evidence:email_seeds','$.contact_satellites_handoff.email_seeds[]','Email seed collection','group_projection','join_table','array','searchable contact seed review rows','pii_sensitive','review_required','prop4you_leadfinder_group.contact_satellite_projection_candidates',null,null,'DirectSkip unified: phone/email, mailing, relationship evidence evaluated together by shared lineage.','{"directskip_lfg_candidates": 261, "sourcehub_handoffs_observed": 6, "unified_group_required": true}'::jsonb,'{"no_raw_values": true, "seed_source": "slice17"}'::jsonb),
  ('directskip_skip_trace_unified_contact_evidence','directskip_skip_trace_unified_contact_evidence:email','$.contact_satellites_handoff.email_seeds[].email','Email seed value path','json_path_projection','join_table','string','normalized/masked runtime contact projection after gates','pii_sensitive','review_required','prop4you_leadfinder_group.contact_satellite_projection_candidates',null,null,'DirectSkip unified: phone/email, mailing, relationship evidence evaluated together by shared lineage.','{"directskip_lfg_candidates": 261, "sourcehub_handoffs_observed": 6, "unified_group_required": true}'::jsonb,'{"no_raw_values": true, "seed_source": "slice17"}'::jsonb),
  ('directskip_skip_trace_unified_contact_evidence','directskip_skip_trace_unified_contact_evidence:mailing_address_seed','$.mailing_contact_handoff.mailing_address_seed','Mailing/contact address seed','group_projection','join_table','object','contact address review and dedupe after gates','pii_sensitive','review_required','prop4you_leadfinder_group.contact_satellite_projection_candidates',null,null,'DirectSkip unified: phone/email, mailing, relationship evidence evaluated together by shared lineage.','{"directskip_lfg_candidates": 261, "sourcehub_handoffs_observed": 6, "unified_group_required": true}'::jsonb,'{"no_raw_values": true, "seed_source": "slice17"}'::jsonb),
  ('directskip_skip_trace_unified_contact_evidence','directskip_skip_trace_unified_contact_evidence:mailing_address_hash','$.mailing_contact_handoff.mailing_address_seed.address_hash','Mailing address hash','derived_projection','generated_column','string','dedupe without raw address exposure','pii_sensitive','review_required',null,null,null,'DirectSkip unified: phone/email, mailing, relationship evidence evaluated together by shared lineage.','{"directskip_lfg_candidates": 261, "sourcehub_handoffs_observed": 6, "unified_group_required": true}'::jsonb,'{"no_raw_values": true, "seed_source": "slice17"}'::jsonb),
  ('directskip_skip_trace_unified_contact_evidence','directskip_skip_trace_unified_contact_evidence:relationship_evidence_seeds','$.relationship_evidence_handoff.relationship_evidence_seeds[]','Relationship evidence seed collection','group_projection','edge_table','array','relationship evidence edge review; not owner truth by itself','pii_sensitive','review_required','prop4you_leadfinder_group.contact_satellite_projection_candidates',null,null,'DirectSkip unified: phone/email, mailing, relationship evidence evaluated together by shared lineage.','{"directskip_lfg_candidates": 261, "sourcehub_handoffs_observed": 6, "unified_group_required": true}'::jsonb,'{"no_raw_values": true, "seed_source": "slice17"}'::jsonb),
  ('directskip_skip_trace_unified_contact_evidence','directskip_skip_trace_unified_contact_evidence:relationship_type','$.relationship_evidence_handoff.relationship_evidence_seeds[].relationship_type','Relationship type path','json_path_projection','edge_table','enum','relationship classification after identity review','pii_sensitive','review_required','prop4you_leadfinder_group.contact_satellite_projection_candidates',null,null,'DirectSkip unified: phone/email, mailing, relationship evidence evaluated together by shared lineage.','{"directskip_lfg_candidates": 261, "sourcehub_handoffs_observed": 6, "unified_group_required": true}'::jsonb,'{"no_raw_values": true, "seed_source": "slice17"}'::jsonb),
  ('directskip_skip_trace_unified_contact_evidence','directskip_skip_trace_unified_contact_evidence:promotion_policy','$.contact_satellites_handoff.match_metrics','Promotion policy metrics','derived_projection','materialized_view','object','derive policy flags/confidence caps without raw payload','pii_sensitive','review_required',null,null,null,'DirectSkip unified: phone/email, mailing, relationship evidence evaluated together by shared lineage.','{"directskip_lfg_candidates": 261, "sourcehub_handoffs_observed": 6, "unified_group_required": true}'::jsonb,'{"no_raw_values": true, "seed_source": "slice17"}'::jsonb),
  ('directskip_skip_trace_unified_contact_evidence','directskip_skip_trace_unified_contact_evidence:transformation_lineage','$.contact_satellites_handoff.transformation_lineage','DirectSkip transformation lineage','json_path_projection','jsonb_only','object','keep full lineage and explanation in JSONB','restricted','review_required',null,null,null,'DirectSkip unified: phone/email, mailing, relationship evidence evaluated together by shared lineage.','{"directskip_lfg_candidates": 261, "sourcehub_handoffs_observed": 6, "unified_group_required": true}'::jsonb,'{"no_raw_values": true, "seed_source": "slice17"}'::jsonb),
  ('realtor_geography_boundary_evidence','realtor_geography_boundary_evidence:area_id','$.boundary.result.areas[].id','Realtor area id','json_path_projection','scalar_column','string','geo identity and joins','provider_sensitive','review_required',null,null,null,'Geography-first boundary candidate. Coordinates stay JSONB until PostGIS derivation passes gates.','{"realtor_candidates": 27, "semantic_lane": "geography"}'::jsonb,'{"no_raw_values": true, "seed_source": "slice17"}'::jsonb),
  ('realtor_geography_boundary_evidence','realtor_geography_boundary_evidence:area_name','$.boundary.result.areas[].name','Realtor area name','json_path_projection','scalar_column','string','human review label; not primary identity','provider_sensitive','review_required',null,null,null,'Geography-first boundary candidate. Coordinates stay JSONB until PostGIS derivation passes gates.','{"realtor_candidates": 27, "semantic_lane": "geography"}'::jsonb,'{"no_raw_values": true, "seed_source": "slice17"}'::jsonb),
  ('realtor_geography_boundary_evidence','realtor_geography_boundary_evidence:area_center','$.boundary.result.areas[].center','Realtor area center','derived_projection','postgis_geometry','geo','spatial search and matching','provider_sensitive','review_required',null,null,null,'Geography-first boundary candidate. Coordinates stay JSONB until PostGIS derivation passes gates.','{"realtor_candidates": 27, "semantic_lane": "geography"}'::jsonb,'{"no_raw_values": true, "seed_source": "slice17"}'::jsonb),
  ('realtor_geography_boundary_evidence','realtor_geography_boundary_evidence:boundary_type','$.boundary.result.boundary.type','Boundary geometry type','json_path_projection','scalar_column','enum','geometry parser routing','provider_sensitive','review_required',null,null,null,'Geography-first boundary candidate. Coordinates stay JSONB until PostGIS derivation passes gates.','{"realtor_candidates": 27, "semantic_lane": "geography"}'::jsonb,'{"no_raw_values": true, "seed_source": "slice17"}'::jsonb),
  ('realtor_geography_boundary_evidence','realtor_geography_boundary_evidence:boundary_coordinates','$.boundary.result.boundary.coordinates','Boundary coordinates payload','derived_projection','postgis_geometry','array','derive PostGIS geometry, keep raw coords JSONB','provider_sensitive','review_required',null,null,null,'Geography-first boundary candidate. Coordinates stay JSONB until PostGIS derivation passes gates.','{"realtor_candidates": 27, "semantic_lane": "geography"}'::jsonb,'{"no_raw_values": true, "seed_source": "slice17"}'::jsonb),
  ('realtor_geography_autocomplete_match_evidence','realtor_geography_autocomplete_match_evidence:geo_id','$.results[].geo_id','Autocomplete geo id','json_path_projection','scalar_column','string','geo identity/matching and disambiguation','provider_sensitive','review_required',null,null,null,'Autocomplete is evidence for matching/selection, not property truth.','{"realtor_candidates": 27, "semantic_lane": "geography"}'::jsonb,'{"no_raw_values": true, "seed_source": "slice17"}'::jsonb),
  ('realtor_geography_autocomplete_match_evidence','realtor_geography_autocomplete_match_evidence:slug_id','$.results[].slug_id','Autocomplete slug id','json_path_projection','scalar_column','string','geo identity/matching and disambiguation','provider_sensitive','review_required',null,null,null,'Autocomplete is evidence for matching/selection, not property truth.','{"realtor_candidates": 27, "semantic_lane": "geography"}'::jsonb,'{"no_raw_values": true, "seed_source": "slice17"}'::jsonb),
  ('realtor_geography_autocomplete_match_evidence','realtor_geography_autocomplete_match_evidence:mpr_id','$.results[].mpr_id','Autocomplete property ref','json_path_projection','scalar_column','string','geo identity/matching and disambiguation','provider_sensitive','review_required',null,null,null,'Autocomplete is evidence for matching/selection, not property truth.','{"realtor_candidates": 27, "semantic_lane": "geography"}'::jsonb,'{"no_raw_values": true, "seed_source": "slice17"}'::jsonb),
  ('realtor_geography_autocomplete_match_evidence','realtor_geography_autocomplete_match_evidence:city','$.results[].city','Autocomplete city','json_path_projection','scalar_column','string','geo identity/matching and disambiguation','provider_sensitive','review_required',null,null,null,'Autocomplete is evidence for matching/selection, not property truth.','{"realtor_candidates": 27, "semantic_lane": "geography"}'::jsonb,'{"no_raw_values": true, "seed_source": "slice17"}'::jsonb),
  ('realtor_geography_autocomplete_match_evidence','realtor_geography_autocomplete_match_evidence:state_code','$.results[].state_code','Autocomplete state code','json_path_projection','scalar_column','string','geo identity/matching and disambiguation','provider_sensitive','review_required',null,null,null,'Autocomplete is evidence for matching/selection, not property truth.','{"realtor_candidates": 27, "semantic_lane": "geography"}'::jsonb,'{"no_raw_values": true, "seed_source": "slice17"}'::jsonb),
  ('realtor_geography_autocomplete_match_evidence','realtor_geography_autocomplete_match_evidence:postal_code','$.results[].postal_code','Autocomplete postal code','json_path_projection','scalar_column','string','geo identity/matching and disambiguation','provider_sensitive','review_required',null,null,null,'Autocomplete is evidence for matching/selection, not property truth.','{"realtor_candidates": 27, "semantic_lane": "geography"}'::jsonb,'{"no_raw_values": true, "seed_source": "slice17"}'::jsonb),
  ('realtor_geography_autocomplete_match_evidence','realtor_geography_autocomplete_match_evidence:county_fips','$.results[].counties[].fips','Autocomplete county FIPS','json_path_projection','scalar_column','string','geo identity/matching and disambiguation','provider_sensitive','review_required',null,null,null,'Autocomplete is evidence for matching/selection, not property truth.','{"realtor_candidates": 27, "semantic_lane": "geography"}'::jsonb,'{"no_raw_values": true, "seed_source": "slice17"}'::jsonb),
  ('realtor_geography_autocomplete_match_evidence','realtor_geography_autocomplete_match_evidence:centroid','$.results[].centroid','Autocomplete centroid','derived_projection','postgis_geometry','geo','geo identity/matching and disambiguation','provider_sensitive','review_required',null,null,null,'Autocomplete is evidence for matching/selection, not property truth.','{"realtor_candidates": 27, "semantic_lane": "geography"}'::jsonb,'{"no_raw_values": true, "seed_source": "slice17"}'::jsonb),
  ('reiq_property_geography_signal_evidence','reiq_property_geography_signal_evidence:property_id','$.property_id','REIQ property id','json_path_projection','scalar_column','string','property geography component/routing','pii_sensitive','review_required',null,null,null,'REIQ property geography lane; owner/mailing geography remains separate and restricted.','{"reiq_property_geography_valuation_objects": 2812, "semantic_lane": "geography"}'::jsonb,'{"no_raw_values": true, "seed_source": "slice17"}'::jsonb),
  ('reiq_property_geography_signal_evidence','reiq_property_geography_signal_evidence:property_city','$.property_city','REIQ property city','json_path_projection','scalar_column','string','property geography component/routing','pii_sensitive','review_required',null,null,null,'REIQ property geography lane; owner/mailing geography remains separate and restricted.','{"reiq_property_geography_valuation_objects": 2812, "semantic_lane": "geography"}'::jsonb,'{"no_raw_values": true, "seed_source": "slice17"}'::jsonb),
  ('reiq_property_geography_signal_evidence','reiq_property_geography_signal_evidence:property_state','$.property_state','REIQ property state','json_path_projection','scalar_column','string','property geography component/routing','pii_sensitive','review_required',null,null,null,'REIQ property geography lane; owner/mailing geography remains separate and restricted.','{"reiq_property_geography_valuation_objects": 2812, "semantic_lane": "geography"}'::jsonb,'{"no_raw_values": true, "seed_source": "slice17"}'::jsonb),
  ('reiq_property_geography_signal_evidence','reiq_property_geography_signal_evidence:property_zip_code','$.property_zip_code','REIQ property ZIP','json_path_projection','scalar_column','string','property geography component/routing','pii_sensitive','review_required',null,null,null,'REIQ property geography lane; owner/mailing geography remains separate and restricted.','{"reiq_property_geography_valuation_objects": 2812, "semantic_lane": "geography"}'::jsonb,'{"no_raw_values": true, "seed_source": "slice17"}'::jsonb),
  ('reiq_property_geography_signal_evidence','reiq_property_geography_signal_evidence:county','$.county','REIQ county','json_path_projection','scalar_column','string','property geography component/routing','pii_sensitive','review_required',null,null,null,'REIQ property geography lane; owner/mailing geography remains separate and restricted.','{"reiq_property_geography_valuation_objects": 2812, "semantic_lane": "geography"}'::jsonb,'{"no_raw_values": true, "seed_source": "slice17"}'::jsonb),
  ('reiq_property_geography_signal_evidence','reiq_property_geography_signal_evidence:property_address','$.property_address','REIQ property address','json_path_projection','scalar_column','string','property geography component/routing','pii_sensitive','review_required',null,null,null,'REIQ property geography lane; owner/mailing geography remains separate and restricted.','{"reiq_property_geography_valuation_objects": 2812, "semantic_lane": "geography"}'::jsonb,'{"no_raw_values": true, "seed_source": "slice17"}'::jsonb),
  ('realtor_market_geography_snapshot_evidence','realtor_market_geography_snapshot_evidence:median_listing_price','$.market.housing_market.median_listing_price','Median listing price','derived_projection','scalar_column','number','market snapshot metric after geography','provider_sensitive','review_required',null,null,null,'Market follows geography; temporal snapshot candidate.','{"depends_on_lane": "geography"}'::jsonb,'{"no_raw_values": true, "seed_source": "slice17"}'::jsonb),
  ('realtor_market_geography_snapshot_evidence','realtor_market_geography_snapshot_evidence:median_sold_price','$.market.housing_market.median_sold_price','Median sold price','derived_projection','scalar_column','number','market snapshot metric after geography','provider_sensitive','review_required',null,null,null,'Market follows geography; temporal snapshot candidate.','{"depends_on_lane": "geography"}'::jsonb,'{"no_raw_values": true, "seed_source": "slice17"}'::jsonb),
  ('realtor_market_geography_snapshot_evidence','realtor_market_geography_snapshot_evidence:median_days_on_market','$.market.housing_market.median_days_on_market','Median days on market','derived_projection','scalar_column','number','market snapshot metric after geography','provider_sensitive','review_required',null,null,null,'Market follows geography; temporal snapshot candidate.','{"depends_on_lane": "geography"}'::jsonb,'{"no_raw_values": true, "seed_source": "slice17"}'::jsonb),
  ('realtor_market_geography_snapshot_evidence','realtor_market_geography_snapshot_evidence:local_hotness_score','$.market.housing_market.local_hotness_score','Local hotness score','derived_projection','scalar_column','number','market snapshot metric after geography','provider_sensitive','review_required',null,null,null,'Market follows geography; temporal snapshot candidate.','{"depends_on_lane": "geography"}'::jsonb,'{"no_raw_values": true, "seed_source": "slice17"}'::jsonb),
  ('property_valuation_evidence_realtor_reiq','property_valuation_evidence_realtor_reiq:estimated_value','$.valuation.estimated_value','Estimated value','derived_projection','scalar_column','number','valuation filtering/sorting after source lineage','mixed_review_required','review_required',null,null,null,'Valuation follows geography and source lineage.','{"depends_on_lane": "geography"}'::jsonb,'{"no_raw_values": true, "seed_source": "slice17"}'::jsonb),
  ('property_valuation_evidence_realtor_reiq','property_valuation_evidence_realtor_reiq:assessed_value','$.assessed_value','Assessed value','derived_projection','scalar_column','number','valuation filtering/sorting after source lineage','mixed_review_required','review_required',null,null,null,'Valuation follows geography and source lineage.','{"depends_on_lane": "geography"}'::jsonb,'{"no_raw_values": true, "seed_source": "slice17"}'::jsonb),
  ('property_valuation_evidence_realtor_reiq','property_valuation_evidence_realtor_reiq:appraised_value','$.appraised_value','Appraised value','derived_projection','scalar_column','number','valuation filtering/sorting after source lineage','mixed_review_required','review_required',null,null,null,'Valuation follows geography and source lineage.','{"depends_on_lane": "geography"}'::jsonb,'{"no_raw_values": true, "seed_source": "slice17"}'::jsonb),
  ('property_valuation_evidence_realtor_reiq','property_valuation_evidence_realtor_reiq:equity','$.equity','Equity signal','derived_projection','scalar_column','number','valuation filtering/sorting after source lineage','mixed_review_required','review_required',null,null,null,'Valuation follows geography and source lineage.','{"depends_on_lane": "geography"}'::jsonb,'{"no_raw_values": true, "seed_source": "slice17"}'::jsonb),
  ('property_physical_listing_evidence_realtor_reiq','property_physical_listing_evidence_realtor_reiq:bed','$.description.beds','Bedrooms','json_path_projection','scalar_column','integer','property facts filtering after identity/geography','provider_sensitive','review_required',null,null,null,'Property facts follow geography and property identity review.','{"depends_on_lane": "geography"}'::jsonb,'{"no_raw_values": true, "seed_source": "slice17"}'::jsonb),
  ('property_physical_listing_evidence_realtor_reiq','property_physical_listing_evidence_realtor_reiq:bath','$.description.baths','Bathrooms','json_path_projection','scalar_column','number','property facts filtering after identity/geography','provider_sensitive','review_required',null,null,null,'Property facts follow geography and property identity review.','{"depends_on_lane": "geography"}'::jsonb,'{"no_raw_values": true, "seed_source": "slice17"}'::jsonb),
  ('property_physical_listing_evidence_realtor_reiq','property_physical_listing_evidence_realtor_reiq:sqft','$.description.sqft','Square feet','json_path_projection','scalar_column','integer','property facts filtering after identity/geography','provider_sensitive','review_required',null,null,null,'Property facts follow geography and property identity review.','{"depends_on_lane": "geography"}'::jsonb,'{"no_raw_values": true, "seed_source": "slice17"}'::jsonb),
  ('property_physical_listing_evidence_realtor_reiq','property_physical_listing_evidence_realtor_reiq:year_built','$.description.year_built','Year built','json_path_projection','scalar_column','integer','property facts filtering after identity/geography','provider_sensitive','review_required',null,null,null,'Property facts follow geography and property identity review.','{"depends_on_lane": "geography"}'::jsonb,'{"no_raw_values": true, "seed_source": "slice17"}'::jsonb),
  ('property_physical_listing_evidence_realtor_reiq','property_physical_listing_evidence_realtor_reiq:listing_status','$.status','Listing status','json_path_projection','scalar_column','enum','property facts filtering after identity/geography','provider_sensitive','review_required',null,null,null,'Property facts follow geography and property identity review.','{"depends_on_lane": "geography"}'::jsonb,'{"no_raw_values": true, "seed_source": "slice17"}'::jsonb),
  ('reiq_property_legal_tax_signal_evidence','reiq_property_legal_tax_signal_evidence:lead_type','$.lead_type','Lead/list type','json_path_projection','scalar_column','enum','legal/situation signal after geography and taxonomy support','pii_sensitive','review_required',null,null,null,'Legal/situation follows geography and state/list type semantics.','{"depends_on_lane": "geography", "needs_taxonomy_support": true}'::jsonb,'{"no_raw_values": true, "seed_source": "slice17"}'::jsonb),
  ('reiq_property_legal_tax_signal_evidence','reiq_property_legal_tax_signal_evidence:case_number','$.case_number','Case/document number','json_path_projection','scalar_column','string','legal/situation signal after geography and taxonomy support','pii_sensitive','review_required',null,null,null,'Legal/situation follows geography and state/list type semantics.','{"depends_on_lane": "geography", "needs_taxonomy_support": true}'::jsonb,'{"no_raw_values": true, "seed_source": "slice17"}'::jsonb),
  ('reiq_property_legal_tax_signal_evidence','reiq_property_legal_tax_signal_evidence:date_filed','$.date_filed','Filed date','json_path_projection','scalar_column','temporal','legal/situation signal after geography and taxonomy support','pii_sensitive','review_required',null,null,null,'Legal/situation follows geography and state/list type semantics.','{"depends_on_lane": "geography", "needs_taxonomy_support": true}'::jsonb,'{"no_raw_values": true, "seed_source": "slice17"}'::jsonb),
  ('reiq_property_legal_tax_signal_evidence','reiq_property_legal_tax_signal_evidence:auction_date_time','$.auction_date_time','Auction date/time','json_path_projection','scalar_column','temporal','legal/situation signal after geography and taxonomy support','pii_sensitive','review_required',null,null,null,'Legal/situation follows geography and state/list type semantics.','{"depends_on_lane": "geography", "needs_taxonomy_support": true}'::jsonb,'{"no_raw_values": true, "seed_source": "slice17"}'::jsonb),
  ('lfg_taxonomy_projection_semantic_support','lfg_taxonomy_projection_semantic_support:baseline_version','$.baseline_version','Baseline version','json_path_projection','scalar_column','string','semantic support for gate approval','restricted','review_required',null,null,null,'Taxonomy/support artifacts drive gate approval, not provider truth.','{"leadfinder_system_candidates": 9, "matrix_registry_candidates": 315}'::jsonb,'{"no_raw_values": true, "seed_source": "slice17"}'::jsonb),
  ('lfg_taxonomy_projection_semantic_support','lfg_taxonomy_projection_semantic_support:contract_refs','$.contract_refs[]','Contract refs','json_path_projection','scalar_column','string','semantic support for gate approval','restricted','review_required',null,null,null,'Taxonomy/support artifacts drive gate approval, not provider truth.','{"leadfinder_system_candidates": 9, "matrix_registry_candidates": 315}'::jsonb,'{"no_raw_values": true, "seed_source": "slice17"}'::jsonb),
  ('lfg_taxonomy_projection_semantic_support','lfg_taxonomy_projection_semantic_support:artifact_kind','$.artifact_kind','Artifact kind','json_path_projection','scalar_column','string','semantic support for gate approval','restricted','review_required',null,null,null,'Taxonomy/support artifacts drive gate approval, not provider truth.','{"leadfinder_system_candidates": 9, "matrix_registry_candidates": 315}'::jsonb,'{"no_raw_values": true, "seed_source": "slice17"}'::jsonb)
)
insert into prop4you_leadfinder_group.projection_candidates (group_id, candidate_key, json_path, path_label, candidate_kind, projection_shape, path_value_kind, relational_need, privacy_class, review_status, proposed_table, proposed_column, proposed_type, candidate_reason, corpus_evidence, lineage, canonical_envelope_key, schema_version)
select g.id, s.candidate_key, s.json_path, s.path_label, s.candidate_kind, s.projection_shape, s.path_value_kind, s.relational_need, s.privacy_class, s.review_status, s.proposed_table, s.proposed_column, s.proposed_type, s.candidate_reason, s.corpus_evidence, s.lineage, g.canonical_envelope_key, g.schema_version
from seed s
join prop4you_leadfinder_group.projection_candidate_groups g on g.group_key = s.group_key
on conflict (candidate_key) do update set json_path=excluded.json_path, path_label=excluded.path_label, candidate_kind=excluded.candidate_kind, projection_shape=excluded.projection_shape, path_value_kind=excluded.path_value_kind, relational_need=excluded.relational_need, privacy_class=excluded.privacy_class, review_status=excluded.review_status, proposed_table=excluded.proposed_table, proposed_column=excluded.proposed_column, proposed_type=excluded.proposed_type, candidate_reason=excluded.candidate_reason, corpus_evidence=excluded.corpus_evidence, lineage=excluded.lineage, canonical_envelope_key=excluded.canonical_envelope_key, schema_version=excluded.schema_version, updated_at=now(), version=prop4you_leadfinder_group.projection_candidates.version+1;

insert into prop4you_leadfinder_group.projection_candidate_gate_evaluations (candidate_id, policy_key, policy_version, gate_key, gate_number, required, evidence_summary)
select c.id, g.policy_key, g.policy_version, g.gate_key, g.gate_number, g.required, jsonb_build_object('seed_source','slice17','default_status','not_evaluated','no_raw_values',true)
from prop4you_leadfinder_group.projection_candidates c
cross join prop4you_leadfinder_group.v_active_projection_policy_gates g
where c.active = true
on conflict (candidate_id, gate_key) do update set gate_number=excluded.gate_number, required=excluded.required, evidence_summary=prop4you_leadfinder_group.projection_candidate_gate_evaluations.evidence_summary || excluded.evidence_summary, updated_at=now(), version=prop4you_leadfinder_group.projection_candidate_gate_evaluations.version+1;

insert into prop4you_leadfinder_group.projection_candidate_reviews (candidate_id, review_key, review_status, review_decision, decision_reason, review_payload)
select c.id, c.candidate_key || ':initial_review', 'in_review', case when c.projection_shape = 'jsonb_only' then 'keep_jsonb' else 'needs_review' end, 'Initial Slice 17 seed. No approval until all seven required gates pass.', jsonb_build_object('seed_source','slice17','raw_values_allowed',false)
from prop4you_leadfinder_group.projection_candidates c
where c.active = true
on conflict (review_key) do update set review_decision=excluded.review_decision, decision_reason=excluded.decision_reason, review_payload=excluded.review_payload, updated_at=now(), version=prop4you_leadfinder_group.projection_candidate_reviews.version+1;

create or replace view prop4you_leadfinder_group.v_projection_candidate_gate_status as
select c.candidate_key, c.json_path, g.group_key, g.lane_key, g.sequence_number, c.projection_shape, c.review_status, count(*) filter (where e.required) as required_gate_count, count(*) filter (where e.required and e.gate_status = 'passed') as passed_required_gate_count, count(*) filter (where e.required and e.gate_status in ('failed','blocked')) as blocking_required_gate_count, bool_and(e.gate_status = 'passed') filter (where e.required) as all_required_gates_passed
from prop4you_leadfinder_group.projection_candidates c
join prop4you_leadfinder_group.projection_candidate_groups g on g.id = c.group_id
left join prop4you_leadfinder_group.projection_candidate_gate_evaluations e on e.candidate_id = c.id
where c.active = true and g.active = true
group by c.candidate_key, c.json_path, g.group_key, g.lane_key, g.sequence_number, c.projection_shape, c.review_status;

create or replace view prop4you_leadfinder_group.v_active_projection_candidates as
select g.group_key, g.group_label, g.lane_key, g.semantic_lane, g.sequence_number, c.candidate_key, c.json_path, c.path_label, c.projection_shape, c.path_value_kind, c.privacy_class, c.review_status, c.relational_need, s.required_gate_count, s.passed_required_gate_count, s.blocking_required_gate_count, coalesce(s.all_required_gates_passed, false) as all_required_gates_passed
from prop4you_leadfinder_group.projection_candidates c
join prop4you_leadfinder_group.projection_candidate_groups g on g.id = c.group_id
left join prop4you_leadfinder_group.v_projection_candidate_gate_status s on s.candidate_key = c.candidate_key
where c.active = true and g.active = true;

create or replace view prop4you_leadfinder_group.v_approved_projection_candidates as
select a.*
from prop4you_leadfinder_group.v_active_projection_candidates a
join prop4you_leadfinder_group.projection_candidates c on c.candidate_key = a.candidate_key
join prop4you_leadfinder_group.projection_candidate_reviews r on r.candidate_id = c.id
where r.review_status = 'approved' and r.all_required_gates_passed = true and a.all_required_gates_passed = true;

create or replace view prop4you_leadfinder_group.v_projection_candidate_next_action_queue as
select *
from prop4you_leadfinder_group.v_active_projection_candidates
where review_status in ('pending','review_required','needs_more_evidence') or blocking_required_gate_count > 0 or all_required_gates_passed = false
order by sequence_number asc, group_key asc, candidate_key asc;

comment on view prop4you_leadfinder_group.v_projection_candidate_gate_status is 'Projection candidate gate status; approval requires all seven required gates passed.';
comment on view prop4you_leadfinder_group.v_active_projection_candidates is 'Active LFG projection candidates ordered by semantic lane and sequence.';
comment on view prop4you_leadfinder_group.v_approved_projection_candidates is 'Only candidates with explicit approved review and all required gates passed. Should be empty until deliberate approvals occur.';
comment on view prop4you_leadfinder_group.v_projection_candidate_next_action_queue is 'Candidates needing review, evidence, or gate evaluation before any final projection implementation.';
