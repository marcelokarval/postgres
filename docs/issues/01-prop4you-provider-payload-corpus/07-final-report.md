# Final Report — Prop4You provider payload corpus

Status: closed for repo-local/provider-corpus planning scope
Updated: 2026-06-15T01:17:11
Owner/reviewer: Thor/default

## Verdict

SUPPORTED for repo-local provider corpus planning, package skeleton, review, browser proof and static-contract closure.

NOT COMPLETE for final Prop4You DDL/runtime/provider implementation. This slice intentionally does not call providers, dump raw PII, freeze final tables or deploy runtime changes.

## User answers applied

| User answer | Applied decision |
| --- | --- |
| Analyze all providers side by side; main priority REIQ -> DirectSkip -> Realtor.com | Provider inventories and side-by-side matrix created for REIQ/base, DirectSkip/owner, Realtor/enrichment and internal payloads |
| DDL is for a separate system from postgres18 | Created `database/ddl/projects/prop4you/`, not base DDL/image changes |
| First DDL decision comes only after JSON comparison and canonical decision | No final tables frozen; only skeleton schemas/package created |
| Use package and subpackages | Created package and subpackage README skeletons |

## What was delivered

Issue stack:

```text
docs/issues/01-prop4you-provider-payload-corpus/
```

Files:

```text
00-detection-and-analysis.md
01-prd.md
02-tasks.md
03-execution-ledger.md
04-subagent-manifest.md
04-worklog.md
05-task-review.md
06-browser-proof.md
07-final-report.md
08-browser-render.html
08-reiq-payload-inventory.md
09-directskip-payload-inventory.md
10-realtor-internal-payload-inventory.md
11-side-by-side-provider-comparison.md
12-fixture-privacy-policy.md
```

DDL skeleton:

```text
database/ddl/projects/prop4you/README.md
database/ddl/projects/prop4you/0001_schemas.sql
database/ddl/projects/prop4you/sourcehub/README.md
database/ddl/projects/prop4you/matrix/README.md
database/ddl/projects/prop4you/leadfinder/README.md
database/ddl/projects/prop4you/providers/README.md
database/ddl/projects/prop4you/reiq/README.md
database/ddl/projects/prop4you/skiptrace/README.md
database/ddl/projects/prop4you/realtor/README.md
database/ddl/projects/prop4you/internal/README.md
database/ddl/projects/prop4you/identity/README.md
database/ddl/projects/prop4you/geography/README.md
database/ddl/projects/prop4you/property/README.md
database/ddl/projects/prop4you/owner/README.md
```

Proof script skeleton:

```text
scripts/proof-prop4you-ddl-lab.sh
```

Canonical docs updated:

```text
docs/canonical-docs-index.md
docs/database-centric-app-model.md
```

## Provider findings summary

### REIQ

Role:

```text
current/base data source
```

Local evidence showed:

- envelope variants: `$.data.result.*` and root flat payload;
- SourceHub producer support for `property.location`, `owners[]`, `ownerships[]`, `situations[]`, provenance and source facts;
- list types including pre_foreclosure, loan_modification, probates, eviction, tax_sale, appointment trustee, heirship, divorce;
- registry/corpus evidence exists mainly for REIQ Matrix lanes, with gaps for some raw local corpora.

DDL implication:

```text
REIQ is the likely base corpus for property/situation/valuation/legal source facts, but list_type must not auto-create canonical situation without Matrix dictionary approval.
```

### DirectSkip

Role:

```text
owner/contact enrichment source
```

Local evidence showed:

- request context mixes owner seed, property context, mailing context and tracking slots;
- raw response shape includes `input`, `status`, `result_code`, `contacts[]`, `names[]`, `phones[]`, `emails[]`, `confirmed_address[]`, `relatives[]`;
- current code already separates raw response, snapshots, SourceHub handoffs and owner-resolution evidence.

DDL implication:

```text
DirectSkip should create owner/contact evidence and candidate graph entries, not canonical owner truth by itself.
```

### Realtor.com

Role:

```text
broad property enrichment source
```

Local evidence showed:

- property identity/location paths;
- property details: beds, baths, sqft, year built, lot, property type/subtype;
- valuation/estimates/history/listing/media paths;
- SourceHub/Matrix pre-SourceHub DTO and internal product-originated payload support.

DDL implication:

```text
Realtor belongs primarily to enrichment/read-model/source-fact layers and requires an existing canonical property anchor or matching policy before materialization.
```

## Validations run

```text
Subagent artifacts/status reviewed: PASS
Required marker grep: PASS
Path-root drift detection/correction: PASS
Orphan cleanup: PASS
bash -n scripts/proof-prop4you-ddl-lab.sh: PASS
DRY_RUN=1 scripts/proof-prop4you-ddl-lab.sh: PASS
psql transaction rollback for 0001_schemas.sql in pg18_ddl_lab: PASS
Browser health: PASS
Browser console errors: 0
Vision QA: PASS
git diff --check: PASS before final commit gate
```

## Subagent monitoring and correction

Used 3 synchronous `delegate_task` workers with file+terminal only.

Workers completed. Because native `delegate_task` has no live ping while running, progress was verified through final artifacts and status files after return.

Correction applied:

- Worker B wrote one artifact and status files under parent path by mistake.
- Thor detected this with path inspection.
- Corrected by copying files into the correct repo path and removing orphan parent paths after verification.

No background subagent process remained.

## Browser proof

Persisted in:

```text
06-browser-proof.md
08-browser-render.html
```

Static browser proof passed with console clean and vision confirmation.

## Residual risks

- Representative real provider payload samples still need privacy-safe corpus construction.
- Current analysis is static and local; provider live contract drift is not proven.
- Some REIQ lanes have code/contract evidence but incomplete local raw corpus.
- DirectSkip/owner payloads are PII-heavy; raw fixture policy must be enforced before any repo fixture.
- Realtor arrays/estimates/history/media require further JSON_TABLE/staging proof before generated columns.
- Final DDL tables remain intentionally unimplemented.

## Next steps

1. Build a private provider corpus directory:

```text
~/.hermes/private/prop4you-provider-corpus/
  reiq/
  directskip/
  realtor/
  internal/
```

2. Generate sanitized summaries from that corpus, not raw dumps.
3. Implement first experimental DDL subpackage:

```text
database/ddl/projects/prop4you/sourcehub/
database/ddl/projects/prop4you/matrix/
```

4. Add safe JSONB coercion helpers before any generated JSONB-path columns.
5. Extend `scripts/proof-prop4you-ddl-lab.sh` from skeleton to actual clean lab proof once first experimental DDL exists.
6. Decide Matrix dictionary v0 fields for:
   - property identity/address
   - owner identity/contact
   - situation/legal timeline
   - valuation/financial
   - listing/history/media
7. Only after that, freeze the first canonical property/owner tables.

## Questions for next planning slice

1. Onde ficará o corpus privado oficial: `~/.hermes/private/prop4you-provider-corpus/` é aceitável ou prefere outro path canônico?
2. A primeira DDL experimental deve começar por `sourcehub.raw_record` + `matrix.semantic_dictionary`, correto?
3. Podemos criar fixtures sintéticas committed baseadas nos shapes observados, desde que 100% fake/redacted?
