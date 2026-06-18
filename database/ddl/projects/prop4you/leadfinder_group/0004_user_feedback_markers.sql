-- package: prop4you/leadfinder_group
-- file: 0004_user_feedback_markers.sql
-- status: experimental / non-final
-- purpose: User/workspace feedback votes, aggregate marker reviews, and global LFG marker apply gate.
-- depends-on: leadfinder_group/0003_operational_minimum.sql, prop4you_user_workspace boundary docs
-- idempotency: idempotent
-- destructive: false
-- [WEAK_RELATIONSHIP] User/workspace/item refs are weak text/version/hash refs, not strong cross-boundary FKs.
-- [NO_AUTO_GLOBAL_FROM_SINGLE_VOTE] A single user vote never mutates global LFG truth directly.
-- [REVIEW_GATE] Aggregates recommend; human or authorized policy review applies global markers.
-- [GATEWAY_AGNOSTIC] Callable by direct SQL, ORM, PostgREST RPC, Django/FastAPI passthrough, workers, or any other transport.
-- [NO_PROVIDER_CALLS] No HTTP/provider calls, no corpus reads, no secrets.

create schema if not exists prop4you_leadfinder_group;

create table if not exists prop4you_leadfinder_group.user_feedback_votes (
  id uuid primary key default uuidv7(),
  public_ref text generated always as (base.make_public_ref('p4ylfgv', id)) stored,
  feedback_key text not null,
  feedback_status text not null default 'active',
  feedback_source text not null default 'user_workspace',
  workspace_schema_name text not null default 'prop4you_user_workspace',
  workspace_ref text,
  workspace_account_ref text,
  user_ref text not null,
  actor_ref text,
  snapshot_ref text,
  campaign_ref text,
  item_kind text not null,
  item_ref text not null,
  item_public_ref text,
  item_hash text,
  item_version text,
  group_id uuid references prop4you_leadfinder_group.operational_groups(id) on delete set null,
  facet_id uuid references prop4you_leadfinder_group.operational_group_facets(id) on delete set null,
  marker_kind text not null,
  vote_value text not null,
  vote_weight numeric(8,4) not null default 1.0,
  vote_reason text,
  correction_payload jsonb not null default '{}'::jsonb,
  evidence_payload jsonb not null default '{}'::jsonb,
  lineage jsonb not null default '{}'::jsonb,
  metadata jsonb not null default '{}'::jsonb,
  reported_at timestamptz not null default now(),
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
  constraint user_feedback_votes_public_ref_key unique (public_ref),
  constraint user_feedback_votes_feedback_key_key unique (feedback_key),
  constraint user_feedback_votes_feedback_key_format_chk check (feedback_key ~ '^[a-z][a-z0-9_.:-]{1,191}$'),
  constraint user_feedback_votes_status_chk check (feedback_status in ('active','withdrawn','superseded','ignored','archived')),
  constraint user_feedback_votes_source_chk check (feedback_source in ('user_workspace','operator_review','imported_feedback','system_test','unknown')),
  constraint user_feedback_votes_workspace_schema_chk check (workspace_schema_name = 'prop4you_user_workspace'),
  constraint user_feedback_votes_item_kind_chk check (item_kind in ('phone','email','mailing_address','owner','property','contact','group','facet','unknown')),
  constraint user_feedback_votes_marker_kind_chk check (marker_kind in ('dnc','wrong','invalid','stale','corrected','verified','unreachable','deliverable','undeliverable','other')),
  constraint user_feedback_votes_vote_value_chk check (vote_value in ('assert','dispute','confirm','withdraw')),
  constraint user_feedback_votes_weight_chk check (vote_weight > 0 and vote_weight <= 10),
  constraint user_feedback_votes_item_ref_nonempty_chk check (length(item_ref) > 0),
  constraint user_feedback_votes_user_ref_nonempty_chk check (length(user_ref) > 0),
  constraint user_feedback_votes_hash_chk check (item_hash is null or item_hash ~ '^[0-9a-f]{32,128}$'),
  constraint user_feedback_votes_json_chk check (jsonb_typeof(correction_payload)='object' and jsonb_typeof(evidence_payload)='object' and jsonb_typeof(lineage)='object' and jsonb_typeof(metadata)='object'),
  constraint user_feedback_votes_version_positive_chk check (version > 0)
);

