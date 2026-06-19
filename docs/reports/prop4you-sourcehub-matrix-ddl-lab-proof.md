# Prop4You Provider + SourceHub + Matrix + LeadFinder DDL Lab Proof

Status: PASS
LAB_DB: pg18_prop4you_projection_candidate_board_lab
PGHOST: 127.0.0.1
PGPORT: 54318

## Scope

Applied base DDL and experimental Prop4You provider/sourcehub/matrix/leadfinder DDL into a clean lab DB.

No provider calls were made.
No raw/fake/redacted fixtures were created.

## Apply order

- `database/ddl/base/0001_install_tracking.sql`
- `database/ddl/base/0002_extensions.sql`
- `database/ddl/base/0003_base_schemas_roles_context.sql`
- `database/ddl/base/0004_public_id.sql`
- `database/ddl/base/0005_lifecycle_columns_triggers.sql`
- `database/ddl/base/0006_jsonb_contract_helpers.sql`
- `database/ddl/base/0007_search_normalization.sql`
- `database/ddl/base/0008_audit_log.sql`
- `database/ddl/base/0009_realtime_base.sql`
- `database/ddl/base/0010_api_base.sql`
- `database/ddl/projects/prop4you/0001_schemas.sql`
- `database/ddl/projects/prop4you/providers/0001_provider_registry.sql`
- `database/ddl/projects/prop4you/sourcehub/0001_sourcehub_corpus.sql`
- `database/ddl/projects/prop4you/matrix/0001_semantic_dictionary.sql`
- `database/ddl/projects/prop4you/leadfinder/0001_canonical_dictionary.sql`
- `database/ddl/projects/prop4you/matrix/0002_mapping_sessions.sql`
- `database/ddl/projects/prop4you/matrix/0003_raw_path_extractors.sql`
- `database/ddl/projects/prop4you/leadfinder/0002_raw_evidence_gap_bridge.sql`
- `database/ddl/projects/prop4you/matrix/0004_quality_report_artifacts.sql`
- `database/ddl/projects/prop4you/matrix/0005_field_mapping_set_artifacts.sql`
- `database/ddl/projects/prop4you/leadfinder/0003_prepare_dictionary_promotions.sql`
- `database/ddl/projects/prop4you/sourcehub/0002_translated_dto_publications.sql`
- `database/ddl/projects/prop4you/leadfinder_group/0001_staging_candidates.sql`
- `database/ddl/projects/prop4you/leadfinder_group/0002_materialization_runs.sql`
- `database/ddl/projects/prop4you/leadfinder_group/0003_operational_minimum.sql`
- `database/ddl/projects/prop4you/leadfinder_group/0004_user_feedback_markers.sql`
- `database/ddl/projects/prop4you/leadfinder_group/0005_canonical_jsonschema_registry.sql`
- `database/ddl/projects/prop4you/leadfinder_group/0006_projection_candidate_review_board.sql`
- `database/ddl/projects/prop4you/leadfinder/0004_dictionary_promotion_review_apply.sql`

## Validation JSON

```json
{"counts": {"provider_count": 4, "payload_class_count": 5, "mapping_version_count": 4, "leadfinder_field_count": 36, "leadfinder_family_count": 15, "matrix_mirror_family_count": 7, "matrix_raw_path_view_count": 4, "matrix_artifact_table_count": 3, "matrix_raw_path_table_count": 2, "matrix_raw_path_function_count": 3, "leadfinder_gap_bridge_table_count": 1, "leadfinder_dictionary_version_count": 1, "matrix_field_mapping_function_count": 1, "sourcehub_translated_dto_view_count": 1, "leadfinder_gap_bridge_function_count": 2, "matrix_quality_report_function_count": 1, "sourcehub_translated_dto_table_count": 1, "sourcehub_translated_dto_function_count": 2, "leadfinder_promotion_prepare_table_count": 1, "leadfinder_promotion_prepare_function_count": 1}, "missing_tables": [], "missing_schemas": [], "uncommented_tables": [], "jsonb_path_type_smoke": "number", "jsonb_leaf_paths_smoke_count": 2}
```

## Boundary

This proves DDL apply/comment/object smoke for experimental Provider + SourceHub + Matrix mirror/candidate + LeadFinder dictionary gate.
It does not prove final Prop4You property/owner tables, provider runtime calls, production deployment, real raw ingestion, or LeadFinder materialization.
