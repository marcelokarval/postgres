# 12 — Recursive JSON inventory summary

Source root: `/home/marcelo-karval/Backup/Projetos/prop4you/prop4you-inertia`

## Counts

```json
{
  "candidate_manifest_path": "docs/corpus/prop4you/lfg/prop4you-inertia-lfg-corpus-candidates.v1.jsonl",
  "classification_counts": {
    "dependency_or_tooling": 853,
    "lfg_corpus_candidate": 3545,
    "parse_error": 64,
    "project_support": 2730,
    "unknown_or_out_of_scope": 5968
  },
  "context_tag_counts": {
    "config_or_tooling": 3520,
    "directskip": 235,
    "leadfinder": 38,
    "legacy_system": 325,
    "matrix": 3320,
    "realtor": 28,
    "registry": 3241,
    "reiq": 3094,
    "sourcehub": 58,
    "structured_json": 13096,
    "system_app": 325,
    "test_or_fixture": 893
  },
  "generated_at": "2026-06-18T18:39:58",
  "lfg_candidate_count": 3545,
  "manifest_path": "docs/corpus/prop4you/lfg/prop4you-inertia-json-manifest.v1.jsonl",
  "no_raw_values_policy": true,
  "parse_error_count": 64,
  "parse_error_paths_sample": [
    ".agent/mcp_config.json",
    ".auto-claude/specs/001-use-o-10x-para-melhorar-toda-a-l-gica-e-entendimen/research.json",
    ".tmp/realtor_enrichment_seed_result.json",
    "_projeto-antigo/botrei_lists_pgsql/.vscode/launch.json",
    "_projeto-antigo/frontend-react/schema_introspection.json",
    "_projeto-antigo/frontend-react/tsconfig.app.json",
    "_projeto-antigo/frontend-react/tsconfig.node.json",
    "_projeto-antigo/mamix-nextjs/Documentation/assets/libs/intl-tel-input/.vscode/settings.json",
    "_projeto-antigo/mamix-nextjs/Starterkit/.eslintrc.json",
    "frontends/.tmp/my-property-rich-testbase-enrichment/materialization-result.json",
    "frontends/docusaurus/tsconfig.json",
    "frontends/front-react/node_modules/@mapbox/jsonlint-lines-primitives/test/fails/10.json",
    "frontends/front-react/node_modules/@mapbox/jsonlint-lines-primitives/test/fails/11.json",
    "frontends/front-react/node_modules/@mapbox/jsonlint-lines-primitives/test/fails/12.json",
    "frontends/front-react/node_modules/@mapbox/jsonlint-lines-primitives/test/fails/13.json",
    "frontends/front-react/node_modules/@mapbox/jsonlint-lines-primitives/test/fails/14.json",
    "frontends/front-react/node_modules/@mapbox/jsonlint-lines-primitives/test/fails/15.json",
    "frontends/front-react/node_modules/@mapbox/jsonlint-lines-primitives/test/fails/16.json",
    "frontends/front-react/node_modules/@mapbox/jsonlint-lines-primitives/test/fails/17.json",
    "frontends/front-react/node_modules/@mapbox/jsonlint-lines-primitives/test/fails/19.json",
    "frontends/front-react/node_modules/@mapbox/jsonlint-lines-primitives/test/fails/2.json",
    "frontends/front-react/node_modules/@mapbox/jsonlint-lines-primitives/test/fails/20.json",
    "frontends/front-react/node_modules/@mapbox/jsonlint-lines-primitives/test/fails/21.json",
    "frontends/front-react/node_modules/@mapbox/jsonlint-lines-primitives/test/fails/22.json",
    "frontends/front-react/node_modules/@mapbox/jsonlint-lines-primitives/test/fails/23.json",
    "frontends/front-react/node_modules/@mapbox/jsonlint-lines-primitives/test/fails/24.json",
    "frontends/front-react/node_modules/@mapbox/jsonlint-lines-primitives/test/fails/25.json",
    "frontends/front-react/node_modules/@mapbox/jsonlint-lines-primitives/test/fails/26.json",
    "frontends/front-react/node_modules/@mapbox/jsonlint-lines-primitives/test/fails/27.json",
    "frontends/front-react/node_modules/@mapbox/jsonlint-lines-primitives/test/fails/28.json",
    "frontends/front-react/node_modules/@mapbox/jsonlint-lines-primitives/test/fails/29.json",
    "frontends/front-react/node_modules/@mapbox/jsonlint-lines-primitives/test/fails/3.json",
    "frontends/front-react/node_modules/@mapbox/jsonlint-lines-primitives/test/fails/30.json",
    "frontends/front-react/node_modules/@mapbox/jsonlint-lines-primitives/test/fails/31.json",
    "frontends/front-react/node_modules/@mapbox/jsonlint-lines-primitives/test/fails/32.json",
    "frontends/front-react/node_modules/@mapbox/jsonlint-lines-primitives/test/fails/33.json",
    "frontends/front-react/node_modules/@mapbox/jsonlint-lines-primitives/test/fails/34.json",
    "frontends/front-react/node_modules/@mapbox/jsonlint-lines-primitives/test/fails/4.json",
    "frontends/front-react/node_modules/@mapbox/jsonlint-lines-primitives/test/fails/5.json",
    "frontends/front-react/node_modules/@mapbox/jsonlint-lines-primitives/test/fails/6.json",
    "frontends/front-react/node_modules/@mapbox/jsonlint-lines-primitives/test/fails/7.json",
    "frontends/front-react/node_modules/@mapbox/jsonlint-lines-primitives/test/fails/8.json",
    "frontends/front-react/node_modules/@mapbox/jsonlint-lines-primitives/test/fails/9.json",
    "frontends/front-react/node_modules/call-bind-apply-helpers/tsconfig.json",
    "frontends/front-react/node_modules/call-bound/tsconfig.json",
    "frontends/front-react/node_modules/dunder-proto/tsconfig.json",
    "frontends/front-react/node_modules/es-define-property/tsconfig.json",
    "frontends/front-react/node_modules/es-errors/tsconfig.json",
    "frontends/front-react/node_modules/es-object-atoms/tsconfig.json",
    "frontends/front-react/node_modules/es-set-tostringtag/tsconfig.json"
  ],
  "provider_tag_counts": {
    "directskip": 235,
    "leadfinder": 38,
    "legacy_system": 325,
    "matrix": 3320,
    "realtor": 28,
    "reiq": 3094,
    "sourcehub": 58
  },
  "root_type_counts": {
    "array": 127,
    "object": 12969,
    "parse_error": 64
  },
  "source_root": "/home/marcelo-karval/Backup/Projetos/prop4you/prop4you-inertia",
  "top_level_json_files": [
    ".auto-claude-security.json",
    ".claude_settings.json",
    ".mcp.json",
    "package-lock.json",
    "package.json"
  ],
  "total_json_files_recursive": 13160,
  "total_size_bytes": 980621145
}
```

## Policy

No raw JSON values were copied. Only paths, key names, hashes, root types, counts and classifications were persisted.

## Candidate samples by tag

## Tag: config_or_tooling

