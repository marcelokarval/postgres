# PG18 DDL Base Lab Proof

Status: PASS
Database: pg18_ddl_lab
Service: postgres18_postgres
Date: 2026-06-14T11:36:47-04:00
Secrets: redacted/omitted

## What this proof did

1. Dropped and recreated a clean lab database named `pg18_ddl_lab` on the live local Swarm PG18 service.
2. Applied `database/ddl/base` with `scripts/apply-ddl-package.sh`; extension enablement is owned by `0002_extensions.sql`.
3. Captured per-database extension installation status from `base.extension_install_results`, including the `pg_cron` runtime constraint.
4. Reapplied the same package to prove idempotence.
5. Exercised functional behavior for public IDs, lifecycle triggers, JSONB guards, search normalization, audit log, realtime outbox/ack, and API facade.

## Extension install output

```text
http	public	f	installed_or_present	-
hypopg	public	f	installed_or_present	-
index_advisor	public	f	installed_or_present	-
pg_cron	public	f	skipped_by_cron_database_name	pg_cron can only be created in cron.database_name=postgres; current_database=pg18_ddl_lab
pg_graphql	graphql	f	installed_or_present	-
pg_hashids	public	f	installed_or_present	-
pg_jsonschema	public	f	installed_or_present	-
pg_net	public	f	installed_or_present	-
pg_partman	public	f	installed_or_present	-
pg_repack	public	f	installed_or_present	-
pg_stat_monitor	public	f	installed_or_present	-
pg_stat_statements	extensions	f	installed_or_present	-
pg_tle	pgtle	f	installed_or_present	-
pgaudit	public	f	installed_or_present	-
pgcrypto	extensions	t	installed_or_present	-
pgjwt	public	f	installed_or_present	-
pgmq	pgmq	f	installed_or_present	-
pgroonga	public	f	installed_or_present	-
pgroonga_database	public	f	installed_or_present	-
pgrouting	public	f	installed_or_present	-
pgsodium	pgsodium	f	installed_or_present	-
pgtap	public	f	installed_or_present	-
plpgsql_check	public	f	installed_or_present	-
postgis	public	f	installed_or_present	-
rum	public	f	installed_or_present	-
supabase_vault	vault	f	installed_or_present	-
uuid-ossp	extensions	f	installed_or_present	-
vector	public	f	installed_or_present	-
wal2json	public	f	installed_or_present	-
wrappers	public	f	installed_or_present	-
```

## DDL apply output

```text
DDL package apply
package_name=base
package_path=/home/marcelo-karval/Backup/Projetos/supabase-postgres-18-fork/postgres/database/ddl/base
tracking_schema=base
database_url=REDACTED_OR_ENV
APPLY 0001_install_tracking.sql checksum=83f7ab11950d41c1506ec4133953c518417aa4247488e0fc6640d0a367b32207
DONE 0001_install_tracking.sql execution_ms=95
APPLY 0002_extensions.sql checksum=46e569501453884124a3e7d170f4900c4ce3fa0493250a4d989ea0b8bd507c10
DONE 0002_extensions.sql execution_ms=1549
APPLY 0003_base_schemas_roles_context.sql checksum=c95d7768e1f3a5570e8142f2cc4edbf1d0d01ec689330717ab37f9ff6c255083
DONE 0003_base_schemas_roles_context.sql execution_ms=94
APPLY 0004_public_id.sql checksum=57733096abf815ba365afc01c019120220a5d1adebe5d3f0e549783fcdee6d42
DONE 0004_public_id.sql execution_ms=103
APPLY 0005_lifecycle_columns_triggers.sql checksum=2145b302e85818423f48b3e46d1d411d1e343245d0e73100971a1751a17d0efd
DONE 0005_lifecycle_columns_triggers.sql execution_ms=94
APPLY 0006_jsonb_contract_helpers.sql checksum=30f6a89f26edc29494f70d4e8b28a7d656db160055386202b601fac702b4a5f0
DONE 0006_jsonb_contract_helpers.sql execution_ms=98
APPLY 0007_search_normalization.sql checksum=525bd3d6cb7fc5f5c8928830ccb577c80ad042d2643f23453414f47ce99920a3
DONE 0007_search_normalization.sql execution_ms=90
APPLY 0008_audit_log.sql checksum=e8556a101b1971e39fe5fa448d9f4f8d2d2ef26a9a0a46cdad62de1b1d62203f
DONE 0008_audit_log.sql execution_ms=101
APPLY 0009_realtime_base.sql checksum=18d97d5b4f70f8985f4024be65d33e4e957c2c051bcb0a08ffe27f897090720d
DONE 0009_realtime_base.sql execution_ms=92
APPLY 0010_api_base.sql checksum=69088b12f3f3f7e1bd68c6d45c29239af9fbb66be66982110e52e92a94a44264
DONE 0010_api_base.sql execution_ms=101
DDL package apply complete
```

