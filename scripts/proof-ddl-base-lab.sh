#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
LAB_DB="${LAB_DB:-pg18_ddl_lab}"
SERVICE="${PG18_SERVICE:-postgres18_postgres}"
OUT_DIR="$ROOT_DIR/docs/reports"
TMP_DIR="$ROOT_DIR/.tmp/ddl-base-lab"
mkdir -p "$OUT_DIR" "$TMP_DIR"
REPORT="$OUT_DIR/pg18-ddl-base-lab-proof.md"
SQL_TEST="$TMP_DIR/functional-tests.sql"
SQL_EXT="$TMP_DIR/install-extensions.sql"

if ! docker service inspect "$SERVICE" >/dev/null 2>&1; then
  echo "ERROR: Docker service $SERVICE not found" >&2
  exit 1
fi

PGUSER_VALUE="$(docker service inspect "$SERVICE" --format '{{range .Spec.TaskTemplate.ContainerSpec.Env}}{{println .}}{{end}}' | awk -F= '$1=="POSTGRES_USER"{print $2; exit}')"
PGPASS_VALUE="$(docker service inspect "$SERVICE" --format '{{range .Spec.TaskTemplate.ContainerSpec.Env}}{{println .}}{{end}}' | awk -F= '$1=="POSTGRES_PASSWORD"{print $2; exit}')"
PGHOST_VALUE="${PGHOST_VALUE:-127.0.0.1}"
PGPORT_VALUE="${PGPORT_VALUE:-54318}"

if [[ -z "$PGUSER_VALUE" || -z "$PGPASS_VALUE" ]]; then
  echo "ERROR: could not read $SERVICE POSTGRES_USER/POSTGRES_PASSWORD from service env" >&2
  exit 1
fi

export PGHOST="$PGHOST_VALUE" PGPORT="$PGPORT_VALUE" PGUSER="$PGUSER_VALUE" PGPASSWORD="$PGPASS_VALUE" PGDATABASE=postgres

psql_base=(psql -v ON_ERROR_STOP=1 -X -q)

echo "== Create clean lab database: $LAB_DB =="
"${psql_base[@]}" <<SQL
select pg_terminate_backend(pid)
  from pg_stat_activity
 where datname = '$LAB_DB'
   and pid <> pg_backend_pid();
drop database if exists "$LAB_DB";
create database "$LAB_DB" owner "$PGUSER_VALUE";
SQL

cat > "$SQL_EXT" <<'SQL'
\set ON_ERROR_STOP on
create schema if not exists lab;
create table if not exists lab.extension_install_results (
  extension_name text primary key,
  target_schema text,
  status text not null,
  message text,
  installed_at timestamptz not null default now()
);
create or replace procedure lab.try_create_extension(p_extension text, p_schema text default null)
language plpgsql
as $$
declare
  sql text;
begin
  if p_schema is not null then
    execute format('create schema if not exists %I', p_schema);
    sql := format('create extension if not exists %I with schema %I', p_extension, p_schema);
  else
    sql := format('create extension if not exists %I', p_extension);
  end if;

  begin
    execute sql;
    insert into lab.extension_install_results(extension_name, target_schema, status, message)
    values (p_extension, p_schema, 'installed_or_present', null)
    on conflict (extension_name) do update
      set target_schema = excluded.target_schema,
          status = excluded.status,
          message = excluded.message,
          installed_at = now();
  exception when others then
    insert into lab.extension_install_results(extension_name, target_schema, status, message)
    values (p_extension, p_schema, 'skipped_or_failed', sqlstate || ': ' || sqlerrm)
    on conflict (extension_name) do update
      set target_schema = excluded.target_schema,
          status = excluded.status,
          message = excluded.message,
          installed_at = now();
  end;
end;
$$;

