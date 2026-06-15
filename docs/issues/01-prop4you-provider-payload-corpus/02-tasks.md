# Tasks — Prop4You provider payload corpus

| ID | Task | Owner | Status | Target artifacts | Validation | Review |
| --- | --- | --- | --- | --- | --- | --- |
| T1 | Create PRD/tasks/ledger/manifest scaffold | Thor | delivered | 00-04 files | files exist | Thor |
| T2 | Analyze REIQ/base data payload evidence | Subagent A + Thor | delivered | 08-reiq-payload-inventory.md | paths/contracts/sources summarized, no PII dump | Thor |
| T3 | Analyze DirectSkip/owner payload evidence | Subagent B + Thor | delivered | 09-directskip-payload-inventory.md | owner/contact fields summarized, no PII dump | Thor |
| T4 | Analyze Realtor.com/property enrichment evidence + internal payloads | Subagent C + Thor | delivered | 10-realtor-internal-payload-inventory.md | enrichment fields summarized, no PII dump | Thor |
| T5 | Synthesize side-by-side provider comparison and canonical dictionary gate | Thor | delivered | 11-side-by-side-provider-comparison.md | REIQ/DirectSkip/Realtor compared by domain families | Thor |
| T6 | Define fixture/privacy policy for separate DDL system | Thor | delivered | 12-fixture-privacy-policy.md | answers repo vs local/private fixtures | Thor |
| T7 | Create/adjust package + subpackage skeleton and lab script skeleton | Thor | delivered | database/ddl/projects/prop4you/*, scripts/proof-prop4you-ddl-lab.sh | non-final skeleton only; shell syntax check | Thor |
| T8 | Review all tasks requested vs delivered, correct gaps | Thor | delivered | 05-task-review.md | side-by-side PASS/WARN/BLOCKED | Thor |
| T9 | Browser-proof + vision QA | Thor | delivered | 06-browser-proof.md, 08-browser-render.html | local server, console, vision | Thor |
| T10 | Final report, task closure, commit/push | Thor | delivered | 07-final-report.md | final report mirrors chat | Thor |

## Side-effect policy

Subagents may write only inside this issue stack and `.tmp/prop4you-payload-corpus/subagents/`. Thor may update canonical docs, create non-final DDL/package skeleton files, and create a proof script skeleton. No production, provider, Docker, secret, runtime or live DB mutation.
