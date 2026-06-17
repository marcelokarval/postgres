# Review — Matrix quality_report artifact helper/contract

Status: delivered for Worker B local slice

## Resultado

Implementado `database/ddl/projects/prop4you/matrix/0004_quality_report_artifacts.sql` como contrato/helper separado de Matrix para `artifact_kind = 'quality_report'`, reutilizando `prop4you_matrix.transformation_artifacts`.

O helper principal é:

```sql
prop4you_matrix.create_raw_path_quality_report_artifact(
  p_raw_path_extraction_run_id uuid,
  p_dictionary_version_id uuid,
  p_artifact_key text default null,
  p_actor_id text default null,
  p_metadata jsonb default '{}'::jsonb
)
```

Ele cria/atualiza de forma idempotente:

- uma `mapping_sessions` de propósito `artifact_generation` para a execução de extração;
- um `transformation_artifacts` com `artifact_kind = 'quality_report'`;
- `artifact_payload` no contrato `matrix.quality_report.raw_path.v0`;
- `quality_summary` com métricas agregadas de paths/tipos/contagens;
- gate `ready_for_review` quando a extração está `completed` e tem evidência, ou `blocked` quando não há evidência pronta.

Também foi criada a view:

```sql
prop4you_matrix.v_quality_report_artifacts
```

para consultar apenas quality reports sem misturar com o bridge LeadFinder.

## Arquivos alterados

- `database/ddl/projects/prop4you/matrix/0004_quality_report_artifacts.sql` — novo DDL Matrix quality_report.
- `database/ddl/projects/prop4you/matrix/README.md` — documenta `0004_quality_report_artifacts.sql` e a separação do quality report.
- `docs/issues/07-prop4you-leadfinder-gap-bridge-quality-report/09-matrix-quality-report-review.md` — este review.
- `.tmp/prop4you-gap-bridge-quality/subagents/B-status.md` — status do subagente B.

## Validação

Executado:

```bash
python3 -m venv .tmp/pglast-venv
.tmp/pglast-venv/bin/pip install pglast
.tmp/pglast-venv/bin/python - <<'PY'
from pathlib import Path
from pglast import parse_sql
sql = Path('database/ddl/projects/prop4you/matrix/0004_quality_report_artifacts.sql').read_text()
stmts = parse_sql(sql)
print('pglast_parse_ok statements=', len(stmts))
PY
```

Resultado real:

```text
pglast_parse_ok statements= 8
```

Também executado smoke estático de contrato/guardrails:

```text
has_quality_report_kind=True
has_no_raw_values_guardrail=True
has_no_provider_calls_guardrail=True
uses_transformation_artifacts=True
has_helper_signature=True
no_insert_fixture_values=True
session_status_not_generated=True
```

Também executei apply real em lab temporário via `docker exec` no container PG18 local, incluindo:

- base DDL `database/ddl/base/*.sql`;
- Prop4You schemas/providers/sourcehub/matrix/leadfinder até `matrix/0004_quality_report_artifacts.sql`.

Runtime smoke criou uma `raw_path_extraction_runs` agregada, uma `raw_path_summary_evidence` sem raw values e chamou `create_raw_path_quality_report_artifact(...)`.

Resultado real do smoke:

```json
{"contract": "matrix.quality_report.raw_path.v0", "view_count": 0, "artifact_kind": "quality_report", "schema_version": "matrix.quality_report.raw_path.v0", "top_path_count": 1, "artifact_status": "generated", "raw_values_flag": "false", "artifact_gate_status": "ready_for_review", "leadfinder_bridge_embedded": "false"}
```

Observação: `view_count` ficou `0` porque foi lido no mesmo SQL statement que chamou a função mutante; o artifact retornado pela função foi criado com sucesso e trouxe `top_path_count = 1`. O lab temporário `pg18_worker_b_quality_lab` foi removido ao final.

`DRY_RUN=1 scripts/proof-prop4you-ddl-lab.sh` confirmou a ordem atual do proof existente. Observação: esse proof ainda não inclui `matrix/0004_quality_report_artifacts.sql`; a integração do proof order está listada como T5/Thor.

## Bloqueios

- Nenhum bloqueio para a entrega do Worker B após validação via `docker exec` no PG18 local.
- Ainda falta integrar o novo DDL ao proof script oficial da slice, o que parece pertencer à T5/Thor.

## Riscos residuais

- O proof runtime foi smoke controlado com evidência agregada mínima; ainda falta o lab completo com ingest/extractor REIQ e bridge LeadFinder da stack 07.
- O helper limita `top_path_evidence` a 200 linhas agregadas para manter o artifact payload revisável; se o relatório precisar de paginação completa, uma próxima slice deve adicionar projeção paginada em view/tabela auxiliar.
- A criação idempotente usa `artifact_key` único global. Se o consumidor fornecer uma chave já usada por artifact não-`quality_report`, a função bloqueia com exceção para evitar sobrescrever outro contrato.

## Próxima task sugerida

Integrar `database/ddl/projects/prop4you/matrix/0004_quality_report_artifacts.sql` no proof/apply order Thor T5 e rodar PG18 lab com:

1. ingest/extractor REIQ;
2. bridge LeadFinder T2;
3. `create_raw_path_quality_report_artifact(...)` T3;
4. validação de que nenhum raw value/PII aparece no `artifact_payload` ou `quality_summary`.
