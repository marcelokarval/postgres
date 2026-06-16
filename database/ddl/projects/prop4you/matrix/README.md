# prop4you/matrix

Status: experimental / non-final / mirror-candidate-review

[MATRIX_IS_NOT_CANONICAL_OWNER] Matrix does not own the canonical LeadFinder dictionary. LeadFinder owns the canonical dictionary/version graph; Matrix only mirrors, proposes and reviews semantic families/fields for provider/internal JSONB corpus comparison.

[MIRROR_CANDIDATE_REVIEW] Existing `canonical_families` and `canonical_fields` object names are retained for compatibility, but they are classified as experimental mirror/candidate/review structures, not source-of-truth tables.

[MATRIX_ARTIFACT_GATE] Matrix mapping sessions and transformation artifacts are review gates for semantic translation artifacts. Passing this gate may authorize later SourceHub DTO publication work, but it does not publish DTOs or materialize LeadFinder canonical entities by itself.

[LEADFINDER_DICTIONARY_FK] `0002_mapping_sessions.sql` links Matrix mapping sessions, transformation artifacts, and artifact field mappings to `prop4you_leadfinder.canonical_dictionary_versions`.

Current DDL:

```text
0001_semantic_dictionary.sql
0002_mapping_sessions.sql
```

Rules:

- [NO_BREAKING_CHANGE] Do not freeze final property/owner tables from provider paths directly.
- Provider paths map to Matrix mirror/candidate/review fields first, then LeadFinder-owned dictionary versions remain the canonical ownership target.
- Matrix approvals gate SourceHub DTO publication and later LeadFinder materialization, but approval in Matrix does not transfer dictionary ownership away from LeadFinder.
- Mapping sessions and transformation artifacts must store only non-secret JSONB metadata, path labels, aggregate findings, transform policies, and review status.
- Store path components as PostgreSQL `text[]` paths, not executable provider code.
- [NO_FIXTURES] No raw/fake/redacted fixtures or payload dumps belong in this subpackage.
- [NO_PROVIDER_CALLS] No provider calls, HTTP clients, secrets, or runtime enrichment logic belong in this subpackage.
