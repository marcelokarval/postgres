# Revisão do corpus JSON DirectSkip / skip trace para LFG

Escopo: apenas JSONs relacionados a DirectSkip/skip trace nos manifests LFG e na árvore fonte de `prop4you-inertia`.

Política de privacidade aplicada: os arquivos foram parseados para chaves, tipos, contagens e famílias de caminho. Nenhum valor bruto de JSON, telefone, e-mail, nome, endereço ou outro PII foi reproduzido neste relatório.

## Fontes verificadas

Manifests em `postgres/docs/corpus/prop4you/lfg/`:

- `prop4you-inertia-json-manifest.v1.jsonl`: 13.160 registros totais; 284 registros com indício DirectSkip/skip trace; 284 parseáveis.
- `prop4you-inertia-lfg-corpus-candidates.v1.jsonl`: 3.545 candidatos totais; 261 candidatos DirectSkip/skip trace; 261 parseáveis.

Árvore fonte em `prop4you-inertia`:

- 236 JSONs com DirectSkip/skip trace no nome/caminho.
- 261 JSONs DirectSkip/skip trace nos candidatos LFG por path/tags/top-level keys/sample paths.
- Todos os 261 candidatos resolvem para arquivo existente e parseável na árvore fonte.

## Contagens dos 261 candidatos LFG DirectSkip/skip trace

Por família de caminho sanitizada:

| Família | Qtde | Leitura |
| --- | ---: | --- |
| `matrix_registry_directskip.analysis` | 117 | sessões/análises de Matrix para provider/list type |
| `matrix_registry_directskip.other` | 86 | contratos, schemas, data manifests e artefatos auxiliares de registry |
| `i18n_feature_flags` | 12 | traduções/feature flags de UI, não payload de domínio |
| `legacy.lfg_property_mocks` | 10 | mocks legados de propriedades com contagens/slots de contato |
| `tmp.matrix_ai_first` | 9 | protótipos Matrix AI-first com input/output DirectSkip |
| `matrix_registry_directskip.tx` | 7 | dados transacionais/raw de registry DirectSkip |
| `tmp.sourcehub_handoffs` | 6 | handoffs SourceHub já no envelope de promoção para Lead Finder |
| `tmp.proofs` | 3 | sumários/provas operacionais envolvendo DirectSkip |
| `legacy.directskip_client` | 3 | auditorias/snapshots do cliente legado DirectSkip |
| `_projeto-antigo/backend/.reports` | 2 | relatórios agregados legados |
| `legacy.directskip_data` | 2 | respostas raw legadas de DirectSkip |
| demais famílias unitárias | 4 | ignores/config, fixture, prova browser |

Outras métricas dos 261 candidatos:

- `root_type`: 251 objetos, 10 arrays.
- Tags dominantes: `structured_json` 261, `directskip` 235, `matrix` 224, `legacy_system` 211, `system_app` 211, `registry` 210.
- Tamanho total aproximado dos arquivos candidatos: 373.299.006 bytes; maior arquivo aproximado: 35.788.758 bytes.
- Pares path/type acumulados declarados no manifest para esses candidatos: 144.957.

## Forma de evidência observada

### 1. Payload provider/raw DirectSkip

Arquivos representativos (sem valores expostos):

- `_projeto-antigo/backend/src/data/directskip_sample_response.json`
- `_projeto-antigo/backend/src/data/directskip_charlotte_basham_response.json`
- `backend/src/apps/system/matrix/registry/directskip/skip_trace_contact_discovery/tx/data/undated/directskip_real_response.json`
- `backend/src/apps/system/matrix/tests/fixtures/directskip_real_response.json`

Forma estrutural recorrente:

- raiz objeto com blocos `input`, `status`, `result_code`, `contacts`.
- `contacts[]` contém arrays/objetos para:
  - `names[]`
  - `phones[]`
  - `emails[]`
  - `confirmed_address[]`
  - `relatives[]`
- contagens sanitizadas nos arquivos raw nomeados:
  - arquivos legados de data: 1 contato, 7 phones, 2 emails, 5 relatives, 1 confirmed_address por payload observado.
  - fixture/tx atual: 1 contato, 3 phones, 2 emails, 2 relatives, 1 confirmed_address por payload observado.

Leitura para LFG: esses arquivos são bons para validar shape/provider parser e casos de cardinalidade, mas devem permanecer como raw lineage/fixture, não como contrato canônico direto.

### 2. Matrix registry para `directskip/skip_trace_contact_discovery`

Famílias principais:

- `backend/src/apps/system/matrix/registry/directskip/skip_trace_contact_discovery/analysis/...`
- `backend/src/apps/system/matrix/registry/directskip/skip_trace_contact_discovery/contracts/...`
- `backend/src/apps/system/matrix/registry/directskip/skip_trace_contact_discovery/schema/...`
- `backend/src/apps/system/matrix/registry/directskip/skip_trace_contact_discovery/data/...`
- `backend/src/apps/system/matrix/registry/directskip/skip_trace_contact_discovery/tx/...`

