#!/usr/bin/env bash
set -euo pipefail

COMPOSE_FILE="docker/pg18-postgrest-rls/compose.pg18-postgrest-rls.yml"
STACK_DIR="docker/pg18-postgrest-rls"
KEEP_STACK=false
RESET_VOLUMES=true
LOG_DIR="tmp/pg18-realtime-v2-smoke"

usage() {
  cat <<'USAGE'
Usage: scripts/smoke-pg18-realtime-v2.sh [--keep-stack] [--no-reset-volumes] [--log-dir DIR]

Deterministic local smoke for the PG18 PostgREST/JWT/RLS/realtime v2 proof.

Default behavior:
  - starts the local compose stack from a clean DB volume;
  - proves HTTP/RLS, can_subscribe, WebSocket subscribe/replay/live event/ACK, denied subscription and invalid token;
  - shuts the stack down on success/failure.

Options:
  --keep-stack        leave the stack running so a human can inspect http://127.0.0.1:18083/
  --no-reset-volumes  do not remove compose volumes before starting
  --log-dir DIR       write evidence logs to DIR
USAGE
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --keep-stack) KEEP_STACK=true; shift ;;
    --no-reset-volumes) RESET_VOLUMES=false; shift ;;
    --log-dir) LOG_DIR="$2"; shift 2 ;;
    -h|--help) usage; exit 0 ;;
    *) echo "unknown arg: $1" >&2; usage >&2; exit 2 ;;
  esac
done

mkdir -p "$LOG_DIR"

cleanup() {
  if [[ "$KEEP_STACK" != true ]]; then
    docker compose -f "$COMPOSE_FILE" down -v --remove-orphans >"$LOG_DIR/compose-down.log" 2>&1 || true
  fi
}
trap cleanup EXIT

redact_pg_url() {
  sed -E 's#(postgres://)[^@]+@#\1[REDACTED]@#g'
}

run() {
  echo "+ $*" | tee -a "$LOG_DIR/commands.log"
  "$@"
}

echo "PG18 realtime v2 smoke starting" | tee "$LOG_DIR/summary.txt"
echo "keep_stack=$KEEP_STACK reset_volumes=$RESET_VOLUMES" | tee -a "$LOG_DIR/summary.txt"

if [[ "$RESET_VOLUMES" == true ]]; then
  docker compose -f "$COMPOSE_FILE" down -v --remove-orphans >"$LOG_DIR/compose-down-before.log" 2>&1 || true
else
  docker compose -f "$COMPOSE_FILE" down --remove-orphans >"$LOG_DIR/compose-down-before.log" 2>&1 || true
fi

run docker compose -f "$COMPOSE_FILE" config >"$LOG_DIR/compose-config.yml"
run docker compose -f "$COMPOSE_FILE" up -d --build >"$LOG_DIR/compose-up.log" 2>&1

for i in $(seq 1 120); do
  pg="$(docker inspect -f '{{.State.Health.Status}}' pg18-rls-db 2>/dev/null || true)"
  pgrst="$(curl -fsS http://127.0.0.1:13001/ >/dev/null 2>&1 && echo ok || true)"
  rt="$(curl -fsS http://127.0.0.1:18084/healthz >/dev/null 2>&1 && echo ok || true)"
  web="$(curl -fsS http://127.0.0.1:18083/healthz >/dev/null 2>&1 && echo ok || true)"
  if [[ "$pg" == healthy && "$pgrst" == ok && "$rt" == ok && "$web" == ok ]]; then
    echo "ready pg=$pg postgrest=$pgrst realtime=$rt web=$web" | tee -a "$LOG_DIR/summary.txt"
    break
  fi
  sleep 2
  if [[ "$i" == 120 ]]; then
    echo "ERROR stack not ready pg=$pg postgrest=$pgrst realtime=$rt web=$web" | tee -a "$LOG_DIR/summary.txt" >&2
    docker compose -f "$COMPOSE_FILE" ps | tee "$LOG_DIR/compose-ps-failed.log" >&2 || true
    docker logs --tail 200 pg18-rls-db >"$LOG_DIR/db-tail.log" 2>&1 || true
    docker logs --tail 200 pg18-rls-postgrest >"$LOG_DIR/postgrest-tail.log" 2>&1 || true
    docker logs --tail 200 pg18-rls-realtime >"$LOG_DIR/realtime-tail.log" 2>&1 || true
    docker logs --tail 200 pg18-rls-web >"$LOG_DIR/web-tail.log" 2>&1 || true
    exit 1
  fi
done

docker compose -f "$COMPOSE_FILE" ps | tee "$LOG_DIR/compose-ps.log"