create table if not exists prop4you_leadfinder_group.feedback_marker_aggregates (
  id uuid primary key default uuidv7(),
  public_ref text generated always as (base.make_public_ref('p4ylfga', id)) stored,
  aggregate_key text not null,
  aggregate_status text not null default 'candidate',
  item_kind text not null,
  item_ref text not null,
  item_public_ref text,
  marker_kind text not null,
  assert_vote_count integer not null default 0,
  dispute_vote_count integer not null default 0,
  confirm_vote_count integer not null default 0,
  distinct_user_count integer not null default 0,
  distinct_workspace_count integer not null default 0,
  net_score numeric(12,4) not null default 0,
  recommendation text not null default 'insufficient_signal',
  recommendation_reason text not null default 'not_refreshed',
  threshold_policy jsonb not null default '{"min_distinct_users":2,"min_net_score":2,"requires_review":true}'::jsonb,
  last_vote_at timestamptz,
  reviewed_at timestamptz,
  reviewed_by_actor_id text,
  lineage jsonb not null default '{}'::jsonb,
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
  constraint feedback_marker_aggregates_public_ref_key unique (public_ref),
  constraint feedback_marker_aggregates_key_key unique (aggregate_key),
  constraint feedback_marker_aggregates_target_key unique (item_kind, item_ref, marker_kind),
  constraint feedback_marker_aggregates_key_format_chk check (aggregate_key ~ '^[a-z][a-z0-9_.:-]{1,191}$'),
  constraint feedback_marker_aggregates_status_chk check (aggregate_status in ('candidate','in_review','reviewed','applied','rejected','superseded','archived')),
  constraint feedback_marker_aggregates_item_kind_chk check (item_kind in ('phone','email','mailing_address','owner','property','contact','group','facet','unknown')),
  constraint feedback_marker_aggregates_marker_kind_chk check (marker_kind in ('dnc','wrong','invalid','stale','corrected','verified','unreachable','deliverable','undeliverable','other')),
  constraint feedback_marker_aggregates_counts_chk check (assert_vote_count >= 0 and dispute_vote_count >= 0 and confirm_vote_count >= 0 and distinct_user_count >= 0 and distinct_workspace_count >= 0),
  constraint feedback_marker_aggregates_recommendation_chk check (recommendation in ('insufficient_signal','human_review_candidate','auto_apply_candidate','reject_candidate','conflict_review')),
  constraint feedback_marker_aggregates_json_chk check (jsonb_typeof(threshold_policy)='object' and jsonb_typeof(lineage)='object' and jsonb_typeof(metadata)='object'),
  constraint feedback_marker_aggregates_version_positive_chk check (version > 0)
);

create table if not exists prop4you_leadfinder_group.feedback_marker_reviews (
  id uuid primary key default uuidv7(),
  public_ref text generated always as (base.make_public_ref('p4ylfgrv', id)) stored,
  aggregate_id uuid not null references prop4you_leadfinder_group.feedback_marker_aggregates(id) on delete restrict,
  review_key text not null,
  review_status text not null default 'in_review',
  review_decision text not null default 'pending',
  decision_reason text,
  reviewer_actor_id text,
  reviewed_at timestamptz,
  accepted_marker_status text not null default 'asserted',
  review_payload jsonb not null default '{}'::jsonb,
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint feedback_marker_reviews_public_ref_key unique (public_ref),
  constraint feedback_marker_reviews_key_key unique (review_key),
  constraint feedback_marker_reviews_aggregate_active_key unique (aggregate_id, review_status) deferrable initially immediate,
  constraint feedback_marker_reviews_key_format_chk check (review_key ~ '^[a-z][a-z0-9_.:-]{1,191}$'),
  constraint feedback_marker_reviews_status_chk check (review_status in ('in_review','accepted','rejected','deferred','applied','superseded','archived')),
  constraint feedback_marker_reviews_decision_chk check (review_decision in ('pending','accept_global_marker','reject_global_marker','defer','request_more_votes','supersede')),
  constraint feedback_marker_reviews_marker_status_chk check (accepted_marker_status in ('asserted','disputed','blocked','superseded','archived')),
  constraint feedback_marker_reviews_json_chk check (jsonb_typeof(review_payload)='object' and jsonb_typeof(metadata)='object')
);

