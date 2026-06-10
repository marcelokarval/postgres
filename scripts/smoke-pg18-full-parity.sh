#!/usr/bin/env bash
# shellcheck shell=bash
set -euo pipefail
IMAGE="${PG18_FULL_IMAGE:-local/supabase-postgres:18-karval-full}"
EXPECTED_IMAGE_ID="${PG18_EXPECTED_IMAGE_ID:-sha256:576f2d7cb01fdd0dacd37679eb37100e3da37102c536ecb3ed39173cdd39e9e3}"
NAME=""
KEEP=false
PASSWORD="local_pg18_smoke_password_only"
SQL_EXTENSIONS=(pg_cron pg_net pgaudit pgmq postgis pg_jsonschema vector rum pgroonga pgroonga_database index_advisor wal2json pg_repack plpgsql_check pgjwt pgrouting pgtap http pg_hashids pgsodium pg_graphql pg_stat_monitor pg_partman supabase_vault hypopg pg_tle wrappers)

need_value() {
  local flag="$1"
  local value="${2:-}"
  if [[ -z "$value" ]]; then
    echo "ERROR $flag requires a value" >&2
    exit 2
  fi
}

usage() {
  cat <<'EOF'
Usage: scripts/smoke-pg18-full-parity.sh [--image TAG] [--expected-image-id SHA256] [--name NAME] [--keep]

Runs a disposable PG18 full-parity smoke against a local image.
No production credentials are used or printed.
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --image) need_value "$1" "${2:-}"; IMAGE="$2"; shift 2 ;;
    --expected-image-id) need_value "$1" "${2:-}"; EXPECTED_IMAGE_ID="$2"; shift 2 ;;
    --name) need_value "$1" "${2:-}"; NAME="$2"; shift 2 ;;
    --keep) KEEP=true; shift ;;
    -h|--help) usage; exit 0 ;;
    *) echo "Unknown argument: $1" >&2; usage >&2; exit 2 ;;
  esac
done

if [[ -z "$NAME" ]]; then
  NAME="pg18-full-parity-smoke-$(date +%s)"
fi

cleanup() {
  if [[ "$KEEP" != true ]]; then
    docker rm -f "$NAME" >/dev/null 2>&1 || true
  fi
}
trap cleanup EXIT

echo "== starting disposable PG18 smoke =="
echo "image=$IMAGE"
echo "expected_image_id=$EXPECTED_IMAGE_ID"
echo "container=$NAME"

image_id="$(docker image inspect "$IMAGE" --format '{{.Id}}')"
[[ "$image_id" == "$EXPECTED_IMAGE_ID" ]] || { echo "ERROR image id mismatch: $image_id" >&2; exit 1; }

docker rm -f "$NAME" >/dev/null 2>&1 || true
docker run -d --name "$NAME"   -e POSTGRES_USER=supabase_admin   -e POSTGRES_PASSWORD="$PASSWORD"   -e POSTGRES_DB=postgres   "$IMAGE" >/dev/null

init_complete=false
for _ in $(seq 1 180); do
  if docker logs "$NAME" 2>&1 | grep -q 'PostgreSQL init process complete; ready for start up.'; then
    init_complete=true
    break
  fi
  if ! docker ps --format '{{.Names}}' | grep -qx "$NAME"; then
    echo "ERROR container exited during init" >&2
    docker logs "$NAME" --tail=240 >&2 || true
    exit 1
  fi
  sleep 2
done
[[ "$init_complete" == true ]] || { echo "ERROR timed out waiting for Supabase init completion marker" >&2; docker logs "$NAME" --tail=240 >&2 || true; exit 1; }

for _ in $(seq 1 120); do
  if docker exec "$NAME" pg_isready -U supabase_admin -d postgres >/dev/null 2>&1; then
    break
  fi
  if ! docker ps --format '{{.Names}}' | grep -qx "$NAME"; then
    echo "ERROR container exited before final readiness" >&2
    docker logs "$NAME" --tail=240 >&2 || true
    exit 1
  fi
  sleep 2
