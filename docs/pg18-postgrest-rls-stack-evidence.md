# PG18 Durable PostgREST JWT/RLS Stack Evidence

Status: LOCAL_STACK_BROWSER_PROOF_PASS

## Stack

- Compose: `docker/pg18-postgrest-rls/compose.pg18-postgrest-rls.yml`
- PG image default: `registry.arthuragrelli.com/supabase-postgres:18-karval-rc1`
- PostgREST pinned digest: `postgrest/postgrest@sha256:488093de819567422bc1d37cb79da6e84bca3726bac321daeed618f0ed957888`
- Web URL during proof: `http://127.0.0.1:18083/docs/pg18-postgrest-rls-web.html`

## Smoke output

```text
Network pg18-postgrest-rls-net Creating 
 Network pg18-postgrest-rls-net Created 
 Container pg18-rls-db Creating 
 Container pg18-rls-db Created 
 Container pg18-rls-postgrest Creating 
 Container pg18-rls-postgrest Created 
 Container pg18-rls-web Creating 
 Container pg18-rls-web Created 
 Container pg18-rls-db Starting 
 Container pg18-rls-db Started 
 Container pg18-rls-postgrest Starting 
 Container pg18-rls-postgrest Started 
 Container pg18-rls-web Starting 
 Container pg18-rls-web Started 
/run/postgresql:5432 - accepting connections
anon_code=401
2281 /home/marcelo-karval/Backup/Projetos/supabase-postgres-18-fork/postgres/tmp/pg18-rls-stack/web.html
PG18_POSTGREST_RLS_STACK_OK
web_url=http://127.0.0.1:18083/docs/pg18-postgrest-rls-web.html
kept_compose_stack=true
```

## JWT/RLS API evidence

Karval JWT profile:

```json
{"plan": "rc1", "role": "authenticated", "metadata": {"source": "pg18-rls-proof"}, "app_user_id": "user_karval_demo", "display_name": "Karval Demo", "jwt_app_user_id": "user_karval_demo", "postgres_version": "18.0"}
```

Other JWT profile, proving claim selects a different RLS-visible row:

```json
{"plan": "blocked", "role": "authenticated", "metadata": {"source": "pg18-rls-proof"}, "app_user_id": "user_other_demo", "display_name": "Other Demo", "jwt_app_user_id": "user_other_demo", "postgres_version": "18.0"}
```

Anonymous denial:

```text
anon_code=401
```

Web same-origin profile:

```json
{"plan": "rc1", "role": "authenticated", "metadata": {"source": "pg18-rls-proof"}, "app_user_id": "user_karval_demo", "display_name": "Karval Demo", "jwt_app_user_id": "user_karval_demo", "postgres_version": "18.0"}
```

## Browser proof

- DOM status: `200 OK`
- DOM user: `user_karval_demo`
- DOM plan: `rc1`
- DOM role: `authenticated`
- DOM Postgres: `18.0`
- Vision: PASS; no visual breakage or missing content observed.

## Runtime correction notes

- Initial init failed because the SQL file was not readable by the container; fixed with file mode `0644`.
- Initial PostgREST readiness advanced too early on root `403`; fixed by waiting for `/rpc/hello` HTTP 200.
- `current_profile` initially tried to expose `shared_preload_libraries`, which authenticated users cannot read without elevated privileges; removed from the RLS-safe RPC to avoid broad grants.