- `.auto-claude/specs/037-performance-fix-vite-import-conflicts-preventing-c/implementation_plan.json`
- `.tmp/matrix-ai-first-cli-prototype-2026-04-05/manifests/cases.json`
- `.tmp/matrix-ai-first-cli-prototype-2026-04-05/manifests/prepared_cases.json`
- `.tmp/playwright-results/.last-run.json`
- `.venv/lib/python3.12/site-packages/setuptools/config/distutils.schema.json`
- `.venv/lib/python3.12/site-packages/setuptools/config/setuptools.schema.json`
- `_projeto-antigo/backend/_archived/matrix/config/heuristics_config.json`
- `_projeto-antigo/backend/_archived/matrix/config/ignore_fields.json`
- `_projeto-antigo/backend/src/lib/matrix_engine/config/heuristics_config.json`
- `_projeto-antigo/backend/src/lib/matrix_engine/config/ignore_fields.json`
- `_projeto-antigo/prop4you-lead-finder/package.json`
- `_projeto-antigo/prop4you-lead-finder/tsconfig.json`
- `backend/src/apps/system/matrix/registry/contracts/source_manifest.contract.json`
- `backend/src/apps/system/matrix/registry/directskip/skip_trace_contact_discovery/data/session_mxsess_1c8TRplqMFISkLb4iVm702PV_source_manifest.json`
- `backend/src/apps/system/matrix/registry/directskip/skip_trace_contact_discovery/data/session_mxsess_3dxdUjDJzsdYUboCZkvWlaTQ_source_manifest.json`
- `backend/src/apps/system/matrix/registry/directskip/skip_trace_contact_discovery/data/session_mxsess_6AkAple7OtLYztFA6xjAjDbj_source_manifest.json`
- `backend/src/apps/system/matrix/registry/directskip/skip_trace_contact_discovery/data/session_mxsess_8AtH7ZN1skwZdjPdsw3uLCJo_source_manifest.json`
- `backend/src/apps/system/matrix/registry/directskip/skip_trace_contact_discovery/data/session_mxsess_98FPpFMNr11P2Swiy8EePjNL_source_manifest.json`
- `backend/src/apps/system/matrix/registry/directskip/skip_trace_contact_discovery/data/session_mxsess_9DUAj0znsVyBDVnsziNsQ6MT_source_manifest.json`
- `backend/src/apps/system/matrix/registry/directskip/skip_trace_contact_discovery/data/session_mxsess_DbG7uQVjBK56N9BUBI96p0co_source_manifest.json`
- `backend/src/apps/system/matrix/registry/directskip/skip_trace_contact_discovery/data/session_mxsess_Dm8ycm7VVkRFtIYHvpeecfg3_source_manifest.json`
- `backend/src/apps/system/matrix/registry/directskip/skip_trace_contact_discovery/data/session_mxsess_MEKjVZdfFmmXP2FAI0jQ5wj3_source_manifest.json`
- `backend/src/apps/system/matrix/registry/directskip/skip_trace_contact_discovery/data/session_mxsess_OgRrfv8vPLS1b9aMhzmjZ7c3_source_manifest.json`
- `backend/src/apps/system/matrix/registry/directskip/skip_trace_contact_discovery/data/session_mxsess_QFixjb2zYQOLI1c8DtKKHJ6J_source_manifest.json`
- `backend/src/apps/system/matrix/registry/directskip/skip_trace_contact_discovery/data/session_mxsess_SJ7ZKWr3S9udCfqbnJjzWcuL_source_manifest.json`
- `backend/src/apps/system/matrix/registry/directskip/skip_trace_contact_discovery/data/session_mxsess_V6RBmk61JuTlIYlOFSeMJeth_source_manifest.json`
- `backend/src/apps/system/matrix/registry/directskip/skip_trace_contact_discovery/data/session_mxsess_V8hhTzPKSsxIhRKuUzlhUiXP_source_manifest.json`
- `backend/src/apps/system/matrix/registry/directskip/skip_trace_contact_discovery/data/session_mxsess_XuhHpM4qlOKc8H9imtQGFYnw_source_manifest.json`
- `backend/src/apps/system/matrix/registry/directskip/skip_trace_contact_discovery/data/session_mxsess_YCMmMjAi6b3SQW1hFgbM5Nt4_source_manifest.json`
- `backend/src/apps/system/matrix/registry/directskip/skip_trace_contact_discovery/data/session_mxsess_Ztg90IraPguhbudcdGbijMG8_source_manifest.json`
## Tag: directskip

- `.tmp/lead-finder-group-acceptance-probe-2026-04-05/outputs/directskip-sourcehub-handoffs.json`
- `.tmp/matrix-ai-first-cli-prototype-2026-04-05/analysis/directskip_current_whitley-comparison.json`
- `.tmp/matrix-ai-first-cli-prototype-2026-04-05/inputs/directskip/directskip_current_whitley.json`
- `.tmp/matrix-ai-first-cli-prototype-2026-04-05/inputs/directskip/directskip_legacy_charlotte_basham.json`
- `.tmp/matrix-ai-first-cli-prototype-2026-04-05/logs/claude-directskip_current_whitley.wrapper.json`
- `.tmp/matrix-ai-first-cli-prototype-2026-04-05/outputs/claude/directskip_current_whitley.json`
- `.tmp/matrix-ai-first-cli-prototype-2026-04-05/outputs/codex/directskip_current_whitley.json`
- `.tmp/matrix-ai-first-cli-prototype-2026-04-05/outputs/codex/directskip_legacy_charlotte_basham.json`
- `.tmp/matrix-ai-first-cli-prototype-2026-04-05/outputs/matrix/directskip_current_whitley.json`
- `.tmp/matrix-ai-first-cli-prototype-2026-04-05/outputs/matrix/directskip_legacy_charlotte_basham.json`
- `.tmp/matrix-sourcehub-real-outputs-2026-04-03/directskip-matrix-output.json`
- `.tmp/matrix-sourcehub-real-outputs-2026-04-03/directskip-sourcehub-output.json`
- `.tmp/p4y-1032-normalization-proof-2026-04-06/outputs/directskip-sourcehub-handoffs.json`
- `.tmp/p4y-1036-structural-proof-2026-04-06/outputs/directskip-sourcehub-handoffs.json`
- `.tmp/p4y-1047-baseline-proof-2026-04-06/outputs/directskip-sourcehub-handoffs.json`
- `.tmp/p4y-1054-universal-street-line-and-duplicate-intelligence-2026-04-06/outputs/directskip-sourcehub-handoffs.json`
- `.tmp/p4y-1079-baseline-analytics-proof-2026-04-06/outputs/directskip-sourcehub-handoffs.json`
- `_projeto-antigo/backend/.reports/skip_trace_tests/2025-11-08_workflow_test/execution_report.json`
- `_projeto-antigo/backend/src/data/directskip_charlotte_basham_response.json`
- `_projeto-antigo/backend/src/data/directskip_sample_response.json`
- `_projeto-antigo/backend/src/lib/clients/directskip/audits/audit_20251120_175044.json`
- `_projeto-antigo/backend/src/lib/clients/directskip/tests/snapshots/test_01_connection_minimal.json`
- `_projeto-antigo/backend/src/lib/clients/directskip/tests/snapshots/test_02_full_search_scott_ayer.json`
- `backend/src/apps/system/matrix/registry/directskip/skip_trace_contact_discovery/analysis/baseline-only/session_mxsess_1c8TRplqMFISkLb4iVm702PV.json`
- `backend/src/apps/system/matrix/registry/directskip/skip_trace_contact_discovery/analysis/baseline-only/session_mxsess_3dxdUjDJzsdYUboCZkvWlaTQ.json`
- `backend/src/apps/system/matrix/registry/directskip/skip_trace_contact_discovery/analysis/baseline-only/session_mxsess_6AkAple7OtLYztFA6xjAjDbj.json`
- `backend/src/apps/system/matrix/registry/directskip/skip_trace_contact_discovery/analysis/baseline-only/session_mxsess_8AtH7ZN1skwZdjPdsw3uLCJo.json`
- `backend/src/apps/system/matrix/registry/directskip/skip_trace_contact_discovery/analysis/baseline-only/session_mxsess_98FPpFMNr11P2Swiy8EePjNL.json`
- `backend/src/apps/system/matrix/registry/directskip/skip_trace_contact_discovery/analysis/baseline-only/session_mxsess_9DUAj0znsVyBDVnsziNsQ6MT.json`
- `backend/src/apps/system/matrix/registry/directskip/skip_trace_contact_discovery/analysis/baseline-only/session_mxsess_DbG7uQVjBK56N9BUBI96p0co.json`
## Tag: leadfinder

