# Review/proposta — LFG staging candidates a partir de SourceHub translated DTOs

Status: proposta/review para T5.0; não é DDL final.
Worker: A — LFG staging candidates contract review.
Escopo alvo provável: `database/ddl/projects/prop4you/leadfinder_group/0001_staging_candidates.sql`.

## 1. Conclusão curta

A próxima fatia viável é criar um pacote `leadfinder_group` com uma tabela mínima de staging, `prop4you_leadfinder_group.staging_candidates`, alimentada exclusivamente por `prop4you_sourcehub.translated_dto_publications` T4.

Recomendação principal: o staging deve ser um gate revisável entre SourceHub DTO e materialização LFG, não a materialização operacional final. Ele deve criar 10 candidatos iniciais a partir das 10 publicações DTO já provadas, preservando lineage por FK/hash e mantendo o desenho gateway/runtime agnostic.

O staging não deve chamar provider, não deve ler corpus privado, não deve copiar `raw_payload`, não deve criar owner/property/lead final e não deve depender de Django/PostgREST/worker. A função de staging deve ser SQL/RPC pura e idempotente.

## 2. Evidência lida no repo

Arquivos revisados:

- `docs/issues/10-prop4you-lfg-staging-materialization-operational/00-detection-and-analysis.md`
- `docs/issues/10-prop4you-lfg-staging-materialization-operational/01-prd.md`
- `docs/issues/10-prop4you-lfg-staging-materialization-operational/02-tasks.md`
- `docs/issues/09-prop4you-sourcehub-translated-dto-publications/01-prd.md`
- `docs/issues/09-prop4you-sourcehub-translated-dto-publications/09-sourcehub-dto-ddl-review.md`
- `database/ddl/projects/prop4you/sourcehub/0001_sourcehub_corpus.sql`
- `database/ddl/projects/prop4you/sourcehub/0002_translated_dto_publications.sql`
- `database/ddl/projects/prop4you/matrix/0005_field_mapping_set_artifacts.sql`
- `database/ddl/projects/prop4you/leadfinder/0001_canonical_dictionary.sql`
- `database/ddl/projects/prop4you/leadfinder/0002_raw_evidence_gap_bridge.sql`
- `docs/database-centric-app-model.md`
- `docs/prop4you-database-centric-base-extraction.md`

Pontos relevantes:

- T4 já existe em SourceHub: `translated_dto_publications` referencia `raw_record_id`, `matrix_artifact_id` e `leadfinder_dictionary_version_id`.
- `sourcehub/0002` declara explicitamente `NO_LFG_MATERIALIZATION` e marca T5 como posterior.
- `matrix/0005` produz `field_mapping_set` sem valores raw e declara T4/T5 later.
- LeadFinder atual possui dicionário/gaps/bridge, mas ainda não possui bounded context LFG operacional.
- O PRD do issue 10 pede exatamente: 10 DTO publications -> 10 LFG staging candidates -> materialization runs/results -> operational/facets mínimos.

## 3. Boundary obrigatório para T5.0

A DDL final de T5.0 deve deixar claro no cabeçalho:

```sql
-- package: prop4you/leadfinder_group
-- file: 0001_staging_candidates.sql
-- status: experimental / non-final
-- purpose: LFG staging candidates derived from SourceHub T4 translated DTO publications.
-- depends-on: sourcehub/0002_translated_dto_publications.sql, matrix/0005_field_mapping_set_artifacts.sql, leadfinder/0001_canonical_dictionary.sql
-- idempotency: idempotent
-- destructive: false
-- [GATEWAY_AGNOSTIC] Callable by direct SQL, PostgREST RPC, Django/FastAPI passthrough, workers, or any other transport.
-- [SOURCEHUB_T4_INPUT] Consumes only SourceHub translated DTO publication rows.
-- [LFG_T5_STAGING_ONLY] Creates staging candidates only; materialization runs/results and operational entities remain later files.
-- [NO_PROVIDER_CALLS] No HTTP/provider SDK/worker/cron/file reads.
-- [NO_RAW_DUMPS] Does not copy SourceHub raw_payload and docs/proofs must not print DTO scalar payloads.
```

## 4. Schema e tabela recomendados

Schema: `prop4you_leadfinder_group`.

Tabela: `prop4you_leadfinder_group.staging_candidates`.

