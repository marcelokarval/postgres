# PG18 Release-Readiness — Final Report

Status: LOCAL_RELEASE_READINESS_WARN

Release candidate posture: READY_FOR_LOCAL_RELEASE_CANDIDATE for Docker build/smoke path; WARN remains because host-Nix clean runner validation is pending on a Nix-enabled runner.

## Requested vs delivered

| Requested | Delivered | Status |
|---|---|---|
| Proceed through next steps 1..6 | Release-readiness, local tests, README/docs realignment, parity contracts, PostgREST/web PRD all delivered | PASS |
| Persist executive PRD | `docs/pg18-release-readiness-prd.md` | PASS |
| Persist tasks from PRD | `docs/pg18-release-readiness-tasks.md` | PASS |
| Execute tasks | Local gates, Docker build path, smoke tests, docs updates, browser proof, reviews | PASS |
| Review by task | `docs/pg18-release-readiness-task-reviews.md` | PASS |
| Review final side-by-side | This file | PASS |
| Correct actively without HITL | Script evidence/report/docs corrections applied after reviewer findings and failed validation-image smoke invocation | PASS |
| Browser-proof + vision | `docs/pg18-release-readiness-browser-proof-evidence.md` | PASS |
| Persist final report in same stack | This file | PASS |

## User decisions applied

1. `supautils` and `plan_filter`: parity only for this slice.
2. Focus: local tests, release readiness, Docker image build path, and documentation realignment.
3. First gateway when implementation begins: PostgREST only. Django remains a separate future round.
4. First client surface: simple web page/client, optionally styled with reui.io in the next implementation slice.

## Artifacts delivered

- `README.md` — rewritten for the PG18 fork reality.
- `docs/pg18-release-readiness-prd.md` — executive PRD.
- `docs/pg18-release-readiness-tasks.md` — task plan and acceptance criteria.
- `docs/pg18-release-readiness-task-reviews.md` — task-by-task review.
- `docs/pg18-release-readiness-final-report.md` — final report.
- `docs/pg18-release-readiness-local-tests-evidence.md` — local validation evidence.
- `docs/pg18-release-readiness-browser-proof.html` — static browser report.
- `docs/pg18-release-readiness-browser-proof-evidence.md` — browser/vision proof evidence.
- `docs/pg18-parity-contracts.md` — parity-only contract for SQL, preload, library-only, and excluded surfaces.
- `docs/pg18-database-centric-postgrest-web-prd.md` — next-slice PRD for PostgREST + simple web client.

## Local validation evidence

### Syntax

- `bash -n scripts/pg18-runtime-status.sh`: PASS.
- `bash -n scripts/smoke-pg18-full-parity.sh`: PASS.
- `bash -n scripts/promote-pg18-stack.sh`: PASS.
- `bash -n scripts/validate-pg18.sh`: PASS.

### Live runtime/status

- `scripts/pg18-runtime-status.sh`: PASS.
- Live stack remains the accepted baseline `postgres18_postgres` with PostgreSQL 18.0 and expected preload.

### Baseline smoke

- `scripts/smoke-pg18-full-parity.sh --image local/supabase-postgres:18-karval-full`: PASS.

### Promotion validation without restart

- `scripts/promote-pg18-stack.sh`: PASS in validate-only default mode; no retag/restart.
- `scripts/promote-pg18-stack.sh --skip-update`: PASS as backward-compatible validate-only alias.

### Host-Nix validation limitation

Command attempted:

```bash
scripts/validate-pg18.sh --skip-docker-test --image-tag local/supabase-postgres:18-karval-validation
```

Result: WARN/BLOCKED on this host because `nix` is not available in PATH.

Interpretation: this does not invalidate the Docker release path. The README now documents that host-Nix validation requires a Nix runner.

### Docker image build path

Command:

```bash
scripts/validate-pg18.sh --skip-nix-builds --skip-docker-test --image-tag local/supabase-postgres:18-karval-validation
```

Result: PASS.

Produced image:

```text
sha256:ddd0cc5e4ecef17d4661c62ccf25ca5c3e78107550109d2141e458e4209a1c32
```

### Smoke of freshly built validation image

Command:

```bash
actual_id=$(docker image inspect local/supabase-postgres:18-karval-validation --format '{{.Id}}')
scripts/smoke-pg18-full-parity.sh \
  --image local/supabase-postgres:18-karval-validation \
  --expected-image-id "$actual_id"
```

Result: PASS with marker:

```text
PG18_FULL_PARITY_SMOKE_OK
```

## Browser-proof evidence

- URL served locally during QA: `http://127.0.0.1:18081/docs/pg18-release-readiness-browser-proof.html`
- HTTP fetch: 200, 2327 bytes.
- Browser console: no errors or warnings.
- Vision verdict: PASS. The page showed the PG18 Release-Readiness slice, local release-readiness badge, accepted image hash, PostgreSQL 18.0/preload, parity decisions, PostgREST/web decisions, PASS table, and next steps without visual breakage.
- Server was monitored and then stopped after proof.

## Review/correction evidence

Independent read-only reviews found real gaps and those were corrected:

- README/docs were too legacy/upstream-aligned: README rewritten around PG18 fork reality.
- `validate-pg18.sh` did not validate missing values for `--log-dir`/`--image-tag`: fixed.
- `validate-pg18.sh` did not write FAIL entries to summary when a step failed: fixed.
- Evidence for local gates was not persisted: fixed in `docs/pg18-release-readiness-local-tests-evidence.md`.
- Browser proof evidence was not persisted initially: fixed.
- Validation-image smoke initially failed due to expected image SHA mismatch; rerun with actual image ID using existing `--expected-image-id` contract: PASS.
- `promote-pg18-stack.sh` was changed to safe-by-default validate-only mode; `--apply` is now required for retag/service update.

## Final verdict

The local PG18 fork is ready to generate and smoke-test a local Docker release-candidate image from this fork path.

Taxonomy: `LOCAL_RELEASE_READINESS_WARN`, not full `LOCAL_RELEASE_READINESS_PASS`, because host-Nix validation is not proven on this workstation. That gate must run on a Nix-enabled runner before a public/formal release tag.

## Commit evidence

- Local commit created for this slice. Resolve exact SHA with `git log -1 --oneline`.
- Working tree verified clean after commit verification.

## Next steps

1. Run full `scripts/validate-pg18.sh` on a Nix-enabled runner without skips.
2. Push `local/supabase-postgres:18-karval-validation` or a rebuilt release tag to the chosen registry and record immutable digest.
3. Create a release checklist mapping tags, image digest, extension matrix, and smoke artifacts.
4. Start the PostgREST database-centric slice from `docs/pg18-database-centric-postgrest-web-prd.md`.
5. In that slice, implement a tiny `api` schema/RPC sample, PostgREST container config, and simple web client page.
6. Decide whether `wrappers all_fdws` is the desired release posture long-term; the Docker path proved it builds, but it is the heaviest part of the image build.
