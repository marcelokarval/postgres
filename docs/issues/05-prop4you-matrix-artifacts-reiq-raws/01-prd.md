# PRD — Prop4You Matrix artifacts and REIQ raw corpus gate

Status: draft

## Problem

LeadFinder now owns the raw-born canonical dictionary v0, but Matrix lacks a versioned session/artifact layer that can analyze REIQ/provider raw evidence against a LeadFinder dictionary version and emit a transformation artifact for later SourceHub translation. The local environment also has many REIQ raw payloads that must be used safely without committing payloads or dumping PII.

## Goals

- Implement Matrix DDL for mapping sessions, transformation artifacts, and artifact field mappings referencing LeadFinder dictionary versions.
- Keep existing Matrix `canonical_*` tables as mirror/candidate/review, not authority.
- Inventory local REIQ raw files by path/type/count/hash-size metadata only, without raw values.
- Add a repo script that can ingest raw JSON files into a lab DB as JSONB without committing payloads.
- Prepare the SourceHub DTO publication contract/design so the next slice has a clear target.
- Extend proof script to apply the new Matrix artifact DDL and validate clean PG18 lab apply.
- Persist PRD/tasks/reviews/final/browser proof.

## Non-goals

- No provider/API calls.
- No raw payload commits.
- No production mutation.
- No final SourceHub translated DTO table implementation unless safe as documentation/contract only.
- No promotion of LeadFinder fields from `candidate` to `in_review` until extractor output exists.

## Acceptance criteria

- `database/ddl/projects/prop4you/matrix/0002_mapping_sessions.sql` exists and applies in lab.
- It references `prop4you_leadfinder.canonical_dictionary_versions`.
- Lab proof validates session/artifact tables exist and comments are present.
- REIQ raw inventory report exists without PII/raw values.
- Raw ingestion script exists and supports dry-run/path-limited mode.
- Browser proof renders PRD/task review/final/lab proof.