A tabela deve ser durável e auditável, mas estreita. Ela deve apontar para SourceHub DTO e carregar somente o necessário para revisão/materialization-run posterior.

Campos recomendados:

```sql
create schema if not exists prop4you_leadfinder_group;

create table if not exists prop4you_leadfinder_group.staging_candidates (
  id uuid primary key default uuidv7(),
  public_ref text generated always as (base.make_public_ref('p4ylfgs', id)) stored,

  source_publication_id uuid not null references prop4you_sourcehub.translated_dto_publications(id) on delete restrict,
  raw_record_id uuid not null references prop4you_sourcehub.raw_records(id) on delete restrict,
  matrix_artifact_id uuid not null references prop4you_matrix.transformation_artifacts(id) on delete restrict,
  leadfinder_dictionary_version_id uuid not null references prop4you_leadfinder.canonical_dictionary_versions(id) on delete restrict,
  provider_id uuid references prop4you_provider.providers(id) on delete restrict,
  payload_class_id uuid references prop4you_provider.payload_classes(id) on delete restrict,

  candidate_key text not null,
  candidate_status text not null default 'staged',
  candidate_gate_status text not null default 'ready_for_review',
  review_status text not null default 'unreviewed',
  candidate_kind text not null default 'lfg_staging_candidate',
  candidate_schema_version text not null default 'leadfinder_group.staging_candidate.v0',

  source_publication_key text not null,
  source_publication_status text not null,
  source_publication_gate_status text not null,
  source_publication_review_status text not null,
  source_translated_dto_sha256 text,
  source_payload_sha256 text,
  matrix_artifact_sha256 text,

  candidate_facts jsonb not null default '{}'::jsonb,
  candidate_summary jsonb not null default '{}'::jsonb,
  quality_summary jsonb not null default '{}'::jsonb,
  lineage_summary jsonb not null default '{}'::jsonb,
  redaction_summary jsonb not null default '{}'::jsonb,
  temporal_phase jsonb not null default '{"sourcehub_dto_publication":"T4","lfg_staging_candidate":"T5_0","lfg_materialization_run":"T5_1_later","lfg_operational_minimum":"T5_2_later"}'::jsonb,
  metadata jsonb not null default '{}'::jsonb,

  staged_at timestamptz not null default now(),
  staged_by_actor_id text,
  reviewed_at timestamptz,
  reviewed_by_actor_id text,
  superseded_by_candidate_id uuid references prop4you_leadfinder_group.staging_candidates(id) on delete set null,
  superseded_at timestamptz,

  active boolean not null default true,
  activated_at timestamptz,
  deactivated_at timestamptz,
  deleted boolean not null default false,
  deleted_at timestamptz,
  deleted_by_actor_id text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  last_modified_by_actor_id text,
  version integer not null default 1,

  constraint staging_candidates_public_ref_key unique (public_ref),
  constraint staging_candidates_source_publication_key unique (source_publication_id),
  constraint staging_candidates_candidate_key_key unique (candidate_key),
  constraint staging_candidates_candidate_key_format_chk check (candidate_key ~ '^[a-z][a-z0-9_.:-]{1,191}$'),
  constraint staging_candidates_status_chk check (candidate_status in ('staged','blocked','ready_for_materialization_review','materialization_pending','materialized','rejected','superseded','archived')),
  constraint staging_candidates_gate_status_chk check (candidate_gate_status in ('not_started','ready_for_review','passed','blocked','not_applicable')),
  constraint staging_candidates_review_status_chk check (review_status in ('unreviewed','in_review','accepted_for_materialization','needs_sourcehub_revision','needs_matrix_revision','needs_dictionary_revision','needs_redaction','rejected','not_applicable')),
  constraint staging_candidates_kind_chk check (candidate_kind in ('lfg_staging_candidate','review_snapshot','regression_metadata','unknown')),
  constraint staging_candidates_schema_version_chk check (candidate_schema_version ~ '^[a-z][a-z0-9_.:-]{1,79}$'),
  constraint staging_candidates_hash_chk check (source_translated_dto_sha256 is null or source_translated_dto_sha256 ~ '^[0-9a-f]{64}$'),
  constraint staging_candidates_source_hash_chk check (source_payload_sha256 is null or source_payload_sha256 ~ '^[0-9a-f]{64}$'),
  constraint staging_candidates_matrix_hash_chk check (matrix_artifact_sha256 is null or matrix_artifact_sha256 ~ '^[0-9a-f]{64}$'),
  constraint staging_candidates_facts_object_chk check (jsonb_typeof(candidate_facts) = 'object'),
  constraint staging_candidates_summary_object_chk check (jsonb_typeof(candidate_summary) = 'object'),
  constraint staging_candidates_quality_object_chk check (jsonb_typeof(quality_summary) = 'object'),
  constraint staging_candidates_lineage_object_chk check (jsonb_typeof(lineage_summary) = 'object'),
  constraint staging_candidates_redaction_object_chk check (jsonb_typeof(redaction_summary) = 'object'),
  constraint staging_candidates_temporal_object_chk check (jsonb_typeof(temporal_phase) = 'object'),
  constraint staging_candidates_metadata_object_chk check (jsonb_typeof(metadata) = 'object'),
  constraint staging_candidates_version_positive_chk check (version > 0)
);
```

