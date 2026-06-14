# PG18 DDL Base Lab Proof

Status: PASS
Database: pg18_ddl_lab
Service: postgres18_postgres
Date: 2026-06-14T11:14:58-04:00
Secrets: redacted/omitted

## What this proof did

1. Dropped and recreated a clean lab database named `pg18_ddl_lab` on the live local Swarm PG18 service.
2. Enabled a broad set of available Supabase/Postgres extensions where possible, recording install/skipped status.
3. Applied `database/ddl/base` with `scripts/apply-ddl-package.sh`.
4. Reapplied the same package to prove idempotence.
5. Exercised functional behavior for public IDs, lifecycle triggers, JSONB guards, search normalization, audit log, realtime outbox/ack, and API facade.

## Extension install output

```text
                                     ?column?
-----------------------------------------------------------------------------------
 http=installed_or_present
 hypopg=installed_or_present
 index_advisor=installed_or_present
 pg_cron=skipped_or_failed [P0001: can only create extension in database postgres]
 pg_graphql=installed_or_present
 pg_jsonschema=installed_or_present
 pg_net=installed_or_present
 pg_partman=installed_or_present
 pg_repack=installed_or_present
 pg_stat_statements=installed_or_present
 pgaudit=installed_or_present
 pgcrypto=installed_or_present
 pgjwt=installed_or_present
 pgmq=installed_or_present
 pgroonga=installed_or_present
 pgrouting=installed_or_present
 pgtap=installed_or_present
 plpgsql_check=installed_or_present
 postgis=installed_or_present
 rum=installed_or_present
 supabase_vault=installed_or_present
 uuid-ossp=installed_or_present
 vector=installed_or_present
 wal2json=installed_or_present
 wrappers=installed_or_present
(25 rows)
```

## DDL apply output

```text
DDL package apply
package_name=base
package_path=/home/marcelo-karval/Backup/Projetos/supabase-postgres-18-fork/postgres/database/ddl/base
tracking_schema=base
database_url=REDACTED_OR_ENV
APPLY 0001_install_tracking.sql checksum=6e574a77da31f61a73223b2daddb1001fc5df466a20689cf439315dcf43680a7
DONE 0001_install_tracking.sql execution_ms=96
APPLY 0002_base_schemas_roles_context.sql checksum=6fcba4da61091b5d0dec2589d1076d4e8b6724a9611ddc4194b5e3a4d098cf51
DONE 0002_base_schemas_roles_context.sql execution_ms=84
APPLY 0003_public_id.sql checksum=b311713b4662bfe366676765481e6d8c124a51fdc10c529a8bd76f1f101eb3fe
DONE 0003_public_id.sql execution_ms=90
APPLY 0004_lifecycle_columns_triggers.sql checksum=6552f9d9377bc5875eb8f562b1205081799a97404a7509a5929f93288c803d55
DONE 0004_lifecycle_columns_triggers.sql execution_ms=81
APPLY 0005_jsonb_contract_helpers.sql checksum=ac03eb2cf3a42e548042b2aba579b9fe64879fd4c8741a50f54df9b66c8358cc
DONE 0005_jsonb_contract_helpers.sql execution_ms=95
APPLY 0006_search_normalization.sql checksum=c6265931a34ab66a73db0a110cd41c0eb5ae6c76e64d52b4e8fd6540a3f6af0b
DONE 0006_search_normalization.sql execution_ms=95
APPLY 0007_audit_log.sql checksum=62a7e0eb67c3ed5fb976eeaaf689f4f351fc6fd385405917f00f26e40448c91d
DONE 0007_audit_log.sql execution_ms=110
APPLY 0008_realtime_base.sql checksum=4d59b99e4aa6b8a39eeced95475c0017df0876e4851f2aeb434c737ee6b4d1a7
DONE 0008_realtime_base.sql execution_ms=106
APPLY 0009_api_base.sql checksum=78e75678b513f184afbef70298fc3f15c267cb5c2703f672319c2dfd735bdd4c
DONE 0009_api_base.sql execution_ms=91
DDL package apply complete
```

## DDL reapply/idempotence output

