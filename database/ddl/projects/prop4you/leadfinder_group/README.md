# prop4you/leadfinder_group

Status: experimental / non-final

LeadFinder Group owns the operational LFG boundary after SourceHub translated DTO publication. This package starts deliberately narrow to avoid premature table explosion.

Implemented DDL:

- `0001_staging_candidates.sql` — T5.0 staging candidates from SourceHub translated DTO publications.
- `0002_materialization_runs.sql` — T5.1 materialization runs/results review gate.
- `0003_operational_minimum.sql` — T5.2 minimal operational groups/events/facets from accepted materialization results.
- `0004_user_feedback_markers.sql` — user/workspace feedback votes, aggregate marker review, and global marker apply gates.
- `0005_canonical_jsonschema_registry.sql` — queryable registry for LFG canonical JSONSchema envelopes and JSONB-to-relational projection policy.
- `0006_projection_candidate_review_board.sql` — queryable review-board for JSON path projection candidates, semantic lanes, seven-gate evaluations, and explicit keep-jsonb/generated-column/index/narrow-table/PostGIS decisions before final projections.
- `0007_systemarea_autocomplete_geography_projection.sql` — real geography-first SystemArea/autocomplete projection with SystemArea rows, provider identities, aliases, feed term/result ledger, local autocomplete function, and provider-free map contract.

Boundaries:

- [GATEWAY_AGNOSTIC] SQL contracts callable by direct SQL, ORM, PostgREST, Django/FastAPI passthrough, workers, or other gateway runtimes.
- [SOURCEHUB_T4_INPUT] LFG consumes SourceHub translated DTO publications, not provider raw payload directly.
- [NO_PROVIDER_CALLS] No HTTP/provider SDK calls, files, workers, or cron are created.
- [NO_RAW_DUMPS] DDL does not copy SourceHub raw_payload into LFG tables.
- [MINIMAL_OPERATIONAL] Operational rows are intentionally minimal and reviewable; final product graph/scoring/map/list/detail remains later.

Canonical flow:

```text
SourceHub translated_dto_publications
  -> LFG staging_candidates
    -> LFG materialization_runs/results
      -> LFG operational_groups/events/facets minimum
```