### Observação sobre `candidate_facts`

Minha recomendação é não copiar o `translated_dto` inteiro cegamente. O staging deve usar uma destas duas políticas, nesta ordem de preferência:

1. Para a fatia inicial, persistir em `candidate_facts` apenas `translated_dto->'fields'` e metadados de contrato/lineage em colunas separadas.
2. Se houver risco de PII no proof, manter `candidate_facts = '{}'` e usar apenas hashes, contagens e `candidate_summary` até existir review de redaction.

Em ambos os casos, a DDL/proof não deve imprimir valores escalares do DTO. A tabela pode armazenar valores traduzidos para revisão interna, mas a projeção de review deve mostrar contagens, famílias/chaves e hashes, não dumps.

## 5. Índices recomendados

```sql
create index if not exists staging_candidates_status_gate_idx
  on prop4you_leadfinder_group.staging_candidates (candidate_status, candidate_gate_status, staged_at desc)
  where deleted = false;

create index if not exists staging_candidates_source_publication_status_idx
  on prop4you_leadfinder_group.staging_candidates (source_publication_id, candidate_status)
  where deleted = false;

create index if not exists staging_candidates_dictionary_status_idx
  on prop4you_leadfinder_group.staging_candidates (leadfinder_dictionary_version_id, candidate_status)
  where deleted = false;

create index if not exists staging_candidates_provider_payload_idx
  on prop4you_leadfinder_group.staging_candidates (provider_id, payload_class_id, candidate_status)
  where deleted = false;

create index if not exists staging_candidates_facts_gin_idx
  on prop4you_leadfinder_group.staging_candidates using gin (candidate_facts jsonb_path_ops);

create index if not exists staging_candidates_summary_gin_idx
  on prop4you_leadfinder_group.staging_candidates using gin (candidate_summary jsonb_path_ops);
```

## 6. Validação por trigger ou função

A DDL deve validar que o candidato sempre reflete sua publicação SourceHub:

- `source_publication_id` precisa existir, `deleted=false`, `active=true`.
- `publication_kind` deve ser `leadfinder_candidate` ou outro valor explicitamente aceito para staging.
- `publication_status` deve estar em `candidate`, `ready_for_review` ou `published`; para `published`, gate precisa ser `passed` por constraint já existente em SourceHub.
- `publication_gate_status` deve estar em `ready_for_review` ou `passed` para staging normal; `blocked` só deve gerar candidate `blocked`.
- `raw_record_id`, `matrix_artifact_id`, `leadfinder_dictionary_version_id`, `provider_id`, `payload_class_id` devem ser copiados da publicação e não aceitos como valores divergentes do caller.
- `matrix_artifact_kind` deve continuar `field_mapping_set` via a validação já existente em SourceHub; T5.0 pode revalidar para defesa em profundidade.
- `source_translated_dto_sha256`, `source_payload_sha256` e `matrix_artifact_sha256` devem ser copiados da publicação.

A função/trigger não deve consultar provider, arquivos externos ou raw corpus. Se ler `translated_dto`, deve ler somente a coluna T4 já publicada.

## 7. Função recomendada

Nome recomendado: `prop4you_leadfinder_group.stage_candidates_from_translated_dto_publications(...)`.

Assinatura proposta:

