# PG18 RC1 Review Closeout

Status: PASS_WITH_NIX_GATE_BLOCKER_DOCUMENTED

## Review findings addressed

- Compose image pinning tightened:
  - PG18 RC1 uses registry digest.
  - PostgREST uses digest.
  - Python web image uses digest.
- Durable stack cleanup verified with default smoke run.
- RLS RPC avoids privileged `current_setting('shared_preload_libraries')` access from authenticated role.
- PostgREST readiness waits on actual RPC, not bare `/` 403.
- Init SQL permissions corrected to be container-readable.
- `scripts/validate-pg18.sh` no longer calls nonexistent `.#psql_18/exts/*` outputs; it uses real `checks.x86_64-linux.ext-*` outputs.

## Remaining gate

A single continuous no-skip Nix validation pass requires persistent runner storage for `/nix`.
The current disposable runner successfully proved the heavy package builds but cannot efficiently rerun the complete script after patch without recompiling from scratch.

## Decision

Commit is acceptable as RC evidence + tooling fix, with explicit final-release blocker documented.
