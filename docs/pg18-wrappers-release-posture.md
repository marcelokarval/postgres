# PG18 `wrappers all_fdws` Release Posture

Status: KEEP_FOR_RC1_WITH_BUILD_COST_WARNING

## Evidence

- The Docker build path successfully built the PG18 image with `wrappers=0.6.1` and `all_fdws` enabled.
- The RC1 smoke created the `wrappers` SQL extension successfully.
- The build logs showed `wrappers` as the heaviest part of the Dockerfile-Nix build, especially Rust/C++/DuckDB/AWS/Arrow/Wasmtime compilation/linking.

## Decision for RC1

Keep `wrappers all_fdws` for RC1 parity because the current objective is Supabase/Postgres-style extension breadth.

## Risk

The release build is slower and more resource-intensive. If future CI/runner cost or time becomes unacceptable, split this into a separate decision:

1. keep all FDWs in the default PG18 image;
2. build a lean core PG18 image plus optional wrappers-full variant;
3. reduce wrappers feature set to the FDWs actually needed by the database-centric product.
