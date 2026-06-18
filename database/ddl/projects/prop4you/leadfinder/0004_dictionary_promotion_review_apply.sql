-- package: prop4you/leadfinder
-- file: 0004_dictionary_promotion_review_apply.sql
-- status: experimental / non-final
-- purpose: Explicit review/apply gate for prepare-only dictionary promotion proposals.
-- depends-on: leadfinder/0003_prepare_dictionary_promotions.sql
-- idempotency: idempotent
-- destructive: false
-- [REVIEW_GATE] Prepared proposals must be reviewed before apply.
-- [NO_WORKSPACE_AUTO_APPLY] User/workspace feedback can recommend review but never applies canonical dictionary changes directly.
-- [GATEWAY_AGNOSTIC] Callable by direct SQL, ORM, PostgREST RPC, Django/FastAPI passthrough, workers, or any other transport.
-- [NO_RAW_VALUES] Stores proposal metadata only; no provider raw payload values.

create schema if not exists prop4you_leadfinder;

create table if not exists prop4you_leadfinder.dictionary_promotion_reviews (
  id uuid primary key default uuidv7(),
  public_ref text generated always as (base.make_public_ref('p4ylfpr', id)) stored,
  preparation_id uuid not null references prop4you_leadfinder.dictionary_promotion_preparations(id) on delete restrict,
  review_key text not null,
  review_status text not null default 'in_review',
  review_decision text not null default 'pending',
  reviewer_actor_id text,
  reviewed_at timestamptz,
  decision_reason text,
  accepted_payload jsonb not null default '{}'::jsonb,
  risk_summary jsonb not null default '{}'::jsonb,
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint dictionary_promotion_reviews_public_ref_key unique (public_ref),
  constraint dictionary_promotion_reviews_key_key unique (review_key),
  constraint dictionary_promotion_reviews_preparation_decision_key unique (preparation_id, review_decision),
  constraint dictionary_promotion_reviews_key_format_chk check (review_key ~ '^[a-z][a-z0-9_.:-]{1,191}$'),
  constraint dictionary_promotion_reviews_status_chk check (review_status in ('in_review','accepted','rejected','deferred','superseded','applied','archived')),
  constraint dictionary_promotion_reviews_decision_chk check (review_decision in ('pending','accept','reject','defer','supersede')),
  constraint dictionary_promotion_reviews_json_chk check (jsonb_typeof(accepted_payload)='object' and jsonb_typeof(risk_summary)='object' and jsonb_typeof(metadata)='object')
);

create table if not exists prop4you_leadfinder.dictionary_promotion_applications (
  id uuid primary key default uuidv7(),
  public_ref text generated always as (base.make_public_ref('p4ylfpa', id)) stored,
  review_id uuid not null references prop4you_leadfinder.dictionary_promotion_reviews(id) on delete restrict,
  preparation_id uuid not null references prop4you_leadfinder.dictionary_promotion_preparations(id) on delete restrict,
  application_key text not null,
  application_status text not null default 'applied',
  proposal_kind text not null,
  dictionary_version_id uuid not null references prop4you_leadfinder.canonical_dictionary_versions(id) on delete restrict,
  canonical_family_id uuid references prop4you_leadfinder.canonical_families(id) on delete set null,
  canonical_field_id uuid references prop4you_leadfinder.canonical_fields(id) on delete set null,
  application_payload jsonb not null default '{}'::jsonb,
  metadata jsonb not null default '{}'::jsonb,
  applied_at timestamptz not null default now(),
  applied_by_actor_id text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint dictionary_promotion_applications_public_ref_key unique (public_ref),
  constraint dictionary_promotion_applications_review_key unique (review_id),
  constraint dictionary_promotion_applications_key_key unique (application_key),
  constraint dictionary_promotion_applications_key_format_chk check (application_key ~ '^[a-z][a-z0-9_.:-]{1,191}$'),
  constraint dictionary_promotion_applications_status_chk check (application_status in ('applied','failed','superseded','archived')),
  constraint dictionary_promotion_applications_kind_chk check (proposal_kind in ('create_family','create_field','link_existing_field','review_only')),
  constraint dictionary_promotion_applications_json_chk check (jsonb_typeof(application_payload)='object' and jsonb_typeof(metadata)='object')
);

create index if not exists dictionary_promotion_reviews_status_idx on prop4you_leadfinder.dictionary_promotion_reviews (review_status, review_decision, updated_at desc);
create index if not exists dictionary_promotion_reviews_preparation_idx on prop4you_leadfinder.dictionary_promotion_reviews (preparation_id, review_status);
create index if not exists dictionary_promotion_applications_prep_idx on prop4you_leadfinder.dictionary_promotion_applications (preparation_id, application_status);

