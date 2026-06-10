# PG18 Release Candidate + PostgREST/Web Proof — Task Ledger

| ID | Task | Acceptance | Status |
|---|---|---|---|
| RC-01 | Persistir PRD/tasks | PRD e ledger existem | DONE |
| RC-02 | Auditar ambiente | Git/Nix/Docker/registry/images/ports registrados | DONE |
| RC-03 | Runner Nix gate | Full validate executado ou blocker técnico persistido | DONE_WARN |
| RC-04 | Release tag/digest | Tag RC local criada, image ID/digest registrado e smoke PASS | DONE |
| RC-05 | Registry readiness | Estratégia/checklist persistidos; push externo só se escopo existir | DONE_WARN |
| RC-06 | Release checklist | Checklist com tags/digest/matrix/preload/smoke/browser/runner | DONE |
| RC-07 | PostgREST proof | PG18 disposable + PostgREST + `api.hello` HTTP PASS | DONE |
| RC-08 | Web proof | Página web simples consome API no browser | DONE |
| RC-09 | wrappers decision | Risco/peso de `wrappers all_fdws` documentado | DONE |
| RC-10 | Reviews/closeout | Review por task/final, commit, relatório chat | DONE |

## WARNs intencionais

- Host-Nix full validate não foi concluído localmente: host sem `nix`; tentativa de Docker CLI dentro de runner Nix bloqueada por timeout GitHub/nixpkgs.
- Registry push externo não executado por falta de escopo explícito/credencial/tag policy para PG18.
