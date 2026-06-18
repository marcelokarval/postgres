# Review — LFG materialization runs/results

Status: proposta/review operacional; não é DDL final.
Worker: B — LFG materialization run/result review gate.
Escopo alvo futuro: `database/ddl/projects/prop4you/leadfinder_group/0002_materialization_runs.sql`.

## 1. Conclusão curta

A próxima camada após staging deve ser um gate explícito de execução com duas tabelas mínimas:

- `prop4you_leadfinder_group.materialization_runs`: uma execução/revisão em lote, ligada a um escopo de staging e a um `sourcehub.translated_dto`/dictionary/matrix baseline.
- `prop4you_leadfinder_group.materialization_results`: um resultado por staging candidate/publicação DTO, com status, hash/lineage, payload operacional mínimo e bloqueios revisáveis.

Esse par deve ficar entre LFG staging e qualquer tabela operacional. Ele não deve pular direto para produto final, não deve criar o grafo final LeadFinder, e não deve espalhar owners/properties/leads em dezenas de tabelas. A função de materialização deve transformar somente candidates elegíveis em resultados revisáveis; uma etapa separada pode promover resultados `passed/accepted` para o operacional mínimo.

## 2. Evidência lida no repo

Arquivos revisados:

- `database/ddl/projects/prop4you/sourcehub/0002_translated_dto_publications.sql`
- `database/ddl/projects/prop4you/sourcehub/0001_sourcehub_corpus.sql`
- `database/ddl/projects/prop4you/leadfinder/0001_canonical_dictionary.sql`
- `database/ddl/projects/prop4you/matrix/0002_mapping_sessions.sql`
- `database/ddl/projects/prop4you/matrix/0005_field_mapping_set_artifacts.sql`
- `docs/issues/09-prop4you-sourcehub-translated-dto-publications/11-executive-synthesis.md`
- `docs/issues/10-prop4you-lfg-staging-materialization-operational/00-detection-and-analysis.md`
- `docs/issues/10-prop4you-lfg-staging-materialization-operational/01-prd.md`
- `docs/issues/10-prop4you-lfg-staging-materialization-operational/02-tasks.md`

Pontos relevantes:

- Slice 09 provou: `97 REIQ raws -> 10 bridge rows -> 1 field_mapping_set -> 10 SourceHub translated DTO publications -> 0 LFG materializations`.
- `sourcehub/0002` declara explicitamente `T4` e `leadfinder_materialization = T5_later`; portanto T5 deve consumir publicações, não raw payload direto.
- `translated_dto_publications` já expõe lineage suficiente: `raw_record_id`, `matrix_artifact_id`, `leadfinder_dictionary_version_id`, provider/payload class, hashes e summaries.
- `publish_translated_dtos_from_field_mapping_set` pode gerar 10 DTOs `ready_for_review`; LFG não deve reexecutar Matrix nem ler provider.
- `raw_records.leadfinder_publication_status` já marca `candidate_dto_ready` ou `published`, mas isso ainda é SourceHub readiness, não materialização LFG.
- `leadfinder/0001` ainda é dictionary/candidates/gaps; não há grafo operacional final para assumir.

## 3. Boundary obrigatório do gate T5.1

Cabeçalho recomendado para a DDL futura:

```sql
-- package: prop4you/leadfinder_group
-- file: 0002_materialization_runs.sql
-- status: experimental / non-final
-- purpose: reviewable LFG materialization run/result gate from LFG staging candidates into minimal operational candidates.
-- depends-on: leadfinder_group/0001_staging_candidates.sql, sourcehub/0002_translated_dto_publications.sql, leadfinder/0001_canonical_dictionary.sql, matrix/0002_mapping_sessions.sql
-- idempotency: idempotent
-- destructive: false
-- [GATEWAY_AGNOSTIC] Callable by direct SQL, PostgREST RPC, ORM, workers, or other gateways.
-- [NO_PROVIDER_CALLS] No HTTP/provider calls, no corpus reads, no secrets.
-- [NO_RAW_PAYLOAD_DUMP] Results store compact operational candidate JSON/summaries, not raw provider payload dumps.
-- [REVIEW_GATE] materialization_runs/results are a gate between staging and operational tables.
-- [NO_FINAL_PRODUCT_TABLE_EXPLOSION] Does not create final LFG product graph/list/detail/scoring model.
```