create table if not exists prop4you_leadfinder_group.global_item_markers (
  id uuid primary key default uuidv7(),
  public_ref text generated always as (base.make_public_ref('p4ylfgm', id)) stored,
  marker_key text not null,
  marker_status text not null default 'asserted',
  item_kind text not null,
  item_ref text not null,
  item_public_ref text,
  marker_kind text not null,
  source_review_id uuid not null references prop4you_leadfinder_group.feedback_marker_reviews(id) on delete restrict,
  source_aggregate_id uuid not null references prop4you_leadfinder_group.feedback_marker_aggregates(id) on delete restrict,
  confidence numeric(5,4) not null default 1.0,
  marker_payload jsonb not null default '{}'::jsonb,
  lineage jsonb not null default '{}'::jsonb,
  metadata jsonb not null default '{}'::jsonb,
  applied_at timestamptz not null default now(),
  applied_by_actor_id text,
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
  constraint global_item_markers_public_ref_key unique (public_ref),
  constraint global_item_markers_marker_key_key unique (marker_key),
  constraint global_item_markers_target_key unique (item_kind, item_ref, marker_kind),
  constraint global_item_markers_key_format_chk check (marker_key ~ '^[a-z][a-z0-9_.:-]{1,191}$'),
  constraint global_item_markers_status_chk check (marker_status in ('asserted','disputed','blocked','superseded','archived')),
  constraint global_item_markers_item_kind_chk check (item_kind in ('phone','email','mailing_address','owner','property','contact','group','facet','unknown')),
  constraint global_item_markers_marker_kind_chk check (marker_kind in ('dnc','wrong','invalid','stale','corrected','verified','unreachable','deliverable','undeliverable','other')),
  constraint global_item_markers_confidence_chk check (confidence >= 0 and confidence <= 1),
  constraint global_item_markers_json_chk check (jsonb_typeof(marker_payload)='object' and jsonb_typeof(lineage)='object' and jsonb_typeof(metadata)='object'),
  constraint global_item_markers_version_positive_chk check (version > 0)
);

create index if not exists user_feedback_votes_target_idx on prop4you_leadfinder_group.user_feedback_votes (item_kind, item_ref, marker_kind, feedback_status);
create index if not exists user_feedback_votes_user_idx on prop4you_leadfinder_group.user_feedback_votes (user_ref, workspace_ref, reported_at desc);
create index if not exists feedback_marker_aggregates_recommendation_idx on prop4you_leadfinder_group.feedback_marker_aggregates (recommendation, aggregate_status, updated_at desc);
create index if not exists feedback_marker_reviews_status_idx on prop4you_leadfinder_group.feedback_marker_reviews (review_status, review_decision, updated_at desc);
create index if not exists global_item_markers_target_idx on prop4you_leadfinder_group.global_item_markers (item_kind, item_ref, marker_kind, marker_status);

drop trigger if exists user_feedback_votes_set_lifecycle_defaults on prop4you_leadfinder_group.user_feedback_votes;
create trigger user_feedback_votes_set_lifecycle_defaults before insert on prop4you_leadfinder_group.user_feedback_votes for each row execute function base.set_lifecycle_defaults();
drop trigger if exists user_feedback_votes_touch_updated_at on prop4you_leadfinder_group.user_feedback_votes;
create trigger user_feedback_votes_touch_updated_at before update on prop4you_leadfinder_group.user_feedback_votes for each row execute function base.touch_updated_at();
drop trigger if exists user_feedback_votes_increment_version on prop4you_leadfinder_group.user_feedback_votes;
create trigger user_feedback_votes_increment_version before update on prop4you_leadfinder_group.user_feedback_votes for each row execute function base.increment_version();