- `.auto-claude/specs/006-feature-lead-finder-visual-polish-ui-components-ca/implementation_plan.json`
- `.auto-claude/specs/006-feature-lead-finder-visual-polish-ui-components-ca/requirements.json`
- `.auto-claude/specs/006-feature-lead-finder-visual-polish-ui-components-ca/task_metadata.json`
- `.auto-claude/specs/020-bug-lead-finder-6-critical-ui-ux-bugs-requiring-sp/implementation_plan.json`
- `.auto-claude/specs/020-bug-lead-finder-6-critical-ui-ux-bugs-requiring-sp/requirements.json`
- `.auto-claude/specs/020-bug-lead-finder-6-critical-ui-ux-bugs-requiring-sp/task_metadata.json`
- `.tmp/lead-finder-group-acceptance-probe-2026-04-05/analysis/acceptance-summary.json`
- `.tmp/lead-finder-group-acceptance-probe-2026-04-05/outputs/directskip-sourcehub-handoffs.json`
- `.tmp/lead-finder-group-acceptance-probe-2026-04-05/outputs/reiq-sourcehub-handoff.json`
- `.tmp/matrix-ai-first-cli-prototype-2026-04-05/baseline/lead_finder_field_catalog.json`
- `.tmp/no-glow-runtime-proof/lead-finder-square-list-radius.json`
- `.tmp/pro-48/lead-finder-dom-summary.json`
- `_projeto-antigo/backend/src/system/lead_finder/mocks/data/index.json`
- `_projeto-antigo/backend/src/system/lead_finder/mocks/data/properties/properties_batch_001.json`
- `_projeto-antigo/backend/src/system/lead_finder/mocks/data/properties/properties_batch_002.json`
- `_projeto-antigo/backend/src/system/lead_finder/mocks/data/properties/properties_batch_003.json`
- `_projeto-antigo/backend/src/system/lead_finder/mocks/data/properties/properties_batch_004.json`
- `_projeto-antigo/backend/src/system/lead_finder/mocks/data/properties/properties_batch_005.json`
- `_projeto-antigo/backend/src/system/lead_finder/mocks/data/properties/properties_batch_006.json`
- `_projeto-antigo/backend/src/system/lead_finder/mocks/data/properties/properties_batch_007.json`
- `_projeto-antigo/backend/src/system/lead_finder/mocks/data/properties/properties_batch_008.json`
- `_projeto-antigo/backend/src/system/lead_finder/mocks/data/properties/properties_batch_009.json`
- `_projeto-antigo/backend/src/system/lead_finder/mocks/data/properties/properties_batch_010.json`
- `_projeto-antigo/backend/src/system/lead_finder/mocks/data/schema_version.json`
- `_projeto-antigo/prop4you-lead-finder/components.json`
- `_projeto-antigo/prop4you-lead-finder/metadata.json`
- `_projeto-antigo/prop4you-lead-finder/package.json`
- `_projeto-antigo/prop4you-lead-finder/tsconfig.json`
- `backend/src/apps/system/lead_finder/artifacts/lead_finder_default_genome.lf_default.v1.json`
- `backend/src/apps/system/lead_finder/baselines/owner/model_inventory/owner_entity.groups.v1.json`
## Tag: legacy_system

- `backend/src/apps/system/lead_finder/artifacts/lead_finder_default_genome.lf_default.v1.json`
- `backend/src/apps/system/lead_finder/baselines/owner/model_inventory/owner_entity.groups.v1.json`
- `backend/src/apps/system/lead_finder/baselines/owner/model_inventory/owner_entity.v1.json`
- `backend/src/apps/system/lead_finder/baselines/owner/owner_contact_address.v1.json`
- `backend/src/apps/system/lead_finder/baselines/owner/owner_email.v1.json`
- `backend/src/apps/system/lead_finder/baselines/owner/owner_identity.v1.json`
- `backend/src/apps/system/lead_finder/baselines/owner/owner_phone.v1.json`
- `backend/src/apps/system/lead_finder/baselines/owner/owner_relationship_evidence.v1.json`
- `backend/src/apps/system/lead_finder/baselines/owner/owner_structural_position.v1.json`
- `backend/src/apps/system/matrix/registry/contracts/baseline_only_analysis.contract.json`
- `backend/src/apps/system/matrix/registry/contracts/compiled_schema_artifact.contract.json`
- `backend/src/apps/system/matrix/registry/contracts/context.contract.json`
- `backend/src/apps/system/matrix/registry/contracts/contextual_analysis.contract.json`
- `backend/src/apps/system/matrix/registry/contracts/dataset_discrepancy_report.contract.json`
- `backend/src/apps/system/matrix/registry/contracts/provider_semantics_pack.contract.json`
- `backend/src/apps/system/matrix/registry/contracts/source_manifest.contract.json`
- `backend/src/apps/system/matrix/registry/directskip/skip_trace_contact_discovery/analysis/baseline-only/session_mxsess_1c8TRplqMFISkLb4iVm702PV.json`
- `backend/src/apps/system/matrix/registry/directskip/skip_trace_contact_discovery/analysis/baseline-only/session_mxsess_3dxdUjDJzsdYUboCZkvWlaTQ.json`
- `backend/src/apps/system/matrix/registry/directskip/skip_trace_contact_discovery/analysis/baseline-only/session_mxsess_6AkAple7OtLYztFA6xjAjDbj.json`
- `backend/src/apps/system/matrix/registry/directskip/skip_trace_contact_discovery/analysis/baseline-only/session_mxsess_8AtH7ZN1skwZdjPdsw3uLCJo.json`
- `backend/src/apps/system/matrix/registry/directskip/skip_trace_contact_discovery/analysis/baseline-only/session_mxsess_98FPpFMNr11P2Swiy8EePjNL.json`
- `backend/src/apps/system/matrix/registry/directskip/skip_trace_contact_discovery/analysis/baseline-only/session_mxsess_9DUAj0znsVyBDVnsziNsQ6MT.json`
- `backend/src/apps/system/matrix/registry/directskip/skip_trace_contact_discovery/analysis/baseline-only/session_mxsess_DbG7uQVjBK56N9BUBI96p0co.json`
- `backend/src/apps/system/matrix/registry/directskip/skip_trace_contact_discovery/analysis/baseline-only/session_mxsess_Dm8ycm7VVkRFtIYHvpeecfg3.json`
- `backend/src/apps/system/matrix/registry/directskip/skip_trace_contact_discovery/analysis/baseline-only/session_mxsess_MEKjVZdfFmmXP2FAI0jQ5wj3.json`
- `backend/src/apps/system/matrix/registry/directskip/skip_trace_contact_discovery/analysis/baseline-only/session_mxsess_OgRrfv8vPLS1b9aMhzmjZ7c3.json`
- `backend/src/apps/system/matrix/registry/directskip/skip_trace_contact_discovery/analysis/baseline-only/session_mxsess_QFixjb2zYQOLI1c8DtKKHJ6J.json`
- `backend/src/apps/system/matrix/registry/directskip/skip_trace_contact_discovery/analysis/baseline-only/session_mxsess_SJ7ZKWr3S9udCfqbnJjzWcuL.json`
- `backend/src/apps/system/matrix/registry/directskip/skip_trace_contact_discovery/analysis/baseline-only/session_mxsess_V6RBmk61JuTlIYlOFSeMJeth.json`
- `backend/src/apps/system/matrix/registry/directskip/skip_trace_contact_discovery/analysis/baseline-only/session_mxsess_V8hhTzPKSsxIhRKuUzlhUiXP.json`
## Tag: matrix

