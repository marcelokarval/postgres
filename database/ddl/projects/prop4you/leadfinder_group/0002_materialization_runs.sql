-- package: prop4you/leadfinder_group
-- file: 0002_materialization_runs.sql
-- status: experimental / non-final
-- purpose: T5.1 reviewable LFG materialization runs/results from staging candidates.
-- depends-on: leadfinder_group/0001_staging_candidates.sql
-- idempotency: idempotent
-- destructive: false
-- [GATEWAY_AGNOSTIC] Callable by direct SQL, ORM, PostgREST RPC, Django/FastAPI passthrough, workers, or any other transport.
-- [REVIEW_GATE] Materialization runs/results are a gate between staging and operational tables.
-- [NO_PROVIDER_CALLS] No HTTP/provider calls, no corpus reads, no secrets.
-- [NO_RAW_PAYLOAD_DUMP] Results store compact operational candidate JSON/summaries, not raw provider payload dumps.
-- [NO_FINAL_PRODUCT_TABLE_EXPLOSION] Does not create the final LFG product graph/list/detail/scoring model.

create schema if not exists prop4you_leadfinder_group;

create table if not exists prop4you_leadfinder_group.materialization_runs (
  id uuid primary key default uuidv7(),
  public_ref text generated always as (base.make_public_ref('p4ylfgr', id)) stored,
  run_key text not null,
  run_status text not null default 'draft',
  run_gate_status text not null default 'not_started',
  run_kind text not null default 'staging_to_operational_minimum',
  staging_scope text not null default 'sourcehub_translated_dto_publications',
  leadfinder_dictionary_version_id uuid references prop4you_leadfinder.canonical_dictionary_versions(id) on delete restrict,
  matrix_artifact_id uuid references prop4you_matrix.transformation_artifacts(id) on delete restrict,
  provider_id uuid references prop4you_provider.providers(id) on delete restrict,
  payload_class_id uuid references prop4you_provider.payload_classes(id) on delete restrict,
  input_candidate_count integer not null default 0,
  result_count integer not null default 0,
  passed_count integer not null default 0,
  blocked_count integer not null default 0,
  failed_count integer not null default 0,
  materialization_plan jsonb not null default '{}'::jsonb,
  quality_summary jsonb not null default '{}'::jsonb,
  redaction_summary jsonb not null default '{}'::jsonb,
  metadata jsonb not null default '{}'::jsonb,
  started_at timestamptz,
  finished_at timestamptz,
  reviewed_at timestamptz,
  reviewed_by_actor_id text,
  approved_at timestamptz,
  approved_by_actor_id text,
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
  constraint materialization_runs_public_ref_key unique (public_ref),
  constraint materialization_runs_run_key_key unique (run_key),
  constraint materialization_runs_run_key_format_chk check (run_key ~ '^[a-z][a-z0-9_.:-]{1,191}$'),
  constraint materialization_runs_status_chk check (run_status in ('draft','running','completed','completed_with_blocks','failed','cancelled','superseded','archived')),
  constraint materialization_runs_gate_chk check (run_gate_status in ('not_started','ready_for_review','passed','blocked','not_applicable')),
  constraint materialization_runs_kind_chk check (run_kind in ('staging_to_operational_minimum','dry_run','replay','regression_check','unknown')),
  constraint materialization_runs_counts_chk check (input_candidate_count >= 0 and result_count >= 0 and passed_count >= 0 and blocked_count >= 0 and failed_count >= 0),
  constraint materialization_runs_passed_gate_chk check (run_gate_status <> 'passed' or (run_status in ('completed','completed_with_blocks') and failed_count = 0)),
  constraint materialization_runs_time_chk check (finished_at is null or started_at is null or finished_at >= started_at),
  constraint materialization_runs_json_chk check (jsonb_typeof(materialization_plan)='object' and jsonb_typeof(quality_summary)='object' and jsonb_typeof(redaction_summary)='object' and jsonb_typeof(metadata)='object'),
  constraint materialization_runs_version_positive_chk check (version > 0)
);