```text
DDL package apply
package_name=base
package_path=/home/marcelo-karval/Backup/Projetos/supabase-postgres-18-fork/postgres/database/ddl/base
tracking_schema=base
database_url=REDACTED_OR_ENV
SKIP 0001_install_tracking.sql checksum=6e574a77da31f61a73223b2daddb1001fc5df466a20689cf439315dcf43680a7
SKIP 0002_base_schemas_roles_context.sql checksum=6fcba4da61091b5d0dec2589d1076d4e8b6724a9611ddc4194b5e3a4d098cf51
SKIP 0003_public_id.sql checksum=b311713b4662bfe366676765481e6d8c124a51fdc10c529a8bd76f1f101eb3fe
SKIP 0004_lifecycle_columns_triggers.sql checksum=6552f9d9377bc5875eb8f562b1205081799a97404a7509a5929f93288c803d55
SKIP 0005_jsonb_contract_helpers.sql checksum=ac03eb2cf3a42e548042b2aba579b9fe64879fd4c8741a50f54df9b66c8358cc
SKIP 0006_search_normalization.sql checksum=c6265931a34ab66a73db0a110cd41c0eb5ae6c76e64d52b4e8fd6540a3f6af0b
SKIP 0007_audit_log.sql checksum=62a7e0eb67c3ed5fb976eeaaf689f4f351fc6fd385405917f00f26e40448c91d
SKIP 0008_realtime_base.sql checksum=4d59b99e4aa6b8a39eeced95475c0017df0876e4851f2aeb434c737ee6b4d1a7
SKIP 0009_api_base.sql checksum=78e75678b513f184afbef70298fc3f15c267cb5c2703f672319c2dfd735bdd4c
DDL package apply complete
```

## Functional tests output

```text
psql:/home/marcelo-karval/Backup/Projetos/supabase-postgres-18-fork/postgres/.tmp/ddl-base-lab/functional-tests.sql:5: NOTICE:  schema "lab" already exists, skipping
psql:/home/marcelo-karval/Backup/Projetos/supabase-postgres-18-fork/postgres/.tmp/ddl-base-lab/functional-tests.sql:19: NOTICE:  PASS: base schema exists

psql:/home/marcelo-karval/Backup/Projetos/supabase-postgres-18-fork/postgres/.tmp/ddl-base-lab/functional-tests.sql:20: NOTICE:  PASS: api schema exists

psql:/home/marcelo-karval/Backup/Projetos/supabase-postgres-18-fork/postgres/.tmp/ddl-base-lab/functional-tests.sql:21: NOTICE:  PASS: audit schema exists

psql:/home/marcelo-karval/Backup/Projetos/supabase-postgres-18-fork/postgres/.tmp/ddl-base-lab/functional-tests.sql:22: NOTICE:  PASS: realtime schema exists

psql:/home/marcelo-karval/Backup/Projetos/supabase-postgres-18-fork/postgres/.tmp/ddl-base-lab/functional-tests.sql:23: NOTICE:  PASS: ddl migrations are 9 applied files

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
SUMMARY|extensions_installed=25
SUMMARY|ddl_migrations=9
SUMMARY|public_ref=lab_019ec6b3-4615-7f07-8139-113b08e8fdd1
SUMMARY|audit_id=019ec6b3-4622-7964-9cd5-d6d34711e628
SUMMARY|event_id=019ec6b3-4624-780b-adea-62670e73eaaf
```

## Final schemas

```text
api	supabase_admin	0	0	0	3
audit	supabase_admin	1	0	0	1
base	supabase_admin	2	0	0	24
extensions	supabase_admin	0	2	0	50
graphql	supabase_admin	0	0	1	6
information_schema	supabase_admin	4	65	0	11
lab	supabase_admin	2	0	0	2
net	supabase_admin	2	0	1	12
pg_catalog	supabase_admin	64	80	0	3402
pgmq	supabase_admin	3	0	0	75
public	pg_database_owner	4	7	0	2755
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
pg_jsonschema	0.3.4	public
pg_net	0.20.3	public
pg_partman	5.3.1	public
pg_repack	1.5.2	public
pg_stat_statements	1.12	extensions
pgaudit	18.0	public
pgcrypto	1.4	extensions
pgjwt	0.2.0	public
pgmq	1.11.1	pgmq
pgroonga	4.0.6	public
pgrouting	3.4.1	public
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