```sql
create or replace function prop4you_leadfinder_group.stage_candidates_from_translated_dto_publications(
  p_limit integer default 10,
  p_publication_statuses text[] default array['ready_for_review','published','candidate'],
  p_candidate_status text default 'staged',
  p_candidate_gate_status text default 'ready_for_review',
  p_actor_id text default null,
  p_metadata jsonb default '{}'::jsonb
)
returns setof prop4you_leadfinder_group.staging_candidates
language plpgsql
volatile;
```

Regras do corpo:

1. `effective_limit := greatest(1, least(coalesce(p_limit, 10), 1000))`.
2. Buscar publicações T4 `deleted=false`, `active=true`, `publication_kind='leadfinder_candidate'`.
3. Aceitar apenas `publication_status` em `p_publication_statuses`, limitado internamente ao vocabulário permitido.
4. Exigir `publication_gate_status in ('ready_for_review','passed')` para candidato normal.
5. Ordenar por `published_at nulls last, created_at, id` para reproduzibilidade.
6. Gerar `candidate_key` determinístico: `lfg_stage:` + publication uuid sem hífen, ou incluir hash quando disponível.
7. Inserir com `on conflict (source_publication_id) do update` ou `on conflict (candidate_key) do update`; preferir unique em `source_publication_id` para um candidato ativo por publicação T4.
8. Copiar somente refs/statuses/hashes/summaries e `translated_dto->'fields'` para `candidate_facts` se a política escolhida permitir.
9. Atualizar `last_modified_by_actor_id` e `metadata` com flags `gateway_agnostic`, `no_provider_calls`, `no_raw_payload_dump`, `sourcehub_phase='T4'`, `lfg_phase='T5_0'`.
10. Retornar as linhas criadas/atualizadas.

Pseudocorpo essencial:

```sql
for pub_row in
  select p.*
    from prop4you_sourcehub.translated_dto_publications p
   where p.deleted = false
     and p.active = true
     and p.publication_kind = 'leadfinder_candidate'
     and p.publication_status = any(effective_statuses)
     and p.publication_gate_status in ('ready_for_review','passed')
   order by p.published_at nulls last, p.created_at, p.id
   limit effective_limit
loop
  candidate_key_value := 'lfg_stage:' || replace(pub_row.id::text, '-', '');

  insert into prop4you_leadfinder_group.staging_candidates as sc (...)
  values (
    pub_row.id,
    pub_row.raw_record_id,
    pub_row.matrix_artifact_id,
    pub_row.leadfinder_dictionary_version_id,
    pub_row.provider_id,
    pub_row.payload_class_id,
    candidate_key_value,
    p_candidate_status,
    p_candidate_gate_status,
    'unreviewed',
    pub_row.publication_key,
    pub_row.publication_status,
    pub_row.publication_gate_status,
    pub_row.review_status,
    pub_row.translated_dto_sha256,
    pub_row.source_payload_sha256,
    pub_row.matrix_artifact_sha256,
    coalesce(pub_row.translated_dto->'fields', '{}'::jsonb),
    jsonb_build_object(
      'source_dto_contract', pub_row.dto_schema_version,
      'field_count', coalesce(jsonb_object_length(pub_row.translated_dto->'fields'), 0),
      'value_policy', 'values_not_printed_in_docs_or_proofs'
    ),
    pub_row.quality_summary,
    jsonb_build_object(
      'source_publication_id', pub_row.id,
      'raw_record_id', pub_row.raw_record_id,
      'matrix_artifact_id', pub_row.matrix_artifact_id,
      'leadfinder_dictionary_version_id', pub_row.leadfinder_dictionary_version_id
    ),
    pub_row.redaction_summary,
    jsonb_build_object('gateway_agnostic', true, 'no_provider_calls', true, 'no_raw_payload_dump', true) || coalesce(p_metadata, '{}'::jsonb)
  )
  on conflict (source_publication_id) do update
    set candidate_status = excluded.candidate_status,
        candidate_gate_status = excluded.candidate_gate_status,
        source_publication_status = excluded.source_publication_status,
        source_publication_gate_status = excluded.source_publication_gate_status,
        source_publication_review_status = excluded.source_publication_review_status,
        source_translated_dto_sha256 = excluded.source_translated_dto_sha256,
        source_payload_sha256 = excluded.source_payload_sha256,
        matrix_artifact_sha256 = excluded.matrix_artifact_sha256,
        candidate_facts = excluded.candidate_facts,
        candidate_summary = excluded.candidate_summary,
        quality_summary = excluded.quality_summary,
        lineage_summary = excluded.lineage_summary,
        redaction_summary = excluded.redaction_summary,
        metadata = sc.metadata || excluded.metadata,
        updated_at = now(),
        last_modified_by_actor_id = p_actor_id
  returning * into result_row;

  return next result_row;
end loop;
```

