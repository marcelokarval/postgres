# Architecture — LFG feedback votes and dictionary promotion apply policy

Status: implemented / lab-proven
Generated: 2026-06-18T11:46:09

## Canonical names

```text
user workspace schema: prop4you_user_workspace
LFG/system schema: prop4you_leadfinder_group
LeadFinder dictionary schema: prop4you_leadfinder
```

## Contract

User feedback is a weak signal stored inside `prop4you_leadfinder_group`, not a direct mutation of global truth.

```text
prop4you_user_workspace
  -> emits feedback with weak refs
  -> user/workspace/account/snapshot/campaign refs remain textual/non-FK in this slice

prop4you_leadfinder_group.user_feedback_votes
  -> records votes like dnc, wrong, invalid, stale, corrected, verified
  -> item kinds include phone, email, mailing_address, owner, property, contact, group, facet

prop4you_leadfinder_group.feedback_marker_aggregates
  -> aggregates votes by item_kind + item_ref + marker_kind
  -> computes recommendation: insufficient_signal, human_review_candidate, auto_apply_candidate, reject_candidate, conflict_review

prop4you_leadfinder_group.feedback_marker_reviews
  -> review gate
  -> accepted review can be applied

prop4you_leadfinder_group.global_item_markers
  -> LFG-owned global marker after review/apply
```

## Dictionary promotion policy

Existing prepare-only proposals now have a review/apply gate:

```text
prop4you_leadfinder.dictionary_promotion_preparations
  -> prop4you_leadfinder.dictionary_promotion_reviews
    -> prop4you_leadfinder.dictionary_promotion_applications
      -> canonical_families / canonical_fields links
```

Rules:

- prepared proposals do not auto-mutate dictionary rows;
- user/workspace feedback cannot bypass dictionary review;
- apply is idempotent by review;
- apply creates/links canonical family/field rows only after accepted review.

## Thor HTTP endpoint roadmap

The database-to-Thor/agent HTTP endpoint remains roadmap-only.

Not implemented in this slice:

```text
pg_net call to Thor
cron calling Thor
trigger calling Thor
agent endpoint auth/secret storage
provider calls
```

Future ADR must cover:

- auth and allowlist;
- idempotency key;
- request/response audit;
- rate limits;
- secret isolation;
- no hot user transaction waiting on agent latency;
- replay safety;
- human review for critical mutations.

## Lab proof counts

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
