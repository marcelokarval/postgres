# PG18 RC1 + PostgREST/Web — Task Reviews

| Task | Requested | Delivered | Evidence | Verdict |
|---|---|---|---|---|
| RC-01 PRD/tasks | Persistir plano e tasks | `docs/pg18-rc-postgrest-prd.md`, `docs/pg18-rc-postgrest-tasks.md` | Files exist | PASS |
| RC-02 Preflight | Auditar ambiente | git clean, no host nix, Docker/Swarm active, images inspected | final report | PASS |
| RC-03 Nix runner | Rodar full validate em Nix runner | Host-Nix absent; Nix container available; docker-client via nixpkgs blocked by GitHub timeout | `docs/pg18-rc-nix-runner-evidence.md` | WARN |
| RC-04 RC tag | Definir tag/digest | `local/supabase-postgres:18-karval-rc1` tagged to `sha256:ddd0...` | `docs/pg18-rc-release-checklist.md` | PASS |
| RC-05 Registry | Preparar registry/push | Local candidate tag `registry.arthuragrelli.com/supabase-postgres:18-karval-rc1`; no push | `docs/pg18-rc-registry-strategy.md` | WARN |
| RC-06 Checklist | Release checklist | Checklist with image, gates, smoke, browser, runner WARN | `docs/pg18-rc-release-checklist.md` | PASS |
| RC-07 PostgREST | Implement tiny api schema/RPC | Disposable PG18 + PostgREST; `/rpc/hello` PASS | `docs/pg18-postgrest-web-proof-evidence.md` | PASS |
| RC-08 Web | Simple web client | Browser rendered page and consumed same-origin proxy to PostgREST | `docs/pg18-postgrest-web-proof-evidence.md` | PASS |
| RC-09 wrappers | Decide posture | Keep for RC1 with build-cost warning | `docs/pg18-wrappers-release-posture.md` | PASS |
| RC-10 Closeout | Review, commit, final report | Pending commit at time of this file generation | final report/chat | PENDING_UNTIL_COMMIT |

## Corrections made during execution

- Browser direct fetch initially failed due CORS: corrected by local same-origin Python proxy while preserving PostgREST as gateway target.
- `scripts/proof-pg18-postgrest-web.sh` was made executable and validated with `bash -n`.
- Proof containers and web server were cleaned up after evidence capture.

## Final script correction round

Reviewer found the proof script was not yet reproducing the same-origin browser proof. Corrections applied:

- `scripts/proof-pg18-postgrest-web.sh` now generates HTML using `/api/hello`.
- The script pins PostgREST to `postgrest/postgrest@sha256:488093de819567422bc1d37cb79da6e84bca3726bac321daeed618f0ed957888`.
- The script verifies the Python same-origin proxy endpoint and writes final web proof artifacts.
- `tmp/pg18-rc` is created by the script before evidence writes.
- Cleanup was re-run and proof containers/network were verified absent.

## Final re-review verdict: PASS

Focused re-review confirmed no remaining blockers: URI uses `DB_USERINFO`, no literal placeholder remains, script is syntax-valid, PostgREST is pinned by digest, HTML uses `/api/hello`, `tmp/pg18-rc` is created, and evidence records final execution/cleanup.
