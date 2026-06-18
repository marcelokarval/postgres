# PRD — LFG readiness audit: system x DDL x JSON

Status: active

## Problem

The LFG database-centric package has SourceHub/Matrix/LeadFinder/LFG staging/materialization/feedback gates, but it is not yet proven complete against the legacy Django `system` model and the available JSON corpus. Moving to `prop4you_user_workspace` before this comparison risks building workspace contracts over an incomplete LFG baseline.

## Goal

Produce a persisted, evidence-based readiness audit that compares:

1. Legacy Django system boundaries/models/contracts.
2. Current PG18 DDL objects and semantics.
3. Available REIQ JSON corpus/path evidence.

The output must identify coverage, gaps, decisions, and the correct next slice.

## Required outputs

- legacy system inventory, redacted/no PII;
- DDL inventory, schema/table/function/view oriented;
- JSON/path inventory, key/path counts only, no values;
- system x DDL x JSON matrix;
- readiness verdict: ready / not ready / ready-with-gaps;
- next slice recommendation.

## Acceptance criteria

- PRD/tasks/ledger persisted.
- At most 3 subagents used with file+terminal only.
- Worker artifacts read and reviewed by Thor.
- Matrix artifact persisted under this issue stack.
- Browser-proof + vision QA pass.
- Final report compares requested vs delivered and lists next steps/questions.