- `.auto-claude/file-timelines/frontend_node_modules_caniuse-lite_data_features_dommatrix.js.json`
- `.tmp/matrix-ai-first-cli-prototype-2026-04-05/analysis/directskip_current_whitley-comparison.json`
- `.tmp/matrix-ai-first-cli-prototype-2026-04-05/analysis/run-status.json`
- `.tmp/matrix-ai-first-cli-prototype-2026-04-05/baseline/lead_finder_field_catalog.json`
- `.tmp/matrix-ai-first-cli-prototype-2026-04-05/inputs/directskip/directskip_current_whitley.json`
- `.tmp/matrix-ai-first-cli-prototype-2026-04-05/inputs/directskip/directskip_legacy_charlotte_basham.json`
- `.tmp/matrix-ai-first-cli-prototype-2026-04-05/inputs/reiq/reiq_appt_of_sub_trustee_tx_00fa13bd.json`
- `.tmp/matrix-ai-first-cli-prototype-2026-04-05/inputs/reiq/reiq_divorce_fl_01a7e1b2.json`
- `.tmp/matrix-ai-first-cli-prototype-2026-04-05/inputs/reiq/reiq_eviction_fl_041698f6.json`
- `.tmp/matrix-ai-first-cli-prototype-2026-04-05/inputs/reiq/reiq_heirship_tx_152de6ee.json`
- `.tmp/matrix-ai-first-cli-prototype-2026-04-05/inputs/reiq/reiq_loan_modification_fl_c45a1057.json`
- `.tmp/matrix-ai-first-cli-prototype-2026-04-05/inputs/reiq/reiq_pre_foreclosure_fl_0b17ec0b.json`
- `.tmp/matrix-ai-first-cli-prototype-2026-04-05/inputs/reiq/reiq_probates_fl_03f6b20e.json`
- `.tmp/matrix-ai-first-cli-prototype-2026-04-05/inputs/reiq/reiq_tax_sale_fl_08923dd0.json`
- `.tmp/matrix-ai-first-cli-prototype-2026-04-05/logs/claude-directskip_current_whitley.wrapper.json`
- `.tmp/matrix-ai-first-cli-prototype-2026-04-05/manifests/cases.json`
- `.tmp/matrix-ai-first-cli-prototype-2026-04-05/manifests/prepared_cases.json`
- `.tmp/matrix-ai-first-cli-prototype-2026-04-05/outputs/claude/directskip_current_whitley.json`
- `.tmp/matrix-ai-first-cli-prototype-2026-04-05/outputs/codex/directskip_current_whitley.json`
- `.tmp/matrix-ai-first-cli-prototype-2026-04-05/outputs/codex/directskip_legacy_charlotte_basham.json`
- `.tmp/matrix-ai-first-cli-prototype-2026-04-05/outputs/codex/reiq_appt_of_sub_trustee_tx_00fa13bd.json`
- `.tmp/matrix-ai-first-cli-prototype-2026-04-05/outputs/codex/reiq_divorce_fl_01a7e1b2.json`
- `.tmp/matrix-ai-first-cli-prototype-2026-04-05/outputs/codex/reiq_eviction_fl_041698f6.json`
- `.tmp/matrix-ai-first-cli-prototype-2026-04-05/outputs/codex/reiq_heirship_tx_152de6ee.json`
- `.tmp/matrix-ai-first-cli-prototype-2026-04-05/outputs/codex/reiq_loan_modification_fl_c45a1057.json`
- `.tmp/matrix-ai-first-cli-prototype-2026-04-05/outputs/codex/reiq_pre_foreclosure_fl_0b17ec0b.json`
- `.tmp/matrix-ai-first-cli-prototype-2026-04-05/outputs/codex/reiq_probates_fl_03f6b20e.json`
- `.tmp/matrix-ai-first-cli-prototype-2026-04-05/outputs/codex/reiq_tax_sale_fl_08923dd0.json`
- `.tmp/matrix-ai-first-cli-prototype-2026-04-05/outputs/matrix/directskip_current_whitley.json`
- `.tmp/matrix-ai-first-cli-prototype-2026-04-05/outputs/matrix/directskip_legacy_charlotte_basham.json`
## Tag: realtor

