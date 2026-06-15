# Prop4You DDL package

Status: skeleton / non-final

This package is the future home for Prop4You database-centric DDL.

Important boundary:

```text
This package is separate from the PG18 base image and base DDL substrate.
It must not freeze final product tables until provider/internal JSON payload comparison is reviewed.
```

Current decision:

```text
package + subpackages
```

Initial subpackages:

```text
sourcehub/   raw ingress, corpus and lineage skeleton
matrix/      semantic dictionary and provider mapping skeleton
leadfinder/  canonical graph materialization boundary skeleton
providers/   shared provider corpus contracts
reiq/        REIQ-specific corpus notes and future DDL
skiptrace/   DirectSkip/owner enrichment future DDL
realtor/     Realtor.com enrichment future DDL
internal/    manual/product-originated payload future DDL
identity/    future identity package, not first frozen slice
geography/   future geography package, not first frozen slice
property/    future property graph package, gated by corpus/dictionary
owner/       future owner graph package, gated by DirectSkip/REIQ comparison
```

Do not treat this skeleton as final schema. It exists to give future DDL work a governed landing zone.
