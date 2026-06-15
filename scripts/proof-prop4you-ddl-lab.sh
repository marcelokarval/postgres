#!/usr/bin/env bash
set -euo pipefail

# Prop4You DDL lab proof skeleton.
# This script intentionally validates only the current non-final skeleton unless
# PROP4YOU_APPLY_EXPERIMENTAL=1 is set by a future implementation slice.

LAB_DB="${LAB_DB:-pg18_prop4you_ddl_lab}"
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DDL_DIR="$PROJECT_ROOT/database/ddl/projects/prop4you"
DRY_RUN="${DRY_RUN:-1}"

usage() {
  cat <<USAGE
Usage: LAB_DB=pg18_prop4you_ddl_lab DRY_RUN=1 scripts/proof-prop4you-ddl-lab.sh

Current behavior:
  - checks that the Prop4You package skeleton exists;
  - prints the intended lab DB;
  - validates SQL syntax shape by listing skeleton files;
  - does not mutate any database while DRY_RUN=1.

Future behavior:
  - create clean lab DB;
  - apply database/ddl/base;
  - apply database/ddl/projects/prop4you package/subpackages;
  - run provider corpus fixtures and catalog comment checks;
  - generate docs/reports/prop4you-ddl-lab-proof.md.
USAGE
}

if [[ "${1:-}" == "--help" ]]; then
  usage
  exit 0
fi

if [[ ! -d "$DDL_DIR" ]]; then
  echo "missing Prop4You DDL directory: $DDL_DIR" >&2
  exit 1
fi

if [[ "$DRY_RUN" != "1" ]]; then
  echo "Refusing non-dry-run execution: final Prop4You DDL is not implemented yet." >&2
  echo "Set future implementation gates before enabling apply mode." >&2
  exit 2
fi

echo "prop4you_ddl_lab_skeleton_ok"
echo "lab_db=$LAB_DB"
echo "ddl_dir=$DDL_DIR"
find "$DDL_DIR" -maxdepth 2 -type f \( -name '*.sql' -o -name 'README.md' \) | sort
