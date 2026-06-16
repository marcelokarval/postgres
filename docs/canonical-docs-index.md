# PG18 Database-Centric Platform — Canonical Docs Index

Status: ACTIVE_INDEX
Date: 2026-06-13
Purpose: make the project knowledge map explicit for Thor/Hermes, humans and non-Hermes agents.

## 1. Start here

Read these first:

1. `AGENTS.md` — live agent entrypoint and operational guardrails.
2. `README.md` — human entrypoint and current status.
3. `llms.txt` — concise LLM/agent discovery context.
4. `llms-full.txt` — full LLM/agent context packet.
5. `docs/canonical-docs-index.md` — this documentation map.

## 2. Release identity

Current pure PG18 release:

- `docs/releases/18.0.0.001-karval-pure-rc1.md`
- GitHub release: `18.0.0.001-karval-pure-rc1`
- Registry digest: `sha256:c477d5146ea51f235b811c093363c3ed5d8a342dbed8efac7635a1b9779e2f9f`

Meaning of pure:

- PG18 image/stack base only.
- No Prop4You/project DDL installed.
- No Strapi database.
- No production/VPS claim.

## 3. PG18 image/build/acceptance docs

Use these for image, extension, Nix, Docker, KVM and RC acceptance truth:

- `docs/pg18-full-parity-final-report.md`
- `docs/pg18-full-parity-acceptance.md`
- `docs/pg18-full-parity-prd.md`
- `docs/pg18-release-readiness-prd.md`
- `docs/pg18-release-readiness-final-report.md`
- `docs/pg18-rc-publish-postgrest-rls-final-report.md`
- `docs/pg18-rc-publish-postgrest-rls-task-reviews.md`

## 4. Realtime and PostgREST proof docs

Use these for database-centric API/realtime behavior:

- `docs/pg18-realtime-websocket-architecture.md`
- `docs/pg18-realtime-v2-llms-prd.md`
- `docs/pg18-realtime-v2-llms-tasks.md`
- `docs/pg18-realtime-v2-llms-task-reviews.md`
- `docs/pg18-realtime-v2-llms-final-report.md`
- `docs/pg18-realtime-v2-llms-browser-proof.html`

Runtime proof command:

```bash
scripts/smoke-pg18-realtime-v2.sh --keep-stack
```

HTML proof URL when running:

```text
http://127.0.0.1:18083/
```

## 5. Database-centric DDL and modeling docs

Use these for DDL package strategy, Application Data Kernel context, Prop4You extraction and soft-DDD rules:

- `docs/pg18-application-data-kernel-context.md`
- `docs/prop4you-database-centric-base-extraction.md`
- `docs/prop4you-core-db-to-ddl-analysis.md`
- `docs/pg18-database-centric-ddl-strategy.md`
- `docs/database-centric-soft-ddd-rule.md`
- `database/ddl/README.md`
- `database/ddl/base/README.md`
- `database/ddl/projects/prop4you/README.md`

Core rule:

```text
schemas = domains / bounded contexts
tables = durable domain records
functions/RPCs = use cases
views = projections
policies = authorization
triggers/jobs = automation
api = public facade
```

## 6. Runtime log / operational diagnosis docs

Use before acting on noisy local runtime logs:

- `docs/pg18-runtime-log-analysis.md`
- `docs/pg18-ddl-strategy-log-analysis-final-report.md`

Known diagnosis:

- `postgres@strapi` noise came from a Strapi Swarm service using ambiguous DB host `postgres` on a shared network.
- `supabase_admin` is an expected image/bootstrap/admin role, not a project app role or table.
- `safeupdate_probe` is a smoke table for preload hook validation; `UPDATE requires a WHERE clause` is expected pass behavior.

## 7. Release notes

- `docs/releases/18.0.0.001-karval-pure-rc1.md`

Future release notes should go under:

```text
docs/releases/<version>.md
```

## 8. Current next work queue

Recommended next slices:

1. DDL installer + base install tracking.
2. Prop4You inherited Django/script inventory.
3. Prop4You minimal DDL package.
4. Project-specific HTML proof after DDL package behavior exists.

## 9. Agent rule

Hermes/Thor and other agents must not rely on memory alone. Before mutating this repository, read:

```text
AGENTS.md
README.md
llms.txt
llms-full.txt
docs/canonical-docs-index.md
```

Then read the domain-specific doc for the task.

## DDL installer active slice

