# Detection and Analysis — JSON curation + PG18 JSONB strategy

Status: active
Created: 2026-06-18T14:57:52
Reviewer: Thor/default

## User correction/adendo

The next slice should not immediately implement table-heavy LFG graph DDL. The legacy Django table model made sense in Django, but PG18 JSONB improvements and provider-native JSON payloads require a broader curation step before freezing canonical tables.

## Decisions carried forward

```text
DirectSkip corpus: use existing real/sample response payloads.
Auto-apply experimental threshold: min_distinct_users=3, min_distinct_workspaces=2, low-risk, no active disputes.
Tag groups: do not design/seed yet; first inventory existing legacy tags.
Realtor JSON/context: include Realtor docs/legacy/backups as corpus evidence.
Country/county scale: 3,200+ counties and 500-600+ sources imply canonical JSONSchema-first strategy before table explosion.
```

## Non-goals

- no raw JSON value dumps;
- no PII values;
- no provider calls;
- no production/database mutation;
- no final graph DDL yet;
- no user workspace tables;
- no tag group design beyond inventory.
