# Final Report — LeadFinder dictionary from raws

Status: delivered after browser proof; commit pending at report write time
Updated: 2026-06-16T12:32:24
Owner/reviewer: Thor/default

## Verdict

SUPPORTED for experimental/non-final LeadFinder-owned canonical dictionary v0 born from local raw/code/baseline evidence, plus Matrix mirror/candidate reclassification and clean PG18 lab proof.

NOT CLAIMED:

- final property/owner/phone/email materialization;
- real private raw ingestion into DB;
- provider runtime calls;
- production deploy;
- generated columns/indexes on final provider paths.

## Delivered DDL

```text
database/ddl/projects/prop4you/leadfinder/0001_canonical_dictionary.sql
database/ddl/projects/prop4you/leadfinder/README.md
```

LeadFinder objects:

```text
prop4you_leadfinder.canonical_dictionary_versions
prop4you_leadfinder.canonical_families
prop4you_leadfinder.canonical_fields
prop4you_leadfinder.canonical_gaps
prop4you_leadfinder.growth_pressure_signals
```

Seeded:

```text
leadfinder.raw_candidate.v0
15 family candidates
36 field candidates
```

## Matrix reclassification

```text
prop4you_matrix.canonical_families = mirror/candidate/review
prop4you_matrix.canonical_fields = mirror/candidate/review
```

LeadFinder now owns canonical dictionary authority.

## Lab proof

Report:

```text
docs/reports/prop4you-sourcehub-matrix-ddl-lab-proof.md
```

Validation summary:

```text
provider_count: 4
payload_class_count: 5
mapping_version_count: 4
matrix_mirror_family_count: 7
leadfinder_dictionary_version_count: 1
leadfinder_family_count: 15
leadfinder_field_count: 36
missing_schemas: []
missing_tables: []
uncommented_tables: []
jsonb_path_type_smoke: number
jsonb_leaf_paths_smoke_count: 2
```

## Raw/code evidence conclusion

The dictionary is raw-born but governed:

- DirectSkip raw-like evidence motivates owner/contact/relationship/address candidates.
- REIQ raw-like evidence motivates property/details/situation/valuation/owner/taxonomy candidates.
- LeadFinder baselines/models/tests expand the initial family set beyond the two narrow raw files.
- Realtor remains code-supported but not raw-supported in local JSON scan.

## Next steps

1. Add Matrix mapping_sessions/transformation_artifacts linked to `prop4you_leadfinder.canonical_dictionary_versions`.
2. Add SourceHub translated DTO publication table linked to raw_record + Matrix artifact + LeadFinder dictionary version.
3. Implement raw ingestion to lab DB from private corpus using raw JSONB, with no repo payload commits.
4. Implement both SQL and Python path candidate extractors; compare outputs.
5. Implement both pgmq + polling enrichment request execution model.
6. Only after that start canonical materialization tables: property, property_details/photos/history/situation/valuation, owner, ownership_history, phone/email/contact satellites, lead/opportunity.

## Questions for next slice

1. Should the next slice be Matrix `mapping_sessions/transformation_artifacts` or SourceHub `translated_dto_publications` first?
2. Should raw ingestion into lab DB load the two local raw-like files immediately, or wait for private corpus files under `~/.hermes/private/prop4you-provider-corpus/`?
3. Should field candidates be promoted from `candidate` to `in_review` only after path extractor output exists?


## Browser proof

PASS. See `06-browser-proof.md`. Static page rendered expected title/badges/content, browser console had 0 errors, and vision QA passed.