## DDL reapply/idempotence output

```text
DDL package apply
package_name=base
package_path=/home/marcelo-karval/Backup/Projetos/supabase-postgres-18-fork/postgres/database/ddl/base
tracking_schema=base
database_url=REDACTED_OR_ENV
SKIP 0001_install_tracking.sql checksum=83f7ab11950d41c1506ec4133953c518417aa4247488e0fc6640d0a367b32207
SKIP 0002_extensions.sql checksum=46e569501453884124a3e7d170f4900c4ce3fa0493250a4d989ea0b8bd507c10
SKIP 0003_base_schemas_roles_context.sql checksum=c95d7768e1f3a5570e8142f2cc4edbf1d0d01ec689330717ab37f9ff6c255083
SKIP 0004_public_id.sql checksum=57733096abf815ba365afc01c019120220a5d1adebe5d3f0e549783fcdee6d42
SKIP 0005_lifecycle_columns_triggers.sql checksum=2145b302e85818423f48b3e46d1d411d1e343245d0e73100971a1751a17d0efd
SKIP 0006_jsonb_contract_helpers.sql checksum=30f6a89f26edc29494f70d4e8b28a7d656db160055386202b601fac702b4a5f0
SKIP 0007_search_normalization.sql checksum=525bd3d6cb7fc5f5c8928830ccb577c80ad042d2643f23453414f47ce99920a3
SKIP 0008_audit_log.sql checksum=e8556a101b1971e39fe5fa448d9f4f8d2d2ef26a9a0a46cdad62de1b1d62203f
SKIP 0009_realtime_base.sql checksum=18d97d5b4f70f8985f4024be65d33e4e957c2c051bcb0a08ffe27f897090720d
SKIP 0010_api_base.sql checksum=69088b12f3f3f7e1bd68c6d45c29239af9fbb66be66982110e52e92a94a44264
DDL package apply complete
```

## Functional tests output

