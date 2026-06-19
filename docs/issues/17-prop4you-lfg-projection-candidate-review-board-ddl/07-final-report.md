# 07 — Final Report: LFG projection candidate review board DDL

Status: completed / browser-proof PASS / pending commit at generation
Generated: 2026-06-19T14:58:17

## User decisions applied

```text
1. Go to DDL now.
2. DirectSkip phone/email, mailing address, and relationship evidence stay together.
3. Realtor/REIQ are separated semantically; geography starts first, then downstream sequences.
```

## Delivered DDL

```text
database/ddl/projects/prop4you/leadfinder_group/0006_projection_candidate_review_board.sql
```

## DDL objects

Tables:

```text
prop4you_leadfinder_group.projection_candidate_groups
prop4you_leadfinder_group.projection_candidates
prop4you_leadfinder_group.projection_candidate_gate_evaluations
prop4you_leadfinder_group.projection_candidate_reviews
```

Views:

```text
prop4you_leadfinder_group.v_projection_candidate_gate_status
prop4you_leadfinder_group.v_active_projection_candidates
prop4you_leadfinder_group.v_approved_projection_candidates
prop4you_leadfinder_group.v_projection_candidate_next_action_queue
```

## Seeded semantic groups

```text
directskip_skip_trace_unified_contact_evidence
realtor_geography_boundary_evidence
realtor_geography_autocomplete_match_evidence
reiq_property_geography_signal_evidence
realtor_market_geography_snapshot_evidence
property_valuation_evidence_realtor_reiq
property_physical_listing_evidence_realtor_reiq
reiq_property_legal_tax_signal_evidence
lfg_taxonomy_projection_semantic_support
```

## Proof result

```json
{
    "group_count": 9,
    "review_count": 53,
    "candidate_count": 53,
    "gate_eval_count": 371,
    "next_action_count": 53,
    "passed_gate_count": 0,
    "geography_group_count": 3,
    "active_candidate_count": 53,
    "directskip_group_count": 1,
    "postgis_candidate_count": 3,
    "approved_candidate_count": 0,
    "candidates_without_gates": 0,
    "first_geography_sequence": 10,
    "directskip_candidate_count": 14,
    "edge_table_candidate_count": 2,
    "join_table_candidate_count": 5
}
```

## Important semantics

DirectSkip:

```text
Unified group, 14 candidates.
Phone/email + mailing address + relationship evidence share provider/list/raw record/schema/mapping/confidence/lineage gates.
Future physical projections may be separate, but review/gate decision is unified.
```

Geography-first:

```text
3 geography groups start first:
  sequence 10: realtor boundary/geography
  sequence 20: realtor autocomplete/match geography
  sequence 30: REIQ property geography

Then downstream:
  110: market
  210: valuation
  310: property facts
  410: legal/tax situation
  900: taxonomy/support
```

## Guardrails

```text
no provider calls
no raw payload values
no final projection tables yet
review-board only
0 approved candidates at seed time
all 53 candidates have 7 gate rows
```

## Correct next slice

Slice 18 should evaluate and approve/block the first geography candidates through the seven gates, then decide whether to implement the first real projection as PostGIS geometry, expression index, generated column, or keep-jsonb.


## Browser proof

```text
liveness: PASS
console_errors: 0
vision_qa: PASS
```
