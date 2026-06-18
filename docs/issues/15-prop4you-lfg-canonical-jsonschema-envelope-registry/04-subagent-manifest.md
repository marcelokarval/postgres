# Subagent Manifest

Runtime cap observed: max 3 concurrent workers per delegate_task batch.

Toolsets: file + terminal only. No MCP/web/provider calls. No raw payload values. No PII.

| Worker | Lane | Artifact | Status file |
| --- | --- | --- | --- |
| A | property/owner/taxonomy envelopes | 08-core-envelope-review.md | .tmp/prop4you-jsonschema-registry/subagents/A-status.md |
| B | DirectSkip/Realtor evidence envelopes | 09-provider-evidence-envelope-review.md | .tmp/prop4you-jsonschema-registry/subagents/B-status.md |
| C | DDL registry/proof | 10-ddl-registry-proof-review.md | .tmp/prop4you-jsonschema-registry/subagents/C-status.md |
