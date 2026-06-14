#!/usr/bin/env bash
set -Eeuo pipefail

usage() {
  cat <<'USAGE'
Usage: scripts/apply-ddl-package.sh --package <path> (--dry-run|--apply|--status) [--database-url <url>] [--schema <schema>]

Options:
  --package <path>       Directory containing ordered *.sql files.
  --dry-run              Print deterministic file order and sha256 checksums; do not connect or mutate.
  --apply                Apply package idempotently using <schema>.ddl_migrations.
  --status               Show installer tracking rows if the tracking table exists.
  --database-url <url>   Optional PostgreSQL URL. Used only as a psql connection argument; never printed.
  --schema <schema>      Tracking schema. Default: base.
  -h, --help             Show this help.

Connection:
  If --database-url is omitted, psql uses DATABASE_URL and/or PG* environment variables.
USAGE
}

PACKAGE_DIR=""
MODE=""
DATABASE_URL_ARG=""
TRACKING_SCHEMA="base"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --package)
      [[ $# -ge 2 ]] || { echo "ERROR: --package requires a path" >&2; exit 2; }
      PACKAGE_DIR="$2"; shift 2 ;;
    --dry-run|--apply|--status)
      [[ -z "$MODE" ]] || { echo "ERROR: choose exactly one mode" >&2; exit 2; }
      MODE="${1#--}"; shift ;;
    --database-url)
      [[ $# -ge 2 ]] || { echo "ERROR: --database-url requires a value" >&2; exit 2; }
      DATABASE_URL_ARG="$2"; shift 2 ;;
    --schema)
      [[ $# -ge 2 ]] || { echo "ERROR: --schema requires a value" >&2; exit 2; }
      TRACKING_SCHEMA="$2"; shift 2 ;;
    -h|--help)
      usage; exit 0 ;;
    *)
      echo "ERROR: unknown argument: $1" >&2; usage >&2; exit 2 ;;
  esac
done

[[ -n "$PACKAGE_DIR" ]] || { echo "ERROR: --package is required" >&2; usage >&2; exit 2; }
[[ -n "$MODE" ]] || { echo "ERROR: one of --dry-run, --apply, or --status is required" >&2; usage >&2; exit 2; }
[[ -d "$PACKAGE_DIR" ]] || { echo "ERROR: package directory not found: $PACKAGE_DIR" >&2; exit 2; }
[[ "$TRACKING_SCHEMA" =~ ^[A-Za-z_][A-Za-z0-9_]*$ ]] || { echo "ERROR: invalid tracking schema name" >&2; exit 2; }

command -v psql >/dev/null 2>&1 || { [[ "$MODE" == "dry-run" ]] || { echo "ERROR: psql is required" >&2; exit 127; }; }
command -v sha256sum >/dev/null 2>&1 || { echo "ERROR: sha256sum is required" >&2; exit 127; }

PACKAGE_ABS="$(cd "$PACKAGE_DIR" && pwd -P)"
PACKAGE_NAME="$(basename "$PACKAGE_ABS")"

mapfile -t SQL_FILES < <(find "$PACKAGE_ABS" -maxdepth 1 -type f -name '*.sql' -printf '%p\n' | LC_ALL=C sort)
[[ ${#SQL_FILES[@]} -gt 0 ]] || { echo "ERROR: no *.sql files found in package: $PACKAGE_DIR" >&2; exit 2; }

psql_base_args=(-X -v ON_ERROR_STOP=1)
if [[ -n "$DATABASE_URL_ARG" ]]; then
  psql_base_args+=("$DATABASE_URL_ARG")
elif [[ -n "${PGHOST:-}" || -n "${PGSERVICE:-}" ]]; then
  # Explicit libpq PG* environment wins over an inherited DATABASE_URL.
  # This prevents stale container-only URLs such as host=postgres from breaking
  # local proof runs that deliberately set PGHOST/PGPORT.
  :
elif [[ -n "${DATABASE_URL:-}" ]]; then
  # psql/libpq do not automatically consume DATABASE_URL in every environment.
  # Pass it as a connection string while keeping all output credential-safe.
  psql_base_args+=("$DATABASE_URL")
fi

psql_exec() {
  psql "${psql_base_args[@]}" "$@"
}

tracking_regclass_sql() {
  printf "select to_regclass('%s.ddl_migrations') is not null;" "$TRACKING_SCHEMA"
}

tracking_exists() {
  local result
  result="$(psql_exec -At --set=tracking_schema="$TRACKING_SCHEMA" -c "$(tracking_regclass_sql)")"
  [[ "$result" == "t" ]]
}

sql_literal() {
  local s=${1//\/\\}
  s=${s//\'/\'\'}
  printf "'%s'" "$s"
}

migration_row() {
  local filename="$1"
  local package_lit filename_lit
  package_lit="$(sql_literal "$PACKAGE_NAME")"
  filename_lit="$(sql_literal "$filename")"
  psql_exec -At \
    -c "select checksum || E'\t' || status from \"$TRACKING_SCHEMA\".ddl_migrations where package_name = $package_lit and filename = $filename_lit;"
}

record_status() {
  local filename="$1" checksum="$2" status="$3" execution_ms="$4" error_message="${5:-}" metadata="${6-}"
  [[ -n "$metadata" ]] || metadata='{}'
  local package_lit filename_lit checksum_lit status_lit error_lit metadata_lit
  package_lit="$(sql_literal "$PACKAGE_NAME")"
  filename_lit="$(sql_literal "$filename")"
  checksum_lit="$(sql_literal "$checksum")"
  status_lit="$(sql_literal "$status")"
  error_lit="$(sql_literal "$error_message")"
  metadata_lit="$(sql_literal "$metadata")"
  psql_exec -q \
    -c "insert into \"$TRACKING_SCHEMA\".ddl_migrations (package_name, filename, checksum, execution_ms, status, error_message, metadata)
        values ($package_lit, $filename_lit, $checksum_lit, $execution_ms::integer, $status_lit, nullif($error_lit,''), $metadata_lit::jsonb)
        on conflict (package_name, filename) do update
           set checksum = excluded.checksum,
               applied_at = now(),
               applied_by = current_user,
               execution_ms = excluded.execution_ms,
               status = excluded.status,
               error_message = excluded.error_message,
               metadata = \"$TRACKING_SCHEMA\".ddl_migrations.metadata || excluded.metadata
         where \"$TRACKING_SCHEMA\".ddl_migrations.checksum = excluded.checksum;"
}

if [[ "$MODE" == "dry-run" ]]; then
  echo "DDL package dry-run"
  echo "package_name=$PACKAGE_NAME"
  echo "package_path=$PACKAGE_ABS"
  echo "tracking_schema=$TRACKING_SCHEMA"
  echo "files:"
  for file in "${SQL_FILES[@]}"; do
    checksum="$(sha256sum "$file" | cut -d ' ' -f 1)"
    printf '  %s  %s\n' "$checksum" "$(basename "$file")"
  done
  exit 0
fi

if [[ "$MODE" == "status" ]]; then
  echo "DDL package status"
  echo "package_name=$PACKAGE_NAME"
  echo "tracking_schema=$TRACKING_SCHEMA"
  if ! tracking_exists; then
    echo "tracking_table=absent"
    echo "No tracking table found at ${TRACKING_SCHEMA}.ddl_migrations."
    exit 0
  fi
  psql_exec \
    -c "select package_name, filename, checksum, status, applied_at, applied_by, execution_ms, error_message from \"$TRACKING_SCHEMA\".ddl_migrations where package_name = $(sql_literal "$PACKAGE_NAME") order by filename;"
  exit 0
fi

# apply mode
if ! tracking_exists; then
  first_file="$(basename "${SQL_FILES[0]}")"
  if [[ "$first_file" != 0001_*.sql ]]; then
    echo "ERROR: tracking table is absent and first sorted file is not 0001_*.sql" >&2
    exit 1
  fi
fi

echo "DDL package apply"
echo "package_name=$PACKAGE_NAME"
echo "package_path=$PACKAGE_ABS"
echo "tracking_schema=$TRACKING_SCHEMA"
echo "database_url=REDACTED_OR_ENV"

for file in "${SQL_FILES[@]}"; do
  filename="$(basename "$file")"
  checksum="$(sha256sum "$file" | cut -d ' ' -f 1)"

  if tracking_exists; then
    existing="$(migration_row "$filename" || true)"
    if [[ -n "$existing" ]]; then
      existing_checksum="${existing%%$'\t'*}"
      existing_status="${existing#*$'\t'}"
      if [[ "$existing_checksum" != "$checksum" ]]; then
        echo "ERROR: checksum drift for $filename in package $PACKAGE_NAME" >&2
        echo "       recorded=$existing_checksum" >&2
        echo "       current =$checksum" >&2
        exit 1
      fi
      if [[ "$existing_status" == "applied" ]]; then
        echo "SKIP $filename checksum=$checksum"
        continue
      fi
    fi
  fi

  echo "APPLY $filename checksum=$checksum"
  start_ms="$(date +%s%3N)"
  set +e
  apply_output="$(psql_exec --single-transaction -f "$file" 2>&1)"
  apply_rc=$?
  set -e
  end_ms="$(date +%s%3N)"
  execution_ms=$((end_ms - start_ms))

  if [[ $apply_rc -ne 0 ]]; then
    echo "$apply_output" >&2
    echo "ERROR: failed applying $filename" >&2
    if tracking_exists; then
      safe_error="$(printf '%s' "$apply_output" | tr '\n' ' ' | cut -c 1-1000)"
      record_status "$filename" "$checksum" "failed" "$execution_ms" "$safe_error" "{\"installer\":\"apply-ddl-package.sh\"}" || true
    fi
    exit "$apply_rc"
  fi

  if tracking_exists; then
    record_status "$filename" "$checksum" "applied" "$execution_ms" "" "{\"installer\":\"apply-ddl-package.sh\"}"
  else
    echo "WARN: tracking table still absent after $filename; unable to record migration" >&2
  fi
  echo "DONE $filename execution_ms=$execution_ms"
done

echo "DDL package apply complete"