create table if not exists prop4you_leadfinder_group.materialization_results (
  id uuid primary key default uuidv7(),
  public_ref text generated always as (base.make_public_ref('p4ylfgx', id)) stored,
  materialization_run_id uuid not null references prop4you_leadfinder_group.materialization_runs(id) on delete restrict,
  staging_candidate_id uuid not null references prop4you_leadfinder_group.staging_candidates(id) on delete restrict,
  source_publication_id uuid not null references prop4you_sourcehub.translated_dto_publications(id) on delete restrict,
  result_key text not null,
  result_status text not null default 'passed',
  result_gate_status text not null default 'ready_for_review',
  result_kind text not null default 'operational_minimum_candidate',
  operational_payload jsonb not null default '{}'::jsonb,
  result_summary jsonb not null default '{}'::jsonb,
  quality_summary jsonb not null default '{}'::jsonb,
  lineage_summary jsonb not null default '{}'::jsonb,
  redaction_summary jsonb not null default '{}'::jsonb,
  metadata jsonb not null default '{}'::jsonb,
  result_sha256 text,
  processed_at timestamptz not null default now(),
  processed_by_actor_id text,
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
  constraint materialization_results_public_ref_key unique (public_ref),
  constraint materialization_results_run_candidate_key unique (materialization_run_id, staging_candidate_id),
  constraint materialization_results_result_key_key unique (result_key),
  constraint materialization_results_result_key_format_chk check (result_key ~ '^[a-z][a-z0-9_.:-]{1,191}$'),
  constraint materialization_results_status_chk check (result_status in ('passed','blocked','failed','skipped','superseded','archived')),
  constraint materialization_results_gate_chk check (result_gate_status in ('ready_for_review','passed','blocked','not_applicable')),
  constraint materialization_results_kind_chk check (result_kind in ('operational_minimum_candidate','dry_run_candidate','regression_result','unknown')),
  constraint materialization_results_hash_chk check (result_sha256 is null or result_sha256 ~ '^[0-9a-f]{64}$'),
  constraint materialization_results_json_chk check (jsonb_typeof(operational_payload)='object' and jsonb_typeof(result_summary)='object' and jsonb_typeof(quality_summary)='object' and jsonb_typeof(lineage_summary)='object' and jsonb_typeof(redaction_summary)='object' and jsonb_typeof(metadata)='object'),
  constraint materialization_results_version_positive_chk check (version > 0)
);

create index if not exists materialization_runs_status_idx on prop4you_leadfinder_group.materialization_runs (run_status, run_gate_status, created_at desc) where deleted=false;
create index if not exists materialization_results_status_idx on prop4you_leadfinder_group.materialization_results (materialization_run_id, result_status, result_gate_status) where deleted=false;
create index if not exists materialization_results_candidate_idx on prop4you_leadfinder_group.materialization_results (staging_candidate_id) where deleted=false;
create index if not exists materialization_results_lineage_gin_idx on prop4you_leadfinder_group.materialization_results using gin (lineage_summary jsonb_path_ops);

comment on table prop4you_leadfinder_group.materialization_runs is 'T5.1 LFG materialization execution/review gate from staging candidates to operational minimum candidates.';
comment on table prop4you_leadfinder_group.materialization_results is 'One T5.1 materialization result per staging candidate, before operational minimum rows are promoted.';

drop trigger if exists materialization_runs_set_lifecycle_defaults on prop4you_leadfinder_group.materialization_runs;
create trigger materialization_runs_set_lifecycle_defaults before insert on prop4you_leadfinder_group.materialization_runs for each row execute function base.set_lifecycle_defaults();
drop trigger if exists materialization_runs_touch_updated_at on prop4you_leadfinder_group.materialization_runs;
create trigger materialization_runs_touch_updated_at before update on prop4you_leadfinder_group.materialization_runs for each row execute function base.touch_updated_at();
drop trigger if exists materialization_runs_increment_version on prop4you_leadfinder_group.materialization_runs;
create trigger materialization_runs_increment_version before update on prop4you_leadfinder_group.materialization_runs for each row execute function base.increment_version();

drop trigger if exists materialization_results_set_lifecycle_defaults on prop4you_leadfinder_group.materialization_results;
create trigger materialization_results_set_lifecycle_defaults before insert on prop4you_leadfinder_group.materialization_results for each row execute function base.set_lifecycle_defaults();
drop trigger if exists materialization_results_touch_updated_at on prop4you_leadfinder_group.materialization_results;
create trigger materialization_results_touch_updated_at before update on prop4you_leadfinder_group.materialization_results for each row execute function base.touch_updated_at();
drop trigger if exists materialization_results_increment_version on prop4you_leadfinder_group.materialization_results;
create trigger materialization_results_increment_version before update on prop4you_leadfinder_group.materialization_results for each row execute function base.increment_version();

create or replace view prop4you_leadfinder_group.v_materialization_result_review as
select mr.id,
       mr.public_ref,
       run.public_ref as run_public_ref,
       run.run_key,
       mr.result_key,
       mr.result_status,
       mr.result_gate_status,
       sc.public_ref as staging_candidate_public_ref,
       sc.candidate_key,
       mr.source_publication_id,
       mr.result_sha256,
       mr.result_summary,
       mr.quality_summary,
       mr.lineage_summary,
       mr.created_at,
       mr.updated_at
  from prop4you_leadfinder_group.materialization_results mr
  join prop4you_leadfinder_group.materialization_runs run on run.id = mr.materialization_run_id
  join prop4you_leadfinder_group.staging_candidates sc on sc.id = mr.staging_candidate_id
 where mr.deleted=false;

create or replace function prop4you_leadfinder_group.materialize_staging_candidates(
  p_run_key text,
  p_limit integer default 10,
  p_actor_id text default null,
  p_metadata jsonb default '{}'::jsonb
)
returns prop4you_leadfinder_group.materialization_runs
language plpgsql
volatile
as $$
declare
  run_row prop4you_leadfinder_group.materialization_runs;
  candidate_row prop4you_leadfinder_group.staging_candidates;
  payload jsonb;
  result_key_value text;
  result_count_value integer := 0;
  effective_limit integer;
