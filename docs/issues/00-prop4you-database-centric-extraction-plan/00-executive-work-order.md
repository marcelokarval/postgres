# Executive Work Order — Prop4You database-centric extraction plan

Status: started
Created: 2026-06-15T00:37:25
Owner: Thor/default as orchestrator and final reviewer
Scope type: repo-local documentation/specification/planning with static/browser proof

## Objective

Turn the Prop4You Inertia backend inventory plus Karval's new guidance into a complete, persisted, executable database-centric extraction plan for future DDL implementation.

## User additions incorporated

- The `system`/Matrix group that composes LeadFinder will be naturally revised.
- Current apps were not created from deep comparison of third-party payload contracts such as Realtor.com, DirectSkip/skip trace, and other providers.
- Many DDLs are expected to mutate as canonical dictionaries improve.
- JSONB is a first-class substrate: raw payloads, provider payloads, own captured payloads, generated/projected fields from JSONB paths, expression indexes, JSON_TABLE and PG18 JSON improvements should guide table design.
- Matrix <-> SourceHub <-> LeadFinder must be redesigned through broad comparison and canonical dictionary work before final table contracts are frozen.
- DDLs must contain clear, objective, documentary comments.
- Thor is orchestrator/reviewer; subagents are bounded workers only.

## Scope

Create durable artifacts under this issue stack:

- PRD
- executable task plan
- execution ledger
- subagent manifest
- source/payload strategy
- DDL extraction plan
- review matrices
- browser proof of docs rendering
- final report with next steps/questions

## Out of scope

- No production mutation.
- No live Prop4You runtime deploy.
- No creation of final Prop4You DDL package yet.
- No direct provider API calls or secrets usage.
- No schema migration against product/prod data.

## Validation

- Static artifact existence and content checks.
- Parent/orchestrator review of subagent outputs.
- Repo diff check.
- Browser render proof of the persisted report/HTML artifact with screenshot/vision.
- Final requested-vs-delivered matrix.

## Stop condition

Closed when artifacts exist, tasks are marked delivered after review, browser-proof is captured, final report is persisted, canonical docs index references the stack, and no background/subagent process remains unaccounted.
