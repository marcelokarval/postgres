# 07 — Final Report: LFG canonical JSONSchema envelope registry

Status: completed / PG18 proof pass / browser-proof pass
Generated: 2026-06-18T16:33:27

## Direct answer

Before this slice:

```text
Rules were documented in docs + skill references, but not sufficiently automatic/queryable inside the repo/runtime contract.
```

After this slice:

```text
Rules are now documented, versioned as repo JSON artifacts, seeded into a PG18 queryable registry, and referenced by the database-centric skill.
```

## Main deliverables

```text
docs/schemas/prop4you/lfg/property-envelope.v1.schema.json
docs/schemas/prop4you/lfg/owner-envelope.v1.schema.json
docs/schemas/prop4you/lfg/contact-satellites-envelope.v1.schema.json
docs/schemas/prop4you/lfg/realtor-evidence-envelope.v1.schema.json
docs/schemas/prop4you/lfg/taxonomy-envelope.v1.schema.json
docs/schemas/prop4you/lfg/lfg-canonical-envelope-index.v1.schema.json
docs/schemas/prop4you/lfg/projection-policy.v1.json
database/ddl/projects/prop4you/leadfinder_group/0005_canonical_jsonschema_registry.sql
scripts/proof-prop4you-lfg-jsonschema-registry.sh
docs/reports/prop4you-lfg-jsonschema-registry-proof.md
```

## PG18 proof result

```json
{"gate_count": 7, "policy_count": 1, "envelope_count": 6, "auto_apply_users": 3, "raw_policy_count": 6, "required_gate_count": 7, "auto_apply_workspaces": 2, "top_level_closed_count": 6, "expected_envelopes_present": 6}
```

## What is automatically accessible now

Through files:

```text
docs/schemas/prop4you/lfg/*.schema.json
docs/schemas/prop4you/lfg/projection-policy.v1.json
```

Through PG18 registry:

```text
prop4you_leadfinder_group.canonical_jsonschema_envelopes
prop4you_leadfinder_group.projection_policies
prop4you_leadfinder_group.v_active_canonical_jsonschema_envelopes
prop4you_leadfinder_group.v_active_projection_policy_gates
```

Through skill:

```text
database-centric-app-modeling -> references/prop4you-lfg-jsonschema-envelope-registry.md
```

## Seven promotion gates now queryable

```text
representative_corpus_observed
matrix_leadfinder_semantic_approval
stable_or_intentionally_provider_specific
query_join_filter_sort_unique_fk_rls_postgis_or_constraint_need
safe_cast_or_coercion_exists
durable_lineage_to_raw_json
privacy_pii_classified
```

## Auto-apply default preserved

```text
marker_risk_class = low
min_distinct_users = 3
min_distinct_workspaces = 2
no_active_disputes = true
audit_event_required = true
```

## Non-goals preserved

```text
no final property/owner/contact tables
no workspace tables
no provider calls
no raw JSON values or PII
no public API/RLS yet
no final tag-group seed
```

## Correct next slice

```text
Slice 16 — LFG projection candidates and first generated-column/table decision set
```

Goal: use the registry to decide the first tiny set of projections that may become generated columns, indexes, PostGIS extraction, or narrow tables — without broad graph table explosion.


## Browser proof

```text
liveness: PASS
console_errors: 0
vision_qa: PASS
```
