# PG18 RC1 + PostgREST/Web — Final Report

Status: LOCAL_RC_READY_WITH_WARNINGS

## Requested vs delivered

| Requested next step | Delivered | Status |
|---|---|---|
| 1. Full validate on Nix runner | Host-Nix absent; Nix container probe ran; Docker CLI acquisition via nixpkgs timed out. Blocker persisted. | WARN |
| 2. Define registry/tag final | Local RC tag created: `local/supabase-postgres:18-karval-rc1` | PASS |
| 3. Rebuild/push image and record digest | RC tag points to freshly built validation image `sha256:ddd0...`; push not performed without explicit registry scope. | WARN |
| 4. Create release checklist | `docs/pg18-rc-release-checklist.md` | PASS |
| 5. Start PostgREST database-centric slice | Implemented disposable PG18 + PostgREST proof | PASS |
| 6. Implement tiny API + web client | `api.hello()` via PostgREST + web page proof | PASS |
| 7. Decide wrappers posture | Keep `wrappers all_fdws` for RC1 with build-cost warning | PASS |

## RC image

- Local tag: `local/supabase-postgres:18-karval-rc1`
- Registry candidate tag, local only: `registry.arthuragrelli.com/supabase-postgres:18-karval-rc1`
- Image ID: `sha256:ddd0cc5e4ecef17d4661c62ccf25ca5c3e78107550109d2141e458e4209a1c32`
- RC smoke: PASS with `PG18_FULL_PARITY_SMOKE_OK`

## Nix runner verdict

`FULL_VALIDATE_ON_NIX_RUNNER`: WARN/BLOCKED locally.

Reason:

- Host has no `nix` on PATH.
- `nixos/nix:latest` container proved Nix exists.
- Attempt to acquire `docker-client` via `nix shell nixpkgs#docker-client` failed due GitHub/nixpkgs timeout.
- No host Nix install was performed.

## Registry verdict

No external push was executed. A local registry candidate tag was created only. External push requires explicit confirmation of:

- target repository/name;
- credentials/session readiness;
- whether `registry.arthuragrelli.com/supabase-postgres:18-karval-rc1` is the desired canonical tag.

## PostgREST/web proof

- PG18 container image: `local/supabase-postgres:18-karval-rc1`
- PostgREST endpoint: `http://127.0.0.1:13000/rpc/hello`
- Web proof URL during QA: `http://127.0.0.1:18082/docs/pg18-postgrest-web-proof.html`
- API payload returned: `message=hello from pg18 postgrest`, `gateway=postgrest`, `client=web`, `postgres_version=18.0`.
- Browser DOM: `200 OK`, expected payload rendered.
- Reproducible script now validates same-origin `/api/hello` via Python proxy.
- Vision: PASS; page had no visual breakage.
- Cleanup verified: no `pg18-postgrest-proof-*` containers/network remained.

## Browser/CORS correction

Direct browser fetch to PostgREST failed due missing CORS header on POST response. The proof was corrected with a local same-origin Python proxy endpoint `/api/hello`, which proxies to PostgREST. This keeps PostgREST as the gateway while avoiding CORS as a blocker for local browser proof. The corrected script reproduces this path and pins the PostgREST image by digest.

## Review evidence

- Docs/release review: PASS.
- Scripts/proof first review: REQUEST_CHANGES.
- Corrections applied: pinned PostgREST digest, same-origin `/api/hello`, proxy integration, tmp creation, URI composed with `DB_USERINFO`, cleanup evidence.
- Focused re-review: PASS.

## Artifacts

- `docs/pg18-rc-postgrest-prd.md`
- `docs/pg18-rc-postgrest-tasks.md`
- `docs/pg18-rc-postgrest-task-reviews.md`
- `docs/pg18-rc-postgrest-final-report.md`
- `docs/pg18-rc-release-checklist.md`
- `docs/pg18-rc-nix-runner-evidence.md`
- `docs/pg18-rc-registry-strategy.md`
- `docs/pg18-postgrest-web-proof-evidence.md`
- `docs/pg18-postgrest-web-proof.html`
- `docs/pg18-wrappers-release-posture.md`
- `scripts/proof-pg18-postgrest-web.sh`
- `scripts/serve-pg18-postgrest-web-proof.py`

## Final verdict

The fork has a local PG18 RC1 image and a working database-centric PostgREST/web proof.

It is not yet a formal public release because the Nix-enabled full validate gate and external registry push/digest are still gated.

## Commit evidence

- Local commit created for this slice; exact SHA via `git log -1 --oneline`.

## Next steps

1. Authorize/install/use a real Nix-enabled runner with Docker socket and rerun full `scripts/validate-pg18.sh` without skips.
2. Confirm registry target and authorize `docker push registry.arthuragrelli.com/supabase-postgres:18-karval-rc1` or provide another canonical target.
3. After push, record immutable registry digest via `docker buildx imagetools inspect`.
4. Convert the PostgREST proof into a durable compose/dev stack if we want to keep iterating on database-centric API contracts.
5. Add a first real database-centric contract beyond `hello`: authenticated JWT claims + RLS-safe RPC returning JSONB.
