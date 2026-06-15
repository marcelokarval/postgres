# Detection and Analysis — Prop4You SourceHub + Matrix DDL v0

Status: started
Date: 2026-06-15T18:50:42
Owner: Thor/default

## User decisions applied

1. Private corpus path accepted:

```text
~/.hermes/private/prop4you-provider-corpus/
```

2. First experimental DDL starts with:

```text
sourcehub.raw_record + matrix.semantic_dictionary
```

3. Important nuance:

The future database-centric system must preserve the old Django behavior where application actions triggered extra data lookups/enrichment. In the database-centric design this becomes an explicit request/enrichment workflow: requests, queue/candidate jobs, provider responses, SourceHub ingress, Matrix validation and LeadFinder materialization.

4. Fixture policy clarification:

Do not create committed fake/redacted fixtures. This slice will not commit provider payload fixtures. It may create schemas, tables, functions, comments, lab checks and scripts that are ready to process a private real corpus later.

## Prior source stack

```text
docs/issues/01-prop4you-provider-payload-corpus/
```

## Current target

Create first experimental but non-final Prop4You DDL package pieces:

```text
database/ddl/projects/prop4you/providers/
database/ddl/projects/prop4you/sourcehub/
database/ddl/projects/prop4you/matrix/
scripts/proof-prop4you-ddl-lab.sh
```

## Non-goals

- no provider API calls;
- no raw payload fixture commits;
- no fake/redacted fixture commits;
- no final property/owner table freeze;
- no production mutation;
- no persistent lab mutation unless explicitly scoped by proof script.
