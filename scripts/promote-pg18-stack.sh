#!/usr/bin/env bash
# shellcheck shell=bash
set -euo pipefail
FULL_IMAGE="${PG18_FULL_IMAGE:-local/supabase-postgres:18-karval-full}"
IMAGE="${PG18_IMAGE:-local/supabase-postgres:18-karval}"
SERVICE="${PG18_SERVICE:-postgres18_postgres}"
EXPECTED_IMAGE_ID="${PG18_EXPECTED_IMAGE_ID:-sha256:576f2d7cb01fdd0dacd37679eb37100e3da37102c536ecb3ed39173cdd39e9e3}"
APPLY=false
SQL_EXTENSIONS=(http hypopg index_advisor pg_cron pg_graphql pg_hashids pg_jsonschema pg_net pg_repack pg_stat_monitor pg_tle pgaudit pgjwt pgmq pgroonga pgroonga_database pgrouting pgsodium pgtap plpgsql_check postgis rum supabase_vault vector wal2json wrappers pg_partman)

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
Usage: scripts/promote-pg18-stack.sh [--apply] [--full-image TAG] [--image TAG] [--expected-image-id SHA256] [--service NAME] [--skip-update]

Default mode is validate-only: no docker tag and no Swarm service update are performed.
Use --apply explicitly to retag FULL_IMAGE as IMAGE and force the Swarm service to restart on IMAGE.
--skip-update is accepted for backward compatibility and keeps validate-only mode.
Does not print production secrets.
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --apply) APPLY=true; shift ;;
    --full-image) need_value "$1" "${2:-}"; FULL_IMAGE="$2"; shift 2 ;;
    --image) need_value "$1" "${2:-}"; IMAGE="$2"; shift 2 ;;
    --expected-image-id) need_value "$1" "${2:-}"; EXPECTED_IMAGE_ID="$2"; shift 2 ;;
    --service) need_value "$1" "${2:-}"; SERVICE="$2"; shift 2 ;;
    --skip-update) APPLY=false; shift ;;
    -h|--help) usage; exit 0 ;;
    *) echo "Unknown argument: $1" >&2; usage >&2; exit 2 ;;
  esac
done

echo "== PG18 stack validation/promotion =="
echo "mode=$([[ "$APPLY" == true ]] && echo apply || echo validate-only)"
echo "full_image=$FULL_IMAGE"
echo "image=$IMAGE"
echo "expected_image_id=$EXPECTED_IMAGE_ID"
echo "service=$SERVICE"

docker service inspect "$SERVICE" >/dev/null

if [[ "$APPLY" == true ]]; then
  full_id="$(docker image inspect "$FULL_IMAGE" --format '{{.Id}}')"
  [[ "$full_id" == "$EXPECTED_IMAGE_ID" ]] || { echo "ERROR full image id mismatch: $full_id" >&2; exit 1; }
  docker tag "$FULL_IMAGE" "$IMAGE"
  image_id="$(docker image inspect "$IMAGE" --format '{{.Id}}')"
  [[ "$image_id" == "$EXPECTED_IMAGE_ID" ]] || { echo "ERROR promoted image id mismatch: $image_id" >&2; exit 1; }
  docker image inspect "$IMAGE" --format '{{.Id}} {{.Created}} {{.Size}}'
  docker service update --detach=false --force --image "$IMAGE" "$SERVICE"
else
  echo "validate_only_no_retag_or_service_update=true"
fi

for _ in $(seq 1 150); do
  replicas="$(docker service ls --filter "name=$SERVICE" --format '{{.Replicas}}')"
  echo "replicas=$replicas"
  [[ "$replicas" == "1/1" ]] && break
  sleep 2
done
[[ "$(docker service ls --filter "name=$SERVICE" --format '{{.Replicas}}')" == "1/1" ]] || { echo "ERROR service did not converge" >&2; exit 1; }

cid="$(docker ps --filter "label=com.docker.swarm.service.name=$SERVICE" --format '{{.ID}}' | head -1)"
[[ -n "$cid" ]] || { echo "ERROR no live container for $SERVICE" >&2; exit 1; }
container_image_id="$(docker inspect "$cid" --format '{{.Image}}')"
[[ "$container_image_id" == "$EXPECTED_IMAGE_ID" ]] || { echo "ERROR live container image id mismatch: $container_image_id" >&2; exit 1; }
echo "live_container_image_id=$container_image_id"
docker exec "$cid" pg_isready -U supabase_admin -d postgres
preload="$(docker exec "$cid" psql -U supabase_admin -d postgres -Atc "show shared_preload_libraries;")"
expected_preload="pg_stat_statements, pgaudit, pg_cron, pg_net, pg_tle, safeupdate"
[[ "$preload" == "$expected_preload" ]] || { echo "ERROR preload mismatch: $preload" >&2; exit 1; }

for ext in "${SQL_EXTENSIONS[@]}"; do
  got="$(docker exec "$cid" psql -U supabase_admin -d postgres -Atc "select extname from pg_extension where extname='$ext';")"
  [[ "$got" == "$ext" ]] || { echo "ERROR missing extension in live task: $ext" >&2; exit 1; }
  echo "$got"
done

for lib in 'safeupdate*.so' 'supautils*.so' 'plan_filter*.so'; do
  found="$(docker exec "$cid" sh -lc "find /nix/store /usr/lib/postgresql -type f -name '$lib' 2>/dev/null | head -1")"
  if [[ -z "$found" ]]; then
    echo "ERROR missing library-only surface in live task: $lib" >&2
    exit 1
  fi
  echo "$found"
done

echo "PG18_STACK_PROMOTION_OK"