- `docs/ddl-installer-prd.md` — active PRD for the DDL installer/base substrate slice.
- `docs/ddl-installer-tasks.md` — active task ledger for the DDL installer/base substrate slice.


## DDL installer delivered slice

- `docs/reports/base-ddl-deep-scan-and-pgaudit-notes.md` — follow-up rescan confirming public_id prefix registry, 16/16 base DDL scope check, full uuid7 public refs, and pgAudit comparison notes.
- `docs/ddl-installer-prd.md` — PRD for the executable base DDL installer slice.
- `docs/ddl-installer-tasks.md` — task ledger and execution evidence for the slice.
- `docs/reviews/ddl-installer-task-review.md` — task-by-task requested-vs-delivered review.
- `docs/reviews/ddl-installer-final-review.md` — final acceptance review.
- `docs/reviews/ddl-installer-architecture-rereview.md` — architecture PASS after implementation/fixes.
- `docs/proofs/ddl-installer-browser-proof.html` — local static browser-proof artifact.
- `docs/proofs/ddl-installer-browser-proof.md` — browser/console/vision QA notes.
- `docs/reports/ddl-installer-final-report.md` — final persisted closeout report.
## Portainer/pgAdmin parity for PG18

- `docs/pg18-portainer-pgadmin-prd.md` — PRD for local Portainer-managed postgres18 parity and pgAdmin access.
- `docs/pg18-portainer-pgadmin-tasks.md` — task ledger for the Portainer/pgAdmin parity slice.
- `docs/reports/pg18-postgres-stack-parity-review.md` — side-by-side postgres vs postgres18 stack comparison and risks.
- `docs/reports/pg18-portainer-pgadmin-final-report.md` — final runtime evidence and requested-vs-delivered report.
- `docker/postgres18.portainer.stack.yml` — secret-free canonical Portainer stack file for local postgres18.
## DDL base live lab proof

- `scripts/proof-ddl-base-lab.sh` — re-runnable lab proof: clean DB, extensions, DDL base apply/reapply and functional tests.
- `docs/reports/pg18-ddl-base-lab-proof.md` — latest evidence for `pg18_ddl_lab` on local postgres18 Swarm.
- `docs/pg18-multidb-cron-policy.md` — active pg_cron policy: `postgres` as central scheduler with `cron.schedule_in_database(...)` for product DBs.
- `README.md`, `AGENTS.md`, `llms.txt`, `llms-full.txt` — database-centric documentation discipline: implementation changes must update relevant docs in the same cycle.
- `docs/database-centric-app-model.md` — canonical methodology for database-centric apps/modules, Django BaseModel-to-DDL contract translation, Prop4You examples, and app completion checklist.
- `docs/reports/prop4you-inertia-app-inventory-and-extraction-order.md` — static inventory of Prop4You Inertia backend apps/models/dependencies and recommended database-centric business-rule extraction order.
- `docs/issues/00-prop4you-database-centric-extraction-plan/` — PRD/task/review/browser-proof stack for Prop4You database-centric extraction, JSONB provider payload strategy, Matrix/SourceHub/LeadFinder dictionary plan, and DDL comment standards.
- `docs/issues/01-prop4you-provider-payload-corpus/` — provider payload corpus PRD/tasks/review stack for REIQ, DirectSkip, Realtor.com and internal payload side-by-side comparison before Prop4You DDL freeze.
- `docs/issues/02-prop4you-sourcehub-matrix-ddl/` — PRD/tasks/review stack for first experimental Prop4You provider registry, SourceHub corpus/enrichment queue, Matrix semantic dictionary DDL and lab proof.
- `docs/reports/prop4you-sourcehub-matrix-ddl-lab-proof.md` — lab proof applying base + Prop4You provider/sourcehub/matrix experimental DDL in a clean PG18 lab DB.
- `docs/issues/03-prop4you-leadfinder-canonical-cycle-analysis/` — analysis correcting Matrix/SourceHub/LeadFinder ownership: LeadFinder generates canonical dictionary; Matrix produces transformation artifacts; SourceHub translates raw into LeadFinder-consumable DTOs.
- `docs/issues/04-prop4you-leadfinder-dictionary-from-raws/` — PRD/tasks/review stack implementing LeadFinder-owned canonical dictionary v0 born from raw/code/baseline evidence and reclassifying Matrix canonical tables as mirror/candidate review.
- `database/ddl/projects/prop4you/leadfinder/0001_canonical_dictionary.sql` — experimental LeadFinder dictionary v0 with 15 family candidates and 36 field candidates.
