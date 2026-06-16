# Detection — Matrix artifacts + REIQ raw corpus

Status: started
Date: 2026-06-16T15:17:51
Owner/reviewer: Thor/default

## User decisions

1. Proceed with Matrix `mapping_sessions` / `transformation_artifacts` first.
2. REIQ has hundreds of raw payloads and they should be used.
3. Keep LeadFinder field candidates as `candidate` until extractor evidence exists.

## Scope

Implement the next safe database-centric gate after LeadFinder dictionary v0:

```text
LeadFinder dictionary version
  -> Matrix mapping session / transformation artifact
  -> future SourceHub translated DTO publication
```

Also inventory REIQ raws without dumping values/PII and prepare scripts/contracts for raw JSONB lab ingestion.

## Safety

No provider calls, no production mutation, no raw payload commits, no raw values/PII printed in docs. Raw files remain local/private; repo stores scripts/contracts/reports only.
