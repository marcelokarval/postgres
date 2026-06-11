#!/usr/bin/env bash
# shellcheck shell=bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
LOG_DIR="${ROOT_DIR}/tmp/pg18-validation"
IMAGE_TAG="pg-docker-test:18"
RUN_NIX_BUILDS=true
RUN_DOCKER_BUILD=true
RUN_DOCKER_TEST=true

usage() {
  cat <<'EOF'
Usage: scripts/validate-pg18.sh [options]

Runs the first real PostgreSQL 18 validation pass for this fork.

Options:
  --log-dir PATH         Directory for logs and summary output
  --image-tag TAG        Docker image tag to use for Dockerfile-18 (default: pg-docker-test:18)
  --skip-nix-builds      Skip all nix build steps
  --skip-docker-build    Skip docker build for Dockerfile-18
  --skip-docker-test     Skip nix docker-image-test harness
  -h, --help             Show this help

Examples:
  scripts/validate-pg18.sh
  scripts/validate-pg18.sh --skip-docker-test
  scripts/validate-pg18.sh --log-dir /tmp/pg18-validation
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --log-dir)
      if [[ $# -lt 2 || -z "${2:-}" ]]; then
        echo "Missing value for --log-dir" >&2
        usage >&2
        exit 2
      fi
      LOG_DIR="$2"
      shift 2
      ;;
    --image-tag)
      if [[ $# -lt 2 || -z "${2:-}" ]]; then
        echo "Missing value for --image-tag" >&2
        usage >&2
        exit 2
      fi
      IMAGE_TAG="$2"
      shift 2
      ;;
    --skip-nix-builds)
      RUN_NIX_BUILDS=false
      shift
      ;;
    --skip-docker-build)
      RUN_DOCKER_BUILD=false
      shift
      ;;
    --skip-docker-test)
      RUN_DOCKER_TEST=false
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "Unknown argument: $1" >&2
      usage >&2
      exit 2
      ;;
  esac
done

mkdir -p "$LOG_DIR"
SUMMARY_FILE="$LOG_DIR/summary.txt"
: > "$SUMMARY_FILE"

log() {
  printf '[%s] %s\n' "$(date '+%Y-%m-%d %H:%M:%S')" "$*" | tee -a "$SUMMARY_FILE"
}

require_cmd() {
  if ! command -v "$1" >/dev/null 2>&1; then
    log "ERROR missing required command: $1"
    exit 1
  fi
}

run_step() {
  local name="$1"
  shift
  local logfile="$LOG_DIR/${name}.log"
  log "START $name"
  set +e
  (
    cd "$ROOT_DIR"
    "$@"
  ) > >(tee "$logfile") 2>&1
  local status=$?
  set -e
  if [[ $status -ne 0 ]]; then
    log "FAIL  $name exit_code=$status logfile=$logfile"
    exit "$status"
  fi
  log "DONE  $name"
}

log "ROOT_DIR=$ROOT_DIR"
log "LOG_DIR=$LOG_DIR"
log "IMAGE_TAG=$IMAGE_TAG"
log "RUN_NIX_BUILDS=$RUN_NIX_BUILDS"
log "RUN_DOCKER_BUILD=$RUN_DOCKER_BUILD"
log "RUN_DOCKER_TEST=$RUN_DOCKER_TEST"

if [[ "$RUN_NIX_BUILDS" == true || "$RUN_DOCKER_TEST" == true ]]; then
  require_cmd nix
fi

if [[ "$RUN_DOCKER_BUILD" == true ]]; then
  require_cmd docker
fi

if [[ "$RUN_NIX_BUILDS" == true ]]; then
  run_step 01-psql_18_bin nix build .#psql_18/bin -L
  run_step 02-psql_18_slim_bin nix build .#psql_18_slim/bin -L

  run_step 03-ext-pg_jsonschema nix build .#checks.x86_64-linux.ext-pg_jsonschema -L
  run_step 04-ext-pgaudit nix build .#checks.x86_64-linux.ext-pgaudit -L
  run_step 05-ext-pgmq nix build .#checks.x86_64-linux.ext-pgmq -L
  run_step 06-ext-postgis nix build .#checks.x86_64-linux.ext-postgis -L
  run_step 07-ext-vector nix build .#checks.x86_64-linux.ext-vector -L
  run_step 08-ext-pg_cron nix build .#checks.x86_64-linux.ext-pg_cron -L
  run_step 09-ext-pg_net nix build .#checks.x86_64-linux.ext-pg_net -L

  run_step 10-check-psql_18 nix build .#checks.x86_64-linux.psql_18 -L
  run_step 11-check-psql_18_slim nix build .#checks.x86_64-linux.psql_18_slim -L
  run_step 12-check-postgresql_18_debug nix build .#checks.x86_64-linux.postgresql_18_debug -L
  run_step 13-check-postgresql_18_src nix build .#checks.x86_64-linux.postgresql_18_src -L
fi

if [[ "$RUN_DOCKER_BUILD" == true ]]; then
  run_step 14-docker-build docker build -f Dockerfile-18 -t "$IMAGE_TAG" .
fi

if [[ "$RUN_DOCKER_TEST" == true ]]; then
  run_step 15-docker-image-test nix run .#docker-image-test -- --no-build --image-tag "$IMAGE_TAG" Dockerfile-18
fi

log "PG18 validation sequence finished successfully"
log "Summary file: $SUMMARY_FILE"
