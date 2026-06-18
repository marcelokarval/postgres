# 13 — Next-slice gate: LFG canonical JSONSchema envelope minimum

Status: recommended next slice

## Why this gate exists

The previous readiness audit said LFG is ready-with-gaps. This JSON curation slice adds that the next step should not be a table-heavy graph implementation yet. The immediate next step should define canonical JSONSchema envelopes and promotion rules.

## Required next outputs

1. `property` canonical JSONSchema envelope.
2. `owner` canonical JSONSchema envelope.
3. `contact_satellites` canonical JSONSchema envelope, informed by DirectSkip.
4. `valuation` / `market` / `comparable_evidence` envelopes, informed by Realtor.
5. `taxonomy/tag/label` vocabulary envelope, without final tag-group seed yet.
6. Projection policy: which envelope paths may become generated columns/tables now.
7. Auto-apply marker policy default:

```text
marker_risk_class = low
min_distinct_users = 3
min_distinct_workspaces = 2
no_active_disputes = true
audit_event_required = true
```

## Non-goals

- no rich workspace tables;
- no provider calls;
- no production deploy;
- no raw JSON values in docs;
- no tag group final design;
- no public API/RLS until envelopes stabilize.
