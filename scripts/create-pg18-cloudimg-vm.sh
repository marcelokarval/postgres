#!/usr/bin/env bash
# shellcheck shell=bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
VM_NAME="pg18-runner"
WORK_DIR="$ROOT_DIR/tmp/pg18-cloudimg-vm"
BASE_IMAGE_URL="https://cloud-images.ubuntu.com/minimal/releases/noble/release/ubuntu-24.04-minimal-cloudimg-amd64.img"
BASE_IMAGE="$WORK_DIR/ubuntu-24.04-minimal-cloudimg-amd64.img"
DISK_IMAGE="$WORK_DIR/${VM_NAME}.qcow2"
SEED_IMAGE="$WORK_DIR/${VM_NAME}-seed.img"
META_DATA="$WORK_DIR/meta-data"
USER_DATA="$WORK_DIR/user-data"
TEMPLATE_FILE="$ROOT_DIR/cloud-init/pg18-runner-user-data.tpl.yaml"
REPO_URL=""
REPO_REF=""
SSH_PORT=2222
MEMORY_MB=8192
CPUS=4
DISK_SIZE="40G"
AUTO_BOOTSTRAP=true
VALIDATION_ARGS=""
PRINT_ONLY=false

usage() {
  cat <<'EOF'
Usage: scripts/create-pg18-cloudimg-vm.sh [options]

Create a disposable Ubuntu 24.04 cloud-image VM for PG18 acceptance work.

Options:
  --name NAME               VM name (default: pg18-runner)
  --work-dir PATH           Working directory for image/seed/log files
  --repo-url URL            Git URL to clone inside the VM (default: current origin url)
  --repo-ref REF            Git ref/branch to checkout inside the VM (default: current branch)
  --ssh-port PORT           Host port forwarded to guest 22 (default: 2222)
  --memory-mb N             Memory in MB (default: 8192)
  --cpus N                  vCPU count (default: 4)
  --disk-size SIZE          Overlay qcow2 size (default: 40G)
  --validation-args TEXT    Args passed through to bootstrap-pg18-runner.sh after --
  --no-auto-bootstrap       Boot VM ready to run bootstrap manually instead of auto-running it
  --print-only              Render cloud-init plan and exit
  -h, --help                Show this help

Examples:
  scripts/create-pg18-cloudimg-vm.sh --print-only
  scripts/create-pg18-cloudimg-vm.sh --validation-args '--skip-docker-test'
  scripts/create-pg18-cloudimg-vm.sh --repo-url https://github.com/your/fork.git --repo-ref karval/pg18-bootstrap
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --name)
      VM_NAME="$2"; shift 2 ;;
    --work-dir)
      WORK_DIR="$2"; shift 2 ;;
    --repo-url)
      REPO_URL="$2"; shift 2 ;;
    --repo-ref)
      REPO_REF="$2"; shift 2 ;;
    --ssh-port)
      SSH_PORT="$2"; shift 2 ;;
    --memory-mb)
      MEMORY_MB="$2"; shift 2 ;;
    --cpus)
      CPUS="$2"; shift 2 ;;
    --disk-size)
      DISK_SIZE="$2"; shift 2 ;;
    --validation-args)
      VALIDATION_ARGS="$2"; shift 2 ;;
    --no-auto-bootstrap)
      AUTO_BOOTSTRAP=false; shift ;;
    --print-only)
      PRINT_ONLY=true; shift ;;
    -h|--help)
      usage; exit 0 ;;
    *)
      echo "Unknown argument: $1" >&2
      usage >&2
      exit 2 ;;
  esac
done

if [[ -z "$REPO_URL" ]]; then
  REPO_URL="$(git -C "$ROOT_DIR" remote get-url origin 2>/dev/null || true)"
fi
if [[ -z "$REPO_REF" ]]; then
  REPO_REF="$(git -C "$ROOT_DIR" branch --show-current 2>/dev/null || true)"
fi
if [[ -z "$REPO_URL" || -z "$REPO_REF" ]]; then
  echo "Could not infer repo url/ref; pass --repo-url and --repo-ref explicitly." >&2
  exit 1
fi

mkdir -p "$WORK_DIR"
BASE_IMAGE="$WORK_DIR/ubuntu-24.04-minimal-cloudimg-amd64.img"
DISK_IMAGE="$WORK_DIR/${VM_NAME}.qcow2"
SEED_IMAGE="$WORK_DIR/${VM_NAME}-seed.img"
META_DATA="$WORK_DIR/meta-data"
USER_DATA="$WORK_DIR/user-data"
SERIAL_LOG="$WORK_DIR/${VM_NAME}-serial.log"
PID_FILE="$WORK_DIR/${VM_NAME}.pid"

