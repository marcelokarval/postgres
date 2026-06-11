#!/usr/bin/env bash
# shellcheck shell=bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
RUNNER_IMAGE="${PG18_NIX_RUNNER_IMAGE:-local/pg18-self-hosted-runner:validation}"
RUNNER_DOCKERFILE="${PG18_NIX_RUNNER_DOCKERFILE:-docker/pg18-self-hosted-runner/Dockerfile}"
NIX_VOLUME="${PG18_NIX_VOLUME:-pg18-nix-store}"
LOG_DIR="${PG18_VALIDATE_LOG_DIR:-${ROOT_DIR}/tmp/pg18-publish/full-validate-persistent-nix}"
OUTER_LOG="${PG18_VALIDATE_OUTER_LOG:-${ROOT_DIR}/tmp/pg18-publish/nix-full-validate-persistent.log}"
IMAGE_TAG="${PG18_VALIDATE_IMAGE_TAG:-local/supabase-postgres:18-karval-full-validate}"
NIX_MAX_JOBS="${PG18_NIX_MAX_JOBS:-1}"
NIX_CORES="${PG18_NIX_CORES:-16}"
ACCEPT_FLAKE_CONFIG="${PG18_ACCEPT_FLAKE_CONFIG:-true}"
REQUIRE_KVM="${PG18_REQUIRE_KVM:-true}"
KVM_DEVICE_ARGS=()
KVM_NIX_FEATURE=""
REBUILD_RUNNER=false
RESET_NIX_VOLUME=false

usage() {
  cat <<'EOF'
Usage: scripts/run-pg18-persistent-nix-validate.sh [options]

Runs scripts/validate-pg18.sh without skips inside the local Nix runner while
persisting /nix in a Docker named volume. This avoids losing the Nix store
between retries after validation-script fixes.

Options:
  --runner-image IMAGE      Runner image (default: local/pg18-self-hosted-runner:validation)
  --nix-volume NAME         Docker volume mounted at /nix (default: pg18-nix-store)
  --log-dir PATH            Inner validate log dir (default: tmp/pg18-publish/full-validate-persistent-nix)
  --outer-log PATH          Outer tee log (default: tmp/pg18-publish/nix-full-validate-persistent.log)
  --image-tag TAG           Validation Docker image tag for Dockerfile-18
  --rebuild-runner          Rebuild the local runner image before running
  --reset-nix-volume        Remove and recreate the Nix volume before running
  -h, --help                Show help

Environment overrides:
  PG18_NIX_RUNNER_IMAGE
  PG18_NIX_RUNNER_DOCKERFILE
  PG18_NIX_VOLUME
  PG18_VALIDATE_LOG_DIR
  PG18_VALIDATE_OUTER_LOG
  PG18_VALIDATE_IMAGE_TAG
  PG18_NIX_MAX_JOBS          Nix derivations in parallel inside runner (default: 1)
  PG18_NIX_CORES             Cores exposed to each derivation; controls heavy cargo/make -j (default: 16)
  PG18_ACCEPT_FLAKE_CONFIG   Trust repo flake substituters/public keys in runner (default: true)
  PG18_REQUIRE_KVM           Require /dev/kvm before running full VM-test gate (default: true)
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --runner-image)
      RUNNER_IMAGE="${2:?missing runner image}"
      shift 2
      ;;
    --nix-volume)
      NIX_VOLUME="${2:?missing nix volume}"
      shift 2
      ;;
    --log-dir)
      LOG_DIR="${2:?missing log dir}"
      shift 2
      ;;
    --outer-log)
      OUTER_LOG="${2:?missing outer log}"
      shift 2
      ;;
    --image-tag)
      IMAGE_TAG="${2:?missing image tag}"
      shift 2
      ;;
    --rebuild-runner)
      REBUILD_RUNNER=true
      shift
      ;;
    --reset-nix-volume)
      RESET_NIX_VOLUME=true
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

mkdir -p "$(dirname "$OUTER_LOG")" "$LOG_DIR"

