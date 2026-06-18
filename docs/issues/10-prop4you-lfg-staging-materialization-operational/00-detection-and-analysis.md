# Detection and analysis — LFG staging/materialization/operational loop

Status: active
Updated: 2026-06-17T21:53:41

User asked to continue in loop until discussed tasks are complete. The remaining discussed sequence after SourceHub T4 is:

```text
T5.0 LFG staging candidates
T5.1 materialization runs/review gate
T5.2 minimal operational/facet tables
```

Guardrails:

- Gateway/runtime agnostic.
- Consume SourceHub translated DTO publications.
- Start from the 10 proven DTO publications.
- No provider calls.
- No raw/DTO scalar dumps in docs/proofs.
- Avoid premature dozens-of-tables explosion: create minimal, reviewable operational surface.
