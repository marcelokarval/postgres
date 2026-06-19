# Worker C — revisão de contrato DDL/proof para review-board de projection candidates

Status: done
Idioma: pt-BR
Escopo: revisão estática, sem provider/MCP/web, sem mutação de DDL existente.

## Arquivos revisados

- `database/ddl/projects/prop4you/leadfinder_group/0005_canonical_jsonschema_registry.sql`
- `scripts/proof-prop4you-lfg-jsonschema-registry.sh`
- `scripts/proof-prop4you-ddl-lab.sh`
- Contexto de issue: `01-prd.md`, `02-tasks.md`
- Contexto DDL adjacente: `0001_staging_candidates.sql`, `0002_materialization_runs.sql`, `0004_user_feedback_markers.sql`

## Leitura do estado atual

O DDL `0005_canonical_jsonschema_registry.sql` já estabelece uma boa base para o board:

- `projection_policies` guarda a política versionada de promoção JSONB -> relacional.
- `canonical_jsonschema_envelopes` guarda envelopes canônicos e vincula cada envelope à política.
- `v_active_projection_policy_gates` expõe os 7 gates como linhas consultáveis.
- `v_active_canonical_jsonschema_envelopes` expõe envelopes ativos sem payload bruto.
- O contrato é explicitamente gateway-agnostic, registry-only, sem provider calls, sem valores crus de payload e sem explosão de tabelas finais.

Os scripts de proof existentes validam:

- apply order de base + Prop4You experimental até `0005`;
- existência de registry e envelopes;
- contagem de 6 envelopes, 1 política e 7 gates;
- política de `no_raw_payload_values`;
- schemas top-level fechados (`additionalProperties=false`);
- defaults de auto-apply para marker low-risk: 3 usuários e 2 workspaces.

Gap principal: ainda não existe uma estrutura persistente e consultável que represente:

- grupos de candidatos de projeção;
- caminhos JSON candidatos por grupo;
- avaliação de cada um dos 7 gates por candidato;
- decisões de board/reviewer;
- fila de próxima ação;
- prova que nenhum candidato é aprovado sem 7 gates passados.

## Recomendação de estrutura para `0006_projection_candidate_review_board.sql`

Criar o novo DDL em `database/ddl/projects/prop4you/leadfinder_group/0006_projection_candidate_review_board.sql`, dependente de `leadfinder_group/0005_canonical_jsonschema_registry.sql`.

Cabeçalho recomendado:

```sql
-- package: prop4you/leadfinder_group
-- file: 0006_projection_candidate_review_board.sql
-- status: experimental / non-final
-- purpose: Review-board queryable para candidatos de projeção JSONB -> relacional, gates e decisões.
-- depends-on: leadfinder_group/0005_canonical_jsonschema_registry.sql
-- idempotency: idempotent
-- destructive: false
-- [GATEWAY_AGNOSTIC]
-- [REVIEW_BOARD_ONLY]
-- [NO_PROVIDER_CALLS]
-- [NO_RAW_PAYLOAD_VALUES]
-- [NO_FINAL_PRODUCT_TABLE_EXPLOSION]
```

### 1. `projection_candidate_groups`

Representa lanes/grupos de decisão, com sequenciamento semântico.

Campos recomendados:

- `id uuid primary key default uuidv7()`
- `public_ref generated` com prefixo novo, por exemplo `p4ylfgpcg`
- `group_key text not null unique`
- `group_status text not null default 'candidate'`
- `group_kind text not null`
- `sequence_number integer not null`
- `lane_key text not null`
- `lane_title text not null`
- `canonical_envelope_key text`
- `schema_version text not null default 'v1'`
- `projection_policy_key text not null default 'lfg_projection_policy.v1'`
- `semantic_owner text not null default 'leadfinder_group'`
- `privacy_class text not null default 'mixed_review_required'`
- `relational_target_kind text not null default 'jsonb_projection_candidate'`
- `review_priority integer not null default 100`
- `decision_status text not null default 'pending'`
- `decision_reason text`
- `lineage jsonb not null default '{}'::jsonb`
- `metadata jsonb not null default '{}'::jsonb`
- lifecycle: `active`, `created_at`, `updated_at`, `version`

