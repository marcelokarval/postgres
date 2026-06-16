# Review — Worker B Matrix artifact DDL

Status: delivered by subagent B

## [MATRIX_ARTIFACT_GATE]

Implemented `database/ddl/projects/prop4you/matrix/0002_mapping_sessions.sql` as an experimental/non-final Matrix artifact gate. The DDL models review workflow state for mapping sessions, transformation artifacts, and artifact field mappings. These rows can gate later SourceHub DTO publication work, but they do not publish DTOs and do not materialize LeadFinder canonical graph rows.

## [LEADFINDER_DICTIONARY_FK]

The new DDL includes required foreign keys to `prop4you_leadfinder.canonical_dictionary_versions` on:

- `prop4you_matrix.mapping_sessions.dictionary_version_id`
- `prop4you_matrix.transformation_artifacts.dictionary_version_id`
- `prop4you_matrix.artifact_field_mappings.dictionary_version_id`

It also includes optional safe links to existing Matrix, SourceHub, Provider, and LeadFinder objects:

- `prop4you_matrix.mapping_versions`
- `prop4you_matrix.provider_path_mappings`
- `prop4you_matrix.canonical_fields` as mirror/candidate/review compatibility
- `prop4you_sourcehub.raw_records` for lineage only
- `prop4you_provider.providers`
- `prop4you_provider.payload_classes`
- `prop4you_leadfinder.canonical_fields`

## [NO_FIXTURES]

No insert statements, fixture values, raw payload samples, fake payload samples, or redacted payload values were added. The SQL creates schema objects, constraints, indexes, and comments only.

## [NO_PROVIDER_CALLS]

No provider/API calls, HTTP clients, lookup functions, network calls, runtime enrichment code, or provider credentials were added. JSONB columns and comments explicitly state that raw provider values and secrets do not belong in Matrix artifacts.

## [DDL_OBJECTS]

Created DDL for these objects:

- `prop4you_matrix.mapping_sessions`
  - UUIDv7 primary key and generated public ref.
  - Required LeadFinder dictionary version FK.
  - Optional provider/payload/mapping/source lineage FKs.
  - Status constraints for session lifecycle and artifact gate lifecycle.
  - JSONB object checks for input scope, extraction summary, and metadata.
  - Useful btree and GIN indexes.
  - Table and column comments.

- `prop4you_matrix.transformation_artifacts`
  - UUIDv7 primary key and generated public ref.
  - Required mapping session FK and required LeadFinder dictionary version FK.
  - Optional provider/payload/mapping/source lineage FKs.
  - Artifact kind/status/gate constraints, checksum constraint, JSONB object checks.
  - Useful btree and GIN indexes.
  - Table and column comments.

- `prop4you_matrix.artifact_field_mappings`
  - UUIDv7 primary key and generated public ref.
  - Required artifact, mapping session, and LeadFinder dictionary version FKs.
  - Optional LeadFinder field, Matrix mirror field, provider path mapping, provider/payload/source lineage FKs.
  - `text[]` source path, target field key, transform policy, status, confidence, and ordinal constraints.
  - Unique artifact/path/target index plus btree and GIN indexes.
  - Table and column comments.

Updated `database/ddl/projects/prop4you/matrix/README.md` to list `0002_mapping_sessions.sql` and document the artifact gate rules.

## [RISKS]

- The DDL is intentionally experimental/non-final; status vocabularies and artifact JSONB contracts may need adjustment after raw corpus extractor output lands.
- `create table if not exists` is idempotent for clean installs but will not retrofit column/constraint changes if an earlier divergent table already exists in a target database.
- `artifact_payload`, `evidence_summary`, and `transform_spec` are flexible JSONB objects; downstream tooling must enforce the no-raw-values policy during artifact generation.
- The optional `prop4you_matrix.mapping_versions` links preserve compatibility with the existing Matrix 0001 model, but future cleanup may migrate all artifact ownership to the new session/artifact tables.
