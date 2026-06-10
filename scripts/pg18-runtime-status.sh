#!/usr/bin/env bash
# shellcheck shell=bash
set -euo pipefail
SERVICE="${PG18_SERVICE:-postgres18_postgres}"
IMAGE="${PG18_IMAGE:-local/supabase-postgres:18-karval}"
FULL_IMAGE="${PG18_FULL_IMAGE:-local/supabase-postgres:18-karval-full}"
EXPECTED_IMAGE_ID="${PG18_EXPECTED_IMAGE_ID:-sha256:576f2d7cb01fdd0dacd37679eb37100e3da37102c536ecb3ed39173cdd39e9e3}"
SQL_EXTENSIONS=(http hypopg index_advisor pg_cron pg_graphql pg_hashids pg_jsonschema pg_net pg_repack pg_stat_monitor pg_tle pgaudit pgjwt pgmq pgroonga pgroonga_database pgrouting pgsodium pgtap plpgsql_check postgis rum supabase_vault vector wal2json wrappers pg_partman)

echo "== PG18 runtime status =="
echo "service=$SERVICE"
echo "image=$IMAGE"
echo "full_image=$FULL_IMAGE"
echo "expected_image_id=$EXPECTED_IMAGE_ID"

echo "-- images --"
image_id="$(docker image inspect "$IMAGE" --format '{{.Id}}')"
full_image_id="$(docker image inspect "$FULL_IMAGE" --format '{{.Id}}')"
docker image inspect "$IMAGE" "$FULL_IMAGE" --format '{{.RepoTags}} {{.Id}} {{.Created}} {{.Size}}'
[[ "$image_id" == "$EXPECTED_IMAGE_ID" ]] || { echo "ERROR image id mismatch for $IMAGE: $image_id" >&2; exit 1; }
[[ "$full_image_id" == "$EXPECTED_IMAGE_ID" ]] || { echo "ERROR image id mismatch for $FULL_IMAGE: $full_image_id" >&2; exit 1; }

echo "-- service --"
docker service inspect "$SERVICE" >/dev/null
docker service ls --filter "name=$SERVICE" --format '{{.Name}} {{.Image}} {{.Replicas}}'

echo "-- live container --"
cid="$(docker ps --filter "label=com.docker.swarm.service.name=$SERVICE" --format '{{.ID}}' | head -1)"
if [[ -z "$cid" ]]; then
  echo "ERROR no live container for service $SERVICE" >&2
  exit 1
fi
docker ps --filter "id=$cid" --format '{{.ID}} {{.Image}} {{.Status}}'
container_image_id="$(docker inspect "$cid" --format '{{.Image}}')"
[[ "$container_image_id" == "$EXPECTED_IMAGE_ID" ]] || { echo "ERROR live container image id mismatch: $container_image_id" >&2; exit 1; }
echo "live_container_image_id=$container_image_id"

echo "-- active matching builds --"
ps -eo pid,ppid,stat,etime,pcpu,pmem,cmd | grep -E 'docker build -f Dockerfile-18|buildx build -f Dockerfile-18|nix profile add.*psql_18_slim' | grep -v grep || true

echo "-- postgres version/preload --"
docker exec "$cid" psql -U supabase_admin -d postgres -Atc "select version(); show shared_preload_libraries;"

echo "-- installed target extensions --"
for ext in "${SQL_EXTENSIONS[@]}"; do
  got="$(docker exec "$cid" psql -U supabase_admin -d postgres -Atc "select extname || '=' || extversion from pg_extension where extname='$ext';")"
  if [[ -z "$got" ]]; then
    echo "ERROR missing extension: $ext" >&2
    exit 1
  fi
  echo "$got"
done

echo "-- library-only surfaces --"
for lib in 'safeupdate*.so' 'supautils*.so' 'plan_filter*.so'; do
  found="$(docker exec "$cid" sh -lc "find /nix/store /usr/lib/postgresql -type f -name '$lib' 2>/dev/null | head -1")"
  if [[ -z "$found" ]]; then
    echo "ERROR missing library-only surface: $lib" >&2
    exit 1
  fi
  echo "$found"
done