- `_projeto-antigo/backend/.reports/realtor_api_endpoints_test/autocomplete_address.json`
- `_projeto-antigo/backend/.reports/realtor_api_endpoints_test/autocomplete_city.json`
- `_projeto-antigo/backend/.reports/realtor_api_endpoints_test/autocomplete_postal_code.json`
- `_projeto-antigo/backend/.reports/realtor_api_endpoints_test/execute_graphql_query_persisted.json`
- `_projeto-antigo/backend/.reports/realtor_api_endpoints_test/fetch_area_boundary_city.json`
- `_projeto-antigo/backend/.reports/realtor_api_endpoints_test/fetch_area_boundary_postal.json`
- `_projeto-antigo/backend/.reports/realtor_api_endpoints_test/fetch_market_details.json`
- `_projeto-antigo/backend/.reports/realtor_api_endpoints_test/fetch_nearby_homes.json`
- `_projeto-antigo/backend/.reports/realtor_api_endpoints_test/fetch_nearby_homes_by_coordinates.json`
- `_projeto-antigo/backend/.reports/realtor_api_endpoints_test/fetch_nearby_homes_for_map.json`
- `_projeto-antigo/backend/.reports/realtor_api_endpoints_test/fetch_property_details.json`
- `_projeto-antigo/backend/.reports/realtor_api_endpoints_test/fetch_property_estimates.json`
- `_projeto-antigo/backend/.reports/realtor_api_endpoints_test/fetch_property_history.json`
- `_projeto-antigo/backend/.reports/realtor_api_endpoints_test/fetch_recently_sold.json`
- `_projeto-antigo/backend/.reports/realtor_api_endpoints_test/fetch_similar_homes.json`
- `_projeto-antigo/backend/.reports/realtor_api_endpoints_test/fetch_spot_offer_evaluation.json`
- `_projeto-antigo/backend/.reports/realtor_api_endpoints_test/test_connection.json`
- `_projeto-antigo/backend/src/lib/clients/realtor/tests/snapshots/autocomplete_search.json`
- `_projeto-antigo/backend/src/lib/clients/realtor/tests/snapshots/connection_test.json`
- `_projeto-antigo/backend/src/lib/clients/realtor/tests/snapshots/fetch_area_boundary.json`
- `_projeto-antigo/backend/src/lib/clients/realtor/tests/snapshots/fetch_market_details.json`
- `_projeto-antigo/backend/src/lib/clients/realtor/tests/snapshots/fetch_property_details.json`
- `_projeto-antigo/backend/src/lib/clients/realtor/tests/snapshots/fetch_property_estimates.json`
- `_projeto-antigo/backend/src/lib/clients/realtor/tests/snapshots/fetch_property_history.json`
- `_projeto-antigo/backend/src/lib/clients/realtor/tests/snapshots/nearby_homes_by_coordinates.json`
- `_projeto-antigo/backend/src/lib/clients/realtor/tests/snapshots/nearby_homes_for_map.json`
- `_projeto-antigo/backend/src/lib/clients/realtor/tests/snapshots/recently_sold.json`
## Tag: registry

- `.auto-claude/specs/005-architecture-extract-registry-as-independent-app-f/implementation_plan.json`
- `.auto-claude/specs/013-bug-url-routing-conflict-my-property-registry-vs-p/implementation_plan.json`
- `.auto-claude/specs/015-feature-status-lists-tags-registry-system-real-est/implementation_plan.json`
- `_projeto-antigo/backend/_archived/matrix/registry/reiq/appt_of_sub_trustee/context.json`
- `_projeto-antigo/backend/_archived/matrix/registry/reiq/appt_of_sub_trustee/tx/analysis/fingerprint.json`
- `_projeto-antigo/backend/_archived/matrix/registry/reiq/appt_of_sub_trustee/tx/analysis/step_zero.json`
- `_projeto-antigo/backend/_archived/matrix/registry/reiq/appt_of_sub_trustee/tx/data/2025-11-27/TX_appt-of-sub-trustee_00fa13bd-c01a-11ee-9e90-42010a800019.json`
- `_projeto-antigo/backend/_archived/matrix/registry/reiq/appt_of_sub_trustee/tx/data/2025-11-27/TX_appt-of-sub-trustee_00fa74b5-c01a-11ee-9e90-42010a800019.json`
- `_projeto-antigo/backend/_archived/matrix/registry/reiq/appt_of_sub_trustee/tx/data/2025-11-27/TX_appt-of-sub-trustee_03d29d25-a635-11ee-9e90-42010a800019.json`
- `_projeto-antigo/backend/_archived/matrix/registry/reiq/appt_of_sub_trustee/tx/data/2025-11-27/TX_appt-of-sub-trustee_03d36099-a635-11ee-9e90-42010a800019.json`
- `_projeto-antigo/backend/_archived/matrix/registry/reiq/appt_of_sub_trustee/tx/data/2025-11-27/TX_appt-of-sub-trustee_06643b7f-bc5a-11ef-b0f1-42010a800021.json`
- `_projeto-antigo/backend/_archived/matrix/registry/reiq/appt_of_sub_trustee/tx/data/2025-11-27/TX_appt-of-sub-trustee_0664c1f8-bc5a-11ef-b0f1-42010a800021.json`
- `_projeto-antigo/backend/_archived/matrix/registry/reiq/appt_of_sub_trustee/tx/data/2025-11-27/TX_appt-of-sub-trustee_06fc72db-846f-11ee-9e90-42010a800019.json`
- `_projeto-antigo/backend/_archived/matrix/registry/reiq/appt_of_sub_trustee/tx/data/2025-11-27/TX_appt-of-sub-trustee_06febf66-846f-11ee-9e90-42010a800019.json`
- `_projeto-antigo/backend/_archived/matrix/registry/reiq/appt_of_sub_trustee/tx/data/2025-11-27/TX_appt-of-sub-trustee_07003d71-846f-11ee-9e90-42010a800019.json`
- `_projeto-antigo/backend/_archived/matrix/registry/reiq/appt_of_sub_trustee/tx/data/2025-11-27/TX_appt-of-sub-trustee_0700bfd6-846f-11ee-9e90-42010a800019.json`
- `_projeto-antigo/backend/_archived/matrix/registry/reiq/appt_of_sub_trustee/tx/data/2025-11-27/TX_appt-of-sub-trustee_1392f402-8210-11ee-94e0-42010a800016.json`
- `_projeto-antigo/backend/_archived/matrix/registry/reiq/appt_of_sub_trustee/tx/data/2025-11-27/TX_appt-of-sub-trustee_13934fa0-8210-11ee-94e0-42010a800016.json`
- `_projeto-antigo/backend/_archived/matrix/registry/reiq/appt_of_sub_trustee/tx/data/2025-11-27/TX_appt-of-sub-trustee_1393a55a-8210-11ee-94e0-42010a800016.json`
- `_projeto-antigo/backend/_archived/matrix/registry/reiq/appt_of_sub_trustee/tx/data/2025-11-27/TX_appt-of-sub-trustee_1d76b476-295c-11ef-8ff3-42010a80001f.json`
- `_projeto-antigo/backend/_archived/matrix/registry/reiq/appt_of_sub_trustee/tx/data/2025-11-27/TX_appt-of-sub-trustee_200192c1-295c-11ef-8ff3-42010a80001f.json`
- `_projeto-antigo/backend/_archived/matrix/registry/reiq/appt_of_sub_trustee/tx/data/2025-11-27/TX_appt-of-sub-trustee_29ccfd26-eaab-11ee-a98f-42010a80001d.json`
- `_projeto-antigo/backend/_archived/matrix/registry/reiq/appt_of_sub_trustee/tx/data/2025-11-27/TX_appt-of-sub-trustee_2b15e7ff-37b3-11ef-8ff3-42010a80001f.json`
- `_projeto-antigo/backend/_archived/matrix/registry/reiq/appt_of_sub_trustee/tx/data/2025-11-27/TX_appt-of-sub-trustee_2fc0979e-c594-11ee-9e90-42010a800019.json`
- `_projeto-antigo/backend/_archived/matrix/registry/reiq/appt_of_sub_trustee/tx/data/2025-11-27/TX_appt-of-sub-trustee_2ff91e42-f366-11ef-9005-42010a800023.json`
- `_projeto-antigo/backend/_archived/matrix/registry/reiq/appt_of_sub_trustee/tx/data/2025-11-27/TX_appt-of-sub-trustee_2ffa80c4-f366-11ef-9005-42010a800023.json`
- `_projeto-antigo/backend/_archived/matrix/registry/reiq/appt_of_sub_trustee/tx/data/2025-11-27/TX_appt-of-sub-trustee_2ffb1342-f366-11ef-9005-42010a800023.json`
- `_projeto-antigo/backend/_archived/matrix/registry/reiq/appt_of_sub_trustee/tx/data/2025-11-27/TX_appt-of-sub-trustee_2ffc2857-f366-11ef-9005-42010a800023.json`
- `_projeto-antigo/backend/_archived/matrix/registry/reiq/appt_of_sub_trustee/tx/data/2025-11-27/TX_appt-of-sub-trustee_2ffd3d80-f366-11ef-9005-42010a800023.json`
- `_projeto-antigo/backend/_archived/matrix/registry/reiq/appt_of_sub_trustee/tx/data/2025-11-27/TX_appt-of-sub-trustee_2fff5419-f366-11ef-9005-42010a800023.json`
## Tag: reiq

