# PG18 PostgREST + Web Proof Evidence

## Containers during proof

- PG image: `local/supabase-postgres:18-karval-rc1`
- PostgreSQL proof container: `pg18-postgrest-proof-db`
- PostgREST proof container: `pg18-postgrest-proof-api`
- PostgREST image: `postgrest/postgrest@sha256:488093de819567422bc1d37cb79da6e84bca3726bac321daeed618f0ed957888`
- PostgREST URL: `http://127.0.0.1:13000`
- Web/proxy URL: `http://127.0.0.1:18082/docs/pg18-postgrest-web-proof.html`

## Reproducible script output after final correction

Command:

```bash
python3 - <<'PY'
from pathlib import Path
s=Path('scripts/proof-pg18-postgrest-web.sh').read_text()
assert 'PGRST_DB_URI="postgres://${DB_USERINFO}@${PG_NAME}:5432/postgres"' in s
assert 'authenticator:***' not in s
print('URI_COMPOSED_OK')
PY
scripts/proof-pg18-postgrest-web.sh
```

Output:

```text
URI_COMPOSED_OK
== PG18 PostgREST/web proof ==
pg_image=local/supabase-postgres:18-karval-rc1
postgrest_image=postgrest/postgrest@sha256:488093de819567422bc1d37cb79da6e84bca3726bac321daeed618f0ed957888
network=pg18-postgrest-proof-net
postgrest_url=http://127.0.0.1:13000
web_url=http://127.0.0.1:18082/docs/pg18-postgrest-web-proof.html
/run/postgresql:5432 - accepting connections
POSTGREST_API_OK
WEB_PROXY_API_OK
web_file=docs/pg18-postgrest-web-proof.html
```

## API proof

Direct PostgREST RPC:

```json
{"client": "web", "gateway": "postgrest", "message": "hello from pg18 postgrest", "preload": "pg_stat_statements, pgaudit, pg_cron, pg_net, pg_tle, safeupdate", "postgres_version": "18.0"}
```

Same-origin web proxy RPC:

```json
{"client": "web", "gateway": "postgrest", "message": "hello from pg18 postgrest", "preload": "pg_stat_statements, pgaudit, pg_cron, pg_net, pg_tle, safeupdate", "postgres_version": "18.0"}
```

Web HTTP:

```text
2426 /tmp/pg18-postgrest-web-proof.html
```

## Browser proof

- URL: `http://127.0.0.1:18082/docs/pg18-postgrest-web-proof.html`
- DOM status: `200 OK`
- DOM message: `hello from pg18 postgrest`
- DOM Postgres: `18.0`
- DOM preload: `pg_stat_statements, pgaudit, pg_cron, pg_net, pg_tle, safeupdate`
- Vision: PASS; page rendered the expected badge, title, status, message, Postgres version, preload, and JSON payload without visible breakage.

## CORS correction

Direct browser fetch to PostgREST was blocked because the PostgREST POST response did not include CORS headers in this image/config combination. The reproducible script now generates HTML that calls same-origin `/api/hello`, and `scripts/serve-pg18-postgrest-web-proof.py` proxies that request to PostgREST.

## Cleanup

The final script run used default cleanup mode. Verification after the run showed no `pg18-postgrest-proof-*` containers/network remained.
