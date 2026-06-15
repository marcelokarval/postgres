# Side-by-side provider comparison — REIQ x DirectSkip x Realtor.com

Status: reviewed/synthesized
Updated: 2026-06-15T01:13:10
Owner: Thor/default

## Executive verdict

The first Prop4You DDL implementation decision remains intentionally gated: final canonical tables should not be frozen until the provider corpus comparison below is converted into Matrix dictionary entries and reviewed against representative payload samples.

However, the available local evidence is enough to define the first non-final package/subpackage skeleton and the corpus decision model.

## Provider role ranking from Karval

```text
REIQ       -> current/base data source
DirectSkip -> owner/contact data source
Realtor.com -> broad property enrichment source
Internal/manual/product-originated -> supporting local/product capture source
```

## Side-by-side by canonical family

| Canonical family | REIQ | DirectSkip | Realtor.com | Internal/product-originated | DDL implication |
| --- | --- | --- | --- | --- | --- |
| Property identity/address | Strong base source: `property.location`, address source facts, list/state context | Request context only; should not define property identity | Strong enrichment/verification via `location.address.*`, provider property id/permalink | Manual property creation and user-captured address | Canonical `property/location` comes from approved graph; preserve provider-specific raw/source facts separately |
| Owner identity | Has owner/ownership/projection candidates by list type | Strong owner/contact evidence via names/contacts/relatives | Generally weak/not primary owner source in inspected evidence | Manual owner/name inputs possible | Owner truth requires candidate graph + Matrix/LeadFinder approval; DirectSkip evidence must not auto-promote |
| Ownership/party roles | Strong for REIQ legal/list-type datasets: party roles, owner projection, legal parties | Evidence-only; relationships/relatives can support but not define ownership | Not primary | Manual corrections possible | Need `owner_candidate`, `ownership_evidence`, and approval/materialization flow |
| Contacts: phone/email/address | Some REIQ lanes expose locked/restricted/contact hints and role addresses | Strong phone/email/confirmed_address/relatives evidence | Not primary | Manual skip trace submissions and user-entered contacts | Contacts should be evidence records with confidence/source, then promoted to owner contact satellites |
| Situations/distress/legal | Strong base via list types: pre_foreclosure, loan_modification, probates, eviction, tax_sale, divorce, heirship, appointment trustee | Not a situation source; can enrich owner resolution | Listing/history can enrich but not define distress situation | User/product signals possible | Situation facts must be structured, not tags; list_type does not auto-create situation without canonical block |
| Valuation/financial | Strong in REIQ for equity/valuation/loan terms/tax sale etc. | Not primary | Strong enrichment: estimates, valuation, listing price, history, spot offer | Manual valuations/overlays possible | Use fact/snapshot model with source lineage and timestamp; do not overwrite canonical blindly |
| Listing/history/media | Limited depending lane | None | Strong: history, listing status, photos/media, similar/nearby homes | Product overlays | Realtor belongs mostly to enrichment/read model/source facts, not base truth |
| Lineage/provenance | SourceHub raw record + mapping versions visible | raw_response/request/response snapshots and SourceHub handoffs | Matrix DTO + SourceHub DTO evidence | product_originated seeds | All providers require raw -> normalized -> canonical lineage tables |
| Generated/projected JSONB paths | Candidate paths depend on REIQ list type and envelope shape | Useful for contact counts/status/result code, but PII requires caution | Strong for property metrics and estimates; array paths need JSON_TABLE/staging | Useful for internal source classification | Only add generated/projected fields after Matrix dictionary approval and stable query need |

## DDL decision gate

Final DDL tables require these gates:

1. Provider corpus sample set exists for REIQ, DirectSkip, Realtor and internal payloads.
2. Raw paths are summarized without leaking PII.
3. Matrix dictionary declares canonical family/field/alias/confusable-with rules.
4. SourceHub lineage and DTO publication boundary is explicit.
5. LeadFinder materialization rule is explicit.
6. PII/RLS/retention policy is accepted.
7. Lab proof validates skeleton/package plus any generated JSONB projections.

## Recommended first implementation route

Because Karval clarified that table decisions happen after JSON comparison, the first DDL implementation should be:

```text
prop4you_sourcehub_corpus + prop4you_matrix_dictionary_skeleton
```

not full identity/property/owner tables yet.

Reason:

```text
REIQ/DirectSkip/Realtor comparison must govern canonical dictionary first;
then property/owner/materialized graph tables can be frozen with less rework.
```

## What should not happen

- Do not copy Django models into final DDL one-to-one.
- Do not treat REIQ list type as canonical situation automatically.
- Do not treat DirectSkip returned contact as canonical owner contact automatically.
- Do not treat Realtor estimate/listing/media as current truth automatically.
- Do not commit raw PII fixture values to repo.
