# Subagent manifest — raw extractors for LeadFinder modeling

Concurrency cap: 3 subagents max.
Toolsets: file + terminal only.
No MCP/web/browser/provider calls.
Subagents must write status files under `.tmp/prop4you-raw-extractors/subagents/`.
Thor performs final review and proof.

## Lanes

- A: LeadFinder filters/code pressure evidence.
- B: SQL raw path extractor DDL.
- C: Python REIQ path scanner.