drop trigger if exists feedback_marker_aggregates_set_lifecycle_defaults on prop4you_leadfinder_group.feedback_marker_aggregates;
create trigger feedback_marker_aggregates_set_lifecycle_defaults before insert on prop4you_leadfinder_group.feedback_marker_aggregates for each row execute function base.set_lifecycle_defaults();
drop trigger if exists feedback_marker_aggregates_touch_updated_at on prop4you_leadfinder_group.feedback_marker_aggregates;
create trigger feedback_marker_aggregates_touch_updated_at before update on prop4you_leadfinder_group.feedback_marker_aggregates for each row execute function base.touch_updated_at();
drop trigger if exists feedback_marker_aggregates_increment_version on prop4you_leadfinder_group.feedback_marker_aggregates;
create trigger feedback_marker_aggregates_increment_version before update on prop4you_leadfinder_group.feedback_marker_aggregates for each row execute function base.increment_version();

drop trigger if exists global_item_markers_set_lifecycle_defaults on prop4you_leadfinder_group.global_item_markers;
create trigger global_item_markers_set_lifecycle_defaults before insert on prop4you_leadfinder_group.global_item_markers for each row execute function base.set_lifecycle_defaults();
drop trigger if exists global_item_markers_touch_updated_at on prop4you_leadfinder_group.global_item_markers;
create trigger global_item_markers_touch_updated_at before update on prop4you_leadfinder_group.global_item_markers for each row execute function base.touch_updated_at();
drop trigger if exists global_item_markers_increment_version on prop4you_leadfinder_group.global_item_markers;
create trigger global_item_markers_increment_version before update on prop4you_leadfinder_group.global_item_markers for each row execute function base.increment_version();

create or replace function prop4you_leadfinder_group.refresh_feedback_marker_aggregate(
  p_item_kind text,
  p_item_ref text,
  p_marker_kind text,
  p_actor_id text default null
)
returns prop4you_leadfinder_group.feedback_marker_aggregates
language plpgsql
volatile
as $$
declare
  aggregate_row prop4you_leadfinder_group.feedback_marker_aggregates;
  assert_count integer;
  dispute_count integer;
  confirm_count integer;
  distinct_users integer;
  distinct_workspaces integer;
  score numeric(12,4);
  recommendation_value text;
  reason_value text;
  last_vote timestamptz;
