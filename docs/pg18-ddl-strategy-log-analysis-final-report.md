# PG18 DDL Strategy + Runtime Log Analysis — Final Report

Date: 2026-06-12
Status: DELIVERED_PASS
Owner/governor: Thor/default

## 1. User decision applied

Karval answered the open next-step questions with: do what is most correct now.

Decision applied:

- Keep HTML/browser proof as the current proof surface.
- Do not move to desktop/mobile proof now.
- Make `llms.txt`/`llms-full.txt` clear for Hermes, but portable for non-Hermes agents.
- Keep PG18 base image/stack separate from project DDLs.
- Use Prop4You as the first real project case for future DDL packages, but do not bake Prop4You into the PG18 image.
- Use ordered, versioned `.sql` files for base/project DDL install control.
- Investigate noisy Postgres logs before mutating runtime.

## 2. What was delivered

### Documentation

Created:

```text
docs/pg18-database-centric-ddl-strategy.md
docs/pg18-runtime-log-analysis.md
docs/pg18-ddl-strategy-log-analysis-final-report.md
```

Updated:

```text
README.md
llms.txt
llms-full.txt
```

### DDL structure

Created:

```text
database/ddl/README.md
database/ddl/base/README.md
database/ddl/projects/prop4you/README.md
```

This establishes the versioned SQL convention without installing project schemas yet.

### Deterministic smoke

Created:

```text
scripts/smoke-pg18-realtime-v2.sh
```

The script proves:

- clean compose startup;
- current-profile JWT/RLS;
- `api.can_subscribe` true/false;
- anon RPC denial;
- live WebSocket event;
- replay with `acked_at`;
- denied subscription;
- invalid token;
- durable ACK read-back.

Run executed:

```bash
scripts/smoke-pg18-realtime-v2.sh --keep-stack --log-dir tmp/pg18-realtime-v2-smoke-live
```

Result:

```text
PG18 realtime v2 smoke PASS
html_url=http://127.0.0.1:18083/
keep_stack=true
```

The HTML proof was intentionally left running for human inspection.

## 3. Runtime log findings

### 3.1 Why `strapi` appears

Evidence from live Docker Swarm:

```text
service: strapi_strapi
image: elestio/strapi-development:latest
dbhost: postgres
dbname: strapi
dbuser: postgres
dbport: 5432
```

Inside the Strapi container:

```text
postgres -> 10.0.1.28
postgres -> 10.0.1.112
postgres18_postgres -> 10.0.1.112
postgres_postgres -> 10.0.1.28
```

Swarm VIP mapping:

```text
postgres_postgres   -> 10.0.1.28
postgres18_postgres -> 10.0.1.112
```

Conclusion:

The repeated lines:

```text
postgres@strapi FATAL: database "strapi" does not exist
```

come from the running Strapi service configured to connect to database `strapi` on host `postgres`. Because `postgres` resolves ambiguously to both PG17 and PG18 services, PG18 receives some of those attempts.

This is not caused by the PG18 realtime proof.

Correct action:

- Do not create `strapi` database inside PG18 unless Strapi is intentionally scoped to PG18.
- If Strapi belongs to PG17, point it explicitly to `postgres_postgres`.
- If Strapi belongs to PG18, point it explicitly to `postgres18_postgres` and install/manage the `strapi` DB intentionally.
- Avoid generic DNS name `postgres` on shared Swarm networks with multiple Postgres services.

### 3.2 Why `supabase_admin` appears

`supabase_admin` is an expected database role from the Supabase/Postgres image recipe.

Evidence:

```text
Dockerfile-18 sets POSTGRES_USER=supabase_admin
Smoke scripts use psql -U supabase_admin -d postgres
```

Conclusion:

`supabase_admin` is not a table. It is an image/admin/bootstrap role used for validation and maintenance. It should not be used as a project application user.

### 3.3 Why `safeupdate_probe` appears

`safeupdate_probe` is a smoke-test table for the preload-only `safeupdate` hook.

Expected/pass behavior:

```text
UPDATE requires a WHERE clause
```

This proves unsafe updates without WHERE are blocked.

The noisy variant:

```text
relation "public.safeupdate_probe" does not exist
```

means an older/non-deterministic probe attempted to use the table before/after creation. The correction is deterministic smoke sequencing, not removing the safeupdate test.

## 4. Database-centric layering now documented

The architecture is now explicitly documented as:

```text
Layer 0 — PG18 image/build recipe
Layer 1 — Optional sibling stack services: PostgREST, realtime, web proof, future workers
Layer 2 — Shared base DDL package
Layer 3 — Project DDL package, initially Prop4You
Layer 4 — Optional seed/reference data package
```

The key rule:

```text
The base image/stack is reusable runtime infrastructure.
Project DDLs are installed later as ordered SQL packages.
```

## 5. Proof evidence

Static/script gate:

```text
bash -n scripts/smoke-pg18-realtime-v2.sh -> PASS
```

Runtime smoke:

```text
PG18 realtime v2 smoke PASS
```

Browser access:

```text
http://127.0.0.1:18083/
Title: PG18 RLS + Realtime v2 Web Proof
Replay events: 1
User: user_karval_demo
Postgres: 18.0
```

## 6. Not claimed

- No Strapi service mutation was made.
- No `strapi` database was created.
- No Prop4You DDL was installed yet.
- No production/VPS deployment claim.
- No desktop/mobile proof.
- No Redis/NATS addition.

## 7. Recommended next steps

1. Inventory inherited Prop4You SQL/scripts.
2. Classify them into:
   - shared base DDL;
   - Prop4You project DDL;
   - seeds/reference data;
   - deprecated/manual-only scripts.
3. Create the first real ordered SQL package under `database/ddl/projects/prop4you/`.
4. Add an installer script that applies ordered `.sql` files and records filename/checksum.
5. Add project-specific HTML proof only after the Prop4You DDL package has a minimal working contract.
6. Fix the live Strapi DNS/config separately if Strapi should remain active:
   - choose explicit PG17 or PG18 target;
   - avoid generic `postgres` hostname.

## 8. Final verdict

DELIVERED_PASS for the correct immediate step:

- architecture clarified;
- DDL layering persisted;
- log root causes identified with runtime evidence;
- deterministic realtime v2 smoke created and passed;
- HTML proof left accessible for inspection.
