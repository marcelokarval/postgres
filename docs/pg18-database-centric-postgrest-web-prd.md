# PRD — Database-Centric PG18 Proof with PostgREST Gateway and Web Client

## 1. Goal

Build the next proof on top of the accepted PG18 image: a database-centric backend where PostgreSQL owns the business logic and PostgREST is the first gateway. The first client is a simple web page, compatible with a future reui.io-style UI.

## 2. Decisions

- Gateway: PostgREST only for this slice.
- Django: out of scope; later dedicated round.
- Client: web first because it is fastest to validate.
- `supautils`/`plan_filter`: parity-only; not required for the first product proof.

## 3. Architecture

```text
[Web client]
    |
    | HTTP/JSON
    v
[PostgREST]
    |
    | PostgreSQL role/JWT/session context
    v
[PostgreSQL 18 database-centric core]
  - schemas
  - tables
  - constraints
  - RLS policies
  - views
  - RPC functions
  - triggers/events
  - pgmq/pg_cron optional jobs
  - pgaudit/logging
```

## 4. Scope in

- Local Docker Compose or script-based stack for:
  - PG18 accepted image;
  - PostgREST;
  - simple static/dev web client.
- Database schemas:
  - `app` for internal tables;
  - `api` for stable exposed views/RPCs;
  - `audit` optional minimal event table.
- Minimal domain:
  - projects/tasks or equivalent simple work items.
- RLS:
  - own-row access;
  - anonymous read/mutation constraints;
  - authenticated mutation path.
- RPC examples:
  - `api.create_project(...)`;
  - `api.list_projects(...)` or view-backed list;
  - `api.create_task(...)`;
  - `api.complete_task(...)`.
- Web client:
  - list records from PostgREST;
  - create/update one record;
  - render authorization error cleanly;
  - no Django.

## 5. Scope out

- Production deploy.
- Remote registry publication.
- Full Supabase platform stack.
- GoTrue/auth server integration.
- Mobile/desktop clients.
- Django gateway.
- Active enforcement of `supautils`/`plan_filter`.

## 6. Acceptance criteria

### AC-1 — Runtime baseline

- Uses accepted PG18 image or a documented derivative.
- `scripts/pg18-runtime-status.sh` passes before starting the proof.

### AC-2 — Database migration

- A repeatable migration creates schemas, tables, grants, RLS and RPC functions.
- Re-run is idempotent or reset path is documented.

### AC-3 — PostgREST gateway

- PostgREST starts locally.
- Health endpoint responds.
- At least one table/view endpoint and one RPC endpoint work.
- Schema cache reload path is documented and tested.

### AC-4 — RLS proof

- Own-row read/write passes.
- Foreign-row access fails.
- Anonymous mutation fails unless explicitly allowed.
- RPC respects authorization claims.

### AC-5 — Web proof

- Browser opens web client.
- Page fetches real data through PostgREST.
- Page creates or updates a record through PostgREST.
- Browser console has no blocking JS errors.
- Vision confirms the UI renders the decisive state.

### AC-6 — Evidence

Persist:

- PRD;
- task ledger;
- SQL migration files;
- PostgREST config;
- web client files;
- smoke script;
- browser-proof evidence;
- final requested-vs-delivered report.

## 7. Recommended implementation order

1. Create local compose/script stack for PG18 + PostgREST.
2. Add database migration and seed.
3. Add HTTP smoke with `curl`.
4. Add simple web client.
5. Browser-proof web client.
6. Add reviews and final report.