- `.tmp/direct-codex-baseline-probe/reiq/loan_modification/high/00_FL_loan-modification_c45a1057-8de0-11ee-9e90-42010a800019.json`
- `.tmp/direct-codex-baseline-probe/reiq/loan_modification/high/01_summary.json`
- `.tmp/direct-codex-baseline-probe/reiq/loan_modification/high/02_chunk_plan.json`
- `.tmp/direct-codex-baseline-probe/reiq/loan_modification/high/03_judgments.json`
- `.tmp/direct-codex-baseline-probe/reiq/loan_modification/high/04_flagged_judgments.json`
- `.tmp/direct-codex-baseline-probe/reiq/loan_modification/low/00_FL_loan-modification_c45a1057-8de0-11ee-9e90-42010a800019.json`
- `.tmp/direct-codex-baseline-probe/reiq/loan_modification/low/01_summary.json`
- `.tmp/direct-codex-baseline-probe/reiq/loan_modification/low/02_chunk_plan.json`
- `.tmp/direct-codex-baseline-probe/reiq/loan_modification/low/03_judgments.json`
- `.tmp/direct-codex-baseline-probe/reiq/loan_modification/low/04_flagged_judgments.json`
- `.tmp/direct-codex-baseline-probe/reiq/loan_modification/medium/00_FL_loan-modification_c45a1057-8de0-11ee-9e90-42010a800019.json`
- `.tmp/direct-codex-baseline-probe/reiq/loan_modification/medium/01_summary.json`
- `.tmp/direct-codex-baseline-probe/reiq/loan_modification/medium/02_chunk_plan.json`
- `.tmp/direct-codex-baseline-probe/reiq/loan_modification/medium/03_judgments.json`
- `.tmp/direct-codex-baseline-probe/reiq/loan_modification/medium/04_flagged_judgments.json`
- `.tmp/lead-finder-group-acceptance-probe-2026-04-05/outputs/reiq-sourcehub-handoff.json`
- `.tmp/matrix-ai-first-cli-prototype-2026-04-05/inputs/reiq/reiq_appt_of_sub_trustee_tx_00fa13bd.json`
- `.tmp/matrix-ai-first-cli-prototype-2026-04-05/inputs/reiq/reiq_divorce_fl_01a7e1b2.json`
- `.tmp/matrix-ai-first-cli-prototype-2026-04-05/inputs/reiq/reiq_eviction_fl_041698f6.json`
- `.tmp/matrix-ai-first-cli-prototype-2026-04-05/inputs/reiq/reiq_heirship_tx_152de6ee.json`
- `.tmp/matrix-ai-first-cli-prototype-2026-04-05/inputs/reiq/reiq_loan_modification_fl_c45a1057.json`
- `.tmp/matrix-ai-first-cli-prototype-2026-04-05/inputs/reiq/reiq_pre_foreclosure_fl_0b17ec0b.json`
- `.tmp/matrix-ai-first-cli-prototype-2026-04-05/inputs/reiq/reiq_probates_fl_03f6b20e.json`
- `.tmp/matrix-ai-first-cli-prototype-2026-04-05/inputs/reiq/reiq_tax_sale_fl_08923dd0.json`
- `.tmp/matrix-ai-first-cli-prototype-2026-04-05/outputs/codex/reiq_appt_of_sub_trustee_tx_00fa13bd.json`
- `.tmp/matrix-ai-first-cli-prototype-2026-04-05/outputs/codex/reiq_divorce_fl_01a7e1b2.json`
- `.tmp/matrix-ai-first-cli-prototype-2026-04-05/outputs/codex/reiq_eviction_fl_041698f6.json`
- `.tmp/matrix-ai-first-cli-prototype-2026-04-05/outputs/codex/reiq_heirship_tx_152de6ee.json`
- `.tmp/matrix-ai-first-cli-prototype-2026-04-05/outputs/codex/reiq_loan_modification_fl_c45a1057.json`
- `.tmp/matrix-ai-first-cli-prototype-2026-04-05/outputs/codex/reiq_pre_foreclosure_fl_0b17ec0b.json`
## Tag: sourcehub