```text
psql:/home/marcelo-karval/Backup/Projetos/supabase-postgres-18-fork/postgres/.tmp/ddl-base-lab/functional-tests.sql:19: NOTICE:  PASS: base schema exists

psql:/home/marcelo-karval/Backup/Projetos/supabase-postgres-18-fork/postgres/.tmp/ddl-base-lab/functional-tests.sql:20: NOTICE:  PASS: api schema exists

psql:/home/marcelo-karval/Backup/Projetos/supabase-postgres-18-fork/postgres/.tmp/ddl-base-lab/functional-tests.sql:21: NOTICE:  PASS: audit schema exists

psql:/home/marcelo-karval/Backup/Projetos/supabase-postgres-18-fork/postgres/.tmp/ddl-base-lab/functional-tests.sql:22: NOTICE:  PASS: realtime schema exists

psql:/home/marcelo-karval/Backup/Projetos/supabase-postgres-18-fork/postgres/.tmp/ddl-base-lab/functional-tests.sql:23: NOTICE:  PASS: ddl migrations are 10 applied files

psql:/home/marcelo-karval/Backup/Projetos/supabase-postgres-18-fork/postgres/.tmp/ddl-base-lab/functional-tests.sql:41: NOTICE:  trigger "sample_entity_set_lifecycle_defaults" for relation "lab.sample_entity" does not exist, skipping
psql:/home/marcelo-karval/Backup/Projetos/supabase-postgres-18-fork/postgres/.tmp/ddl-base-lab/functional-tests.sql:46: NOTICE:  trigger "sample_entity_touch_updated_at" for relation "lab.sample_entity" does not exist, skipping
psql:/home/marcelo-karval/Backup/Projetos/supabase-postgres-18-fork/postgres/.tmp/ddl-base-lab/functional-tests.sql:51: NOTICE:  trigger "sample_entity_increment_version" for relation "lab.sample_entity" does not exist, skipping
{"actor_id": "actor-lab-1", "tenant_id": "tenant-lab-1", "actor_role": "lab-role", "request_id": "request-lab-1"}
psql:/home/marcelo-karval/Backup/Projetos/supabase-postgres-18-fork/postgres/.tmp/ddl-base-lab/functional-tests.sql:63: NOTICE:  PASS: insert generated uuidv7

psql:/home/marcelo-karval/Backup/Projetos/supabase-postgres-18-fork/postgres/.tmp/ddl-base-lab/functional-tests.sql:67: NOTICE:  PASS: lifecycle defaults set

psql:/home/marcelo-karval/Backup/Projetos/supabase-postgres-18-fork/postgres/.tmp/ddl-base-lab/functional-tests.sql:70: NOTICE:  PASS: update increments version

psql:/home/marcelo-karval/Backup/Projetos/supabase-postgres-18-fork/postgres/.tmp/ddl-base-lab/functional-tests.sql:73: NOTICE:  PASS: registered public_id prefix

psql:/home/marcelo-karval/Backup/Projetos/supabase-postgres-18-fork/postgres/.tmp/ddl-base-lab/functional-tests.sql:75: NOTICE:  PASS: public_ref keeps uuid suffix

psql:/home/marcelo-karval/Backup/Projetos/supabase-postgres-18-fork/postgres/.tmp/ddl-base-lab/functional-tests.sql:79: NOTICE:  PASS: public_ref resolves target table

psql:/home/marcelo-karval/Backup/Projetos/supabase-postgres-18-fork/postgres/.tmp/ddl-base-lab/functional-tests.sql:81: NOTICE:  PASS: jsonb_is_object true for object

psql:/home/marcelo-karval/Backup/Projetos/supabase-postgres-18-fork/postgres/.tmp/ddl-base-lab/functional-tests.sql:82: NOTICE:  PASS: jsonb dangerous string detected

psql:/home/marcelo-karval/Backup/Projetos/supabase-postgres-18-fork/postgres/.tmp/ddl-base-lab/functional-tests.sql:83: NOTICE:  PASS: jsonb safe rejects script

psql:/home/marcelo-karval/Backup/Projetos/supabase-postgres-18-fork/postgres/.tmp/ddl-base-lab/functional-tests.sql:84: NOTICE:  PASS: jsonb max depth works

psql:/home/marcelo-karval/Backup/Projetos/supabase-postgres-18-fork/postgres/.tmp/ddl-base-lab/functional-tests.sql:86: NOTICE:  PASS: email normalization

psql:/home/marcelo-karval/Backup/Projetos/supabase-postgres-18-fork/postgres/.tmp/ddl-base-lab/functional-tests.sql:87: NOTICE:  PASS: phone normalization

psql:/home/marcelo-karval/Backup/Projetos/supabase-postgres-18-fork/postgres/.tmp/ddl-base-lab/functional-tests.sql:88: NOTICE:  PASS: search terms normalize/dedupe

psql:/home/marcelo-karval/Backup/Projetos/supabase-postgres-18-fork/postgres/.tmp/ddl-base-lab/functional-tests.sql:100: NOTICE:  PASS: audit row recorded

psql:/home/marcelo-karval/Backup/Projetos/supabase-postgres-18-fork/postgres/.tmp/ddl-base-lab/functional-tests.sql:106: NOTICE:  PASS: realtime event recorded

psql:/home/marcelo-karval/Backup/Projetos/supabase-postgres-18-fork/postgres/.tmp/ddl-base-lab/functional-tests.sql:107: NOTICE:  PASS: realtime ack recorded

psql:/home/marcelo-karval/Backup/Projetos/supabase-postgres-18-fork/postgres/.tmp/ddl-base-lab/functional-tests.sql:109: NOTICE:  PASS: api health returns ok

psql:/home/marcelo-karval/Backup/Projetos/supabase-postgres-18-fork/postgres/.tmp/ddl-base-lab/functional-tests.sql:110: NOTICE:  PASS: api current_context actor

psql:/home/marcelo-karval/Backup/Projetos/supabase-postgres-18-fork/postgres/.tmp/ddl-base-lab/functional-tests.sql:111: NOTICE:  PASS: api ddl_status sees migrations

SUMMARY|schemas=4
SUMMARY|extensions_installed=30
SUMMARY|ddl_migrations=10
SUMMARY|extension_results=30
SUMMARY|public_ref=lab_019ec6c7-40c0-7a5a-81e5-1224f2ed2c27
SUMMARY|audit_id=019ec6c7-40d3-7d26-8fec-a3026095e622
SUMMARY|event_id=019ec6c7-40d6-772a-8398-d21815074349
```

