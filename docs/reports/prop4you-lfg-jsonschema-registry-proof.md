# Prop4You LFG JSONSchema Registry Proof

Status: PASS
LAB_DB: pg18_prop4you_jsonschema_registry_lab
PGHOST: 127.0.0.1
PGPORT: 54318

## Scope

Validated repo-local JSONSchema artifacts, projection policy, DDL apply, and queryable registry rows.

No provider calls were made.
No raw payload values or PII were emitted.
No final property/owner/contact/workspace tables were created.

## Validation JSON

~~~json
{"gate_count": 7, "policy_count": 1, "envelope_count": 6, "auto_apply_users": 3, "raw_policy_count": 6, "required_gate_count": 7, "auto_apply_workspaces": 2, "top_level_closed_count": 6, "expected_envelopes_present": 6}
~~~

## Artifacts

- docs/schemas/prop4you/lfg/*.schema.json
- docs/schemas/prop4you/lfg/projection-policy.v1.json
- database/ddl/projects/prop4you/leadfinder_group/0005_canonical_jsonschema_registry.sql
