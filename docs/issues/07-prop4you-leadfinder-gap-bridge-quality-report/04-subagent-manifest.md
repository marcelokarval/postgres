# Subagent manifest — LeadFinder gap bridge + Matrix quality report

Concurrency cap: 3 subagents max.
Toolsets: file + terminal only.
No MCP/web/provider calls.
Subagents must write status files under `.tmp/prop4you-gap-bridge-quality/subagents/`.
Thor performs final review and proof.

## Lanes

- A: LeadFinder raw evidence gap bridge DDL.
- B: Matrix quality_report separate artifact helper/contract.
- C: Temporal phase/modeling review.
