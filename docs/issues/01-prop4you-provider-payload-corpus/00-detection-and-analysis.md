# Detection and Analysis — Prop4You provider payload corpus

Status: started
Created: 2026-06-15T01:05:42
Owner: Thor/default as orchestrator and final reviewer

## Problem statement

Karval clarified that Prop4You DDL design must be decided only after side-by-side analysis of all relevant data JSONs/payload contracts, especially:

```text
REIQ       -> current/base data source
DirectSkip -> owner data source
Realtor.com -> broad enrichment source
```

The DDL is for a separate system layered on the PG18 stack, not the PG18 base image itself. Therefore this slice must define and prove the provider payload corpus methodology before freezing canonical Prop4You tables.

## Source of truth

Prior stack:

```text
docs/issues/00-prop4you-database-centric-extraction-plan/
```

Prop4You Inertia backend:

```text
/home/marcelo-karval/Backup/Projetos/prop4you/prop4you-inertia/backend/src
```

## Initial constraints

- No external provider API calls unless explicitly authorized later.
- No secrets or PII should be printed or committed.
- If fixtures are found, summarize shape/path inventory rather than dumping raw values.
- DDL implementation decision is deferred until provider/internal JSON comparison is complete.
- Package structure should be package + subpackages.
- Browser-proof here is static artifact proof, not runtime/provider proof.
