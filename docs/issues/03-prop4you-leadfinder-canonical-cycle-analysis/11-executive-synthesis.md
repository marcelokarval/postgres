# 11 — Executive synthesis: corrected LeadFinder canonical cycle

Status: delivered
Updated: 2026-06-16T12:06:25
Reviewer: Thor/default

## Verdict

Karval's correction is accepted: the current issue 02 DDL is safe only as an experimental raw/corpus/mapping lab. It must not be promoted as canonical until LeadFinder-owned dictionary/version/gap contracts exist.

## Corrected ownership

```text
LeadFinder group
  owns/generates canonical dictionary and canonical graph/materialization.

Matrix
  consumes LeadFinder dictionary version + raw/new evidence and produces a versioned transformation DTO/artifact.

SourceHub
  consumes raw/provider DTO + Matrix artifact and publishes LeadFinder-consumable JSON/DTO with lineage.

LeadFinder group
  consumes translated DTO, materializes canonical facts/leads, and emits gap/growth signals for dictionary evolution.
```

## Why this matters

The Django-era mistake was allowing implementation layers and helper systems to shape business truth before the canonical lead-generation graph was explicit. The database-centric version can repeat the same mistake if `prop4you_matrix.canonical_*` becomes the source of truth instead of a review/mirror over LeadFinder-owned dictionary versions.

## Evidence summary

- Private corpus path exists but has 0 JSON files today.
- Backend has 345 local JSON files; Matrix registry dominates local corpus/artifact evidence.
- DirectSkip has 1 raw-like local JSON file and extensive Matrix/SourceHub code evidence.
- REIQ has 1 raw-like local JSON file and extensive Matrix/SourceHub code evidence.
- Realtor has strong code/test evidence but no local JSON raw registry evidence in this scan.
- LeadFinder group evidence exists in `apps/system/lead_finder`, `domains/real_estate` canonical graph models, and tests for hydration/admin/public masking.
- Existing Prop4You-Inertia docs already partially encode the corrected architecture, but runtime residue remains.

## Current-step risk

```text
Risk: MEDIUM-HIGH if the next DDL expands Matrix/SourceHub/provider-first before LeadFinder canonical generator exists.
```

The issue 02 DDL currently has useful raw/mapping structures, but these are ownership-risky names/placement:

```text
prop4you_matrix.canonical_families
prop4you_matrix.canonical_fields
```

They should be treated as experimental mirrors/candidates until LeadFinder-owned dictionary tables exist, or renamed/migrated later.

## Corrected gate sequence

```text
G0 LeadFinder canonical seed gate
  -> dictionary_version + concepts/families/fields + gaps/growth signals

G1 SourceHub raw corpus gate
  -> raw_records/corpus_samples/lineage, no canonical promotion

G2 Matrix mapping session gate
  -> dictionary_version + raw pointers => transformation artifact/DTO mapping

G3 SourceHub translator gate
  -> raw + provider DTO + Matrix artifact => LeadFinder-consumable translated DTO

G4 LeadFinder materialization gate
  -> translated DTO => canonical facts/leads/materialization results

G5 Dictionary evolution gate
  -> gaps/conflicts/new patterns => LeadFinder dictionary N+1; Matrix remaps deltas
```

## Immediate DDL direction

1. Freeze issue 02 as experimental lab, not canonical truth.
2. Create `database/ddl/projects/prop4you/leadfinder/0001_canonical_dictionary.sql` next.
3. Add LeadFinder-owned tables:
   - `canonical_dictionary_versions`
   - `canonical_families`
   - `canonical_fields`
   - `canonical_gaps` / `growth_pressure_signals`
   - minimal materialization contract/status table if needed
4. Adjust Matrix later to reference `leadfinder_dictionary_version_id` and emit `transformation_artifacts`/`mapping_sessions`.
5. Add SourceHub translator/publication DDL after Matrix artifact link exists.
6. Only then freeze property/owner/phone/email/property-details tables.

## Guardrail

No future DDL should introduce provider-derived final columns unless it can answer:

```text
Which LeadFinder canonical dictionary version owns this concept?
Which Matrix artifact mapped this provider path?
Which SourceHub publication translated this raw into LeadFinder DTO?
Which LeadFinder materialization result accepted/rejected it?
```
