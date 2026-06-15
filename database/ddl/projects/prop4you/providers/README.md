# prop4you/providers

Status: experimental / non-final

Shared provider corpus contracts, provider/origin registry, payload class catalog, and JSONB path helper functions for Prop4You SourceHub + Matrix review.

DDL:

- `0001_provider_registry.sql` creates `prop4you_provider.providers`, `prop4you_provider.payload_classes`, `prop4you_provider.provider_payload_classes`, and review-only JSONB path helpers.

Rules:

- Do not freeze final tables from Django models alone.
- Preserve raw evidence/lineage when provider payloads are involved.
- Do not commit raw, fake, redacted, or synthetic provider payload fixtures here.
- Do not call providers from DDL, review docs, or proof scripts.
- Store no secrets, credentials, API URLs, request headers, or runtime integration config in this package.
- Use this package only as a non-final registry/catalog and JSONB inspection helper substrate for SourceHub and Matrix work.
- Add objective `COMMENT ON` statements for every SQL schema, table, column, and function added.
- Validate in `pg18_ddl_lab` or a clean lab DB before promotion.
