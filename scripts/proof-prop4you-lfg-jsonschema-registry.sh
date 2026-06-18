#!/usr/bin/env bash
set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
LAB_DB="${LAB_DB:-pg18_prop4you_jsonschema_registry_lab}"
PGHOST="${PGHOST:-127.0.0.1}"
PGPORT="${PGPORT:-54318}"
PGUSER="${PGUSER:-supabase_admin}"
ADMIN_DB="${ADMIN_DB:-postgres}"
KEEP_DB="${KEEP_DB:-0}"
REPORT_PATH="$PROJECT_ROOT/docs/reports/prop4you-lfg-jsonschema-registry-proof.md"
SCHEMA_DIR="$PROJECT_ROOT/docs/schemas/prop4you/lfg"

python3 - <<'PY'
from pathlib import Path
import json, sys
root = Path('docs/schemas/prop4you/lfg')
required = [
  'property-envelope.v1.schema.json',
  'owner-envelope.v1.schema.json',
  'contact-satellites-envelope.v1.schema.json',
  'realtor-evidence-envelope.v1.schema.json',
  'taxonomy-envelope.v1.schema.json',
  'lfg-canonical-envelope-index.v1.schema.json',
  'projection-policy.v1.json',
]
errors=[]
for name in required:
    p=root/name
    if not p.exists():
        errors.append(f'missing:{name}')
        continue
    doc=json.loads(p.read_text())
    if name.endswith('.schema.json'):
        for key in ['$schema','$id','title','type','additionalProperties']:
            if key not in doc:
                errors.append(f'{name}:missing:{key}')
        if doc.get('type') != 'object':
            errors.append(f'{name}:type_not_object')
    else:
        gates=doc.get('promotion_gates') or []
        if len(gates) < 7:
            errors.append('projection-policy:missing_7_gates')
        marker=doc.get('low_risk_marker_auto_apply_default') or {}
        if marker.get('min_distinct_users') != 3 or marker.get('min_distinct_workspaces') != 2:
            errors.append('projection-policy:auto_apply_default_mismatch')
if errors:
    print('\n'.join(errors), file=sys.stderr)
    sys.exit(1)
print('jsonschema_static_validation_ok')
PY

KEEP_DB=1 LAB_DB="$LAB_DB" PGHOST="$PGHOST" PGPORT="$PGPORT" PGUSER="$PGUSER" ADMIN_DB="$ADMIN_DB" "$PROJECT_ROOT/scripts/proof-prop4you-ddl-lab.sh" >/tmp/prop4you-lfg-jsonschema-registry-base-proof.out

psql_lab=(psql -h "$PGHOST" -p "$PGPORT" -U "$PGUSER" -d "$LAB_DB" -v ON_ERROR_STOP=1 -q)
psql_admin=(psql -h "$PGHOST" -p "$PGPORT" -U "$PGUSER" -d "$ADMIN_DB" -v ON_ERROR_STOP=1 -q)

validation_json="$("${psql_lab[@]}" -At <<'SQL'
select jsonb_build_object(
  'envelope_count', (select count(*) from prop4you_leadfinder_group.canonical_jsonschema_envelopes where active and envelope_status='active'),
  'policy_count', (select count(*) from prop4you_leadfinder_group.projection_policies where active and policy_status='active'),
  'gate_count', (select count(*) from prop4you_leadfinder_group.v_active_projection_policy_gates),
  'required_gate_count', (select count(*) from prop4you_leadfinder_group.v_active_projection_policy_gates where required),
  'expected_envelopes_present', (select count(*) from prop4you_leadfinder_group.canonical_jsonschema_envelopes where envelope_key in ('property-envelope','owner-envelope','contact-satellites-envelope','realtor-evidence-envelope','taxonomy-envelope','lfg-canonical-envelope-index')),
  'raw_policy_count', (select count(*) from prop4you_leadfinder_group.canonical_jsonschema_envelopes where raw_value_policy='no_raw_payload_values'),
  'top_level_closed_count', (select count(*) from prop4you_leadfinder_group.canonical_jsonschema_envelopes where json_schema->>'additionalProperties' = 'false'),
  'auto_apply_users', (select (policy_doc #>> '{low_risk_marker_auto_apply_default,min_distinct_users}')::int from prop4you_leadfinder_group.projection_policies where policy_key='lfg_projection_policy.v1' limit 1),
  'auto_apply_workspaces', (select (policy_doc #>> '{low_risk_marker_auto_apply_default,min_distinct_workspaces}')::int from prop4you_leadfinder_group.projection_policies where policy_key='lfg_projection_policy.v1' limit 1)
)::text;
SQL
)"

VALIDATION_JSON="$validation_json" python3 - <<'PY'
import json, os, sys
p=json.loads(os.environ['VALIDATION_JSON'])
errors=[]
if p.get('envelope_count') != 6: errors.append(f"envelope_count={p.get('envelope_count')}")
if p.get('policy_count') != 1: errors.append(f"policy_count={p.get('policy_count')}")
if p.get('gate_count') != 7: errors.append(f"gate_count={p.get('gate_count')}")
if p.get('required_gate_count') != 7: errors.append(f"required_gate_count={p.get('required_gate_count')}")
if p.get('expected_envelopes_present') != 6: errors.append(f"expected_envelopes_present={p.get('expected_envelopes_present')}")
if p.get('raw_policy_count') != 6: errors.append(f"raw_policy_count={p.get('raw_policy_count')}")
if p.get('top_level_closed_count') != 6: errors.append(f"top_level_closed_count={p.get('top_level_closed_count')}")
if p.get('auto_apply_users') != 3: errors.append(f"auto_apply_users={p.get('auto_apply_users')}")
if p.get('auto_apply_workspaces') != 2: errors.append(f"auto_apply_workspaces={p.get('auto_apply_workspaces')}")
if errors:
    print('registry_validation_failed: ' + '; '.join(errors), file=sys.stderr)
    sys.exit(1)
print('registry_validation_ok')
PY

mkdir -p "$(dirname "$REPORT_PATH")"
cat > "$REPORT_PATH" <<REPORT
# Prop4You LFG JSONSchema Registry Proof

Status: PASS
LAB_DB: $LAB_DB
PGHOST: $PGHOST
PGPORT: $PGPORT

## Scope

Validated repo-local JSONSchema artifacts, projection policy, DDL apply, and queryable registry rows.

No provider calls were made.
No raw payload values or PII were emitted.
No final property/owner/contact/workspace tables were created.

## Validation JSON

~~~json
$validation_json
~~~

## Artifacts

- docs/schemas/prop4you/lfg/*.schema.json
- docs/schemas/prop4you/lfg/projection-policy.v1.json
- database/ddl/projects/prop4you/leadfinder_group/0005_canonical_jsonschema_registry.sql
REPORT

if [[ "$KEEP_DB" != "1" ]]; then
  "${psql_admin[@]}" <<SQL
select pg_terminate_backend(pid)
from pg_stat_activity
where datname = '${LAB_DB}' and pid <> pg_backend_pid();
drop database if exists ${LAB_DB};
SQL
fi

echo "prop4you_lfg_jsonschema_registry_proof_ok"
echo "$REPORT_PATH"