curl -fsS -X POST http://127.0.0.1:18083/api/current-profile | tee "$LOG_DIR/current-profile.json" | python3 -m json.tool >/dev/null

TOKEN="$("$STACK_DIR/scripts/make_jwt.py")"
{
  echo "allowed=$(curl -fsS -X POST http://127.0.0.1:13001/rpc/can_subscribe \
    -H "Authorization: Bearer $TOKEN" \
    -H 'Content-Type: application/json' \
    -d '{"p_scope_type":"user","p_scope_id":"user_karval_demo","p_topic":"proof.realtime"}')"
  echo "denied=$(curl -fsS -X POST http://127.0.0.1:13001/rpc/can_subscribe \
    -H "Authorization: Bearer $TOKEN" \
    -H 'Content-Type: application/json' \
    -d '{"p_scope_type":"user","p_scope_id":"user_other_demo","p_topic":"proof.realtime"}')"
} >"$LOG_DIR/can-subscribe.txt"
grep -q 'allowed=true' "$LOG_DIR/can-subscribe.txt"
grep -q 'denied=false' "$LOG_DIR/can-subscribe.txt"

anon_code="$(curl -sS -o "$LOG_DIR/anon-current-profile.json" -w '%{http_code}' -X POST http://127.0.0.1:13001/rpc/current_profile -H 'Content-Type: application/json' -d '{}')"
[[ "$anon_code" == "401" ]] || { echo "ERROR expected anon 401 got $anon_code" >&2; exit 1; }

# Start a tracked finite websocket client, then publish one event so live delivery and ACK happen.
docker compose -f "$COMPOSE_FILE" exec -T \
  -e WS_URL=ws://127.0.0.1:4000/ws \
  -e LAST_EVENT_ID=0 \
  realtime node test-client.js >"$LOG_DIR/ws-live-client.log" 2>&1 &
ws_pid=$!
sleep 2
curl -fsS -X POST http://127.0.0.1:18083/api/publish-realtime | tee "$LOG_DIR/publish.json" | python3 -m json.tool >/dev/null
wait "$ws_pid"

grep -q '"type":"event"' "$LOG_DIR/ws-live-client.log"
grep -q '"type":"ack"' "$LOG_DIR/ws-live-client.log"

# Replay should now include durable history and ACK metadata.
docker compose -f "$COMPOSE_FILE" exec -T \
  -e WS_URL=ws://127.0.0.1:4000/ws \
  -e LAST_EVENT_ID=0 \
  realtime node test-client.js >"$LOG_DIR/ws-replay-client.log" 2>&1
grep -q '"type":"replay"' "$LOG_DIR/ws-replay-client.log"
grep -q '"acked_at"' "$LOG_DIR/ws-replay-client.log"

# Negative checks.
docker compose -f "$COMPOSE_FILE" exec -T \
  -e WS_URL=ws://127.0.0.1:4000/ws \
  -e DENIED_SCOPE_ID=user_other_demo \
  realtime node test-client.js >"$LOG_DIR/ws-denied-client.log" 2>&1
grep -q 'subscription_denied' "$LOG_DIR/ws-denied-client.log"

docker compose -f "$COMPOSE_FILE" exec -T \
  -e WS_URL=ws://127.0.0.1:4000/ws \
  -e INVALID_TOKEN=1 \
  realtime node test-client.js >"$LOG_DIR/ws-invalid-token-client.log" 2>&1
grep -q 'invalid jwt signature' "$LOG_DIR/ws-invalid-token-client.log"

# Durable ACK read-back.
docker compose -f "$COMPOSE_FILE" exec -T pg18 \
  psql -U supabase_admin -d postgres -v ON_ERROR_STOP=1 -P pager=off \
  -c "select e.id, e.scope_type, e.scope_id, e.topic, a.app_user_id as ack_user, a.acked_at is not null as acked from private.event_outbox e left join private.realtime_event_acks a on a.event_id=e.id order by e.id;" \
  | tee "$LOG_DIR/ack-readback.txt"
grep -q ' t' "$LOG_DIR/ack-readback.txt"

cat >"$LOG_DIR/summary.txt" <<SUMMARY
PG18 realtime v2 smoke PASS
html_url=http://127.0.0.1:18083/
keep_stack=$KEEP_STACK
logs=$LOG_DIR
checks=current-profile, can-subscribe true/false, anon 401, live websocket event, replay with acked_at, denied subscription, invalid token, durable ACK readback
SUMMARY

cat "$LOG_DIR/summary.txt"
if [[ "$KEEP_STACK" == true ]]; then
  echo "Stack left running for human/browser inspection: http://127.0.0.1:18083/"
fi
