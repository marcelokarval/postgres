# 10 — SourceHub DDL review (Worker B)

Status: delivered by Worker B
Date: 2026-06-15
Scope: `database/ddl/projects/prop4you/sourcehub/0001_sourcehub_corpus.sql`

[DDL_OBJECTS]

Implemented experimental, non-final SourceHub DDL for schema `prop4you_sourcehub`:

- `raw_records`
  - Stores raw provider/internal JSONB evidence in `raw_payload`.
  - Tracks provider, payload class, source kind, ingress/review status, Matrix mapping status, LeadFinder publication status, privacy flags, optional provider request refs, and optional private corpus URI/path metadata.
- `corpus_samples`
  - Stores private real corpus sample metadata only: provider, sample key, status, purpose, optional private URI/path, checksum, size, redaction/storage policy, and review metadata.
  - Does not create or commit payload files.
- `source_lineage_edges`
  - Captures raw-to-raw and raw-to-derived lineage relationships without declaring canonical property/owner/lead truth.
- `enrichment_requests`
  - Durable queue-intent table for extra lookup requests formerly triggered by Django-style application logic.
  - Stores status, priority, lookup kind, trigger object metadata, idempotency key, non-secret request payload, response raw record pointer, attempts, and errors.
- Functions:
  - `enqueue_enrichment_request(...)`
  - `mark_enrichment_response(...)`
- Lifecycle triggers:
  - `base.set_lifecycle_defaults()` / `base.touch_updated_at()` / `base.increment_version()` attached to all four tables.
- Public-id prefix registrations:
  - `p4yshr`, `p4yshs`, `p4yshl`, `p4yshe`.

[ENRICHMENT_REQUEST_FLOW]

The old Django-style behavior of “record changed / gap found / trigger another lookup” is represented as database state, not as provider runtime code:

1. `enqueue_enrichment_request(...)` records or deduplicates an enrichment intent.
2. The request remains queued/ready/blocked/in_progress/succeeded/failed/cancelled/superseded in `enrichment_requests`.
3. No HTTP/client/provider call is made by SQL.
4. A future authorized worker can store a response as `raw_records.raw_payload`.
5. `mark_enrichment_response(...)` links that response row to the request and writes a lineage edge with `lineage_kind = 'enrichment_response_for'`.
6. Matrix and LeadFinder gates remain separate; raw payloads do not publish canonical entities directly.

[COMMENT_COVERAGE]

Coverage included in DDL:

- Schema comment: yes.
- Table comments: 4/4.
- Column comments: all important/current columns across 4 tables.
- Function comments: 2/2.
- Trigger comments: 12/12.
- Constraint comment: explicit comment on `raw_records_corpus_sample_fk`.

Validation command run:

```text
python3 lightweight_sql_checks
```

Observed output summary:

```text
create_table 4
create_function 2
create_trigger 12
comment_column 119
insert_into 0
lightweight_sql_checks=ok
```

A live `psql` validation was attempted against the local socket but blocked by local auth/role setup (`role "marcelo-karval" does not exist`; `postgres` peer auth failed). No database mutation was performed for validation.

[NO_FIXTURES]

No fixture file was created. The SQL contains zero `insert into` payload/sample fixture statements. The only persistent data-like operation in the file is public-id prefix registration through the base registry helper.

[NO_PROVIDER_CALLS]

No provider/client/runtime/Docker operation was added. The DDL contains no HTTP endpoint invocation, no curl/wget usage, no secrets, and no worker implementation.

[RISKS]

- This is experimental/non-final and should be reviewed with real private provider corpus samples before being treated as canonical.
- `raw_payload` can hold sensitive personal/provider data; access controls/RLS are not finalized in this Worker B slice.
- Queue semantics are conceptual; worker locking, retry policy, provider authorization, and operational scheduling remain future work.
- Private path/URI metadata can leak local/private structure if mishandled by operators.
- Apply order matters: base DDL, Prop4You schemas, and provider registry must precede SourceHub DDL.
