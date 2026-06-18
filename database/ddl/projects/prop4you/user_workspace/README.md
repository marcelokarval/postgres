# prop4you/user_workspace

Status: boundary-only / non-final

Canonical schema:

```text
prop4you_user_workspace
```

This package is the logged-in user workspace boundary for future P4Y selections, snapshots, local tags/labels/markers, notes, lists, campaigns, refresh decisions, usage and tenant-visible workflow state.

Current slice intentionally does not implement full workspace tables. `prop4you_leadfinder_group` feedback tables reference workspace/user/account/snapshot using weak text refs so LFG can aggregate user feedback without coupling to the final user/workspace schema or a specific Postgres instance.

Ownership rule:

```text
prop4you_user_workspace = user/tenant-local decisions and snapshots
prop4you_leadfinder_group = LFG/system global evidence, votes aggregation, review/apply of global markers
```

Future work:

- workspace snapshots table
- local annotation/tag/marker tables
- usage/billing/export references
- RLS/API facade
- FDW point-lookup/snapshot contract if/when LFG runs in a dedicated DB
