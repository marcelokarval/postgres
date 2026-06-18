# 07 — Final Report: LFG system x DDL x JSON readiness

Status: completed / browser-proof pass / repo-only audit pass
Generated: 2026-06-18T13:17:52

## Executive verdict

```text
LFG current state: ready-with-gaps
LFG closed/final: no
Proceed to rich prop4you_user_workspace: no
Correct next slice: LFG canonical graph/taxonomy minimum from system x DDL x JSON gaps
```

## Why

The existing PG18 work proves a strong database-centric pipeline:

```text
SourceHub raw/DTO
  -> Matrix extraction/quality/mapping
    -> LeadFinder dictionary/gaps/promotions
      -> LFG staging/materialization/operational minimum
        -> feedback votes/global marker gate
```

But the legacy system and JSON audit show that the final LFG domain still needs explicit graph/taxonomy closure before workspace is safe.

## Evidence produced

```text
08-legacy-system-inventory.md
09-current-ddl-inventory.md
10-json-path-inventory.md
11-system-ddl-json-readiness-matrix.md
```

## Legacy system findings

Legacy Django `system`/real_estate includes:

```text
property/location/address/details
owner/ownership/party roles/representatives/relationships
owner contact address
owner phones with DNC/wrong/dead-line/callability
owner emails with bounce/sendability
property situations/events/history/valuation
system property/list/situation taxonomy
workspace tags/lists/saved property/status registries
public LF projections with masking/entitlement
skiptrace/sourcehub raw/results/cache
```

## DDL findings

Current PG18 DDL has:

```text
6 schemas
37 tables
12 views
25 functions
43 triggers
```

It covers pipeline/gates but not final graph:

```text
covered: SourceHub, Matrix, LeadFinder dictionary, DTO, LFG staging/materialization/minimum, feedback markers
missing final: property, owner, contact, taxonomy, tags/labels groups, workspace, API/RLS, retention/load ops
```

## JSON findings

Corpus path inventory:

```text
97 JSON files
97 parsed successfully
0 parse errors
3,685 unique path+type pairs
1 raw source payload file with 51 top-level keys
```

Key family evidence:

```text
property address/city/state/zip
owner/mortgagor names
owner mailing address
legal/filing identifiers
property physical attributes
financial/loan/equity values
lead_type/list/source context
Matrix baseline/contextual/contracts/source_manifest artifacts
```

No values/PII were printed.

## User decisions incorporated

```text
snapshot storage question: deferred until graph readiness
LFG tag/label vocabulary should be reusable by user workspace later
user-created tags should join groups/contexts in future
low-risk global markers should auto-apply after threshold of multiple users/workspaces
```

## Requested vs delivered

| Requested | Delivered |
| --- | --- |
| Do not assume LFG closed | Verdict says LFG is not closed/final |
| Check system x DDL x JSON | Consolidated matrix persisted |
| Use loop engineering/orchestrator | PRD/tasks/ledger/subagents/review/final persisted |
| Use max 3 subagents | Used exactly 3 bounded workers |
| No unnecessary MCP/browser | Workers used file+terminal only |
| No raw JSON/PII | JSON inventory lists keys/paths/counts only |
| Browser-proof + vision | Pending in this file; completed in final chat after QA |
| Mark tasks delivered | Will mark after browser + commit |

## Correct next slice

```text
Slice 14 — LFG canonical graph/taxonomy minimum
```

Scope recommendation:

```text
1. property/address/details minimum
2. owner/ownership minimum
3. mailing/contact address minimum
4. phone/email satellite contract skeleton or DirectSkip-gated deferral
5. system taxonomy/tag/label vocabulary reusable by users
6. tag/label group/context model seed, including REISift-style “start” concept as future-compatible vocabulary
7. auto-apply policy table for low-risk global markers by multi-user/workspace threshold
```

Non-goals for next slice:

```text
no full workspace product tables
no UI
no provider calls
no production deploy
no raw payload dumps
```

## Questions to answer in/after next slice

1. Which graph tables must become first-class now versus remain facets?
2. Should phone/email final tables wait for DirectSkip corpus, or be created as contract skeletons?
3. What threshold/risk classes should auto-apply global markers use?
4. Should tag groups be global LFG-owned only first, or include user-created group placeholders?


## Browser proof

```text
url: http://127.0.0.1:8777/08-browser-render.html
liveness: PASS
console_errors: 0
vision_qa: PASS
```