## 4. Modelo recomendado: `materialization_runs`

Nome recomendado: `prop4you_leadfinder_group.materialization_runs`.

Responsabilidade: registrar uma tentativa controlada de transformar staging candidates em resultados revisáveis.

Campos mínimos recomendados:

- `id uuid primary key default uuidv7()`
- `public_ref text generated always as (base.make_public_ref('p4ylfgr', id)) stored`
- `run_key text not null unique`
- `run_status text not null default 'draft'`
- `run_gate_status text not null default 'not_started'`
- `run_kind text not null default 'staging_to_operational_minimum'`
- `staging_scope text not null default 'sourcehub_translated_dto_publications'`
- `leadfinder_dictionary_version_id uuid not null references prop4you_leadfinder.canonical_dictionary_versions(id)`
- `matrix_artifact_id uuid references prop4you_matrix.transformation_artifacts(id)`
- `provider_id uuid references prop4you_provider.providers(id)`
- `payload_class_id uuid references prop4you_provider.payload_classes(id)`
- `input_candidate_count integer not null default 0`
- `result_count integer not null default 0`
- `passed_count integer not null default 0`
- `blocked_count integer not null default 0`
- `failed_count integer not null default 0`
- `materialization_plan jsonb not null default '{}'::jsonb`
- `quality_summary jsonb not null default '{}'::jsonb`
- `redaction_summary jsonb not null default '{}'::jsonb`
- `metadata jsonb not null default '{}'::jsonb`
- `started_at timestamptz`
- `finished_at timestamptz`
- `reviewed_at timestamptz`
- `reviewed_by_actor_id text`
- `approved_at timestamptz`
- lifecycle padrão: `active`, `deleted`, `created_at`, `updated_at`, `last_modified_by_actor_id`, `version`.

Vocabulário sugerido:

- `run_status`: `draft`, `running`, `completed`, `completed_with_blocks`, `failed`, `cancelled`, `superseded`, `archived`.
- `run_gate_status`: `not_started`, `ready_for_review`, `passed`, `blocked`, `not_applicable`.
- `run_kind`: `staging_to_operational_minimum`, `dry_run`, `replay`, `regression_check`, `unknown`.

Checks importantes:

- `run_key ~ '^[a-z][a-z0-9_.:-]{1,191}$'`.
- contadores `>= 0`.
- `run_gate_status = 'passed'` somente se `run_status in ('completed','completed_with_blocks')` e `failed_count = 0`.
- `finished_at >= started_at`, quando ambos existirem.
- JSONB columns com `jsonb_typeof(...) = 'object'`.

Índices:

- `(run_status, run_gate_status, created_at desc)`.
- `(leadfinder_dictionary_version_id, run_status)`.
- `(matrix_artifact_id, run_status)` where not null.
- `(provider_id, payload_class_id, run_status)`.

## 5. Modelo recomendado: `materialization_results`

Nome recomendado: `prop4you_leadfinder_group.materialization_results`.

Responsabilidade: preservar uma linha por staging candidate processado, sem ainda escrever diretamente no operacional final.

Campos mínimos recomendados:

