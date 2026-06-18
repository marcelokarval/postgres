# Subagent Manifest

Runtime tool cap observed: max 3 concurrent subagents per batch. User allowed 6, but actual cap is 3.

Toolsets: file + terminal only. No browser/web/MCP/provider calls. No raw payload dumps. No PII values.

| Worker | Lane | Artifact | Status file |
| --- | --- | --- | --- |
| A | DirectSkip real/sample response corpus | 08-directskip-corpus-inventory.md | .tmp/prop4you-json-curation/subagents/A-status.md |
| B | Realtor/docs/backups/source inventory | 09-realtor-corpus-inventory.md | .tmp/prop4you-json-curation/subagents/B-status.md |
| C | Legacy tags/labels inventory | 10-legacy-tags-labels-inventory.md | .tmp/prop4you-json-curation/subagents/C-status.md |