find_ssh_key() {
  for key in "$HOME/.ssh/id_ed25519.pub" "$HOME/.ssh/id_rsa.pub"; do
    if [[ -f "$key" ]]; then
      cat "$key"
      return 0
    fi
  done
  return 1
}

render_ssh_key() {
  local key
  if key="$(find_ssh_key)"; then
    printf '%s' "$key"
  else
    printf '%s' 'ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIFakeKeyPlaceholderReplaceMeIfYouWant real-local-access-disabled'
  fi
}

escape_sed() {
  printf '%s' "$1" | sed -e 's/[\/&]/\\&/g'
}

render_user_data() {
  local ssh_key repo_url repo_ref validation_args auto_bootstrap
  ssh_key="$(escape_sed "$(render_ssh_key)")"
  repo_url="$(escape_sed "$REPO_URL")"
  repo_ref="$(escape_sed "$REPO_REF")"
  validation_args="$(escape_sed "$VALIDATION_ARGS")"
  auto_bootstrap="$AUTO_BOOTSTRAP"

  sed \
    -e "s/__SSH_AUTH_KEY__/${ssh_key}/g" \
    -e "s/__REPO_URL__/${repo_url}/g" \
    -e "s/__REPO_REF__/${repo_ref}/g" \
    -e "s/__VALIDATION_ARGS__/${validation_args}/g" \
    -e "s/__AUTO_BOOTSTRAP__/${auto_bootstrap}/g" \
    "$TEMPLATE_FILE" > "$USER_DATA"
}

render_meta_data() {
  cat > "$META_DATA" <<EOF
instance-id: ${VM_NAME}
local-hostname: ${VM_NAME}
EOF
}

print_plan() {
  cat <<EOF
PG18 cloudimg VM plan
- vm_name: $VM_NAME
- work_dir: $WORK_DIR
- base_image_url: $BASE_IMAGE_URL
- repo_url: $REPO_URL
- repo_ref: $REPO_REF
- ssh_port: $SSH_PORT
- memory_mb: $MEMORY_MB
- cpus: $CPUS
- disk_size: $DISK_SIZE
- auto_bootstrap: $AUTO_BOOTSTRAP
- validation_args: ${VALIDATION_ARGS:-(none)}
- serial_log: $SERIAL_LOG

Expected SSH:
  ssh -p $SSH_PORT ubuntu@127.0.0.1
EOF
}

require_cmd() {
  if ! command -v "$1" >/dev/null 2>&1; then
    echo "Missing required command: $1" >&2
    exit 1
  fi
}

print_plan
render_meta_data
render_user_data

if [[ "$PRINT_ONLY" == true ]]; then
  echo '--- rendered meta-data ---'
  cat "$META_DATA"
  echo '--- rendered user-data ---'
  sed -n '1,220p' "$USER_DATA"
  exit 0
fi

require_cmd curl
require_cmd qemu-img
require_cmd cloud-localds
require_cmd qemu-system-x86_64

if [[ ! -f "$BASE_IMAGE" ]]; then
  curl -L "$BASE_IMAGE_URL" -o "$BASE_IMAGE"
fi

qemu-img create -f qcow2 -F qcow2 -b "$BASE_IMAGE" "$DISK_IMAGE" "$DISK_SIZE" >/dev/null
cloud-localds "$SEED_IMAGE" "$USER_DATA" "$META_DATA"

qemu-system-x86_64 \
  -name "$VM_NAME" \
  -enable-kvm \
  -m "$MEMORY_MB" \
  -smp "$CPUS" \
  -cpu host \
  -nographic \
  -serial file:"$SERIAL_LOG" \
  -pidfile "$PID_FILE" \
  -drive if=virtio,format=qcow2,file="$DISK_IMAGE" \
  -drive if=virtio,format=raw,file="$SEED_IMAGE" \
  -netdev user,id=net0,hostfwd=tcp::${SSH_PORT}-:22 \
  -device virtio-net-pci,netdev=net0 \
  >/dev/null 2>&1 &

echo "VM started in background."
echo "PID: $(cat "$PID_FILE")"
echo "SSH: ssh -p $SSH_PORT ubuntu@127.0.0.1"
echo "Serial log: $SERIAL_LOG"