- `id uuid primary key default uuidv7()`
- `public_ref text generated always as (base.make_public_ref('p4ylfgz', id)) stored`
- `run_id uuid not null references prop4you_leadfinder_group.materialization_runs(id) on delete restrict`
- `staging_candidate_id uuid not null references prop4you_leadfinder_group.staging_candidates(id) on delete restrict`
- `source_publication_id uuid not null references prop4you_sourcehub.translated_dto_publications(id) on delete restrict`
- `raw_record_id uuid not null references prop4you_sourcehub.raw_records(id) on delete restrict`
- `matrix_artifact_id uuid not null references prop4you_matrix.transformation_artifacts(id) on delete restrict`
- `leadfinder_dictionary_version_id uuid not null references prop4you_leadfinder.canonical_dictionary_versions(id) on delete restrict`
- `result_key text not null unique`
- `result_status text not null default 'candidate'`
- `result_gate_status text not null default 'ready_for_review'`
- `operation_kind text not null default 'upsert_operational_minimum_candidate'`
- `dedupe_key text`
- `source_publication_sha256 text`
- `materialized_payload jsonb not null default '{}'::jsonb`
- `materialized_payload_sha256 text`
- `field_coverage_summary jsonb not null default '{}'::jsonb`
- `blocking_summary jsonb not null default '{}'::jsonb`
- `lineage_summary jsonb not null default '{}'::jsonb`
- `target_schema name`
- `target_table name`
- `target_id uuid`
- lifecycle padrão: `active`, `deleted`, `created_at`, `updated_at`, `last_modified_by_actor_id`, `version`.

Vocabulário sugerido:

- `result_status`: `candidate`, `materialized_candidate`, `blocked`, `failed`, `skipped`, `accepted_for_operational`, `promoted_to_operational`, `rejected`, `superseded`, `archived`.
- `result_gate_status`: `not_started`, `ready_for_review`, `passed`, `blocked`, `not_applicable`.
- `operation_kind`: `upsert_operational_minimum_candidate`, `dry_run_validate`, `skip_duplicate`, `block_privacy`, `block_mapping_gap`, `unknown`.

Checks importantes:

- `unique (run_id, staging_candidate_id)`.
- `result_key` determinístico, por exemplo `lfgmat:<run_uuid_sem_hifen>:<staging_uuid_sem_hifen>` ou baseado em `source_publication_id` quando reprocessável.
- `source_publication_sha256` e `materialized_payload_sha256` com regex `^[0-9a-f]{64}$`, quando não nulos.
- `materialized_payload`, `field_coverage_summary`, `blocking_summary`, `lineage_summary` devem ser objetos JSONB.
- `target_schema/table/id` devem ser todos nulos ou todos preenchidos. Antes da promoção operacional, permanecer nulos.
- `result_status = 'promoted_to_operational'` exige `target_id is not null` e `result_gate_status = 'passed'`.

Índices:

- `(run_id, result_status, result_gate_status)`.
- `(staging_candidate_id, result_status)`.
- `(source_publication_id, result_status)`.
- `(raw_record_id)` para auditoria.
- `(leadfinder_dictionary_version_id, result_status)`.
- partial unique por `dedupe_key where deleted=false and dedupe_key is not null`, se a dedupe for estabilizada.
- GIN em `field_coverage_summary`/`blocking_summary` se os reviews filtrarem por motivos.

## 6. Regras de elegibilidade

A função de execução deve aceitar somente staging candidates que atendam ao gate anterior. Como o Worker A ainda definirá `staging_candidates`, recomendo compatibilidade mínima:

- staging candidate ativo e não deletado.
- staging status em algo equivalente a `ready_for_materialization` ou `accepted_for_materialization`.
- staging gate em `passed` ou `ready_for_review`, conforme modo `dry_run` vs execução real.
- `source_publication_id` apontando para `translated_dto_publications` ativa, não deletada, `publication_status in ('ready_for_review','published')` e `publication_gate_status in ('ready_for_review','passed')`.
- `source_publication.review_status` não pode ser `needs_redaction`, `needs_mapping_revision`, `needs_dictionary_revision`, `rejected`.
- dictionary version consistente entre staging candidate, publication, Matrix artifact e run.
- Matrix artifact deve continuar `artifact_kind='field_mapping_set'`, não deletado, gate `ready_for_review/passed`.
- sem leitura direta de `raw_payload` durante materialização, exceto FK/hashes/lineage já publicados.

Para `run_gate_status='passed'`, recomendo exigir entradas com gate anterior `passed`; para `ready_for_review`, aceitar entradas em review, desde que a saída fique `ready_for_review` e não seja promovida.

## 7. Funções recomendadas