done

docker exec "$NAME" pg_isready -U supabase_admin -d postgres

echo "-- version/preload --"
docker exec "$NAME" psql -U supabase_admin -d postgres -Atc "select version(); show shared_preload_libraries;"
preload="$(docker exec "$NAME" psql -U supabase_admin -d postgres -Atc "show shared_preload_libraries;")"
expected_preload="pg_stat_statements, pgaudit, pg_cron, pg_net, pg_tle, safeupdate"
[[ "$preload" == "$expected_preload" ]] || { echo "ERROR preload mismatch actual=$preload expected=$expected_preload" >&2; exit 1; }

echo "-- create extension smoke --"
for ext in "${SQL_EXTENSIONS[@]}"; do
  docker exec "$NAME" psql -U supabase_admin -d postgres -v ON_ERROR_STOP=1 -qAtc "CREATE EXTENSION IF NOT EXISTS "$ext" CASCADE; select 'OK:$ext';"
done

echo "-- functional probes --"
jsonschema="$(docker exec "$NAME" psql -U supabase_admin -d postgres -Atc "select jsonb_matches_schema(\$\${\"type\":\"object\",\"required\":[\"x\"]}\$\$::json, \$\${\"x\":1}\$\$::jsonb);")"
[[ "$jsonschema" == "t" ]] || { echo "ERROR jsonschema probe expected t got $jsonschema" >&2; exit 1; }
postgis="$(docker exec "$NAME" psql -U supabase_admin -d postgres -Atc "select ST_AsText(ST_GeomFromText('POINT(1 2)'));")"
[[ "$postgis" == "POINT(1 2)" ]] || { echo "ERROR postgis probe got $postgis" >&2; exit 1; }
vector="$(docker exec "$NAME" psql -U supabase_admin -d postgres -Atc "select '[1,2,3]'::vector <-> '[1,2,4]'::vector;")"
[[ "$vector" == "1" || "$vector" == "1.0" ]] || { echo "ERROR vector probe got $vector" >&2; exit 1; }

docker exec "$NAME" psql -U supabase_admin -d postgres -v ON_ERROR_STOP=1 -qAtc "drop table if exists public.safeupdate_probe; create table public.safeupdate_probe(id int primary key, val int); insert into public.safeupdate_probe values (1,10),(2,20); select count(*) from public.safeupdate_probe;" >/dev/null
set +e
out="$(docker exec "$NAME" psql -U supabase_admin -d postgres -v ON_ERROR_STOP=1 -c "update public.safeupdate_probe set val = val + 1;" 2>&1)"
ec=$?
set -e
printf '%s
' "$out"
[[ "$ec" -ne 0 ]] || { echo "ERROR safeupdate allowed UPDATE without WHERE" >&2; exit 1; }
printf '%s
' "$out" | grep -q 'UPDATE requires a WHERE clause' || { echo "ERROR safeupdate failure was not the expected error" >&2; exit 1; }
where_result="$(docker exec "$NAME" psql -U supabase_admin -d postgres -Atc "update public.safeupdate_probe set val = val + 1 where id = 1; select val from public.safeupdate_probe where id=1; drop table public.safeupdate_probe;")"
printf '%s
' "$where_result" | grep -qx '11' || { echo "ERROR safeupdate WHERE update probe failed: $where_result" >&2; exit 1; }

echo "-- library-only surfaces --"
docker exec "$NAME" sh -lc 'test -n "$(find /nix/store /usr/lib/postgresql -type f -name "safeupdate*.so" 2>/dev/null | head -1)"'
docker exec "$NAME" sh -lc 'test -n "$(find /nix/store /usr/lib/postgresql -type f -name "supautils*.so" 2>/dev/null | head -1)"'
docker exec "$NAME" sh -lc 'test -n "$(find /nix/store /usr/lib/postgresql -type f -name "plan_filter*.so" 2>/dev/null | head -1)"'

echo "PG18_FULL_PARITY_SMOKE_OK"