begin
  if p_run_key is null or p_run_key !~ '^[a-z][a-z0-9_.:-]{1,191}$' then
    raise exception 'invalid run_key: %', p_run_key using errcode='22023';
  end if;
  effective_limit := greatest(1, least(coalesce(p_limit, 10), 1000));

  insert into prop4you_leadfinder_group.materialization_runs as run (
    run_key, run_status, run_gate_status, run_kind,
    materialization_plan, metadata, started_at, last_modified_by_actor_id
  ) values (
    p_run_key, 'running', 'not_started', 'staging_to_operational_minimum',
    jsonb_build_object('source','staging_candidates','target','operational_minimum','limit',effective_limit,'no_provider_calls',true,'no_raw_payload_dump',true),
    jsonb_build_object('source','prop4you_leadfinder_group.materialize_staging_candidates','gateway_agnostic',true) || coalesce(p_metadata,'{}'::jsonb),
    now(), p_actor_id
  ) on conflict (run_key) do update
    set run_status='running', run_gate_status='not_started', started_at=now(), finished_at=null, metadata=excluded.metadata, updated_at=now(), last_modified_by_actor_id=p_actor_id
  returning * into run_row;

  for candidate_row in
    select * from prop4you_leadfinder_group.staging_candidates sc
     where sc.deleted=false and sc.active=true
       and sc.candidate_status in ('ready_for_materialization','staged')
       and sc.candidate_gate_status in ('ready_for_review','passed')
     order by sc.created_at, sc.id
     limit effective_limit
  loop
    payload := jsonb_build_object(
      'contract','leadfinder_group.materialization_result.v0',
      'staging_candidate_id', candidate_row.id,
      'source_publication_id', candidate_row.source_publication_id,
      'candidate_facts', candidate_row.candidate_facts,
      'operational_intent', jsonb_build_object('group','candidate','event','group_materialized','facets','minimum'),
      'lineage', candidate_row.lineage_summary,
      'no_provider_calls', true,
      'raw_payload_not_copied', true
    );
    result_key_value := 'lfg_result:' || replace(run_row.id::text,'-','') || ':' || left(replace(candidate_row.id::text,'-',''),24);

    insert into prop4you_leadfinder_group.materialization_results as res (
      materialization_run_id, staging_candidate_id, source_publication_id,
      result_key, result_status, result_gate_status, result_kind,
      operational_payload, result_summary, quality_summary, lineage_summary, redaction_summary, metadata,
      result_sha256, processed_by_actor_id, last_modified_by_actor_id
    ) values (
      run_row.id, candidate_row.id, candidate_row.source_publication_id,
      result_key_value, 'passed', 'passed', 'operational_minimum_candidate',
      payload,
      jsonb_build_object('lfg_materialization_run','T5_1','operational_minimum_ready',true,'value_policy','values_stored_not_printed_in_proofs'),
      candidate_row.quality_summary,
      candidate_row.lineage_summary || jsonb_build_object('materialization_run_id',run_row.id,'materialization_result_id',null),
      candidate_row.redaction_summary,
      jsonb_build_object('source','prop4you_leadfinder_group.materialize_staging_candidates','gateway_agnostic',true,'no_provider_calls',true) || coalesce(p_metadata,'{}'::jsonb),
      encode(digest(payload::text,'sha256'),'hex'), p_actor_id, p_actor_id
    ) on conflict (materialization_run_id, staging_candidate_id) do update
      set result_status=excluded.result_status,
          result_gate_status=excluded.result_gate_status,
          operational_payload=excluded.operational_payload,
          result_summary=excluded.result_summary,
          quality_summary=excluded.quality_summary,
          lineage_summary=excluded.lineage_summary,
          redaction_summary=excluded.redaction_summary,
          metadata=excluded.metadata,
          result_sha256=excluded.result_sha256,
          updated_at=now(),
          last_modified_by_actor_id=p_actor_id;

    update prop4you_leadfinder_group.staging_candidates
       set candidate_status='materialized', updated_at=now(), last_modified_by_actor_id=p_actor_id
     where id = candidate_row.id;

    result_count_value := result_count_value + 1;
  end loop;

  update prop4you_leadfinder_group.materialization_runs
     set run_status='completed',
         run_gate_status='passed',
         input_candidate_count=result_count_value,
         result_count=result_count_value,
         passed_count=result_count_value,
         blocked_count=0,
         failed_count=0,
         finished_at=now(),
         quality_summary=jsonb_build_object('result_count',result_count_value,'passed_count',result_count_value,'no_provider_calls',true),
         redaction_summary=jsonb_build_object('proof_policy','counts_hashes_only_no_raw_or_dto_scalar_dumps'),
         updated_at=now(),
         last_modified_by_actor_id=p_actor_id
   where id=run_row.id
   returning * into run_row;

  return run_row;
end;
$$;

comment on function prop4you_leadfinder_group.materialize_staging_candidates(text,integer,text,jsonb) is
'T5.1 gateway-agnostic materialization gate from LFG staging candidates to materialization_results. Does not create final product graph; use operational minimum function later.';
