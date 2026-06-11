#!/usr/bin/env bash
set -euo pipefail

# Safe helper for enabling/checking KVM before PG18 NixOS VM-backed validation.
# Default mode is read-only preflight. Use --apply to run sudo modprobe commands.

MODE="preflight"
if [[ "${1:-}" == "--apply" ]]; then
  if [[ $# -ne 1 ]]; then
    echo "ERROR: --apply does not accept extra arguments" >&2
    echo "Run: $0 --help" >&2
    exit 64
  fi
  MODE="apply"
elif [[ "${1:-}" == "--help" || "${1:-}" == "-h" ]]; then
  cat <<'USAGE'
Usage:
  scripts/enable-kvm-preflight.sh          # read-only preflight
  scripts/enable-kvm-preflight.sh --apply  # prompt for sudo and try to load kvm/kvm_intel or kvm_amd

After /dev/kvm exists, rerun:
  PG18_REQUIRE_KVM=true scripts/run-pg18-persistent-nix-validate.sh
USAGE
  exit 0
elif [[ -n "${1:-}" ]]; then
  echo "ERROR: unknown argument: $1" >&2
  echo "Run: $0 --help" >&2
  exit 64
fi

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

log() { printf '[kvm-preflight] %s\n' "$*"; }
section() { printf '\n== %s ==\n' "$*"; }

section "context"
log "repo=$ROOT_DIR"
log "mode=$MODE"
log "user=$(id -un)"
log "groups=$(id -nG)"
log "kernel=$(uname -r)"
if command -v systemd-detect-virt >/dev/null 2>&1; then
  if virt="$(systemd-detect-virt 2>/dev/null)"; then
    log "virtualization=$virt"
  else
    log "virtualization=none"
  fi
fi

section "cpu virtualization"
if grep -Eq '\bvmx\b' /proc/cpuinfo; then
  log "cpu_flag=vmx (Intel VT-x visible)"
  KVM_VENDOR="intel"
elif grep -Eq '\bsvm\b' /proc/cpuinfo; then
  log "cpu_flag=svm (AMD-V visible)"
  KVM_VENDOR="amd"
else
  log "cpu_flag=missing (no vmx/svm visible)"
  KVM_VENDOR="unknown"
fi
lscpu | grep -E 'Model name|Virtualization|Hypervisor' || true

section "current kvm state"
if [[ -e /dev/kvm ]]; then
  ls -l /dev/kvm
else
  log "/dev/kvm=absent"
fi
lsmod | grep -E '^kvm|^kvm_intel|^kvm_amd' || log "kvm_modules=not_loaded"

section "module availability"
modinfo kvm >/dev/null 2>&1 && log "module kvm=available" || log "module kvm=missing"
case "$KVM_VENDOR" in
  intel) modinfo kvm_intel >/dev/null 2>&1 && log "module kvm_intel=available" || log "module kvm_intel=missing" ;;
  amd) modinfo kvm_amd >/dev/null 2>&1 && log "module kvm_amd=available" || log "module kvm_amd=missing" ;;
  *) log "vendor-specific module=unknown because no vmx/svm flag visible" ;;
esac

if [[ "$MODE" == "apply" ]]; then
  section "apply sudo modprobe"
  log "This may ask for your sudo password. It loads kernel modules only; it does not mutate repo files."
  sudo modprobe kvm
  case "$KVM_VENDOR" in
    intel) sudo modprobe kvm_intel ;;
    amd) sudo modprobe kvm_amd ;;
    *) log "No vendor module loaded because CPU vendor flag is unknown" ;;
  esac
fi

section "post-check"
if [[ -e /dev/kvm ]]; then
  ls -l /dev/kvm
  lsmod | grep -E '^kvm|^kvm_intel|^kvm_amd' || true
  log "KVM_READY=yes"
  cat <<'NEXT'

Next command:
  PG18_REQUIRE_KVM=true scripts/run-pg18-persistent-nix-validate.sh

Monitor:
  tail -f tmp/pg18-publish/nix-full-validate-persistent.log
  tail -f tmp/pg18-publish/full-validate-persistent-nix/summary.txt
NEXT
  exit 0
fi

log "KVM_READY=no"
cat <<'NEXT'

If this was read-only mode, run:
  scripts/enable-kvm-preflight.sh --apply

After /dev/kvm exists, rerun:
  PG18_REQUIRE_KVM=true scripts/run-pg18-persistent-nix-validate.sh

Monitor:
  tail -f tmp/pg18-publish/nix-full-validate-persistent.log
  tail -f tmp/pg18-publish/full-validate-persistent-nix/summary.txt

If --apply failed, collect diagnostics:
  sudo modprobe -v kvm
  sudo modprobe -v kvm_intel   # Intel hosts
  sudo modprobe -v kvm_amd     # AMD hosts
  sudo dmesg | grep -iE 'kvm|vmx|svm|virtualization' | tail -80

If firmware/BIOS disables VT-x/AMD-V, enable virtualization there or move the gate to a KVM-capable runner.
NEXT
exit 86