Constraints sugeridas:

- `group_key ~ '^[a-z][a-z0-9_.:-]{1,191}$'`
- `group_status in ('candidate','in_review','approved','blocked','rejected','superseded','archived')`
- `group_kind in ('directskip_contact_satellites','geography_boundary','geography_market','geography_property','valuation','property_physical_facts','legal_situation_signals','taxonomy_support','unknown')`
- `lane_key in ('directskip_unified','geography_first','valuation_downstream','property_facts_downstream','legal_situation_downstream','taxonomy_support_downstream')`
- `privacy_class in ('public_safe','restricted','pii_sensitive','provider_sensitive','mixed_review_required','unknown')`
- `decision_status in ('pending','ready_for_review','approved','blocked','rejected','needs_more_evidence','superseded','archived')`
- `sequence_number > 0`, `review_priority > 0`, JSON objects válidos.
- FK composta opcional para envelope: `(canonical_envelope_key, schema_version)` -> `canonical_jsonschema_envelopes(envelope_key, schema_version)` deferrable.
- FK composta para policy: `(projection_policy_key, schema_version)` -> `projection_policies(policy_key, policy_version)` deferrable.

Índices:

- `(lane_key, sequence_number, group_status)` where `active=true`
- `(decision_status, review_priority, updated_at desc)` where `active=true`
- GIN em `lineage jsonb_path_ops` ou `metadata` se usado nas filas.

### 2. `projection_candidates`

Representa cada path candidato, dentro de um grupo.

Campos recomendados:

- `id uuid primary key default uuidv7()`
- `public_ref generated` com prefixo novo, por exemplo `p4ylfgpc`
- `group_id uuid not null references projection_candidate_groups(id) on delete restrict`
- `candidate_key text not null unique`
- `candidate_status text not null default 'candidate'`
- `candidate_kind text not null default 'json_path_projection'`
- `canonical_envelope_key text not null`
- `schema_version text not null default 'v1'`
- `json_path text not null`
- `path_label text not null`
- `path_value_kind text not null default 'unknown'`
- `candidate_reason text not null`
- `relational_need text not null`
- `proposed_table text`
- `proposed_column text`
- `proposed_type text`
- `projection_shape text not null default 'scalar_column'`
- `privacy_class text not null default 'mixed_review_required'`
- `raw_value_policy text not null default 'no_raw_payload_values'`
- `corpus_evidence jsonb not null default '{}'::jsonb`
- `lineage jsonb not null default '{}'::jsonb`
- `review_status text not null default 'pending'`
- `approved_at timestamptz`
- `approved_by_actor_id text`
- lifecycle: `active`, `created_at`, `updated_at`, `version`

Constraints sugeridas:

- `unique(group_id, json_path)`
- `candidate_key ~ '^[a-z][a-z0-9_.:-]{1,191}$'`
- `candidate_status in ('candidate','in_review','approved','blocked','rejected','superseded','archived')`
- `candidate_kind in ('json_path_projection','derived_projection','group_projection','index_hint','constraint_hint','unknown')`
- `json_path` deve ser não vazio e começar com `$` ou com path lógico canônico controlado; preferir `json_path like '$.%' or json_path = '$'` se todos os seeds usarem JSONPath.
- `path_value_kind in ('string','number','integer','boolean','object','array','geo','temporal','enum','mixed','unknown')`
- `projection_shape in ('scalar_column','generated_column','expression_index','join_table','edge_table','postgis_geometry','materialized_view','jsonb_only','unknown')`
- `raw_value_policy in ('no_raw_payload_values','hashes_and_refs_only','normalized_values_allowed_internal','unknown')`
- `approved` só se policy permitir: `candidate_status <> 'approved' or review_status = 'approved'`.
- FK composta `(canonical_envelope_key, schema_version)` -> registry de envelopes.

