# PRD — Prop4You system schema / LFG topology / user workspace boundary

Status: active

## Problem

The current Matrix -> SourceHub -> LFG pipeline is technically proven, but the operational boundary between legacy Django `system`, LFG data, and the logged-in user's P4Y workspace needs to be explicit before promotion policy and larger materialization.

Without this boundary, we risk treating LFG-owned tags, labels, phone markers, DTO versions, ingestion state, and provider facts as if they were the same as user-owned annotations or workspace state.

## Goals

- Define `system`/LFG as an internal external-like data system, not merely a user app table set.
- Define user logged-in workspace as a consumer/snapshot layer that references LFG data by ID/version/hash.
- Clarify tags/labels/markers such as DNC/wrong in both contexts.
- Clarify multi-Postgres / multi-schema topology and when FDW is appropriate.
- Clarify ingestion/load separation for variable high-volume LFG ingestion.
- Persist deployment/operational guidance for Postgres 18 database-centric architecture.
- Preserve gateway/runtime agnostic posture.

## Non-goals

- No Angular/frontend design.
- No production deploy change.
- No provider calls.
- No final table explosion.
- No FDW DDL credentials/user mappings in this slice.
- No public RLS/API exposure.
- No dictionary promotion apply implementation yet.

## Acceptance

- PRD/tasks/ledger persisted.
- 3 bounded worker reviews persisted and independently reviewed.
- Canonical architecture doc persisted.
- Existing docs/index updated.
- Browser-proof + vision verifies the architecture artifact.
- Final report compares requested vs delivered and names next steps/questions.
