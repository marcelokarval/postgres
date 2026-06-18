# PRD — LFG user feedback votes and promotion policy

Status: active

## Problem

We have T0-T5 database-centric flow and the system/LFG vs workspace boundary. The next risk is allowing user feedback like DNC, wrong phone, wrong email, or wrong mailing address to influence global LFG truth without a safe voting/review/apply policy.

## Goals

- Declare `prop4you_user_workspace` as the canonical logged-in workspace schema name.
- Store user feedback/votes in `prop4you_leadfinder_group` using weak relationships.
- Support item kinds: phone, email, mailing_address, owner, property, contact, group, facet, unknown.
- Support marker kinds: dnc, wrong, invalid, stale, corrected, verified, unreachable, deliverable, undeliverable, other.
- Aggregate votes into review rows with policy recommendation.
- Apply reviewed/global markers into LFG-owned marker table, not directly from a single user vote.
- Add LeadFinder dictionary promotion review/apply policy for prepared proposals.
- Keep gateway/runtime agnostic.
- Prove everything in PG18 lab.

## Non-goals

- No Thor/agent HTTP endpoint yet; roadmap only.
- No real provider calls.
- No real user identities; use weak text refs in lab.
- No full `prop4you_user_workspace` table model yet.
- No production mutation.

## Acceptance

- PRD/tasks/ledger persisted.
- 3 worker reviews persisted and independently reviewed.
- DDL applies cleanly in PG18 lab.
- Lab creates feedback votes, aggregate review, global marker apply, dictionary promotion apply.
- Browser-proof + vision confirms evidence.
- Final report compares requested vs delivered and lists next steps/questions.
