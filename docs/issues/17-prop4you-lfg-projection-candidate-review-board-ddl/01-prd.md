# PRD — LFG projection candidate review board DDL

Status: active

## Problem

The LFG corpus base and JSONSchema registry exist, but decisions about which JSON paths become relational projections are still not queryable as durable DDL. Without a review board, projection work can drift back into blind Django table replication or ad-hoc JSON path extraction.

## Goal

Create a database-centric review board that stores projection candidate groups, candidate paths, decisions, semantic sequencing, privacy class, corpus evidence, and seven-gate evaluation state.

## Deliverables

1. `0006_projection_candidate_review_board.sql` under `leadfinder_group`.
2. Seed candidate groups for:
   - DirectSkip contact_satellites unified group;
   - geography first: Realtor boundary/geography, Realtor market geography, REIQ state/county/property geography;
   - sequential downstream groups: valuation, property physical facts, legal/situation signals, taxonomy/support.
3. Seed path-level candidate reviews for DirectSkip and geography-first lanes.
4. Views for active candidates, gate status, approved candidates, and next-action queue.
5. PG18 proof script with clean lab DB assertions.
6. PRD/tasks/reviews/final/browser-proof.

## Acceptance criteria

- DDL applies in a clean PG18 lab DB.
- Candidate groups are seeded.
- DirectSkip unified group contains phone/email, mailing address, and relationship evidence paths together.
- Geography-first groups exist and are sequenced before valuation/property/legal downstream groups.
- Every seeded candidate has seven gate rows.
- No candidate is auto-approved unless all seven gates pass.
- The proof returns machine-checkable JSON counts.
- Browser-proof and vision QA pass.
