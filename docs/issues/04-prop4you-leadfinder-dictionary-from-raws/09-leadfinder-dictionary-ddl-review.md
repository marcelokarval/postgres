# Review — LeadFinder dictionary DDL v0

Status: implemented by Worker B

## [LEADFINDER_OWNS_CANONICAL]

Implemented an experimental/non-final LeadFinder-owned dictionary package in `database/ddl/projects/prop4you/leadfinder/0001_canonical_dictionary.sql`.

The DDL explicitly declares that LeadFinder owns canonical dictionary semantics. Matrix remains a mirror/candidate mapping and review support layer; SourceHub remains raw ingress/lineage owner.

## [NO_FIXTURES]

No fixtures were created. The seed data is limited to dictionary version, family candidates, and field candidates. It contains only semantic labels, descriptions, review metadata, and `evidence_origin` category labels.

No raw payload values, fake payloads, redacted payloads, names, phone numbers, emails, addresses, provider responses, or secrets were inserted.

## [NO_PROVIDER_CALLS]

No provider calls were made or implemented. The SQL has no HTTP/client/runtime enrichment logic.

Local DB validation was attempted but the running local PostgreSQL instance rejects the current OS role and peer-auth postgres access:

- `psql --version`: PostgreSQL client 16.14 available.
- `pg_isready`: local server accepting connections.
- `psql -d postgres`: failed with `FATAL: role "marcelo-karval" does not exist`.
- `psql -U postgres -d postgres`: failed with `FATAL: Peer authentication failed for user "postgres"`.
- `sudo -n -u postgres ...`: failed because sudo requires a password.

Static repository checks were run instead:

- `git diff --check -- database/ddl/projects/prop4you/leadfinder/0001_canonical_dictionary.sql database/ddl/projects/prop4you/leadfinder/README.md` returned cleanly.
- Python static count check confirmed expected object/comment/seed markers.

## [DDL_OBJECTS]

Created DDL for schema `prop4you_leadfinder` and these tables:

1. `prop4you_leadfinder.canonical_dictionary_versions`
   - UUIDv7 primary key.
   - Unique `version_key`.
   - JSONB `metadata` object constraint.
   - Review/source/ownership constraints.

2. `prop4you_leadfinder.canonical_families`
   - UUIDv7 primary key.
   - FK to dictionary version.
   - Unique `(dictionary_version_id, family_key)`.
   - Candidate status, family role, JSONB `evidence_origin`, JSONB `metadata`.
   - B-tree and GIN indexes.

3. `prop4you_leadfinder.canonical_fields`
   - UUIDv7 primary key.
   - FK to dictionary version and family.
   - Unique `(dictionary_version_id, family_id, field_key)`.
   - Candidate status, materialization intent, privacy classification, JSONB `evidence_origin`, JSONB `metadata`.
   - B-tree and GIN indexes.

4. `prop4you_leadfinder.canonical_gaps`
   - UUIDv7 primary key.
   - FK to dictionary version, optional family, optional field.
   - Unique `(dictionary_version_id, gap_key)`.
   - Gap kind/severity/status constraints and indexes.

5. `prop4you_leadfinder.growth_pressure_signals`
   - UUIDv7 primary key.
   - FK to dictionary version, optional family, optional field.
   - Unique `(dictionary_version_id, signal_key)`.
   - Signal kind/status/pressure constraints and indexes.

Seeded dictionary version:

- `leadfinder.raw_candidate.v0`

Seeded approved family list:

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

Seeded field candidates include property reference/address/parcel candidates, property detail/media/history candidates, situation/legal candidates, valuation/financial candidates, owner identity/ownership/party-role candidates, owner contact address/phone/email quality candidates, relationship evidence candidates, lead opportunity candidates, and source lineage reference candidates.

## [COMMENT_COVERAGE]

Comment coverage added for:

- Schema: `prop4you_leadfinder`.
- All 5 tables.
- All 64 table columns.

Static count result from the implemented SQL:

```text
create_table_count 5
comment_table_count 5
comment_column_count 64
uuidv7_count 5
no_fixtures_marker True
no_provider_calls_marker True
leadfinder_marker True
family_seed_count 15
```

## [RISKS]

- Runtime SQL execution against `pg18_ddl_lab` could not be completed from this session due local PostgreSQL authentication constraints. Parent/Thor should run the integrated lab proof with appropriate DB credentials.
- The dictionary is intentionally non-final. Candidate fields are semantic placeholders and must not be treated as final materialized property/owner/contact/lead schema.
- `evidence_origin` metadata contains only category labels; downstream reviewers must continue to prevent raw payload values or PII from being copied into dictionary metadata.
- Future DDL may need lifecycle triggers/public refs if the broader Prop4You package standardizes those for dictionary objects.
