# Detection and Analysis — LFG feedback votes + promotion policy

Status: active
Created: 2026-06-18T11:29:29
Reviewer: Thor/default

## User decisions

```text
workspace schema: prop4you_user_workspace
LFG/system schema: prop4you_leadfinder_group
feedback: table in prop4you_leadfinder_group with weak relationships to item/user/workspace
policy: aggregate user votes; support automatic canonical/global marker recommendations and human review
Thor/agent HTTP endpoint: roadmap future only, not implemented in this slice
```

## Scope

Implementation slice for database-centric PG18 contracts:

- declare/record `prop4you_user_workspace` boundary;
- implement LFG feedback votes/review/global marker gate;
- implement LeadFinder dictionary promotion review/apply gate from prepared proposals;
- prove in clean PG18 lab DB;
- browser-proof static QA.

## Non-goals

- no production deploy;
- no real user PII;
- no provider calls;
- no Thor HTTP endpoint implementation;
- no full workspace app tables;
- no final product graph explosion.
