# Task Review — Slice 18

Status: PASS

## Acceptance items

| Item | Evidence | Result |
| --- | --- | --- |
| Inspect legacy SystemArea/autocomplete before DDL | `08-systemarea-legacy-audit.md`, `09-autocomplete-contract-audit.md` | PASS |
| Implement real DDL now | `0007_systemarea_autocomplete_geography_projection.sql` | PASS |
| Preserve legacy autocomplete contract | `search_system_area_autocomplete(...)`, `v_system_area_autocomplete_suggestions` | PASS |
| Use SystemArea identity, not provider/property identity | `system_areas.public_ref`, provider identity side table | PASS |
| Start with geography before downstream lanes | DDL only creates geography/autocomplete objects | PASS |
| No provider calls | proof guardrail + local-only function | PASS |
| No raw provider payload values | lineage/metadata refs only; docs/proof synthetic | PASS |
| No property/owner/workspace table explosion | DDL creates only SystemArea geography/feed objects | PASS |
| PG18 proof real execution | `docs/reports/prop4you-lfg-systemarea-autocomplete-geography-proof.md` | PASS |

## Implemented objects

```text
prop4you_leadfinder_group.system_areas
prop4you_leadfinder_group.system_area_provider_identities
prop4you_leadfinder_group.system_area_aliases
prop4you_leadfinder_group.system_area_feed_terms
prop4you_leadfinder_group.system_area_feed_results
prop4you_leadfinder_group.v_system_area_autocomplete_suggestions
prop4you_leadfinder_group.v_system_area_provider_lineage
prop4you_leadfinder_group.v_system_area_projection_gate_status
prop4you_leadfinder_group.upsert_system_area_projection(...)
prop4you_leadfinder_group.search_system_area_autocomplete(...)
```

## Proof summary

```json
{
  "system_area_count": 4,
  "provider_identity_count": 4,
  "alias_count": 4,
  "feed_term_count": 1,
  "feed_result_count": 1,
  "centroid_count": 4,
  "bbox_count": 4,
  "autocomplete_orl_count": 1,
  "autocomplete_zip_count": 1,
  "autocomplete_state_count": 1,
  "projected_gate_candidate_count": 18,
  "approved_candidate_count": 0
}
```

## Notes

- `value == systemAreaId == system_areas.public_ref` in the autocomplete contract.
- `center` is serialized as `[lng, lat]`.
- `bbox` is serialized as `[west, south, east, north]`.
- Address/street-level autocomplete is intentionally excluded from this surface.
