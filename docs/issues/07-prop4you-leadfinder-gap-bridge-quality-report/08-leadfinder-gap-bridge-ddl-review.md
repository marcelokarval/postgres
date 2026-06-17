# Review — Worker A LeadFinder raw evidence gap bridge DDL

## Resultado

Implementado `database/ddl/projects/prop4you/leadfinder/0002_raw_evidence_gap_bridge.sql` como DDL idempotente e não-destrutivo para ligar evidência agregada da Matrix (`raw_path_extraction_runs` / `raw_path_summary_evidence`) ao backlog LeadFinder (`canonical_gaps` e `growth_pressure_signals`).

O desenho mantém as fases temporais explícitas e separadas via `temporal_phase`:

- `raw_observation`
- `path_extraction`
- `gap_proposal`
- `quality_report`
- `dto_candidate`
- `materialization_candidate`

O bridge suporta os dois caminhos exigidos:

1. match contra campo LeadFinder existente via `canonical_field_id` nullable;
2. gap novo via par obrigatório `proposed_family_key` + `proposed_field_key` quando `canonical_field_id` é nulo.

## Estruturas criadas

- Tabela `prop4you_leadfinder.raw_evidence_gap_bridges`
  - guarda refs Matrix/LeadFinder, path label, tipo JSON, contagens, pressão de filtro, fase temporal e links para gap/sinal;
  - não guarda raw values;
  - possui unique constraint `NULLS NOT DISTINCT` para idempotência também nos casos propostos com `canonical_field_id` nulo.
- View `prop4you_leadfinder.v_raw_evidence_gap_bridge_review`
  - projeção segura para revisão, sem payload bruto.
- Função `prop4you_leadfinder.propose_raw_evidence_gap_bridge(...)`
  - cria/atualiza de forma idempotente `canonical_gaps`, `growth_pressure_signals` e bridge row para uma evidência Matrix.
- Função `prop4you_leadfinder.bridge_raw_evidence_gap_candidates(...)`
  - helper batch para propor gaps a partir de evidência agregada acima de um threshold, derivando chaves seguras de componentes de path.
- Registro de public ref prefix `p4ylfgb`.

## Validação executada

Executado lab local em database descartável `pg18_lfgb_worker_a_lab`, sem imprimir secrets:

1. recriação do database lab;
2. aplicação de `database/ddl/base` via installer;
3. aplicação na ordem:
   - `projects/prop4you/0001_schemas.sql`
   - `providers/0001_provider_registry.sql`
   - `sourcehub/0001_sourcehub_corpus.sql`
   - `leadfinder/0001_canonical_dictionary.sql`
   - `matrix/0001_semantic_dictionary.sql`
   - `matrix/0002_mapping_sessions.sql`
   - `matrix/0003_raw_path_extractors.sql`
   - `leadfinder/0002_raw_evidence_gap_bridge.sql`
   - reapply de `leadfinder/0002_raw_evidence_gap_bridge.sql`
4. checks finais retornaram:
   - `bridge_table=prop4you_leadfinder.raw_evidence_gap_bridges`
   - `bridge_function=prop4you_leadfinder.propose_raw_evidence_gap_bridge(uuid,uuid,text,uuid,text,text,text,text,text,text,jsonb,text,jsonb)`
   - `unique_nulls_not_distinct=true`

Também executado dry-run do pacote LeadFinder:

- `scripts/apply-ddl-package.sh --package database/ddl/projects/prop4you/leadfinder --dry-run`
- hash de `0002_raw_evidence_gap_bridge.sql`: `e90afae49961f4aa8c59b88be85f49c60e01477a11b09584e8edd178ef930449`

## Bloqueios

Nenhum bloqueio para a entrega da DDL.

## Riscos residuais

- A função batch deriva `proposed_field_key` de componentes do path; revisão humana ainda deve ajustar família/campo antes de qualquer promoção semântica.
- Não foi criado fixture nem payload sintético para provar criação de registro funcional, por aderência à restrição de não criar fixtures nesta task. A prova de criação com corpus REIQ real deve ficar para a task de integração/lab end-to-end.
- A reexecução sobre ambientes onde uma versão anterior experimental desta mesma DDL já tenha criado a tabela sem `NULLS NOT DISTINCT` não altera constraints existentes automaticamente; no fluxo normal, este arquivo é novo e foi validado em database limpo.

## Próxima task sugerida

Integrar no proof script de ordem de aplicação e executar a prova end-to-end com corpus REIQ real, criando pelo menos um bridge row e validando que nenhum raw value aparece em outputs/logs.
