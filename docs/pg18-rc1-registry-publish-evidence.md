# PG18 RC1 Registry Publish Evidence

Status: PASS

Registry tag:
`registry.arthuragrelli.com/supabase-postgres:18-karval-rc1`

Registry digest:
`sha256:edf25ff4c3f74c315874145b3fb5eff1b3b98560cf9d8c21e815831bf370326e`

Local source tag:
`local/supabase-postgres:18-karval-rc1`

Image ID previously validated:
`sha256:ddd0cc5e4ecef17d4661c62ccf25ca5c3e78107550109d2141e458e4209a1c32`

Command used:
```bash
docker push registry.arthuragrelli.com/supabase-postgres:18-karval-rc1
docker buildx imagetools inspect registry.arthuragrelli.com/supabase-postgres:18-karval-rc1
```

Verification:
```text
Name:      registry.arthuragrelli.com/supabase-postgres:18-karval-rc1
Digest:    sha256:edf25ff4c3f74c315874145b3fb5eff1b3b98560cf9d8c21e815831bf370326e
```

Notes:
- Credentials were not printed.
- The published digest is the immutable release reference for RC1 consumption.