## Final schemas

```text
api	supabase_admin	0	0	0	3
audit	supabase_admin	1	0	0	1
base	supabase_admin	3	0	0	25
extensions	supabase_admin	0	2	0	50
graphql	supabase_admin	0	0	1	6
information_schema	supabase_admin	4	65	0	11
lab	supabase_admin	1	0	0	1
net	supabase_admin	2	0	1	12
pg_catalog	supabase_admin	64	80	0	3402
pgmq	supabase_admin	3	0	0	75
pgsodium	supabase_admin	1	4	1	137
pgsodium_masks	supabase_admin	0	0	0	0
pgtle	supabase_admin	1	0	0	24
public	pg_database_owner	4	8	0	2789
realtime	supabase_admin	2	0	0	2
repack	supabase_admin	0	2	0	26
vault	supabase_admin	1	1	0	5
```

## Final extensions

```text
http	1.6	public
hypopg	1.4.1	public
index_advisor	0.2.0	public
pg_graphql	1.6.1	graphql
pg_hashids	1.3.0-cd0e1b31d52b394a0df64079406a14a4f7387cd6	public
pg_jsonschema	0.3.4	public
pg_net	0.20.3	public
pg_partman	5.3.1	public
pg_repack	1.5.2	public
pg_stat_monitor	2.0	public
pg_stat_statements	1.12	extensions
pg_tle	1.5.2	pgtle
pgaudit	18.0	public
pgcrypto	1.4	extensions
pgjwt	0.2.0	public
pgmq	1.11.1	pgmq
pgroonga	4.0.6	public
pgroonga_database	4.0.6	public
pgrouting	3.4.1	public
pgsodium	3.1.8	pgsodium
pgtap	1.3.3	public
plpgsql	1.0	pg_catalog
plpgsql_check	2.8	public
postgis	3.6.3	public
rum	1.3	public
supabase_vault	0.3.1	vault
uuid-ossp	1.1	extensions
vector	0.8.2	public
wal2json	2.6	public
wrappers	0.6.1	public
```

## Verdict

The clean lab database successfully exercises the implemented base DDL substrate.