### 7.1 Criar execução

Nome sugerido:

```sql
prop4you_leadfinder_group.create_materialization_run(
  p_run_key text default null,
  p_dictionary_version_id uuid,
  p_matrix_artifact_id uuid default null,
  p_provider_id uuid default null,
  p_payload_class_id uuid default null,
  p_limit integer default 100,
  p_run_kind text default 'staging_to_operational_minimum',
  p_actor_id text default null,
  p_metadata jsonb default '{}'::jsonb
)
```

Deve criar `materialization_runs` em `running` ou `draft`, com `materialization_plan` contendo filtros e fase temporal:

```json
{
  "sourcehub_dto_publication": "T4",
  "lfg_staging": "T5.0",
  "lfg_materialization_gate": "T5.1",
  "operational_minimum": "T5.2_later",
  "no_provider_calls": true,
  "no_raw_payload_dump": true
}
```

### 7.2 Executar run e gerar results

Nome sugerido:

```sql
prop4you_leadfinder_group.execute_materialization_run(
  p_run_id uuid,
  p_limit integer default 100,
  p_actor_id text default null
)
returns setof prop4you_leadfinder_group.materialization_results
```

Comportamento:

1. Bloquear run inexistente, deletado, finalizado ou com status incompatível.
2. Selecionar staging candidates elegíveis e suas publicações SourceHub.
3. Validar consistência dictionary/matrix/provider/payload class.
4. Construir `materialized_payload` compacto e versionado a partir do staging candidate/translated DTO, não do raw payload.
5. Gravar `materialization_results` idempotentes por `(run_id, staging_candidate_id)` ou `result_key`.
6. Classificar cada linha como `materialized_candidate`, `blocked`, `failed` ou `skipped`, com `blocking_summary` explícito.
7. Atualizar contadores do run e fechar com `completed`, `completed_with_blocks` ou `failed`.
8. Não inserir em tabelas operacionais; isso pertence à etapa T5.2.

### 7.3 Marcar gate/review

Nome sugerido:

```sql
prop4you_leadfinder_group.review_materialization_result(
  p_result_id uuid,
  p_result_gate_status text,
  p_result_status text default null,
  p_actor_id text default null,
  p_review_note text default null,
  p_metadata jsonb default '{}'::jsonb
)
```

Aprovar/promover deve ser separado:

- `review_materialization_result`: muda gate/status de resultado.
- T5.2: função operacional consome apenas results `result_gate_status='passed'` e `result_status='accepted_for_operational'`.

## 8. Payload materializado: formato mínimo

`materialized_payload` não deve ser um produto final. Deve ser um envelope auditável:

```json
{
  "contract": "leadfinder_group.materialization_result.v0",
  "gateway_agnostic": true,
  "source": {
    "source_publication_id": "uuid",
    "staging_candidate_id": "uuid",
    "raw_record_id": "uuid",
    "translated_dto_sha256": "sha256"
  },
  "dictionary": {
    "dictionary_version_id": "uuid"
  },
  "candidate": {
    "entity_key": "stable key if available",
    "facets": {},
    "situations": [],
    "lineage_refs": []
  },
  "quality": {
    "required_field_count": 0,
    "present_field_count": 0,
    "blocked_reasons": []
  },
  "temporal_phase": {
    "sourcehub_dto_publication": "T4",
    "lfg_staging": "T5.0",
    "lfg_materialization_gate": "T5.1",
    "operational_minimum": "T5.2_later"
  }
}
```

Permitir valores derivados do DTO/staging para provar a jornada no banco, mas documentação/proofs não devem imprimir escalares sensíveis. Para browser-proof, use contagens, refs, hashes, status e timestamps.

## 9. Relação com operacional mínimo T5.2

O gate B deve entregar para o Worker C/Thor somente resultados aceitos, não tabelas finais.

Regra recomendada:

```text
SourceHub translated DTO publication
  -> LFG staging candidate
  -> materialization run/result
  -> minimal operational group/event/facet only if result_gate_status='passed'
```

