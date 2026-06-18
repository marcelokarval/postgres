# 11 — Matriz consolidada: legacy system x PG18 DDL x JSON corpus

Status: consolidated

## Verdict

```text
LFG atual: ready-with-gaps
Workspace completo: not-ready
Workspace mínimo weak-ref/snapshot: only after next LFG gap slice
```

O LFG ainda não deve ser tratado como fechado para iniciar `prop4you_user_workspace` rico. O pipeline database-centric está correto e provado, mas o modelo final de property/owner/contact/taxonomy/search/workspace não está completo frente ao legado `system` e aos JSONs disponíveis.

## Executive matrix

| Legacy/system area | JSON evidence | Current DDL coverage | Gap class | Decision |
| --- | --- | --- | --- | --- |
| SourceHub raw ingress | raw payload file + manifests + hashes | `sourcehub.raw_records`, `corpus_samples`, lineage | covered | keep raw restricted; no raw in public/API |
| Matrix semantic artifacts | baseline-only/contextual/discrepancy/contracts/source_manifest | `matrix.*`, path extraction, quality, field mapping set | covered for discovery | improve explicit genome/approval parity later |
| LeadFinder dictionary | canonical_dictionary_snapshot families/fields/aliases | `leadfinder.canonical_*`, gaps, promotions review/apply | covered as experimental | continue promotion policy; not final graph |
| SourceHub translated DTO | contracts/source_manifest/source paths | `translated_dto_publications` | covered | DTO remains handoff, not graph truth |
| LFG staging/materialization | no final property graph in JSON; DTO path evidence | `staging_candidates`, `materialization_runs/results` | covered for gate | keep reviewable |
| Operational LFG group | JSON has property/owner/financial/contact fields | `operational_groups/events/facets` only | weak-ref/facet-only | not final graph |
| Property/address | property address/city/state/zip/APN-like/file refs | no final property/address DDL; only facets | missing-final-table | next LFG canonical graph slice |
| Property details | bed/bath/sqft/garage/pool/year/legal/subdivision | dictionary candidates/facets only | missing-final-table | next LFG canonical graph slice |
| Owner identity | mortgagor/owner first/last names, ownership | no owner entity final DDL | missing-final-table | next LFG canonical graph slice |
| Ownership | ownership, owner/property relation hints | no ownership final table | missing-final-table | next LFG canonical graph slice |
| Mailing/contact address | owner_address/city/state/zip | feedback item_kind supports mailing_address; no contact graph | missing-final-table | next LFG canonical graph slice |
| Phone/email contact satellites | legacy has rich phone/email, JSON focus sample lacks phone/email payload | feedback markers support item kinds; no phone/email tables | missing-final-table | defer until DirectSkip/contact corpus, but model contract needed |
| DNC/wrong/bounce/sendability | legacy has DNC/wrong/bounce/sendability | feedback votes/global markers | partially covered | need auto-apply thresholds and marker policy DDL extension |
| System taxonomy/list/situation | lead_type, list_type, source list, situations | semantic dictionary + facets; no normalized taxonomy tables | semantic-candidate-only | next taxonomy slice or graph slice |
| Tags/labels vocabulary | legacy fields include system tag slugs/label slugs; user wants reusable vocabulary | no tag vocabulary/group tables | missing | next after graph baseline or combined taxonomy slice |
| Workspace tags/lists/status | legacy has property list/saved property/tag registries | `prop4you_user_workspace` schema only | not-ready | do not implement rich workspace yet |
| Public LF API projections | legacy has markers/detail/summaries/location search | no api facade/RLS | missing-api | later after graph baseline |
| SkipTrace/provider-specific | legacy has skiptrace requests/results/system cache | provider registry only; skiptrace README skeleton | missing-provider-package | later provider-specific slice |
| Retention/partition/ops | high ingest variable load discussed | no retention/partition policies | missing-ops | before production/deploy |

## Readiness gate

### What is ready

```text
T0 raw -> T1 Matrix extraction -> T2 gap bridge -> T3 quality -> T4 DTO -> T5 staging/materialization/operational minimum
feedback votes -> aggregate -> review -> global marker apply
LeadFinder promotion prepare -> review -> apply
```

### What is not ready

```text
final property/address table graph
final owner/ownership/party graph
final contact satellite graph
final system taxonomy/tag/label vocabulary and groups
workspace local tag/list/snapshot model
public API/RLS facade
retention/partition/load policy
provider-specific skiptrace/realtor/reiq packages
```

## Answer to the user question

> O LFG já está pronto e fechado para irmos para o prop4you_user_workspace?

```text
Não para workspace completo.
Sim apenas para workspace futuro extremamente mínimo baseado em refs/hashes, mas isso ainda seria prematuro antes de completar o próximo LFG graph/taxonomy gap slice.
```

The correct next implementation slice is not workspace. It is LFG canonical graph/taxonomy gap closure from this matrix.

## Correct next slice

```text
Slice 14 — LFG canonical graph/taxonomy minimum from system x DDL x JSON gaps
```

Recommended scope:

1. property/address/details minimum;
2. owner/ownership minimum;
3. mailing/contact address minimum;
4. phone/email satellite contract skeleton or deferred with explicit DirectSkip dependency;
5. system taxonomy/tag/label vocabulary and reusable tag groups;
6. auto-apply threshold policy for low-risk global markers;
7. no workspace product tables yet.

## Updated answers incorporated

### Snapshot question

Deferred. It means whether user snapshots should store only LFG refs/hashes or also a compact redacted copy. This depends on graph readiness and should not be decided before the next LFG gap slice.

### Tags/labels

User decision:

```text
LFG vocabulary should be reusable by users.
User-created tags should belong to groups/contexts in the future, similar to REISift/start-tag style.
```

Implication:

```text
Need a system vocabulary/group layer before workspace tags are implemented.
```

### Auto-apply global markers

User decision:

```text
After a configured number of users/workspaces report the same low-risk situation, apply automatically.
```

Implication:

```text
Need policy table/config for thresholds and marker risk class. Current aggregate computes auto_apply_candidate but still applies via explicit review function. Next slice should add policy-governed auto-apply where safe.
```