create or replace function prop4you_leadfinder.review_dictionary_promotion(
  p_preparation_id uuid,
  p_review_decision text default 'accept',
  p_reviewer_actor_id text default null,
  p_decision_reason text default null,
  p_metadata jsonb default '{}'::jsonb
)
returns prop4you_leadfinder.dictionary_promotion_reviews
language plpgsql
volatile
as $$
declare
  prep prop4you_leadfinder.dictionary_promotion_preparations;
  review_row prop4you_leadfinder.dictionary_promotion_reviews;
  review_status_value text;
begin
  select * into prep from prop4you_leadfinder.dictionary_promotion_preparations where id=p_preparation_id;
  if not found then raise exception 'dictionary promotion preparation not found: %', p_preparation_id using errcode='22023'; end if;
  if p_review_decision not in ('pending','accept','reject','defer','supersede') then
    raise exception 'invalid review decision: %', p_review_decision using errcode='22023';
  end if;

  review_status_value := case p_review_decision
    when 'pending' then 'in_review'
    when 'accept' then 'accepted'
    when 'reject' then 'rejected'
    when 'defer' then 'deferred'
    when 'supersede' then 'superseded'
  end;

  insert into prop4you_leadfinder.dictionary_promotion_reviews as r (
    preparation_id, review_key, review_status, review_decision, reviewer_actor_id, reviewed_at,
    decision_reason, accepted_payload, risk_summary, metadata
  ) values (
    prep.id,
    'dictionary_promotion_review:' || replace(prep.id::text,'-','') || ':' || p_review_decision,
    review_status_value,
    p_review_decision,
    p_reviewer_actor_id,
    case when p_review_decision='pending' then null else now() end,
    p_decision_reason,
    jsonb_build_object('preparation', to_jsonb(prep), 'no_workspace_auto_apply', true, 'no_raw_values', true),
    jsonb_build_object('requires_review_gate', true, 'workspace_feedback_not_authority', true),
    jsonb_build_object('source','review_dictionary_promotion','gateway_agnostic',true) || coalesce(p_metadata,'{}'::jsonb)
  ) on conflict (review_key) do update
    set review_status=excluded.review_status,
        reviewer_actor_id=excluded.reviewer_actor_id,
        reviewed_at=excluded.reviewed_at,
        decision_reason=excluded.decision_reason,
        accepted_payload=excluded.accepted_payload,
        risk_summary=excluded.risk_summary,
        metadata=excluded.metadata,
        updated_at=now()
  returning * into review_row;

  update prop4you_leadfinder.dictionary_promotion_preparations
     set proposal_status = case p_review_decision
       when 'pending' then 'in_review'
       when 'accept' then 'accepted_for_manual_apply'
       when 'reject' then 'rejected'
       when 'defer' then 'deferred'
       when 'supersede' then 'superseded'
     end,
     updated_at=now()
   where id=prep.id;

  return review_row;
end;
$$;

create or replace function prop4you_leadfinder.apply_dictionary_promotion_review(
  p_review_id uuid,
  p_actor_id text default null,
  p_metadata jsonb default '{}'::jsonb
)
returns prop4you_leadfinder.dictionary_promotion_applications
language plpgsql
volatile
as $$
declare
  review_row prop4you_leadfinder.dictionary_promotion_reviews;
  prep prop4you_leadfinder.dictionary_promotion_preparations;
  family_id_value uuid;
  field_id_value uuid;
  app_row prop4you_leadfinder.dictionary_promotion_applications;
