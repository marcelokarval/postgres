# PRD — LFG SystemArea autocomplete geography projection DDL

Status: active

## Problem

Slice 17 created a projection candidate review board, but geography/autocomplete is still only a candidate. Karval decided Slice 18 must implement the real DDL and specifically use the legacy SystemArea/autocomplete model as the base.

## Goal

Create the first real database-centric geography projection for LFG/SystemArea autocomplete: canonical system areas, provider identity, local autocomplete/search, viewport/bbox/centroid contracts, provider/feed result lineage, and promotion gate linkage.

## Deliverables

1. Legacy SystemArea/autocomplete inventory.
2. DDL `0007_systemarea_autocomplete_geography_projection.sql`.
3. Proof script that applies PG18 lab DDL and proves the SystemArea autocomplete projection objects and sample behavior.
4. Docs/reviews/final/browser-proof.

## Acceptance criteria

- DDL applies in clean PG18 lab DB.
- Real projection tables/views/functions exist.
- SystemArea identity fields are represented: public ref, slug_id, realty_id/provider object, provider_geo_id, area_type, name, state, parent, centroid, boundary/viewport readiness, search terms.
- Autocomplete contract supports query -> suggestions with label/value/type/systemAreaId/center/bbox/registrationStatus shape.
- Geography starts before downstream market/valuation/property/legal lanes.
- No raw provider payload values are stored in docs/proofs.
- Existing projection candidate board remains compatible.