Importante: não armazenar valores observados do corpus; `corpus_evidence` deve conter só contagens, tipos, hashes/refs e flags, por exemplo `observed_count`, `provider_family_refs`, `sourcehub_record_ref_count`, `sample_hash_refs`, `matrix_mapping_refs`.

Índices:

- `(group_id, candidate_status, review_status)` where `active=true`
- `(canonical_envelope_key, json_path)` where `active=true`
- `(review_status, updated_at desc)` where `active=true`
- GIN em `corpus_evidence` e/ou `lineage`.

### 3. `projection_candidate_gate_evaluations`

Uma linha por candidato e gate. O DDL deve garantir 7 linhas por candidato via seed/proof; em SQL puro a obrigatoriedade de “exatamente 7” é melhor provada por view/proof do que por check constraint.

Campos recomendados:

- `id uuid primary key default uuidv7()`
- `public_ref generated` com prefixo novo, por exemplo `p4ylfgpcg8` ou `p4ylfggt`
- `candidate_id uuid not null references projection_candidates(id) on delete cascade`
- `policy_key text not null default 'lfg_projection_policy.v1'`
- `policy_version text not null default 'v1'`
- `gate_key text not null`
- `gate_number integer not null`
- `required boolean not null default true`
- `gate_status text not null default 'not_evaluated'`
- `evaluation_result text not null default 'pending'`
- `evidence_summary jsonb not null default '{}'::jsonb`
- `blocking_reason text`
- `evaluated_at timestamptz`
- `evaluated_by_actor_id text`
- `created_at`, `updated_at`, `version`

Constraints sugeridas:

- `unique(candidate_id, gate_key)`
- `unique(candidate_id, gate_number)`
- FK `(policy_key, policy_version)` -> `projection_policies(policy_key, policy_version)`
- `gate_number between 1 and 7`
- `gate_status in ('not_evaluated','passed','failed','blocked','not_applicable')`
- `evaluation_result in ('pending','pass','fail','blocked','not_applicable')`
- `required=false or gate_status <> 'not_applicable'` se gates obrigatórios nunca puderem ser N/A; como a policy atual marca todos required, recomendo bloquear N/A para required.
- `gate_status='passed'` implica `evaluation_result='pass'`.
- JSON object em `evidence_summary`.

Índices:

- `(candidate_id, gate_number)`
- `(gate_key, gate_status)`
- `(policy_key, policy_version, gate_number)`

Seed recomendado: derivar gate rows via `insert ... select candidate.id, gate.* from projection_candidates cross join v_active_projection_policy_gates`, em vez de hardcodar 7 vezes por candidato. Isso reduz drift se a policy mudar de versão.

### 4. `projection_candidate_reviews`

Registra decisão do board/humano/policy sobre o candidato.

Campos recomendados:

- `id uuid primary key default uuidv7()`
- `public_ref generated` com prefixo novo, por exemplo `p4ylfgpcr`
- `candidate_id uuid not null references projection_candidates(id) on delete restrict`
- `review_key text not null unique`
- `review_status text not null default 'in_review'`
- `review_decision text not null default 'pending'`
- `decision_reason text`
- `reviewer_actor_id text`
- `reviewed_at timestamptz`
- `all_required_gates_passed boolean not null default false`
- `review_payload jsonb not null default '{}'::jsonb`
- `metadata jsonb not null default '{}'::jsonb`
- `created_at`, `updated_at`

Constraints sugeridas:

- `review_key` format check.
- `review_status in ('in_review','approved','rejected','blocked','deferred','superseded','archived')`
- `review_decision in ('pending','approve_projection','reject_projection','block_projection','request_more_evidence','defer','supersede')`
- `review_decision <> 'approve_projection' or all_required_gates_passed = true`
- JSON object checks.

