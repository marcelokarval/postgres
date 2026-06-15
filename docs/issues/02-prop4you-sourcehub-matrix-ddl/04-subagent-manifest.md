# Subagent Manifest

| Worker | Scope | Allowed writes | Forbidden |
| --- | --- | --- | --- |
| A | Provider registry + JSONB helper DDL | provider DDL/docs/status | provider calls, secrets, runtime, fixtures |
| B | SourceHub raw/corpus/enrichment request DDL | sourcehub DDL/docs/status | provider calls, secrets, runtime, fixtures |
| C | Matrix dictionary/path mapping DDL | matrix DDL/docs/status | provider calls, secrets, runtime, fixtures |
