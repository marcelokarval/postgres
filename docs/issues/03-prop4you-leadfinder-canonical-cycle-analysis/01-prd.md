# PRD — Prop4You LeadFinder canonical cycle analysis

Status: draft

## Problem

The current experimental SourceHub + Matrix DDL may still be biased toward provider/source ingestion. Karval clarified that the canonical dictionary should be born from the LeadFinder group — the final consumer and canonical generator — while Matrix uses that dictionary to generate transformation DTOs and SourceHub translates provider raw into LeadFinder-consumable JSON.

## Goal

Analyze whether the current approach repeats the Django-era mistake, inspect Prop4You-Inertia system/leadfinder structures and available raw corpus evidence, then define the corrected execution order before implementing further DDL.

## Non-goals

- No provider calls.
- No raw PII dumps.
- No final DDL mutation in this analysis slice unless explicitly promoted later.
- No production/runtime mutation.

## Acceptance criteria

- Persist raw/corpus evidence summary without values.
- Persist Prop4You-Inertia system/leadfinder app analysis.
- Persist corrected Matrix <-> SourceHub <-> LeadFinder dependency model.
- Identify current-step risk and recommended next DDL direction.
- Record requested-vs-delivered review and final report.