Recomendação forte: não permitir aprovação via insert manual cega. Criar função gateway-agnostic `open_projection_candidate_review(...)` ou `record_projection_candidate_review(...)` que calcula `all_required_gates_passed` por query e atualiza `projection_candidates.review_status/candidate_status`. Mesmo com função, manter constraint como defesa.

## Views recomendadas

### `v_projection_candidate_gate_status`

Uma linha por candidato com rollup:

- `candidate_id`, `candidate_key`, `group_key`, `lane_key`, `sequence_number`
- `required_gate_count`
- `passed_required_gate_count`
- `failed_required_gate_count`
- `blocked_required_gate_count`
- `not_evaluated_required_gate_count`
- `all_required_gates_passed`
- `gate_status_summary jsonb`

Essa view é o coração do proof “não aprova sem 7 gates”.

### `v_active_projection_candidates`

Board operacional:

- dados de grupo, envelope, path, status, privacy, proposed shape;
- contagens de gates via join em `v_projection_candidate_gate_status`;
- sem valores brutos de payload.

### `v_approved_projection_candidates`

Somente candidatos aprovados e seguros:

Filtro obrigatório:

```sql
where candidate_status = 'approved'
  and review_status = 'approved'
  and all_required_gates_passed = true
```

### `v_projection_candidate_next_action_queue`

Fila ordenada por lane/sequence/priority:

- `needs_gate_evaluation`: gate faltando/falhou/bloqueou;
- `ready_for_board_review`: 7 gates passed mas sem review aprovado;
- `approved_ready_for_implementation`: aprovado e 7 gates passed;
- `blocked_or_rejected`: bloqueado/rejeitado.

Ordenação recomendada: `sequence_number`, `review_priority`, `updated_at`.

## Seeds mínimos recomendados

### Grupos

Seeds devem cobrir os critérios do PRD:

1. `directskip.contact_satellites.unified`
   - lane: `directskip_unified`
   - sequence: 10
   - envelope: `contact-satellites-envelope`
   - inclui phone/email, mailing address e relationship evidence no mesmo grupo.

2. `geography.realtor.boundary`
   - lane: `geography_first`
   - sequence: 20
   - envelope: `realtor-evidence-envelope`

3. `geography.realtor.market`
   - lane: `geography_first`
   - sequence: 30
   - envelope: `realtor-evidence-envelope`

4. `geography.reiq.property`
   - lane: `geography_first`
   - sequence: 40
   - envelope: `property-envelope` ou envelope provider-specific se existir; se ainda não existir, use metadata/lineage para indicar provider family sem FK a provider raw.

5. `valuation.downstream`
   - lane: `valuation_downstream`
   - sequence: 100

6. `property_physical_facts.downstream`
   - lane: `property_facts_downstream`
   - sequence: 110

7. `legal_situation_signals.downstream`
   - lane: `legal_situation_downstream`
   - sequence: 120

8. `taxonomy_support.downstream`
   - lane: `taxonomy_support_downstream`
   - sequence: 130

### Path-level candidates

Para DirectSkip unified, manter juntos no mesmo `group_id`:

- phone evidence path(s);
- email evidence path(s);
- mailing address path(s);
- owner/contact relationship evidence path(s).

Para geography-first lanes:

- boundary/geography evidence do Realtor;
- market geography do Realtor;
- REIQ state/county/property geography.

Os seeds devem usar paths canônicos do envelope quando possível e metadata para `provider_family`, `source_doc`, `review_reason`, sem payload scalar.

## Funções recomendadas

### `refresh_projection_candidate_gate_rows(p_candidate_id uuid)`

Cria/atualiza as 7 rows de gate a partir de `v_active_projection_policy_gates`.

Uso: após seed de candidatos e em proof.

### `record_projection_candidate_gate_evaluation(...)`

