# 07 — Final Report: JSON curation + PG18 JSONB strategy

Status: completed / browser-proof pass / repo-only strategy pass
Generated: 2026-06-18T15:05:46

## Executive verdict

```text
Do not table-expand LFG yet.
Adopt JSONB-first / JSONSchema-governed canonical envelopes.
Next slice: LFG canonical JSONSchema envelope minimum.
```

## Evidence produced

```text
08-directskip-corpus-inventory.md
09-realtor-corpus-inventory.md
10-legacy-tags-labels-inventory.md
11-multi-corpus-json-curation-matrix.md
12-adr-pg18-jsonb-first-canonical-modeling.md
13-next-slice-gate-jsonschema-envelope-minimum.md
```

## DirectSkip findings

```text
213 JSON files parsed
210 Matrix registry artifacts
3 external real/sample raw responses
raw envelope: input, status, contacts, result_code
external totals: 3 contacts, 17 contact phones, 6 emails, 3 confirmed addresses, 12 relatives, 32 relative phones
```

Decision:

```text
DirectSkip is contact enrichment evidence, not owner/property truth.
Use JSONB raw + narrow contact satellite projections when needed.
```

## Realtor findings

Surfaces:

```text
autocomplete
property details
property estimates
property history/tax/permits
spot offer
nearby homes/map/recently sold/similar homes
market details
area boundary/geography
```

Decision:

```text
Realtor enriches canonical property/area.
Use tables for anchors, provider refs, PostGIS geometry, sanctioned snapshots.
Use JSONB for rich provider residue, arrays, media, comparables, market hotness, histories and advertiser/contact blocks.
```

## Tags/labels findings

System taxonomy and workspace tags are separate.

System side:

```text
PropertySituation.situation_type/status
LeadFinderMaterializedTaxonomyBlock
system_property_tag_slugs derived from active situations
Lead Finder genome systemic_taxonomy fields
```

Workspace side:

```text
PropertyTagRegistry
PropertyStatusRegistry
PropertyListRegistry
PropertyTag
PropertyList
SavedProperty.tags/lists
```

Examples observed:

```text
foreclosure, pre_foreclosure, probate, tax_lien, tax_delinquent, high_equity, absentee_owner, vacant
hot_lead, cold_lead, contacted, follow_up, qualified, not_interested
Available, Under Contract, Sold, Archived
Hot Leads, Follow Up, Archive, All Properties
```

Decision:

```text
Do not design/seed tag groups yet.
First define taxonomy/tag JSONSchema envelope and promotion boundary.
```

## Requested vs delivered

| Requested | Delivered |
| --- | --- |
| Use DirectSkip response payloads | DirectSkip real/sample + registry corpus inventoried |
| Experimental auto-apply threshold acceptable | Persisted default: low risk, 3 users, 2 workspaces, no disputes |
| Analyze legacy tag group candidates before design | Legacy tags/status/lists/system taxonomy inventory persisted |
| Analyze JSONB/table context with PG18 | ADR persisted with JSONB-first policy |
| Include Realtor JSON/context/backups | Realtor docs/code/snapshots/backups inventoried |
| Broader curation for many future sources/counties | Canonical JSONSchema-first strategy persisted |
| Orchestrator with subagents | 3 bounded workers used; runtime cap 3 noted |
| Browser-proof + vision | Pending in this file; final chat updates after QA |

## Correct next slice

```text
Slice 15 — LFG canonical JSONSchema envelope minimum
```

Scope:

1. property canonical envelope;
2. owner canonical envelope;
3. contact_satellites envelope informed by DirectSkip;
4. valuation/market/comparable evidence envelopes informed by Realtor;
5. taxonomy/tag/label vocabulary envelope;
6. projection policy for generated columns/tables;
7. marker auto-apply policy default.

## Non-goals preserved

```text
no DDL graph expansion yet
no workspace tables
no provider calls
no raw JSON values
no PII in artifacts
no final tag-group seed
```


## Browser proof

```text
url: http://127.0.0.1:8778/08-browser-render.html
liveness: PASS
console_errors: 0
vision_qa: PASS
```
