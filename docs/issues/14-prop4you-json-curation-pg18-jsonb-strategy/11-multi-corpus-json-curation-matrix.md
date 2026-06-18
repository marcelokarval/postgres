# 11 — Multi-corpus JSON curation matrix

Status: consolidated

## Verdict

```text
Do not implement table-heavy LFG graph yet.
Adopt JSONB-first, JSONSchema-governed canonical envelopes.
Promote relational tables/columns only for stable anchors, indexed/query-critical fields, constraints, graph edges, geography geometry, and sanctioned facts.
```

## Corpus coverage

| Corpus/source | Evidence inspected | Key result | Modeling decision |
| --- | --- | --- | --- |
| REIQ loan modification | 97 JSONs from Matrix registry and raw payload path inventory | flat provider payload with property, owner, filing, physical, financial fields | raw JSONB + SourceHub/Matrix DTO; promote property/owner/valuation only after canonical schema approval |
| DirectSkip contact discovery | 213 JSONs parsed; 3 external raw/sample responses; 210 registry artifacts | nested contact satellite payload: contacts, names, phones, emails, confirmed addresses, relatives, relative phones | JSONB-first; narrow satellite projections for normalized phone/email/address/relative only when operationally needed |
| Realtor | docs, code, DTOs, tests, snapshots/backups | broad heterogeneous shapes: autocomplete, details, valuation, history, comparables, market, boundaries | hybrid: JSONB evidence/residue + tables for anchors/provider refs/PostGIS/sanctioned snapshots |
| Legacy tags/labels | real_estate models/services/tests + LF contracts/genome | system taxonomy and workspace tags are separate; legacy has default colors/status/list names and guardrail tests | do not seed tag groups yet; inventory first; preserve system-vs-workspace boundary |

## DirectSkip implications

```text
Top envelope: input, status, contacts, result_code
External raw total: 3 contacts, 17 contact phones, 6 emails, 3 confirmed addresses, 12 relatives, 32 relative phones
```

Decision:

```text
DirectSkip is contact enrichment evidence.
It must not define canonical owner/property truth by itself.
```

Promote later only:

```text
normalized phone/email/address for dedupe/search
contact/relative edge evidence if product needs it
status/result code/counts for operational audit
```

Keep as JSONB:

```text
raw envelope
provider-specific nested arrays
relatives until relationship product contract exists
unknown/new provider paths
```

## Realtor implications

Realtor surfaces:

```text
autocomplete/property details/property estimates/property history/spot offer/nearby homes/map/recently sold/similar homes/market details/area boundary/geography
```

Decision:

```text
Realtor enriches an already canonical property/area.
Realtor does not create canonical property truth by itself.
```

Promote later:

```text
provider references
canonical anchor refs
PostGIS boundary geometry
selected property details
valuation snapshots
system area market snapshots
comparable candidate evidence if product contract exists
```

Keep as JSONB:

```text
full gallery/features/advertiser blocks
AVM series and forecast arrays
history/tax/permit arrays until productized
comparables arrays until materialization contract exists
market hotness/ratios/provider-specific residue
raw boundary ancillary presentation data
```

## Legacy tags/labels implications

System taxonomy candidates:

```text
PropertySituation.situation_type/status
LeadFinderMaterializedTaxonomyBlock
system_property_tag_slugs derived from active situations
systemic_taxonomy fields in Lead Finder genome
```

Workspace-facing vocabularies:

```text
PropertyTagRegistry
PropertyStatusRegistry
PropertyListRegistry
PropertyTag
PropertyList
SavedProperty.tags/lists
```

Legacy/default examples observed:

```text
foreclosure, pre_foreclosure, probate, tax_lien, tax_delinquent, high_equity, absentee_owner, vacant
hot_lead, cold_lead, contacted, follow_up, qualified, not_interested
Available, Under Contract, Sold, Archived
Hot Leads, Follow Up, Archive, All Properties
```

Do not treat same string as same domain meaning.

## Canonical JSONSchema-first strategy

Each provider/source family should have:

```text
raw schema: provider-native shape, lenient unknown fields, strict enough for envelope/family sanity
normalized schema: SourceHub/Matrix interpreted DTO, provider-aware but canonical-facing
canonical schema: LeadFinder-owned stable JSONSchema for property/owner/contact/taxonomy graph envelopes
projection schema: query/index/read-model shape for API/search/materialized views
```

This allows:

```text
500-600+ future sources
3,200+ county variations
provider drift tracking
canonical growth without table explosion
selective relational promotion
```

## PG18 JSONB usage policy

Use JSONB for:

```text
raw payload/evidence
provider-specific residue
variable arrays
nested contact/media/history/comparable structures
Matrix artifacts and review payloads
canonical JSON envelopes before table promotion
```

Use relational tables/columns for:

```text
identity anchors and refs
provider/source lineage
hashes/versions/status
FK graph edges
tenant/workspace auth boundaries later
stable constraints
search/filter/sort fields
PostGIS geometry
snapshots with temporal semantics
```

Use generated/projected columns when:

```text
path is representative and stable
meaning is approved
cast is safe
field is frequently queried
lineage remains intact
```

## Recommended next slice

```text
Slice 15 — LFG canonical JSONSchema envelope minimum
```

Scope:

1. define canonical JSONSchema envelope families for property, owner, contact_satellites, valuation, taxonomy;
2. include DirectSkip contact satellite schema family;
3. include Realtor enrichment evidence schema families;
4. define promotion rules from JSONB evidence to relational projections;
5. add marker auto-apply threshold policy as configuration/ADR or DDL only after schema policy is fixed;
6. do not build workspace tables.
