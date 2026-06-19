# 00 — Detection and Analysis

Generated: 2026-06-19T18:45:14

## User decision

```text
1. Slice 18 must implement real DDL now.
2. For geography, inspect legacy autocomplete because SystemArea is the base primitive.
```

## Initial evidence read

```text
backend/src/domains/geography/models/area_models.py
backend/src/domains/geography/services/system_area_registration_service.py
backend/src/domains/geography/services/geokeo_system_area.py
backend/src/domains/geography/migrations/0010_systemarea_geo_area_search_gin_idx_and_more.py
backend/src/apps/public/lead_finder/api_queries.py
backend/src/apps/public/lead_finder/contracts.py
frontends/front-react/src/pages/private/lead-finder/hooks/useLeadMapState.ts
```

## Preliminary architecture reading

SystemArea is the legacy canonical geography primitive for Lead Finder location filtering/autocomplete. The frontend uses `system_area_ids`, `systemAreaId`, `bbox`, and `center`; backend ranks canonical SystemArea first, can expand via Realtor autocomplete/feed, and treats address results as outside this Lead Finder location surface.
