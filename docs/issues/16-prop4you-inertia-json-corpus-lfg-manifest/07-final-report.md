# 07 — Final Report: prop4you-inertia JSON corpus manifest for LFG

Status: completed / browser-proof pass / pending commit at generation
Generated: 2026-06-18T18:49:00

## Direct answer

```text
All `.json` files under prop4you-inertia were listed recursively and represented in the full manifest.
Top-level JSON files in the repo root were listed separately.
The project/LFG-relevant subset was classified and converted into a governed LFG corpus base.
```

## Source root

```text
/home/marcelo-karval/Backup/Projetos/prop4you/prop4you-inertia
```

## Top-level JSON files in root

```text
.auto-claude-security.json
.claude_settings.json
.mcp.json
package-lock.json
package.json
```

## Counts

```json
{
  "lfg_candidates": 3545,
  "parse_errors": 64,
  "recursive_json_total": 13160,
  "top_level_json_total": 5,
  "used_for_lfg_base": 3448
}
```

## Classification counts

```json
{
  "dependency_or_tooling": 853,
  "lfg_corpus_candidate": 3545,
  "parse_error": 64,
  "project_support": 2730,
  "unknown_or_out_of_scope": 5968
}
```

## LFG base decision counts

```json
{
  "exclude_from_domain_corpus": 9571,
  "include_as_project_metadata_not_lfg_domain": 77,
  "include_canonical_support": 149,
  "include_lfg_corpus": 383,
  "include_shape_only_restricted": 2896,
  "include_with_ephemeral_marker": 20,
  "review_or_exclude_until_parseable": 64
}
```

## Machine-readable artifacts

```text
docs/corpus/prop4you/lfg/prop4you-inertia-json-manifest.v1.jsonl
docs/corpus/prop4you/lfg/prop4you-inertia-lfg-corpus-candidates.v1.jsonl
docs/corpus/prop4you/lfg/prop4you-inertia-json-summary.v1.json
docs/corpus/prop4you/lfg/prop4you-inertia-lfg-corpus-base.v1.jsonl
docs/corpus/prop4you/lfg/prop4you-inertia-lfg-corpus-base-summary.v1.json
```

## How the JSONs are used for LFG

```text
include_lfg_corpus:
  direct domain evidence after envelope/gate review.
include_canonical_support:
  LeadFinder/Matrix contracts and baselines used to validate meaning.
include_shape_only_restricted:
  useful raw/sensitive evidence represented by hash/key/path/type only.
include_with_ephemeral_marker:
  runtime proof evidence, not durable truth by itself.
exclude_from_domain_corpus:
  dependency/tooling/generated/unrelated JSON represented in manifest but not used as domain source.
```

## Key conclusions

### DirectSkip / skiptrace

DirectSkip real/sample/handoff JSONs exist and are now part of the governed corpus base. DirectSkip should feed `contact_satellites`, especially via SourceHub handoffs. Raw responses stay restricted JSONB/parser evidence and do not define owner/property truth.

### Realtor / property / market

Realtor JSONs are enrichment evidence. They support `realtor_evidence`, property physical details, valuation, market/geography, and potential PostGIS/boundary projections after gates. Advertiser/contact/media/history arrays stay restricted JSONB.

### REIQ

REIQ dominates property/legal/situation evidence and is high-value for property/situation envelopes. Because it includes names/addresses/legal text, it remains lineage-bound and restricted until projection gates and privacy controls pass.

### Matrix / SourceHub / LeadFinder

Matrix registry and LeadFinder baselines are canonical support and semantic evidence. SourceHub handoffs are the safest bridge from raw/provider evidence into LFG. Generated caches and tooling are excluded from domain corpus.

## Residual risks

- 64 JSON files did not parse; most are tooling invalid-json test cases or temporary partial artifacts and are marked for review/exclusion.
- Archived/current duplicates need dedupe before any ingestion beyond manifest.
- Raw values and PII were not copied; future DB ingestion needs RLS/masking/retention before storing or exposing values.
- This slice does not create final property/owner/contact tables.

## Correct next slice

```text
Slice 17 — LFG projection candidate review board from prop4you-inertia corpus base
```

Goal: transform corpus base + JSONSchema registry into per-path candidate decisions using the seven gates.


## Browser proof

```text
liveness: PASS
console_errors: 0
vision_qa: PASS
```
