# PG18 Ubuntu 24.04 cloud image VM

This path creates a disposable local Ubuntu 24.04 VM via QEMU + cloud-init for PG18 acceptance work.

It is useful when:
- the current workstation should not be mutated with a permanent Nix install
- you want a clean Linux acceptance surface
- you want the VM to auto-clone the repo and run the checked-in bootstrap path

## Important scope note

Local Docker Swarm on the host can be useful for image-building workflows and future self-hosted runner experiments, but it does not replace the need for a clean Nix-capable acceptance surface.

This VM path is for that acceptance surface.

## Files

- `cloud-init/pg18-runner-user-data.tpl.yaml`
- `scripts/create-pg18-cloudimg-vm.sh`
- `scripts/bootstrap-pg18-runner.sh`

## Requirements on the host

- `qemu-system-x86_64`
- `qemu-img`
- `cloud-localds`
- `curl`
- KVM support preferred

Typical Ubuntu packages:

```bash
sudo apt-get update
sudo apt-get install -y qemu-system-x86 qemu-utils cloud-image-utils
```

## Dry preview

```bash
scripts/create-pg18-cloudimg-vm.sh --print-only
```

This renders:
- `meta-data`
- `user-data`
- inferred repo URL/ref
- the exact SSH port and VM sizing

## Create and boot the VM

```bash
scripts/create-pg18-cloudimg-vm.sh
```

Default behavior:
- downloads Ubuntu 24.04 minimal cloud image if needed
- creates a qcow2 overlay disk
- renders a cloud-init seed image
- boots a local VM in the background
- forwards host port `2222` to guest SSH
- cloud-init clones the repo inside the guest
- cloud-init runs `scripts/bootstrap-pg18-runner.sh`

## Useful options

Use a specific repo/ref:

```bash
scripts/create-pg18-cloudimg-vm.sh \
  --repo-url https://github.com/your/fork.git \
  --repo-ref karval/pg18-bootstrap
```

Skip auto-bootstrap and leave the VM ready for manual control:

```bash
scripts/create-pg18-cloudimg-vm.sh --no-auto-bootstrap
```

Pass validation flags through to the bootstrap/validator:

```bash
scripts/create-pg18-cloudimg-vm.sh --validation-args '--skip-docker-test'
```

## Access the guest

```bash
ssh -p 2222 ubuntu@127.0.0.1
```

Serial log:
- `tmp/pg18-cloudimg-vm/<name>-serial.log`

Inside the guest, the repo is cloned to:
- `/opt/pg18-repo`

## What happens inside the guest

Cloud-init writes and runs:
- `/usr/local/bin/pg18-cloud-init-bootstrap.sh`

That script:
1. clones/fetches the repo
2. checks out the requested ref
3. runs `scripts/bootstrap-pg18-runner.sh`
4. which then runs `scripts/validate-pg18.sh`

## Failure flow

If acceptance fails in the guest, use the same path already checked into the repo:

```bash
cd /opt/pg18-repo
scripts/triage-pg18-failure.sh --validation-log-dir tmp/pg18-validation
```

Then:

```bash
scripts/promote-pg18-safe-outs.sh --bundle /tmp/pg18-triage-out/<stamp> --dry-run
```

## Honest limitation

This script creates the VM and wires the acceptance path, but it does not itself prove PG18 is green until the guest finishes the real validation successfully.