Não recomendo que `execute_materialization_run` preencha `target_schema/table/id`. Esses campos ficam nulos até uma função T5.2 promover resultados aceitos. Isso evita pular o gate e permite revisão antes de qualquer entidade operacional.

## 10. Views de revisão

Criar pelo menos duas views:

- `v_materialization_run_review`: run + contadores + dictionary/matrix/provider + gate/status.
- `v_materialization_result_review`: result + run_key + staging/publication refs + hashes + status/gate + blocking/coverage summaries.

A view de result deve omitir/raw payload e preferir:

- `public_ref`
- `run_public_ref`
- `source_publication_public_ref`
- `staging_candidate_public_ref`
- `raw_record_public_ref`
- `translated_dto_sha256`
- `materialized_payload_sha256`
- contagens e statuses

## 11. Idempotência e concorrência

Recomendações:

- `run_key` determinístico por escopo quando for replay/proof; exemplo `lfgmat:reiq:property_search_result:<artifact_short>:<dictionary_short>:proof10`.
- `materialization_results` unique por `(run_id, staging_candidate_id)` para evitar duplicação dentro da run.
- Não usar `on conflict` em partial unique index como caminho primário; use `result_key` ou `(run_id, staging_candidate_id)`.
- Atualizar contadores do run por agregação dos results após execução, não por incremento cego em loop.
- Evitar side effects fora do schema `prop4you_leadfinder_group` durante T5.1, exceto timestamps/status do próprio staging se o Worker A definir status como `materialization_in_review`.

## 12. Privacidade e segurança

- Não imprimir `translated_dto` completo em proof/review browser.
- Não ler `raw_records.raw_payload` na função T5.1 para preencher resultado; o contrato de entrada é T4/T5.0.
- `blocking_summary` pode conter códigos (`missing_required_field`, `privacy_boundary`, `dictionary_mismatch`), mas não valores pessoais.
- Sem RLS pública nesta fatia.
- Sem provider calls, cron, pg_net, secrets, workers obrigatórios ou dependência Django/PostgREST.

## 13. Critérios de aceitação para esta camada

Para a prova do PRD:

- Uma run criada.
- Dez staging candidates processados.
- Dez `materialization_results` criados.
- Contadores do run batem: `input_candidate_count=10`, `result_count=10`, e `passed/blocked/failed` somam 10.
- Nenhuma tabela operacional é preenchida por T5.1 diretamente.
- Browser-proof mostra refs/status/contagens/hashes, não payload bruto nem escalares DTO sensíveis.

## 14. Riscos / decisões pendentes

1. O Worker A ainda precisa fechar o contrato exato de `staging_candidates`; este review presume FK `staging_candidate_id` e vínculo com `source_publication_id`.
2. O nome do schema/pacote proposto pelo PRD é `leadfinder_group`; o schema deve ser algo como `prop4you_leadfinder_group` para manter padrão do repo.
3. Definir se `run_gate_status='passed'` requer todos results passed ou aceita `completed_with_blocks` com blocks explicitamente revisados.
4. Definir se `materialized_payload` guarda facetas já no formato T5.2 ou apenas envelope intermediário. Minha recomendação: envelope intermediário com `candidate.facets`, sem assumir tabelas finais.
5. Definir hash canônico de `materialized_payload`; para prova experimental, `digest(jsonb::text,'sha256')` é aceitável se documentado como banco-local, não canonicalização universal.
6. Registrar prefixos públicos novos (`p4ylfgr`, `p4ylfgz`) no mesmo padrão base quando a DDL for implementada.

## 15. Veredito

A camada `materialization_runs/results` é necessária e deve ser implementada antes do operacional mínimo. Ela preserva o gate entre SourceHub/staging e LFG operacional, permite auditar os 10 DTOs provados no slice 09, e impede a tentação de transformar T4 diretamente em produto final.

Recomendação: implementar `leadfinder_group/0002_materialization_runs.sql` com as duas tabelas, funções de criação/execução/review e views de revisão descritas acima, mas manter a promoção operacional em `0003_operational_minimum.sql`.
