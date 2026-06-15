# Executive Synthesis — Prop4You database-centric extraction plan

Status: reviewed
Updated: 2026-06-15T00:44:05
Owner: Thor/default

## Verdict

SUPPORTED for repo-local/documentation/static-contract closure.

INCOMPLETE for final Prop4You DDL/runtime/product claims because this slice intentionally does not implement final DDL, call providers, or run product runtime flows.

## Final architectural stance

The Prop4You DDL extraction must not copy Django models mechanically. The current backend is evidence. The final database-centric shape must be derived from:

1. current Django/Inertia domains and relations;
2. provider/internal payload contracts;
3. JSONB raw/normalized/canonical layering;
4. Matrix semantic dictionary and field review lifecycle;
5. SourceHub ingress/lineage/DTO publication;
6. LeadFinder canonical graph consumption;
7. DDL comments and lab proof before promotion.

## Critical addition from Karval

The `system` group that composes LeadFinder/Matrix/SourceHub is expected to mutate. Many existing apps were not designed from broad provider payload comparison. Therefore provider JSON and internal captured JSON must be first-class evidence, not incidental metadata.

## Extraction strategy

Recommended implementation order remains dependency-aware but now gains one extra gate: before freezing DDL fields for provider-driven domains, run provider payload corpus comparison and dictionary approval.

```text
0. base/core substrate
1. identity
2. geography
3. finance/billing where access gates are needed
4. property/leadfinder canonical graph
5. sourcehub raw/lineage/DTO publication
6. skiptrace enrichment
7. matrix semantic dictionary/governance
8. sales/communication
9. api facade
```

For the Matrix/SourceHub/LeadFinder cluster, the operational order is:

```text
sourcehub.raw_record corpus
  -> matrix semantic dictionary / genome / reviews
  -> sourcehub canonical DTO publication
  -> leadfinder graph materialization
  -> generated/projected fields after stability
```

## JSONB stance

Use JSONB heavily, but governed:

- raw provider/internal payloads are append-only evidence;
- normalized projections are mapper-versioned;
- canonical facts/tables only promote approved semantics;
- generated/projected fields from JSONB paths are for stable/high-value paths;
- JSON_TABLE is available in PG18 lab for row projection from JSON structures;
- every projection must preserve lineage to raw payload and dictionary decision.

## DDL comments stance

DDL comments are mandatory contract, not decoration. Future DDLs must use `COMMENT ON` for schemas, tables, columns, functions, triggers, policies and views. Comments must be objective, orientative and documentary.

## Parent/orchestrator validation evidence

- Subagent artifacts were read by Thor.
- Status files were read.
- Marker grep confirmed required sections and claims.
- PG18 lab smoke validated JSONB generated projection and JSON_TABLE in `pg18_ddl_lab` using temporary table and rollback.
- No provider API calls, runtime mutation, Docker/Swarm mutation, or production changes were made.

## Artifacts synthesized

- `08-jsonb-provider-payload-strategy.md`
- `09-matrix-sourcehub-leadfinder-canonical-dictionary.md`
- `10-ddl-extraction-and-comment-standards.md`

## Residual gates

- Collect representative provider payload samples without secrets.
- Build actual `database/ddl/projects/prop4you` package.
- Add lab proof script for Prop4You package.
- Validate comments/catalog checks against real DDL.
- Browser/runtime proof for any user-facing flow remains future work.