begin
  select count(*) filter (where vote_value='assert'),
         count(*) filter (where vote_value='dispute'),
         count(*) filter (where vote_value='confirm'),
         count(distinct user_ref),
         count(distinct coalesce(workspace_ref,'__none__')),
         coalesce(sum(case vote_value when 'assert' then vote_weight when 'confirm' then vote_weight when 'dispute' then -vote_weight else 0 end),0),
         max(reported_at)
    into assert_count, dispute_count, confirm_count, distinct_users, distinct_workspaces, score, last_vote
    from prop4you_leadfinder_group.user_feedback_votes
   where deleted=false and feedback_status='active'
     and item_kind=p_item_kind and item_ref=p_item_ref and marker_kind=p_marker_kind;

  if score >= 2 and distinct_users >= 2 then
    recommendation_value := 'auto_apply_candidate';
    reason_value := 'threshold_met_distinct_users_and_net_score_requires_review_gate';
  elsif score > 0 then
    recommendation_value := 'human_review_candidate';
    reason_value := 'positive_signal_below_auto_threshold';
  elsif score < 0 then
    recommendation_value := 'reject_candidate';
    reason_value := 'negative_net_score';
  elsif assert_count > 0 and dispute_count > 0 then
    recommendation_value := 'conflict_review';
    reason_value := 'conflicting_feedback';
  else
    recommendation_value := 'insufficient_signal';
    reason_value := 'not_enough_active_votes';
  end if;

  insert into prop4you_leadfinder_group.feedback_marker_aggregates as a (
    aggregate_key, aggregate_status, item_kind, item_ref, marker_kind,
    assert_vote_count, dispute_vote_count, confirm_vote_count,
    distinct_user_count, distinct_workspace_count, net_score,
    recommendation, recommendation_reason, last_vote_at,
    lineage, metadata, last_modified_by_actor_id
  ) values (
    'lfg_feedback_aggregate:' || p_item_kind || ':' || left(regexp_replace(p_item_ref,'[^a-zA-Z0-9]+','_','g'),80) || ':' || p_marker_kind,
    'candidate', p_item_kind, p_item_ref, p_marker_kind,
    coalesce(assert_count,0), coalesce(dispute_count,0), coalesce(confirm_count,0),
    coalesce(distinct_users,0), coalesce(distinct_workspaces,0), coalesce(score,0),
    recommendation_value, reason_value, last_vote,
    jsonb_build_object('weak_relationship',true,'workspace_schema','prop4you_user_workspace','no_single_vote_auto_global',true),
    jsonb_build_object('source','refresh_feedback_marker_aggregate','gateway_agnostic',true),
    p_actor_id
  ) on conflict (item_kind, item_ref, marker_kind) do update
    set assert_vote_count=excluded.assert_vote_count,
        dispute_vote_count=excluded.dispute_vote_count,
        confirm_vote_count=excluded.confirm_vote_count,
        distinct_user_count=excluded.distinct_user_count,
        distinct_workspace_count=excluded.distinct_workspace_count,
        net_score=excluded.net_score,
        recommendation=excluded.recommendation,
        recommendation_reason=excluded.recommendation_reason,
        last_vote_at=excluded.last_vote_at,
        updated_at=now(),
        last_modified_by_actor_id=p_actor_id
  returning * into aggregate_row;

  return aggregate_row;
end;
$$;

create or replace function prop4you_leadfinder_group.record_user_feedback_vote(
  p_user_ref text,
  p_workspace_ref text,
  p_item_kind text,
  p_item_ref text,
  p_marker_kind text,
  p_vote_value text default 'assert',
  p_vote_reason text default null,
  p_item_public_ref text default null,
  p_item_hash text default null,
  p_item_version text default null,
  p_actor_ref text default null,
  p_metadata jsonb default '{}'::jsonb
)
returns prop4you_leadfinder_group.feedback_marker_aggregates
language plpgsql
volatile
as $$
declare
  vote_key_value text;
  aggregate_row prop4you_leadfinder_group.feedback_marker_aggregates;
begin
  vote_key_value := 'lfg_feedback_vote:' || p_user_ref || ':' || coalesce(p_workspace_ref,'workspace_unknown') || ':' || p_item_kind || ':' || left(regexp_replace(p_item_ref,'[^a-zA-Z0-9]+','_','g'),64) || ':' || p_marker_kind;

  insert into prop4you_leadfinder_group.user_feedback_votes as v (
    feedback_key, user_ref, workspace_ref, actor_ref, item_kind, item_ref, item_public_ref, item_hash, item_version,
    marker_kind, vote_value, vote_reason, lineage, metadata, last_modified_by_actor_id
  ) values (
    vote_key_value, p_user_ref, p_workspace_ref, p_actor_ref, p_item_kind, p_item_ref, p_item_public_ref, p_item_hash, p_item_version,
    p_marker_kind, p_vote_value, p_vote_reason,
    jsonb_build_object('weak_relationship',true,'workspace_schema','prop4you_user_workspace','user_ref',p_user_ref,'workspace_ref',p_workspace_ref),
    jsonb_build_object('source','record_user_feedback_vote','no_auto_global_from_single_vote',true) || coalesce(p_metadata,'{}'::jsonb),
    p_actor_ref
  ) on conflict (feedback_key) do update
    set feedback_status='active',
        vote_value=excluded.vote_value,
        vote_reason=excluded.vote_reason,
        item_public_ref=excluded.item_public_ref,
        item_hash=excluded.item_hash,
        item_version=excluded.item_version,
        metadata=excluded.metadata,
        updated_at=now(),
        last_modified_by_actor_id=p_actor_ref;

  aggregate_row := prop4you_leadfinder_group.refresh_feedback_marker_aggregate(p_item_kind, p_item_ref, p_marker_kind, p_actor_ref);
  return aggregate_row;
