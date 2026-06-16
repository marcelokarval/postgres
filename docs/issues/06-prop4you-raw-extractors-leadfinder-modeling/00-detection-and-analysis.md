# Detection and analysis — raw extractors for LeadFinder modeling

Status: active
Created: 2026-06-16T16:33:21
Owner: Thor/default

## Decision

Implement SQL/Python path/type/filter extractors before SourceHub translated DTO publication.

Reason:

```text
raw data are the matrix for canonical discovery and LeadFinder Group modeling.
LeadFinder filters are the demand-side guide for what organized, queryable, traceable data must exist.
SourceHub DTO publication should not freeze before extractor evidence has shaped the LeadFinder Group contract.
```

## Current context

- LeadFinder dictionary v0 exists as raw-born candidate dictionary.
- Matrix artifact gate exists.
- REIQ focused FL corpus has 97 JSON files and lab ingestion proof `INSERT 0 97`.
- Next required knowledge: observed paths/types/frequencies and filter pressure mapped to LeadFinder families.

## Safety boundaries

- No provider/API calls.
- No production mutation.
- No raw payload values in repo reports.
- No PII dumps.
- No committed raw JSON.
- Keep LeadFinder fields as candidates until extractor output is reviewed.