Top-level keys frequentes:

- `provider_slug`, `list_type_slug`, `state_slug`
- `artifact_kind`, `session_public_id`, `session_key`
- `published_contract_ref`, `baseline_version`, `contract_refs`
- `alias_evidence_snapshot`, `canonical_dictionary_snapshot`, `coverage_snapshot`
- `multi_provider_snapshot`, `provider_drift_snapshot`, `dataset_discrepancy_snapshot`
- `field_analysis`, `matrix_context_snapshot`, `workspace_snapshot`, `corpus_stats`, `source_manifest`, `source_surface`

Leitura para LFG: esses artefatos são evidência de mapeamento e governança semântica. Devem alimentar versionamento, aprovação, drift e lineage, mas não devem ser achatados como registros operacionais de contato.

### 3. SourceHub handoffs já próximos do envelope LFG

Arquivos `directskip-sourcehub-handoffs.json` encontrados: 6.

Presença por arquivo:

- `raw_record_public_id`: 6/6.
- `mailing_contact_handoff`: 6/6.
- `contact_satellites_handoff`: 6/6.
- `relationship_evidence_handoff`: 6/6.
- `co_owner_contact_satellites_handoff`: 0/6 na amostra revisada.

Forma de `contact_satellites_handoff` nos 6 arquivos:

- campos envelope escalares/identificadores: `provider_slug`, `list_type_slug`, `canonical_schema_version`, `mapping_version`, `raw_record_public_id`, `seed_public_id`, `ingested_at`, `producer_stage`, `consumer_stage`, `queue`, `canonical_property_public_id`, `state_slug`.
- arrays canônicos: `phone_seeds`, `email_seeds`.
- blocos compostos: `match_metrics`, `portable_intelligence`, `transformation_lineage`.
- cardinalidade observada: `phone_seeds` min/med/max = 3/3/3; `email_seeds` min/med/max = 2/2/2.

Forma de `relationship_evidence_handoff` nos 6 arquivos:

- campos envelope semelhantes ao handoff de contato.
- blocos adicionais: `owner_returned`, `property_address_comparison`, `relationship_evidence_seeds`.
- cardinalidade observada: `relationship_evidence_seeds` min/med/max = 2/2/2.

Forma de `mailing_contact_handoff` nos 6 arquivos:

- campos envelope semelhantes.
- blocos: `mailing_address_seed`, `property_address_seed` quando disponível, `property_address_comparison` quando disponível, `portable_intelligence`, `transformation_lineage`.
- `property_address_seed` e `property_address_comparison` aparecem em 3/6.

## Como usar no envelope `contact_satellites`

O caminho mais seguro para LFG é consumir o envelope SourceHub já montado, não o payload DirectSkip raw:

1. `provider -> SourceHub`: persistir raw payload e raw record reference.
2. `Matrix`: validar mapping/versionamento para `provider_slug=directskip` e `list_type_slug=skip_trace_contact_discovery`.
3. `SourceHub`: publicar seed envelopes por família:
   - `contact_satellites_handoff` para phones/emails.
   - `mailing_contact_handoff` para endereço de contato/mailing.
   - `relationship_evidence_handoff` para relatives/associates.
   - `co_owner_contact_satellites_handoff` apenas quando houver owner canônico explícito para co-owner.
4. `Lead Finder`: materializar apenas seeds aprovados e associados a `canonical_property_public_id`/`canonical_owner_public_id` quando exigido.

Contrato de contato recomendado para `contact_satellites`:

- Envelope mínimo projetável: provider/list type/version/raw record/seed/property/stage/queue/ingested/state.
- `phone_seeds[]`: materializar em tabela/visão de contato telefônico com `owner_ref`, `role_in_record`, `phone_number`, `contact_role`, `phone_type`, `phone_subtype`, `contact_source_confidence`.
- `email_seeds[]`: materializar em tabela/visão de contato de email com `owner_ref`, `role_in_record`, `email`, `contact_role`, `contact_source_confidence`.
- `match_metrics`: usar como política de promoção e auditoria, não como fonte absoluta de identidade de owner.
- `portable_intelligence` e `transformation_lineage`: preservar como JSONB versionado para explicabilidade, reprocessamento e auditoria.

Regra crítica observada no código-fonte: contatos de DirectSkip são evidência para descoberta de contato; eles não definem a verdade canônica de owner/property. Promoção deve respeitar `promotion_policy`, `owner_identity_required_for_promotion`, bloqueio de contatos address-only e cap de confiança quando houver falha/ambiguidade de normalização.

## Candidatos a projeção relacional vs `keep_jsonb`

### Projection candidates

Projetar em colunas/tabelas relacionais quando usados para busca, join, RLS, dedupe, métricas ou promoção:

Envelope de handoff:

