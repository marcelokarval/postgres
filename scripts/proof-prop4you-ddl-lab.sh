#!/usr/bin/env bash
set -euo pipefail

# Prop4You DDL lab proof.
# Applies base DDL + current experimental Prop4You package into a clean lab DB.
# Does not call providers and does not create raw/fake/redacted payload fixtures.

LAB_DB="${LAB_DB:-pg18_prop4you_ddl_lab}"
PGHOST="${PGHOST:-127.0.0.1}"
PGPORT="${PGPORT:-54318}"
PGUSER="${PGUSER:-supabase_admin}"
ADMIN_DB="${ADMIN_DB:-postgres}"
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BASE_DDL_DIR="$PROJECT_ROOT/database/ddl/base"
P4Y_DDL_DIR="$PROJECT_ROOT/database/ddl/projects/prop4you"
REPORT_PATH="$PROJECT_ROOT/docs/reports/prop4you-sourcehub-matrix-ddl-lab-proof.md"
DRY_RUN="${DRY_RUN:-0}"
KEEP_DB="${KEEP_DB:-0}"

usage() {
  cat <<USAGE
Usage: LAB_DB=pg18_prop4you_ddl_lab scripts/proof-prop4you-ddl-lab.sh

Environment:
  PGHOST     default 127.0.0.1
  PGPORT     default 54318
  PGUSER     default supabase_admin
  PGPASSWORD required unless pgpass/env already handles auth
  LAB_DB     default pg18_prop4you_ddl_lab
  DRY_RUN    1 prints apply order and exits without DB mutation
  KEEP_DB    1 preserves lab DB after success for manual inspection

Scope:
  - drops/recreates only LAB_DB;
  - applies database/ddl/base/*.sql;
  - applies current Prop4You experimental DDL;
  - validates provider/sourcehub/matrix objects and comments;
  - writes docs/reports/prop4you-sourcehub-matrix-ddl-lab-proof.md.
USAGE
}

if [[ "${1:-}" == "--help" ]]; then
  usage
  exit 0
fi

mapfile -t base_files < <(find "$BASE_DDL_DIR" -maxdepth 1 -type f -name '*.sql' | sort)
apply_files=(
  "${base_files[@]}"
  "$P4Y_DDL_DIR/0001_schemas.sql"
  "$P4Y_DDL_DIR/providers/0001_provider_registry.sql"
  "$P4Y_DDL_DIR/sourcehub/0001_sourcehub_corpus.sql"
  "$P4Y_DDL_DIR/matrix/0001_semantic_dictionary.sql"
)

for f in "${apply_files[@]}"; do
  if [[ ! -f "$f" ]]; then
    echo "missing required DDL file: $f" >&2
    exit 1
  fi
done

if [[ "$DRY_RUN" == "1" ]]; then
  echo "prop4you_ddl_lab_dry_run_ok"
  printf '%s\n' "${apply_files[@]}"
  exit 0
fi

if [[ -z "${PGPASSWORD:-}" ]]; then
  echo "PGPASSWORD must be set for lab proof" >&2
  exit 2
fi

psql_admin=(psql -h "$PGHOST" -p "$PGPORT" -U "$PGUSER" -d "$ADMIN_DB" -v ON_ERROR_STOP=1 -q)
psql_lab=(psql -h "$PGHOST" -p "$PGPORT" -U "$PGUSER" -d "$LAB_DB" -v ON_ERROR_STOP=1 -q)

"${psql_admin[@]}" <<SQL
select pg_terminate_backend(pid)
from pg_stat_activity
where datname = '${LAB_DB}' and pid <> pg_backend_pid();
drop database if exists ${LAB_DB};
create database ${LAB_DB};
SQL

for f in "${apply_files[@]}"; do
  echo "applying $(realpath --relative-to="$PROJECT_ROOT" "$f")"
  "${psql_lab[@]}" -f "$f"
done

validation_sql=$(cat <<'SQL'
with expected_schemas(schema_name) as (
  values ('prop4you_provider'), ('prop4you_sourcehub'), ('prop4you_matrix')
), expected_tables(schema_name, table_name) as (
  values
    ('prop4you_provider','providers'),
    ('prop4you_provider','payload_classes'),
    ('prop4you_provider','provider_payload_classes'),
    ('prop4you_sourcehub','raw_records'),
    ('prop4you_sourcehub','corpus_samples'),
    ('prop4you_sourcehub','source_lineage_edges'),
    ('prop4you_sourcehub','enrichment_requests'),
    ('prop4you_matrix','canonical_families'),
    ('prop4you_matrix','canonical_fields'),
    ('prop4you_matrix','mapping_versions'),
    ('prop4you_matrix','provider_path_mappings'),
    ('prop4you_matrix','mapping_reviews')
), missing_schemas as (
  select schema_name from expected_schemas e
  where not exists (select 1 from information_schema.schemata s where s.schema_name=e.schema_name)
), missing_tables as (
  select schema_name || '.' || table_name as table_name from expected_tables e
  where not exists (
    select 1 from information_schema.tables t
    where t.table_schema=e.schema_name and t.table_name=e.table_name
  )
), uncommented_tables as (
  select e.schema_name || '.' || e.table_name as table_name
  from expected_tables e
  join pg_class c on c.relname=e.table_name
  join pg_namespace n on n.oid=c.relnamespace and n.nspname=e.schema_name
  where obj_description(c.oid, 'pg_class') is null
), counts as (
  select
    (select count(*) from prop4you_provider.providers) as provider_count,
    (select count(*) from prop4you_provider.payload_classes) as payload_class_count,
    (select count(*) from prop4you_matrix.canonical_families) as canonical_family_count,
    (select count(*) from prop4you_matrix.mapping_versions) as mapping_version_count
)
select jsonb_build_object(
  'missing_schemas', coalesce((select jsonb_agg(schema_name) from missing_schemas), '[]'::jsonb),
  'missing_tables', coalesce((select jsonb_agg(table_name) from missing_tables), '[]'::jsonb),
  'uncommented_tables', coalesce((select jsonb_agg(table_name) from uncommented_tables), '[]'::jsonb),
  'counts', (select to_jsonb(counts) from counts),
  'jsonb_path_type_smoke', prop4you_provider.jsonb_path_type('{"data":{"result":{"beds":3}}}'::jsonb, array['data','result','beds']),
  'jsonb_leaf_paths_smoke_count', (select count(*) from prop4you_provider.jsonb_leaf_paths('{"data":{"result":{"beds":3,"tags":["a"]}}}'::jsonb, 6))
)::text;
SQL
)
validation_json="$("${psql_lab[@]}" -Atc "$validation_sql")"

VALIDATION_JSON="$validation_json" python3 - <<'PY'
import json, os, sys
payload = json.loads(os.environ['VALIDATION_JSON'])
errors = []
for key in ['missing_schemas', 'missing_tables', 'uncommented_tables']:
    if payload.get(key) != []:
        errors.append(f'{key}={payload.get(key)!r}')
if payload.get('jsonb_path_type_smoke') != 'number':
    errors.append(f"jsonb_path_type_smoke={payload.get('jsonb_path_type_smoke')!r}")
if int(payload.get('jsonb_leaf_paths_smoke_count') or 0) < 2:
    errors.append(f"jsonb_leaf_paths_smoke_count={payload.get('jsonb_leaf_paths_smoke_count')!r}")
counts = payload.get('counts') or {}
for key in ['provider_count', 'payload_class_count', 'canonical_family_count', 'mapping_version_count']:
    if int(counts.get(key) or 0) <= 0:
        errors.append(f'{key}={counts.get(key)!r}')
if errors:
    print('validation_failed: ' + '; '.join(errors), file=sys.stderr)
    sys.exit(1)
PY

mkdir -p "$(dirname "$REPORT_PATH")"
cat > "$REPORT_PATH" <<REPORT
# Prop4You SourceHub + Matrix DDL Lab Proof

Status: PASS
LAB_DB: $LAB_DB
PGHOST: $PGHOST
PGPORT: $PGPORT

## Scope

Applied base DDL and experimental Prop4You provider/sourcehub/matrix DDL into a clean lab DB.

No provider calls were made.
No raw/fake/redacted fixtures were created.

## Apply order

$(printf -- '- `%s`\n' "${apply_files[@]#$PROJECT_ROOT/}")

## Validation JSON

\`\`\`json
$validation_json
\`\`\`

## Boundary

This proves DDL apply/comment/object smoke for experimental SourceHub + Matrix corpus gate only.
It does not prove final Prop4You property/owner tables, provider runtime calls, production deployment, or LeadFinder materialization.
REPORT

if [[ "$KEEP_DB" != "1" ]]; then
  "${psql_admin[@]}" <<SQL
select pg_terminate_backend(pid)
from pg_stat_activity
where datname = '${LAB_DB}' and pid <> pg_backend_pid();
drop database if exists ${LAB_DB};
SQL
fi

echo "prop4you_ddl_lab_proof_ok"
echo "$REPORT_PATH"
