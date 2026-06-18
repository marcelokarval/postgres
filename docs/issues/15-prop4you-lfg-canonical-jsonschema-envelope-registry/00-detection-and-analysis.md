# Detection and Analysis — LFG canonical JSONSchema envelope registry

Status: active
Created: 2026-06-18T16:19:19
Reviewer: Thor/default

## User question

Are the table-vs-json/jsonb rules documented and automatically accessible?

## Answer before this slice

```text
Documented: yes, in docs and skill references.
Automatically accessible inside the repo/runtime contract: not enough yet.
```

The rules need to become machine-readable/repo-addressable artifacts:

- canonical JSONSchema files;
- projection/promotion policy file;
- DDL registry to store schemas and projection policies;
- proof script that validates artifacts and DDL registration;
- skill reference so future agents load the gate automatically.

## Slice goal

Create the minimum canonical envelope registry for LFG without implementing final graph tables.

## Non-goals

- no final property/owner/contact tables;
- no workspace tables;
- no provider calls;
- no raw JSON values or PII;
- no public API/RLS yet;
- no final tag-group seed.
