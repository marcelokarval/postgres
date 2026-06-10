#!/usr/bin/env bash
# shellcheck shell=bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
INPUT_PATH=""
TRIAGE_DIR="${ROOT_DIR}/tmp/pg18-triage"
MODE="auto"

usage() {
  cat <<'EOF'
Usage: scripts/triage-pg18-failure.sh [options]

Collects and summarizes docker-image-test failure artifacts for the PG18 path.

Input modes:
  --output-dir PATH      A preserved docker-image-test OUTPUT_DIR (contains regression_output/)
  --validation-log-dir   A validate-pg18.sh log dir; script will inspect logs for preserved OUTPUT_DIR
  --latest-tmp           Auto-pick the newest /tmp/tmp.* with regression_output/ (default fallback)

Options:
  --triage-dir PATH      Base directory where triage bundles are written
  -h, --help             Show this help

Examples:
  scripts/triage-pg18-failure.sh --output-dir /tmp/tmp.abcd1234
  scripts/triage-pg18-failure.sh --validation-log-dir tmp/pg18-validation
  scripts/triage-pg18-failure.sh --latest-tmp
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --output-dir)
      MODE="output-dir"
      INPUT_PATH="$2"
      shift 2
      ;;
    --validation-log-dir)
      MODE="validation-log-dir"
      INPUT_PATH="$2"
      shift 2
      ;;
    --latest-tmp)
      MODE="latest-tmp"
      shift
      ;;
    --triage-dir)
      TRIAGE_DIR="$2"
      shift 2
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

log() {
  printf '[%s] %s\n' "$(date '+%Y-%m-%d %H:%M:%S')" "$*"
}

resolve_output_dir() {
  case "$MODE" in
    output-dir)
      printf '%s\n' "$INPUT_PATH"
      ;;
    validation-log-dir)
      local hit
      hit=$(grep -RhoE 'Test output preserved at: .*' "$INPUT_PATH" 2>/dev/null | tail -n1 | sed 's/^Test output preserved at: //') || true
      if [[ -n "$hit" ]]; then
        printf '%s\n' "$hit"
        return 0
      fi
      return 1
      ;;
    latest-tmp|auto)
      find /tmp -maxdepth 1 -type d -name 'tmp.*' -print 2>/dev/null | while read -r d; do
        if [[ -d "$d/regression_output" ]]; then
          printf '%s\n' "$d"
        fi
      done | xargs -r ls -td 2>/dev/null | head -n1
      ;;
    *)
      return 1
      ;;
  esac
}

OUTPUT_DIR="$(resolve_output_dir || true)"
if [[ -z "$OUTPUT_DIR" ]]; then
  echo "Could not resolve a docker-image-test output dir." >&2
  exit 1
fi

REG_DIR="$OUTPUT_DIR/regression_output"
RESULTS_DIR="$REG_DIR/results"
DIFFS_FILE="$REG_DIR/regression.diffs"
EXPECTED_DIR="$ROOT_DIR/nix/tests/expected"

if [[ ! -d "$REG_DIR" ]]; then
  echo "Resolved path does not contain regression_output/: $OUTPUT_DIR" >&2
  exit 1
fi

STAMP="$(date '+%Y%m%d-%H%M%S')"
BUNDLE_DIR="$TRIAGE_DIR/$STAMP"
mkdir -p "$BUNDLE_DIR/raw" "$BUNDLE_DIR/safe-candidates"

SUMMARY_MD="$BUNDLE_DIR/summary.md"
FAILED_LIST="$BUNDLE_DIR/failed-files.txt"
SAFE_COPY_LIST="$BUNDLE_DIR/safe-copy-candidates.txt"
: > "$FAILED_LIST"
: > "$SAFE_COPY_LIST"

if [[ -f "$DIFFS_FILE" ]]; then
  cp "$DIFFS_FILE" "$BUNDLE_DIR/raw/"
fi
if [[ -d "$RESULTS_DIR" ]]; then
  cp -r "$RESULTS_DIR" "$BUNDLE_DIR/raw/"
fi

extract_failed_files() {
  if [[ -f "$DIFFS_FILE" ]]; then
    grep -oE 'expected/[A-Za-z0-9_.-]+\.out|results/[A-Za-z0-9_.-]+\.out' "$DIFFS_FILE" \
      | sed -E 's@^(expected|results)/@@' \
      | sort -u
  elif [[ -d "$RESULTS_DIR" ]]; then
    find "$RESULTS_DIR" -maxdepth 1 -type f -name '*.out' -printf '%f\n' | sort -u
  fi
}

is_patched_shared_file() {
  case "$1" in
    roles.out|vault.out|pgmq.out|http.out) return 0 ;;
    *) return 1 ;;
  esac
}

candidate_z18_name() {
  local f="$1"
  if [[ "$f" == z_17_* ]]; then
    printf '%s\n' "z_18_${f#z_17_}"
  else
    printf '%s\n' ""
  fi
}

mapfile -t FAILED_FILES < <(extract_failed_files)
for f in "${FAILED_FILES[@]:-}"; do
  [[ -n "$f" ]] || continue
  printf '%s\n' "$f" >> "$FAILED_LIST"

  if is_patched_shared_file "$f"; then
    continue
  fi

  if [[ -f "$RESULTS_DIR/$f" ]]; then
    cp "$RESULTS_DIR/$f" "$BUNDLE_DIR/safe-candidates/"
    printf '%s\n' "$f" >> "$SAFE_COPY_LIST"
  fi
done

{
  echo "# PG18 failure triage summary"
  echo
  echo "- source_output_dir: $OUTPUT_DIR"
  echo "- regression_output: $REG_DIR"
  echo "- expected_dir: $EXPECTED_DIR"
  echo "- triage_bundle: $BUNDLE_DIR"
  echo
  echo "## Failed files"
  if [[ -s "$FAILED_LIST" ]]; then
    while read -r f; do
      [[ -n "$f" ]] || continue
      echo "- $f"
    done < "$FAILED_LIST"
  else
    echo "- none detected from regression.diffs parsing"
  fi
  echo
  echo "## Safe copied result files"
  if [[ -s "$SAFE_COPY_LIST" ]]; then
    while read -r f; do
      [[ -n "$f" ]] || continue
      echo "- $f"
    done < "$SAFE_COPY_LIST"
  else
    echo "- none"
  fi
  echo
  echo "## Files intentionally excluded from direct copy"
  echo "- roles.out"
  echo "- vault.out"
  echo "- pgmq.out"
  echo "- http.out"
  echo
  echo "## PG18-specific fixture candidates"
  any_candidate=false
  if [[ -s "$FAILED_LIST" ]]; then
    while read -r f; do
      [[ -n "$f" ]] || continue
      candidate="$(candidate_z18_name "$f")"
      if [[ -n "$candidate" ]]; then
        any_candidate=true
        echo "- $f -> $candidate"
      fi
    done < "$FAILED_LIST"
  fi
  if [[ "$any_candidate" == false ]]; then
    echo "- no z_17_* divergence candidates detected"
  fi
  echo
  echo "## Suggested next actions"
  echo "1. Inspect raw/regression.diffs and raw/results/*.out in the triage bundle."
  echo "2. If only z_17_* outputs diverged materially, consider creating z_18_* companions instead of replacing z_17_*."
  echo "3. Do not copy patched shared outputs (roles.out, vault.out, pgmq.out, http.out) back into nix/tests/expected/."
  echo "4. If divergence is legitimate, promote only safe-candidates/*.out after review."
} > "$SUMMARY_MD"

log "PG18 triage bundle written to: $BUNDLE_DIR"
log "Summary: $SUMMARY_MD"
