# Shared Base DDL Package

Shared base DDL belongs here.

This package may include common database-centric primitives that are useful across projects, for example:

- migration/install tracking;
- shared audit/event helpers;
- generic app identity helpers;
- generic realtime scope helpers;
- utility functions;
- common schemas that are not project-specific.

Base DDL must not depend on Prop4You or any other project package.

File sequence example:

```text
0001_install_tracking.sql
0002_app_identity.sql
0003_realtime_base.sql
```

No SQL files have been installed here yet. This README establishes the convention before importing inherited scripts.