Permite atualizar um gate específico, validando `gate_key/gate_number` contra a policy ativa.

### `record_projection_candidate_review(...)`

Calcula `all_required_gates_passed` e só permite `approve_projection` quando todos os gates obrigatórios passam. Atualiza `projection_candidates` para `approved` apenas quando seguro.

## Contrato de proof recomendado

Criar script novo, por exemplo:

- `scripts/proof-prop4you-lfg-projection-candidate-review-board.sh`

O script deve seguir o estilo dos proofs atuais:

- usar clean lab DB via `scripts/proof-prop4you-ddl-lab.sh` ou apply order próprio;
- adicionar `0006_projection_candidate_review_board.sql` ao apply order;
- não chamar providers;
- não imprimir valores crus de payload/PII;
- gerar JSON machine-checkable;
- escrever report em `docs/reports/prop4you-lfg-projection-candidate-review-board-proof.md` somente no proof final.

Assertions mínimas:

```sql
select jsonb_build_object(
  'group_count', count_groups,
  'candidate_count', count_candidates,
  'directskip_group_count', count_directskip,
  'directskip_unified_path_kinds', directskip_kinds_json,
  'geography_first_group_count', count_geography,
  'downstream_group_count', count_downstream,
  'gate_row_count', count_gate_rows,
  'candidate_count_with_7_gates', count_candidates_with_7,
  'required_gate_count_per_candidate_ok', boolean,
  'approved_without_all_required_gates_count', count_bad_approvals,
  'approved_candidate_view_violation_count', count_bad_view_rows,
  'raw_value_policy_violation_count', count_raw_policy_bad,
  'top_next_action_queue_count', count_queue
)
```

Critérios de PASS:

- `group_count >= 8`.
- Existe exatamente um grupo DirectSkip unified ativo.
- DirectSkip unified contém ao menos path kinds de `phone`, `email`, `mailing_address`, `relationship_evidence` ou equivalentes normalizados.
- Geography-first tem grupos antes das lanes downstream: `max(geography sequence) < min(downstream sequence)`.
- Todo candidato seedado possui 7 gate rows.
- `approved_without_all_required_gates_count = 0`.
- `raw_value_policy_violation_count = 0`.
- Views existem: active, gate status, approved, queue.

## Recomendações sobre apply order

Atualizar `scripts/proof-prop4you-ddl-lab.sh` depois que o DDL existir:

- inserir `leadfinder_group/0006_projection_candidate_review_board.sql` imediatamente após `0005_canonical_jsonschema_registry.sql`;
- ampliar validation SQL para contar as novas tabelas/views;
- se o proof genérico continuar sem seeds ricos, manter as assertions completas no proof específico do review-board.

## Riscos e cuidados

1. Não modelar candidatos como tabelas finais de produto.
   - O board deve decidir projeção, não criar `properties`, `owners`, `contacts`, workspace tables ou graph final.

2. Não armazenar payload bruto em `corpus_evidence`, `review_payload` ou `metadata`.
   - Apenas contagens, refs, hashes, tipos e flags.

3. Não aprovar por status manual isolado.
   - Aprovação precisa ser derivada de gates + review.

4. Evitar duplicar gates hardcoded nos seeds.
   - Derivar de `v_active_projection_policy_gates`.

5. Manter a separação temporal:
   - Registry/policy (`0005`) -> review-board de projeção (`0006`) -> implementação futura de projeções aprovadas.

## Conclusão

A base atual (`0005` + proof registry) é suficiente para ancorar um review-board robusto. O próximo DDL deve introduzir quatro objetos duráveis principais: grupos, candidatos, gate evaluations e reviews, além de quatro views de operação/proof. O contrato essencial é: todo candidato seedado recebe 7 gate rows da policy ativa; nenhuma view ou função considera um candidato aprovado sem todos os gates obrigatórios passados e uma decisão explícita do review-board.