call lab.try_create_extension('pgcrypto', 'extensions');
call lab.try_create_extension('uuid-ossp', 'extensions');
call lab.try_create_extension('pg_stat_statements', 'extensions');
call lab.try_create_extension('pgaudit', 'public');
call lab.try_create_extension('pg_jsonschema', 'public');
call lab.try_create_extension('pgjwt', 'public');
call lab.try_create_extension('pgmq', 'pgmq');
call lab.try_create_extension('vector', 'public');
call lab.try_create_extension('pg_graphql', 'graphql');
call lab.try_create_extension('pg_net', 'public');
call lab.try_create_extension('pg_cron', 'public');
call lab.try_create_extension('supabase_vault', 'vault');
call lab.try_create_extension('http', 'public');
call lab.try_create_extension('hypopg', 'public');
call lab.try_create_extension('index_advisor', 'public');
call lab.try_create_extension('pg_partman', 'public');
call lab.try_create_extension('pg_repack', 'public');
call lab.try_create_extension('pgroonga', 'public');
call lab.try_create_extension('postgis', 'public');
call lab.try_create_extension('pgrouting', 'public');
call lab.try_create_extension('pgtap', 'public');
call lab.try_create_extension('plpgsql_check', 'public');
call lab.try_create_extension('rum', 'public');
call lab.try_create_extension('wal2json', 'public');
call lab.try_create_extension('wrappers', 'public');

select extension_name || '=' || status || coalesce(' [' || message || ']', '')
  from lab.extension_install_results
 order by extension_name;
SQL

export PGDATABASE="$LAB_DB"
echo "== Enable extensions in $LAB_DB =="
"${psql_base[@]}" -f "$SQL_EXT" | tee "$TMP_DIR/extensions.out"

echo "== Apply DDL base package =="
"$ROOT_DIR/scripts/apply-ddl-package.sh" --package "$ROOT_DIR/database/ddl/base" --apply | tee "$TMP_DIR/apply.out"

echo "== Reapply DDL base package (idempotence) =="
"$ROOT_DIR/scripts/apply-ddl-package.sh" --package "$ROOT_DIR/database/ddl/base" --apply | tee "$TMP_DIR/reapply.out"

cat > "$SQL_TEST" <<'SQL'
\set ON_ERROR_STOP on
\pset tuples_only on
\pset format unaligned

create schema if not exists lab;

create or replace function lab.assert_true(p_name text, p_ok boolean)
returns void
language plpgsql
as $$
begin
  if not coalesce(p_ok, false) then
    raise exception 'ASSERT FAILED: %', p_name;
  end if;
  raise notice 'PASS: %', p_name;
end;
$$;

select lab.assert_true('base schema exists', exists(select 1 from pg_namespace where nspname='base'));
select lab.assert_true('api schema exists', exists(select 1 from pg_namespace where nspname='api'));
select lab.assert_true('audit schema exists', exists(select 1 from pg_namespace where nspname='audit'));
select lab.assert_true('realtime schema exists', exists(select 1 from pg_namespace where nspname='realtime'));
select lab.assert_true('ddl migrations are 9 applied files', (select count(*) from base.ddl_migrations where package_name='base' and status='applied') = 9);

create table if not exists lab.sample_entity (
  id uuid primary key default uuidv7(),
  name text not null,
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz,
  updated_at timestamptz,
  active boolean,
  activated_at timestamptz,
  deactivated_at timestamptz,
  deleted boolean,
  deleted_at timestamptz,
  deleted_by_actor_id text,
  version integer,
  last_modified_by_actor_id text
);

drop trigger if exists sample_entity_set_lifecycle_defaults on lab.sample_entity;
create trigger sample_entity_set_lifecycle_defaults
before insert on lab.sample_entity
for each row execute function base.set_lifecycle_defaults();

drop trigger if exists sample_entity_touch_updated_at on lab.sample_entity;
create trigger sample_entity_touch_updated_at
before update on lab.sample_entity
for each row execute function base.touch_updated_at();

drop trigger if exists sample_entity_increment_version on lab.sample_entity;
create trigger sample_entity_increment_version
before update on lab.sample_entity
for each row execute function base.increment_version();

begin;
select base.set_local_context('actor-lab-1', 'tenant-lab-1', 'request-lab-1', 'lab-role');

insert into lab.sample_entity(name, metadata)
values ('Alpha Entity', '{"kind":"lab"}'::jsonb)
returning id \gset

