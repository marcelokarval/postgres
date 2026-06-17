# Detection and analysis — SourceHub translated DTO publications

Status: active

## Decision

Proceed with T4: SourceHub translated DTO publications from raw_record + Matrix field_mapping_set + LeadFinder dictionary version. Runtime/gateway remains 100% agnostic. No LFG materialization yet.

## Guardrails

- SourceHub publishes DTOs; it does not own semantic meaning.
- Matrix field_mapping_set owns semantic translation contract.
- LeadFinder owns canonical dictionary and later LFG materialization.
- Raw values must not be printed into docs/reports.
- No Django/PostgREST/ORM dependency.
