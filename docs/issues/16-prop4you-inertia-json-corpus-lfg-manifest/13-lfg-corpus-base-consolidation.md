# 13 — LFG corpus base consolidation from prop4you-inertia JSONs

Status: PASS
Generated: 2026-06-18T18:47:02

## Direct answer

All `.json` files under `prop4you-inertia` are represented in the full manifest. The subset that belongs to Prop4You/LFG is now used as governed LFG base by manifest/hash/path-shape, without raw values.

## Source root

```text
/home/marcelo-karval/Backup/Projetos/prop4you/prop4you-inertia
```

## Machine-readable artifacts

```text
docs/corpus/prop4you/lfg/prop4you-inertia-json-manifest.v1.jsonl
docs/corpus/prop4you/lfg/prop4you-inertia-lfg-corpus-candidates.v1.jsonl
docs/corpus/prop4you/lfg/prop4you-inertia-json-summary.v1.json
docs/corpus/prop4you/lfg/prop4you-inertia-lfg-corpus-base.v1.jsonl
docs/corpus/prop4you/lfg/prop4you-inertia-lfg-corpus-base-summary.v1.json
```

## Counts

```json
{
  "canonical_envelope_hint_counts": {
    "contact_satellites": 235,
    "none": 9712,
    "property": 3104,
    "realtor_evidence": 27,
    "taxonomy": 82
  },
  "decision_counts": {
    "exclude_from_domain_corpus": 9571,
    "include_as_project_metadata_not_lfg_domain": 77,
    "include_canonical_support": 149,
    "include_lfg_corpus": 383,
    "include_shape_only_restricted": 2896,
    "include_with_ephemeral_marker": 20,
    "review_or_exclude_until_parseable": 64
  },
  "enriched_manifest": "docs/corpus/prop4you/lfg/prop4you-inertia-lfg-corpus-base.v1.jsonl",
  "evidence_role_counts": {
    "canonical_baseline_support": 36,
    "canonical_support_contract_schema": 113,
    "contact_enrichment_evidence": 7,
    "generated_docs_cache": 1,
    "handoff_or_lineage_evidence": 1,
    "parse_error": 64,
    "project_config_or_support": 77,
    "property_legal_signal_evidence": 19,
    "property_market_enrichment_evidence": 27,
    "restricted_legacy_raw_sample": 36,
    "restricted_raw_or_source_manifest": 2860,
    "runtime_proof_ephemeral": 20,
    "semantic_analysis_evidence": 236,
    "semantic_registry_evidence": 93,
    "tooling_dependency": 7939,
    "unknown_or_out_of_scope": 1631
  },
  "generated_at": "2026-06-18T18:47:02",
  "no_raw_values_policy": true,
  "priority_counts": {
    "blocked": 64,
    "high": 531,
    "low": 77,
    "medium": 2917,
    "none": 9571
  },
  "privacy_tier_counts": {
    "internal": 1708,
    "pii_sensitive": 3335,
    "provider_sensitive": 27,
    "restricted": 86,
    "tooling": 7940,
    "unknown": 64
  },
  "source_family_counts": {
    "dependency_or_tooling": 7939,
    "directskip_skiptrace": 235,
    "leadfinder_baseline": 36,
    "matrix_registry_or_artifact": 46,
    "parse_error": 64,
    "project_support": 77,
    "realtor_property_market": 27,
    "reiq_property_legal_signal": 3094,
    "sourcehub": 11,
    "unknown": 1631
  },
  "source_manifest": "docs/corpus/prop4you/lfg/prop4you-inertia-json-manifest.v1.jsonl",
  "total_json_files": 13160,
  "used_for_lfg_base_count": 3448
}
```

## Interpretation

- `include_lfg_corpus`: domain evidence usable by LFG after envelope/gate checks.
- `include_canonical_support`: LeadFinder/Matrix contracts/baselines used as support for validation and projection gates.
- `include_shape_only_restricted`: useful but sensitive/raw; use hashes, keys, path/type shapes and redacted processing only.
- `include_with_ephemeral_marker`: useful proof output, but `.tmp`/runtime evidence must not become durable truth without issue/proof provenance.
- `exclude_from_domain_corpus`: dependency/tooling/generated/unrelated JSON; represented in manifest but not a domain evidence source.

## Provider/source conclusions

### DirectSkip / skiptrace

Use DirectSkip primarily through SourceHub handoff shapes for `contact_satellites`. Raw DirectSkip responses stay as restricted JSONB lineage/parser regression evidence. Do not let DirectSkip define owner/property truth.

### Realtor

Use Realtor as `realtor_evidence` and property/market/geography enrichment. Project only sanctioned physical/valuation/market/geography fields after gates. Keep advertisers/contact/media/history arrays in restricted JSONB.

### REIQ

Use REIQ as property/legal/situation signal evidence. Strong candidate for property/situation envelope validation, but PII/legal text remains restricted and lineage-bound.

### Matrix / SourceHub / LeadFinder

Matrix registry and LeadFinder baselines are canonical support and semantic evidence. SourceHub handoffs are the preferred bridge into LFG. Caches/generated docs/tooling must not contaminate domain corpus.

## Residual warnings

- 64 JSON files failed parsing; most are tooling/test invalid-json cases or temporary partial artifacts. They remain represented and marked `review_or_exclude_until_parseable`.
- Some source families are duplicated across archived and active paths; future ingestion must dedupe by hash/provider/list/state/internal_id.
- Sensitive payloads must stay shape-only or restricted until RLS/retention/masking exists.
