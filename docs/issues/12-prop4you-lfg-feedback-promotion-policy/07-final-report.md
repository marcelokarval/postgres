# Final Report — Slice 12 LFG feedback votes and promotion policy

Status: completed / browser-proof pass / PG18 proof pass
Generated: 2026-06-18T11:46:09

## Executive summary

Implemented the next recommended slice after system/LFG topology:

```text
Slice 12 — LFG feedback votes + marker review/apply + LeadFinder dictionary promotion review/apply
```

The key decision is now enforced by DDL and proof:

```text
A user/workspace vote is signal.
Aggregate is recommendation.
Review is authority.
Apply creates global marker or dictionary mutation.
```

## Delivered objects

### Workspace boundary

```text
database/ddl/projects/prop4you/0001_schemas.sql
database/ddl/projects/prop4you/user_workspace/README.md
```

Canonical workspace schema:

```text
prop4you_user_workspace
```

### LFG feedback markers

```text
database/ddl/projects/prop4you/leadfinder_group/0004_user_feedback_markers.sql
```

Creates:

```text
prop4you_leadfinder_group.user_feedback_votes
prop4you_leadfinder_group.feedback_marker_aggregates
prop4you_leadfinder_group.feedback_marker_reviews
prop4you_leadfinder_group.global_item_markers
prop4you_leadfinder_group.v_feedback_marker_review_queue
```

Functions:

```text
record_user_feedback_vote(...)
refresh_feedback_marker_aggregate(...)
open_feedback_marker_review(...)
apply_feedback_marker_review(...)
```

### Dictionary promotion apply gate

```text
database/ddl/projects/prop4you/leadfinder/0004_dictionary_promotion_review_apply.sql
```

Creates:

```text
prop4you_leadfinder.dictionary_promotion_reviews
prop4you_leadfinder.dictionary_promotion_applications
prop4you_leadfinder.v_dictionary_promotion_apply_review
```

Functions:

```text
review_dictionary_promotion(...)
apply_dictionary_promotion_review(...)
```

## PG18 lab proof

Proof result:

```json
{
  "aggregate_recommendations": [
    "auto_apply_candidate"
  ],
  "canonical_family_count": 15,
  "canonical_field_count": 37,
  "dictionary_promotion_application_count": 1,
  "dictionary_promotion_review_count": 1,
  "feedback_aggregate_count": 1,
  "feedback_review_count": 1,
  "feedback_vote_count": 2,
  "global_marker_count": 1,
  "global_marker_statuses": [
    "asserted"
  ],
  "no_provider_calls": true,
  "no_thor_http_endpoint_created": true,
  "operational_group_count": 10,
  "prepared_promotion_count": 10,
  "weak_relationships": true,
  "workspace_schema_exists": 1
}
```

Acceptance highlights:

```text
workspace_schema_exists = 1
feedback_vote_count = 2
feedback_aggregate_count = 1
aggregate_recommendations = [auto_apply_candidate]
feedback_review_count = 1
global_marker_count = 1
global_marker_statuses = [asserted]
dictionary_promotion_review_count = 1
dictionary_promotion_application_count = 1
prepared_promotion_count = 10
operational_group_count = 10
no_provider_calls = true
no_thor_http_endpoint_created = true
weak_relationships = true
```

## Thor HTTP endpoint roadmap

Recorded as future discussion only. No endpoint, pg_net call, trigger, cron, or secret was implemented.

## Requested vs delivered

| Requested | Delivered |
| --- | --- |
| proceed to next recommended slices | Implemented feedback/promotion policy slice |
| workspace schema name `prop4you_user_workspace` | Added schema/comment + README boundary |
| LFG schema `prop4you_leadfinder_group` | Feedback marker system implemented there |
| feedback table with weak item/user relationships | `user_feedback_votes` with weak refs and no strong workspace FK |
| voting/policies/human review | aggregate/review/apply flow implemented |
| dictionary promotion apply gate | review/application tables and functions implemented |
| Thor endpoint as roadmap future | documented non-goal; no endpoint created |
| PRD/tasks/reviews/final/browser proof | PRD/tasks/reviews/final persisted; browser proof follows |

## Non-goals preserved

- no production deploy;
- no real PII;
- no provider calls;
- no Thor HTTP endpoint;
- no full workspace tables;
- no final graph/table explosion;
- no user feedback auto-mutating global canonical truth.

## Next steps

1. Slice 13 — `prop4you_user_workspace` snapshot contract:
   - selected LFG refs;
   - snapshot hash/version;
   - refresh decision;
   - local notes/tags/markers separated from LFG global markers.

2. Slice 14 — LFG feedback anti-abuse and reviewer workflow:
   - vote credibility;
   - tenant/user throttling;
   - conflict review;
   - reviewer queues.

3. Slice 15 — Thor/agent HTTP ADR only:
   - auth;
   - idempotency;
   - safe payload schema;
   - cron/outbox policy;
   - no hot transaction blocking.

## Questions for next step

- Should workspace snapshots store only `lfg_group_id/public_ref + dto_hash`, or also a compact redacted DTO envelope?
- Should local user tags be completely independent tables, or share marker vocabulary with LFG while keeping owner scope separate?
- Should global marker application require human actor always, or allow auto-apply after N trusted users/workspaces for low-risk markers?


## Browser proof

```text
url: http://127.0.0.1:8776/08-browser-render.html
liveness: PASS
console_errors: 0
vision_qa: PASS
```
