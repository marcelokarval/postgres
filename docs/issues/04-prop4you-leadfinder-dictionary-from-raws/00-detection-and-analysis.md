# Detection — LeadFinder dictionary born from raws

Status: started
Date: 2026-06-16T12:17:30
Owner: Thor/default

## Correction captured

Karval corrected the prior conclusion: the canonical center is owned by LeadFinder Group, but the LeadFinder Group itself is born/evolved from raw analysis. This means the flow is not purely top-down. It is governed feedback:

```text
raw/provider/internal evidence -> candidate LeadFinder families/fields -> approved LeadFinder dictionary version -> Matrix mapping DTO -> SourceHub translation -> LeadFinder materialization -> dictionary evolution
```

## Active decisions

1. Seed families and fields as appropriate, not only families.
2. Treat existing `matrix.canonical_*` now as mirror/candidate/review, not canonical ownership.
3. Continue with proposed families and actively remodel with what raws/local evidence provide.

## Safety

No provider calls, no production mutation, no raw/PII dumps, no fake/redacted fixture commits.
