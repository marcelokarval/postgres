# prop4you/matrix

Status: experimental / non-final / mirror-candidate-review

[MATRIX_IS_NOT_CANONICAL_OWNER] Matrix does not own the canonical LeadFinder dictionary. LeadFinder owns the canonical dictionary/version graph; Matrix only mirrors, proposes and reviews semantic families/fields for provider/internal JSONB corpus comparison.

[MIRROR_CANDIDATE_REVIEW] Existing `canonical_families` and `canonical_fields` object names are retained for compatibility, but they are classified as experimental mirror/candidate/review structures, not source-of-truth tables.

Current DDL:

```text
0001_semantic_dictionary.sql
```

Rules:

- [NO_BREAKING_CHANGE] Do not freeze final property/owner tables from provider paths directly.
- Provider paths map to Matrix mirror/candidate/review fields first, then LeadFinder-owned dictionary versions become the canonical ownership target when available.
- Matrix approvals gate SourceHub DTO publication and later LeadFinder materialization, but approval in Matrix does not transfer dictionary ownership away from LeadFinder.
- Future DDL may add a non-breaking FK/link to `leadfinder_dictionary_version`; this package currently records the intended lineage in comments and seed metadata only.
- Store path components as PostgreSQL `text[]` paths, not executable provider code.
- No provider calls, secrets, raw/fake/redacted fixtures or payload dumps belong in this subpackage.