select lab.assert_true('insert generated uuidv7', uuid_extract_version(:'id'::uuid) = 7);
select lab.assert_true('lifecycle defaults set', exists(
  select 1 from lab.sample_entity
   where id = :'id'::uuid and active is true and deleted is false and version = 1 and created_at is not null and updated_at is not null and activated_at is not null
));

update lab.sample_entity set name='Alpha Entity Updated' where id=:'id'::uuid;
select lab.assert_true('update increments version', (select version from lab.sample_entity where id=:'id'::uuid) = 2);

select (base.register_public_id_prefix('lab', 'lab', 'sample_entity', 'Lab Entity', 'id', true, '{"source":"ddl-lab"}'::jsonb)).prefix \gset
select lab.assert_true('registered public_id prefix', :'prefix' = 'lab');
select base.make_public_ref('lab', :'id'::uuid) as public_ref \gset
select lab.assert_true('public_ref keeps uuid suffix', split_part(:'public_ref', '_', 2)::uuid = :'id'::uuid);
select lab.assert_true('public_ref resolves target table', exists(
  select 1 from base.resolve_public_ref(:'public_ref')
   where schema_name='lab' and table_name='sample_entity' and object_id=:'id'::uuid and entity_name='Lab Entity'
));

select lab.assert_true('jsonb_is_object true for object', base.jsonb_is_object('{"ok":true}'::jsonb));
select lab.assert_true('jsonb dangerous string detected', base.jsonb_has_dangerous_string('{"x":"<script>alert(1)</script>"}'::jsonb));
select lab.assert_true('jsonb safe rejects script', not base.jsonb_is_safe('{"x":"javascript:alert(1)"}'::jsonb));
select lab.assert_true('jsonb max depth works', base.jsonb_max_depth('{"a":{"b":[1]}}'::jsonb) >= 4);

select lab.assert_true('email normalization', base.normalize_email('  USER@Example.COM ') = 'user@example.com');
select lab.assert_true('phone normalization', base.normalize_phone('(305) 555-1212') = '+13055551212');
select lab.assert_true('search terms normalize/dedupe', base.normalize_search_terms('Alpha alpha beta!') = array['alpha','beta']);

select audit.record_log(
  p_action := 'update',
  p_schema_name := 'lab',
  p_table_name := 'sample_entity',
  p_object_id := :'id',
  p_object_public_id := :'public_ref',
  p_description := 'DDL lab audit proof',
  p_changes := jsonb_build_object('name', jsonb_build_object('old','Alpha Entity','new','Alpha Entity Updated')),
  p_metadata := '{"proof":"ddl-base-lab"}'::jsonb
) as audit_id \gset
select lab.assert_true('audit row recorded', exists(select 1 from audit.log where id=:'audit_id'::uuid and object_public_id=:'public_ref'));

insert into realtime.event_outbox(topic, event_type, aggregate_schema, aggregate_table, aggregate_id, public_ref, payload, metadata)
values ('lab.sample_entity', 'updated', 'lab', 'sample_entity', :'id'::uuid, :'public_ref', '{"name":"Alpha Entity Updated"}'::jsonb, '{"proof":"ddl-base-lab"}'::jsonb)
returning id as event_id \gset
select realtime.ack_event(:'event_id'::uuid, 'ddl-lab-consumer', '{"ok":true}'::jsonb) as ack_id \gset
select lab.assert_true('realtime event recorded', exists(select 1 from realtime.event_outbox where id=:'event_id'::uuid and public_ref=:'public_ref'));
select lab.assert_true('realtime ack recorded', exists(select 1 from realtime.event_acks where id=:'ack_id'::uuid and consumer='ddl-lab-consumer'));

select lab.assert_true('api health returns ok', (api.health()->>'ok')::boolean is true);
select lab.assert_true('api current_context actor', api.current_context()->>'actor_id' = 'actor-lab-1');
select lab.assert_true('api ddl_status sees migrations', (select count(*) from api.ddl_status('base')) = 9);

