# Final Report — LFG staging/materialization/operational loop

Status: delivered after browser proof; commit pending at report write time
Updated: 2026-06-17T22:04:46
Reviewer: Thor/default

## Verdict

The discussed loop from Matrix/SourceHub into LFG is now complete through a minimal T5 operational proof.

```text
T0 SourceHub raw evidence
  -> T1 Matrix extraction
    -> T2 LeadFinder gap bridge
      -> T3 Matrix quality_report
        -> T3.5 Matrix field_mapping_set
          -> T3.6 LeadFinder prepare-only promotions
            -> T4 SourceHub translated DTO publication
              -> T5.0 LFG staging candidates
                -> T5.1 materialization runs/results
                  -> T5.2 operational groups/events/facets minimum
```

## Delivered

```text
database/ddl/projects/prop4you/leadfinder_group/README.md
database/ddl/projects/prop4you/leadfinder_group/0001_staging_candidates.sql
database/ddl/projects/prop4you/leadfinder_group/0002_materialization_runs.sql
database/ddl/projects/prop4you/leadfinder_group/0003_operational_minimum.sql
```

## Proof

```json
{
  "bridge_count": 10,
  "field_mapping_set_count": 1,
  "gateway_agnostic": true,
  "lfg_run_statuses": [
    "completed"
  ],
  "materialization_result_count": 10,
  "materialization_run_count": 1,
  "no_provider_calls": true,
  "no_raw_values_printed": true,
  "operational_event_count": 10,
  "operational_facet_count": 30,
  "operational_group_count": 10,
  "promotion_preparation_count": 10,
  "quality_report_count": 1,
  "raw_record_count": 97,
  "run_distinct_path_count": 9650,
  "run_extracted_path_count": 172700,
  "run_source_record_count": 97,
  "sourcehub_t4_statuses": [
    "ready_for_review"
  ],
  "staging_candidate_count": 10,
  "translated_dto_publication_count": 10
}
```

## Non-claims

- No final full LeadFinder product graph.
- No property/owner/address/contact/scoring table explosion.
- No Django/PostgREST/ORM dependency.
- No provider calls.
- No raw payload dump in docs/proofs.
- No public RLS/API exposure.


## Browser proof

PASS. See `06-browser-proof.md`.
