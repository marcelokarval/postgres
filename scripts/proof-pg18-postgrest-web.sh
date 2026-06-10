#!/usr/bin/env bash
# shellcheck shell=bash
set -euo pipefail

PG_IMAGE="${PG18_RC_IMAGE:-local/supabase-postgres:18-karval-rc1}"
PGRST_IMAGE="${PG18_PGRST_IMAGE:-postgrest/postgrest@sha256:488093de819567422bc1d37cb79da6e84bca3726bac321daeed618f0ed957888}"
NETWORK="${PG18_PGRST_NETWORK:-pg18-postgrest-proof-net}"
PG_NAME="${PG18_PGRST_PG_NAME:-pg18-postgrest-proof-db}"
PGRST_NAME="${PG18_PGRST_NAME:-pg18-postgrest-proof-api}"
PGRST_PORT="${PG18_PGRST_PORT:-13000}"
WEB_PORT="${PG18_WEB_PORT:-18082}"
KEEP=false
PASSWORD="local_pg18_postgres_password_only"
AUTH_CRED="local_pg18_postgrest_authenticator_only"
DB_USERINFO="authenticator:${AUTH_CRED}"
WEB_PID=""

usage() {
  cat <<'EOF'
Usage: scripts/proof-pg18-postgrest-web.sh [--keep]

Starts disposable local containers:
- PG18 release-candidate image
- pinned PostgREST gateway

Creates a tiny database-centric api schema/RPC, writes a static web client proof page,
and verifies the same-origin local web proxy endpoint `/api/hello`.
No production credentials are used or printed.
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --keep) KEEP=true; shift ;;
    -h|--help) usage; exit 0 ;;
    *) echo "Unknown argument: $1" >&2; usage >&2; exit 2 ;;
  esac
done

cleanup() {
  if [[ -n "${WEB_PID:-}" ]]; then
    kill "$WEB_PID" >/dev/null 2>&1 || true
    wait "$WEB_PID" >/dev/null 2>&1 || true
  fi
  if [[ "$KEEP" != true ]]; then
    docker rm -f "$PGRST_NAME" "$PG_NAME" >/dev/null 2>&1 || true
    docker network rm "$NETWORK" >/dev/null 2>&1 || true
  fi
}
trap cleanup EXIT

mkdir -p docs tmp/pg18-rc

echo "== PG18 PostgREST/web proof =="
echo "pg_image=$PG_IMAGE"
echo "postgrest_image=$PGRST_IMAGE"
echo "network=$NETWORK"
echo "postgrest_url=http://127.0.0.1:$PGRST_PORT"
echo "web_url=http://127.0.0.1:$WEB_PORT/docs/pg18-postgrest-web-proof.html"

docker rm -f "$PGRST_NAME" "$PG_NAME" >/dev/null 2>&1 || true
docker network rm "$NETWORK" >/dev/null 2>&1 || true
docker network create "$NETWORK" >/dev/null

docker run -d --name "$PG_NAME" --network "$NETWORK" \
  -e POSTGRES_USER=supabase_admin \
  -e POSTGRES_PASSWORD="$PASSWORD" \
  -e POSTGRES_DB=postgres \
  "$PG_IMAGE" >/dev/null

init_complete=false
for _ in $(seq 1 180); do
  if docker logs "$PG_NAME" 2>&1 | grep -q 'PostgreSQL init process complete; ready for start up.'; then
    init_complete=true
    break
  fi
  if ! docker ps --format '{{.Names}}' | grep -qx "$PG_NAME"; then
    echo "ERROR PG container exited during init" >&2
    docker logs "$PG_NAME" --tail=240 >&2 || true
    exit 1
  fi
  sleep 2
done
[[ "$init_complete" == true ]] || { echo "ERROR timed out waiting for PG init marker" >&2; docker logs "$PG_NAME" --tail=240 >&2 || true; exit 1; }

for _ in $(seq 1 120); do
  if docker exec "$PG_NAME" pg_isready -U supabase_admin -d postgres >/dev/null 2>&1; then
    break
  fi
  sleep 2
done
docker exec "$PG_NAME" pg_isready -U supabase_admin -d postgres

docker exec -i "$PG_NAME" psql -U supabase_admin -d postgres -v ON_ERROR_STOP=1 >/dev/null <<SQL
DO \$\$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'web_anon') THEN
    CREATE ROLE web_anon NOLOGIN;
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'authenticator') THEN
    CREATE ROLE authenticator LOGIN PASSWORD '$AUTH_CRED';
  ELSE
    ALTER ROLE authenticator LOGIN PASSWORD '$AUTH_CRED';
  END IF;
END
\$\$;
GRANT web_anon TO authenticator;
CREATE SCHEMA IF NOT EXISTS api;
GRANT USAGE ON SCHEMA api TO web_anon;
CREATE OR REPLACE FUNCTION api.hello()
RETURNS jsonb
LANGUAGE sql
STABLE
SECURITY DEFINER
AS \$\$
  SELECT jsonb_build_object(
    'message', 'hello from pg18 postgrest',
    'postgres_version', current_setting('server_version'),
    'preload', current_setting('shared_preload_libraries'),
    'gateway', 'postgrest',
    'client', 'web'
  );
\$\$;
GRANT EXECUTE ON FUNCTION api.hello() TO web_anon;
SQL

