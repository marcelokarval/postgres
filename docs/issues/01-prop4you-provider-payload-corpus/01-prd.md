# PRD — Prop4You provider payload corpus and canonical DDL decision gate

Status: draft
Owner: Thor/default

## Goal

Create a persisted, reviewable provider payload corpus plan and first repo-local artifact stack that enables future Prop4You database-centric DDL design to be driven by side-by-side JSON/provider comparison instead of mechanically copying Django models.

## Providers in v0

Priority order and role:

```text
1. REIQ       — current/base data source
2. DirectSkip — owner/contact enrichment source
3. Realtor.com — broad property enrichment source
4. Internal/manual/product-originated payloads — supporting corpus
```

## Requirements

- Analyze available backend code, tests, fixtures, sample JSONs, DTOs and contracts related to REIQ, DirectSkip, Realtor.com, SourceHub, Matrix and LeadFinder.
- Produce provider-by-provider payload/path inventory without leaking secrets or PII.
- Produce side-by-side comparison matrix: identity/property/owner/contact/situation/valuation/legal/lineage/enrichment fields.
- Define canonical dictionary decision gates.
- Define package + subpackage DDL structure, but do not freeze final tables until corpus comparison is reviewed.
- Define fixture policy for a DDL system separate from PG18 base.
- Define PII/RLS/retention boundaries for raw payloads.
- Create initial Prop4You DDL package skeleton only if safe/non-committal.
- Create lab-proof plan/script skeleton that does not claim final DDL execution.

## Non-goals

- No provider API calls.
- No real payload dumps in chat or docs.
- No production/runtime mutation.
- No final table schema freeze.
- No persistent DB mutation beyond optional temporary/rollback smoke checks.

## Acceptance criteria

- Issue stack created and referenced in canonical docs.
- Subagent artifacts exist for REIQ, DirectSkip and Realtor/internal comparison lanes.
- Parent/orchestrator review compares requested vs delivered.
- Provider corpus strategy answers the four user decisions.
- DDL package + subpackage skeleton exists or is explicitly deferred with reason.
- Browser-proof + vision confirms rendered report.
- Final report persists next steps/questions.
