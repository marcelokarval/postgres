#!/usr/bin/env bash
set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
LAB_DB="${LAB_DB:-pg18_prop4you_systemarea_autocomplete_lab}"
PGHOST="${PGHOST:-127.0.0.1}"
PGPORT="${PGPORT:-54318}"
PGUSER="${PGUSER:-supabase_admin}"
REPORT_PATH="$PROJECT_ROOT/docs/reports/prop4you-lfg-systemarea-autocomplete-geography-proof.md"

if [[ -z "${PGPASSWORD:-}" ]]; then
  echo "PGPASSWORD must be set for SystemArea autocomplete proof" >&2
  exit 2
fi

cd "$PROJECT_ROOT"
KEEP_DB=1 LAB_DB="$LAB_DB" scripts/proof-prop4you-ddl-lab.sh >/tmp/prop4you_systemarea_autocomplete_base_proof.log

psql -v ON_ERROR_STOP=1 -h "$PGHOST" -p "$PGPORT" -U "$PGUSER" -d "$LAB_DB" -q <<'SQL'
select prop4you_leadfinder_group.upsert_system_area_projection(
  p_slug_id := 'Florida',
  p_area_type := 'state',
  p_name := 'Florida',
  p_state_code := 'FL',
  p_provider_geo_id := 'state:fl',
  p_provider_area_ref := 'state:fl',
  p_center_lng := -81.5158,
  p_center_lat := 27.6648,
  p_bbox_west := -87.6349,
  p_bbox_south := 24.3963,
  p_bbox_east := -80.0314,
  p_bbox_north := 31.0009,
  p_registration_status := 'canonical',
  p_boundary_status := 'derived',
  p_lineage := '{"proof":"slice18","raw_values":false}'::jsonb
);
select prop4you_leadfinder_group.upsert_system_area_projection(
  p_slug_id := 'Orlando_FL',
  p_area_type := 'city',
  p_name := 'Orlando',
  p_state_code := 'FL',
  p_provider_geo_id := 'city:fl_orlando',
  p_provider_area_ref := 'city:fl_orlando',
  p_realty_id := 'city:fl_orlando',
  p_center_lng := -81.3792,
  p_center_lat := 28.5383,
  p_bbox_west := -81.6,
  p_bbox_south := 28.35,
  p_bbox_east := -81.2,
  p_bbox_north := 28.7,
  p_registration_status := 'created',
  p_boundary_status := 'derived',
  p_lineage := '{"proof":"slice18","source":"legacy_systemarea_autocomplete","raw_values":false}'::jsonb
);
select prop4you_leadfinder_group.upsert_system_area_projection(
  p_slug_id := 'Orange_County_FL',
  p_area_type := 'county',
  p_name := 'Orange',
  p_state_code := 'FL',
  p_provider_geo_id := 'county:fl_orange',
  p_provider_area_ref := 'county:fl_orange',
  p_center_lng := -81.2519,
  p_center_lat := 28.4845,
  p_bbox_west := -81.66,
  p_bbox_south := 28.35,
  p_bbox_east := -80.86,
  p_bbox_north := 28.88,
  p_registration_status := 'already_installed',
  p_boundary_status := 'derived',
  p_lineage := '{"proof":"slice18","raw_values":false}'::jsonb
);
select prop4you_leadfinder_group.upsert_system_area_projection(
  p_slug_id := '32801_FL',
  p_area_type := 'postal_code',
  p_name := '32801',
  p_state_code := 'FL',
  p_provider_geo_id := 'postal_code:fl_32801',
  p_provider_area_ref := 'postal_code:fl_32801',
  p_center_lng := -81.3789,
  p_center_lat := 28.5410,
  p_bbox_west := -81.40,
  p_bbox_south := 28.52,
  p_bbox_east := -81.36,
  p_bbox_north := 28.56,
  p_registration_status := 'projected',
  p_boundary_status := 'derived',
  p_lineage := '{"proof":"slice18","raw_values":false}'::jsonb
);

insert into prop4you_leadfinder_group.system_area_feed_terms (
  term, normalized_term, expected_area_type, state_code, provider_slug, feed_status, provider_call_made, result_count, created_count, already_installed_count, lineage
) values (
  'Orlando FL', 'orlando fl', 'city', 'FL', 'realtor', 'completed', false, 1, 1, 0, '{"proof":"slice18","provider_call_made":false,"raw_values":false}'::jsonb
) on conflict do nothing;

insert into prop4you_leadfinder_group.system_area_feed_results (
  feed_term_id, system_area_id, provider_slug, provider_area_ref, provider_geo_id, provider_slug_id, area_type, name, state_code, rank, match_score, result_status, materialization_reason, lineage
)
select t.id, a.id, 'realtor', a.provider_area_ref, a.provider_geo_id, a.slug_id, a.area_type, a.name, a.state_code, 1, 1.0, 'materialized', 'proof normalized city match', '{"proof":"slice18","raw_values":false}'::jsonb
from prop4you_leadfinder_group.system_area_feed_terms t
join prop4you_leadfinder_group.system_areas a on a.slug_id = 'Orlando_FL'
where t.normalized_term = 'orlando fl'
on conflict do nothing;
SQL