- `.tmp/lead-finder-group-acceptance-probe-2026-04-05/outputs/directskip-sourcehub-handoffs.json`
- `.tmp/lead-finder-group-acceptance-probe-2026-04-05/outputs/reiq-sourcehub-handoff.json`
- `.tmp/matrix-sourcehub-real-outputs-2026-04-03/directskip-matrix-output.json`
- `.tmp/matrix-sourcehub-real-outputs-2026-04-03/directskip-sourcehub-output.json`
- `.tmp/matrix-sourcehub-real-outputs-2026-04-03/reiq-matrix-output.json`
- `.tmp/matrix-sourcehub-real-outputs-2026-04-03/reiq-sourcehub-output.json`
- `.tmp/p4y-1032-normalization-proof-2026-04-06/outputs/directskip-sourcehub-handoffs.json`
- `.tmp/p4y-1032-normalization-proof-2026-04-06/outputs/reiq-sourcehub-handoff.json`
- `.tmp/p4y-1036-structural-proof-2026-04-06/outputs/directskip-sourcehub-handoffs.json`
- `.tmp/p4y-1036-structural-proof-2026-04-06/outputs/reiq-sourcehub-handoff.json`
- `.tmp/p4y-1047-baseline-proof-2026-04-06/outputs/directskip-sourcehub-handoffs.json`
- `.tmp/p4y-1047-baseline-proof-2026-04-06/outputs/reiq-sourcehub-handoff.json`
- `.tmp/p4y-1054-universal-street-line-and-duplicate-intelligence-2026-04-06/outputs/directskip-sourcehub-handoffs.json`
- `.tmp/p4y-1054-universal-street-line-and-duplicate-intelligence-2026-04-06/outputs/reiq-sourcehub-handoff.json`
- `.tmp/p4y-1079-baseline-analytics-proof-2026-04-06/outputs/directskip-sourcehub-handoffs.json`
- `.tmp/p4y-1079-baseline-analytics-proof-2026-04-06/outputs/reiq-sourcehub-handoff.json`
- `.tmp/p4y-1183/pre_sourcehub_dto_composed.json`
- `.tmp/p4y-1183/pre_sourcehub_dto_runtime.json`
- `.tmp/p4y-1183/pre_sourcehub_final_dto_probe_runtime.json`
- `.tmp/p4y-1183/sourcehub_reference_handoffs.json`
- `_projeto-antigo/backend/docs/sourcehub/audit_2025-11-14/raw_samples/reiq_appt-of-sub-trustee_detail_054fb142-b4c0-11f0-be91-42010a800029.json`
- `_projeto-antigo/backend/docs/sourcehub/audit_2025-11-14/raw_samples/reiq_appt-of-sub-trustee_detail_ed4b8679-adbb-11f0-9808-42010a800027.json`
- `_projeto-antigo/backend/docs/sourcehub/audit_2025-11-14/raw_samples/reiq_appt-of-sub-trustee_list_page1.json`
- `_projeto-antigo/backend/docs/sourcehub/audit_2025-11-14/raw_samples/reiq_divorce_detail_043a9b1e-adbc-11f0-9808-42010a800027.json`
- `_projeto-antigo/backend/docs/sourcehub/audit_2025-11-14/raw_samples/reiq_divorce_detail_eab64f26-bd61-11f0-be91-42010a800029.json`
- `_projeto-antigo/backend/docs/sourcehub/audit_2025-11-14/raw_samples/reiq_divorce_list_page1.json`
- `_projeto-antigo/backend/docs/sourcehub/audit_2025-11-14/raw_samples/reiq_eviction_detail_67e0afe2-bd67-11f0-be91-42010a800029.json`
- `_projeto-antigo/backend/docs/sourcehub/audit_2025-11-14/raw_samples/reiq_eviction_detail_67ecdd81-bd67-11f0-be91-42010a800029.json`
- `_projeto-antigo/backend/docs/sourcehub/audit_2025-11-14/raw_samples/reiq_eviction_list_page1.json`
- `_projeto-antigo/backend/docs/sourcehub/audit_2025-11-14/raw_samples/reiq_heirship_detail_b0f8b0e4-b0b2-11f0-9808-42010a800027.json`
## Tag: structured_json

- `.auto-claude/file-timelines/frontend_node_modules_caniuse-lite_data_features_dommatrix.js.json`
- `.auto-claude/specs/001-use-o-10x-para-melhorar-toda-a-l-gica-e-entendimen/implementation_plan.json`
- `.auto-claude/specs/002-preciso-que-vc-analise-a-discuss-o-abaixo-para-que/implementation_plan.json`
- `.auto-claude/specs/003-me-fale-do-que-se-trata-esse-projeto-de-forma-deta/implementation_plan.json`
- `.auto-claude/specs/004-feature-enhanced-input-components-moneyinput-addre/implementation_plan.json`
- `.auto-claude/specs/005-architecture-extract-registry-as-independent-app-f/implementation_plan.json`
- `.auto-claude/specs/006-feature-lead-finder-visual-polish-ui-components-ca/implementation_plan.json`
- `.auto-claude/specs/006-feature-lead-finder-visual-polish-ui-components-ca/requirements.json`
- `.auto-claude/specs/006-feature-lead-finder-visual-polish-ui-components-ca/task_metadata.json`
- `.auto-claude/specs/007-ui-branded-scrollbar-with-brand-orange-color-front/implementation_plan.json`
- `.auto-claude/specs/008-feature-autocompleteinput-integration-in-addproper/implementation_plan.json`
- `.auto-claude/specs/009-bug-addpropertymodal-input-ux-corrections-real-est/implementation_plan.json`
- `.auto-claude/specs/010-feature-modalheader-colorscheme-variant-system-bra/implementation_plan.json`
- `.auto-claude/specs/011-bug-modalcontent-overflow-pushes-footer-off-screen/implementation_plan.json`
- `.auto-claude/specs/012-refactor-migrate-addpropertymodal-to-modular-modal/implementation_plan.json`
- `.auto-claude/specs/013-bug-url-routing-conflict-my-property-registry-vs-p/implementation_plan.json`
- `.auto-claude/specs/014-bug-property-model-inconsistency-causing-test-fail/implementation_plan.json`
- `.auto-claude/specs/015-feature-status-lists-tags-registry-system-real-est/implementation_plan.json`
- `.auto-claude/specs/016-feature-implement-4th-step-in-addpropertymodal-bas/implementation_plan.json`
- `.auto-claude/specs/017-bug-fix-addpropertymodal-never-mounts-when-propert/implementation_plan.json`
- `.auto-claude/specs/018-bug-fix-react-jsx-errors-add-property-modal-in-my-/implementation_plan.json`
- `.auto-claude/specs/019-bug-crmfilterdrawer-import-error-breaking-my-prope/implementation_plan.json`
- `.auto-claude/specs/020-bug-lead-finder-6-critical-ui-ux-bugs-requiring-sp/implementation_plan.json`
- `.auto-claude/specs/020-bug-lead-finder-6-critical-ui-ux-bugs-requiring-sp/requirements.json`
- `.auto-claude/specs/020-bug-lead-finder-6-critical-ui-ux-bugs-requiring-sp/task_metadata.json`
- `.auto-claude/specs/021-bug-fix-propertyservice-critical-runtime-errors-le/implementation_plan.json`
- `.auto-claude/specs/022-bug-propertyservice-critical-runtime-fixes-real-es/implementation_plan.json`
- `.auto-claude/specs/023-feature-implement-my-property-page-with-ai-studio-/implementation_plan.json`
- `.auto-claude/specs/024-bug-javascript-typescript-errors-and-backend-impor/implementation_plan.json`
- `.auto-claude/specs/025-refactor-billing-views-security-hardening-sprint-8/implementation_plan.json`
## Tag: system_app

