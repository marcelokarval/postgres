# 09-provider-registry-ddl-review — Worker A

Status: delivered by subagent A
Date: 2026-06-15
Scope: provider registry + JSONB helper DDL for Prop4You SourceHub + Matrix experimental package.

## [NO_FIXTURES]

No provider payload fixtures were created or committed. The DDL seeds only registry/catalog metadata rows for known provider/origin keys and payload class relationships. It does not include raw, fake, redacted, synthetic, or sample payload JSON documents.

## [NO_PROVIDER_CALLS]

No provider calls were made. The SQL contains no runtime client, endpoint invocation, secret, request header, credential, job, trigger, or network operation. The provider catalog explicitly stores `provider_call_allowed=false` in seed metadata for provider/origin rows.

## [COMMENT_COVERAGE]

Comment coverage added in `database/ddl/projects/prop4you/providers/0001_provider_registry.sql`:

- 1 schema comment for `prop4you_provider`.
- 3 table comments.
- 30 column comments across all provider registry/catalog tables.
- 4 function comments for JSONB helper functions.

Coverage intent: every schema/table/column/function introduced by this worker has an objective `COMMENT ON` statement.

## [DDL_OBJECTS]

Created/updated experimental non-final DDL objects:

- Schema boundary:
  - `prop4you_provider` comment refreshed for provider registry + helper scope.

- Tables:
  - `prop4you_provider.providers`
    - Provider/origin registry for REIQ, DirectSkip, Realtor.com, and internal/product-originated payloads.
    - Uses `uuidv7()`, constrained text enums, JSONB metadata object guard, and URL format guard for optional human homepage reference.
  - `prop4you_provider.payload_classes`
    - Payload class catalog for property/search/owner/skip-trace/internal snapshot review categories.
    - Uses `uuidv7()`, constrained domain/direction/root type values, JSONB schema hint and metadata object guards.
  - `prop4you_provider.provider_payload_classes`
    - Many-to-many registry between providers/origins and payload classes.
    - Uses `uuidv7()`, FK references, unique provider/class relationship, JSONB metadata object guard.

- Indexes:
  - `providers_provider_kind_status_idx`
  - `payload_classes_domain_direction_idx`
  - `provider_payload_classes_class_idx`

- JSONB helper functions:
  - `prop4you_provider.jsonb_path_exists(jsonb, text[])`
  - `prop4you_provider.jsonb_path_type(jsonb, text[])`
  - `prop4you_provider.jsonb_path_text(jsonb, text[])`
  - `prop4you_provider.jsonb_leaf_paths(jsonb, integer)`

- Seed metadata rows:
  - Provider/origin keys: `reiq`, `directskip`, `realtor_com`, `prop4you_internal`.
  - Payload class keys: `property_search_result`, `property_detail`, `owner_profile`, `skip_trace_result`, `leadfinder_candidate_snapshot`.
  - Provider/class review links for expected non-final comparison scope.

## Verification

Static checks performed locally:

- `git diff --check -- database/ddl/projects/prop4you/providers/0001_provider_registry.sql database/ddl/projects/prop4you/providers/README.md` completed with exit code 0.
- A Python count over the SQL file found 3 created tables, 4 created functions, 1 schema comment, 3 table comments, 30 column comments, and 4 function comments.

Runtime SQL application was not performed by this worker because local `psql` access is blocked by host authentication for the current OS role and peer auth for `postgres`. The parent lab installer slice should apply this DDL in the clean `pg18_ddl_lab` proof database once credentials/context are available.

## [RISKS]

- SQL is intentionally experimental and non-final; it should not be treated as the canonical provider integration model or final property/owner/lead schema.
- `jsonb_leaf_paths` is a review helper. Large payloads can produce many paths; callers should use bounded private corpus review queries and keep `max_depth` conservative.
- Seeded provider/payload relationships are classification scaffolding from current issue context, not evidence that all providers expose those payloads in production.
- The provider registry stores human reference metadata only. Runtime endpoint configuration, secrets, and provider clients must remain outside this DDL.
- Parent integration still needs clean lab application proof after SourceHub and Matrix DDL are added to the package order.
