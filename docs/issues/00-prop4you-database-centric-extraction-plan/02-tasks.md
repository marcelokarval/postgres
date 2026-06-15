# Tasks — Prop4You database-centric extraction plan

| ID | Task | Owner | Status | Target artifacts | Validation | Review |
| --- | --- | --- | --- | --- | --- | --- |
| T1 | Persist executive work order, PRD, task plan, and ledger scaffold | Thor | delivered | 00,01,02,03 | files exist and contain scope/acceptance | Thor |
| T2 | Produce/source-review JSONB and provider payload strategy | Subagent A + Thor | delivered | 08-jsonb-provider-payload-strategy.md | strategy covers raw JSON, canonical projection, generated fields, lineage | Thor side-by-side |
| T3 | Produce Matrix/SourceHub/LeadFinder canonical dictionary plan | Subagent B + Thor | delivered | 09-matrix-sourcehub-leadfinder-canonical-dictionary.md | plan covers comparison workflow, dictionary lifecycle, DTO/payload contracts | Thor side-by-side |
| T4 | Produce DDL extraction order and comment/documentation standards | Subagent C + Thor | delivered | 10-ddl-extraction-and-comment-standards.md | extraction order + SQL comment standard + mutation policy | Thor side-by-side |
| T5 | Synthesize executive plan and update canonical references | Thor | delivered | 11-executive-synthesis.md, docs/canonical-docs-index.md | artifact references and no stale contradictions | Thor |
| T6 | Review each task requested vs delivered and correct gaps | Thor | delivered | 05-task-review.md | all tasks PASS or explicit residual gate | Thor |
| T7 | Browser-proof and vision QA of rendered report | Thor | delivered | 06-browser-proof.md, 08-browser-render.html, screenshot | server health, browser screenshot/vision, console check | Thor |
| T8 | Final report, next steps, and task closure | Thor | delivered | 07-final-report.md, 02-tasks.md | final requested-vs-delivered matrix and next questions | Thor |

## Side-effect policy

Subagents may only edit files inside this issue stack unless explicitly directed otherwise. They may read source/docs. They must not mutate production/runtime, secrets, Hermes skills, Docker stacks, or external systems.