- `backend/src/apps/system/lead_finder/artifacts/lead_finder_default_genome.lf_default.v1.json`
- `backend/src/apps/system/lead_finder/baselines/owner/model_inventory/owner_entity.groups.v1.json`
- `backend/src/apps/system/lead_finder/baselines/owner/model_inventory/owner_entity.v1.json`
- `backend/src/apps/system/lead_finder/baselines/owner/owner_contact_address.v1.json`
- `backend/src/apps/system/lead_finder/baselines/owner/owner_email.v1.json`
- `backend/src/apps/system/lead_finder/baselines/owner/owner_identity.v1.json`
- `backend/src/apps/system/lead_finder/baselines/owner/owner_phone.v1.json`
- `backend/src/apps/system/lead_finder/baselines/owner/owner_relationship_evidence.v1.json`
- `backend/src/apps/system/lead_finder/baselines/owner/owner_structural_position.v1.json`
- `backend/src/apps/system/matrix/registry/contracts/baseline_only_analysis.contract.json`
- `backend/src/apps/system/matrix/registry/contracts/compiled_schema_artifact.contract.json`
- `backend/src/apps/system/matrix/registry/contracts/context.contract.json`
- `backend/src/apps/system/matrix/registry/contracts/contextual_analysis.contract.json`
- `backend/src/apps/system/matrix/registry/contracts/dataset_discrepancy_report.contract.json`
- `backend/src/apps/system/matrix/registry/contracts/provider_semantics_pack.contract.json`
- `backend/src/apps/system/matrix/registry/contracts/source_manifest.contract.json`
- `backend/src/apps/system/matrix/registry/directskip/skip_trace_contact_discovery/analysis/baseline-only/session_mxsess_1c8TRplqMFISkLb4iVm702PV.json`
- `backend/src/apps/system/matrix/registry/directskip/skip_trace_contact_discovery/analysis/baseline-only/session_mxsess_3dxdUjDJzsdYUboCZkvWlaTQ.json`
- `backend/src/apps/system/matrix/registry/directskip/skip_trace_contact_discovery/analysis/baseline-only/session_mxsess_6AkAple7OtLYztFA6xjAjDbj.json`
- `backend/src/apps/system/matrix/registry/directskip/skip_trace_contact_discovery/analysis/baseline-only/session_mxsess_8AtH7ZN1skwZdjPdsw3uLCJo.json`
- `backend/src/apps/system/matrix/registry/directskip/skip_trace_contact_discovery/analysis/baseline-only/session_mxsess_98FPpFMNr11P2Swiy8EePjNL.json`
- `backend/src/apps/system/matrix/registry/directskip/skip_trace_contact_discovery/analysis/baseline-only/session_mxsess_9DUAj0znsVyBDVnsziNsQ6MT.json`
- `backend/src/apps/system/matrix/registry/directskip/skip_trace_contact_discovery/analysis/baseline-only/session_mxsess_DbG7uQVjBK56N9BUBI96p0co.json`
- `backend/src/apps/system/matrix/registry/directskip/skip_trace_contact_discovery/analysis/baseline-only/session_mxsess_Dm8ycm7VVkRFtIYHvpeecfg3.json`
- `backend/src/apps/system/matrix/registry/directskip/skip_trace_contact_discovery/analysis/baseline-only/session_mxsess_MEKjVZdfFmmXP2FAI0jQ5wj3.json`
- `backend/src/apps/system/matrix/registry/directskip/skip_trace_contact_discovery/analysis/baseline-only/session_mxsess_OgRrfv8vPLS1b9aMhzmjZ7c3.json`
- `backend/src/apps/system/matrix/registry/directskip/skip_trace_contact_discovery/analysis/baseline-only/session_mxsess_QFixjb2zYQOLI1c8DtKKHJ6J.json`
- `backend/src/apps/system/matrix/registry/directskip/skip_trace_contact_discovery/analysis/baseline-only/session_mxsess_SJ7ZKWr3S9udCfqbnJjzWcuL.json`
- `backend/src/apps/system/matrix/registry/directskip/skip_trace_contact_discovery/analysis/baseline-only/session_mxsess_V6RBmk61JuTlIYlOFSeMJeth.json`
- `backend/src/apps/system/matrix/registry/directskip/skip_trace_contact_discovery/analysis/baseline-only/session_mxsess_V8hhTzPKSsxIhRKuUzlhUiXP.json`
## Tag: test_or_fixture

- `.auto-claude/specs/001-use-o-10x-para-melhorar-toda-a-l-gica-e-entendimen/implementation_plan.json`
- `.auto-claude/specs/002-preciso-que-vc-analise-a-discuss-o-abaixo-para-que/implementation_plan.json`
- `.auto-claude/specs/003-me-fale-do-que-se-trata-esse-projeto-de-forma-deta/implementation_plan.json`
- `.auto-claude/specs/004-feature-enhanced-input-components-moneyinput-addre/implementation_plan.json`
- `.auto-claude/specs/005-architecture-extract-registry-as-independent-app-f/implementation_plan.json`
- `.auto-claude/specs/006-feature-lead-finder-visual-polish-ui-components-ca/implementation_plan.json`
- `.auto-claude/specs/006-feature-lead-finder-visual-polish-ui-components-ca/requirements.json`
- `.auto-claude/specs/006-feature-lead-finder-visual-polish-ui-components-ca/task_metadata.json`
- `.auto-claude/specs/007-ui-branded-scrollbar-with-brand-orange-color-front/implementation_plan.json`
- `.auto-claude/specs/008-feature-autocompleteinput-integration-in-addproper/implementation_plan.json`
- `.auto-claude/specs/009-bug-addpropertymodal-input-ux-corrections-real-est/implementation_plan.json`
- `.auto-claude/specs/010-feature-modalheader-colorscheme-variant-system-bra/implementation_plan.json`
- `.auto-claude/specs/011-bug-modalcontent-overflow-pushes-footer-off-screen/implementation_plan.json`
- `.auto-claude/specs/012-refactor-migrate-addpropertymodal-to-modular-modal/implementation_plan.json`
- `.auto-claude/specs/013-bug-url-routing-conflict-my-property-registry-vs-p/implementation_plan.json`
- `.auto-claude/specs/014-bug-property-model-inconsistency-causing-test-fail/implementation_plan.json`
- `.auto-claude/specs/015-feature-status-lists-tags-registry-system-real-est/implementation_plan.json`
- `.auto-claude/specs/016-feature-implement-4th-step-in-addpropertymodal-bas/implementation_plan.json`
- `.auto-claude/specs/017-bug-fix-addpropertymodal-never-mounts-when-propert/implementation_plan.json`
- `.auto-claude/specs/018-bug-fix-react-jsx-errors-add-property-modal-in-my-/implementation_plan.json`
- `.auto-claude/specs/019-bug-crmfilterdrawer-import-error-breaking-my-prope/implementation_plan.json`
- `.auto-claude/specs/020-bug-lead-finder-6-critical-ui-ux-bugs-requiring-sp/implementation_plan.json`
- `.auto-claude/specs/020-bug-lead-finder-6-critical-ui-ux-bugs-requiring-sp/requirements.json`
- `.auto-claude/specs/020-bug-lead-finder-6-critical-ui-ux-bugs-requiring-sp/task_metadata.json`
- `.auto-claude/specs/021-bug-fix-propertyservice-critical-runtime-errors-le/implementation_plan.json`
- `.auto-claude/specs/022-bug-propertyservice-critical-runtime-fixes-real-es/implementation_plan.json`
- `.auto-claude/specs/023-feature-implement-my-property-page-with-ai-studio-/implementation_plan.json`
- `.auto-claude/specs/024-bug-javascript-typescript-errors-and-backend-impor/implementation_plan.json`
- `.auto-claude/specs/025-refactor-billing-views-security-hardening-sprint-8/implementation_plan.json`
- `.auto-claude/specs/026-refactor-fix-sales-domain-root-route-404-eliminate/implementation_plan.json`