- `provider_slug`
- `list_type_slug`
- `canonical_schema_version`
- `mapping_version`
- `raw_record_public_id`
- `seed_public_id`
- `canonical_property_public_id`
- `canonical_owner_public_id` quando existir
- `target_owner_role` quando existir
- `producer_stage`
- `consumer_stage`
- `queue`
- `ingested_at`
- `state_slug`

Contato telefônico (`phone_seeds[]`):

- `owner_ref`
- `role_in_record`
- `phone_number`
- `contact_role`
- `phone_type`
- `phone_subtype`
- `contact_source_confidence`

Contato email (`email_seeds[]`):

- `owner_ref`
- `role_in_record`
- `email`
- `contact_role`
- `contact_source_confidence`

Endereço de contato/mailing (`mailing_address_seed`):

- `address_line`, `secondary_address_line`
- `address_number`, `street_line`, `street_name`, directional/type/occupancy components
- `city`, `state`, `zip_code`, `county`, `country`
- `normalized_address`, `address_hash`, `is_po_box`, `contact_address_type`

Evidência de relacionamento (`relationship_evidence_seeds[]`):

- `evidence_ref`
- `display_name`, `first_name`, `middle_name`, `last_name`
- `relationship_label`, `relationship_type`
- `age`
- `identity_resolution_status`
- `possible_duplicate_of_owner`
- `duplicate_resolution_vote_required`
- `owner_match_confidence`
- `relationship_evidence_confidence`

Métricas/política de promoção, como colunas derivadas ou view materializada:

- `recommended_result_status`
- `submitted_owner_status`
- `submitted_owner_top_level_found`
- `submitted_owner_relative_found`
- `co_owner_top_level_found`
- `best_co_owner_contact_index`
- `confidence_cap_applied`
- `confidence_cap`
- `normalizer_failure_detected`
- flags de `promotion_policy`.

### keep_jsonb

Manter como JSONB versionado/lineage quando a forma é mutável, explicativa ou de governança:

- raw provider payload completo (`input`, `status`, `result_code`, `contacts`, arrays internos raw).
- `provider_response_payload` dentro de raw payload SourceHub.
- `transformation_lineage` completo.
- `portable_intelligence` completo.
- `match_metrics` completo, além de colunas derivadas principais.
- `property_address_comparison` completo, além de flags/enum deriváveis.
- `owner_returned` completo, além de identidade normalizada/projetada quando promovida.
- `semantic_primitives`, `field_mappings`, `resolution_evidence_projection` dos DTOs pre-SourceHub.
- Matrix registry artifacts: `alias_evidence_snapshot`, `canonical_dictionary_snapshot`, `coverage_snapshot`, `multi_provider_snapshot`, `provider_drift_snapshot`, `dataset_discrepancy_snapshot`, `field_analysis`, `workspace_snapshot`, `corpus_stats`, `source_manifest`, `source_surface`.
- i18n/feature flag JSONs e relatórios/provas browser: fora do core LFG materialization; manter como suporte/documentação.

## Recomendação LFG

1. Tratar `contact_satellites_handoff` como o corpus primário para implementação do envelope LFG de phones/emails.
2. Usar raw DirectSkip apenas para testes de parser, regressão e lineage (`keep_jsonb`).
3. Projetar os seeds aprovados por SourceHub em relações de contato (`phone`, `email`) com chaves para property/owner quando disponíveis.
4. Preservar Matrix registry e `transformation_lineage` como JSONB governado para explicar por que um seed foi aceito, bloqueado ou reprocessável.
5. Exigir `promotion_policy`/confidence checks antes de publicar contatos em inventário pesquisável, especialmente quando há sinais de address-only, relative-only, co-owner ou normalizer failure.

## Riscos residuais

- Os 6 handoffs revisados não exercitam `co_owner_contact_satellites_handoff`; o shape foi inferido do código-fonte e deve ganhar fixture própria.
- Alguns candidatos são arquivos grandes de registry/análise; a revisão foi estrutural, não semântica linha-a-linha.
- Arquivos i18n/feature flags aparecem por termos `skipTracing`, mas não devem entrar no corpus de domínio LFG exceto como suporte de UI.
- Campos de PII foram identificados por nomes/shape; qualquer migração real precisa de controles de mascaramento, RLS e retention antes de exposição operacional.

## Evidência de validação

Comandos executados sem imprimir valores raw de JSON:

- parse dos dois manifests para contagens, root types, tags, famílias de path e top-level keys.
- parse dos 261 candidatos LFG DirectSkip/skip trace contra a árvore fonte; resultado: 0 arquivos ausentes, 0 erros de parse.
- varredura por nome/caminho na árvore fonte; resultado: 236 JSONs com DirectSkip/skip trace no caminho.
- análise focada dos 6 `directskip-sourcehub-handoffs.json`; resultado: 6/6 com `contact_satellites_handoff`, `mailing_contact_handoff`, `relationship_evidence_handoff`; 0/6 com `co_owner_contact_satellites_handoff`.