container_path() {
  local host_path="$1"
  if [[ "$host_path" == "$ROOT_DIR" ]]; then
    printf '/work'
  elif [[ "$host_path" == "$ROOT_DIR"/* ]]; then
    printf '/work/%s' "${host_path#"$ROOT_DIR"/}"
  else
    printf '%s' "$host_path"
  fi
}

CONTAINER_LOG_DIR="$(container_path "$LOG_DIR")"

if [[ "$REBUILD_RUNNER" == true ]] || ! docker image inspect "$RUNNER_IMAGE" >/dev/null 2>&1; then
  docker build -f "$ROOT_DIR/$RUNNER_DOCKERFILE" -t "$RUNNER_IMAGE" "$ROOT_DIR"
fi

if [[ "$RESET_NIX_VOLUME" == true ]]; then
  docker volume rm "$NIX_VOLUME" >/dev/null 2>&1 || true
fi

docker volume create "$NIX_VOLUME" >/dev/null

if [[ -e /dev/kvm ]]; then
  KVM_DEVICE_ARGS=(--device /dev/kvm)
  KVM_NIX_FEATURE="kvm"
elif [[ "$REQUIRE_KVM" == true ]]; then
  cat >&2 <<'EOF'
ERROR: /dev/kvm is not available on the host, but this full no-skip PG18 gate
requires NixOS VM tests with the Nix system feature `kvm`.

The Nix build will otherwise fail at VM-test checks such as ext-pg_jsonschema:
  Required features: {kvm, nixos-test}

Enable KVM on the host/runner before rerunning, for example:
  sudo modprobe kvm
  sudo modprobe kvm_intel   # Intel hosts
  sudo modprobe kvm_amd     # AMD hosts

Then verify:
  ls -l /dev/kvm

If this machine cannot expose KVM, move this gate to a KVM-capable runner.
Set PG18_REQUIRE_KVM=false only for diagnostic/non-release runs.
EOF
  exit 86
fi

# Important: Docker initializes an empty named volume with the image's existing
# /nix contents on first mount. That preserves the single-user Nix install from
# the runner image while making subsequent builds cacheable across attempts.
{
  echo "== persistent nix validate =="
  echo "root=$ROOT_DIR"
  echo "runner_image=$RUNNER_IMAGE"
  echo "nix_volume=$NIX_VOLUME"
  echo "log_dir_host=$LOG_DIR"
  echo "log_dir_container=$CONTAINER_LOG_DIR"
  echo "image_tag=$IMAGE_TAG"
  echo "nix_max_jobs=$NIX_MAX_JOBS"
  echo "nix_cores=$NIX_CORES"
  echo "accept_flake_config=$ACCEPT_FLAKE_CONFIG"
  echo "require_kvm=$REQUIRE_KVM"
  echo "kvm_nix_feature=${KVM_NIX_FEATURE:-none}"
  docker run --rm \
    -e "PG18_NIX_MAX_JOBS=$NIX_MAX_JOBS" \
    -e "PG18_NIX_CORES=$NIX_CORES" \
    -e "PG18_ACCEPT_FLAKE_CONFIG=$ACCEPT_FLAKE_CONFIG" \
    -e "PG18_NIX_EXTRA_FEATURE=$KVM_NIX_FEATURE" \
    "${KVM_DEVICE_ARGS[@]}" \
    -v "$NIX_VOLUME":/nix \
    -v "$ROOT_DIR":/work \
    -v /var/run/docker.sock:/var/run/docker.sock \
    -w /work \
    --entrypoint bash \
    "$RUNNER_IMAGE" \
    -lc 'set -euo pipefail
      if ! getent group nixbld >/dev/null; then groupadd -r nixbld; fi
      for i in $(seq 1 16); do
        id nixbld$i >/dev/null 2>&1 || useradd -r -g nixbld -G nixbld -d /var/empty -s /usr/sbin/nologin nixbld$i
      done
      git config --global --add safe.directory /work
      export NIX_CONFIG="max-jobs = ${PG18_NIX_MAX_JOBS:-1}
cores = ${PG18_NIX_CORES:-16}"
      if [[ -n "${PG18_NIX_EXTRA_FEATURE:-}" ]]; then
        export NIX_CONFIG="$NIX_CONFIG
extra-system-features = ${PG18_NIX_EXTRA_FEATURE}"
      fi
      if [[ "${PG18_ACCEPT_FLAKE_CONFIG:-true}" == "true" ]]; then
        export NIX_CONFIG="$NIX_CONFIG
accept-flake-config = true"
      fi
      nix --version
      printf "nix_config=%s\\n" "$(printf "%s" "$NIX_CONFIG" | tr "\n" ";")"
      docker version --format "client={{.Client.Version}} server={{.Server.Version}}"
      bash scripts/validate-pg18.sh --log-dir "'"$CONTAINER_LOG_DIR"'" --image-tag "'"$IMAGE_TAG"'"'
} 2>&1 | tee "$OUTER_LOG"
