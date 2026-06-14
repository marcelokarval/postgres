# Database DDL Packages

This directory contains versioned SQL packages that are installed into a running PG18 base database/stack.

The DDL packages are intentionally separate from the compiled PG18 image.


## Modeling rule

All DDL packages follow the database-centric soft-DDD rule:

```text
schemas = domains / bounded contexts
tables = durable domain records
functions/RPCs = use cases
views = projections
policies = authorization rules
api = public facade
```

Canonical rule doc: `docs/database-centric-soft-ddd-rule.md`.

## Layers

```text
base/                  shared DDL primitives reusable by projects
projects/prop4you/     Prop4You-specific database-centric DDL package
```

## File naming

Use numeric order:

```text
0001_name.sql
0002_name.sql
0003_name.sql
```

Rules:

- Each file must have a clear purpose.
- Prefer idempotent DDL where reasonable.
- Destructive DDL must be explicit and isolated.
- Do not hide order in shell globs without numeric prefixes.
- Keep base DDL independent from project DDL.
- Project DDL may depend on base DDL.

## Install state

A future base installer should track applied files with filename and checksum in a database table such as `private.ddl_migrations`.

Until that installer exists, this directory is the canonical source structure for DDL sequencing.

## Framework extraction rule

Do not create a canonical `platform/django` package. When extracting rules from Django-era projects, convert them into framework-agnostic database-centric primitives in `base/` or future capability-named packages. Django, FastAPI, Kong and PostgREST are consumers/transports.
