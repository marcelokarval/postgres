# 14 — Next slice gate: projection candidate review from corpus base

Status: recommended next slice

## Next correct slice

Slice 17 — LFG projection candidate review board from prop4you-inertia corpus base.

## Goal

Use the enriched corpus base to create a review table/artifact of candidate JSON paths and decide, per the seven registry gates, whether each path remains JSONB or becomes a generated column, expression index, narrow table, PostGIS projection, or deferred review.

## Inputs

```text
docs/corpus/prop4you/lfg/prop4you-inertia-lfg-corpus-base.v1.jsonl
docs/corpus/prop4you/lfg/prop4you-inertia-lfg-corpus-base-summary.v1.json
docs/schemas/prop4you/lfg/projection-policy.v1.json
prop4you_leadfinder_group.v_active_projection_policy_gates
```

## Candidate groups

1. DirectSkip contact_satellites:
   - handoff envelope refs/stages/queue/versioning;
   - phone/email seed fields;
   - mailing address seed fields;
   - relationship evidence flags.

2. Realtor evidence:
   - provider refs/listing refs;
   - property physical facts;
   - valuation snapshots;
   - market/geography snapshots;
   - boundary geometry candidate.

3. REIQ property/legal signal:
   - provider record refs;
   - list/situation type;
   - state/county/property id;
   - filing/auction/legal dates;
   - normalized financial values.

4. Matrix/LeadFinder support:
   - baseline version;
   - contract/schema refs;
   - artifact role;
   - discrepancy/growth suggestions.

## Hard rule

Do not create broad property/owner/contact final tables yet. First persist candidate decisions and prove the seven gates for each selected path.
