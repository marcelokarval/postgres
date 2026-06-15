# prop4you/matrix

Status: experimental / non-final

Matrix owns semantic dictionary, provider path mappings, mapping versions and review gates for Prop4You provider/internal JSONB corpus comparison.

Current DDL:

```text
0001_semantic_dictionary.sql
```

Rules:

- Do not freeze final property/owner tables from provider paths directly.
- Provider paths map to canonical fields first.
- Matrix approvals gate SourceHub DTO publication and later LeadFinder materialization.
- Store path components as PostgreSQL `text[]` paths, not executable provider code.
- No provider calls, secrets, raw/fake/redacted fixtures or payload dumps belong in this subpackage.
