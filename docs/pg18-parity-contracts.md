# PG18 Parity Contracts — safeupdate, supautils, plan_filter

## Decision

For this fork's current PostgreSQL 18 local release-readiness lane:

- `safeupdate` is active and behavior-proven.
- `supautils` is parity-only: library/config surface present, not active enforcement.
- `plan_filter` is parity-only: library/config surface present, not active enforcement.

This follows Karval's decision: parity now, enforcement later only if explicitly scoped.

## Runtime contract table

| Surface | Current PG18 contract | Evidence gate | Status |
|---|---|---|---|
| `safeupdate` | preload-only hook | `shared_preload_libraries` includes `safeupdate`; unsafe `UPDATE` without `WHERE` fails | ACTIVE/PASS |
| `supautils` | library/config parity surface | `supautils.so` exists in runtime image | PARITY/PASS/WARN semantic enforcement deferred |
| `plan_filter` | library/config parity surface | `plan_filter-0.1.so` exists in runtime image | PARITY/PASS/WARN semantic enforcement deferred |

## Why not active enforcement now?

`supautils` and `plan_filter` are powerful policy/enforcement surfaces. Activating them changes session behavior, role rules, allowed GUCs and/or query-plan rejection semantics. That belongs in a dedicated hardening slice with explicit acceptance tests.

Current PG18 preload remains:

`pg_stat_statements, pgaudit, pg_cron, pg_net, pg_tle, safeupdate`

## Future activation gates

Before claiming active enforcement:

### supautils

- prove expected GUCs exist after load/preload;
- prove reserved roles/memberships behavior;
- prove allowed configs include the intended `pgrst.*`, `safeupdate.*` or `plan_filter.*` scopes;
- prove no breakage to PostgREST/authenticator sessions.

### plan_filter

- preload or load the module intentionally;
- set `plan_filter.statement_cost_limit`;
- prove a high-cost query is blocked;
- prove a normal query still passes;
- decide whether PostgREST authenticator sessions inherit the filter.

Until those gates are implemented, docs and final reports must not describe `supautils` or `plan_filter` as active enforcement.
