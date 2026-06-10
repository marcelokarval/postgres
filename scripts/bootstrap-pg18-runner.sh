#!/usr/bin/env bash
# shellcheck shell=bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
REPO_DIR="$ROOT_DIR"
NIX_MODE="official"
INSTALL_DOCKER=true
RUN_VALIDATION=true
VALIDATION_ARGS=()
ONLY_PRINT=false

usage() {
  cat <<'EOF'
Usage: scripts/bootstrap-pg18-runner.sh [options] [-- validate-args...]

Bootstrap a temporary Linux runner/VM for PG18 acceptance.

Defaults:
- install Nix using the official 2.34.6 installer/config path used by this repo
- install Docker only if missing
- run scripts/validate-pg18.sh after bootstrap

Options:
  --repo-dir PATH         Repo root (default: current repo)
  --nix-mode MODE         official | determinate (default: official)
  --skip-docker           Do not attempt Docker installation
  --skip-validation       Do not run validate-pg18.sh after bootstrap
  --print-only            Print the plan and exit without mutating the host
  -h, --help              Show this help

Examples:
  scripts/bootstrap-pg18-runner.sh
  scripts/bootstrap-pg18-runner.sh --skip-validation
  scripts/bootstrap-pg18-runner.sh --nix-mode determinate -- --skip-docker-test
  scripts/bootstrap-pg18-runner.sh --print-only
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --repo-dir)
      REPO_DIR="$2"
      shift 2
      ;;
    --nix-mode)
      NIX_MODE="$2"
      shift 2
      ;;
    --skip-docker)
      INSTALL_DOCKER=false
      shift
      ;;
    --skip-validation)
      RUN_VALIDATION=false
      shift
      ;;
    --print-only)
      ONLY_PRINT=true
      shift
      ;;
    --)
      shift
      VALIDATION_ARGS=("$@")
      break
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

if [[ ! -d "$REPO_DIR" ]]; then
  echo "repo dir not found: $REPO_DIR" >&2
  exit 1
fi

case "$NIX_MODE" in
  official|determinate) ;;
  *)
    echo "invalid --nix-mode: $NIX_MODE (expected official or determinate)" >&2
    exit 2
    ;;
esac

SUDO=""
if [[ "${EUID}" -ne 0 ]]; then
  SUDO="sudo"
fi

CURRENT_USER="${SUDO_USER:-${USER:-$(id -un)}}"
TMP_DIR="${TMPDIR:-/tmp}/pg18-runner-bootstrap"
mkdir -p "$TMP_DIR"
NIX_CONF_FILE="$TMP_DIR/nix.conf"
LOG_DIR="$REPO_DIR/tmp/pg18-runner-bootstrap"
mkdir -p "$LOG_DIR"
SUMMARY_FILE="$LOG_DIR/summary.txt"
: > "$SUMMARY_FILE"

log() {
  printf '[%s] %s\n' "$(date '+%Y-%m-%d %H:%M:%S')" "$*" | tee -a "$SUMMARY_FILE"
}

run_cmd() {
  log "RUN $*"
  "$@"
}

run_root() {
  if [[ -n "$SUDO" ]]; then
    run_cmd sudo "$@"
  else
    run_cmd "$@"
  fi
}

require_linux() {
  if [[ "$(uname -s)" != "Linux" ]]; then
    log "ERROR bootstrap-pg18-runner.sh currently targets Linux runners only"
    exit 1
  fi
}

write_nix_conf() {
  cat > "$NIX_CONF_FILE" <<EOF
allowed-users = *
always-allow-substitutes = true
auto-optimise-store = false
build-users-group = nixbld
builders-use-substitutes = true
cores = 0
experimental-features = nix-command flakes
max-jobs = auto
require-sigs = true
substituters = https://cache.nixos.org https://nix-postgres-artifacts.s3.amazonaws.com https://postgrest.cachix.org https://cache.nixos.org/
trusted-public-keys = cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY= nix-postgres-artifacts:dGZlQOvKcNEjvT7QEAJbcV6b6uk7VF/hWMjhYleiaLI= postgrest.cachix.org-1:icgW4R15fz1+LqvhPjt4EnX/r19AaqxiVV+1olwlZtI= cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY=
trusted-users = ${CURRENT_USER} root
EOF
  log "Wrote $NIX_CONF_FILE for trusted user $CURRENT_USER"
}

