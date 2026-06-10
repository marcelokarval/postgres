# PostgreSQL 18 bootstrap status

This fork has started the PostgreSQL 18 port as a bootstrap track.

Current state

- `nix/config.nix` now declares PostgreSQL `18.0` using the hash from the pinned `nixpkgs` revision in `flake.lock`.
- `nix/packages/postgres.nix` now exposes:
  - `psql_18`
  - `psql_18_slim`
- `nix/overlays/default.nix` now exports `postgresql_18`.

Important constraint discovered during bootstrap

Before the first PG18 extension pass, `nix/ext/versions.json` declared support for:

- 28 extensions on PostgreSQL 17
- 0 extensions on PostgreSQL 18

That meant a naive port would fail quickly because several extension derivations assume at least one compatible version exists for the active PostgreSQL major.

Current PG18 extension baseline in this fork

A first evidence-based PG18 slice has now been added to `nix/ext/versions.json`:

- `pg_cron` -> `1.6.7` on PG18 only
- `pg_net` -> `0.20.3` on PG15/17/18
- `pgmq` -> `1.11.1` on PG18 only
- `postgis` -> `3.6.3` on PG18 only
- `vector` -> `0.8.2` on PG15/17/18
- `pg_jsonschema` -> `0.3.4` on PG18 only (`pgrx` `0.16.1`, Rust `1.88.0`)
- `pgaudit` -> `18.0` on PG18 only

Bootstrap strategy currently applied

- PostgreSQL 18 was introduced first as a bootstrap/core target.
- A first minimal PG18 extension baseline is now declared in `nix/ext/versions.json`.
- The remaining PG18 extension surface stays intentionally narrow until derivations/tests/checks are ported and verified.

Why this is necessary

Even after this expanded slice, some important derivations and test surfaces are still version-aware and not fully PG18-verified:

- multiple extension VM tests still define upgrade paths only from 15 -> 17
- `docker-image-test.nix` now recognizes `Dockerfile-18`, but runtime behavior is still unverified on this host
- `Dockerfile-18` now exists as a minimal derivative of `Dockerfile-17`, but has not yet been validated by build/test

So the fork now has a credible PG18 path, but not yet a verified end-to-end PG18 image build.

Next required steps

1. Run the checked-in acceptance path on a host with working Nix:
   - `scripts/validate-pg18.sh`
2. If Docker runtime regression fails, collect artifacts with:
   - `scripts/triage-pg18-failure.sh --validation-log-dir tmp/pg18-validation`
3. Promote only reviewed-safe divergence outputs with:
   - `scripts/promote-pg18-safe-outs.sh --bundle /tmp/pg18-triage-out/<stamp>`
   - or `--as-z18` when PG18-specific siblings are justified
4. Expand PG18 image/test coverage incrementally from the current minimal path, especially where extension VM tests still hardcode 15/17/orioledb-17 upgrade flows.

Host/tooling note

This workspace host does not currently have `nix` installed in PATH, so bootstrap work here is being done by source analysis and file edits, not by local `nix build` verification yet.