end;
$$;

create or replace function prop4you_leadfinder_group.open_feedback_marker_review(
  p_aggregate_id uuid,
  p_reviewer_actor_id text default null,
  p_review_decision text default 'pending',
  p_metadata jsonb default '{}'::jsonb
)
returns prop4you_leadfinder_group.feedback_marker_reviews
language plpgsql
volatile
as $$
declare
  aggregate_row prop4you_leadfinder_group.feedback_marker_aggregates;
  review_row prop4you_leadfinder_group.feedback_marker_reviews;
begin
  select * into aggregate_row from prop4you_leadfinder_group.feedback_marker_aggregates where id=p_aggregate_id and deleted=false;
  if not found then raise exception 'feedback aggregate not found: %', p_aggregate_id using errcode='22023'; end if;

  insert into prop4you_leadfinder_group.feedback_marker_reviews as r (
    aggregate_id, review_key, review_status, review_decision, reviewer_actor_id, reviewed_at,
    review_payload, metadata
  ) values (
    aggregate_row.id,
    'lfg_feedback_review:' || replace(aggregate_row.id::text,'-',''),
    case when p_review_decision='pending' then 'in_review' else case when p_review_decision='accept_global_marker' then 'accepted' when p_review_decision='reject_global_marker' then 'rejected' else 'deferred' end end,
    p_review_decision,
    p_reviewer_actor_id,
    case when p_review_decision='pending' then null else now() end,
    jsonb_build_object('aggregate', to_jsonb(aggregate_row), 'weak_relationship', true, 'no_single_vote_auto_global', true),
    jsonb_build_object('source','open_feedback_marker_review','gateway_agnostic',true) || coalesce(p_metadata,'{}'::jsonb)
  ) on conflict (review_key) do update
    set review_status=excluded.review_status,
        review_decision=excluded.review_decision,
        reviewer_actor_id=excluded.reviewer_actor_id,
        reviewed_at=excluded.reviewed_at,
        review_payload=excluded.review_payload,
        metadata=excluded.metadata,
        updated_at=now()
  returning * into review_row;

  update prop4you_leadfinder_group.feedback_marker_aggregates
     set aggregate_status = case when review_row.review_status='accepted' then 'reviewed' else review_row.review_status end,
         reviewed_at = review_row.reviewed_at,
         reviewed_by_actor_id = p_reviewer_actor_id,
         updated_at=now()
   where id=aggregate_row.id;

  return review_row;
end;
$$;

create or replace function prop4you_leadfinder_group.apply_feedback_marker_review(
  p_review_id uuid,
  p_actor_id text default null,
  p_metadata jsonb default '{}'::jsonb
)
returns prop4you_leadfinder_group.global_item_markers
language plpgsql
volatile
as $$
declare
  review_row prop4you_leadfinder_group.feedback_marker_reviews;
  aggregate_row prop4you_leadfinder_group.feedback_marker_aggregates;
  marker_row prop4you_leadfinder_group.global_item_markers;
  marker_key_value text;
