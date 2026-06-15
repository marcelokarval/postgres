# PRD — Prop4You database-centric extraction methodology and execution plan

Status: draft
Owner: Thor/default

## Problem

Prop4You currently has Django/Inertia domain apps, system apps, public facades, and integration logic evolved around Python models/services. The PG18 database-centric project needs a governed plan for extracting business rules into DDL packages without freezing current Django artifacts as final truth prematurely.

The current Django apps are useful evidence, but not final canonical design because many were not created from full provider payload contract analysis. Provider JSON payloads from Realtor.com, DirectSkip/skip trace, SourceHub flows, Matrix semantics, and internally captured JSON must be compared before deciding final durable tables and generated/projected fields.

## Goals

1. Define a database-centric extraction methodology for Prop4You that treats Django apps as evidence, not final truth.
2. Establish JSONB-first modeling for provider/internal payloads.
3. Define how generated/projected columns from JSONB paths should be used when fields become stable canonical access paths.
4. Formalize Matrix <-> SourceHub <-> LeadFinder as a canonical dictionary and semantic comparison pipeline before final DDL freeze.
5. Define DDL comment/documentation requirements.
6. Produce a task plan for future implementation against `pg18_ddl_lab`.
7. Persist all artifacts in the canonical docs stack.

## Non-goals

- Implement final Prop4You DDL tables now.
- Call third-party provider APIs now.
- Deploy or mutate production.
- Replace all Django behavior in one step.
- Claim runtime/product completeness beyond repo-local/static proof.

## Current evidence

Primary prior report:

```text
docs/reports/prop4you-inertia-app-inventory-and-extraction-order.md
```

Active PG18 base substrate:

```text
database/ddl/base/
docs/database-centric-app-model.md
docs/pg18-multidb-cron-policy.md
docs/reports/pg18-ddl-base-lab-proof.md
```

Prop4You backend source analyzed:

```text
/home/marcelo-karval/Backup/Projetos/prop4you/prop4you-inertia/backend/src
```

## Product assumptions

- UUID7/public refs reduce physical coupling, but semantic dependency still matters.
- Provider payload JSON should be preserved raw with lineage before being projected into canonical fields.
- Generated/projected fields from JSONB paths should be used only for stable, frequently queried, semantically named paths.
- Matrix should govern semantic meaning and canonical dictionary, not just hold ad hoc DTOs.
- SourceHub owns ingress/lineage/handoff boundaries.
- LeadFinder consumes canonical property/owner/lead semantics, not provider-specific raw payloads directly.

## Acceptance criteria

- PRD persisted.
- Tasks persisted with status and review target.
- Execution ledger persisted.
- Subagent outputs reviewed by Thor.
- Report defines all active Prop4You apps/surfaces and extraction order.
- Report includes JSONB/provider payload strategy.
- Report defines generated/projected field strategy.
- Report defines DDL comment standards.
- Browser-proof confirms report rendering artifact is accessible locally.
- Final report compares requested vs delivered side-by-side.
- Canonical docs index references the new issue stack.

## Risks

- Static analysis may miss dynamic runtime behavior.
- Provider payload contracts are not yet fully harvested.
- Some Matrix files are Pydantic/TypedDict contracts, not durable Django models.
- Browser proof of static docs does not prove production runtime.
- DDL implementation must be validated later in `pg18_ddl_lab`.