validation_json="$(
psql -v ON_ERROR_STOP=1 -h "$PGHOST" -p "$PGPORT" -U "$PGUSER" -d "$LAB_DB" -At <<'SQL'
with autocomplete as (
  select jsonb_agg(to_jsonb(x) order by x.label) as rows, count(*) as row_count
  from prop4you_leadfinder_group.search_system_area_autocomplete('Orl', null, null, 20) x
), counts as (
  select
    (select count(*) from prop4you_leadfinder_group.system_areas) as system_area_count,
    (select count(*) from prop4you_leadfinder_group.system_area_provider_identities) as provider_identity_count,
    (select count(*) from prop4you_leadfinder_group.system_area_aliases) as alias_count,
    (select count(*) from prop4you_leadfinder_group.system_area_feed_terms) as feed_term_count,
    (select count(*) from prop4you_leadfinder_group.system_area_feed_results) as feed_result_count,
    (select count(*) from prop4you_leadfinder_group.system_areas where centroid is not null) as centroid_count,
    (select count(*) from prop4you_leadfinder_group.system_areas where bbox is not null) as bbox_count,
    (select count(*) from prop4you_leadfinder_group.search_system_area_autocomplete('Orl', null, null, 20)) as autocomplete_orl_count,
    (select count(*) from prop4you_leadfinder_group.search_system_area_autocomplete('328', array['postal_code'], 'FL', 20)) as autocomplete_zip_count,
    (select count(*) from prop4you_leadfinder_group.search_system_area_autocomplete('Florida', array['state'], null, 20)) as autocomplete_state_count,
    (select count(*) from prop4you_leadfinder_group.v_system_area_projection_gate_status where systemarea_projection_present) as projected_gate_candidate_count,
    (select count(*) from prop4you_leadfinder_group.v_approved_projection_candidates) as approved_candidate_count,
    (select row_count from autocomplete) as autocomplete_rows_json_count,
    (select rows from autocomplete) as autocomplete_rows
)
select jsonb_pretty(to_jsonb(counts)) from counts;
SQL
)"

python3 - <<PY
import json
j=json.loads('''$validation_json''')
assert j['system_area_count'] == 4, j
assert j['provider_identity_count'] == 4, j
assert j['alias_count'] == 4, j
assert j['feed_term_count'] == 1, j
assert j['feed_result_count'] == 1, j
assert j['centroid_count'] == 4, j
assert j['bbox_count'] == 4, j
assert j['autocomplete_orl_count'] >= 1, j
assert j['autocomplete_zip_count'] >= 1, j
assert j['autocomplete_state_count'] >= 1, j
assert j['projected_gate_candidate_count'] >= 15, j
assert j['approved_candidate_count'] == 0, j
rows=j['autocomplete_rows'] or []
assert any(r.get('type') == 'city' and r.get('systemAreaId') == r.get('value') for r in rows), rows
assert any(isinstance(r.get('center'), list) and len(r['center']) == 2 for r in rows), rows
assert any(isinstance(r.get('bbox'), list) and len(r['bbox']) == 4 for r in rows), rows
print('systemarea_autocomplete_assertions_ok')
PY

cat > "$REPORT_PATH" <<EOF_REPORT
# Prop4You LFG SystemArea autocomplete geography proof

Status: PASS

## Lab DB

~~~text
$LAB_DB
~~~

## Validation JSON

~~~json
$validation_json
~~~

## Assertions

~~~text
system_area_count = 4
provider_identity_count = 4
alias_count = 4
feed_term_count = 1
feed_result_count = 1
centroid_count = 4
bbox_count = 4
autocomplete_orl_count >= 1
autocomplete_zip_count >= 1
autocomplete_state_count >= 1
projected_gate_candidate_count >= 15
approved_candidate_count = 0
autocomplete rows use value == systemAreaId
autocomplete center is [lng, lat]
autocomplete bbox is [west, south, east, north]
~~~

## Guardrails

~~~text
no provider calls
no raw provider payload values
real geography projection DDL
no property/owner/workspace table explosion
~~~
EOF_REPORT

psql -v ON_ERROR_STOP=1 -h "$PGHOST" -p "$PGPORT" -U "$PGUSER" -d postgres -At <<SQL >/dev/null
select pg_terminate_backend(pid)
from pg_stat_activity
where datname = '$LAB_DB' and pid <> pg_backend_pid();
SQL
dropdb --if-exists -h "$PGHOST" -p "$PGPORT" -U "$PGUSER" "$LAB_DB"

echo "prop4you_lfg_systemarea_autocomplete_geography_proof_ok"
