# Subagent manifest

Concurrency cap: 3.
Toolsets: file, terminal only.
No MCP/web/provider calls.
Workers are advisory; Thor validates and implements final DDL.

| Worker | Scope |
| --- | --- |
| A | LFG staging candidates from SourceHub DTOs |
| B | Materialization run/result review gate |
| C | Minimal operational/facet tables without table explosion |
