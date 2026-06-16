# Matrix canonical tables reclassification

Status: delivered by Worker C

[MATRIX_IS_NOT_CANONICAL_OWNER]

Matrix is not the canonical owner of the LeadFinder dictionary. The canonical ownership target for dictionary families/fields/versions belongs to LeadFinder. Matrix remains a review/mapping package for provider/internal JSONB corpus comparison.

[MIRROR_CANDIDATE_REVIEW]

The existing `prop4you_matrix.canonical_families` and `prop4you_matrix.canonical_fields` names are retained for compatibility, but their classification is now experimental mirror/candidate/review:

- `canonical_families`: Matrix mirror/candidate/review family catalog.
- `canonical_fields`: Matrix mirror/candidate/review field meaning catalog.
- `provider_path_mappings.canonical_field_id`: compatibility column pointing to a Matrix review field candidate, not proof of canonical dictionary ownership.
- `mapping_reviews.canonical_field_id`: review linkage to a Matrix candidate field, while LeadFinder remains the canonical dictionary owner.

[NO_BREAKING_CHANGE]

The patch does not remove objects, rename tables/columns, add constraints, or add an FK to a table that may not exist yet. It changes only comments and safe seed metadata/descriptions in the idempotent Matrix DDL.

[DDL_PATCH]

Changed files:

- `database/ddl/projects/prop4you/matrix/0001_semantic_dictionary.sql`
- `database/ddl/projects/prop4you/matrix/README.md`

DDL-level changes:

- Added package markers documenting that Matrix is not canonical dictionary owner.
- Updated schema/table/column comments to say Matrix rows are mirror/candidate/review structures.
- Added comments noting future non-breaking lineage/FK target to `leadfinder_dictionary_version` after LeadFinder dictionary DDL exists.
- Updated seeded `canonical_families` descriptions and metadata with:
  - `dictionary_owner: leadfinder`
  - `matrix_classification: mirror_candidate_review`
  - `future_fk: leadfinder_dictionary_version`

[RISKS]

- Existing object names still include `canonical_*` for compatibility, so consumers must read comments/README and not infer ownership from names.
- No FK was added now because the LeadFinder dictionary version table/contract is not present in this slice; adding it prematurely could break lab apply.
- Seed metadata updates are idempotent but will overwrite previous metadata for these seeded families through the existing `on conflict` path.
