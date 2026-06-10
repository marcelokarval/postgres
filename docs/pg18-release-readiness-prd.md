# PRD — PG18 Local Release-Readiness, Documentation Realignment, and Database-Centric Next Slice

## 1. Executive objective

Advance the PostgreSQL 18 Supabase/Postgres fork from a locally accepted full-parity image into a local release-readiness lane suitable for preparing a fork release and repeatable Docker image generation.

This slice must also realign documentation, especially `README.md`, with the actual current state: PostgreSQL 18 is no longer just bootstrap/WIP in this fork; it is a locally accepted database-image slice with documented limits.

A separate forward-looking PRD must define the next database-centric proof: PostgREST gateway first, no Django in this round, and a simple web client as the first consumer.

## 2. User decisions captured

1. `supautils` and `plan_filter`: parity only for now, not active enforcement.
2. Current priority: local tests and documentation to become confident the fork is ready to generate a release and Docker image build path.
3. Gateway for next database-centric work: PostgREST only; Django is a later dedicated round.
4. First client for the database-centric proof: web, because it is fastest; simple API-driven page, compatible with a future reui.io-style UI.

## 3. In scope

- Persist this PRD and a detailed task ledger.
- Run local release-readiness gates that are safe on this host.
- Keep the already accepted runtime anchor:
  - image ID `sha256:576f2d7cb01fdd0dacd37679eb37100e3da37102c536ecb3ed39173cdd39e9e3`
  - service `postgres18_postgres`
  - preload `pg_stat_statements, pgaudit, pg_cron, pg_net, pg_tle, safeupdate`
- Execute or validate the existing scripts:
  - `scripts/pg18-runtime-status.sh`
  - `scripts/smoke-pg18-full-parity.sh`
  - `scripts/promote-pg18-stack.sh --skip-update`
  - `scripts/validate-pg18.sh --skip-docker-test`
- Realign `README.md` for PG18 local release-readiness and remove stale/WIP claims.
- Persist a parity contract document for `supautils` and `plan_filter`.
- Persist a PostgREST/web database-centric PRD as the next implementation slice.
- Browser-proof the final docs locally and inspect with vision.
- Run independent reviews and correct issues without HITL.
- Commit the slice locally.

## 4. Out of scope

- Publishing a remote release or pushing to a registry.
- Mutating production/VPS infrastructure.
- Enabling `supautils`/`plan_filter` enforcement semantics.
- Implementing the PostgREST gateway and web app in this slice.
- Django gateway implementation.
- Full Supabase platform stack parity.

## 5. Acceptance criteria

### AC-1 — Runtime truth remains valid

The live stack must still validate:

- `postgres18_postgres` is `1/1` and healthy.
- live container image ID equals the accepted image ID.
- PostgreSQL reports `18.0`.
- required preload matches exactly.
- extension matrix and library-only surfaces pass `scripts/pg18-runtime-status.sh`.

### AC-2 — Local release-readiness gates pass or are honestly bounded

Required local gates:

- script syntax checks pass;
- `scripts/pg18-runtime-status.sh` passes;
- `scripts/smoke-pg18-full-parity.sh --image local/supabase-postgres:18-karval-full` passes;
- `scripts/promote-pg18-stack.sh --skip-update` passes;
- `scripts/validate-pg18.sh --skip-docker-test --image-tag local/supabase-postgres:18-karval-validation` completes or produces persisted failure evidence and triage.

The full `docker-image-test` and clean runner validation may remain a next gate if not completed locally in this slice.

### AC-3 — README reflects current PG18 reality

`README.md` must clearly distinguish:

- upstream Supabase/Postgres baseline;
- this fork's PG18 local accepted image path;
- build commands;
- validation commands;
- local release/promotion commands;
- extension/runtime contract model;
- limits and non-claims.

### AC-4 — Parity contracts are explicit

`docs/pg18-parity-contracts.md` must state:

- `safeupdate` is preload-only and behavior-proven;
- `supautils` is a library/config parity surface, not active enforcement in this slice;
- `plan_filter` is a library/config parity surface, not active enforcement in this slice;
- future activation requires separate behavioral tests.

### AC-5 — Database-centric next PRD exists

`docs/pg18-database-centric-postgrest-web-prd.md` must define the next slice:

- PostgREST as gateway;
- web client first;
- Django out of scope;
- database owns business logic;
- RLS/RPC/views/contracts;
- acceptance gates for HTTP, RLS, RPC and browser proof.

### AC-6 — Browser-proof exists

A local static report must be served, opened in browser, console checked, visually inspected, and evidence persisted.

### AC-7 — Reviews and final report exist

Persist:

- task review matrix;
- final requested-vs-delivered report;
- residual risks and next steps;
- commit evidence.

## 6. Release-readiness classification

This slice can classify the fork as:

- `LOCAL_RELEASE_READINESS_PASS`: local gates pass, docs aligned, and build path is repeatable on this host.
- `LOCAL_RELEASE_READINESS_WARN`: local runtime/smoke pass but a heavier gate remains pending or failed with bounded triage.
- `BLOCKED`: a required local gate fails without triage or a runtime anchor breaks.

## 7. Risks

| Risk | Handling |
|---|---|
| README overclaims production readiness | Rewrite with local-release wording and explicit non-claims. |
| `supautils`/`plan_filter` confused as active enforcement | Document parity-only contract. |
| Docker build path relies on local cache | Run `validate-pg18.sh --skip-docker-test`; keep clean runner as next gate if needed. |
| Browser-proof server becomes stale/down | Start agent-owned static server, verify HTTP before browser, kill after proof. |
| Subagent self-report overtrusted | Use subagents only for read-only/review lanes; parent reruns decisive gates. |
