# PG18 RC1 Publish + Durable PostgREST/RLS Final Report

Status: RELEASE_CANDIDATE_PUBLISHED_WITH_NIX_GATE_BLOCKED_BY_RUNNER_ARCHITECTURE

## Delivered

1. RC1 image published to ArthurAgrelli registry.
2. Immutable digest registered.
3. Durable PostgREST/web development stack created.
4. Database-centric JWT claims + RLS-safe RPC contract implemented.
5. HTTP/API smoke and browser proof validated.
6. Default cleanup path validated.
7. Nix validation script corrected to use actual check outputs.
8. Nix runner evidence persisted, including real successful builds of both PG18 package surfaces.

## Registry

Image:
`registry.arthuragrelli.com/supabase-postgres:18-karval-rc1`

Digest:
`sha256:edf25ff4c3f74c315874145b3fb5eff1b3b98560cf9d8c21e815831bf370326e`

## Nix gate

Final status: BLOCKED for one continuous no-skip pass due runner architecture, not due PG18 compile failure.

Evidence:
- `01-psql_18_bin`: PASS in real Nix runner.
- `02-psql_18_slim_bin`: PASS in real Nix runner.
- Failure point: obsolete `scripts/validate-pg18.sh` output names.
- Fix applied: extension builds now point to `checks.x86_64-linux.ext-*`.
- Remaining requirement: rerun in runner with persistent `/nix` volume.

Detailed evidence:
- `docs/pg18-rc1-nix-full-validate-evidence.md`

## Durable stack

Files:
- `docker/pg18-postgrest-rls/compose.pg18-postgrest-rls.yml`
- `docker/pg18-postgrest-rls/init/001-api-rls.sql`
- `docker/pg18-postgrest-rls/scripts/make_jwt.py`
- `docker/pg18-postgrest-rls/web/serve.py`
- `scripts/smoke-pg18-postgrest-rls-stack.sh`

Proof expectation:
- `status`: `200 OK`
- `user`: `user_karval_demo`
- `plan`: `rc1`
- `role`: `authenticated`
- `postgres`: `18.0`

## Release posture

RC1 is published and usable by digest for controlled development/QA.

Do not mark the image as final production release until a persistent Nix runner completes `scripts/validate-pg18.sh` without skips after the script fix.
