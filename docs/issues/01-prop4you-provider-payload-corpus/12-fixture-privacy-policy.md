# Fixture and privacy policy — Prop4You provider payload corpus

Status: reviewed/synthesized
Updated: 2026-06-15T01:13:10
Owner: Thor/default

## Decision

Because Prop4You DDL is a separate system from the PG18 base image, fixture strategy should be explicit and layered.

## Allowed in repo

Commit only privacy-safe artifacts:

```text
1. path inventories
2. schema/path summaries
3. hash/count/type summaries
4. Matrix dictionary examples without raw payload values
5. scripts and DDL that can consume a private corpus later
```

Current clarification from Karval: do not commit fake/redacted fixtures. The real corpus belongs outside git in the private corpus path.

## Not allowed in repo by default

```text
1. raw provider payloads containing names, addresses, phones, emails, case numbers or provider IDs
2. API keys, tokens, headers, cookies, auth envelopes
3. full DirectSkip responses with real contact data
4. full REIQ/Realtor payloads containing real property/owner data unless explicitly sanitized
5. raw screenshots/HTML dumps with PII
```

## Local/private corpus layout proposal

Private corpus can live outside git, for example:

```text
~/.hermes/private/prop4you-provider-corpus/
  reiq/
  directskip/
  realtor/
  internal/
```

Repo stores only summaries under:

```text
docs/issues/01-prop4you-provider-payload-corpus/
```

Future lab scripts should accept a local private corpus path:

```bash
PROP4YOU_PROVIDER_CORPUS_DIR=~/.hermes/private/prop4you-provider-corpus   scripts/proof-prop4you-ddl-lab.sh --dry-run
```

## Redaction rules

Before any sample fixture is committed:

- Replace names with stable fake names.
- Replace street addresses with fake-but-valid format.
- Replace phones/emails with test domains/numbers.
- Replace provider IDs with deterministic fake IDs preserving shape only.
- Remove API keys and request headers.
- Keep JSON path structure, types, array cardinality and null/missing behavior.

## RLS/retention guidance

Raw provider payload tables require:

- RLS by tenant/workspace/user/project boundary where applicable.
- Separation of raw payload from public API views.
- Retention class per provider and payload type.
- Audit of access to PII-bearing payloads.
- Redacted projection views for operator/reporting workflows.

## Decision for current slice

No raw fixtures are committed in this slice. Only inventories, side-by-side comparison, DDL skeleton and proof script skeleton are committed.
