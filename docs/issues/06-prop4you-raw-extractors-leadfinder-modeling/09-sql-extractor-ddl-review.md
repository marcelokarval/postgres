# Review — Worker B SQL raw path extractor DDL

Status: delivered for Thor review.

## Resultado

Implementei `database/ddl/projects/prop4you/matrix/0003_raw_path_extractors.sql` como DDL experimental, idempotente e não destrutivo para a Matrix extrair evidência segura de paths/tipos/contagens a partir de `prop4you_sourcehub.raw_records`.

A implementação mantém a regra de privacidade do slice:

- não cria fixtures de payload;
- não executa chamadas a providers;
- não lê arquivos externos;
- não expõe nem persiste valores escalares brutos do JSONB;
- usa `prop4you_provider.jsonb_leaf_paths` para enumerar paths/tipos;
- usa `prop4you_provider.jsonb_path_type` no extrator per-record seguro.

## Objetos criados

Arquivo: `database/ddl/projects/prop4you/matrix/0003_raw_path_extractors.sql`

Objetos principais:

1. `prop4you_matrix.jsonb_path_label(text[])`
   - Formata `text[]` JSONB path em label de revisão (`$.items[0]["owner name"]`).
   - Não lê valores do payload.

2. `prop4you_matrix.raw_path_extraction_runs`
   - Header de execução/lab para refresh idempotente de evidências.
   - Registra filtros, `max_depth`, contagens e sumário agregado.
   - Usa `public_ref` com prefixo `p4yrpe`.

3. `prop4you_matrix.raw_path_summary_evidence`
   - Tabela agregada de evidência por run/provider/payload_class/path/type.
   - Campos principais: `source_path`, `source_path_label`, `observed_json_type`, `occurrence_count`, `raw_record_count`, janela `captured_at`.
   - Não armazena valores brutos.

4. `prop4you_matrix.v_raw_record_leaf_path_evidence`
   - View segura per-record para path/type evidence em profundidade padrão 8.
   - Expõe `raw_record_public_ref`, provider/payload labels, path e tipo.
   - Não expõe `raw_payload` nem valores escalares.

5. `prop4you_matrix.v_raw_path_current_summary`
   - View live agregada sobre os raw records ativos/não deletados.
   - Retorna paths, tipos, contagens e janela temporal.

6. `prop4you_matrix.refresh_raw_path_summary_evidence(...)`
   - Refresh idempotente da tabela agregada por `run_key`.
   - Suporta filtros opcionais por `provider_id` e `payload_class_id` e clamp de profundidade 1..32.
   - Regrava apenas as evidências daquela run.

7. `prop4you_matrix.raw_record_path_type_evidence(uuid, integer)`
   - Extrator seguro para um raw record específico.
   - Usa `jsonb_leaf_paths` + `jsonb_path_type` para retornar só path/type.

8. Prefixo público registrado:
   - `p4yrpe` -> `prop4you_matrix.raw_path_extraction_runs`.

## Validação executada

Ambiente: container PG18 local `postgres18_postgres.1.w09al3xi32rt4ve65wnqjgr8s`, database isolada temporária `p4y_worker_b_raw_path_lab`.

DDL aplicado em ordem:

1. `database/ddl/base/*.sql`
2. `database/ddl/projects/prop4you/0001_schemas.sql`
3. `database/ddl/projects/prop4you/providers/0001_provider_registry.sql`
4. `database/ddl/projects/prop4you/sourcehub/0001_sourcehub_corpus.sql`
5. `database/ddl/projects/prop4you/leadfinder/0001_canonical_dictionary.sql`
6. `database/ddl/projects/prop4you/matrix/0001_semantic_dictionary.sql`
7. `database/ddl/projects/prop4you/matrix/0002_mapping_sessions.sql`
8. `database/ddl/projects/prop4you/matrix/0003_raw_path_extractors.sql`
9. Reaplicação de `0003_raw_path_extractors.sql` para provar idempotência.

Saída relevante:

```text
PG18 validation database: p4y_worker_b_raw_path_lab
objects=4
functions=3
path_label=$.items[0]["owner name"]
empty_refresh_status=completed
empty_refresh_counts=0/0/0
```

Interpretação:

- os 2 tables/views esperados principais existem (`objects=4`);
- as 3 funções esperadas existem (`functions=3`);
- label de path funciona sem ler valor bruto;
- refresh sem raw records finaliza como `completed` com contagens zero;
- a DDL nova foi reaplicada sem erro.

A database temporária foi removida ao final da validação.

## Notas de design

- O DDL grava aggregate evidence em Matrix porque Matrix é a fronteira de revisão semântica; SourceHub continua dono dos raw payloads.
- `raw_path_summary_evidence.evidence_summary` pode guardar refs públicas de amostra para navegação de revisão, mas não valores.
- As views são úteis em lab sem materializar dados sensíveis.
- `refresh_raw_path_summary_evidence` não altera `prop4you_sourcehub.raw_records.matrix_mapping_status`; a promoção de status deve permanecer como decisão posterior de workflow/review.

## Bloqueios

Nenhum bloqueio técnico para o slice B.

## Riscos residuais

- Em corpora muito grandes, `jsonb_leaf_paths` via recursive walk pode ser caro; recomenda-se Thor avaliar volume e talvez usar filtros por provider/payload_class/run.
- `sample_raw_record_public_refs` em `evidence_summary` usa todos os refs distintos por path; se o corpus crescer muito, pode ser necessário limitar/amostrar em uma iteração futura.
- Não validei contra payload real por exigência do slice de não criar fixtures nem inserir valores brutos.

## Próxima task sugerida

Thor/T5: integrar `0003_raw_path_extractors.sql` ao proof script e executar validação com corpus privado/controlado quando disponível, verificando volume, tempo de execução e formato de summaries para consumo por LeadFinder modeling.
