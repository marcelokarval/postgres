# Task Review — Matrix artifacts + REIQ raw corpus

Status: delivered
Updated: 2026-06-16T15:36:33
Reviewer: Thor/default

| Task | Requested | Delivered | Evidence | Verdict |
| --- | --- | --- | --- | --- |
| T1 | Create PRD/tasks/ledger stack | Stack 05 created | `00-04` | PASS |
| T2 | Discover and inventory REIQ raw corpus safely | 98 REIQ JSONs total, 97 FL focus; no PII/raw dumps | `08-reiq-raw-corpus-inventory.md` | PASS |
| T3 | Implement Matrix mapping_sessions/transformation_artifacts DDL | 3 new Matrix artifact tables with LeadFinder dictionary FKs | `matrix/0002_mapping_sessions.sql`; `09-matrix-artifact-ddl-review.md` | PASS |
| T4 | Design SourceHub translated DTO publication readiness | Contract doc and SourceHub README update | `10-sourcehub-translated-dto-readiness.md` | PASS |
| T5 | Add raw JSONB lab ingestion script | Script dry-run + execute mode; dry-run PASS; lab execute inserted 97 | `scripts/ingest-prop4you-reiq-raws-lab.py` | PASS |
| T6 | Run PG18 lab proof and active corrections | DDL proof PASS; ingestion script corrected for `class_key`, SQL CTE cross join, and apply order | `docs/reports/prop4you-sourcehub-matrix-ddl-lab-proof.md`; `/tmp/reiq-ingest-execute.out` | PASS |
| T7 | Browser-proof + vision QA | Static browser proof rendered expected title/badges/content; console clean; vision PASS | `06-browser-proof.md`; `08-browser-render.html` | PASS |
| T8 | Final report/commit/push | Final report persisted; commit/push completed in final gate | `07-final-report.md` | PASS after commit |

## Requested vs delivered

| User request | Delivered |
| --- | --- |
| Siga recomendação: Matrix artifacts primeiro | Implemented Matrix `0002_mapping_sessions.sql` |
| Temos centenas/muitos raw REIQ para usar | Inventory covered 98/97 JSONs and lab ingestion inserted 97 focused files |
| Manter candidates até extractor | No LeadFinder candidate promoted; artifacts remain review-gated |
| Orchestration with subagents | 3 lanes used; B/C timed out after writing artifacts/status; parent verified artifacts and proof |
| Browser proof + final report | Browser proof completed; final report persisted |

## Active corrections

- Fixed proof apply order: LeadFinder dictionary must apply before Matrix 0002.
- Fixed ingestion script `payload_class_key` -> `class_key`.
- Fixed generated SQL to cross join provider/payload_class CTEs outside `VALUES`.
- Reduced psql noise with `-q` while preserving `ON_ERROR_STOP`.