begin
  select * into review_row from prop4you_leadfinder_group.feedback_marker_reviews where id=p_review_id;
  if not found then raise exception 'feedback marker review not found: %', p_review_id using errcode='22023'; end if;
  if review_row.review_status <> 'accepted' or review_row.review_decision <> 'accept_global_marker' then
    raise exception 'review must be accepted for global marker apply: %', p_review_id using errcode='22023';
  end if;
  select * into aggregate_row from prop4you_leadfinder_group.feedback_marker_aggregates where id=review_row.aggregate_id;
  marker_key_value := 'lfg_global_marker:' || aggregate_row.item_kind || ':' || left(regexp_replace(aggregate_row.item_ref,'[^a-zA-Z0-9]+','_','g'),80) || ':' || aggregate_row.marker_kind;

  insert into prop4you_leadfinder_group.global_item_markers as m (
    marker_key, marker_status, item_kind, item_ref, item_public_ref, marker_kind,
    source_review_id, source_aggregate_id, confidence, marker_payload, lineage, metadata, applied_by_actor_id, last_modified_by_actor_id
  ) values (
    marker_key_value, review_row.accepted_marker_status, aggregate_row.item_kind, aggregate_row.item_ref, aggregate_row.item_public_ref, aggregate_row.marker_kind,
    review_row.id, aggregate_row.id, least(1.0, greatest(0.1, aggregate_row.net_score / 5.0)),
    jsonb_build_object('marker_kind',aggregate_row.marker_kind,'recommendation',aggregate_row.recommendation,'net_score',aggregate_row.net_score,'distinct_user_count',aggregate_row.distinct_user_count,'distinct_workspace_count',aggregate_row.distinct_workspace_count),
    aggregate_row.lineage || jsonb_build_object('review_id',review_row.id,'aggregate_id',aggregate_row.id,'weak_relationship',true),
    jsonb_build_object('source','apply_feedback_marker_review','review_gate',true,'no_single_vote_auto_global',true) || coalesce(p_metadata,'{}'::jsonb),
    p_actor_id, p_actor_id
  ) on conflict (item_kind, item_ref, marker_kind) do update
    set marker_status=excluded.marker_status,
        source_review_id=excluded.source_review_id,
        source_aggregate_id=excluded.source_aggregate_id,
        confidence=excluded.confidence,
        marker_payload=excluded.marker_payload,
        lineage=excluded.lineage,
        metadata=excluded.metadata,
        updated_at=now(),
        last_modified_by_actor_id=p_actor_id
  returning * into marker_row;

  update prop4you_leadfinder_group.feedback_marker_reviews set review_status='applied', updated_at=now() where id=review_row.id;
  update prop4you_leadfinder_group.feedback_marker_aggregates set aggregate_status='applied', updated_at=now() where id=aggregate_row.id;
  return marker_row;
end;
$$;

create or replace view prop4you_leadfinder_group.v_feedback_marker_review_queue as
select a.id as aggregate_id,
       a.public_ref as aggregate_public_ref,
       a.item_kind,
       a.item_ref,
       a.marker_kind,
       a.assert_vote_count,
       a.dispute_vote_count,
       a.confirm_vote_count,
       a.distinct_user_count,
       a.distinct_workspace_count,
       a.net_score,
       a.recommendation,
       a.recommendation_reason,
       a.aggregate_status,
       m.id as global_marker_id,
       m.marker_status as global_marker_status,
       a.updated_at
  from prop4you_leadfinder_group.feedback_marker_aggregates a
  left join prop4you_leadfinder_group.global_item_markers m on m.item_kind=a.item_kind and m.item_ref=a.item_ref and m.marker_kind=a.marker_kind and m.deleted=false
 where a.deleted=false;

comment on table prop4you_leadfinder_group.user_feedback_votes is 'Weak user/workspace feedback votes about LFG items such as phone/email/mailing_address. Votes do not directly mutate global truth.';
comment on table prop4you_leadfinder_group.feedback_marker_aggregates is 'Aggregated feedback marker signal used to recommend review/apply policy for global LFG markers.';
comment on table prop4you_leadfinder_group.feedback_marker_reviews is 'Human or authorized policy review gate for aggregated user feedback markers.';
comment on table prop4you_leadfinder_group.global_item_markers is 'LFG-owned global markers applied after feedback aggregate review, never directly from a single user vote.';
