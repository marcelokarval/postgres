# Prop4You Project DDL Package

Prop4You-specific database-centric DDL belongs here.

This package is a consumer of the PG18 base image/stack. It must not be baked into the PG18 image.

Canonical platform boundaries:

- Lead Finder defines the canonical graph.
- Matrix governs semantic meaning and mapping artifacts.
- SourceHub owns ingress, lineage and canonical DTO publication.
- Skip Trace enriches; it does not define owner/property truth.
- Situations are structured facts, not tags.

Potential future scope examples:

```text
org/<org_id>
property/<property_id>
lead/<lead_id>
owner/<owner_id>
room/<room_id>
```

File sequence example:

```text
0001_schemas.sql
0002_identity_and_membership.sql
0003_canonical_graph.sql
0004_realtime_scopes.sql
0005_rls_policies.sql
0006_rpc_contracts.sql
```

No project SQL files have been installed here yet. The next correct step is to inventory inherited Prop4You scripts and convert them into ordered, reviewable `.sql` files.
