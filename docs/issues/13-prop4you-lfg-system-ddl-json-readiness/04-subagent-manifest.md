# Subagent Manifest

Concurrency cap: 3.

Toolsets: file + terminal only. No browser/web/MCP/provider calls. No raw payload dumps. No PII values.

| Worker | Lane | Artifact | Status file |
| --- | --- | --- | --- |
| A | Legacy Django system inventory | 08-legacy-system-inventory.md | .tmp/prop4you-lfg-readiness/subagents/A-status.md |
| B | Current PG18 DDL inventory | 09-current-ddl-inventory.md | .tmp/prop4you-lfg-readiness/subagents/B-status.md |
| C | JSON corpus/path inventory | 10-json-path-inventory.md | .tmp/prop4you-lfg-readiness/subagents/C-status.md |