select 'SUMMARY|schemas=' || (select count(*) from pg_namespace where nspname in ('base','api','audit','realtime'));
select 'SUMMARY|extensions_installed=' || (select count(*) from pg_extension);
select 'SUMMARY|ddl_migrations=' || (select count(*) from base.ddl_migrations where package_name='base');
select 'SUMMARY|public_ref=' || :'public_ref';
select 'SUMMARY|audit_id=' || :'audit_id';
select 'SUMMARY|event_id=' || :'event_id';
commit;
SQL

echo "== Run functional tests =="
"${psql_base[@]}" -f "$SQL_TEST" 2>&1 | tee "$TMP_DIR/functional-tests.out"

echo "== Capture final inventory =="
"${psql_base[@]}" -At -F $'\t' > "$TMP_DIR/final-schemas.tsv" <<'SQL'
with class_counts as (
  select n.oid,
         count(c.oid) filter (where c.relkind in ('r','p')) as tables,
         count(c.oid) filter (where c.relkind='v') as views,
         count(c.oid) filter (where c.relkind='S') as sequences
    from pg_namespace n
    left join pg_class c on c.relnamespace=n.oid
   group by n.oid
), proc_counts as (
  select n.oid, count(p.oid) as functions
    from pg_namespace n
    left join pg_proc p on p.pronamespace=n.oid
   group by n.oid
)
select n.nspname,
       pg_get_userbyid(n.nspowner) as owner,
       coalesce(c.tables,0) as tables,
       coalesce(c.views,0) as views,
       coalesce(c.sequences,0) as sequences,
       coalesce(p.functions,0) as functions
from pg_namespace n
left join class_counts c on c.oid=n.oid
left join proc_counts p on p.oid=n.oid
where n.nspname not like 'pg_toast%'
order by n.nspname;
SQL
"${psql_base[@]}" -At -F $'\t' > "$TMP_DIR/final-extensions.tsv" <<'SQL'
select e.extname, e.extversion, n.nspname
from pg_extension e join pg_namespace n on n.oid=e.extnamespace
order by e.extname;
SQL

cat > "$REPORT" <<EOF_REPORT
# PG18 DDL Base Lab Proof

Status: PASS
Database: $LAB_DB
Service: $SERVICE
Date: $(date -Iseconds)
Secrets: redacted/omitted

## What this proof did

1. Dropped and recreated a clean lab database named \`$LAB_DB\` on the live local Swarm PG18 service.
2. Enabled a broad set of available Supabase/Postgres extensions where possible, recording install/skipped status.
3. Applied \`database/ddl/base\` with \`scripts/apply-ddl-package.sh\`.
4. Reapplied the same package to prove idempotence.
5. Exercised functional behavior for public IDs, lifecycle triggers, JSONB guards, search normalization, audit log, realtime outbox/ack, and API facade.

## Extension install output

\`\`\`text
$(sed -E 's/(password|secret|token|key)=([^ ]+)/\1=[REDACTED]/ig' "$TMP_DIR/extensions.out")
\`\`\`

## DDL apply output

\`\`\`text
$(sed -E 's/(password|secret|token|key)=([^ ]+)/\1=[REDACTED]/ig' "$TMP_DIR/apply.out")
\`\`\`

## DDL reapply/idempotence output

\`\`\`text
$(sed -E 's/(password|secret|token|key)=([^ ]+)/\1=[REDACTED]/ig' "$TMP_DIR/reapply.out")
\`\`\`

## Functional tests output

\`\`\`text
$(sed -E 's/(password|secret|token|key)=([^ ]+)/\1=[REDACTED]/ig' "$TMP_DIR/functional-tests.out")
\`\`\`

## Final schemas

\`\`\`text
$(cat "$TMP_DIR/final-schemas.tsv")
\`\`\`

## Final extensions

\`\`\`text
$(cat "$TMP_DIR/final-extensions.tsv")
\`\`\`

## Verdict

The clean lab database successfully exercises the implemented base DDL substrate.

EOF_REPORT

echo "report=$REPORT"
echo "PASS ddl base lab proof database=$LAB_DB"
