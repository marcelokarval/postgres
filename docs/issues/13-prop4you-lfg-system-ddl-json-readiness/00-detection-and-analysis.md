# Detection and Analysis — LFG system x DDL x JSON readiness

Status: active
Created: 2026-06-18T13:11:05
Reviewer: Thor/default

## User correction

Do not move directly to `prop4you_user_workspace` yet. First prove whether LFG is ready by comparing:

```text
legacy Django system model/boundaries
x current PG18 DDLs
x available JSON corpus/path evidence
```

## Decisions carried forward

```text
workspace schema: prop4you_user_workspace
LFG/system schema: prop4you_leadfinder_group
tags/labels vocabulary: LFG vocabulary should be reusable by users
tags/labels grouping: future user-created tags should belong to groups/contexts, similar to REISift/start-tag style
auto-apply: low-risk global markers may auto-apply after configured multi-user/workspace threshold
snapshot details: deferred until LFG readiness audit closes
Thor HTTP endpoint: future roadmap only
```

## Evidence roots

```text
legacy system root: /home/marcelo-karval/Backup/Projetos/prop4you/prop4you-inertia/backend/src
JSON corpus focus: /home/marcelo-karval/Backup/Projetos/prop4you/prop4you-inertia/backend/src/apps/system/matrix/registry/reiq/loan_modification/fl
PG18 DDL root: /home/marcelo-karval/Backup/Projetos/supabase-postgres-18-fork/postgres/database/ddl/projects/prop4you
```

## Non-goals

- no raw JSON dumps;
- no PII values;
- no production/database mutation beyond existing local lab if needed;
- no workspace DDL implementation;
- no provider calls;
- no Thor HTTP endpoint.
