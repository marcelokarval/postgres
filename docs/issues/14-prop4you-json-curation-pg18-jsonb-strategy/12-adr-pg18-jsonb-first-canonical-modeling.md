# 12 — ADR: PG18 JSONB-first canonical modeling policy

Status: accepted-for-next-slice

## Context

Legacy Django modeling used many tables because Django ORM and app-service boundaries made that practical. In PG18 database-centric architecture, provider evidence arrives as heterogeneous JSON from REIQ, DirectSkip, Realtor and future county/provider sources. PostgreSQL 18 improves JSON/JSONB ergonomics enough that LFG should not blindly translate every Django table or provider key into relational DDL.

## Decision

Adopt a hybrid model:

```text
JSONB-first for evidence, provider-native payloads, canonical envelopes, and review artifacts.
Relational-first for durable identity, graph edges, constraints, auth boundaries, PostGIS geometry, temporal snapshots, and high-value indexed projections.
```

## Do not

- turn every provider key into a table column;
- make Realtor/DirectSkip provider shapes canonical truth;
- use workspace tags to fill system taxonomy gaps;
- expose raw JSONB via public API;
- index large JSONB blindly;
- store PII-bearing raw payloads in docs/proofs.

## Model layers

```text
bronze/raw JSONB
  exact provider/internal payload, hash, source, privacy class

silver/normalized JSONB
  SourceHub/Matrix interpreted DTOs and curation artifacts

gold/canonical JSONSchema envelope
  LeadFinder-owned stable canonical shape, still JSON-capable

relational projections
  extracted anchors/edges/fields used for constraints/search/joins/PostGIS/API
```

## Promotion gates

A JSON path can become relational only when all are true:

1. observed in representative corpora;
2. semantic meaning is approved by Matrix/LeadFinder;
3. stable enough across source families or intentionally provider-specific;
4. needed for query, join, filtering, sorting, uniqueness, FK, RLS, PostGIS, or operational constraint;
5. safe cast/coercion exists;
6. lineage to raw JSON remains durable;
7. privacy/PII exposure is classified.

## Provider-specific stance

### DirectSkip

Contact enrichment provider. It provides evidence for phones, emails, addresses, relatives and reachability. It does not define owner/property truth alone.

### Realtor

Property/geography/market enrichment provider. It provides evidence for details, media, valuation, comparables, market and boundaries. It does not create canonical property truth alone.

### REIQ/county-like sources

Often source-of-record or filing-oriented. Still enters as raw JSONB through SourceHub and is promoted through Matrix/LeadFinder contracts, not by table name alone.

## PG18 mechanics

Use:

```text
jsonb for raw/envelope/residue
JSONSchema validation where available via extension/app function policy
generated columns or expression indexes for stable paths
GIN JSONB selectively for ad hoc/review tables only
PostGIS for geometry extracted from JSONB
append-only temporal tables for sanctioned snapshots
```

## Consequence

The next LFG slice should define canonical JSONSchema envelopes before final table expansion. Tables will still exist, but as projections/anchors/edges over governed JSON evidence, not as blind replicas of Django models.
