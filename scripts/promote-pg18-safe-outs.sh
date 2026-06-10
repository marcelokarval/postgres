#!/usr/bin/env bash
# shellcheck shell=bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TRIAGE_BUNDLE=""
PROMOTE_MODE="in-place"
TARGET_PREFIX=""
EXPECTED_DIR="${ROOT_DIR}/nix/tests/expected"
DRY_RUN=false

usage() {
  cat <<'EOF'
Usage: scripts/promote-pg18-safe-outs.sh --bundle PATH [options]

Promotes only reviewed-safe .out files from a PG18 triage bundle.

Required:
  --bundle PATH          Triage bundle directory created by triage-pg18-failure.sh

Options:
  --as-z18              Promote z_17_*.out as z_18_*.out siblings
  --in-place            Promote files using their existing filenames (default)
  --expected-dir PATH   Override nix/tests/expected target
  --dry-run             Print actions without copying files
  -h, --help            Show this help

Examples:
  scripts/promote-pg18-safe-outs.sh --bundle /tmp/pg18-triage-out/20260608-183431 --dry-run
  scripts/promote-pg18-safe-outs.sh --bundle /tmp/pg18-triage-out/20260608-183431 --as-z18
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --bundle)
      TRIAGE_BUNDLE="$2"
      shift 2
      ;;
    --as-z18)
      PROMOTE_MODE="as-z18"
      shift
      ;;
    --in-place)
      PROMOTE_MODE="in-place"
      shift
      ;;
    --expected-dir)
      EXPECTED_DIR="$2"
      shift 2
      ;;
    --dry-run)
      DRY_RUN=true
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

if [[ -z "$TRIAGE_BUNDLE" ]]; then
  usage >&2
  exit 2
fi

SAFE_DIR="$TRIAGE_BUNDLE/safe-candidates"
SAFE_LIST="$TRIAGE_BUNDLE/safe-copy-candidates.txt"
SUMMARY_FILE="$TRIAGE_BUNDLE/promotion-summary.txt"

if [[ ! -d "$SAFE_DIR" ]]; then
  echo "safe-candidates directory not found in bundle: $SAFE_DIR" >&2
  exit 1
fi
if [[ ! -f "$SAFE_LIST" ]]; then
  echo "safe-copy-candidates.txt not found in bundle: $SAFE_LIST" >&2
  exit 1
fi
if [[ ! -d "$EXPECTED_DIR" ]]; then
  echo "expected dir not found: $EXPECTED_DIR" >&2
  exit 1
fi

is_forbidden_shared_name() {
  case "$1" in
    roles.out|vault.out|pgmq.out|http.out) return 0 ;;
    *) return 1 ;;
  esac
}

map_target_name() {
  local src="$1"
  case "$PROMOTE_MODE" in
    in-place)
      printf '%s\n' "$src"
      ;;
    as-z18)
      if [[ "$src" == z_17_* ]]; then
        printf '%s\n' "z_18_${src#z_17_}"
      else
        printf '%s\n' "$src"
      fi
      ;;
    *)
      printf '%s\n' "$src"
      ;;
  esac
}

: > "$SUMMARY_FILE"
printf 'bundle=%s\nmode=%s\nexpected_dir=%s\ndry_run=%s\n\n' "$TRIAGE_BUNDLE" "$PROMOTE_MODE" "$EXPECTED_DIR" "$DRY_RUN" >> "$SUMMARY_FILE"

copied=0
skipped=0
while read -r filename; do
  [[ -n "$filename" ]] || continue

  if is_forbidden_shared_name "$filename"; then
    printf 'SKIP forbidden shared file: %s\n' "$filename" | tee -a "$SUMMARY_FILE"
    skipped=$((skipped + 1))
    continue
  fi

  src="$SAFE_DIR/$filename"
  if [[ ! -f "$src" ]]; then
    printf 'SKIP missing safe candidate payload: %s\n' "$filename" | tee -a "$SUMMARY_FILE"
    skipped=$((skipped + 1))
    continue
  fi

  target_name="$(map_target_name "$filename")"
  dest="$EXPECTED_DIR/$target_name"

  if [[ "$DRY_RUN" == true ]]; then
    printf 'DRYRUN copy %s -> %s\n' "$src" "$dest" | tee -a "$SUMMARY_FILE"
  else
    cp "$src" "$dest"
    printf 'COPIED %s -> %s\n' "$src" "$dest" | tee -a "$SUMMARY_FILE"
  fi
  copied=$((copied + 1))
done < "$SAFE_LIST"

printf '\nsummary: copied=%s skipped=%s\n' "$copied" "$skipped" | tee -a "$SUMMARY_FILE"