## 8. View de revisão segura

Criar uma view sem dumps de valores:

`prop4you_leadfinder_group.v_staging_candidate_review`

Campos recomendados:

- candidate id/public_ref/key/status/gate/review.
- SourceHub publication public_ref/key/status/gate/review.
- raw record public_ref, Matrix artifact key, dictionary version key.
- provider_key, payload_class_key.
- hashes: translated DTO, source payload, Matrix artifact.
- contagens: `candidate_field_count`, `quality_summary`, `redaction_summary`.
- timestamps.

Evitar na view inicial:

- `candidate_facts` completo.
- `translated_dto` completo.
- `raw_payload` completo.
- qualquer valor escalar de endereço, telefone, email, owner name, contact ou provider record.

## 9. Prefixo público e lifecycle

Registrar prefixo:

```sql
select base.register_public_id_prefix(
  'p4ylfgs',
  'prop4you_leadfinder_group',
  'staging_candidates',
  'Prop4You LFG staging candidate'
);
```

Aplicar triggers padrão:

- `base.set_lifecycle_defaults()` em insert.
- `base.touch_updated_at()` em update.
- `base.increment_version()` em update.

## 10. Relação com T5.1 e T5.2

T5.0 deve preparar, não executar materialização final.

T5.1 deve consumir `staging_candidates` e criar:

- `materialization_runs`
- `materialization_results`

T5.2 deve consumir resultados aceitos e criar a superfície operacional mínima.

Portanto T5.0 não deve criar:

- property final.
- owner final.
- lead final.
- scoring final.
- situation final.
- list/map/detail facades.
- RLS pública.

## 11. Critérios de aceite específicos para T5.0

A prova integrada deve conseguir demonstrar sem raw dumps:

```sql
select count(*) from prop4you_sourcehub.translated_dto_publications; -- >= 10 no fluxo alvo
select count(*) from prop4you_leadfinder_group.staging_candidates; -- 10 no fluxo alvo
```

E uma projeção segura:

```sql
select candidate_key,
       candidate_status,
       candidate_gate_status,
       source_publication_key,
       source_translated_dto_sha256,
       candidate_summary->>'field_count' as field_count
from prop4you_leadfinder_group.v_staging_candidate_review
order by created_at
limit 10;
```

A prova não deve imprimir `candidate_facts`, `translated_dto`, `raw_payload` ou valores escalares sensíveis.

## 12. Riscos e decisões pendentes

1. `sourcehub/0002` atualmente computa `translated_dto_sha256` por `translated_dto::text`. Isso é suficiente para prova local, mas não deve ser vendido como canonicalização externa universal.
2. `publish_translated_dtos_from_field_mapping_set` pode gerar publicações com `review_status='unreviewed'`. T5.0 precisa decidir se staging aceita `unreviewed` para prova experimental ou se exige `accepted_for_publication`. Para cumprir o fluxo dos 10 DTOs agora, recomendo aceitar `ready_for_review/unreviewed` como staging `unreviewed`, sem permitir materialização final automática.
3. `candidate_facts` pode conter PII se copiar `translated_dto->'fields'`. Para prova, a view deve ocultar valores e mostrar somente contagens/hashes. Se a equipe quiser risco menor, a primeira DDL pode deixar `candidate_facts='{}'` e depender de SourceHub DTO por FK.
4. O nome `leadfinder_group` é adequado para separar LFG staging/materialization do schema `prop4you_leadfinder` que hoje é dicionário/gap/canonical-review. Evita misturar dicionário com produto operacional.
5. Ainda não há RLS pública; manter todas as views como review internas, sem facade `api.*` nesta fatia.

## 13. Veredito

A proposta T5.0 está aprovada conceitualmente para implementação experimental como staging-only:

- consome exclusivamente SourceHub T4 DTO publications;
- cria uma linha idempotente de staging por publicação T4;
- preserva FK/lineage/hashes;
- continua gateway/runtime agnostic;
- não faz provider calls;
- não materializa owners/properties/leads finais;
- não imprime raw/DTO scalar dumps em docs/proofs;
- prepara o contrato limpo para T5.1 materialization runs/results.
