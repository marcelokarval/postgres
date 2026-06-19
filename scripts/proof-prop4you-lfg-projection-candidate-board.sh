#!/usr/bin/env bash
set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
LAB_DB="${LAB_DB:-pg18_prop4you_projection_candidate_board_lab}"
PGHOST="${PGHOST:-127.0.0.1}"
PGPORT="${PGPORT:-54318}"
PGUSER="${PGUSER:-postgres}"
REPORT_PATH="$PROJECT_ROOT/docs/reports/prop4you-lfg-projection-candidate-board-proof.md"

if [[ -z "${PGPASSWORD:-}" ]]; then
  echo "PGPASSWORD must be set for projection candidate board proof" >&2
  exit 2
fi

cd "$PROJECT_ROOT"

KEEP_DB=1 LAB_DB="$LAB_DB" scripts/proof-prop4you-ddl-lab.sh >/tmp/prop4you_projection_candidate_board_base_proof.log

validation_json="$(
PGPASSWORD="$PGPASSWORD" psql -v ON_ERROR_STOP=1 -h "$PGHOST" -p "$PGPORT" -U "$PGUSER" -d "$LAB_DB" -At <<'SQL'
with counts as (
  select
    (select count(*) from prop4you_leadfinder_group.projection_candidate_groups) as group_count,
    (select count(*) from prop4you_leadfinder_group.projection_candidates) as candidate_count,
    (select count(*) from prop4you_leadfinder_group.projection_candidate_gate_evaluations) as gate_eval_count,
    (select count(*) from prop4you_leadfinder_group.projection_candidate_reviews) as review_count,
    (select count(*) from prop4you_leadfinder_group.v_active_projection_candidates) as active_candidate_count,
    (select count(*) from prop4you_leadfinder_group.v_approved_projection_candidates) as approved_candidate_count,
    (select count(*) from prop4you_leadfinder_group.v_projection_candidate_next_action_queue) as next_action_count,
    (select count(*) from prop4you_leadfinder_group.projection_candidate_groups where group_key='directskip_skip_trace_unified_contact_evidence') as directskip_group_count,
    (select count(*) from prop4you_leadfinder_group.projection_candidates c join prop4you_leadfinder_group.projection_candidate_groups g on g.id=c.group_id where g.group_key='directskip_skip_trace_unified_contact_evidence') as directskip_candidate_count,
    (select count(*) from prop4you_leadfinder_group.projection_candidate_groups where lane_key='geography_first') as geography_group_count,
    (select min(sequence_number) from prop4you_leadfinder_group.projection_candidate_groups where lane_key='geography_first') as first_geography_sequence,
    (select count(*) from prop4you_leadfinder_group.projection_candidates where projection_shape='postgis_geometry') as postgis_candidate_count,
    (select count(*) from prop4you_leadfinder_group.projection_candidates where projection_shape='join_table') as join_table_candidate_count,
    (select count(*) from prop4you_leadfinder_group.projection_candidates where projection_shape='edge_table') as edge_table_candidate_count,
    (select count(*) from prop4you_leadfinder_group.projection_candidate_gate_evaluations where gate_status='passed') as passed_gate_count,
    (select count(*) from prop4you_leadfinder_group.projection_candidates c where not exists (select 1 from prop4you_leadfinder_group.projection_candidate_gate_evaluations e where e.candidate_id=c.id)) as candidates_without_gates
)
select jsonb_pretty(to_jsonb(counts)) from counts;
SQL
)"

python3 - <<PY
import json
j=json.loads('''$validation_json''')
assert j['group_count'] == 9, j
assert j['candidate_count'] == 53, j
assert j['gate_eval_count'] == 53 * 7, j
assert j['review_count'] == 53, j
assert j['active_candidate_count'] == 53, j
assert j['approved_candidate_count'] == 0, j
assert j['next_action_count'] == 53, j
assert j['directskip_group_count'] == 1, j
assert j['directskip_candidate_count'] >= 14, j
assert j['geography_group_count'] == 3, j
assert j['first_geography_sequence'] == 10, j
assert j['postgis_candidate_count'] >= 3, j
assert j['join_table_candidate_count'] >= 3, j
assert j['edge_table_candidate_count'] >= 2, j
assert j['passed_gate_count'] == 0, j
assert j['candidates_without_gates'] == 0, j
print('projection_candidate_board_assertions_ok')
PY

cat > "$REPORT_PATH" <<EOF_REPORT
# Prop4You LFG projection candidate board proof

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
group_count = 9
candidate_count = 53
gate_eval_count = 371
review_count = 53
approved_candidate_count = 0
next_action_count = 53
directskip_group_count = 1
directskip_candidate_count >= 14
geography_group_count = 3
first_geography_sequence = 10
postgis_candidate_count >= 3
join_table_candidate_count >= 3
edge_table_candidate_count >= 2
passed_gate_count = 0
candidates_without_gates = 0
~~~

## Guardrails

~~~text
no provider calls
no raw payload values
no final projection tables
review-board only
~~~
EOF_REPORT

PGPASSWORD="$PGPASSWORD" psql -v ON_ERROR_STOP=1 -h "$PGHOST" -p "$PGPORT" -U "$PGUSER" -d postgres -At <<SQL >/dev/null
select pg_terminate_backend(pid)
from pg_stat_activity
where datname = '$LAB_DB' and pid <> pg_backend_pid();
SQL
PGPASSWORD="$PGPASSWORD" dropdb --if-exists -h "$PGHOST" -p "$PGPORT" -U "$PGUSER" "$LAB_DB"

echo "prop4you_lfg_projection_candidate_board_proof_ok"
