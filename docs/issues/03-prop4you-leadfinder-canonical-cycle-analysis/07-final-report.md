# Final Report — Prop4You LeadFinder canonical cycle analysis

Status: delivered
Updated: 2026-06-16T12:06:25
Owner/reviewer: Thor/default

## Verdict

The correction changes the implementation order. The current SourceHub + Matrix DDL from issue 02 remains useful as an experimental lab, but it is not safe to promote as canonical. The next DDL must pivot to LeadFinder-owned canonical dictionary/gap contracts.

## Core conclusion

```text
LeadFinder group is the canonical generator.
Matrix is the mapping/review compiler.
SourceHub is the raw/translation/publication boundary.
Providers are evidence sources.
```

## Why current issue 02 is not enough

Issue 02 created:

```text
prop4you_provider.*
prop4you_sourcehub.raw_records/corpus_samples/lineage/enrichment_requests
prop4you_matrix.canonical_families/canonical_fields/mapping_versions/provider_path_mappings/mapping_reviews
```

That is acceptable for a raw/mapping lab. The danger is naming/authority: `matrix.canonical_*` can accidentally make Matrix the owner of canonical truth. Karval's correction means these must become either temporary candidates/mirrors or later be moved under LeadFinder dictionary ownership.

## Evidence from raw/corpus scan

- Private corpus path: exists but currently empty.
- Backend local JSONs: 345.
- Matrix registry JSONs: 316.
- DirectSkip registry JSONs: 210, with 1 raw-like file.
- REIQ registry JSONs: 98, with 1 raw-like file.
- Realtor raw JSON registry files: 0 in this scan; code/test evidence exists.
- SourceHub JSON path files: 0 by path token; code/model evidence exists.
- LeadFinder baseline JSONs: 8 owner baseline/model inventory files.

No raw values, PII, provider IDs, phones, emails or payload dumps were included.

## Evidence from Prop4You-Inertia

LeadFinder group includes at least:

```text
property/address
property details/photos
property history/snapshots
property situations/legal timeline
valuation/financial facts
owner entity
ownership historical relation
party roles
representatives
relationship evidence
owner contact address
owner phones with callable/DNC/dead/matched/priority-like statuses
owner emails with sendability/bounce-like statuses
lead/opportunity/scoring/public/workspace consumers
```

Key observation: `apps/system/lead_finder` and `domains/real_estate` already contain the corrected architecture in partial form, but runtime residue remains in services/interfaces/compat fields.

## Corrected pipeline

```text
G0 LeadFinder canonical seed gate
G1 SourceHub raw corpus gate
G2 Matrix mapping session gate
G3 SourceHub translator/publication gate
G4 LeadFinder materialization gate
G5 Dictionary evolution gate
```

## Immediate decision

Next work should not continue by expanding provider/sourcehub/matrix DDL first. It should create the minimal LeadFinder canonical generator package:

```text
database/ddl/projects/prop4you/leadfinder/0001_canonical_dictionary.sql
```

Suggested objects:

```text
prop4you_leadfinder.canonical_dictionary_versions
prop4you_leadfinder.canonical_families
prop4you_leadfinder.canonical_fields
prop4you_leadfinder.canonical_gaps
prop4you_leadfinder.growth_pressure_signals
```

Then Matrix can reference `leadfinder_dictionary_version_id`, and SourceHub can publish translated DTOs against that version.

## Non-claims

This analysis did not:

- call providers;
- inspect production DB rows;
- dump raw payloads/PII;
- create new DDL in this slice;
- prove runtime/browser behavior;
- prove real corpus ingestion.

## Next steps

1. Create PRD/tasks for LeadFinder canonical dictionary DDL v0.
2. Implement LeadFinder-owned dictionary/gap tables before changing Matrix authority.
3. Add Matrix transformation artifact/session tables referencing LeadFinder dictionary version.
4. Add SourceHub translated DTO publication table referencing raw record + Matrix artifact + dictionary version.
5. Build raw ingestion path using real private corpus into lab DB, with raw JSONB allowed in lab but no payload commits.
6. Implement both pgmq + polling model for enrichment requests.
7. Implement both SQL and Python path candidate extractors and compare outputs.

## Questions for next slice

1. Should `matrix.canonical_families/fields` be deprecated/renamed now, or kept temporarily as mirror/candidate until LeadFinder DDL exists?
2. Should LeadFinder dictionary v0 seed only families first, or also canonical fields for property/owner/phone/email immediately?
3. For raw ingestion in lab, do we keep raw JSONB in `prop4you_sourcehub.raw_records` only, or also write a private filesystem checksum index beside the lab load?