begin
  select * into review_row from prop4you_leadfinder.dictionary_promotion_reviews where id=p_review_id;
  if not found then raise exception 'dictionary promotion review not found: %', p_review_id using errcode='22023'; end if;
  if review_row.review_status <> 'accepted' or review_row.review_decision <> 'accept' then
    raise exception 'review must be accepted before apply: %', p_review_id using errcode='22023';
  end if;
  select * into prep from prop4you_leadfinder.dictionary_promotion_preparations where id=review_row.preparation_id;

  if prep.existing_family_id is not null then
    family_id_value := prep.existing_family_id;
  else
    insert into prop4you_leadfinder.canonical_families (
      dictionary_version_id, family_key, display_name, family_role, candidate_status, description, evidence_origin, metadata
    ) values (
      prep.dictionary_version_id,
      prep.target_family_key,
      initcap(replace(prep.target_family_key,'_',' ')),
      prep.proposed_family_role,
      'in_review',
      'Created by explicit dictionary promotion review/apply gate from raw-derived Matrix field mapping proposal.',
      jsonb_build_object('source','dictionary_promotion_review_apply','preparation_id',prep.id,'review_id',review_row.id,'no_raw_values',true),
      jsonb_build_object('applied_by_actor_id',p_actor_id,'gateway_agnostic',true) || coalesce(p_metadata,'{}'::jsonb)
    ) on conflict (dictionary_version_id, family_key) do update
      set candidate_status = case when prop4you_leadfinder.canonical_families.candidate_status='candidate' then 'in_review' else prop4you_leadfinder.canonical_families.candidate_status end,
          metadata = prop4you_leadfinder.canonical_families.metadata || excluded.metadata,
          updated_at=now()
    returning id into family_id_value;
  end if;

  if prep.proposal_kind in ('create_family','create_field','link_existing_field') and prep.target_field_key is not null then
    if prep.existing_field_id is not null then
      field_id_value := prep.existing_field_id;
    else
      insert into prop4you_leadfinder.canonical_fields (
        dictionary_version_id, family_id, field_key, display_name, value_kind, cardinality,
        candidate_status, materialization_intent, pii_classification, description, evidence_origin, metadata
      ) values (
        prep.dictionary_version_id,
        family_id_value,
        prep.target_field_key,
        initcap(replace(prep.target_field_key,'_',' ')),
        prep.proposed_value_kind,
        prep.proposed_cardinality,
        'in_review',
        prep.proposed_materialization_intent,
        prep.proposed_pii_classification,
        'Created by explicit dictionary promotion review/apply gate from raw-derived Matrix field mapping proposal.',
        jsonb_build_object('source','dictionary_promotion_review_apply','preparation_id',prep.id,'review_id',review_row.id,'source_path_label',prep.source_path_label,'no_raw_values',true),
        jsonb_build_object('applied_by_actor_id',p_actor_id,'gateway_agnostic',true) || coalesce(p_metadata,'{}'::jsonb)
      ) on conflict (dictionary_version_id, family_id, field_key) do update
        set candidate_status = case when prop4you_leadfinder.canonical_fields.candidate_status='candidate' then 'in_review' else prop4you_leadfinder.canonical_fields.candidate_status end,
            metadata = prop4you_leadfinder.canonical_fields.metadata || excluded.metadata,
            updated_at=now()
      returning id into field_id_value;
    end if;
  end if;

  insert into prop4you_leadfinder.dictionary_promotion_applications as a (
    review_id, preparation_id, application_key, application_status, proposal_kind, dictionary_version_id,
    canonical_family_id, canonical_field_id, application_payload, metadata, applied_by_actor_id
  ) values (
    review_row.id,
    prep.id,
    'dictionary_promotion_application:' || replace(review_row.id::text,'-',''),
    'applied',
    prep.proposal_kind,
    prep.dictionary_version_id,
    family_id_value,
    field_id_value,
    jsonb_build_object('proposal_kind',prep.proposal_kind,'target_family_key',prep.target_family_key,'target_field_key',prep.target_field_key,'canonical_family_id',family_id_value,'canonical_field_id',field_id_value,'no_workspace_auto_apply',true,'no_raw_values',true),
    jsonb_build_object('source','apply_dictionary_promotion_review','review_gate',true,'gateway_agnostic',true) || coalesce(p_metadata,'{}'::jsonb),
    p_actor_id
  ) on conflict (review_id) do update
    set canonical_family_id=excluded.canonical_family_id,
        canonical_field_id=excluded.canonical_field_id,
        application_payload=excluded.application_payload,
        metadata=excluded.metadata,
        updated_at=now()
  returning * into app_row;

  update prop4you_leadfinder.dictionary_promotion_reviews set review_status='applied', updated_at=now() where id=review_row.id;
  update prop4you_leadfinder.dictionary_promotion_preparations set proposal_status='accepted_for_manual_apply', updated_at=now() where id=prep.id;
  return app_row;
end;
$$;

create or replace view prop4you_leadfinder.v_dictionary_promotion_apply_review as
select p.id as preparation_id,
       p.public_ref as preparation_public_ref,
       p.proposal_key,
       p.proposal_kind,
       p.proposal_status,
       p.target_family_key,
       p.target_field_key,
       r.id as review_id,
       r.review_status,
       r.review_decision,
       a.id as application_id,
       a.application_status,
       a.canonical_family_id,
       a.canonical_field_id,
       p.updated_at
  from prop4you_leadfinder.dictionary_promotion_preparations p
  left join prop4you_leadfinder.dictionary_promotion_reviews r on r.preparation_id=p.id
  left join prop4you_leadfinder.dictionary_promotion_applications a on a.review_id=r.id;

comment on table prop4you_leadfinder.dictionary_promotion_reviews is 'Explicit review gate for prepare-only dictionary promotion proposals. User/workspace feedback cannot bypass this gate.';
comment on table prop4you_leadfinder.dictionary_promotion_applications is 'Idempotent application record for accepted dictionary promotion reviews, linking to canonical family/field rows.';
