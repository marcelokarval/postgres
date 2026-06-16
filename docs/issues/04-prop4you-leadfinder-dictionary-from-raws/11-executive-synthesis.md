# 11 — Executive synthesis: LeadFinder dictionary born from raws

Status: delivered
Updated: 2026-06-16T12:32:24
Reviewer: Thor/default

## Core correction

The canonical center is owned by LeadFinder Group, but it is born/evolved from raw analysis. The safe model is not provider-first and not top-down-only. It is governed feedback:

```text
raw/provider/internal evidence
  -> LeadFinder family/field candidates
  -> LeadFinder dictionary version
  -> Matrix transformation artifact
  -> SourceHub translated DTO
  -> LeadFinder materialization
  -> LeadFinder gaps/growth pressure
  -> next dictionary version
```

## What changed in DDL

- Added LeadFinder-owned dictionary package:
  - `prop4you_leadfinder.canonical_dictionary_versions`
  - `prop4you_leadfinder.canonical_families`
  - `prop4you_leadfinder.canonical_fields`
  - `prop4you_leadfinder.canonical_gaps`
  - `prop4you_leadfinder.growth_pressure_signals`
- Seeded `leadfinder.raw_candidate.v0`.
- Seeded 15 family candidates and 36 field candidates.
- Reclassified Matrix `canonical_*` as mirror/candidate/review, not canonical ownership.

## Raw-derived insight

Local raw-like corpus is narrow but enough to justify v0 candidate families:

- DirectSkip raw-like structure supports owner/contact/relationship/address evidence.
- REIQ loan-modification raw-like structure supports property identity/details, legal/situation, valuation/loan/equity, owner hints and taxonomy pressure.
- LeadFinder baselines/models/tests support broader families that are not fully represented by raw local files yet.
- Realtor remains code-supported but lacks raw-like JSON evidence in local scan.

## Correct status of issue 02

Issue 02 is now explicitly experimental:

```text
prop4you_matrix.canonical_* = Matrix mirror/candidate/review
prop4you_leadfinder.canonical_* = LeadFinder-owned dictionary authority
```

## PG18/JSONB stance

This keeps PG18 JSONB power available without prematurely freezing tables:

- raw payloads remain JSONB evidence;
- LeadFinder dictionary records raw-derived concepts without raw values;
- Matrix maps JSONB paths to candidate fields/artifacts;
- SourceHub later publishes translated DTO JSONB;
- generated/projected fields should be added only after dictionary + artifact + usage stability.
