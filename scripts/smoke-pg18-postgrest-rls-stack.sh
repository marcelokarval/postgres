#!/usr/bin/env bash
# shellcheck shell=bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
STACK_DIR="$ROOT_DIR/docker/pg18-postgrest-rls"
COMPOSE_FILE="$STACK_DIR/compose.pg18-postgrest-rls.yml"
LOG_DIR="${PG18_RLS_LOG_DIR:-$ROOT_DIR/tmp/pg18-rls-stack}"
PGRST_PORT="${PG18_DEV_PGRST_PORT:-13001}"
WEB_PORT="${PG18_DEV_WEB_PORT:-18083}"
APP_USER_ID="${PG18_DEV_APP_USER_ID:-user_karval_demo}"
OTHER_USER_ID="user_other_demo"
KEEP=false

usage() {
  cat <<'EOF'
Usage: scripts/smoke-pg18-postgrest-rls-stack.sh [--keep]

Starts the durable PG18/PostgREST/web compose stack, validates:
- PostgREST hello RPC
- authenticated current_profile RPC using local JWT
- RLS isolation for a second JWT user
- anonymous denial for current_profile
- web proxy endpoint

Default mode cleans up the compose stack at exit. Use --keep for browser inspection.
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --keep) KEEP=true; shift ;;
    -h|--help) usage; exit 0 ;;
    *) echo "Unknown argument: $1" >&2; usage >&2; exit 2 ;;
  esac
done

mkdir -p "$LOG_DIR"
cleanup() {
  if [[ "$KEEP" != true ]]; then
    docker compose -f "$COMPOSE_FILE" down -v --remove-orphans >/dev/null 2>&1 || true
  fi
}
trap cleanup EXIT

cd "$STACK_DIR"
docker compose -f "$COMPOSE_FILE" down -v --remove-orphans >/dev/null 2>&1 || true
docker compose -f "$COMPOSE_FILE" up -d --pull never --remove-orphans | tee "$LOG_DIR/compose-up.log"

init_complete=false
for _ in $(seq 1 180); do
  if docker logs pg18-rls-db 2>&1 | grep -q 'PostgreSQL init process complete; ready for start up.'; then
    init_complete=true
    break
  fi
  if ! docker ps --format '{{.Names}}' | grep -qx 'pg18-rls-db'; then
    echo 'ERROR pg18-rls-db exited during init' >&2
    docker logs pg18-rls-db --tail=240 >&2 || true
    exit 1
  fi
  sleep 2
done
if [[ "$init_complete" != true ]]; then
  echo 'ERROR timed out waiting for PG init marker' >&2
  docker logs pg18-rls-db --tail=240 >&2 || true
  exit 1
fi
for _ in $(seq 1 120); do
  if docker exec pg18-rls-db pg_isready -U supabase_admin -d postgres >/dev/null 2>&1; then
    break
  fi
  sleep 1
done
docker exec pg18-rls-db pg_isready -U supabase_admin -d postgres | tee "$LOG_DIR/pg-isready.log"

hello_payload=''
for _ in $(seq 1 120); do
  hello_code="$(curl -s -o "$LOG_DIR/hello-probe.json" -w '%{http_code}' -X POST "http://127.0.0.1:$PGRST_PORT/rpc/hello" -H 'Content-Type: application/json' -d '{}' || true)"
  if [[ "$hello_code" == "200" ]]; then
    hello_payload="$(cat "$LOG_DIR/hello-probe.json")"
    break
  fi
  sleep 1
done
if [[ "${hello_code:-}" != "200" ]]; then
  echo "ERROR PostgREST hello RPC not ready, last_status=${hello_code:-none}" >&2
  cat "$LOG_DIR/hello-probe.json" >&2 || true
  docker logs pg18-rls-postgrest --tail=240 >&2 || true
  exit 1
fi
echo "$hello_payload" | tee "$LOG_DIR/hello.json" | jq -e '.gateway == "postgrest"' >/dev/null

make_token() {
  PG18_DEV_APP_USER_ID="$1" python3 "$STACK_DIR/scripts/make_jwt.py"
}
karval_token="$(make_token "$APP_USER_ID")"
other_token="$(make_token "$OTHER_USER_ID")"

karval_payload="$(curl -fsS -X POST "http://127.0.0.1:$PGRST_PORT/rpc/current_profile" -H 'Content-Type: application/json' -H "Authorization: Bearer $karval_token" -d '{}')"
echo "$karval_payload" | tee "$LOG_DIR/current-profile-karval.json" | jq -e --arg u "$APP_USER_ID" '.app_user_id == $u and .jwt_app_user_id == $u and .role == "authenticated" and .plan == "rc1"' >/dev/null

other_payload="$(curl -fsS -X POST "http://127.0.0.1:$PGRST_PORT/rpc/current_profile" -H 'Content-Type: application/json' -H "Authorization: Bearer $other_token" -d '{}')"
echo "$other_payload" | tee "$LOG_DIR/current-profile-other.json" | jq -e --arg u "$OTHER_USER_ID" '.app_user_id == $u and .jwt_app_user_id == $u and .plan == "blocked"' >/dev/null

anon_code="$(curl -s -o "$LOG_DIR/current-profile-anon.json" -w '%{http_code}' -X POST "http://127.0.0.1:$PGRST_PORT/rpc/current_profile" -H 'Content-Type: application/json' -d '{}')"
echo "anon_code=$anon_code" | tee "$LOG_DIR/anon-code.txt"
if [[ "$anon_code" == "200" ]]; then
  echo "Expected anonymous current_profile to be denied" >&2
  exit 1
fi

for _ in $(seq 1 90); do
  if curl -fsS "http://127.0.0.1:$WEB_PORT/healthz" >/dev/null 2>&1; then
    break
  fi
  sleep 1
done
web_payload="$(curl -fsS -X POST "http://127.0.0.1:$WEB_PORT/api/current-profile")"
echo "$web_payload" | tee "$LOG_DIR/web-current-profile.json" | jq -e --arg u "$APP_USER_ID" '.app_user_id == $u and .plan == "rc1"' >/dev/null
curl -fsS -o "$LOG_DIR/web.html" "http://127.0.0.1:$WEB_PORT/docs/pg18-postgrest-rls-web.html"
wc -c "$LOG_DIR/web.html" | tee "$LOG_DIR/web-html-size.txt"

printf 'PG18_POSTGREST_RLS_STACK_OK\n'
printf 'web_url=http://127.0.0.1:%s/docs/pg18-postgrest-rls-web.html\n' "$WEB_PORT"
if [[ "$KEEP" == true ]]; then
  printf 'kept_compose_stack=true\n'
fi
