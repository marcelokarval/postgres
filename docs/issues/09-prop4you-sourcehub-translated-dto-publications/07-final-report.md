# Final Report — SourceHub translated DTO publications

Status: delivered after browser proof; commit pending at report write time
Updated: 2026-06-17T20:49:02
Reviewer: Thor/default

## Verdict

T4 is now implemented as a SourceHub-owned, gateway-agnostic translated DTO publication layer.

```text
T0 SourceHub raw evidence
  -> T1 Matrix extraction
    -> T2 LeadFinder gap bridge
      -> T3 Matrix quality_report
        -> T3.5 Matrix field_mapping_set
          -> T3.6 LeadFinder prepare-only promotions
            -> T4 SourceHub translated DTO publication
              -> T5 LFG materialization later
```

## Delivered

```text
database/ddl/projects/prop4you/sourcehub/0002_translated_dto_publications.sql
```

Objects:

```text
prop4you_sourcehub.translated_dto_publications
prop4you_sourcehub.validate_translated_dto_publication()
prop4you_sourcehub.v_translated_dto_publication_review
prop4you_sourcehub.publish_translated_dtos_from_field_mapping_set(...)
```

## Proof

```json
{
  "bridge_count": 10,
  "dictionary_match_count": 10,
  "field_mapping_artifact_kind_count": 10,
  "field_mapping_set_count": 1,
  "gateway_agnostic": true,
  "lfg_materialization_created": 0,
  "no_raw_values_printed": true,
  "promotion_preparation_count": 10,
  "quality_report_count": 1,
  "raw_record_count": 97,
  "run_distinct_path_count": 9650,
  "run_extracted_path_count": 172700,
  "run_source_record_count": 97,
  "sourcehub_t4_statuses": [
    "ready_for_review"
  ],
  "translated_dto_contract": "sourcehub.translated_dto.v0",
  "translated_dto_hash_count": 10,
  "translated_dto_publication_count": 10
}
```

## Non-claims

- No Django dependency.
- No PostgREST dependency.
- No ORM dependency.
- No provider calls.
- No automatic canonical dictionary promotion.
- No LFG runtime/materialization.
- No raw payload values printed in docs/proofs.


## Browser proof

PASS. See `06-browser-proof.md`.
