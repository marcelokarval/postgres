# PRD — LFG canonical JSONSchema envelopes + projection policy registry

Status: active

## Problem

The JSONB-first rules are documented in prose, but future DDL work needs a stronger automatic contract: files and registry rows that define canonical JSON envelopes, projection decisions, and the rule set for when JSON remains JSONB versus when it becomes relational projection.

## Goal

Implement a repo-local, PG18-friendly minimum registry for LFG canonical JSONSchema envelopes and projection policy.

## Deliverables

1. JSONSchema files under `docs/schemas/prop4you/lfg/`:
   - `property-envelope.v1.schema.json`
   - `owner-envelope.v1.schema.json`
   - `contact-satellites-envelope.v1.schema.json`
   - `realtor-evidence-envelope.v1.schema.json`
   - `taxonomy-envelope.v1.schema.json`
   - `lfg-canonical-envelope-index.v1.schema.json`
2. Projection policy artifact:
   - `projection-policy.v1.json`
3. DDL registry:
   - `database/ddl/projects/prop4you/leadfinder_group/0005_canonical_jsonschema_registry.sql`
4. Proof script:
   - `scripts/proof-prop4you-lfg-jsonschema-registry.sh`
5. Persisted PRD/tasks/reviews/browser-proof/final report.
6. Skill update so future tasks automatically know this gate exists.

## Acceptance criteria

- JSON files parse with Python stdlib.
- JSONSchema files have `$schema`, `$id`, `title`, `type`, `additionalProperties` policy.
- Projection policy contains the 7 promotion gates and default low-risk marker auto-apply policy.
- DDL applies in PG18 lab proof.
- Registry rows are queryable after DDL apply.
- No raw payload values or PII.
- Browser-proof + vision pass.
