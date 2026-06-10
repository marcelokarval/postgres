# PG18 RC1 Registry Strategy

## Local result

```text
local_rc=local/supabase-postgres:18-karval-rc1
registry_candidate=registry.arthuragrelli.com/supabase-postgres:18-karval-rc1
image_id=sha256:ddd0cc5e4ecef17d4661c62ccf25ca5c3e78107550109d2141e458e4209a1c32
push_status=NOT_PUSHED_NO_EXPLICIT_SCOPE
```

## Policy

No external registry push was performed because this session has no explicit PG18 registry publication scope, repository name policy, or credential confirmation.

Existing local Docker images reference `registry.arthuragrelli.com`, so a plausible target was tagged locally as:

```text
registry.arthuragrelli.com/supabase-postgres:18-karval-rc1
```

This is only a local tag until an explicit `docker push` is authorized.

## Push command when authorized

```bash
docker push registry.arthuragrelli.com/supabase-postgres:18-karval-rc1
```

After push, record immutable digest:

```bash
docker buildx imagetools inspect registry.arthuragrelli.com/supabase-postgres:18-karval-rc1
```