docker run -d --name "$PGRST_NAME" --network "$NETWORK" -p "127.0.0.1:$PGRST_PORT:3000" \
  -e PGRST_DB_URI="postgres://${DB_USERINFO}@${PG_NAME}:5432/postgres" \
  -e PGRST_DB_SCHEMAS="api" \
  -e PGRST_DB_ANON_ROLE="web_anon" \
  -e PGRST_SERVER_PORT="3000" \
  "$PGRST_IMAGE" >/dev/null

for _ in $(seq 1 90); do
  if curl -fsS "http://127.0.0.1:$PGRST_PORT/" >/dev/null 2>&1; then
    break
  fi
  if ! docker ps --format '{{.Names}}' | grep -qx "$PGRST_NAME"; then
    echo "ERROR PostgREST container exited" >&2
    docker logs "$PGRST_NAME" --tail=240 >&2 || true
    exit 1
  fi
  sleep 1
done

api_payload="$(curl -fsS -X POST "http://127.0.0.1:$PGRST_PORT/rpc/hello" -H 'Content-Type: application/json' -d '{}')"
echo "$api_payload" | jq -e '.message == "hello from pg18 postgrest" and .gateway == "postgrest" and .client == "web"' >/dev/null
cat > docs/pg18-postgrest-web-proof.html <<HTML
<!doctype html>
<html lang="pt-BR">
<head>
  <meta charset="utf-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1" />
  <title>PG18 PostgREST Web Proof</title>
  <style>
    body{font-family:Inter,system-ui,sans-serif;background:#0b1020;color:#eaf0ff;margin:0;padding:32px}.card{max-width:920px;margin:auto;background:#111a33;border:1px solid #2f4277;border-radius:18px;padding:28px;box-shadow:0 20px 60px #0008}.badge{display:inline-block;background:#1e7f4f;color:#d8ffe8;padding:6px 10px;border-radius:999px;font-weight:700}.grid{display:grid;grid-template-columns:180px 1fr;gap:10px;margin-top:20px}.k{color:#8fb3ff}.v{font-family:ui-monospace,monospace;background:#0a1228;border-radius:8px;padding:8px;white-space:pre-wrap}button{background:#5b8cff;color:white;border:0;border-radius:10px;padding:10px 14px;font-weight:700;cursor:pointer}pre{background:#071022;border:1px solid #22335f;border-radius:12px;padding:16px;overflow:auto}</style>
</head>
<body>
  <main class="card">
    <span class="badge">POSTGREST WEB PROOF</span>
    <h1>PG18 database-centric gateway proof</h1>
    <p>Cliente web simples consumindo RPC <code>api.hello()</code> via PostgREST.</p>
    <button id="reload">Chamar /rpc/hello</button>
    <div class="grid">
      <div class="k">API</div><div class="v" id="api">/api/hello</div>
      <div class="k">Status</div><div class="v" id="status">loading</div>
      <div class="k">Message</div><div class="v" id="message">...</div>
      <div class="k">Postgres</div><div class="v" id="pg">...</div>
      <div class="k">Preload</div><div class="v" id="preload">...</div>
    </div>
    <h2>Payload</h2>
    <pre id="payload">{}</pre>
  </main>
<script>
async function callApi(){
  const status = document.getElementById('status');
  status.textContent = 'fetching';
  const res = await fetch('/api/hello', {method:'POST', headers:{'Content-Type':'application/json'}, body:'{}'});
  const data = await res.json();
  status.textContent = res.status + ' ' + (res.ok ? 'OK' : 'ERROR');
  document.getElementById('message').textContent = data.message || '';
  document.getElementById('pg').textContent = data.postgres_version || '';
  document.getElementById('preload').textContent = data.preload || '';
  document.getElementById('payload').textContent = JSON.stringify(data, null, 2);
}
document.getElementById('reload').onclick = callApi;
callApi();
</script>
</body>
</html>
HTML

echo "$api_payload" > tmp/pg18-rc/postgrest-api-payload.json

python3 scripts/serve-pg18-postgrest-web-proof.py > tmp/pg18-rc/web-proxy.log 2>&1 &
WEB_PID="$!"
for _ in $(seq 1 40); do
  if curl -fsS "http://127.0.0.1:$WEB_PORT/healthz" >/dev/null 2>&1; then
    break
  fi
  sleep 0.5
done
curl -fsS "http://127.0.0.1:$WEB_PORT/healthz" >/dev/null
web_payload="$(curl -fsS -X POST "http://127.0.0.1:$WEB_PORT/api/hello")"
echo "$web_payload" | jq -e '.message == "hello from pg18 postgrest" and .gateway == "postgrest" and .client == "web"' >/dev/null
echo "$web_payload" > tmp/pg18-rc/web-proxy-api.json
curl -fsS -o /tmp/pg18-postgrest-web-proof.html "http://127.0.0.1:$WEB_PORT/docs/pg18-postgrest-web-proof.html"
wc -c /tmp/pg18-postgrest-web-proof.html > tmp/pg18-rc/web-http.txt

printf 'POSTGREST_API_OK\n'
printf 'WEB_PROXY_API_OK\n'
printf 'web_file=docs/pg18-postgrest-web-proof.html\n'
if [[ "$KEEP" == true ]]; then
  printf 'kept_pg_container=%s\nkept_postgrest_container=%s\nkept_network=%s\n' "$PG_NAME" "$PGRST_NAME" "$NETWORK"
fi
