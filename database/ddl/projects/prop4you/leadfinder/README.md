# prop4you/leadfinder

Status: experimental / non-final

LeadFinder owns the canonical graph and the canonical dictionary boundary. Matrix can mirror candidate meanings and mappings, and SourceHub owns raw ingress/lineage, but this subpackage is where LeadFinder-owned canonical family/field semantics are proposed and governed.

Implemented DDL:

- `0001_canonical_dictionary.sql` — creates `prop4you_leadfinder.canonical_dictionary_versions`, `canonical_families`, `canonical_fields`, `canonical_gaps`, and `growth_pressure_signals`; seeds the initial `leadfinder.raw_candidate.v0` dictionary version plus candidate families/fields from the approved family list.
- `0002_raw_evidence_gap_bridge.sql` — bridges Matrix raw path evidence into LeadFinder-owned gap candidates.
- `0003_prepare_dictionary_promotions.sql` — prepares dictionary promotion proposals from approved field mapping artifacts without mutating canonical dictionary rows.
- `0004_dictionary_promotion_review_apply.sql` — explicit review/apply gate for prepared dictionary promotions, creating/linking canonical family/field rows only after accepted review.

Boundaries:

- Experimental/non-final only; no final property, owner, phone, email, or lead materialization tables are created in this slice.
- No raw payload values, fake fixtures, redacted fixtures, secrets, provider responses, phone numbers, emails, names, or addresses are stored by this dictionary seed.
- Candidate rows use `evidence_origin` JSONB labels to preserve provenance categories without embedding raw values.
- Provider calls and runtime enrichment are out of scope.
- Dictionary rows use UUIDv7 primary keys and JSONB metadata for future review workflow.

Seeded candidate families:

- `property_identity`
- `property_details`
- `property_media`
- `property_history`
- `situation_legal`
- `valuation_financial`
- `owner_identity`
- `ownership_history`
- `party_roles`
- `owner_contact_address`
- `owner_phone`
- `owner_email`
- `relationship_evidence`
- `lead_opportunity`
- `source_lineage`

Rules:

- LeadFinder owns canonical dictionary semantics.
- Matrix `canonical_*` objects must be treated as experimental mirror/candidate support, not the ownership source for the final canonical graph.
- Keep fields as candidates until review approves DTO or canonical graph materialization.
- Preserve SourceHub lineage for raw evidence; do not copy raw payload values into dictionary metadata.
- Add objective `COMMENT ON` statements for every SQL object and column.
- Validate in `pg18_ddl_lab` or a clean lab DB before promotion when database access is available.