ensure_base_packages() {
  if command -v apt-get >/dev/null 2>&1; then
    run_root apt-get update
    run_root apt-get install -y ca-certificates curl git xz-utils jq
  else
    log "WARN apt-get not found; skipping base package installation"
  fi
}

source_nix_daemon() {
  if [[ -f /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh ]]; then
    # shellcheck disable=SC1091
    . /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh
  fi
}

configure_existing_nix() {
  run_root mkdir -p /etc/nix
  run_root cp "$NIX_CONF_FILE" /etc/nix/nix.conf
  if command -v systemctl >/dev/null 2>&1; then
    run_root systemctl restart nix-daemon || true
  fi
  source_nix_daemon
  nix --version
}

install_nix_official() {
  if command -v nix >/dev/null 2>&1; then
    log "Nix already present; updating /etc/nix/nix.conf instead of reinstalling"
    configure_existing_nix
    return
  fi

  write_nix_conf
  run_cmd bash -lc "curl -L https://releases.nixos.org/nix/nix-2.34.6/install | sh -s -- --daemon --yes --nix-extra-conf-file '$NIX_CONF_FILE'"
  source_nix_daemon
  nix --version
}

install_nix_determinate() {
  if command -v nix >/dev/null 2>&1; then
    log "Nix already present; updating /etc/nix/nix.conf instead of reinstalling"
    configure_existing_nix
    return
  fi

  write_nix_conf
  run_cmd bash -lc "curl -fsSL https://install.determinate.systems/nix | sh -s -- install --no-confirm"
  run_root mkdir -p /etc/nix
  run_root cp "$NIX_CONF_FILE" /etc/nix/nix.conf
  if command -v systemctl >/dev/null 2>&1; then
    run_root systemctl restart nix-daemon || true
  fi
  source_nix_daemon
  nix --version
}

ensure_docker() {
  if command -v docker >/dev/null 2>&1; then
    log "Docker already present: $(command -v docker)"
    return
  fi

  if [[ "$INSTALL_DOCKER" != true ]]; then
    log "ERROR docker missing and --skip-docker was set"
    exit 1
  fi

  if command -v apt-get >/dev/null 2>&1; then
    run_root apt-get update
    run_root apt-get install -y docker.io
    if command -v systemctl >/dev/null 2>&1; then
      run_root systemctl enable --now docker || true
    fi
    if getent group docker >/dev/null 2>&1; then
      run_root usermod -aG docker "$CURRENT_USER" || true
    fi
  else
    log "ERROR docker missing and no supported package manager path is implemented here"
    exit 1
  fi
}

print_plan() {
  cat <<EOF
PG18 runner bootstrap plan
- repo_dir: $REPO_DIR
- nix_mode: $NIX_MODE
- install_docker_if_missing: $INSTALL_DOCKER
- run_validation: $RUN_VALIDATION
- validation_args: ${VALIDATION_ARGS[*]:-(none)}
- nix_conf_file: $NIX_CONF_FILE
- log_dir: $LOG_DIR

Validation command:
  $REPO_DIR/scripts/validate-pg18.sh ${VALIDATION_ARGS[*]:-}
EOF
}

run_validation() {
  local cmd=("$REPO_DIR/scripts/validate-pg18.sh")
  if [[ ${#VALIDATION_ARGS[@]} -gt 0 ]]; then
    cmd+=("${VALIDATION_ARGS[@]}")
  fi
  log "Starting PG18 validation"
  (
    cd "$REPO_DIR"
    "${cmd[@]}"
  ) 2>&1 | tee "$LOG_DIR/validate-pg18.log"
}

require_linux
print_plan

if [[ "$ONLY_PRINT" == true ]]; then
  exit 0
fi

ensure_base_packages
case "$NIX_MODE" in
  official) install_nix_official ;;
  determinate) install_nix_determinate ;;
esac
ensure_docker

if [[ "$RUN_VALIDATION" == true ]]; then
  run_validation
else
  log "Validation skipped by flag"
fi

log "Bootstrap finished. Summary file: $SUMMARY_FILE"
