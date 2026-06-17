# Detection and analysis — LeadFinder gap bridge + Matrix quality report

Status: active
Created: 2026-06-17T17:44:50
Owner: Thor/default

## User decisions

1. Implement `leadfinder/0002_raw_evidence_gap_bridge.sql`: yes.
2. Bridge should support both existing `canonical_field_id` matches and proposed family/field keys for new gaps: yes.
3. Matrix `quality_report` should remain a separate artifact, not embedded into LeadFinder bridge: yes.

## Temporal framing

Current phase is modeling/evidence, not operational materialization.

```text
T0 Raw evidence observed/captured
T1 Raw path extraction / modeling evidence
T2 LeadFinder gap/proposal bridge
T3 Matrix quality_report as separate review artifact
T4 SourceHub DTO publication later
T5 LeadFinder materialization later
```

## Key guardrail

LeadFinder filters are a strong guide for LFG needs, but we are only looking at them as demand-side modeling pressure. We are not yet implementing runtime LeadFinder Group materialization.
