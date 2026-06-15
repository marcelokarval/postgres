# prop4you/sourcehub

Status: experimental / non-final

SourceHub owns raw provider/internal payload evidence, private corpus metadata, lineage, and enrichment request workflow state for Prop4You corpus comparison. It is a review substrate, not the final property/owner/lead model.

Implemented DDL:

- `0001_sourcehub_corpus.sql` — creates `prop4you_sourcehub.raw_records`, `corpus_samples`, `source_lineage_edges`, `enrichment_requests`, helper functions, lifecycle triggers, indexes, comments, and public-id prefix registrations.

Boundaries:

- [NO_FIXTURES] No raw, fake, redacted, or sample payload files are created or committed.
- [NO_PROVIDER_CALLS] No provider runtime, HTTP call, secret, Docker/runtime mutation, or worker is created.
- Private real corpus files stay outside git; SourceHub stores only optional `private_corpus_uri` / `private_corpus_path` metadata plus checksum/size/status fields.
- `raw_payload jsonb` is raw evidence for review. It is not a canonical property, owner, lead, or DTO.
- Matrix must authorize semantic meaning/path mappings before LeadFinder materialization can rely on SourceHub evidence.

[ENRICHMENT_REQUEST_FLOW]

The `enrichment_requests` table preserves the old Django-style idea that a domain/review event can trigger extra data lookup. In this DDL it is modeled only as durable queue intent:

1. A review/domain gap records an enrichment request with provider, lookup kind, trigger metadata, priority, idempotency key, and non-secret `request_payload`.
2. A future authorized worker may consume ready/queued rows outside this DDL package.
3. If a response exists later, it should be stored as a `raw_records` JSONB evidence row.
4. `mark_enrichment_response()` links the request to that raw response and writes a SourceHub lineage edge.
5. No provider call is made by the database DDL or helper functions.

[COMMENT_COVERAGE]

The implemented SQL includes `COMMENT ON` coverage for the schema, every table, every column, helper functions, lifecycle triggers, and the raw-record-to-corpus foreign key constraint. Indexes are named descriptively but PostgreSQL does not normally require comments on every index for this experimental review slice.

[DDL_OBJECTS]

Tables:

- `prop4you_sourcehub.raw_records`
- `prop4you_sourcehub.corpus_samples`
- `prop4you_sourcehub.source_lineage_edges`
- `prop4you_sourcehub.enrichment_requests`

Functions:

- `prop4you_sourcehub.enqueue_enrichment_request(...)`
- `prop4you_sourcehub.mark_enrichment_response(...)`

Primary indexes/themes:

- provider/class/status review lookup
- queue lookup for enrichment requests
- trigger object lookup for enrichment requests
- raw JSONB and metadata GIN review indexes
- lineage from/to/derived-object lookup

[RISKS]

- Non-final: column names/status vocabularies may change after real provider corpus comparison and Matrix review.
- `raw_payload` can contain sensitive data; access policy/RLS is intentionally not finalized in this slice.
- The queue table does not implement locking/worker semantics yet; it only captures durable intent.
- Private corpus URI/path metadata must be handled carefully by operators to avoid leaking local paths or secrets.
- Apply order requires base DDL, Prop4You schemas, and provider registry before SourceHub DDL.
